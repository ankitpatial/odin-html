# OHTML LSP Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an LSP server in Odin that provides diagnostics, go-to-definition, and completions for `.ohtml` files, reusing the existing lexer, parser, and resolver.

**Architecture:** The LSP server runs as a separate `ohtml lsp` command, communicating via JSON-RPC over stdio. It maintains an in-memory document store and component registry. On each file change, it re-parses the file and publishes diagnostics. Go-to-definition resolves component names to `.ohtml` file paths. Completions suggest component names from the registry and prop names from parsed `Props` structs.

**Tech Stack:** Odin (standard library only — `core:encoding/json`, `core:os`, `core:strings`, `core:fmt`), LSP protocol over JSON-RPC/stdio

**Spec:** `docs/superpowers/specs/2026-03-28-ohtml-lsp-zed-extension-design.md` (Phase 2)

---

## File Structure

```
src/lsp/
├── rpc.odin          # JSON-RPC stdio transport (read/write Content-Length framed messages)
├── types.odin        # LSP protocol types (Position, Range, Diagnostic, etc.)
├── server.odin       # Main message loop, dispatch, initialize/shutdown
├── document.odin     # Open document store (URI → content + parsed AST)
├── diagnostics.odin  # Parse files → collect errors → publish LSP diagnostics
├── definition.odin   # Go-to-definition for component references
└── completion.odin   # Component name + prop name completions

src/main.odin         # Add "lsp" command to CLI dispatch

editors/zed/
├── extension.toml    # Add ohtml-lsp as primary language server
└── src/ohtml.rs      # Update to launch ohtml-lsp binary
```

---

## Task 1: JSON-RPC Stdio Transport

**Files:**
- Create: `src/lsp/rpc.odin`

- [ ] **Step 1: Create the rpc package file**

Create `src/lsp/rpc.odin`. This handles reading LSP messages from stdin (Content-Length framed) and writing responses to stdout.

```odin
package lsp

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// ─── reading ────────────────────────────────────────────────────────────────

// read_message reads one LSP message from stdin.
// LSP uses Content-Length: N\r\n\r\n{json body} framing.
// Returns the parsed JSON value, or nil on EOF/error.
read_message :: proc() -> (val: json.Value, ok: bool) {
	// 1. Read headers line by line until empty line
	content_length := -1
	header_buf: [4096]byte
	header_pos := 0

	for {
		// Read one byte at a time to find \r\n
		line_buf: [1024]byte
		line_len := 0

		for {
			n, err := os.read(os.stdin, line_buf[line_len:line_len + 1])
			if n == 0 || err != nil {
				return {}, false
			}
			if line_len > 0 && line_buf[line_len - 1] == '\r' && line_buf[line_len] == '\n' {
				// Found \r\n — line is line_buf[:line_len-1]
				break
			}
			line_len += 1
			if line_len >= len(line_buf) - 1 {
				return {}, false
			}
		}

		line := string(line_buf[:line_len - 1]) // exclude \r

		// Empty line = end of headers
		if len(line) == 0 {
			break
		}

		// Parse Content-Length header
		if strings.has_prefix(line, "Content-Length: ") {
			val_str := line[len("Content-Length: "):]
			cl, parse_ok := strconv.parse_int(val_str)
			if parse_ok {
				content_length = cl
			}
		}
	}

	if content_length < 0 {
		return {}, false
	}

	// 2. Read exactly content_length bytes
	body := make([]byte, content_length)
	defer delete(body)
	total_read := 0
	for total_read < content_length {
		n, err := os.read(os.stdin, body[total_read:])
		if n == 0 || err != nil {
			return {}, false
		}
		total_read += n
	}

	// 3. Parse JSON
	parsed, parse_err := json.parse(body)
	if parse_err != .None {
		return {}, false
	}

	return parsed, true
}

// ─── writing ────────────────────────────────────────────────────────────────

// write_response sends a JSON-RPC response with the given id and result.
write_response :: proc(id: json.Value, result: json.Value) {
	response := json.Object{}
	defer json.destroy(json.Value(response))
	response["jsonrpc"] = json.Value("2.0")
	response["id"] = json.clone(id)
	response["result"] = json.clone(result)
	write_json(response)
}

// write_error_response sends a JSON-RPC error response.
write_error_response :: proc(id: json.Value, code: int, message: string) {
	err_obj := json.Object{}
	err_obj["code"] = json.Value(f64(code))
	err_obj["message"] = json.Value(message)

	response := json.Object{}
	defer json.destroy(json.Value(response))
	response["jsonrpc"] = json.Value("2.0")
	response["id"] = json.clone(id)
	response["error"] = json.Value(err_obj)
	write_json(response)
}

// write_notification sends a JSON-RPC notification (no id).
write_notification :: proc(method: string, params: json.Value) {
	notif := json.Object{}
	defer json.destroy(json.Value(notif))
	notif["jsonrpc"] = json.Value("2.0")
	notif["method"] = json.Value(method)
	notif["params"] = json.clone(params)
	write_json(notif)
}

// write_json marshals a JSON object and writes it with Content-Length framing.
write_json :: proc(obj: json.Object) {
	data, marshal_err := json.marshal(obj, {})
	if marshal_err != nil {
		return
	}
	defer delete(data)

	header := fmt.tprintf("Content-Length: %d\r\n\r\n", len(data))
	os.write(os.stdout, transmute([]byte)header)
	os.write(os.stdout, data)
}
```

