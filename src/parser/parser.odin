// src/parser/parser.odin
package parser

import "core:fmt"
import "core:strings"
import "../ast"
import "../token"
import "../lexer"
import "../errors"

Parser :: struct {
    tokens: [dynamic]token.Token,
    pos:    int,
    file:   string,
    doc:    ^ast.Document,
}

// ─── entry point ──────────────────────────────────────────────────────────────

parse :: proc(src: string, file: string) -> (ast.Document, Maybe(errors.Error)) {
    tokens := lexer.tokenize(src)
    doc := ast.Document{file = file}
    doc.children = make([dynamic]ast.Node)
    doc.svelte_head = make([dynamic]ast.Node)
    p := Parser{tokens = tokens, pos = 0, file = file, doc = &doc}

    // Check for script block first (it must appear before any HTML children)
    if p.pos < len(p.tokens) && p.tokens[p.pos].kind == .Script_Open {
        script, err := parse_script_block(&p)
        if err != nil { return doc, err }
        doc.script = script
    }

    // Skip whitespace-only Text tokens between script and first element
    for p.pos < len(p.tokens) {
        tok := p.tokens[p.pos]
        if tok.kind == .Text && strings.trim_space(tok.value) == "" {
            p.pos += 1
            continue
        }
        break
    }

    // Parse remaining children
    children, err := parse_children(&p, nil)
    if err != nil { return doc, err }
    doc.children = children

    return doc, nil
}

// ─── helpers ──────────────────────────────────────────────────────────────────

peek_tok :: proc(p: ^Parser, offset: int = 0) -> token.Token {
    idx := p.pos + offset
    if idx >= len(p.tokens) {
        return token.Token{kind = .EOF}
    }
    return p.tokens[idx]
}

advance_tok :: proc(p: ^Parser) -> token.Token {
    if p.pos >= len(p.tokens) {
        return token.Token{kind = .EOF}
    }
    tok := p.tokens[p.pos]
    p.pos += 1
    return tok
}

make_error :: proc(p: ^Parser, msg: string) -> errors.Error {
    tok := peek_tok(p)
    return errors.Error{file = p.file, line = tok.line, col = tok.col, msg = msg}
}

tok_pos :: proc(tok: token.Token) -> token.Pos {
    return token.Pos{line = tok.line, col = tok.col}
}

// ─── script block ─────────────────────────────────────────────────────────────

parse_script_block :: proc(p: ^Parser) -> (ast.Script_Block, Maybe(errors.Error)) {
    sb := ast.Script_Block{}
    sb.imports = make([dynamic]ast.Import)

    // consume Script_Open — its value contains the lang attribute
    open_tok := advance_tok(p)

    // Detect language from the Script_Open token value
    lang := "odin"
    if strings.contains(open_tok.value, "lang=\"ts\"") {
        lang = "ts"
    }
    sb.lang = lang

    // consume Script_Content
    if p.pos >= len(p.tokens) || p.tokens[p.pos].kind != .Script_Content {
        return sb, nil
    }
    content_tok := advance_tok(p)
    sb.raw = content_tok.value

    // consume Script_Close
    if p.pos < len(p.tokens) && p.tokens[p.pos].kind == .Script_Close {
        advance_tok(p)
    }

    // Parse the raw script content based on language
    if lang == "ts" {
        props, imports := parse_ts_script(sb.raw, p.file)
        sb.props = props
        sb.imports = imports
        // Clear raw so codegen doesn't try to extract Odin defs from TypeScript
        sb.raw = ""
    } else {
        if err := parse_script_content(sb.raw, &sb, p.file); err != nil {
            return sb, err
        }
    }

    return sb, nil
}

