// src/codegen/codegen_test.odin
package codegen

import "core:testing"
import "core:strings"
import "../ast"
import "../parser"

@(test)
test_gen_plain_html :: proc(t: ^testing.T) {
    src := `<div><h1>Hello World</h1></div>`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "hello")
    testing.expect(t, strings.contains(result, "package hello"))
    testing.expect(t, strings.contains(result, "render :: proc(w: io.Writer)"))
    testing.expect(t, strings.contains(result, `"<div><h1>Hello World</h1></div>"`))
}

@(test)
test_gen_props_and_string_expr :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    name: string,
}
</script>
<h1>Hello, {name}!</h1>`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "greeting")
    testing.expect(t, strings.contains(result, "Props :: struct"))
    testing.expect(t, strings.contains(result, "render :: proc(w: io.Writer, props: Props)"))
    testing.expect(t, strings.contains(result, "runtime.html_escape(w, props.name)"))
}

@(test)
test_gen_non_string_expr :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    count: int,
}
</script>
<span>{count}</span>`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "counter")
    testing.expect(t, strings.contains(result, "runtime.html_escape(w, fmt.tprint(props.count))"))
}

@(test)
test_gen_raw_html :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { content: string }
</script>
<div>{@html content}</div>`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "raw")
    testing.expect(t, strings.contains(result, "io.write_string(w, props.content)"))
}

@(test)
test_gen_dynamic_attr :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { cls: string }
</script>
<div class={cls}></div>`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "dynattr")
    testing.expect(t, strings.contains(result, "runtime.html_escape(w, props.cls)"))
}

@(test)
test_gen_boolean_attr :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { disabled: bool }
</script>
<button disabled={disabled}></button>`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "boolattr")
    testing.expect(t, strings.contains(result, "if props.disabled"))
}

@(test)
test_gen_if_block :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { show: bool }
</script>
{#if show}<span>Yes</span>{:else}<span>No</span>{/if}`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "iftest")
    testing.expect(t, strings.contains(result, "if props.show"))
    testing.expect(t, strings.contains(result, "} else {"))
}

@(test)
test_gen_each_block :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { items: []string }
</script>
{#each items as item}<li>{item}</li>{/each}`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "eachtest")
    testing.expect(t, strings.contains(result, "for item in props.items"))
}

@(test)
test_gen_each_with_index :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { items: []string }
</script>
{#each items as item, i}<li>{i}</li>{/each}`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "idxtest")
    testing.expect(t, strings.contains(result, "for item, i in props.items"))
}

@(test)
test_gen_each_else :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { items: []string }
</script>
{#each items as item}<li>{item}</li>{:else}<p>Empty</p>{/each}`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "eachelse")
    testing.expect(t, strings.contains(result, "len(props.items)"))
}

@(test)
test_gen_children :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    title: string,
    children: proc(w: io.Writer),
}
</script>
<div><h2>{title}</h2>{@render children()}</div>`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "card")
    testing.expect(t, strings.contains(result, "children: runtime.Children"))
    testing.expect(t, strings.contains(result, "runtime.children_render(w, props.children)"))
}

@(test)
test_gen_typed_snippet :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    items: []string,
    row: proc(w: io.Writer, item: string),
}
</script>
{#each items as item}{@render row(item)}{/each}`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "list")
    testing.expect(t, strings.contains(result, "row: runtime.Snippet(string)"))
    testing.expect(t, strings.contains(result, "runtime.snippet_render"))
}

@(test)
test_gen_layout_inlining :: proc(t: ^testing.T) {
    root_layout, _ := parser.parse(`<!DOCTYPE html><html><body>{@render children()}</body></html>`, "views/+layout.ohtml")
    about_layout, _ := parser.parse(`<div class="about-wrapper">{@render children()}</div>`, "views/about/+layout.ohtml")
    about_page, _ := parser.parse(`<script lang="odin">
Props :: struct { title: string }
</script>
<h1>{title}</h1>`, "views/about/+page.ohtml")

    layout_chain := []ast.Document{root_layout, about_layout}
    result := generate_page(about_page, "about", layout_chain)

    testing.expect(t, strings.contains(result, "<!DOCTYPE html>"), "should contain doctype from root layout")
    testing.expect(t, strings.contains(result, "about-wrapper"), "should contain about-wrapper from nested layout")
    testing.expect(t, strings.contains(result, "props.title"), "should contain props.title from page")
}

@(test)
test_whitespace_collapse :: proc(t: ^testing.T) {
    src := `<div>
    <span>Hello</span>
    <span>World</span>
</div>`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "ws")
    // Should not have excessive whitespace in the output
    // The generated write_string calls should have collapsed whitespace
    testing.expect(t, !strings.contains(result, `"\n    "`), "should not have raw newlines in output strings")
}

@(test)
test_text_node_whitespace :: proc(t: ^testing.T) {
    src := `<p>Hello  World</p>`
    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "txt")
    testing.expect(t, strings.contains(result, "Hello  World"), "should preserve text node whitespace")
}
