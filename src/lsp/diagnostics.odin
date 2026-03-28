// src/lsp/diagnostics.odin
package lsp

import "core:encoding/json"

// publish_diagnostics_for publishes LSP diagnostics for a document.
// It converts parse_errors (parser + resolver errors) into LSP Diagnostic
// objects and sends them via a textDocument/publishDiagnostics notification.
publish_diagnostics_for :: proc(server: ^Server, uri: string) {
	doc, ok := get_document(&server.document_store, uri)
	if !ok { return }

	diags := json.Array{}
	for e in doc.parse_errors {
		d := Diagnostic{
			range = Range{
				start = Position{ line = max(e.line - 1, 0), character = max(e.col - 1, 0) },
				end   = Position{ line = max(e.line - 1, 0), character = max(e.col - 1, 0) },
			},
			severity = SEVERITY_ERROR,
			message  = e.msg,
			source   = "ohtml",
		}
		append(&diags, diagnostic_to_json(d))
	}

	params := json.Object{}
	params["uri"] = json.Value(uri)
	params["diagnostics"] = json.Value(diags)

	write_notification("textDocument/publishDiagnostics", json.Value(params))
}