- [ ] **Step 2: Test manually with a simple echo**

Create a temporary test in `src/main.odin` by adding an "lsp-test" command that reads one message and echoes it back:

```odin
case "lsp-test":
    msg, ok := lsp.read_message()
    if ok {
        fmt.eprintfln("Got message: %v", msg)
    }
```

Run manually:
```bash
cd src && odin build . -out:../ohtml
printf 'Content-Length: 52\r\n\r\n{"jsonrpc":"2.0","id":1,"method":"initialize"}' | ../ohtml lsp-test
```

Expected: stderr shows the parsed JSON message.

- [ ] **Step 3: Remove test command and commit**

Remove the "lsp-test" case from main.odin.

```bash
git add src/lsp/rpc.odin
git commit -m "feat(lsp): add JSON-RPC stdio transport layer"
```

---

## Task 2: LSP Protocol Types

**Files:**
- Create: `src/lsp/types.odin`

- [ ] **Step 1: Create types file with all needed LSP types**

Create `src/lsp/types.odin`:

```odin
package lsp

// ─── basic types ────────────────────────────────────────────────────────────

Position :: struct {
	line:      int,
	character: int,
}

Range :: struct {
	start: Position,
	end:   Position,
}

Location :: struct {
	uri:   string,
	range: Range,
}

// ─── diagnostics ────────────────────────────────────────────────────────────

Diagnostic :: struct {
	range:    Range,
	severity: int, // 1=Error, 2=Warning, 3=Info, 4=Hint
	source:   string,
	message:  string,
}

SEVERITY_ERROR :: 1
SEVERITY_WARNING :: 2
SEVERITY_INFO :: 3
SEVERITY_HINT :: 4

// ─── completion ─────────────────────────────────────────────────────────────

Completion_Item :: struct {
	label:  string,
	kind:   int,
	detail: string,
}

COMPLETION_KIND_CLASS :: 7     // for components
COMPLETION_KIND_PROPERTY :: 10 // for props

// ─── text document ──────────────────────────────────────────────────────────

Text_Document_Identifier :: struct {
	uri: string,
}

Text_Document_Position :: struct {
	text_document: Text_Document_Identifier,
	position:      Position,
}

// ─── helpers ────────────────────────────────────────────────────────────────

// file_uri_to_path converts a file:// URI to a filesystem path.
// e.g. "file:///Users/foo/bar.ohtml" -> "/Users/foo/bar.ohtml"
file_uri_to_path :: proc(uri: string) -> string {
	if len(uri) > 7 && uri[:7] == "file://" {
		return uri[7:]
	}
	return uri
}

// path_to_file_uri converts a filesystem path to a file:// URI.
// e.g. "/Users/foo/bar.ohtml" -> "file:///Users/foo/bar.ohtml"
path_to_file_uri :: proc(path: string) -> string {
	return fmt.tprintf("file://%s", path)
}
```

- [ ] **Step 2: Commit**

```bash
git add src/lsp/types.odin
git commit -m "feat(lsp): add LSP protocol types"
```

---

## Task 3: Document Store

**Files:**
- Create: `src/lsp/document.odin`

- [ ] **Step 1: Create document store**

Create `src/lsp/document.odin`. This manages open documents and their parsed state.

