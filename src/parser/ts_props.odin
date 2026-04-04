// src/parser/ts_props.odin
package parser

import "core:strings"
import "../ast"

// parse_ts_script parses a TypeScript <script lang="ts"> block, extracting
// `interface Props { ... }` fields and Svelte component imports.
// Everything else ($props(), $state, functions, etc.) is ignored.
parse_ts_script :: proc(raw: string, file: string) -> (ast.Props_Def, [dynamic]ast.Import) {
    props := ast.Props_Def{}
    props.fields = make([dynamic]ast.Prop_Field)
    props.inline_structs = make([dynamic]ast.Inline_Struct)
    imports := make([dynamic]ast.Import)

    lines := strings.split_lines(raw)
    defer delete(lines)

    i := 0
    for i < len(lines) {
        line := strings.trim_space(lines[i])

        // ── imports: import Name from './path.svelte' ──
        if strings.has_prefix(line, "import ") && strings.contains(line, " from ") {
            imp, ok := parse_ts_import_line(line)
            if ok {
                append(&imports, imp)
            }
            i += 1
            continue
        }

        // ── interface Props { ... } ──
        if strings.contains(line, "interface Props") {
            // Find the opening brace
            brace_idx := strings.index(line, "{")
            if brace_idx >= 0 {
                // Check if closing brace is on the same line
                close_idx := strings.last_index(line, "}")
                if close_idx > brace_idx {
                    // Single-line interface: interface Props { name: string; count: number }
                    body := line[brace_idx + 1 : close_idx]
                    parse_ts_interface_body(body, &props)
                    i += 1
                    continue
                }
            }

            // Multi-line: collect lines until closing brace of the interface
            i += 1
            depth := 1
            field_buf := strings.Builder{}
            strings.builder_init(&field_buf)
            for i < len(lines) && depth > 0 {
                inner := strings.trim_space(lines[i])

                // Track brace depth to find interface end
                prev_depth := depth
                for ch in inner {
                    if ch == '{' { depth += 1 }
                    else if ch == '}' { depth -= 1 }
                }

                if depth > 0 {
                    // Accumulate into field buffer (handles multi-line inline objects)
                    if strings.builder_len(field_buf) > 0 {
                        strings.write_string(&field_buf, " ")
                    }
                    strings.write_string(&field_buf, inner)

                    // If we're back at depth 1, we have a complete field
                    if depth == 1 {
                        full_field := strings.clone(strings.to_string(field_buf))
                        if len(strings.trim_space(full_field)) > 0 {
                            parse_ts_field_line(full_field, &props)
                        }
                        strings.builder_reset(&field_buf)
                    }
                } else if prev_depth == 1 {
                    // depth just went to 0 — this is the closing brace of interface
                    // Any accumulated content before the } is a field
                    // Check if there's content before the closing }
                    brace_pos := strings.last_index(inner, "}")
                    if brace_pos > 0 {
                        before := strings.trim_space(inner[:brace_pos])
                        if len(before) > 0 {
                            if strings.builder_len(field_buf) > 0 {
                                strings.write_string(&field_buf, " ")
                            }
                            strings.write_string(&field_buf, before)
                        }
                    }
                    full_field := strings.clone(strings.to_string(field_buf))
                    if len(strings.trim_space(full_field)) > 0 {
                        parse_ts_field_line(full_field, &props)
                    }
                    strings.builder_reset(&field_buf)
                }
                i += 1
            }
            continue
        }

        i += 1
    }

    return props, imports
}

