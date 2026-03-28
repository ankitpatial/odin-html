// src/lsp/definition.odin
package lsp

import "core:encoding/json"

// handle_definition will be fully implemented in Task 6.
// For now it returns null (no result).
handle_definition :: proc(server: ^Server, id: json.Value, params: json.Value) {
	write_response(id, json.Value(nil))
}
