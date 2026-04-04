// src/resolver/resolver.odin
package resolver

import "core:os"
import "core:fmt"
import "core:strings"
import "../ast"
import "../errors"

// ─── registry ─────────────────────────────────────────────────────────────────

Registry :: struct {
    components: map[string]map[string]bool, // import_path -> {component_names}
}

make_registry :: proc() -> Registry {
    return Registry{
        components = make(map[string]map[string]bool),
    }
}

register_component :: proc(r: ^Registry, pkg_path: string, name: string) {
    if pkg_path not_in r.components {
        r.components[pkg_path] = make(map[string]bool)
    }
    m := &r.components[pkg_path]
    m^[name] = true
}

// ─── resolve ──────────────────────────────────────────────────────────────────

// resolve validates component references in the AST against declared imports
// and the component registry. Returns all collected errors.
resolve :: proc(doc: ^ast.Document, registry: Registry) -> [dynamic]errors.Error {
    errs := make([dynamic]errors.Error)

    // 1. Build import map: alias/pkg_name -> full path
    import_map := make(map[string]string)
    defer delete(import_map)

    if script, ok := doc.script.?; ok {
        for imp in script.imports {
            if alias, has_alias := imp.alias.?; has_alias {
                import_map[alias] = imp.path
            } else {
                // Derive the package name from the last path segment
                pkg_name := last_path_segment(imp.path)
                import_map[pkg_name] = imp.path
            }
        }
    }

    // 2. Walk AST children recursively
    for node in doc.children {
        resolve_node(node, import_map, registry, doc.file, &errs)
    }

    return errs
}

// ─── node walker ──────────────────────────────────────────────────────────────

resolve_node :: proc(node: ast.Node, import_map: map[string]string, registry: Registry, file: string, errs: ^[dynamic]errors.Error) {
    switch n in node {
    case ast.Component:
        // Check its pkg matches an import and the component exists in the registry.
        // For .svelte files, unresolvable components are skipped (client-only).
        is_svelte := strings.has_suffix(file, ".svelte")
        import_path, pkg_found := import_map[n.pkg]
        if !pkg_found {
            if !is_svelte {
                append(errs, errors.Error{
                    file = file, line = n.pos.line, col = n.pos.col,
                    msg = fmt.tprintf("component package %q is not imported", n.pkg),
                })
            }
        } else {
            if comp_set, path_found := registry.components[import_path]; path_found {
                if !comp_set[n.name] && !is_svelte {
                    append(errs, errors.Error{
                        file = file, line = n.pos.line, col = n.pos.col,
                        msg = fmt.tprintf("component %q not found in package %q", n.name, import_path),
                    })
                }
            } else if !is_svelte {
                append(errs, errors.Error{
                    file = file, line = n.pos.line, col = n.pos.col,
                    msg = fmt.tprintf("component %q not found in package %q", n.name, import_path),
                })
            }
        }
        // Recurse into component children
        for child in n.children {
            resolve_node(child, import_map, registry, file, errs)
        }

    case ast.Element:
        for child in n.children {
            resolve_node(child, import_map, registry, file, errs)
        }

    case ast.If_Block:
        for child in n.children {
            resolve_node(child, import_map, registry, file, errs)
        }
        for else_if in n.else_ifs {
            for child in else_if.children {
                resolve_node(child, import_map, registry, file, errs)
            }
        }
        if else_body, ok := n.else_body.?; ok {
            for child in else_body {
                resolve_node(child, import_map, registry, file, errs)
            }
        }

    case ast.Each_Block:
        for child in n.children {
            resolve_node(child, import_map, registry, file, errs)
        }
        if else_body, ok := n.else_body.?; ok {
            for child in else_body {
                resolve_node(child, import_map, registry, file, errs)
            }
        }

    case ast.Snippet_Def:
        for child in n.children {
            resolve_node(child, import_map, registry, file, errs)
        }

    case ast.Text, ast.Expression, ast.Raw_Html, ast.Render_Call:
        // No component references in these nodes
    }
}

// ─── layout chain ─────────────────────────────────────────────────────────────

// resolve_layout_chain returns the ordered list of layout file paths from
// outermost (views_root) to innermost (page's directory).
resolve_layout_chain :: proc(page_path: string, views_root: string) -> [dynamic]string {
    chain := make([dynamic]string)

    // Normalise paths: trim trailing slashes
    root := strings.trim_right(views_root, "/")
    page := page_path

    // Get the directory containing the page file
    page_dir := dir_of(page)

    // Collect directory levels from views_root down to page_dir
    // First, verify page_dir is inside views_root
    if !strings.has_prefix(page_dir, root) {
        return chain
    }

    // Build list of directories from root to page_dir
    dirs := make([dynamic]string)
    defer delete(dirs)

    // Start with root
    append(&dirs, root)

    // Get the relative path from root to page_dir
    rel := page_dir[len(root):]
    rel = strings.trim_left(rel, "/")

    if len(rel) > 0 {
        // Split by "/" and walk down
        parts := strings.split(rel, "/")
        defer delete(parts)

        current := root
        for part in parts {
            if len(part) == 0 { continue }
            current = strings.concatenate([]string{current, "/", part})
            append(&dirs, current)
        }
    }

    // Check each directory for +layout.ohtml or +layout.svelte.
    // A (group) directory with a layout resets the chain — the group layout
    // replaces all parent layouts (SvelteKit convention).
    for d, i in dirs {
        layout_path := strings.concatenate([]string{d, "/+layout.ohtml"})
        layout_svelte_path := strings.concatenate([]string{d, "/+layout.svelte"})
        // Prefer .ohtml; fall back to .svelte
        found_path: string
        if os.exists(layout_path) {
            found_path = layout_path
        } else if os.exists(layout_svelte_path) {
            found_path = layout_svelte_path
        }
        if len(found_path) > 0 {
            // If this directory is a (group), clear prior layouts — group layout replaces parents.
            if i > 0 {
                base := last_segment(d)
                if len(base) > 2 && base[0] == '(' && base[len(base) - 1] == ')' {
                    clear(&chain)
                }
            }
            append(&chain, found_path)
        }
    }

    return chain
}

// last_segment returns the final component of a slash-separated path.
last_segment :: proc(path: string) -> string {
    idx := strings.last_index_byte(path, '/')
    if idx < 0 { return path }
    return path[idx + 1:]
}

// ─── helpers ──────────────────────────────────────────────────────────────────

// last_path_segment returns the final component of a slash-separated path.
// e.g. "components/card" -> "card"
last_path_segment :: proc(path: string) -> string {
    idx := strings.last_index(path, "/")
    if idx < 0 {
        return path
    }
    return path[idx+1:]
}

// dir_of returns the directory portion of a file path.
// e.g. "views/about/+page.ohtml" -> "views/about"
dir_of :: proc(path: string) -> string {
    idx := strings.last_index(path, "/")
    if idx < 0 {
        return "."
    }
    return path[:idx]
}