parse_script_content :: proc(raw: string, sb: ^ast.Script_Block, file: string) -> Maybe(errors.Error) {
    lines := strings.split_lines(raw)
    defer delete(lines)

    i := 0
    for i < len(lines) {
        line := strings.trim_space(lines[i])

        // import "path" or import alias "path"
        if strings.has_prefix(line, "import ") {
            imp := parse_import_line(line)
            append(&sb.imports, imp)
            i += 1
            continue
        }

        // Props :: struct {
        if strings.contains(line, "Props :: struct") || strings.contains(line, "Props::struct") {
            // Collect all lines of the struct
            struct_lines: [dynamic]string
            defer delete(struct_lines)
            append(&struct_lines, line)
            i += 1
            depth := 0
            // Count opening brace on first line
            for ch in line {
                if ch == '{' { depth += 1 }
                else if ch == '}' { depth -= 1 }
            }
            for i < len(lines) && depth > 0 {
                l := lines[i]
                append(&struct_lines, l)
                for ch in l {
                    if ch == '{' { depth += 1 }
                    else if ch == '}' { depth -= 1 }
                }
                i += 1
            }
            // Parse the struct fields
            props, err := parse_props_struct(struct_lines[:], file)
            if err != nil {
                return err
            }
            sb.props = props
            continue
        }

        i += 1
    }
    return nil
}

parse_import_line :: proc(line: string) -> ast.Import {
    // remove "import " prefix
    rest := strings.trim_space(line[len("import "):])

    // Does it start with a quote? → no alias
    if len(rest) > 0 && rest[0] == '"' {
        path := strings.trim(rest, "\"")
        // Find the closing quote
        end := strings.index(rest[1:], "\"")
        if end >= 0 {
            path = rest[1 : end+1]
        }
        return ast.Import{path = path}
    }

    // Otherwise: alias "path"
    // Split on first space or quote
    space_idx := strings.index(rest, " ")
    if space_idx < 0 {
        return ast.Import{path = rest}
    }
    alias := strings.trim_space(rest[:space_idx])
    path_part := strings.trim_space(rest[space_idx+1:])
    path := strings.trim(path_part, "\"")
    // More robust: find content between quotes
    q1 := strings.index(path_part, "\"")
    if q1 >= 0 {
        q2 := strings.index(path_part[q1+1:], "\"")
        if q2 >= 0 {
            path = path_part[q1+1 : q1+1+q2]
        }
    }
    return ast.Import{alias = alias, path = path}
}

parse_props_struct :: proc(lines: []string, file: string) -> (ast.Props_Def, Maybe(errors.Error)) {
    props := ast.Props_Def{}
    props.fields = make([dynamic]ast.Prop_Field)

    inside := false
    for raw_line in lines {
        trimmed := strings.trim_space(raw_line)

        if strings.contains(trimmed, "Props :: struct") || strings.contains(trimmed, "Props::struct") {
            inside = true
            // Check if the struct body is on the same line: Props :: struct { ... }
            brace_open := strings.index(trimmed, "{")
            brace_close := strings.last_index(trimmed, "}")
            if brace_open >= 0 && brace_close > brace_open {
                // Extract fields between { and }
                fields_str := trimmed[brace_open+1 : brace_close]
                // Split by comma to get individual fields
                field_parts := strings.split(fields_str, ",")
                defer delete(field_parts)
                for fp in field_parts {
                    fp_trimmed := strings.trim_space(fp)
                    if len(fp_trimmed) == 0 { continue }
                    if err := parse_and_append_field(fp_trimmed, &props, file); err != nil {
                        return props, err
                    }
                }
                inside = false // done parsing inline struct
            }
            continue
        }

        if !inside { continue }
        if trimmed == "{" { continue }
        if trimmed == "}" || trimmed == "}," { break }
        if len(trimmed) == 0 { continue }

        if err := parse_and_append_field(trimmed, &props, file); err != nil {
            return props, err
        }
    }

    return props, nil
}

