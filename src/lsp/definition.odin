// src/lsp/definition.odin
package lsp

import "core:encoding/json"
import "core:os"
import "core:strings"

import "../ast"

// handle_definition handles textDocument/definition requests.
// When the cursor is on a Component node, it resolves the component's import
// to a file path and returns a Location pointing to that file.
handle_definition :: proc(server: ^Server, id: json.Value, params: json.Value) {
	params_obj, ok := json_get_object(params)
	if !ok {
		write_response(id, json.Value(nil))
		return
	}

	// Extract URI
	td_obj, td_ok := json_object_get_object(params_obj, "textDocument")
	if !td_ok {
		write_response(id, json.Value(nil))
		return
	}
	uri := json_object_get_string(td_obj, "uri")

	// Extract position (0-indexed from client, convert to 1-indexed for AST)
	pos_obj, pos_ok := json_object_get_object(params_obj, "position")
	if !pos_ok {
		write_response(id, json.Value(nil))
		return
	}
	target_line := json_object_get_int(pos_obj, "line") + 1
	// target_col not needed for line-based matching but extracted for completeness
	// target_col := json_object_get_int(pos_obj, "character") + 1

	doc, doc_ok := get_document(&server.document_store, uri)
	if !doc_ok {
		write_response(id, json.Value(nil))
		return
	}

	parsed_doc, has_parsed := doc.parsed.?
	if !has_parsed {
		write_response(id, json.Value(nil))
		return
	}

	// Find component at position
	comp := find_component_at(&parsed_doc, target_line)
	if comp == nil {
		write_response(id, json.Value(nil))
		return
	}

	// Resolve component import path
	import_path := resolve_component_import(&parsed_doc, comp.pkg, server.root_path, uri_to_path(uri))
	if len(import_path) == 0 {
		write_response(id, json.Value(nil))
		return
	}

	// Find the .ohtml file
	comp_file := find_component_file(server.root_path, import_path, comp.name)
	if len(comp_file) == 0 {
		write_response(id, json.Value(nil))
		return
	}

	// Build Location response (go to line 0, col 0 of target file)
	start_obj := json.Object{}
	start_obj["line"] = json.Value(i64(0))
	start_obj["character"] = json.Value(i64(0))
	end_obj := json.Object{}
	end_obj["line"] = json.Value(i64(0))
	end_obj["character"] = json.Value(i64(0))
	range_obj := json.Object{}
	range_obj["start"] = json.Value(start_obj)
	range_obj["end"] = json.Value(end_obj)

	location := json.Object{}
	location["uri"] = json.Value(path_to_uri(comp_file))
	location["range"] = json.Value(range_obj)

	write_response(id, json.Value(location))
}

// find_component_at walks the AST to find a Component node on the given line.
find_component_at :: proc(doc: ^ast.Document, line: int) -> ^ast.Component {
	for &node in doc.children {
		if result := find_component_in_node(&node, line); result != nil {
			return result
		}
	}
	return nil
}

find_component_in_node :: proc(node: ^ast.Node, line: int) -> ^ast.Component {
	#partial switch &n in node {
	case ast.Component:
		if n.pos.line == line { return &n }
		for &child in n.children {
			if r := find_component_in_node(&child, line); r != nil { return r }
		}
	case ast.Element:
		for &child in n.children {
			if r := find_component_in_node(&child, line); r != nil { return r }
		}
	case ast.If_Block:
		for &child in n.children {
			if r := find_component_in_node(&child, line); r != nil { return r }
		}
		for &ei in n.else_ifs {
			for &child in ei.children {
				if r := find_component_in_node(&child, line); r != nil { return r }
			}
		}
		if else_body, has_else := n.else_body.?; has_else {
			for &child in else_body {
				if r := find_component_in_node(&child, line); r != nil { return r }
			}
		}
	case ast.Each_Block:
		for &child in n.children {
			if r := find_component_in_node(&child, line); r != nil { return r }
		}
		if else_body, has_else := n.else_body.?; has_else {
			for &child in else_body {
				if r := find_component_in_node(&child, line); r != nil { return r }
			}
		}
	case ast.Snippet_Def:
		for &child in n.children {
			if r := find_component_in_node(&child, line); r != nil { return r }
		}
	}
	return nil
}

// resolve_component_import finds the import path for a component's package alias.
resolve_component_import :: proc(doc: ^ast.Document, pkg_alias: string, src_dir: string, file_path: string) -> string {
	script, has_script := doc.script.?
	if !has_script { return "" }

	for imp in script.imports {
		alias := ""
		if a, has_a := imp.alias.?; has_a {
			alias = a
		} else {
			alias = lsp_path_base(imp.path)
		}
		if alias == pkg_alias {
			path := imp.path
			if strings.has_prefix(path, ".") {
				rel := lsp_relative_path(src_dir, file_path)
				file_dir := lsp_path_dir(rel)
				path = lsp_resolve_relative_path(file_dir, path)
			}
			return path
		}
	}
	return ""
}

// find_component_file finds the .ohtml file for a component.
find_component_file :: proc(src_dir: string, import_path: string, comp_name: string) -> string {
	candidate := strings.concatenate({src_dir, "/", import_path, "/", comp_name, ".ohtml"})
	if os.exists(candidate) {
		return candidate
	}
	delete(candidate)
	return ""
}
