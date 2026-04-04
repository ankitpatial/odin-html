// src/lexer/lexer.odin
package lexer

import "core:strings"
import "../token"

Lexer :: struct {
    src:    string,
    pos:    int,
    line:   int,
    col:    int,
    tokens: [dynamic]token.Token,
}

tokenize :: proc(src: string) -> [dynamic]token.Token {
    l := Lexer{
        src    = src,
        pos    = 0,
        line   = 1,
        col    = 1,
        tokens = make([dynamic]token.Token),
    }
    lex_all(&l)
    return l.tokens
}

// ─── helpers ──────────────────────────────────────────────────────────────────

peek :: proc(l: ^Lexer, offset: int = 0) -> byte {
    idx := l.pos + offset
    if idx >= len(l.src) { return 0 }
    return l.src[idx]
}

advance :: proc(l: ^Lexer) -> byte {
    if l.pos >= len(l.src) { return 0 }
    ch := l.src[l.pos]
    l.pos += 1
    if ch == '\n' {
        l.line += 1
        l.col   = 1
    } else {
        l.col += 1
    }
    return ch
}

// skip_whitespace advances past space / tab / newline
skip_whitespace :: proc(l: ^Lexer) {
    for l.pos < len(l.src) {
        ch := peek(l)
        if ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' {
            advance(l)
        } else {
            break
        }
    }
}

// starts_with returns true if the unconsumed src starts with s
starts_with :: proc(l: ^Lexer, s: string) -> bool {
    if l.pos + len(s) > len(l.src) { return false }
    return l.src[l.pos : l.pos + len(s)] == s
}

emit :: proc(l: ^Lexer, kind: token.Kind, value: string, line, col: int) {
    append(&l.tokens, token.Token{kind = kind, value = value, line = line, col = col})
}

// ─── top-level driver ─────────────────────────────────────────────────────────

lex_all :: proc(l: ^Lexer) {
    for l.pos < len(l.src) {
        lex_text_or_tag(l)
    }
}

// lex_text_or_tag is the outermost dispatcher: either we are looking at a tag /
// block directive, or we consume plain text.
lex_text_or_tag :: proc(l: ^Lexer) {
    // Try to consume a run of plain text first (everything up to '<' or '{')
    text_start := l.pos
    line        := l.line
    col         := l.col

    for l.pos < len(l.src) {
        ch := peek(l)
        if ch == '<' || ch == '{' { break }
        advance(l)
    }

    if l.pos > text_start {
        emit(l, .Text, l.src[text_start:l.pos], line, col)
        return
    }

    // Now we are at '<' or '{'
    if peek(l) == '<' {
        lex_tag_or_doctype_or_comment(l)
    } else if peek(l) == '{' {
        lex_brace_block(l)
    }
}

// ─── tag / doctype / comment ──────────────────────────────────────────────────

lex_tag_or_doctype_or_comment :: proc(l: ^Lexer) {
    // we are sitting on '<'

    // <!-- comment -->
    if starts_with(l, "<!--") {
        lex_comment(l)
        return
    }

    // <!DOCTYPE ...>
    if starts_with(l, "<!") {
        lex_doctype(l)
        return
    }

    // </tag>
    if starts_with(l, "</") {
        lex_end_tag(l)
        return
    }

    // <script lang="odin">
    if starts_with(l, "<script") {
        // peek ahead: is the next char after "script" whitespace or '>'?
        next_idx := l.pos + len("<script")
        if next_idx >= len(l.src) || l.src[next_idx] == ' ' || l.src[next_idx] == '\t' || l.src[next_idx] == '>' || l.src[next_idx] == '\n' {
            lex_script_block(l)
            return
        }
    }

    // <tagname …>
    lex_open_tag(l)
}

lex_comment :: proc(l: ^Lexer) {
    line := l.line
    col  := l.col
    start := l.pos
    // consume "<!--"
    advance(l); advance(l); advance(l); advance(l)
    for l.pos < len(l.src) {
        if starts_with(l, "-->") {
            advance(l); advance(l); advance(l)
            break
        }
        advance(l)
    }
    emit(l, .Comment, l.src[start:l.pos], line, col)
}

lex_doctype :: proc(l: ^Lexer) {
    line := l.line
    col  := l.col
    start := l.pos
    for l.pos < len(l.src) {
        ch := advance(l)
        if ch == '>' { break }
    }
    emit(l, .Doctype, l.src[start:l.pos], line, col)
}

// is_component_name returns true if the tag name is a component reference:
// either contains a dot (e.g. "card.Card") or starts with an uppercase letter (e.g. "Badge").
is_component_name :: proc(name: string) -> bool {
    if strings.contains(name, ".") { return true }
    if len(name) > 0 && name[0] >= 'A' && name[0] <= 'Z' { return true }
    return false
}