// parse_and_append_field parses a single "name: type" field line and appends to props.fields.
// Returns an error if a snippet proc has more than 2 parameters (io.Writer + 1 arg max).
parse_and_append_field :: proc(field_line: string, props: ^ast.Props_Def, file: string) -> Maybe(errors.Error) {
    // Strip trailing comma
    fl := field_line
    if strings.has_suffix(fl, ",") {
        fl = fl[:len(fl)-1]
    }
    fl = strings.trim_space(fl)
    if len(fl) == 0 { return nil }

    colon_idx := strings.index(fl, ":")
    if colon_idx < 0 { return nil }

    name := strings.trim_space(fl[:colon_idx])
    type_expr := strings.trim_space(fl[colon_idx+1:])

    if len(name) == 0 { return nil }

    field := ast.Prop_Field{name = name, type_expr = type_expr}

    // Detect snippet: proc(w: io.Writer) or proc(w: io.Writer, item: Type)
    if strings.has_prefix(type_expr, "proc(") {
        field.is_snippet = true
        // Extract args inside proc(...)
        paren_start := strings.index(type_expr, "(")
        paren_end := strings.last_index(type_expr, ")")
        if paren_start >= 0 && paren_end > paren_start {
            args_str := type_expr[paren_start+1 : paren_end]
            // Split by comma to find parameters
            args := strings.split(args_str, ",")
            defer delete(args)
            // First arg is always w: io.Writer (the writer)
            // If there's a second arg, that's the snippet arg type
            // If there are 3+ args, reject — snippets support at most 1 user arg
            if len(args) >= 3 {
                msg := fmt.tprintf("snippet prop %q has too many arguments: only 1 user argument is supported (got %d)", name, len(args)-1)
                return errors.Error{file = file, line = 0, col = 0, msg = msg}
            }
            if len(args) >= 2 {
                second_arg := strings.trim_space(args[1])
                // second_arg is "item: Item" — extract the type
                colon := strings.index(second_arg, ":")
                if colon >= 0 {
                    arg_type := strings.trim_space(second_arg[colon+1:])
                    field.snippet_arg_type = arg_type
                }
            }
            // If only 1 arg (just w: io.Writer), snippet_arg_type stays nil
        }
    }

    append(&props.fields, field)
    return nil
}


// ─── children ─────────────────────────────────────────────────────────────────

// parse_children parses a sequence of nodes until a stop condition is met.
// stop_kinds: if the current token matches any of these, we stop (without consuming).
// Pass nil to parse until EOF.
parse_children :: proc(p: ^Parser, stop_kinds: []token.Kind) -> ([dynamic]ast.Node, Maybe(errors.Error)) {
    children := make([dynamic]ast.Node)

    for p.pos < len(p.tokens) {
        tok := peek_tok(p)

        if tok.kind == .EOF { break }

        // Check stop conditions
        if stop_kinds != nil {
            should_stop := false
            for kind in stop_kinds {
                if tok.kind == kind {
                    should_stop = true
                    break
                }
            }
            if should_stop { break }
        }

        // Also stop at end tags / else / end blocks when parsing inside an element
        if stop_kinds != nil {
            if tok.kind == .Tag_End_Open || tok.kind == .Block_End ||
               tok.kind == .Block_Else || tok.kind == .Block_Else_If ||
               tok.kind == .Block_End_Snippet {
                break
            }
        }

        node, err := parse_node(p)
        if err != nil { return children, err }
        if node != nil {
            append(&children, node.(ast.Node))
        }
    }

    return children, nil
}

parse_node :: proc(p: ^Parser) -> (Maybe(ast.Node), Maybe(errors.Error)) {
    tok := peek_tok(p)

    #partial switch tok.kind {
    case .Text:
        advance_tok(p)
        // Skip pure-whitespace text nodes between tags
        content := tok.value
        node := ast.Node(ast.Text{content = content, pos = tok_pos(tok)})
        return node, nil

    case .Tag_Open:
        return parse_element(p)

    case .Expr_Open:
        return parse_expression(p)

    case .Block_If:
        return parse_if_block(p)

    case .Block_Each:
        return parse_each_block(p)

    case .Block_Snippet:
        return parse_snippet_def(p)

    case .Render:
        tok2 := advance_tok(p)
        name, args := parse_render_expr(tok2.value)
        node := ast.Node(ast.Render_Call{name = name, args = args, pos = tok_pos(tok2)})
        return node, nil

    case .Html_Raw:
        tok2 := advance_tok(p)
        content := strings.trim_space(tok2.value)
        node := ast.Node(ast.Raw_Html{content = content, pos = tok_pos(tok2)})
        return node, nil

    case .Comment:
        advance_tok(p)
        return nil, nil

    case .Doctype:
        tok2 := advance_tok(p)
        // tok2.value already contains the full doctype string (e.g. "<!DOCTYPE html>")
        node := ast.Node(ast.Raw_Html{content = tok2.value, pos = tok_pos(tok2), is_literal = true})
        return node, nil

    case:
        // Unknown token in node position — skip it to avoid infinite loops
        advance_tok(p)
        return nil, nil
    }
}

