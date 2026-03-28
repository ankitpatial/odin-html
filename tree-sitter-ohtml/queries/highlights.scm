; --- Tags ---
(start_tag (tag_name) @tag)
(end_tag (tag_name) @tag)
(self_closing_tag (tag_name) @tag)
(script_start_tag) @tag
(script_end_tag) @tag

; --- Components ---
(component_start_tag (component_name) @type)
(component_end_tag (component_name) @type)
(component_self_closing_tag (component_name) @type)

; --- Attributes ---
(attribute (attribute_name) @attribute)
(quoted_attribute_value) @string

; --- Control Flow Keywords ---
; Container nodes: Zed injection overrides keyword color on expression regions.
; Leaf nodes (if_end, each_end): no children, safe to highlight entirely.
(if_start) @keyword.control
(if_end) @keyword.control
(else_if_clause) @keyword.control
(else_clause) @keyword.control
(each_start) @keyword.control
(each_end) @keyword.control

; --- Snippets ---
(snippet_start) @keyword.control
(snippet_end) @keyword.control
(snippet_name) @function

; --- Directives ---
(raw_html_expression) @keyword.directive
(render_expression) @keyword.directive

; --- Punctuation ---
"<" @punctuation.bracket
">" @punctuation.bracket
"</" @punctuation.bracket
"/>" @punctuation.bracket
"=" @operator
"{" @punctuation.special
"}" @punctuation.special

; --- Comments ---
(comment) @comment

; --- Doctype ---
(doctype) @keyword
