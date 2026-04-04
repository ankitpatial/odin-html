// src/main.odin
package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

import ast "ast"
import codegen "codegen"
import errors "errors"
import lsp "lsp"
import parser "parser"
import resolver "resolver"
import runtime_gen "runtime_gen"

// ─── entry point ──────────────────────────────────────────────────────────────

main :: proc() {
	args := os.args
	if len(args) < 2 {
		print_usage()
		os.exit(2)
	}

	command := args[1]
	rest := args[2:]

	switch command {
	case "generate":
		src_dir, out_dir, ok := parse_src_out_args(rest)
		if !ok {
			fmt.eprintln("Usage: ohtml generate <src> [-o <out>]")
			os.exit(2)
		}
		code := cmd_generate(src_dir, out_dir)
		os.exit(code)

	case "watch":
		src_dir, out_dir, ok := parse_src_out_args(rest)
		if !ok {
			fmt.eprintln("Usage: ohtml watch <src> [-o <out>]")
			os.exit(2)
		}
		cmd_watch(src_dir, out_dir)

	case "fmt":
		if len(rest) == 0 {
			fmt.eprintln("Usage: ohtml fmt <src>")
			os.exit(2)
		}
		src_dir := rest[0]
		code := cmd_fmt(src_dir)
		os.exit(code)

	case "lsp":
		lsp.run()

	case:
		fmt.eprintfln("Unknown command: %s", command)
		print_usage()
		os.exit(2)
	}
}

print_usage :: proc() {
	fmt.eprintln("ohtml v0.1.0")
	fmt.eprintln("")
	fmt.eprintln("Usage:")
	fmt.eprintln("  ohtml generate <src> [-o <out>]")
	fmt.eprintln("  ohtml watch    <src> [-o <out>]")
	fmt.eprintln("  ohtml fmt      <src>")
	fmt.eprintln("  ohtml lsp")
}

// parse_src_out_args parses remaining args after the command.
// Returns (src_dir, out_dir, ok).
// -o <out> is optional (defaults to "gen").
parse_src_out_args :: proc(args: []string) -> (src_dir: string, out_dir: string, ok: bool) {
	out_dir = "gen"
	src_dir = ""

	i := 0
	for i < len(args) {
		arg := args[i]
		if arg == "-o" {
			i += 1
			if i >= len(args) {
				return "", "", false
			}
			out_dir = args[i]
		} else if !strings.has_prefix(arg, "-") {
			src_dir = arg
		}
		i += 1
	}

	if len(src_dir) == 0 {
		return "", "", false
	}

	return src_dir, out_dir, true
}

// ─── generate command ─────────────────────────────────────────────────────────