// ─── element ──────────────────────────────────────────────────────────────────

parse_element :: proc(p: ^Parser) -> (Maybe(ast.Node), Maybe(errors.Error)) {
    // consume Tag_Open '<'
    open_tok := advance_tok(p)
    pos := tok_pos(open_tok)

    // next token: Tag_Name or Component_Name
    name_tok := peek_tok(p)
    if name_tok.kind == .Component_Name {
        return parse_component(p, pos)
    }

    if name_tok.kind != .Tag_Name {
        return nil, nil
    }
    advance_tok(p)
    tag := name_tok.value

    // <slot /> is an alias for {@render children()}
    if tag == "slot" {
        // Consume remaining tokens until Tag_Self_Close or Tag_Close
        for p.pos < len(p.tokens) {
            tok := peek_tok(p)
            if tok.kind == .Tag_Self_Close || tok.kind == .Tag_Close || tok.kind == .EOF {
                advance_tok(p)
                break
            }
            advance_tok(p)
        }
        node := ast.Node(ast.Render_Call{name = "children", args = nil, pos = pos})
        return node, nil
    }

    // <svelte:head> — parse children and store in doc.svelte_head for injection into <head>
    if tag == "svelte:head" {
        // Consume remaining attrs/close of opening tag
        for p.pos < len(p.tokens) {
            tok := peek_tok(p)
            if tok.kind == .Tag_Close || tok.kind == .Tag_Self_Close || tok.kind == .EOF { break }
            advance_tok(p)
        }
        if peek_tok(p).kind == .Tag_Self_Close {
            advance_tok(p)
            return nil, nil
        }
        advance_tok(p) // consume >

        // Parse children until </svelte:head>
        children, child_err := parse_children(p, {.Tag_End_Open})
        if child_err_val, has_err := child_err.?; has_err {
            return nil, child_err_val
        }

        // Consume </svelte:head>
        for p.pos < len(p.tokens) {
            t := advance_tok(p)
            if t.kind == .Tag_Close { break }
        }

        // Store in document's svelte_head
        for child in children {
            append(&p.doc.svelte_head, child)
        }
        delete(children)

        return nil, nil
    }

    // <svelte:body>, <svelte:window>, etc. — skip entirely for SSR
    if strings.has_prefix(tag, "svelte:") {
        depth := 1
        for p.pos < len(p.tokens) {
            tok := advance_tok(p)
            if tok.kind == .Tag_Self_Close { depth -= 1 }
            if tok.kind == .Tag_Open { depth += 1 }
            if tok.kind == .Tag_End_Open {
                // consume closing tag name and >
                for p.pos < len(p.tokens) {
                    t := advance_tok(p)
                    if t.kind == .Tag_Close { break }
                }
                depth -= 1
            }
            if depth <= 0 || tok.kind == .EOF { break }
        }
        return nil, nil
    }

    el := ast.Element{tag = tag, pos = pos}
    el.attributes = make([dynamic]ast.Attribute)
    el.children = make([dynamic]ast.Node)

    // Parse attributes
    attrs, err := parse_attributes(p)
    if err != nil { return nil, err }
    el.attributes = attrs

    // Self-closing or regular close
    next := peek_tok(p)
    if next.kind == .Tag_Self_Close {
        advance_tok(p)
        el.self_close = true
        node := ast.Node(el)
        return node, nil
    }

    // consume Tag_Close '>'
    if next.kind == .Tag_Close {
        advance_tok(p)
    }

    // Parse children until we hit </tag>
    children, cerr := parse_element_children(p, tag)
    if cerr != nil { return nil, cerr }
    el.children = children

    node := ast.Node(el)
    return node, nil
}

