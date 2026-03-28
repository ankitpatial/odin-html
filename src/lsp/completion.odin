// src/lsp/completion.odin
package lsp

import "core:encoding/json"
import "core:os"
import "core:strings"

import "../parser"

COMPLETION_KIND_TEXT     :: 1
COMPLETION_KIND_FIELD    :: 5
COMPLETION_KIND_CLASS    :: 7
COMPLETION_KIND_PROPERTY :: 10
COMPLETION_KIND_SNIPPET  :: 15

// handle_completion handles textDocument/completion requests.
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
			add_prop_completions(server, pkg_path, name, pkg_name, &items)
		}
	}

	// 3. HTML tag completions
	add_html_tag_completions(&items)

	// 4. HTML attribute completions
	add_html_attribute_completions(&items)

	result := json.Object{}
	result["isIncomplete"] = json.Value(false)
	result["items"] = json.Value(items)

	write_response(id, json.Value(result))
}

// add_prop_completions adds prop completion items for a component.
// Handles both documents in store and on-demand parsing safely.
add_prop_completions :: proc(
	server: ^Server,
	pkg_path: string,
	comp_name: string,
	pkg_name: string,
	items: ^json.Array,
) {
	comp_file := find_component_file(server.root_path, pkg_path, comp_name)
	if len(comp_file) == 0 { return }

	// Check document store first
	comp_uri := path_to_uri(comp_file)
	if doc, ok := get_document(&server.document_store, comp_uri); ok {
		if parsed, has := doc.parsed.?; has {
			if script, has_script := parsed.script.?; has_script {
				if props, has_props := script.props.?; has_props {
					for field in props.fields {
						if field.is_snippet { continue }
						add_prop_item(items, field.name, field.type_expr, pkg_name, comp_name)
					}
				}
			}
		}
		return
	}

	// Parse on demand — keep src_bytes alive until we've cloned what we need
	src_bytes, read_err := os.read_entire_file_from_path(comp_file, context.allocator)
	if read_err != nil { return }

	parsed_doc, parse_err := parser.parse(string(src_bytes), comp_file)
	if _, has_err := parse_err.?; has_err {
		delete(src_bytes)
		return
	}

	if script, has_script := parsed_doc.script.?; has_script {
		if props, has_props := script.props.?; has_props {
			for field in props.fields {
				if field.is_snippet { continue }
				// Clone strings since src_bytes will be freed
				add_prop_item(items, strings.clone(field.name), strings.clone(field.type_expr), pkg_name, comp_name)
			}
		}
	}

	delete(src_bytes)
}

add_prop_item :: proc(items: ^json.Array, field_name: string, type_expr: string, pkg_name: string, comp_name: string) {
	detail := strings.concatenate({pkg_name, ".", comp_name, " prop: ", type_expr})
	item := json.Object{}
	item["label"] = json.Value(field_name)
	item["kind"] = json.Value(i64(COMPLETION_KIND_PROPERTY))
	item["detail"] = json.Value(detail)
	append(items, json.Value(item))
}

// ─── HTML completions ───────────────────────────────────────────────────────

