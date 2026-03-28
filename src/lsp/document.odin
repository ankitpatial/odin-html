// src/lsp/document.odin
package lsp

import "core:strings"

import "../ast"
import "../errors"
import "../parser"
import "../resolver"

// Document represents a tracked open document with its content and parsed AST.
Document :: struct {
	uri:          string,
	content:      string,
	parsed:       Maybe(ast.Document),
	parse_errors: [dynamic]errors.Error,
}

// Document_Store maps URIs to open documents.
Document_Store :: struct {
	documents: map[string]Document,
}

// make_document_store creates a new empty document store.
make_document_store :: proc() -> Document_Store {
	return Document_Store{
		documents = make(map[string]Document),
	}
}

// open_document adds a document to the store, parses it, and returns any errors.
open_document :: proc(store: ^Document_Store, uri: string, content: string, registry: resolver.Registry, src_dir: string) {
	doc := Document{
		uri     = uri,
		content = content,
	}
	parse_document(&doc, registry, src_dir)
	// Free old document resources if overwriting
	if old_doc, exists := &store.documents[uri]; exists {
		delete(old_doc.parse_errors)
	}
	store.documents[uri] = doc
}

// update_document replaces the content of an existing document and re-parses it.
update_document :: proc(store: ^Document_Store, uri: string, content: string, registry: resolver.Registry, src_dir: string) {
	doc := Document{
		uri     = uri,
		content = content,
	}
	parse_document(&doc, registry, src_dir)
	// Free old document resources if overwriting
	if old_doc, exists := &store.documents[uri]; exists {
		delete(old_doc.parse_errors)
	}
	store.documents[uri] = doc
}

// close_document removes a document from the store.
close_document :: proc(store: ^Document_Store, uri: string) {
	if _, ok := store.documents[uri]; ok {
		delete_key(&store.documents, uri)
	}
}

// get_document retrieves a document by URI, returning it and whether it exists.
get_document :: proc(store: ^Document_Store, uri: string) -> (^Document, bool) {
	if doc, ok := &store.documents[uri]; ok {
		return doc, true
	}
	return nil, false
}

// parse_document parses the document content and runs the resolver.
// src_dir is the workspace root, needed to normalize relative import paths.
parse_document :: proc(doc: ^Document, registry: resolver.Registry, src_dir: string) {
	file_path := uri_to_path(doc.uri)

	doc.parse_errors = make([dynamic]errors.Error)

	parsed, parse_err := parser.parse(doc.content, file_path)
	if err_val, has_err := parse_err.?; has_err {
		append(&doc.parse_errors, err_val)
		doc.parsed = nil
		return
	}

	doc.parsed = parsed

	// Normalize relative import paths before resolution (same as cmd_generate)
	if parsed_doc, ok := &doc.parsed.?; ok {
		if script, has_script := &parsed_doc.script.?; has_script {
			rel := lsp_relative_path(src_dir, file_path)
			file_dir := lsp_path_dir(rel)
			for &imp in script.imports {
				if strings.has_prefix(imp.path, ".") {
					imp.path = lsp_resolve_relative_path(file_dir, imp.path)
				}
			}
		}
	}

	// Run resolver to check component references
	if parsed_doc, ok := &doc.parsed.?; ok {
		resolve_errs := resolver.resolve(parsed_doc, registry)
		for e in resolve_errs {
			append(&doc.parse_errors, e)
		}
		delete(resolve_errs)
	}
}