parse_element_children :: proc(p: ^Parser, tag: string) -> ([dynamic]ast.Node, Maybe(errors.Error)) {
    children := make([dynamic]ast.Node)

    for p.pos < len(p.tokens) {
        tok := peek_tok(p)

        if tok.kind == .EOF { break }

        // Check for closing tag: Tag_End_Open followed by matching Tag_Name
        if tok.kind == .Tag_End_Open {
            // peek ahead to see if the next tag name matches
            next := peek_tok(p, 1)
            if next.kind == .Tag_Name && next.value == tag {
                // consume </tag>
                advance_tok(p) // Tag_End_Open
                advance_tok(p) // Tag_Name
                // consume Tag_Close
                if peek_tok(p).kind == .Tag_Close {
                    advance_tok(p)
                }
                break
            } else if next.kind == .Component_Name {
                // This is a component closing tag — stop and let the parent handle it
                break
            } else {
                // Mismatched end tag — stop anyway
                break
            }
        }

        node, err := parse_node(p)
        if err != nil { return children, err }
        if node != nil {
            append(&children, node.(ast.Node))
        }
    }

    return children, nil
}

// ─── component ────────────────────────────────────────────────────────────────

parse_component :: proc(p: ^Parser, pos: token.Pos) -> (Maybe(ast.Node), Maybe(errors.Error)) {
    // name_tok is Component_Name e.g. "card.Card"
    name_tok := advance_tok(p)
    full_name := name_tok.value

    // split "pkg.Name" into pkg and name
    // For dot-style (ohtml): "card.Card" -> pkg="card", name="Card"
    // For bare-name (svelte): "Badge" -> pkg="Badge", name="Badge"
    dot_idx := strings.index(full_name, ".")
    pkg := full_name
    name := full_name
    if dot_idx >= 0 {
        pkg = full_name[:dot_idx]
        name = full_name[dot_idx+1:]
    }

    comp := ast.Component{pkg = pkg, name = name, pos = pos}
    comp.attributes = make([dynamic]ast.Attribute)
    comp.children = make([dynamic]ast.Node)

    attrs, err := parse_attributes(p)
    if err != nil { return nil, err }
    comp.attributes = attrs

    next := peek_tok(p)
    if next.kind == .Tag_Self_Close {
        advance_tok(p)
        comp.self_close = true
        node := ast.Node(comp)
        return node, nil
    }

    if next.kind == .Tag_Close {
        advance_tok(p)
    }

    // Parse children until matching </pkg.Name>
    children, cerr := parse_component_children(p, full_name)
    if cerr != nil { return nil, cerr }
    comp.children = children

    node := ast.Node(comp)
    return node, nil
}

parse_component_children :: proc(p: ^Parser, full_name: string) -> ([dynamic]ast.Node, Maybe(errors.Error)) {
    children := make([dynamic]ast.Node)

    for p.pos < len(p.tokens) {
        tok := peek_tok(p)
        if tok.kind == .EOF { break }

        if tok.kind == .Tag_End_Open {
            next := peek_tok(p, 1)
            if next.kind == .Component_Name && next.value == full_name {
                advance_tok(p) // Tag_End_Open
                advance_tok(p) // Component_Name
                if peek_tok(p).kind == .Tag_Close {
                    advance_tok(p)
                }
                break
            } else {
                break
            }
        }

        node, err := parse_node(p)
        if err != nil { return children, err }
        if node != nil {
            append(&children, node.(ast.Node))
        }
    }

    return children, nil
}

// ─── attributes ───────────────────────────────────────────────────────────────

parse_attributes :: proc(p: ^Parser) -> ([dynamic]ast.Attribute, Maybe(errors.Error)) {
    attrs := make([dynamic]ast.Attribute)

    for p.pos < len(p.tokens) {
        tok := peek_tok(p)

        // Stop at end of tag
        if tok.kind == .Tag_Close || tok.kind == .Tag_Self_Close || tok.kind == .EOF {
            break
        }

        if tok.kind != .Attr_Name {
            break
        }

        attr_tok := advance_tok(p)
        attr := ast.Attribute{name = attr_tok.value, pos = tok_pos(attr_tok)}

        // Check for '=' following
        next := peek_tok(p)
        if next.kind == .Attr_Eq {
            advance_tok(p) // consume '='
            // Next is either Attr_Value (static) or Expr_Open (dynamic)
            val_tok := peek_tok(p)
            if val_tok.kind == .Attr_Value {
                advance_tok(p)
                attr.value = ast.Static_Value{value = val_tok.value}
            } else if val_tok.kind == .Expr_Open {
                advance_tok(p) // consume Expr_Open
                expr_tok := peek_tok(p)
                if expr_tok.kind == .Expr_Content {
                    advance_tok(p)
                    attr.value = ast.Dynamic_Value{expr = expr_tok.value}
                }
                // consume Expr_Close
                if peek_tok(p).kind == .Expr_Close {
                    advance_tok(p)
                }
            }
        } else {
            // Boolean shorthand
            attr.value = ast.Bool_Shorthand{}
        }

        append(&attrs, attr)
    }

    return attrs, nil
}

