; Script block content -> Odin
((script_element (raw_text) @content)
 (#set! "language" "odin"))

; Expression content -> Odin
((expression (expression_content) @content)
 (#set! "language" "odin"))

; Raw HTML expression content -> Odin
((raw_html_expression (expression_content) @content)
 (#set! "language" "odin"))

; Render expression content -> Odin
((render_expression (render_content) @content)
 (#set! "language" "odin"))

; If condition -> Odin
((if_start (expression_content) @content)
 (#set! "language" "odin"))

; Else-if condition -> Odin
((else_if_clause (expression_content) @content)
 (#set! "language" "odin"))

; Each iterable -> Odin
((each_start (expression_content) @content)
 (#set! "language" "odin"))