```odin
package lsp

import ast "../ast"
import errors "../errors"
import parser "../parser"
import resolver "../resolver"

// Stored_Document holds the source text, parsed AST, and any errors for an open file.
Stored_Document :: struct {
	uri:     string,
	path:    string,
	content: string,
	doc:     ast.Document,
	parsed:  bool, // true if doc is valid (no parse error)
}

// Document_Store tracks all open documents and the workspace state.
Document_Store :: struct {
	documents:  map[string]Stored_Document, // uri -> document
	registry:   resolver.Registry,
	src_dir:    string, // workspace root
}

make_document_store :: proc() -> Document_Store {
	return Document_Store{
		documents = make(map[string]Stored_Document),
		registry  = resolver.make_registry(),
	}
}

// open_document adds or updates a document in the store and parses it.
open_document :: proc(store: ^Document_Store, uri: string, content: string) {
	path := file_uri_to_path(uri)

	doc, parse_err := parser.parse(content, path)
	parsed := true
	if _, has_err := parse_err.?; has_err {
		parsed = false
	}

	store.documents[uri] = Stored_Document{
		uri     = uri,
		path    = path,
		content = content,
		doc     = doc,
		parsed  = parsed,
	}
}

// update_document updates content and re-parses.
update_document :: proc(store: ^Document_Store, uri: string, content: string) {
	open_document(store, uri, content)
}

// close_document removes a document from the store.
close_document :: proc(store: ^Document_Store, uri: string) {
	delete_key(&store.documents, uri)
}

// get_document returns the stored document for a URI, or nil.
get_document :: proc(store: ^Document_Store, uri: string) -> ^Stored_Document {
	if uri in store.documents {
		return &store.documents[uri]
	}
	return nil
}
```

- [ ] **Step 2: Commit**

```bash
git add src/lsp/document.odin
git commit -m "feat(lsp): add document store for open file tracking"
```

---

## Task 4: Server Core — Initialize, Shutdown, Message Loop

**Files:**
- Create: `src/lsp/server.odin`
- Modify: `src/main.odin` — add `lsp` command

- [ ] **Step 1: Create server.odin with message loop and initialize handler**

Create `src/lsp/server.odin`:

```odin
package lsp

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

// Server holds the LSP server state.
Server :: struct {
	store:       Document_Store,
	initialized: bool,
	shutdown:    bool,
	root_uri:    string,
}

// run starts the LSP server message loop on stdio.
run :: proc() {
	server := Server{
		store = make_document_store(),
	}

	for {
		msg, ok := read_message()
		if !ok {
			break // stdin closed
		}

		obj, is_obj := msg.(json.Object)
		if !is_obj {
			json.destroy(msg)
			continue
		}

		method_val, has_method := obj["method"]
		if !has_method {
			json.destroy(msg)
			continue
		}
		method, is_str := method_val.(json.String)
		if !is_str {
			json.destroy(msg)
			continue
		}

		id, has_id := obj["id"]
		params, _ := obj["params"]

		switch method {
		case "initialize":
			handle_initialize(&server, id, params)
		case "initialized":
			// Client acknowledged — nothing to do
		case "shutdown":
			server.shutdown = true
			if has_id {
				write_response(id, json.Value(nil))
			}
		case "exit":
			json.destroy(msg)
			code := 0 if server.shutdown else 1
			os.exit(code)
		case "textDocument/didOpen":
			handle_did_open(&server, params)
		case "textDocument/didChange":
			handle_did_change(&server, params)
		case "textDocument/didClose":
			handle_did_close(&server, params)
		case "textDocument/definition":
			handle_definition(&server, id, params)
		case "textDocument/completion":
			handle_completion(&server, id, params)
		}

		json.destroy(msg)
	}
}

// handle_initialize responds with server capabilities.
handle_initialize :: proc(server: ^Server, id: json.Value, params: json.Value) {
	// Extract rootUri from params
	if params_obj, ok := params.(json.Object); ok {
		if root_uri, has := params_obj["rootUri"]; has {
			if uri_str, is_str := root_uri.(json.String); is_str {
				server.root_uri = strings.clone(uri_str)
				server.store.src_dir = file_uri_to_path(uri_str)
			}
		}
	}

	// Build workspace registry
	build_registry(server)

	server.initialized = true

	// Build response
	sync_opts := json.Object{}
	sync_opts["openClose"] = json.Value(true)
	sync_opts["change"] = json.Value(f64(1)) // Full sync

	capabilities := json.Object{}
	capabilities["textDocumentSync"] = json.Value(sync_opts)
	capabilities["definitionProvider"] = json.Value(true)
	capabilities["completionProvider"] = json.Value(json.Object{})

	result := json.Object{}
	result["capabilities"] = json.Value(capabilities)

	write_response(id, json.Value(result))
}

// build_registry discovers all .ohtml files and builds the component registry.
build_registry :: proc(server: ^Server) {
	if len(server.store.src_dir) == 0 {
		return
	}

	files := discover_ohtml_files(server.store.src_dir)
	defer delete(files)

	for file in files {
		if is_page_file(file) || is_layout_file(file) {
			continue
		}
		rel := relative_path(server.store.src_dir, file)
		rel_dir := path_dir(rel)
		comp_name := path_stem(path_base(rel))
		resolver.register_component(&server.store.registry, rel_dir, comp_name)
	}
}

// ─── document sync handlers ─────────────────────────────────────────────────

handle_did_open :: proc(server: ^Server, params: json.Value) {
	params_obj, ok := params.(json.Object)
	if !ok {return}

	td, has_td := params_obj["textDocument"]
	if !has_td {return}
	td_obj, td_ok := td.(json.Object)
	if !td_ok {return}

	uri_val, has_uri := td_obj["uri"]
	if !has_uri {return}
	uri, uri_ok := uri_val.(json.String)
	if !uri_ok {return}

	text_val, has_text := td_obj["text"]
	if !has_text {return}
	text, text_ok := text_val.(json.String)
	if !text_ok {return}

	open_document(&server.store, uri, text)
	publish_diagnostics_for(server, uri)
}

handle_did_change :: proc(server: ^Server, params: json.Value) {
	params_obj, ok := params.(json.Object)
	if !ok {return}

	td, has_td := params_obj["textDocument"]
	if !has_td {return}
	td_obj, td_ok := td.(json.Object)
	if !td_ok {return}

	uri_val, has_uri := td_obj["uri"]
	if !has_uri {return}
	uri, uri_ok := uri_val.(json.String)
	if !uri_ok {return}

	// Full sync: take the last content change
	changes, has_changes := params_obj["contentChanges"]
	if !has_changes {return}
	changes_arr, changes_ok := changes.(json.Array)
	if !changes_ok || len(changes_arr) == 0 {return}

	last_change, lc_ok := changes_arr[len(changes_arr) - 1].(json.Object)
	if !lc_ok {return}
	text_val, has_text := last_change["text"]
	if !has_text {return}
	text, text_ok := text_val.(json.String)
	if !text_ok {return}

	update_document(&server.store, uri, text)
	publish_diagnostics_for(server, uri)
}

handle_did_close :: proc(server: ^Server, params: json.Value) {
	params_obj, ok := params.(json.Object)
	if !ok {return}

	td, has_td := params_obj["textDocument"]
	if !has_td {return}
	td_obj, td_ok := td.(json.Object)
	if !td_ok {return}

	uri_val, has_uri := td_obj["uri"]
	if !has_uri {return}
	uri, uri_ok := uri_val.(json.String)
	if !uri_ok {return}

	close_document(&server.store, uri)

	// Clear diagnostics for closed file
	diag_params := json.Object{}
	diag_params["uri"] = json.Value(uri)
	diag_params["diagnostics"] = json.Value(json.Array{})
	write_notification("textDocument/publishDiagnostics", json.Value(diag_params))
}

// ─── file helpers (reused from main) ────────────────────────────────────────

// These are duplicated from main.odin since they're in the main package.
// In a production codebase these would be in a shared utility package.

discover_ohtml_files :: proc(dir: string) -> [dynamic]string {
	result := make([dynamic]string)
	walk_dir(dir, &result)
	return result
}

walk_dir :: proc(dir: string, result: ^[dynamic]string) {
	handle, err := os.open(dir)
	if err != nil {return}
	defer os.close(handle)

	infos, read_err := os.read_dir(handle, -1, context.allocator)
	if read_err != nil {return}
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

is_page_file :: proc(path: string) -> bool {
	return strings.has_suffix(path, "/+page.ohtml") || path == "+page.ohtml"
}

is_layout_file :: proc(path: string) -> bool {
	return strings.has_suffix(path, "/+layout.ohtml") || path == "+layout.ohtml"
}

relative_path :: proc(base_dir: string, file: string) -> string {
	base := strings.trim_right(base_dir, "/")
	if strings.has_prefix(file, base) {
		rel := file[len(base):]
		return strings.trim_left(rel, "/")
	}
	return file
}

path_dir :: proc(path: string) -> string {
	idx := strings.last_index(path, "/")
	if idx < 0 {return "."}
	return path[:idx]
}

path_base :: proc(path: string) -> string {
	idx := strings.last_index(path, "/")
	if idx < 0 {return path}
	return path[idx + 1:]
}

path_stem :: proc(name: string) -> string {
	idx := strings.last_index(name, ".")
	if idx < 0 {return name}
	return name[:idx]
}

resolve_relative_path :: proc(file_dir: string, rel: string) -> string {
	base_segs := strings.split(file_dir, "/")
	defer delete(base_segs)
	base := make([dynamic]string)
	defer delete(base)
	for s in base_segs {
		if len(s) > 0 && s != "." {
			append(&base, s)
		}
	}
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
```