cmd_generate :: proc(src_dir: string, out_dir: string) -> int {
	// 1. Ensure out_dir exists, then write runtime package to out_dir/rt/
	ensure_dir(out_dir)
	if !runtime_gen.generate(out_dir) {
		fmt.eprintfln("error: failed to write runtime package to %s/rt", out_dir)
		return 1
	}

	// 1b. Parse app.html as the outermost document wrapper (optional).
	// SvelteKit uses app.html to provide the HTML document shell (DOCTYPE, <html>,
	// <head>, <body>). We preprocess its %sveltekit.*% placeholders and parse it
	// as the outermost layout in the chain.
	app_doc: Maybe(ast.Document)
	app_html_src: string // preprocessed source — must survive for AST slice refs
	{
		app_path := fmt.tprintf("%s/app.html", src_dir)
		raw, read_err := os.read_entire_file_from_path(app_path, context.allocator)
		if read_err == nil {
			app_html_src = preprocess_app_html(string(raw))
			delete(raw)
			doc, parse_err := parser.parse(app_html_src, "app.html")
			if _, has_err := parse_err.?; has_err {
				fmt.eprintfln("warning: failed to parse app.html — document wrapper disabled")
			} else {
				app_doc = doc
				fmt.printfln("  parsed app.html as document wrapper")
			}
		}
	}

	// 2. Discover all .ohtml and .svelte files recursively
	files := discover_ohtml_files(src_dir)
	defer delete(files)

	if len(files) == 0 {
		fmt.eprintfln("No .ohtml or .svelte files found in %s", src_dir)
		return 0
	}

	// 3. Parse each file
	// Keep all src buffers alive until codegen is done (AST slices point into them)
	src_bufs := make([dynamic][]byte)
	defer {
		for buf in src_bufs {delete(buf)}
		delete(src_bufs)
	}

	docs := make(map[string]ast.Document)
	defer delete(docs)
	all_errors := make([dynamic]errors.Error)
	defer delete(all_errors)

	for file in files {
		src_bytes, read_err := os.read_entire_file_from_path(file, context.allocator)
		if read_err != nil {
			fmt.eprintfln("error: failed to read %s: %v", file, read_err)
			return 1
		}
		append(&src_bufs, src_bytes)

		src := string(src_bytes)
		doc, parse_err := parser.parse(src, file)
		if parse_err_val, has_err := parse_err.?; has_err {
			append(&all_errors, parse_err_val)
		} else {
			docs[file] = doc
		}
	}

	// 4. Build component registry from discovered files
	reg := resolver.make_registry()
	for file in files {
		if is_page_file(file) || is_layout_file(file) {
			continue
		}
		// Import path = relative path from src_dir to the file's directory
		rel := relative_path(src_dir, file)
		// rel is like "components/card/Card.ohtml"
		rel_dir := path_dir(rel) // "components/card"
		comp_name := path_stem(path_base(rel)) // "Card"
		resolver.register_component(&reg, rel_dir, comp_name)
	}

	// 5. Normalize relative import paths to root-relative, then resolve
	for file in files {
		doc, in_map := &docs[file]
		if !in_map {continue}

		// Normalize relative imports (e.g. "../components/card" -> "components/card")
		if script, ok := &doc.script.?; ok {
			rel := relative_path(src_dir, file)
			file_dir := path_dir(rel)
			for &imp in script.imports {
				if strings.has_prefix(imp.path, ".") {
					imp.path = resolve_relative_path(file_dir, imp.path)
				}
			}
		}

		errs := resolver.resolve(doc, reg)
		for e in errs {
			append(&all_errors, e)
		}
		delete(errs)
	}

	// 6. If ANY errors: print all, return 1 (all-or-nothing)
	if len(all_errors) > 0 {
		for e in all_errors {
			fmt.eprintln(errors.format(e))
		}
		return 1
	}

	// 7 & 8. Generate .odin files and write them (skip layouts — they are inlined into pages)
	gen_count := 0
	for file in files {
		if is_layout_file(file) {continue}

		doc := docs[file]
		rel := relative_path(src_dir, file)
		out_path := compute_out_path(out_dir, rel, file)
		pkg_name := compute_pkg_name(rel, src_dir)
		route_params := extract_route_params(rel)

		// Rewrite imports to be relative from the generated file's output directory.
		// At this point imp.path is absolute from source root (resolved in phase 6).
		// We strip (group) segments, then make relative to the output directory.
		out_rel_dir := normalize_path_special(path_dir(rel))
		if script, ok := &doc.script.?; ok {
			for &imp in script.imports {
				if strings.has_prefix(imp.path, "core:") {continue}
				// Strip (group) segments from the resolved absolute import path
				normalized := normalize_path_special(imp.path)
				imp.path = make_relative_path(out_rel_dir, normalized)
			}
		}
		rt_import := make_relative_path(out_rel_dir, "rt")

		// Ensure output directory exists
		out_file_dir := path_dir(out_path)
		ensure_dir(out_file_dir)

		code: string
		if is_page_file(file) {
			// Check if the page is standalone (has its own <!DOCTYPE).
			// Standalone pages skip layout inlining.
			is_standalone := page_has_doctype(file)

			layout_docs := make([dynamic]ast.Document)
			defer delete(layout_docs)
			layout_src_bufs := make([dynamic][]byte)
			defer {
				for buf in layout_src_bufs {delete(buf)}
				delete(layout_src_bufs)
			}

			if !is_standalone {
				// Prepend app.html as outermost wrapper (index 0)
				if ad, ok := app_doc.?; ok {
					append(&layout_docs, ad)
				}

				layout_chain_paths := resolver.resolve_layout_chain(file, src_dir)
				defer delete(layout_chain_paths)

				for lp in layout_chain_paths {
					lp_bytes, lp_read_err := os.read_entire_file_from_path(lp, context.allocator)
					if lp_read_err != nil {continue}
					append(&layout_src_bufs, lp_bytes)
					lp_doc, lp_err := parser.parse(string(lp_bytes), lp)
					if _, has_err := lp_err.?; !has_err {
						append(&layout_docs, lp_doc)
					}
				}
			}

			code = codegen.generate_page(doc, pkg_name, layout_docs[:], route_params, rt_import)
		} else {
			// Regular component
			code = codegen.generate(doc, pkg_name, rt_import)
		}
		gen_count += 1

		write_err := os.write_entire_file(out_path, transmute([]byte)code)
		if write_err != nil {
			fmt.eprintfln("error: failed to write %s", out_path)
			return 1
		}

		fmt.printfln("  wrote %s", out_path)
	}

	fmt.printfln("Generated %d file(s) into %s", gen_count, out_dir)
	return 0
}

