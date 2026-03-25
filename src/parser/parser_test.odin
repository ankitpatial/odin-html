// src/parser/parser_test.odin
package parser

import "core:testing"
import "../ast"

@(test)
test_parse_plain_html :: proc(t: ^testing.T) {
    src := `<div><h1>Hello World</h1></div>`
    doc, err := parse(src, "test.ohtml")
    testing.expect(t, err == nil, "should parse without error")
    testing.expect_value(t, len(doc.children), 1)
    div := doc.children[0].(ast.Element)
    testing.expect_value(t, div.tag, "div")
    h1 := div.children[0].(ast.Element)
    testing.expect_value(t, h1.tag, "h1")
    text := h1.children[0].(ast.Text)
    testing.expect_value(t, text.content, "Hello World")
}

@(test)
test_parse_self_closing :: proc(t: ^testing.T) {
    src := `<br />`
    doc, _ := parse(src, "test.ohtml")
    el := doc.children[0].(ast.Element)
    testing.expect_value(t, el.self_close, true)
}

@(test)
test_parse_script_block :: proc(t: ^testing.T) {
    src := `<script lang="odin">
import "core:fmt"

Props :: struct {
    name: string,
    count: int,
}
</script>
<div></div>`
    doc, _ := parse(src, "test.ohtml")
    script, has := doc.script.?
    testing.expect(t, has, "should have script")
    testing.expect_value(t, len(script.imports), 1)
    testing.expect_value(t, script.imports[0].path, "core:fmt")
    props, has_props := script.props.?
    testing.expect(t, has_props, "should have props")
    testing.expect_value(t, len(props.fields), 2)
    testing.expect_value(t, props.fields[0].name, "name")
    testing.expect_value(t, props.fields[0].type_expr, "string")
}

@(test)
test_parse_snippet_props :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    children: proc(w: io.Writer),
    row: proc(w: io.Writer, item: Item),
}
</script>
<div></div>`
    doc, _ := parse(src, "test.ohtml")
    props := doc.script.?.props.?
    testing.expect_value(t, props.fields[0].is_snippet, true)
    testing.expect(t, props.fields[0].snippet_arg_type == nil, "children has no arg type")
    testing.expect_value(t, props.fields[1].is_snippet, true)
    arg_type := props.fields[1].snippet_arg_type.?
    testing.expect_value(t, arg_type, "Item")
}

@(test)
test_parse_expression :: proc(t: ^testing.T) {
    src := `<h1>{title}</h1>`
    doc, _ := parse(src, "test.ohtml")
    h1 := doc.children[0].(ast.Element)
    expr := h1.children[0].(ast.Expression)
    testing.expect_value(t, expr.content, "title")
}

@(test)
test_parse_raw_html :: proc(t: ^testing.T) {
    src := `<div>{@html raw_content}</div>`
    doc, _ := parse(src, "test.ohtml")
    div := doc.children[0].(ast.Element)
    raw := div.children[0].(ast.Raw_Html)
    testing.expect_value(t, raw.content, "raw_content")
}

@(test)
test_parse_if_block :: proc(t: ^testing.T) {
    src := `{#if show}<span>Yes</span>{:else}<span>No</span>{/if}`
    doc, _ := parse(src, "test.ohtml")
    if_block := doc.children[0].(ast.If_Block)
    testing.expect_value(t, if_block.condition, "show")
    testing.expect_value(t, len(if_block.children), 1)
    else_body := if_block.else_body.?
    testing.expect_value(t, len(else_body), 1)
}

@(test)
test_parse_else_if :: proc(t: ^testing.T) {
    src := `{#if a}<span>A</span>{:else if b}<span>B</span>{:else}<span>C</span>{/if}`
    doc, _ := parse(src, "test.ohtml")
    if_block := doc.children[0].(ast.If_Block)
    testing.expect_value(t, len(if_block.else_ifs), 1)
    testing.expect_value(t, if_block.else_ifs[0].condition, "b")
}