- [ ] **Step 2: Add `lsp` command to main.odin**

Add to the switch in `main()` in `src/main.odin`, before the default case:

```odin
case "lsp":
    lsp.run()
```

And add the import at the top:

```odin
import lsp "lsp"
```

- [ ] **Step 3: Build and test initialize handshake**

```bash
cd src && odin build . -out:../ohtml
```

Test with a manual initialize request:

```bash
printf 'Content-Length: 118\r\n\r\n{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":1,"rootUri":"file:///tmp","capabilities":{}}}' | ../ohtml lsp 2>/dev/null
```

Expected: stdout contains a `Content-Length:` header followed by JSON with `capabilities` including `textDocumentSync`, `definitionProvider`, and `completionProvider`.

- [ ] **Step 4: Commit**

```bash
git add src/lsp/server.odin src/main.odin
git commit -m "feat(lsp): add server core with initialize/shutdown and document sync"
```

---

## Task 5: Diagnostics

**Files:**
- Create: `src/lsp/diagnostics.odin`

- [ ] **Step 1: Create diagnostics module**

Create `src/lsp/diagnostics.odin`:

```odin
package lsp

import "core:encoding/json"
import "core:strings"

import errors "../errors"
import parser "../parser"
import resolver "../resolver"

// publish_diagnostics_for parses the document at uri and publishes diagnostics.
publish_diagnostics_for :: proc(server: ^Server, uri: string) {
	stored := get_document(&server.store, uri)
	if stored == nil {return}

	diags := make([dynamic]json.Value)
	defer delete(diags)

	// 1. Collect parse errors
	_, parse_err := parser.parse(stored.content, stored.path)
	if err_val, has_err := parse_err.?; has_err {
		append(&diags, error_to_diagnostic(err_val))
	}

	// 2. If parsed OK, collect resolver errors
	if stored.parsed {
		doc := &stored.doc

		// Normalize imports before resolution
		if script, ok := &doc.script.?; ok {
			rel := relative_path(server.store.src_dir, stored.path)
			file_dir := path_dir(rel)
			for &imp in script.imports {
				if strings.has_prefix(imp.path, ".") {
					imp.path = resolve_relative_path(file_dir, imp.path)
				}
			}
		}

		resolve_errs := resolver.resolve(doc, server.store.registry)
		for e in resolve_errs {
			append(&diags, error_to_diagnostic(e))
		}
		delete(resolve_errs)
	}

	// 3. Publish
	params := json.Object{}
	params["uri"] = json.Value(uri)
	params["diagnostics"] = json.Value(json.Array(diags[:]))

	write_notification("textDocument/publishDiagnostics", json.Value(params))
}

// error_to_diagnostic converts an errors.Error to an LSP Diagnostic JSON value.
error_to_diagnostic :: proc(e: errors.Error) -> json.Value {
	// Convert 1-indexed line/col to 0-indexed
	line := max(e.line - 1, 0)
	col := max(e.col - 1, 0)

	start := json.Object{}
	start["line"] = json.Value(f64(line))
	start["character"] = json.Value(f64(col))

	end := json.Object{}
	end["line"] = json.Value(f64(line))
	end["character"] = json.Value(f64(col))

	range_obj := json.Object{}
	range_obj["start"] = json.Value(start)
	range_obj["end"] = json.Value(end)

	diag := json.Object{}
	diag["range"] = json.Value(range_obj)
	diag["severity"] = json.Value(f64(SEVERITY_ERROR))
	diag["source"] = json.Value("ohtml")
	diag["message"] = json.Value(e.msg)

	return json.Value(diag)
}
```

- [ ] **Step 2: Build and test**

```bash
cd src && odin build . -out:../ohtml
```

Test by opening a file with a parse error and checking that diagnostics are published. Create a test script:

```bash
cat <<'SCRIPT' > /tmp/test_diag.sh
#!/bin/bash
# Send initialize
printf 'Content-Length: 118\r\n\r\n{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":1,"rootUri":"file:///tmp","capabilities":{}}}'
# Send initialized
printf 'Content-Length: 52\r\n\r\n{"jsonrpc":"2.0","method":"initialized","params":{}}'
# Send didOpen with broken content
printf 'Content-Length: 187\r\n\r\n{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"file:///tmp/test.ohtml","languageId":"ohtml","version":1,"text":"<div>\\n{#if}\\n{/if}\\n</div>"}}}'
sleep 1
SCRIPT
chmod +x /tmp/test_diag.sh
/tmp/test_diag.sh | ../ohtml lsp 2>/dev/null
```