// parse_ts_import_line parses: import Name from './path.svelte'
// Returns the import and true if it's a .svelte component import, false otherwise.
parse_ts_import_line :: proc(line: string) -> (ast.Import, bool) {
    // Format: import Name from './path.svelte'
    // or:     import Name from "./path.svelte"
    rest := strings.trim_space(line[len("import "):])

    // Find " from "
    from_idx := strings.index(rest, " from ")
    if from_idx < 0 { return {}, false }

    alias := strings.trim_space(rest[:from_idx])
    path_part := strings.trim_space(rest[from_idx + len(" from "):])

    // Strip quotes and trailing semicolon
    path_part = strings.trim_right(path_part, ";")
    path_part = strings.trim_space(path_part)
    path_str := strings.trim(path_part, "'\"")

    // Only process .svelte imports as component imports
    if !strings.has_suffix(path_str, ".svelte") { return {}, false }

    // Strip the .svelte extension from the path
    path_str = path_str[:len(path_str) - len(".svelte")]

    // Resolve $lib/ alias to lib/ (SvelteKit convention)
    if strings.has_prefix(path_str, "$lib/") {
        path_str = strings.concatenate({"lib/", path_str[len("$lib/"):]})
    }

    // Strip the filename, keep only the directory path.
    // e.g. "../components/badge/Badge" -> "../components/badge"
    slash_idx := strings.last_index(path_str, "/")
    if slash_idx >= 0 {
        path_str = path_str[:slash_idx]
    }

    return ast.Import{alias = alias, path = path_str}, true
}

// parse_ts_interface_body parses a single-line interface body like "name: string; count: number"
parse_ts_interface_body :: proc(body: string, props: ^ast.Props_Def) {
    // Split by semicolon
    parts := strings.split(body, ";")
    defer delete(parts)
    for part in parts {
        trimmed := strings.trim_space(part)
        if len(trimmed) == 0 { continue }
        parse_ts_field_line(trimmed, props)
    }
}

// parse_ts_field_line parses a single TypeScript interface field line like:
//   name: string;
//   count?: number;
//   items: string[];
//   active: boolean | null;
//   children: Snippet;
//   items: { name: string; price: number; active: boolean }[];
parse_ts_field_line :: proc(line: string, props: ^ast.Props_Def) {
    fl := strings.trim_right(line, ";,")
    fl = strings.trim_space(fl)
    if len(fl) == 0 { return }

    colon_idx := strings.index(fl, ":")
    if colon_idx < 0 { return }

    name := strings.trim_space(fl[:colon_idx])
    type_str := strings.trim_space(fl[colon_idx + 1:])

    if len(name) == 0 || len(type_str) == 0 { return }

    // Check for optional marker: name?
    is_optional := false
    if strings.has_suffix(name, "?") {
        name = name[:len(name) - 1]
        is_optional = true
    }

    // Check for inline object type: { field: type; ... } or { field: type; ... }[]
    if strings.has_prefix(type_str, "{") {
        odin_type := parse_inline_object_type(name, type_str, props)
        if is_optional {
            odin_type = strings.concatenate({"Maybe(", odin_type, ")"})
        }
        field := ast.Prop_Field{
            name      = name,
            type_expr = odin_type,
            is_snippet = false,
        }
        append(&props.fields, field)
        return
    }

    // Convert TS type to Odin type
    odin_type, is_snippet := convert_ts_type(type_str)

    // Wrap in Maybe() if optional
    if is_optional && !is_snippet {
        odin_type = strings.concatenate({"Maybe(", odin_type, ")"})
    }

    field := ast.Prop_Field{
        name      = name,
        type_expr = odin_type,
        is_snippet = is_snippet,
    }

    append(&props.fields, field)
}