lex_end_tag :: proc(l: ^Lexer) {
    line := l.line
    col  := l.col
    // emit  </
    advance(l); advance(l) // consume '</'
    emit(l, .Tag_End_Open, "</", line, col)

    skip_whitespace(l)
    name_line := l.line; name_col := l.col
    name := read_tag_name(l)
    if is_component_name(name) {
        emit(l, .Component_Name, name, name_line, name_col)
    } else {
        emit(l, .Tag_Name, name, name_line, name_col)
    }

    skip_whitespace(l)
    if peek(l) == '>' {
        cl := l.line; cc := l.col
        advance(l)
        emit(l, .Tag_Close, ">", cl, cc)
    }
}

lex_open_tag :: proc(l: ^Lexer) {
    line := l.line
    col  := l.col
    advance(l) // consume '<'
    emit(l, .Tag_Open, "<", line, col)

    skip_whitespace(l)
    name_line := l.line; name_col := l.col
    name := read_tag_name(l)
    if is_component_name(name) {
        emit(l, .Component_Name, name, name_line, name_col)
    } else {
        emit(l, .Tag_Name, name, name_line, name_col)
    }

    // attributes
    lex_attributes(l)

    // close: /> or >
    skip_whitespace(l)
    if starts_with(l, "/>") {
        cl := l.line; cc := l.col
        advance(l); advance(l)
        emit(l, .Tag_Self_Close, "/>", cl, cc)
    } else if peek(l) == '>' {
        cl := l.line; cc := l.col
        advance(l)
        emit(l, .Tag_Close, ">", cl, cc)
    }
}

// read_tag_name reads a run of valid tag-name characters (letters, digits, -, _, .)
read_tag_name :: proc(l: ^Lexer) -> string {
    start := l.pos
    for l.pos < len(l.src) {
        ch := peek(l)
        if is_tag_name_char(ch) {
            advance(l)
        } else {
            break
        }
    }
    return l.src[start:l.pos]
}

is_tag_name_char :: proc(ch: byte) -> bool {
    return (ch >= 'a' && ch <= 'z') ||
           (ch >= 'A' && ch <= 'Z') ||
           (ch >= '0' && ch <= '9') ||
           ch == '-' || ch == '_' || ch == '.' || ch == ':'
}

// ─── attributes ───────────────────────────────────────────────────────────────

lex_attributes :: proc(l: ^Lexer) {
    for {
        skip_whitespace(l)
        ch := peek(l)
        // stop conditions: end of tag
        if ch == '>' || ch == 0 { break }
        if starts_with(l, "/>") { break }

        // read attribute name
        name_line := l.line; name_col := l.col
        attr_name := read_attr_name(l)
        if len(attr_name) == 0 { break }
        emit(l, .Attr_Name, attr_name, name_line, name_col)

        skip_whitespace(l)
        if peek(l) != '=' {
            // boolean attribute — no value
            continue
        }
        // consume '='
        eq_line := l.line; eq_col := l.col
        advance(l)
        emit(l, .Attr_Eq, "=", eq_line, eq_col)

        skip_whitespace(l)
        // dynamic value {expr} or static value "..."
        if peek(l) == '{' {
            lex_expr_inline(l)
        } else if peek(l) == '"' || peek(l) == '\'' {
            lex_attr_static_value(l)
        }
    }
}

read_attr_name :: proc(l: ^Lexer) -> string {
    start := l.pos
    for l.pos < len(l.src) {
        ch := peek(l)
        if ch == '=' || ch == '>' || ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == 0 { break }
        if starts_with(l, "/>") { break }
        advance(l)
    }
    return l.src[start:l.pos]
}

lex_attr_static_value :: proc(l: ^Lexer) {
    quote := advance(l) // consume opening quote
    start := l.pos
    line  := l.line; col := l.col
    for l.pos < len(l.src) {
        ch := advance(l)
        if ch == quote { break }
    }
    // value is between start and pos-1 (exclude closing quote)
    val := l.src[start : l.pos - 1]
    emit(l, .Attr_Value, val, line, col)
}

// lex_expr_inline emits Expr_Open, Expr_Content, Expr_Close for {expr} used as
// an attribute value.  Nested braces are handled correctly.
lex_expr_inline :: proc(l: ^Lexer) {
    open_line := l.line; open_col := l.col
    advance(l) // consume '{'
    emit(l, .Expr_Open, "{", open_line, open_col)

    content_line := l.line; content_col := l.col
    start := l.pos
    depth := 1
    for l.pos < len(l.src) && depth > 0 {
        ch := advance(l)
        if ch == '{' { depth += 1 }
        else if ch == '}' { depth -= 1 }
    }
    // content excludes the final '}'
    content := l.src[start : l.pos - 1]
    emit(l, .Expr_Content, content, content_line, content_col)

    close_line := l.line; close_col := l.col - 1
    emit(l, .Expr_Close, "}", close_line, close_col)
}