// ─── expression ───────────────────────────────────────────────────────────────

parse_expression :: proc(p: ^Parser) -> (Maybe(ast.Node), Maybe(errors.Error)) {
    open_tok := advance_tok(p) // consume Expr_Open
    pos := tok_pos(open_tok)

    content := ""
    if peek_tok(p).kind == .Expr_Content {
        content = advance_tok(p).value
    }
    // consume Expr_Close
    if peek_tok(p).kind == .Expr_Close {
        advance_tok(p)
    }

    node := ast.Node(ast.Expression{content = content, pos = pos})
    return node, nil
}

// ─── if block ─────────────────────────────────────────────────────────────────

parse_if_block :: proc(p: ^Parser) -> (Maybe(ast.Node), Maybe(errors.Error)) {
    if_tok := advance_tok(p) // consume Block_If, value = condition
    pos := tok_pos(if_tok)
    condition := if_tok.value

    ib := ast.If_Block{condition = condition, pos = pos}
    ib.children = make([dynamic]ast.Node)
    ib.else_ifs = make([dynamic]ast.Else_If)

    // Parse children until {:else if}, {:else}, or {/if}
    stop_kinds := []token.Kind{.Block_Else_If, .Block_Else, .Block_End}
    children, err := parse_children_with_stops(p, stop_kinds)
    if err != nil { return nil, err }
    ib.children = children

    // Handle {:else if ...} chains
    for p.pos < len(p.tokens) && peek_tok(p).kind == .Block_Else_If {
        else_if_tok := advance_tok(p)
        ei_cond := else_if_tok.value
        ei := ast.Else_If{condition = ei_cond}
        ei.children = make([dynamic]ast.Node)

        ei_children, ei_err := parse_children_with_stops(p, stop_kinds)
        if ei_err != nil { return nil, ei_err }
        ei.children = ei_children
        append(&ib.else_ifs, ei)
    }

    // Handle {:else}
    if p.pos < len(p.tokens) && peek_tok(p).kind == .Block_Else {
        advance_tok(p) // consume Block_Else
        else_children, else_err := parse_children_with_stops(p, []token.Kind{.Block_End})
        if else_err != nil { return nil, else_err }
        ib.else_body = else_children
    }

    // consume {/if}
    if p.pos < len(p.tokens) && peek_tok(p).kind == .Block_End {
        advance_tok(p)
    }

    node := ast.Node(ib)
    return node, nil
}

// ─── each block ───────────────────────────────────────────────────────────────

parse_each_block :: proc(p: ^Parser) -> (Maybe(ast.Node), Maybe(errors.Error)) {
    each_tok := advance_tok(p) // consume Block_Each, value = "items as item" or "items as item, i"
    pos := tok_pos(each_tok)
    expr := each_tok.value

    iterable, binding, index := parse_each_expr(expr)

    eb := ast.Each_Block{
        iterable = iterable,
        binding  = binding,
        index    = index,
        pos      = pos,
    }
    eb.children = make([dynamic]ast.Node)

    stop_kinds := []token.Kind{.Block_Else, .Block_End}
    children, err := parse_children_with_stops(p, stop_kinds)
    if err != nil { return nil, err }
    eb.children = children

    // {:else}
    if p.pos < len(p.tokens) && peek_tok(p).kind == .Block_Else {
        advance_tok(p)
        else_children, else_err := parse_children_with_stops(p, []token.Kind{.Block_End})
        if else_err != nil { return nil, else_err }
        eb.else_body = else_children
    }

    // {/each}
    if p.pos < len(p.tokens) && peek_tok(p).kind == .Block_End {
        advance_tok(p)
    }

    node := ast.Node(eb)
    return node, nil
}