// parse_inline_object_type handles inline object types like:
//   { name: string; price: number; active: boolean }
//   { name: string; price: number }[]
// It generates a struct name from the parent field name (e.g. "items" -> "PropsItems"),
// parses the inner fields, stores the inline struct definition, and returns the Odin type.
parse_inline_object_type :: proc(field_name: string, type_str: string, props: ^ast.Props_Def) -> string {
    t := type_str

    // Check if it's an array of inline objects: { ... }[]
    is_array := false
    // Find the closing brace
    close_brace := find_matching_brace(t, 0)
    if close_brace < 0 {
        // Malformed — fallback
        return "rawptr"
    }

    after_brace := strings.trim_space(t[close_brace + 1:])
    if strings.has_prefix(after_brace, "[]") {
        is_array = true
    }

    // Extract body between { and }
    body := strings.trim_space(t[1:close_brace])

    // Generate struct name: "Props" + capitalize(field_name)
    struct_name := strings.concatenate({"Props", capitalize_first(field_name)})

    // Parse inner fields
    inner_fields := make([dynamic]ast.Prop_Field)
    parts := strings.split(body, ";")
    defer delete(parts)
    for part in parts {
        trimmed := strings.trim_space(part)
        if len(trimmed) == 0 { continue }

        inner_colon := strings.index(trimmed, ":")
        if inner_colon < 0 { continue }

        inner_name := strings.trim_space(trimmed[:inner_colon])
        inner_type_str := strings.trim_space(trimmed[inner_colon + 1:])
        if len(inner_name) == 0 || len(inner_type_str) == 0 { continue }

        inner_optional := false
        if strings.has_suffix(inner_name, "?") {
            inner_name = inner_name[:len(inner_name) - 1]
            inner_optional = true
        }

        odin_type, is_snippet := convert_ts_type(inner_type_str)
        if inner_optional && !is_snippet {
            odin_type = strings.concatenate({"Maybe(", odin_type, ")"})
        }

        append(&inner_fields, ast.Prop_Field{
            name       = inner_name,
            type_expr  = odin_type,
            is_snippet = is_snippet,
        })
    }

    // Store inline struct
    append(&props.inline_structs, ast.Inline_Struct{
        name   = struct_name,
        fields = inner_fields,
    })

    // Return the type reference
    if is_array {
        return strings.concatenate({"[]", struct_name})
    }
    return struct_name
}

// find_matching_brace finds the index of the closing '}' that matches the opening '{' at pos.
find_matching_brace :: proc(s: string, pos: int) -> int {
    depth := 0
    for i := pos; i < len(s); i += 1 {
        if s[i] == '{' { depth += 1 }
        else if s[i] == '}' {
            depth -= 1
            if depth == 0 { return i }
        }
    }
    return -1
}

// capitalize_first returns a string with the first letter uppercased.
capitalize_first :: proc(s: string) -> string {
    if len(s) == 0 { return s }
    if s[0] >= 'a' && s[0] <= 'z' {
        buf := make([]byte, len(s))
        buf[0] = s[0] - 32
        for i := 1; i < len(s); i += 1 {
            buf[i] = s[i]
        }
        return string(buf)
    }
    return s
}

// convert_ts_type converts a TypeScript type expression to an Odin type expression.
// Returns the Odin type string and whether it's a snippet type.
convert_ts_type :: proc(ts_type: string) -> (odin_type: string, is_snippet: bool) {
    t := strings.trim_space(ts_type)

    // Snippet type
    if t == "Snippet" {
        return "proc(w: io.Writer)", true
    }

    // Type | null  or  Type | undefined  → Maybe(Type)
    if strings.contains(t, "|") {
        parts := strings.split(t, "|")
        defer delete(parts)
        // Find the non-null/non-undefined part
        real_type := ""
        has_null := false
        for part in parts {
            p := strings.trim_space(part)
            if p == "null" || p == "undefined" {
                has_null = true
            } else {
                real_type = p
            }
        }
        if has_null && len(real_type) > 0 {
            inner, _ := convert_ts_type(real_type)
            return strings.concatenate({"Maybe(", inner, ")"}), false
        }
        // If no null, just convert the first type
        if len(real_type) > 0 {
            return convert_ts_type(real_type)
        }
    }

    // Array type: Type[]
    if strings.has_suffix(t, "[]") {
        inner_ts := t[:len(t) - 2]
        inner, _ := convert_ts_type(inner_ts)
        return strings.concatenate({"[]", inner}), false
    }

    // Primitive types
    switch t {
    case "string":
        return "string", false
    case "number":
        return "i64", false
    case "boolean":
        return "bool", false
    }

    // Unknown type — pass through as-is
    return t, false
}
