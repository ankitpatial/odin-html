// src/lsp/server.odin
package lsp

import "core:encoding/json"
import "core:os"
import "core:strings"

import "../resolver"

// Server holds all LSP server state.
Server :: struct {
	initialized:    bool,
	shutdown:       bool,
	root_uri:       string,
	root_path:      string,
	document_store: Document_Store,
	registry:       resolver.Registry,
}

// run is the main entry point for the LSP server.
// It reads JSON-RPC messages from stdin and dispatches them.
run :: proc() {
	server := Server{
		document_store = make_document_store(),
		registry       = resolver.make_registry(),
	}

	log("ohtml-lsp: server starting")

	for {
		msg, ok := read_message()
		if !ok {
			log("ohtml-lsp: stdin closed, exiting")
			break
		}

		obj, is_obj := json_get_object(msg)
		if !is_obj {
			log("ohtml-lsp: received non-object message, ignoring")
			continue
		}

		method := json_object_get_string(obj, "method")
		id, has_id := obj["id"]
		params_val, has_params := obj["params"]
		params: json.Value = has_params ? params_val : json.Value(nil)

		if len(method) == 0 {
			// Response or unknown message, ignore
			continue
		}

		log("ohtml-lsp: received method=%s", method)

		switch method {
		case "initialize":
			if has_id {
				handle_initialize(&server, id, params)
			}
		case "initialized":
			server.initialized = true
			log("ohtml-lsp: initialized")
		case "shutdown":
			server.shutdown = true
			if has_id {
				write_response(id, json.Value(nil))
			}
			log("ohtml-lsp: shutdown requested")
		case "exit":
			exit_code := 0 if server.shutdown else 1
			log("ohtml-lsp: exiting with code %d", exit_code)
			os.exit(exit_code)
		case "textDocument/didOpen":
			handle_did_open(&server, params)
		case "textDocument/didChange":
			handle_did_change(&server, params)
		case "textDocument/didClose":
			handle_did_close(&server, params)
		case "textDocument/definition":
			if has_id {
				handle_definition(&server, id, params)
			}
		case "textDocument/completion":
			if has_id {
				handle_completion(&server, id, params)
			}
		case:
			// Unknown method
			if has_id {
				// Request with unknown method: respond with MethodNotFound
				write_error(id, -32601, "Method not found")
			}
		}

		if server.shutdown {
			// After responding to shutdown, keep looping for exit
		}
	}
}

// ---- Request Handlers ----

handle_initialize :: proc(server: ^Server, id: json.Value, params: json.Value) {
	if params_obj, ok := json_get_object(params); ok {
		server.root_uri = json_object_get_string(params_obj, "rootUri")
		server.root_path = uri_to_path(server.root_uri)
		log("ohtml-lsp: rootUri=%s rootPath=%s", server.root_uri, server.root_path)

		// Build component registry from workspace
		build_registry(server)
	}

	// Build capabilities
	text_sync := json.Object{}
	text_sync["openClose"] = json.Value(true)
	text_sync["change"] = json.Value(i64(1)) // Full sync

	comp_provider := json.Object{}
	triggers := json.Array{}
	append(&triggers, json.Value("<"))
	append(&triggers, json.Value("."))
	comp_provider["triggerCharacters"] = json.Value(triggers)

	caps := json.Object{}
	caps["textDocumentSync"] = json.Value(text_sync)
	caps["definitionProvider"] = json.Value(true)
	caps["completionProvider"] = json.Value(comp_provider)

	server_info := json.Object{}
	server_info["name"] = json.Value("ohtml-lsp")
	server_info["version"] = json.Value("0.1.0")

	result := json.Object{}
	result["capabilities"] = json.Value(caps)
	result["serverInfo"] = json.Value(server_info)

	write_response(id, json.Value(result))
}

handle_did_open :: proc(server: ^Server, params: json.Value) {
	params_obj, ok := json_get_object(params)
	if !ok {return}

	td_obj, td_ok := json_object_get_object(params_obj, "textDocument")
	if !td_ok {return}

	uri := json_object_get_string(td_obj, "uri")
	text := json_object_get_string(td_obj, "text")

	if len(uri) == 0 {return}

	log("ohtml-lsp: didOpen uri=%s", uri)
	open_document(&server.document_store, uri, text, server.registry, server.root_path)
	publish_diagnostics_for(server, uri)
}

