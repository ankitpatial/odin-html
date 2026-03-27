// src/lexer/lexer_test.odin
package lexer

import "core:testing"
import "../token"

// ─── helpers ──────────────────────────────────────────────────────────────────

// find_token searches tokens for the first occurrence of the given kind and
// returns (token, true) if found, otherwise (zero, false).
find_token :: proc(tokens: [dynamic]token.Token, kind: token.Kind) -> (token.Token, bool) {
    for t in tokens {
        if t.kind == kind { return t, true }
    }
    return {}, false
}

// find_token_with_value searches for the first token matching both kind and value.
find_token_with_value :: proc(tokens: [dynamic]token.Token, kind: token.Kind, value: string) -> bool {
    for t in tokens {
        if t.kind == kind && t.value == value { return true }
    }
    return false
}

// has_sequence checks that kinds appear in order (not necessarily consecutive)
// in the token stream.
has_sequence :: proc(tokens: [dynamic]token.Token, kinds: []token.Kind) -> bool {
    idx := 0
    for t in tokens {
        if idx >= len(kinds) { break }
        if t.kind == kinds[idx] { idx += 1 }
    }
    return idx == len(kinds)
}

// count_kind counts how many tokens of the given kind exist.
count_kind :: proc(tokens: [dynamic]token.Token, kind: token.Kind) -> int {
    n := 0
    for t in tokens { if t.kind == kind { n += 1 } }
    return n
}

// ─── tests ────────────────────────────────────────────────────────────────────

@(test)
test_plain_html :: proc(t: ^testing.T) {
    src    := "<div><h1>Hello World</h1></div>"
    tokens := tokenize(src)
    defer delete(tokens)

    // Opening <div>
    testing.expect(t, has_sequence(tokens, []token.Kind{.Tag_Open, .Tag_Name}),
        "expected Tag_Open followed by Tag_Name")

    // <h1>
    testing.expect(t, find_token_with_value(tokens, .Tag_Name, "div"),
        "expected Tag_Name('div')")
    testing.expect(t, find_token_with_value(tokens, .Tag_Name, "h1"),
        "expected Tag_Name('h1')")

    // Text node
    testing.expect(t, find_token_with_value(tokens, .Text, "Hello World"),
        "expected Text('Hello World')")

    // </h1> close  -->  Tag_End_Open
    testing.expect(t, count_kind(tokens, .Tag_End_Open) == 2,
        "expected 2 Tag_End_Open tokens")
    testing.expect(t, count_kind(tokens, .Tag_Close) >= 4,
        "expected at least 4 Tag_Close tokens")
}

@(test)
test_self_closing :: proc(t: ^testing.T) {
    src    := "<br />"
    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect(t, has_sequence(tokens, []token.Kind{.Tag_Open, .Tag_Name, .Tag_Self_Close}),
        "expected Tag_Open, Tag_Name, Tag_Self_Close sequence")
    testing.expect(t, find_token_with_value(tokens, .Tag_Name, "br"),
        "expected Tag_Name('br')")
}

@(test)
test_script_block :: proc(t: ^testing.T) {
    src := `<script lang="odin">import "core:fmt"
Props :: struct { name: string }</script><div></div>`
    tokens := tokenize(src)
    defer delete(tokens)

    _, ok := find_token(tokens, .Script_Open)
    testing.expect(t, ok, "expected Script_Open")

    sc, ok2 := find_token(tokens, .Script_Content)
    testing.expect(t, ok2, "expected Script_Content")
    // content should contain the odin source
    has_import := len(sc.value) > 0
    testing.expect(t, has_import, "Script_Content should not be empty")

    _, ok3 := find_token(tokens, .Script_Close)
    testing.expect(t, ok3, "expected Script_Close")

    // After </script>, HTML should continue
    testing.expect(t, find_token_with_value(tokens, .Tag_Name, "div"),
        "expected Tag_Name('div') after script block")
}

@(test)
test_expression :: proc(t: ^testing.T) {
    src    := "<h1>{title}</h1>"
    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect(t, has_sequence(tokens, []token.Kind{.Expr_Open, .Expr_Content, .Expr_Close}),
        "expected Expr_Open, Expr_Content, Expr_Close")
    testing.expect(t, find_token_with_value(tokens, .Expr_Content, "title"),
        "expected Expr_Content('title')")
}

@(test)
test_if_block :: proc(t: ^testing.T) {
    src    := "{#if show}<span>Yes</span>{:else}<span>No</span>{/if}"
    tokens := tokenize(src)
    defer delete(tokens)

    bi, ok := find_token(tokens, .Block_If)
    testing.expect(t, ok, "expected Block_If")
    testing.expect(t, bi.value == "show", "Block_If value should be 'show'")

    _, ok2 := find_token(tokens, .Block_Else)
    testing.expect(t, ok2, "expected Block_Else")

    bend, ok3 := find_token(tokens, .Block_End)
    testing.expect(t, ok3, "expected Block_End")
    testing.expect(t, bend.value == "if", "Block_End value should be 'if'")
}

@(test)
test_else_if :: proc(t: ^testing.T) {
    src    := "{#if a}<span>A</span>{:else if b}<span>B</span>{/if}"
    tokens := tokenize(src)
    defer delete(tokens)

    bi, ok := find_token(tokens, .Block_If)
    testing.expect(t, ok, "expected Block_If")
    testing.expect(t, bi.value == "a", "Block_If value should be 'a'")

    bei, ok2 := find_token(tokens, .Block_Else_If)
    testing.expect(t, ok2, "expected Block_Else_If")
    testing.expect(t, bei.value == "b", "Block_Else_If value should be 'b'")

    bend, ok3 := find_token(tokens, .Block_End)
    testing.expect(t, ok3, "expected Block_End")
    testing.expect(t, bend.value == "if", "Block_End value should be 'if'")
}