@(test)
test_parse_each_block :: proc(t: ^testing.T) {
    src := `{#each items as item}<li>{item.name}</li>{/each}`
    doc, _ := parse(src, "test.ohtml")
    each := doc.children[0].(ast.Each_Block)
    testing.expect_value(t, each.iterable, "items")
    testing.expect_value(t, each.binding, "item")
}

@(test)
test_parse_each_with_index :: proc(t: ^testing.T) {
    src := `{#each items as item, i}<li>{i}</li>{/each}`
    doc, _ := parse(src, "test.ohtml")
    each := doc.children[0].(ast.Each_Block)
    idx := each.index.?
    testing.expect_value(t, idx, "i")
}

@(test)
test_parse_each_else :: proc(t: ^testing.T) {
    src := `{#each items as item}<li>{item.name}</li>{:else}<p>Empty</p>{/each}`
    doc, _ := parse(src, "test.ohtml")
    each := doc.children[0].(ast.Each_Block)
    else_body := each.else_body.?
    testing.expect_value(t, len(else_body), 1)
}

@(test)
test_parse_snippet_def :: proc(t: ^testing.T) {
    src := `{#snippet row(item: Item)}<li>{item.name}</li>{/snippet}`
    doc, _ := parse(src, "test.ohtml")
    snippet := doc.children[0].(ast.Snippet_Def)
    testing.expect_value(t, snippet.name, "row")
    pname := snippet.param_name.?
    testing.expect_value(t, pname, "item")
    ptype := snippet.param_type.?
    testing.expect_value(t, ptype, "Item")
}

@(test)
test_parse_render_call :: proc(t: ^testing.T) {
    src := `<div>{@render children()}{@render row(item)}</div>`
    doc, _ := parse(src, "test.ohtml")
    div := doc.children[0].(ast.Element)
    r1 := div.children[0].(ast.Render_Call)
    testing.expect_value(t, r1.name, "children")
    r2 := div.children[1].(ast.Render_Call)
    testing.expect_value(t, r2.name, "row")
    arg := r2.args.?
    testing.expect_value(t, arg, "item")
}

@(test)
test_parse_component :: proc(t: ^testing.T) {
    src := `<card.Card title="Hello"><p>Child</p></card.Card>`
    doc, _ := parse(src, "test.ohtml")
    comp := doc.children[0].(ast.Component)
    testing.expect_value(t, comp.pkg, "card")
    testing.expect_value(t, comp.name, "Card")
    testing.expect_value(t, len(comp.attributes), 1)
    testing.expect_value(t, len(comp.children), 1)
}

@(test)
test_parse_self_closing_component :: proc(t: ^testing.T) {
    src := `<button.Button label="Click" />`
    doc, _ := parse(src, "test.ohtml")
    comp := doc.children[0].(ast.Component)
    testing.expect_value(t, comp.self_close, true)
}

@(test)
test_parse_static_attr :: proc(t: ^testing.T) {
    src := `<div class="card" id="main"></div>`
    doc, _ := parse(src, "test.ohtml")
    div := doc.children[0].(ast.Element)
    testing.expect_value(t, len(div.attributes), 2)
    _, is_static := div.attributes[0].value.(ast.Static_Value)
    testing.expect(t, is_static, "should be Static_Value")
}

@(test)
test_parse_dynamic_attr :: proc(t: ^testing.T) {
    src := `<div class={cls}></div>`
    doc, _ := parse(src, "test.ohtml")
    div := doc.children[0].(ast.Element)
    dyn, is_dyn := div.attributes[0].value.(ast.Dynamic_Value)
    testing.expect(t, is_dyn, "should be Dynamic_Value")
    testing.expect_value(t, dyn.expr, "cls")
}

@(test)
test_reject_snippet_2_args :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    callback: proc(w: io.Writer, a: Item, b: Other),
}
</script>
<div></div>`
    _, err := parse(src, "test.ohtml")
    e, has_err := err.?
    testing.expect(t, has_err, "should report error for snippet with 2+ args")
    _ = e
}
