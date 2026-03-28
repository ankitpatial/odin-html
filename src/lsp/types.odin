// src/lsp/types.odin
package lsp

import "core:encoding/json"
import "core:strings"

// ---- LSP Protocol Types ----

Position :: struct {
	line:      int,
	character: int,
}

Range :: struct {
	start: Position,
	end:   Position,
}

Diagnostic :: struct {
	range:    Range,
	severity: int,
	message:  string,
	source:   string,
}

// Diagnostic severity constants
SEVERITY_ERROR       :: 1
SEVERITY_WARNING     :: 2
SEVERITY_INFORMATION :: 3
SEVERITY_HINT        :: 4

// ---- URI Helpers ----

// uri_to_path converts a file:// URI to a local file path.
// e.g. "file:///Users/foo/bar.ohtml" -> "/Users/foo/bar.ohtml"
uri_to_path :: proc(uri: string) -> string {
	if strings.has_prefix(uri, "file://") {
		return uri[len("file://"):]
	}
	return uri
}

// path_to_uri converts a local file path to a file:// URI.
// e.g. "/Users/foo/bar.ohtml" -> "file:///Users/foo/bar.ohtml"
path_to_uri :: proc(path: string) -> string {
	return strings.concatenate({"file://", path})
}

// ---- JSON Helpers ----

// Extract a string from a json.Value, returns empty string if not a string.
json_get_string :: proc(val: json.Value) -> string {
	if s, ok := val.(json.String); ok {
		return s
	}
	return ""
}

// Extract an object from a json.Value, returns nil if not an object.
json_get_object :: proc(val: json.Value) -> (json.Object, bool) {
	if obj, ok := val.(json.Object); ok {
		return obj, true
	}
	return nil, false
}

// Get a string field from a json.Object.
json_object_get_string :: proc(obj: json.Object, key: string) -> string {
	if val, ok := obj[key]; ok {
		return json_get_string(val)
	}
	return ""
}

// Get an object field from a json.Object.
json_object_get_object :: proc(obj: json.Object, key: string) -> (json.Object, bool) {
	if val, ok := obj[key]; ok {
		return json_get_object(val)
	}
	return nil, false
}

// Get a number field from a json.Object as int.
json_object_get_int :: proc(obj: json.Object, key: string) -> int {
	if val, ok := obj[key]; ok {
		#partial switch v in val {
		case json.Float:
			return int(v)
		case json.Integer:
			return int(v)
		}
	}
	return 0
}

// Convert a Diagnostic to a json.Value (json.Object).
diagnostic_to_json :: proc(d: Diagnostic) -> json.Value {
	range_obj := json.Object{}
	start_obj := json.Object{}
	start_obj["line"] = json.Value(i64(d.range.start.line))
	start_obj["character"] = json.Value(i64(d.range.start.character))
	end_obj := json.Object{}
	end_obj["line"] = json.Value(i64(d.range.end.line))
	end_obj["character"] = json.Value(i64(d.range.end.character))
	range_obj["start"] = json.Value(start_obj)
	range_obj["end"] = json.Value(end_obj)

	diag := json.Object{}
	diag["range"] = json.Value(range_obj)
	diag["severity"] = json.Value(i64(d.severity))
	diag["message"] = json.Value(d.message)
	diag["source"] = json.Value(d.source)

	return json.Value(diag)
}