// ─── script block ─────────────────────────────────────────────────────────────

lex_script_block :: proc(l: ^Lexer) {
    line := l.line
    col  := l.col
    // capture the opening tag to detect lang attribute
    tag_start := l.pos
    for l.pos < len(l.src) {
        ch := advance(l)
        if ch == '>' { break }
    }
    open_tag := l.src[tag_start:l.pos]
    // Detect language: look for lang="ts" or lang="odin" in the opening tag
    lang := "odin" // default
    if strings.contains(open_tag, "lang=\"ts\"") || strings.contains(open_tag, "lang='ts'") {
        lang = "ts"
    }
    open_value := strings.concatenate({"<script lang=\"", lang, "\">"})
    emit(l, .Script_Open, open_value, line, col)

    // content until </script>
    content_line := l.line; content_col := l.col
    content_start := l.pos
    for l.pos < len(l.src) {
        if starts_with(l, "</script>") { break }
        advance(l)
    }
    emit(l, .Script_Content, l.src[content_start:l.pos], content_line, content_col)

    // consume </script>
    close_line := l.line; close_col := l.col
    for i := 0; i < len("</script>"); i += 1 { advance(l) }
    emit(l, .Script_Close, "</script>", close_line, close_col)
}

// ─── brace blocks (expressions + control flow) ───────────────────────────────

lex_brace_block :: proc(l: ^Lexer) {
    // we are sitting on '{'
    line := l.line
    col  := l.col

    // peek at what follows '{'
    next := peek(l, 1)

    switch next {
    case '#':
        // {#if ...}, {#each ...}, {#snippet ...}
        advance(l); advance(l) // consume '{' and '#'
        keyword_start := l.pos
        for l.pos < len(l.src) && peek(l) != ' ' && peek(l) != '\t' && peek(l) != '}' {
            advance(l)
        }
        keyword := l.src[keyword_start:l.pos]
        switch keyword {
        case "if":
            skip_whitespace(l)
            cond := read_until_close_brace(l)
            emit(l, .Block_If, cond, line, col)
        case "each":
            skip_whitespace(l)
            expr := read_until_close_brace(l)
            emit(l, .Block_Each, expr, line, col)
        case "snippet":
            skip_whitespace(l)
            sig := read_until_close_brace(l)
            emit(l, .Block_Snippet, sig, line, col)
        }

    case '/':
        // {/if}, {/each}, {/snippet}
        advance(l); advance(l) // consume '{' and '/'
        keyword_start := l.pos
        for l.pos < len(l.src) && peek(l) != '}' && peek(l) != ' ' {
            advance(l)
        }
        keyword := l.src[keyword_start:l.pos]
        skip_whitespace(l)
        if peek(l) == '}' { advance(l) }

        if keyword == "snippet" {
            emit(l, .Block_End_Snippet, keyword, line, col)
        } else {
            emit(l, .Block_End, keyword, line, col)
        }

    case ':':
        // {:else} or {:else if ...}
        advance(l); advance(l) // consume '{' and ':'
        keyword_start := l.pos
        for l.pos < len(l.src) && peek(l) != ' ' && peek(l) != '}' && peek(l) != '\t' {
            advance(l)
        }
        keyword := l.src[keyword_start:l.pos]
        if keyword == "else" {
            skip_whitespace(l)
            // check if followed by "if"
            if starts_with(l, "if") {
                advance(l); advance(l) // consume "if"
                skip_whitespace(l)
                cond := read_until_close_brace(l)
                emit(l, .Block_Else_If, cond, line, col)
            } else {
                // {:else}
                if peek(l) == '}' { advance(l) }
                emit(l, .Block_Else, "", line, col)
            }
        }

    case '@':
        // {@render ...} or {@html ...}
        advance(l); advance(l) // consume '{' and '@'
        keyword_start := l.pos
        for l.pos < len(l.src) && peek(l) != ' ' && peek(l) != '\t' && peek(l) != '}' {
            advance(l)
        }
        keyword := l.src[keyword_start:l.pos]
        skip_whitespace(l)
        expr := read_until_close_brace(l)
        switch keyword {
        case "render":
            emit(l, .Render, expr, line, col)
        case "html":
            emit(l, .Html_Raw, expr, line, col)
        }

    case:
        // plain expression {expr}
        lex_expr_inline(l)
    }
}

// read_until_close_brace reads text until the matching '}', respecting nested
// braces.  Consumes the final '}'.  Returns the inner text without the '}'.
read_until_close_brace :: proc(l: ^Lexer) -> string {
    start := l.pos
    depth := 1
    for l.pos < len(l.src) && depth > 0 {
        ch := advance(l)
        if ch == '{' { depth += 1 }
        else if ch == '}' { depth -= 1 }
    }
    return strings.trim_right(l.src[start : l.pos - 1], " \t\r\n")
}