// ensure_dir creates a directory and all parents if they don't exist.
ensure_dir :: proc(dir: string) {
	if dir == "." || len(dir) == 0 {return}
	// Try to create parent first
	parent := path_dir(dir)
	if parent != dir {
		ensure_dir(parent)
	}
	os.make_directory(dir)
}

// ─── watch command ────────────────────────────────────────────────────────────

cmd_watch :: proc(src_dir: string, out_dir: string) {
	fmt.eprintfln("Watching %s for changes... (Ctrl+C to stop)", src_dir)

	// Track file modification times
	mod_times := make(map[string]time.Time)
	defer delete(mod_times)

	// Initial build
	_ = cmd_generate(src_dir, out_dir)

	// Initialize mod times after first build
	init_files := discover_ohtml_files(src_dir)
	for file in init_files {
		t, t_err := os.modification_time_by_path(file)
		if t_err == nil {
			mod_times[file] = t
		}
	}
	delete(init_files)

	// Poll loop
	for {
		time.sleep(1 * time.Second)

		current_files := discover_ohtml_files(src_dir)
		changed := false

		for file in current_files {
			t, t_err := os.modification_time_by_path(file)
			if t_err != nil {continue}

			prev_t, existed := mod_times[file]
			if !existed || t != prev_t {
				fmt.eprintfln("  changed: %s", file)
				mod_times[file] = t
				changed = true
			}
		}
		delete(current_files)

		if changed {
			fmt.eprintln("Rebuilding...")
			_ = cmd_generate(src_dir, out_dir)
		}
	}
}

// ─── fmt command ──────────────────────────────────────────────────────────────

cmd_fmt :: proc(src_dir: string) -> int {
	files := discover_ohtml_files(src_dir)
	defer delete(files)

	for file in files {
		content_bytes, read_err := os.read_entire_file_from_path(file, context.allocator)
		if read_err != nil {
			fmt.eprintfln("error: failed to read %s", file)
			return 1
		}
		defer delete(content_bytes)

		content := string(content_bytes)
		formatted := format_ohtml(content)

		write_err := os.write_entire_file(file, transmute([]byte)formatted)
		if write_err != nil {
			fmt.eprintfln("error: failed to write %s", file)
			return 1
		}

		fmt.printfln("  formatted %s", file)
	}

	return 0
}

format_ohtml :: proc(src: string) -> string {
	lines := strings.split_lines(src)
	defer delete(lines)

	b := strings.Builder{}
	strings.builder_init(&b)

	indent := 0
	in_script := false

	for line in lines {
		trimmed := strings.trim_right(line, " \t")

		// Track script block — don't touch its content
		if strings.contains(trimmed, "<script>") || strings.contains(trimmed, "<script ") {
			in_script = true
		}

		if in_script {
			strings.write_string(&b, trimmed)
			strings.write_byte(&b, '\n')
			if strings.contains(trimmed, "</script>") {
				in_script = false
			}
			continue
		}

		// Preserve blank lines
		if len(strings.trim_space(trimmed)) == 0 {
			strings.write_byte(&b, '\n')
			continue
		}

		// Decrease indent for closing tags
		inner := strings.trim_left(trimmed, " \t")
		is_closing := strings.has_prefix(inner, "</") || strings.has_prefix(inner, "{/")
		if is_closing && indent > 0 {
			indent -= 1
		}

		// Write indentation
		for _ in 0 ..< indent {
			strings.write_string(&b, "  ")
		}

		// Normalize attribute quotes: single → double
		normalized := normalize_quotes(trimmed)
		strings.write_string(&b, normalized)
		strings.write_byte(&b, '\n')

		// Increase indent for opening tags (not self-closing, not closing, not comments)
		is_opening :=
			strings.has_prefix(inner, "<") &&
			!is_closing &&
			!strings.has_suffix(strings.trim_right(inner, " \t"), "/>") &&
			!strings.has_prefix(inner, "<!--")
		if is_opening {
			indent += 1
		}
		// Control flow blocks
		if strings.has_prefix(inner, "{#") {
			indent += 1
		}
	}

	return strings.to_string(b)
}