Expected: stdout includes a `textDocument/publishDiagnostics` notification with diagnostic(s).

- [ ] **Step 3: Commit**

```bash
git add src/lsp/diagnostics.odin
git commit -m "feat(lsp): add diagnostics publishing on file open/change"
```

---

## Task 6: Go-to-Definition

**Files:**
- Create: `src/lsp/definition.odin`

- [ ] **Step 1: Create definition module**

Create `src/lsp/definition.odin`. When the cursor is on a component name (`<pkg.ComponentName>`), this resolves it to the component's `.ohtml` file.

```odin
package lsp

import "core:encoding/json"
import "core:strings"

import ast "../ast"

// handle_definition handles textDocument/definition requests.
handle_definition :: proc(server: ^Server, id: json.Value, params: json.Value) {
	params_obj, ok := params.(json.Object)
	if !ok {
		write_response(id, json.Value(nil))
		return
	}

	// Extract URI and position
	td, has_td := params_obj["textDocument"]
	if !has_td {
		write_response(id, json.Value(nil))
		return
	}
	td_obj, td_ok := td.(json.Object)
	if !td_ok {
		write_response(id, json.Value(nil))
		return
	}
	uri_val, _ := td_obj["uri"]
	uri, _ := uri_val.(json.String)

	pos_val, _ := params_obj["position"]
	pos_obj, _ := pos_val.(json.Object)
	line_val, _ := pos_obj["line"]
	char_val, _ := pos_obj["character"]
	line_f, _ := line_val.(json.Float)
	char_f, _ := char_val.(json.Float)
	target_line := int(line_f) + 1 // convert to 1-indexed
	target_col := int(char_f) + 1

	stored := get_document(&server.store, uri)
	if stored == nil || !stored.parsed {
		write_response(id, json.Value(nil))
		return
	}

	// Find component at position
	comp := find_component_at(&stored.doc, target_line, target_col)
	if comp == nil {
		write_response(id, json.Value(nil))
		return
	}

	// Resolve import path
	import_path := ""
	if script, has_script := stored.doc.script.?; has_script {
		for imp in script.imports {
			alias := ""
			if a, has_alias := imp.alias.?; has_alias {
				alias = a
			} else {
				// Use last path segment as implicit alias
				alias = path_base(imp.path)
			}
			if alias == comp.pkg {
				import_path = imp.path
				break
			}
		}
	}

	if len(import_path) == 0 {
		write_response(id, json.Value(nil))
		return
	}

	// Normalize relative import
	if strings.has_prefix(import_path, ".") {
		rel := relative_path(server.store.src_dir, stored.path)
		file_dir := path_dir(rel)
		import_path = resolve_relative_path(file_dir, import_path)
	}

	// Find the .ohtml file for this component
	comp_file := find_component_file(server.store.src_dir, import_path, comp.name)
	if len(comp_file) == 0 {
		write_response(id, json.Value(nil))
		return
	}

	// Build Location response
	start := json.Object{}
	start["line"] = json.Value(f64(0))
	start["character"] = json.Value(f64(0))
	end := json.Object{}
	end["line"] = json.Value(f64(0))
	end["character"] = json.Value(f64(0))
	range_obj := json.Object{}
	range_obj["start"] = json.Value(start)
	range_obj["end"] = json.Value(end)

	location := json.Object{}
	location["uri"] = json.Value(path_to_file_uri(comp_file))
	location["range"] = json.Value(range_obj)

	write_response(id, json.Value(location))
}

// find_component_at walks the AST to find a Component node at the given position.
find_component_at :: proc(doc: ^ast.Document, line: int, col: int) -> ^ast.Component {
	for &node in doc.children {
		if result := find_component_in_node(&node, line, col); result != nil {
			return result
		}
	}
	return nil
}

find_component_in_node :: proc(node: ^ast.Node, line: int, col: int) -> ^ast.Component {
	switch &n in node {
	case ast.Component:
		if n.pos.line == line {
			return &n
		}
		for &child in n.children {
			if result := find_component_in_node(&child, line, col); result != nil {
				return result
			}
		}
	case ast.Element:
		for &child in n.children {
			if result := find_component_in_node(&child, line, col); result != nil {
				return result
			}
		}
	case ast.If_Block:
		for &child in n.children {
			if result := find_component_in_node(&child, line, col); result != nil {
				return result
			}
		}
		for &ei in n.else_ifs {
			for &child in ei.children {
				if result := find_component_in_node(&child, line, col); result != nil {
					return result
				}
			}
		}
		if else_body, has_else := n.else_body.?; has_else {
			for &child in else_body {
				if result := find_component_in_node(&child, line, col); result != nil {
					return result
				}
			}
		}
	case ast.Each_Block:
		for &child in n.children {
			if result := find_component_in_node(&child, line, col); result != nil {
				return result
			}
		}
		if else_body, has_else := n.else_body.?; has_else {
			for &child in else_body {
				if result := find_component_in_node(&child, line, col); result != nil {
					return result
				}
			}
		}
	case ast.Snippet_Def:
		for &child in n.children {
			if result := find_component_in_node(&child, line, col); result != nil {
				return result
			}
		}
	case ast.Text, ast.Expression, ast.Raw_Html, ast.Render_Call:
		// Leaf nodes — no components inside
	}
	return nil
}

// find_component_file returns the absolute path to a component's .ohtml file.
find_component_file :: proc(src_dir: string, import_path: string, comp_name: string) -> string {
	// Component file is at: src_dir/import_path/CompName.ohtml
	candidate := strings.concatenate({src_dir, "/", import_path, "/", comp_name, ".ohtml"})
	// Check if file exists
	handle, err := os.open(candidate)
	if err != nil {
		delete(candidate)
		return ""
	}
	os.close(handle)
	return candidate
}
```

