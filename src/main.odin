// src/main.odin
package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

import ast         "ast"
import codegen     "codegen"
import errors      "errors"
import parser      "parser"
import resolver    "resolver"
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
            fmt.eprintln("Usage: odin-templ generate <src> [-o <out>]")
            os.exit(2)
        }
        code := cmd_generate(src_dir, out_dir)
        os.exit(code)

    case "watch":
        src_dir, out_dir, ok := parse_src_out_args(rest)
        if !ok {
            fmt.eprintln("Usage: odin-templ watch <src> [-o <out>]")
            os.exit(2)
        }
        cmd_watch(src_dir, out_dir)

    case "fmt":
        if len(rest) == 0 {
            fmt.eprintln("Usage: odin-templ fmt <src>")
            os.exit(2)
        }
        src_dir := rest[0]
        code := cmd_fmt(src_dir)
        os.exit(code)

    case:
        fmt.eprintfln("Unknown command: %s", command)
        print_usage()
        os.exit(2)
    }
}

print_usage :: proc() {
    fmt.eprintln("odin-templ v0.1.0")
    fmt.eprintln("")
    fmt.eprintln("Usage:")
    fmt.eprintln("  odin-templ generate <src> [-o <out>]")
    fmt.eprintln("  odin-templ watch    <src> [-o <out>]")
    fmt.eprintln("  odin-templ fmt      <src>")
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
    // 1. Ensure out_dir exists, then write runtime package to out_dir/runtime/
    ensure_dir(out_dir)
    if !runtime_gen.generate(out_dir) {
        fmt.eprintfln("error: failed to write runtime package to %s/runtime", out_dir)
        return 1
    }

    // 2. Discover all .ohtml files recursively
    files := discover_ohtml_files(src_dir)
    defer delete(files)

    if len(files) == 0 {
        fmt.eprintfln("No .ohtml files found in %s", src_dir)
        return 0
    }

    // 3. Parse each file
    // Keep all src buffers alive until codegen is done (AST slices point into them)
    src_bufs := make([dynamic][]byte)
    defer {
        for buf in src_bufs { delete(buf) }
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
        rel_dir := path_dir(rel)             // "components/card"
        comp_name := path_stem(path_base(rel))  // "Card"
        resolver.register_component(&reg, rel_dir, comp_name)
    }

    // 5. Resolve each file (validate imports/components)
    for file in files {
        doc, in_map := &docs[file]
        if !in_map { continue }
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

    // 7 & 8. Generate .odin files and write them
    for file in files {
        doc := docs[file]
        rel := relative_path(src_dir, file)
        out_path := compute_out_path(out_dir, rel, file)
        pkg_name := compute_pkg_name(rel)

        // Ensure output directory exists
        out_file_dir := path_dir(out_path)
        ensure_dir(out_file_dir)

        code: string
        if is_page_file(file) {
            // Resolve layout chain
            layout_chain_paths := resolver.resolve_layout_chain(file, src_dir)
            defer delete(layout_chain_paths)

            layout_docs := make([dynamic]ast.Document)
            defer delete(layout_docs)
            // Keep layout source buffers alive until after codegen (AST slices point into them)
            layout_src_bufs := make([dynamic][]byte)
            defer {
                for buf in layout_src_bufs { delete(buf) }
                delete(layout_src_bufs)
            }

            for lp in layout_chain_paths {
                lp_bytes, lp_read_err := os.read_entire_file_from_path(lp, context.allocator)
                if lp_read_err != nil { continue }
                append(&layout_src_bufs, lp_bytes)
                lp_doc, lp_err := parser.parse(string(lp_bytes), lp)
                if _, has_err := lp_err.?; !has_err {
                    append(&layout_docs, lp_doc)
                }
            }

            code = codegen.generate_page(doc, pkg_name, layout_docs[:])
        } else {
            // Regular component or layout file — both use generate
            code = codegen.generate(doc, pkg_name)
        }

        write_err := os.write_entire_file(out_path, transmute([]byte)code)
        if write_err != nil {
            fmt.eprintfln("error: failed to write %s", out_path)
            return 1
        }

        fmt.printfln("  wrote %s", out_path)
    }

    fmt.printfln("Generated %d file(s) into %s", len(files), out_dir)
    return 0
}

// ensure_dir creates a directory and all parents if they don't exist.
ensure_dir :: proc(dir: string) {
    if dir == "." || len(dir) == 0 { return }
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
            if t_err != nil { continue }

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
        if strings.contains(trimmed, "<script>") {
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
        for _ in 0..<indent {
            strings.write_string(&b, "  ")
        }

        // Normalize attribute quotes: single → double
        normalized := normalize_quotes(trimmed)
        strings.write_string(&b, normalized)
        strings.write_byte(&b, '\n')

        // Increase indent for opening tags (not self-closing, not closing, not comments)
        is_opening := strings.has_prefix(inner, "<") &&
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
        if ch == '\'' && i > 0 && line[i-1] == '=' {
            // Single-quoted attribute value after '='
            strings.write_byte(&b, '"')
            i += 1
            for i < len(line) && line[i] != '\'' {
                strings.write_byte(&b, line[i])
                i += 1
            }
            strings.write_byte(&b, '"')
            if i < len(line) { i += 1 } // skip closing '
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
            walk_dir(full_path, result)
            delete(full_path)
        } else if strings.has_suffix(info.name, ".ohtml") {
            append(result, full_path)
        } else {
            delete(full_path)
        }
    }
}

// ─── path helpers ─────────────────────────────────────────────────────────────

// is_page_file returns true if the file is a +page.ohtml file.
is_page_file :: proc(path: string) -> bool {
    return strings.has_suffix(path, "/+page.ohtml") || path == "+page.ohtml"
}

// is_layout_file returns true if the file is a +layout.ohtml file.
is_layout_file :: proc(path: string) -> bool {
    return strings.has_suffix(path, "/+layout.ohtml") || path == "+layout.ohtml"
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
    if idx < 0 { return "." }
    return path[:idx]
}

// path_base returns the filename portion of a path.
path_base :: proc(path: string) -> string {
    idx := strings.last_index(path, "/")
    if idx < 0 { return path }
    return path[idx+1:]
}

// path_stem returns the filename without its extension.
path_stem :: proc(name: string) -> string {
    idx := strings.last_index(name, ".")
    if idx < 0 { return name }
    return name[:idx]
}

// strip_brackets removes `[` and `]` from a path segment (e.g. "[slug]" -> "slug").
strip_brackets :: proc(segment: string) -> string {
    return strings.trim(segment, "[]")
}

// normalize_path_brackets strips brackets from every segment of a slash-separated path.
// e.g. "views/blog/[slug]" -> "views/blog/slug"
normalize_path_brackets :: proc(path: string) -> string {
    segments := strings.split(path, "/")
    defer delete(segments)
    for i in 0..<len(segments) {
        segments[i] = strip_brackets(segments[i])
    }
    return strings.join(segments, "/")
}

// compute_out_path computes the output .odin file path.
// rel is the relative path from src_dir, e.g. "components/card/Card.ohtml"
// For +page.ohtml: out_dir/rel_dir/page.odin
// For +layout.ohtml: out_dir/rel_dir/layout.odin
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
// It uses the last directory segment of the relative path, or the stem if at root.
// Brackets are stripped from the segment name (e.g. [slug] -> slug).
compute_pkg_name :: proc(rel: string) -> string {
    rel_dir := path_dir(rel)
    if rel_dir == "." {
        return strings.to_lower(path_stem(path_base(rel)))
    }
    // Last segment of rel_dir
    idx := strings.last_index(rel_dir, "/")
    last_seg: string
    if idx < 0 {
        last_seg = rel_dir
    } else {
        last_seg = rel_dir[idx+1:]
    }
    // Strip [brackets] from the segment (e.g. [slug] -> slug)
    last_seg = strip_brackets(last_seg)
    return strings.to_lower(last_seg)
}