// normalize_quotes converts single-quoted attribute values to double-quoted.
normalize_quotes :: proc(line: string) -> string {
	b := strings.Builder{}
	strings.builder_init(&b)

	i := 0
	for i < len(line) {
		ch := line[i]
		if ch == '\'' && i > 0 && line[i - 1] == '=' {
			// Single-quoted attribute value after '='
			strings.write_byte(&b, '"')
			i += 1
			for i < len(line) && line[i] != '\'' {
				strings.write_byte(&b, line[i])
				i += 1
			}
			strings.write_byte(&b, '"')
			if i < len(line) {i += 1} 	// skip closing '
		} else {
			strings.write_byte(&b, ch)
			i += 1
		}
	}

	return strings.to_string(b)
}

// ─── file discovery ───────────────────────────────────────────────────────────

discover_ohtml_files :: proc(dir: string) -> [dynamic]string {
	result := make([dynamic]string)
	walk_dir(dir, &result)
	return result
}

walk_dir :: proc(dir: string, result: ^[dynamic]string) {
	handle, err := os.open(dir)
	if err != nil {
		return
	}
	defer os.close(handle)

	infos, read_err := os.read_dir(handle, -1, context.allocator)
	if read_err != nil {
		return
	}
	defer os.file_info_slice_delete(infos, context.allocator)

	for info in infos {
		full_path := strings.concatenate({dir, "/", info.name})
		if info.type == .Directory {
			// Skip directories that shouldn't be processed
			if info.name == "node_modules" || info.name == ".svelte-kit" || info.name == "(backend)" {
				delete(full_path)
				continue
			}
			walk_dir(full_path, result)
			delete(full_path)
		} else if strings.has_suffix(info.name, ".ohtml") || strings.has_suffix(info.name, ".svelte") {
			append(result, full_path)
		} else {
			delete(full_path)
		}
	}
}

// ─── path helpers ─────────────────────────────────────────────────────────────

// is_page_file returns true if the file is a +page.ohtml or +page.svelte file.
is_page_file :: proc(path: string) -> bool {
	return strings.has_suffix(path, "/+page.ohtml") || path == "+page.ohtml" ||
	       strings.has_suffix(path, "/+page.svelte") || path == "+page.svelte"
}

// is_layout_file returns true if the file is a +layout.ohtml or +layout.svelte file.
is_layout_file :: proc(path: string) -> bool {
	return strings.has_suffix(path, "/+layout.ohtml") || path == "+layout.ohtml" ||
	       strings.has_suffix(path, "/+layout.svelte") || path == "+layout.svelte"
}

// relative_path returns the path of file relative to base_dir.
// e.g. base_dir="testdata/simple", file="testdata/simple/hello/Hello.ohtml"
//      returns "hello/Hello.ohtml"
relative_path :: proc(base_dir: string, file: string) -> string {
	base := strings.trim_right(base_dir, "/")
	if strings.has_prefix(file, base) {
		rel := file[len(base):]
		return strings.trim_left(rel, "/")
	}
	return file
}

// path_dir returns the directory portion of a path.
path_dir :: proc(path: string) -> string {
	idx := strings.last_index(path, "/")
	if idx < 0 {return "."}
	return path[:idx]
}

// path_base returns the filename portion of a path.
path_base :: proc(path: string) -> string {
	idx := strings.last_index(path, "/")
	if idx < 0 {return path}
	return path[idx + 1:]
}

