// src/lsp/completion.odin
package lsp

import "core:encoding/json"

// handle_completion will be fully implemented in Task 7.
// For now it returns an empty completion list.
handle_completion :: proc(server: ^Server, id: json.Value, params: json.Value) {
	items := json.Array{}

	result := json.Object{}
	result["isIncomplete"] = json.Value(false)
	result["items"] = json.Value(items)

	write_response(id, json.Value(result))
}