handle_did_change :: proc(server: ^Server, params: json.Value) {
	params_obj, ok := json_get_object(params)
	if !ok {return}

	td_obj, td_ok := json_object_get_object(params_obj, "textDocument")
	if !td_ok {return}

	uri := json_object_get_string(td_obj, "uri")
	if len(uri) == 0 {return}

	// Full sync: get the text from the first content change
	changes_val, has_changes := params_obj["contentChanges"]
	if !has_changes {return}

	changes_arr, is_arr := changes_val.(json.Array)
	if !is_arr || len(changes_arr) == 0 {return}

	first_change, fc_ok := json_get_object(changes_arr[0])
	if !fc_ok {return}

	text := json_object_get_string(first_change, "text")

	log("ohtml-lsp: didChange uri=%s", uri)
	update_document(&server.document_store, uri, text, server.registry, server.root_path)
	publish_diagnostics_for(server, uri)
}

handle_did_close :: proc(server: ^Server, params: json.Value) {
	params_obj, ok := json_get_object(params)
	if !ok {return}

	td_obj, td_ok := json_object_get_object(params_obj, "textDocument")
	if !td_ok {return}

	uri := json_object_get_string(td_obj, "uri")
	if len(uri) == 0 {return}

	log("ohtml-lsp: didClose uri=%s", uri)
	close_document(&server.document_store, uri)
}

// ---- Registry Building ----

// build_registry discovers all .ohtml files in the workspace and builds
// the component registry for resolution.
// It also detects the actual ohtml project root (common ancestor of .ohtml files)
// and sets server.root_path to it, so import paths resolve correctly.
build_registry :: proc(server: ^Server) {
	if len(server.root_path) == 0 {
		return
	}

	files := lsp_discover_ohtml_files(server.root_path)
	defer delete(files)

	if len(files) == 0 {
		log("ohtml-lsp: no .ohtml files found in %s", server.root_path)
		return
	}

	// Detect the actual ohtml project root: common directory prefix of all .ohtml files
	src_dir := detect_src_dir(files[:])
	if len(src_dir) > 0 {
		server.root_path = src_dir
	}

	log("ohtml-lsp: discovered %d .ohtml files, src_dir=%s", len(files), server.root_path)

	for file in files {
		if lsp_is_page_file(file) || lsp_is_layout_file(file) {
			continue
		}
		rel := lsp_relative_path(server.root_path, file)
		rel_dir := lsp_path_dir(rel)
		comp_name := lsp_path_stem(lsp_path_base(rel))
		resolver.register_component(&server.registry, rel_dir, comp_name)
	}
}

// detect_src_dir finds the deepest common directory of all .ohtml files.
// e.g. if files are all under /repo/examples/ecomm/, returns that path.
detect_src_dir :: proc(files: []string) -> string {
	if len(files) == 0 { return "" }

	// Start with the directory of the first file
	common := lsp_path_dir(files[0])

	for file in files[1:] {
		dir := lsp_path_dir(file)
		// Find common prefix
		for !strings.has_prefix(dir, common) {
			common = lsp_path_dir(common)
			if common == "." || len(common) == 0 {
				return ""
			}
		}
	}

	return common
}

// ---- File Discovery Helpers ----
// These are copies of helpers from package main since we cannot import main.

lsp_discover_ohtml_files :: proc(dir: string) -> [dynamic]string {
	result := make([dynamic]string)
	lsp_walk_dir(dir, &result)
	return result
}

lsp_walk_dir :: proc(dir: string, result: ^[dynamic]string) {
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
			lsp_walk_dir(full_path, result)
			delete(full_path)
		} else if strings.has_suffix(info.name, ".ohtml") {
			append(result, full_path)
		} else {
			delete(full_path)
		}
	}
}

lsp_is_page_file :: proc(path: string) -> bool {
	return strings.has_suffix(path, "/+page.ohtml") || path == "+page.ohtml"
}

lsp_is_layout_file :: proc(path: string) -> bool {
	return strings.has_suffix(path, "/+layout.ohtml") || path == "+layout.ohtml"
}

lsp_relative_path :: proc(base_dir: string, file: string) -> string {
	base := strings.trim_right(base_dir, "/")
	if strings.has_prefix(file, base) {
		rel := file[len(base):]
		return strings.trim_left(rel, "/")
	}
	return file
}

lsp_path_dir :: proc(path: string) -> string {
	idx := strings.last_index(path, "/")
	if idx < 0 {return "."}
	return path[:idx]
}

lsp_path_base :: proc(path: string) -> string {
	idx := strings.last_index(path, "/")
	if idx < 0 {return path}
	return path[idx + 1:]
}

lsp_path_stem :: proc(name: string) -> string {
	idx := strings.last_index(name, ".")
	if idx < 0 {return name}
	return name[:idx]
}

lsp_resolve_relative_path :: proc(file_dir: string, rel: string) -> string {
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