// path_stem returns the filename without its extension.
path_stem :: proc(name: string) -> string {
	idx := strings.last_index(name, ".")
	if idx < 0 {return name}
	return name[:idx]
}

// make_relative_path computes a relative path from from_dir to to_path.
// Both are slash-separated paths relative to the same root.
// e.g. from_dir="views/product", to_path="components/price" -> "../../components/price"
// e.g. from_dir="components/product_card", to_path="components/badge" -> "../badge"
make_relative_path :: proc(from_dir: string, to_path: string) -> string {
	if from_dir == "." || len(from_dir) == 0 {
		return to_path
	}

	from_segs := strings.split(from_dir, "/")
	defer delete(from_segs)
	to_segs := strings.split(to_path, "/")
	defer delete(to_segs)

	// Find common prefix length
	common := 0
	for common < len(from_segs) && common < len(to_segs) {
		if from_segs[common] != to_segs[common] {break}
		common += 1
	}

	result := make([dynamic]string)
	defer delete(result)

	// Go up from from_dir (past common prefix)
	for _ in common ..< len(from_segs) {
		append(&result, "..")
	}

	// Go into to_path (past common prefix)
	for i in common ..< len(to_segs) {
		append(&result, to_segs[i])
	}

	if len(result) == 0 {return "."}
	return strings.join(result[:], "/")
}

// resolve_relative_path resolves a relative import path against a file's directory.
// e.g. file_dir="views/product/[slug]", rel="../../../components/card" -> "components/card"
// e.g. file_dir="views/cart", rel="../components/button" -> "components/button"
resolve_relative_path :: proc(file_dir: string, rel: string) -> string {
	// Start from the file's directory segments
	base_segs := strings.split(file_dir, "/")
	defer delete(base_segs)
	base := make([dynamic]string)
	defer delete(base)
	for s in base_segs {
		if len(s) > 0 && s != "." {
			append(&base, s)
		}
	}

	// Walk the relative path
	rel_segs := strings.split(rel, "/")
	defer delete(rel_segs)
	for s in rel_segs {
		if s == ".." {
			if len(base) > 0 {resize(&base, len(base) - 1)}
		} else if s != "." && len(s) > 0 {
			append(&base, s)
		}
	}

	if len(base) == 0 {return "."}
	return strings.join(base[:], "/")
}

// strip_brackets removes `[` and `]` from a path segment (e.g. "[slug]" -> "slug").
strip_brackets :: proc(segment: string) -> string {
	return strings.trim(segment, "[]")
}

// is_group_segment returns true for (parenthesized) path groups like "(auth)".
// Group directories are logical groupings — they are stripped from output paths
// but can contain +layout.ohtml that applies to children (SvelteKit convention).
is_group_segment :: proc(seg: string) -> bool {
	return len(seg) > 2 && seg[0] == '(' && seg[len(seg) - 1] == ')'
}

// normalize_path_special strips [bracket] route param segments and (group) segments
// from a slash-separated path.
// e.g. "views/product/[slug]" -> "views/product"
// e.g. "views/(auth)/login" -> "views/login"
normalize_path_special :: proc(path: string) -> string {
	segments := strings.split(path, "/")
	defer delete(segments)
	filtered := make([dynamic]string)
	defer delete(filtered)
	for seg in segments {
		if len(seg) > 0 && seg[0] == '[' {continue}   // route param
		if is_group_segment(seg) {continue}             // logical group
		append(&filtered, seg)
	}
	if len(filtered) == 0 {return "."}
	return strings.join(filtered[:], "/")
}

// Keep old name as alias for backwards compat within the codebase.
normalize_path_brackets :: normalize_path_special

// extract_route_params extracts parameter names from [bracket] directory segments.
// e.g. "product/[slug]/+page.ohtml" -> ["slug"]
// e.g. "blog/[category]/[slug]/+page.ohtml" -> ["category", "slug"]
extract_route_params :: proc(rel: string) -> []string {
	rel_dir := path_dir(rel)
	segments := strings.split(rel_dir, "/")
	defer delete(segments)
	params := make([dynamic]string)
	for seg in segments {
		if len(seg) > 2 && seg[0] == '[' && seg[len(seg) - 1] == ']' {
			append(&params, seg[1:len(seg) - 1])
		}
	}
	return params[:]
}