@(test)
test_each_block :: proc(t: ^testing.T) {
    src    := "{#each items as item}<li>{item.name}</li>{/each}"
    tokens := tokenize(src)
    defer delete(tokens)

    be, ok := find_token(tokens, .Block_Each)
    testing.expect(t, ok, "expected Block_Each")
    testing.expect(t, be.value == "items as item",
        "Block_Each value should be 'items as item'")

    bend, ok2 := find_token(tokens, .Block_End)
    testing.expect(t, ok2, "expected Block_End")
    testing.expect(t, bend.value == "each", "Block_End value should be 'each'")
}

@(test)
test_each_with_index :: proc(t: ^testing.T) {
    src    := "{#each items as item, i}<li>{i}</li>{/each}"
    tokens := tokenize(src)
    defer delete(tokens)

    be, ok := find_token(tokens, .Block_Each)
    testing.expect(t, ok, "expected Block_Each")
    testing.expect(t, be.value == "items as item, i",
        "Block_Each value should be 'items as item, i'")
}

@(test)
test_render :: proc(t: ^testing.T) {
    src    := "{@render children()}"
    tokens := tokenize(src)
    defer delete(tokens)

    r, ok := find_token(tokens, .Render)
    testing.expect(t, ok, "expected Render token")
    testing.expect(t, r.value == "children()", "Render value should be 'children()'")
}

@(test)
test_html_raw :: proc(t: ^testing.T) {
    src    := "{@html raw_content}"
    tokens := tokenize(src)
    defer delete(tokens)

    hr, ok := find_token(tokens, .Html_Raw)
    testing.expect(t, ok, "expected Html_Raw token")
    testing.expect(t, hr.value == "raw_content", "Html_Raw value should be 'raw_content'")
}

@(test)
test_snippet_block :: proc(t: ^testing.T) {
    src    := "{#snippet row(item: Item)}<li>{item.name}</li>{/snippet}"
    tokens := tokenize(src)
    defer delete(tokens)

    bs, ok := find_token(tokens, .Block_Snippet)
    testing.expect(t, ok, "expected Block_Snippet")
    testing.expect(t, bs.value == "row(item: Item)",
        "Block_Snippet value should be 'row(item: Item)'")

    _, ok2 := find_token(tokens, .Block_End_Snippet)
    testing.expect(t, ok2, "expected Block_End_Snippet")
}

@(test)
test_static_attributes :: proc(t: ^testing.T) {
    src    := `<div class="card" id="main"></div>`
    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect(t, find_token_with_value(tokens, .Attr_Name, "class"),
        "expected Attr_Name('class')")
    testing.expect(t, find_token_with_value(tokens, .Attr_Value, "card"),
        "expected Attr_Value('card')")
    testing.expect(t, find_token_with_value(tokens, .Attr_Name, "id"),
        "expected Attr_Name('id')")
    testing.expect(t, find_token_with_value(tokens, .Attr_Value, "main"),
        "expected Attr_Value('main')")

    // There should be two Attr_Eq tokens
    testing.expect(t, count_kind(tokens, .Attr_Eq) == 2, "expected 2 Attr_Eq tokens")
}

@(test)
test_dynamic_attribute :: proc(t: ^testing.T) {
    src    := "<div class={cls}></div>"
    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect(t, find_token_with_value(tokens, .Attr_Name, "class"),
        "expected Attr_Name('class')")
    testing.expect(t, count_kind(tokens, .Attr_Eq) >= 1, "expected Attr_Eq")
    testing.expect(t, find_token_with_value(tokens, .Expr_Content, "cls"),
        "expected Expr_Content('cls')")
}

@(test)
test_component_tag :: proc(t: ^testing.T) {
    src    := `<card.Card title="Hello"></card.Card>`
    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect(t, find_token_with_value(tokens, .Component_Name, "card.Card"),
        "expected Component_Name('card.Card')")
    testing.expect(t, find_token_with_value(tokens, .Attr_Name, "title"),
        "expected Attr_Name('title')")
    testing.expect(t, find_token_with_value(tokens, .Attr_Value, "Hello"),
        "expected Attr_Value('Hello')")
}

@(test)
test_self_closing_component :: proc(t: ^testing.T) {
    src    := `<button.Button label="Click" />`
    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect(t, find_token_with_value(tokens, .Component_Name, "button.Button"),
        "expected Component_Name('button.Button')")
    testing.expect(t, find_token_with_value(tokens, .Attr_Name, "label"),
        "expected Attr_Name('label')")
    testing.expect(t, find_token_with_value(tokens, .Attr_Value, "Click"),
        "expected Attr_Value('Click')")
    _, ok := find_token(tokens, .Tag_Self_Close)
    testing.expect(t, ok, "expected Tag_Self_Close")
}

@(test)
test_nested_braces_in_expr :: proc(t: ^testing.T) {
    src    := `<span>{fmt.tprintf("%d", count)}</span>`
    tokens := tokenize(src)
    defer delete(tokens)

    ec, ok := find_token(tokens, .Expr_Content)
    testing.expect(t, ok, "expected Expr_Content")
    testing.expect(t, ec.value == `fmt.tprintf("%d", count)`,
        "Expr_Content should contain the full expression including inner braces")
}
