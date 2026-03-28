// src/lsp/completion.odin
package lsp

import "core:encoding/json"
import "core:os"
import "core:strings"

import "../ast"
import "../parser"

// handle_completion handles textDocument/completion requests.
// It provides two kinds of completions:
// 1. Component names from the registry (e.g. "card.ProductCard")
// 2. Prop names from component Props structs
handle_completion :: proc(server: ^Server, id: json.Value, params: json.Value) {
	items := json.Array{}

	// 1. Component completions from registry
	for pkg_path, names in server.registry.components {
		pkg_name := lsp_path_base(pkg_path)
		for name, _ in names {
			label := strings.concatenate({pkg_name, ".", name})
			detail := strings.concatenate({"Component from ", pkg_path})

			item := json.Object{}
			item["label"] = json.Value(label)
			item["kind"] = json.Value(i64(COMPLETION_KIND_CLASS))
			item["detail"] = json.Value(detail)
			append(&items, json.Value(item))
		}
	}

	// 2. Prop completions from component Props structs
	for pkg_path, names in server.registry.components {
		pkg_name := lsp_path_base(pkg_path)
		for name, _ in names {
			props := get_component_props(server, pkg_path, name)
			for field in props {
				if field.is_snippet { continue }
				detail := strings.concatenate({pkg_name, ".", name, " prop: ", field.type_expr})
				item := json.Object{}
				item["label"] = json.Value(field.name)
				item["kind"] = json.Value(i64(COMPLETION_KIND_PROPERTY))
				item["detail"] = json.Value(detail)
				append(&items, json.Value(item))
			}
		}
	}

	result := json.Object{}
	result["isIncomplete"] = json.Value(false)
	result["items"] = json.Value(items)

	write_response(id, json.Value(result))
}

COMPLETION_KIND_CLASS    :: 7
COMPLETION_KIND_PROPERTY :: 10

// get_component_props loads a component file and extracts its Props fields.
get_component_props :: proc(server: ^Server, pkg_path: string, comp_name: string) -> [dynamic]ast.Prop_Field {
	empty := make([dynamic]ast.Prop_Field)

	// Try to find the file
	comp_file := find_component_file(server.root_path, pkg_path, comp_name)
	if len(comp_file) == 0 { return empty }

	// Check if already in document store
	comp_uri := path_to_uri(comp_file)
	if doc, ok := get_document(&server.document_store, comp_uri); ok {
		if parsed, has := doc.parsed.?; has {
			if script, has_script := parsed.script.?; has_script {
				if props, has_props := script.props.?; has_props {
					delete(empty)
					return props.fields
				}
			}
		}
		return empty
	}

	// Parse on demand
	src_bytes, read_err := os.read_entire_file_from_path(comp_file, context.allocator)
	if read_err != nil { return empty }
	defer delete(src_bytes)

	parsed_doc, parse_err := parser.parse(string(src_bytes), comp_file)
	if _, has_err := parse_err.?; has_err { return empty }

	if script, has_script := parsed_doc.script.?; has_script {
		if props, has_props := script.props.?; has_props {
			delete(empty)
			return props.fields
		}
	}

	return empty
}
