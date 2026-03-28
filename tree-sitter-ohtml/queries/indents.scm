; Indent after opening tags
(element (start_tag) @indent)
(element (end_tag) @outdent)

; Indent after component opening tags
(component (component_start_tag) @indent)
(component (component_end_tag) @outdent)

; Indent after control flow openers
(if_block (if_start) @indent)
(if_block (if_end) @outdent)
(each_block (each_start) @indent)
(each_block (each_end) @outdent)
(snippet_block (snippet_start) @indent)
(snippet_block (snippet_end) @outdent)

; Else clauses: outdent then indent
(else_if_clause) @outdent @indent
(else_clause) @outdent @indent