- [ ] **Step 2: Build and verify**

```bash
cd src && odin build . -out:../ohtml
```

Expected: builds without errors.

- [ ] **Step 3: Commit**

```bash
git add src/lsp/definition.odin
git commit -m "feat(lsp): add go-to-definition for component references"
```

---

## Task 7: Completions

**Files:**
- Create: `src/lsp/completion.odin`

- [ ] **Step 1: Create completion module**

Create `src/lsp/completion.odin`. Provides component name completions from the registry and prop completions from parsed `Props` structs.

```odin
package lsp

import "core:encoding/json"
import "core:os"
import "core:strings"

import ast "../ast"
import parser "../parser"

// handle_completion handles textDocument/completion requests.
handle_completion :: proc(server: ^Server, id: json.Value, params: json.Value) {
	items := make([dynamic]json.Value)
	defer delete(items)

	// 1. Component completions from registry
	for pkg_path, names in server.store.registry.components {
		pkg_name := path_base(pkg_path)
		for name, _ in names {
			label := strings.concatenate({pkg_name, ".", name})

			item := json.Object{}
			item["label"] = json.Value(label)
			item["kind"] = json.Value(f64(COMPLETION_KIND_CLASS))
			item["detail"] = json.Value(strings.concatenate({"Component from ", pkg_path}))

			append(&items, json.Value(item))
		}
	}

	// 2. Prop completions — if cursor is inside a component tag, suggest props
	//    For now, we provide all component props as general completions.
	//    A more precise implementation would check cursor context.
	for pkg_path, names in server.store.registry.components {
		for name, _ in names {
			// Try to load and parse the component file to get its Props
			comp_file := find_component_file(server.store.src_dir, pkg_path, name)
			if len(comp_file) == 0 {continue}

			// Check if already in store
			comp_uri := path_to_file_uri(comp_file)
			stored := get_document(&server.store, comp_uri)

			props_fields: [dynamic]ast.Prop_Field
			if stored != nil && stored.parsed {
				if props, has_props := stored.doc.script.?.props.?; has_props {
					props_fields = props.fields
				}
			} else {
				// Parse on demand
				src_bytes, read_err := os.read_entire_file_from_path(comp_file, context.allocator)
				if read_err != nil {continue}
				defer delete(src_bytes)

				doc, parse_err := parser.parse(string(src_bytes), comp_file)
				if _, has_err := parse_err.?; has_err {continue}

				if script, has_script := doc.script.?; has_script {
					if props, has_props := script.props.?; has_props {
						props_fields = props.fields
					}
				}
			}

			pkg_name := path_base(pkg_path)
			for field in props_fields {
				// Skip snippet/children props
				if field.is_snippet {continue}

				item := json.Object{}
				item["label"] = json.Value(field.name)
				item["kind"] = json.Value(f64(COMPLETION_KIND_PROPERTY))
				item["detail"] = json.Value(strings.concatenate({
					pkg_name, ".", name, " prop: ", field.type_expr,
				}))

				append(&items, json.Value(item))
			}
		}
	}

	result := json.Object{}
	result["isIncomplete"] = json.Value(false)
	result["items"] = json.Value(json.Array(items[:]))

	write_response(id, json.Value(result))
}
```