parse_each_expr :: proc(expr: string) -> (iterable: string, binding: string, index: Maybe(string)) {
    // Format: "items as item" or "items as item, i"
    as_idx := strings.index(expr, " as ")
    if as_idx < 0 {
        return strings.trim_space(expr), "", nil
    }

    iterable = strings.trim_space(expr[:as_idx])
    rest := strings.trim_space(expr[as_idx+4:])

    // Check for index: "item, i"
    comma_idx := strings.index(rest, ",")
    if comma_idx >= 0 {
        binding = strings.trim_space(rest[:comma_idx])
        idx := strings.trim_space(rest[comma_idx+1:])
        index = idx
    } else {
        binding = strings.trim_space(rest)
        index = nil
    }

    return iterable, binding, index
}

// ─── snippet def ──────────────────────────────────────────────────────────────

parse_snippet_def :: proc(p: ^Parser) -> (Maybe(ast.Node), Maybe(errors.Error)) {
    snip_tok := advance_tok(p) // consume Block_Snippet, value = "name(param: Type)"
    pos := tok_pos(snip_tok)
    sig := snip_tok.value

    name, param_name, param_type := parse_snippet_sig(sig)

    sd := ast.Snippet_Def{
        name       = name,
        param_name = param_name,
        param_type = param_type,
        pos        = pos,
    }
    sd.children = make([dynamic]ast.Node)

    stop_kinds := []token.Kind{.Block_End_Snippet}
    children, err := parse_children_with_stops(p, stop_kinds)
    if err != nil { return nil, err }
    sd.children = children

    // consume {/snippet}
    if p.pos < len(p.tokens) && peek_tok(p).kind == .Block_End_Snippet {
        advance_tok(p)
    }

    node := ast.Node(sd)
    return node, nil
}

parse_snippet_sig :: proc(sig: string) -> (name: string, param_name: Maybe(string), param_type: Maybe(string)) {
    // Format: "name" or "name(param: Type)"
    paren_idx := strings.index(sig, "(")
    if paren_idx < 0 {
        return strings.trim_space(sig), nil, nil
    }

    name = strings.trim_space(sig[:paren_idx])
    rest := sig[paren_idx+1:]
    close_idx := strings.last_index(rest, ")")
    if close_idx < 0 {
        return name, nil, nil
    }

    params_str := strings.trim_space(rest[:close_idx])
    if len(params_str) == 0 {
        return name, nil, nil
    }

    // Parse "param: Type"
    colon_idx := strings.index(params_str, ":")
    if colon_idx < 0 {
        return name, params_str, nil
    }

    pname := strings.trim_space(params_str[:colon_idx])
    ptype := strings.trim_space(params_str[colon_idx+1:])
    return name, pname, ptype
}

// ─── render call ──────────────────────────────────────────────────────────────

parse_render_expr :: proc(expr: string) -> (name: string, args: Maybe(string)) {
    // Format: "children()" or "row(item)"
    paren_idx := strings.index(expr, "(")
    if paren_idx < 0 {
        return strings.trim_space(expr), nil
    }

    name = strings.trim_space(expr[:paren_idx])
    rest := expr[paren_idx+1:]
    close_idx := strings.last_index(rest, ")")
    if close_idx < 0 {
        return name, nil
    }

    args_str := strings.trim_space(rest[:close_idx])
    if len(args_str) == 0 {
        return name, nil
    }
    return name, args_str
}

// ─── parse_children_with_stops ────────────────────────────────────────────────

// parse_children_with_stops parses nodes until the current token is one of the stop kinds.
// Unlike parse_children, this version does NOT implicitly stop at Tag_End_Open or Block_End —
// it only stops at the explicitly provided kinds.
parse_children_with_stops :: proc(p: ^Parser, stop_kinds: []token.Kind) -> ([dynamic]ast.Node, Maybe(errors.Error)) {
    children := make([dynamic]ast.Node)

    for p.pos < len(p.tokens) {
        tok := peek_tok(p)
        if tok.kind == .EOF { break }

        // Check explicit stop kinds
        for kind in stop_kinds {
            if tok.kind == kind {
                return children, nil
            }
        }

        node, err := parse_node(p)
        if err != nil { return children, err }
        if node != nil {
            append(&children, node.(ast.Node))
        }
    }

    return children, nil
}