add_html_tag_completions :: proc(items: ^json.Array) {
	Tag :: struct { name: string, detail: string, self_closing: bool }

	tags := []Tag{
		// Document
		{"html", "Document root", false},
		{"head", "Document metadata container", false},
		{"body", "Document body", false},
		{"title", "Document title", false},
		// Sections
		{"div", "Generic container", false},
		{"span", "Inline container", false},
		{"section", "Thematic section", false},
		{"article", "Self-contained content", false},
		{"aside", "Sidebar content", false},
		{"header", "Header section", false},
		{"footer", "Footer section", false},
		{"main", "Main content", false},
		{"nav", "Navigation section", false},
		// Headings
		{"h1", "Heading level 1", false},
		{"h2", "Heading level 2", false},
		{"h3", "Heading level 3", false},
		{"h4", "Heading level 4", false},
		{"h5", "Heading level 5", false},
		{"h6", "Heading level 6", false},
		// Text
		{"p", "Paragraph", false},
		{"a", "Hyperlink", false},
		{"strong", "Strong importance", false},
		{"em", "Emphasis", false},
		{"b", "Bold text", false},
		{"i", "Italic text", false},
		{"u", "Underlined text", false},
		{"s", "Strikethrough", false},
		{"small", "Small text", false},
		{"mark", "Highlighted text", false},
		{"code", "Code fragment", false},
		{"pre", "Preformatted text", false},
		{"blockquote", "Block quotation", false},
		{"q", "Inline quotation", false},
		{"abbr", "Abbreviation", false},
		{"cite", "Citation", false},
		{"time", "Date/time", false},
		{"sub", "Subscript", false},
		{"sup", "Superscript", false},
		// Lists
		{"ul", "Unordered list", false},
		{"ol", "Ordered list", false},
		{"li", "List item", false},
		{"dl", "Description list", false},
		{"dt", "Description term", false},
		{"dd", "Description details", false},
		// Table
		{"table", "Table", false},
		{"thead", "Table header group", false},
		{"tbody", "Table body group", false},
		{"tfoot", "Table footer group", false},
		{"tr", "Table row", false},
		{"th", "Table header cell", false},
		{"td", "Table data cell", false},
		{"caption", "Table caption", false},
		{"colgroup", "Column group", false},
		{"col", "Table column", true},
		// Form
		{"form", "Form", false},
		{"input", "Input field", true},
		{"textarea", "Multi-line input", false},
		{"button", "Button", false},
		{"select", "Dropdown select", false},
		{"option", "Select option", false},
		{"optgroup", "Option group", false},
		{"label", "Form label", false},
		{"fieldset", "Form field group", false},
		{"legend", "Fieldset caption", false},
		{"datalist", "Predefined options", false},
		{"output", "Calculation result", false},
		{"progress", "Progress indicator", false},
		{"meter", "Scalar measurement", false},
		// Media
		{"img", "Image", true},
		{"video", "Video", false},
		{"audio", "Audio", false},
		{"source", "Media source", true},
		{"picture", "Responsive image", false},
		{"figure", "Figure with caption", false},
		{"figcaption", "Figure caption", false},
		{"canvas", "Drawing canvas", false},
		{"svg", "SVG container", false},
		// Embedded
		{"iframe", "Inline frame", false},
		{"embed", "Embedded content", true},
		{"object", "External object", false},
		// Metadata
		{"meta", "Metadata", true},
		{"link", "External resource link", true},
		{"style", "CSS styles", false},
		{"script", "JavaScript", false},
		{"noscript", "Fallback for no-script", false},
		{"base", "Base URL", true},
		// Interactive
		{"details", "Expandable details", false},
		{"summary", "Details summary", false},
		{"dialog", "Dialog box", false},
		// Misc
		{"br", "Line break", true},
		{"hr", "Horizontal rule", true},
		{"wbr", "Word break opportunity", true},
		{"template", "HTML template", false},
		{"slot", "Web component slot", false},
		{"data", "Machine-readable data", false},
		{"address", "Contact information", false},
	}

	for tag in tags {
		item := json.Object{}
		item["label"] = json.Value(tag.name)
		item["kind"] = json.Value(i64(COMPLETION_KIND_TEXT))
		item["detail"] = json.Value(tag.detail)

		// Insert text with angle brackets
		if tag.self_closing {
			item["insertText"] = json.Value(strings.concatenate({"<", tag.name, " />"}))
		} else {
			item["insertText"] = json.Value(strings.concatenate({"<", tag.name, ">"}))
		}

		append(items, json.Value(item))
	}
}

add_html_attribute_completions :: proc(items: ^json.Array) {
	Attr :: struct { name: string, detail: string }

	// Global HTML attributes
	attrs := []Attr{
		{"class", "CSS class names"},
		{"id", "Unique identifier"},
		{"style", "Inline CSS styles"},
		{"title", "Advisory title"},
		{"hidden", "Hidden element"},
		{"tabindex", "Tab order"},
		{"role", "ARIA role"},
		{"aria-label", "ARIA label"},
		{"aria-hidden", "ARIA hidden"},
		{"aria-describedby", "ARIA described by"},
		{"data-", "Custom data attribute"},
		// Common attributes
		{"href", "Hyperlink reference (a, link)"},
		{"src", "Source URL (img, script, video, audio)"},
		{"alt", "Alternative text (img)"},
		{"type", "Type (input, button, script, style)"},
		{"name", "Name (input, form, meta)"},
		{"value", "Value (input, option, button)"},
		{"placeholder", "Placeholder text (input, textarea)"},
		{"disabled", "Disabled state"},
		{"readonly", "Read-only state"},
		{"required", "Required field"},
		{"checked", "Checked state (checkbox, radio)"},
		{"selected", "Selected state (option)"},
		{"for", "Associated element (label)"},
		{"action", "Form submission URL"},
		{"method", "Form HTTP method"},
		{"target", "Link target (_blank, _self)"},
		{"rel", "Link relationship"},
		{"width", "Width (img, video, canvas)"},
		{"height", "Height (img, video, canvas)"},
		{"loading", "Loading strategy (lazy, eager)"},
		{"charset", "Character encoding (meta)"},
		{"content", "Meta content"},
		{"lang", "Language"},
		{"dir", "Text direction (ltr, rtl)"},
		{"autofocus", "Auto focus on load"},
		{"autocomplete", "Autocomplete behavior"},
		{"min", "Minimum value"},
		{"max", "Maximum value"},
		{"step", "Step increment"},
		{"pattern", "Validation pattern"},
		{"maxlength", "Maximum length"},
		{"minlength", "Minimum length"},
		{"multiple", "Allow multiple values"},
		{"accept", "Accepted file types"},
		{"colspan", "Column span (td, th)"},
		{"rowspan", "Row span (td, th)"},
		{"scope", "Header scope (th)"},
		{"open", "Open state (details, dialog)"},
		{"defer", "Deferred execution (script)"},
		{"async", "Async execution (script)"},
		{"crossorigin", "CORS setting"},
		{"integrity", "Subresource integrity"},
		{"download", "Download filename"},
		{"draggable", "Draggable element"},
		{"contenteditable", "Editable content"},
		{"spellcheck", "Spell check"},
	}

	for attr in attrs {
		item := json.Object{}
		item["label"] = json.Value(attr.name)
		item["kind"] = json.Value(i64(COMPLETION_KIND_FIELD))
		item["detail"] = json.Value(attr.detail)
		append(items, json.Value(item))
	}
}