- [ ] **Step 2: Build and verify**

```bash
cd src && odin build . -out:../ohtml
```

Expected: builds without errors.

- [ ] **Step 3: Commit**

```bash
git add src/lsp/completion.odin
git commit -m "feat(lsp): add component and prop completions"
```

---

## Task 8: Update Zed Extension to Use ohtml-lsp

**Files:**
- Modify: `editors/zed/extension.toml`
- Modify: `editors/zed/src/ohtml.rs`

- [ ] **Step 1: Add ohtml-lsp as the primary language server**

Update `editors/zed/extension.toml` to declare both OLS and ohtml-lsp:

```toml
id = "ohtml"
name = "OHTML"
version = "0.2.0"
schema_version = 1
authors = ["Ankit Patial"]
description = "Odin HTML template language support with syntax highlighting, diagnostics, and completions"
repository = "https://github.com/ankitpatial/odin-html"

[language_servers.ohtml-lsp]
name = "OHTML LSP"
language = "OHTML"

[grammars.ohtml]
repository = "file:///Users/ankitpatial/projects/github.com/ankitpatial/odin-html"
rev = "main"
path = "tree-sitter-ohtml"
```

- [ ] **Step 2: Update Rust adapter to launch ohtml-lsp**

Replace the OLS download logic in `editors/zed/src/ohtml.rs` with ohtml-lsp:

```rust
use zed_extension_api::{self as zed, settings::LspSettings};

struct OhtmlExtension;

impl zed::Extension for OhtmlExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<zed::Command> {
        // Check user-configured path
        let settings = LspSettings::for_worktree(language_server_id.as_ref(), worktree)?;
        if let Some(binary_settings) = settings.binary.as_ref() {
            if let Some(path) = binary_settings.path.as_ref() {
                return Ok(zed::Command {
                    command: path.clone(),
                    args: vec!["lsp".to_string()],
                    env: Default::default(),
                });
            }
        }

        // Check PATH for ohtml binary
        if let Some(path) = worktree.which("ohtml") {
            return Ok(zed::Command {
                command: path,
                args: vec!["lsp".to_string()],
                env: Default::default(),
            });
        }

        Err("ohtml binary not found in PATH. Build from source: cd src && odin build . -out:ohtml".to_string())
    }
}

zed::register_extension!(OhtmlExtension);
```

- [ ] **Step 3: Build and test**

Build the ohtml binary and add to PATH:

```bash
cd src && odin build . -out:../ohtml
# Ensure ../ohtml is on PATH or use absolute path in Zed settings
```

Reinstall the Zed dev extension and open an `.ohtml` file. Verify:
- Diagnostics appear for parse errors
- Go-to-definition works on component names (Cmd+Click)
- Completions appear when typing

- [ ] **Step 4: Commit**

```bash
git add editors/zed/extension.toml editors/zed/src/ohtml.rs
git commit -m "feat(zed): switch to ohtml-lsp for diagnostics, definition, and completions"
```

---

## Task 9: Integration Testing

- [ ] **Step 1: Test diagnostics with real example files**

Build and run:
```bash
cd src && odin build . -out:../ohtml
```

Create a test `.ohtml` file with a known error:

```bash
cat > /tmp/test_broken.ohtml << 'EOF'
<script lang="odin">
import "nonexistent/package"

Props :: struct {
    name: string,
}
</script>
<div>{name}</div>
<nonexistent.Foo />
EOF
```

Send it to the LSP and verify diagnostics are published for the unresolved component.

- [ ] **Step 2: Test go-to-definition with the example project**

Open `examples/ecomm/views/+page.ohtml` in Zed. Cmd+Click on `<product_card.ProductCard`. Verify it navigates to `examples/ecomm/components/product_card/ProductCard.ohtml`.

- [ ] **Step 3: Test completions**

In any `.ohtml` file in the examples project, trigger completions. Verify:
- Component names like `badge.Badge`, `price.Price`, `product_card.ProductCard` appear
- Prop names like `label`, `variant`, `amount`, `on_sale` appear

- [ ] **Step 4: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix(lsp): address issues found during integration testing"
```

---

## Task Dependency Graph

```
Task 1 (JSON-RPC transport)
  └── Task 2 (LSP types)
        └── Task 3 (Document store)
              └── Task 4 (Server core + initialize)
                    ├── Task 5 (Diagnostics)
                    ├── Task 6 (Go-to-definition)
                    └── Task 7 (Completions)
                          └── Task 8 (Zed extension update)
                                └── Task 9 (Integration testing)
```

Tasks 5, 6, 7 can be parallelized after Task 4.