// compute_out_path computes the output .odin file path.
// rel is the relative path from src_dir, e.g. "components/card/Card.ohtml"
// For +page.ohtml: out_dir/rel_dir/page.odin
// For +layout.ohtml: skipped (inlined into pages)
// For components: out_dir/rel_dir/card.odin (lowercased stem)
// Directory segments with [brackets] (e.g. [slug]) are normalized by stripping brackets.
compute_out_path :: proc(out_dir: string, rel: string, file: string) -> string {
	rel_dir := path_dir(rel)
	rel_dir = normalize_path_brackets(rel_dir)
	file_stem := strings.to_lower(path_stem(path_base(rel)))

	out_name: string
	if is_page_file(file) {
		out_name = "page.odin"
	} else if is_layout_file(file) {
		out_name = "layout.odin"
	} else {
		out_name = strings.concatenate({file_stem, ".odin"})
	}

	if rel_dir == "." {
		return strings.concatenate({out_dir, "/", out_name})
	}
	return strings.concatenate({out_dir, "/", rel_dir, "/", out_name})
}

// compute_pkg_name returns the Odin package name for a generated file.
// It uses the last non-special directory segment of the relative path.
// [bracket] segments (route params) and (group) segments are skipped.
compute_pkg_name :: proc(rel: string, src_dir: string) -> string {
	rel_dir := path_dir(rel)
	if rel_dir == "." {
		base := path_base(src_dir)
		if base == "." || len(base) == 0 {
			return "root"
		}
		return strings.to_lower(strip_brackets(base))
	}
	// Find the last non-special segment (skip [brackets] and (groups))
	segments := strings.split(rel_dir, "/")
	defer delete(segments)
	last_seg := ""
	for seg in segments {
		if len(seg) == 0 {continue}
		if seg[0] == '[' {continue}        // route param
		if is_group_segment(seg) {continue} // logical group
		last_seg = seg
	}
	if len(last_seg) == 0 {return "root"}
	return strings.to_lower(last_seg)
}

// preprocess_app_html replaces SvelteKit template placeholders in app.html
// so it can be parsed as a regular layout document.
// %sveltekit.body%   → {@render children()} (body insertion point)
// %sveltekit.head%   → {@render __svelte_head__()} (head content insertion point)
// %sveltekit.assets%, %sveltekit.nonce%, %sveltekit.env.*% → removed
preprocess_app_html :: proc(src: string) -> string {
	b := strings.Builder{}
	strings.builder_init(&b, 0, len(src) + 64)

	i := 0
	for i < len(src) {
		if src[i] == '%' && i + 1 < len(src) {
			// Look for closing %
			j := i + 1
			for j < len(src) && src[j] != '%' {
				j += 1
			}
			if j < len(src) && j > i + 1 {
				placeholder := src[i + 1:j]
				if strings.has_prefix(placeholder, "sveltekit.") {
					key := placeholder[len("sveltekit."):]
					if key == "body" {
						strings.write_string(&b, "{@render children()}")
					} else if key == "head" {
						strings.write_string(&b, "{@render __svelte_head__()}")
					}
					// assets, nonce, env.* — emit nothing
					i = j + 1
					continue
				}
			}
		}
		strings.write_byte(&b, src[i])
		i += 1
	}

	return strings.to_string(b)
}

// page_has_doctype checks whether a page file contains its own <!DOCTYPE declaration.
// Standalone pages (with DOCTYPE) skip layout inlining.
page_has_doctype :: proc(file_path: string) -> bool {
	data, err := os.read_entire_file_from_path(file_path, context.temp_allocator)
	if err != nil { return false }
	src := string(data)
	// Skip the <script lang="odin">...</script> or <script lang="ts">...</script> block if present
	rest := src
	if idx := strings.index(src, "</script>"); idx >= 0 {
		rest = src[idx + len("</script>"):]
	}
	trimmed := strings.trim_left_space(rest)
	return strings.has_prefix(trimmed, "<!DOCTYPE") || strings.has_prefix(trimmed, "<!doctype")
}
