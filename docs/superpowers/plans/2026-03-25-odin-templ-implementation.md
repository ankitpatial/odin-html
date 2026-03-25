# odin-templ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a CLI tool in Odin that compiles `.ohtml` template files (Svelte 5-inspired syntax) into `.odin` source files for zero-overhead SSR.

**Architecture:** Three-stage compiler pipeline (Lexer → Parser → CodeGen) with a Resolver pass between Parser and CodeGen. The CLI discovers `.ohtml` files, runs them through the pipeline, and writes generated `.odin` files to an output directory.

**Tech Stack:** Odin (stdlib only — `core:os`, `core:io`, `core:strings`, `core:fmt`, `core:flags`, `core:testing`, `core:unicode/utf8`, `core:path/filepath`)

**Spec:** `docs/superpowers/specs/2026-03-25-odin-templ-design.md`

---

## File Structure

```
src/
    main.odin                  # package main — CLI entry, arg parsing, orchestration
    token/
        token.odin             # Token type enum + Token struct
    lexer/
        lexer.odin             # Tokenizer: .ohtml source → token stream
        lexer_test.odin        # Lexer tests
    ast/
        ast.odin               # AST node types (Document, Element, Expr, IfBlock, etc.)
    parser/
        parser.odin            # Parser: token stream → AST
        parser_test.odin       # Parser tests
    resolver/
        resolver.odin          # Resolver: validate imports, props, component refs, layout chains
        resolver_test.odin     # Resolver tests
    codegen/
        codegen.odin           # Code generator: resolved AST → .odin source string
        codegen_test.odin      # CodeGen tests
    runtime_gen/
        runtime_gen.odin       # Writes the gen/runtime/ package (escape.odin, snippet.odin)
    errors/
        errors.odin            # Error type with file, line, col, message
testdata/
    simple/
        hello/
            Hello.ohtml        # Basic component, no props
    props/
        greeting/
            Greeting.ohtml     # Component with string prop
    expressions/
        counter/
            Counter.ohtml      # Non-string expression, fmt.tprint
    control_flow/
        list/
            List.ohtml         # {#if}, {#each}, {:else}
    attributes/
        link/
            Link.ohtml         # Dynamic + boolean attributes
    children/
        card/
            Card.ohtml         # Component with children
    snippets/
        table/
            Table.ohtml        # Component with typed snippet
    composition/
        components/
            card/
                Card.ohtml
            badge/
                Badge.ohtml
        pages/
            home/
                +page.ohtml    # Uses card.Card and badge.Badge
    layouts/
        views/
            +layout.ohtml      # Root layout
            +page.ohtml        # Home page
            about/
                +layout.ohtml  # Nested layout
                +page.ohtml    # About page
```

---

## Task 1: Project Scaffold + Error Types

**Files:**
- Create: `src/errors/errors.odin`
- Create: `src/main.odin` (stub)

- [ ] **Step 1: Create error types**

```odin
// src/errors/errors.odin
package errors

import "core:fmt"

Error :: struct {
    file: string,
    line: int,
    col:  int,
    msg:  string,
}

format :: proc(e: Error) -> string {
    return fmt.tprintf("%s:%d:%d - error: %s", e.file, e.line, e.col, e.msg)
}
```

- [ ] **Step 2: Create main.odin stub**

```odin
// src/main.odin
package main

import "core:fmt"
import "core:os"

main :: proc() {
    fmt.println("odin-templ v0.1.0")
}
```

- [ ] **Step 3: Verify it builds**

Run: `odin build src/ -out:odin-templ`
Expected: compiles with no errors

- [ ] **Step 4: Commit**

```bash
git add src/
git commit -m "feat: project scaffold with error types and main stub"
```

---

## Task 2: Token Types

**Files:**
- Create: `src/token/token.odin`

- [ ] **Step 1: Define token types**

```odin
// src/token/token.odin
package token

Kind :: enum {
    // Structural
    EOF,
    Error,

    // Script block
    Script_Open,        // <script lang="odin">
    Script_Close,       // </script>
    Script_Content,     // raw Odin code inside script

    // HTML
    Tag_Open,           // <
    Tag_Close,          // >
    Tag_Self_Close,     // />
    Tag_End_Open,       // </
    Tag_Name,           // div, span, etc.
    Attr_Name,          // class, id, etc.
    Attr_Eq,            // =
    Attr_Value,         // "static-value"
    Text,               // raw text between tags
    Doctype,            // <!DOCTYPE html>
    Comment,            // <!-- ... -->

    // Expressions
    Expr_Open,          // { (start of expression)
    Expr_Close,         // } (end of expression)
    Expr_Content,       // expression body text

    // Control flow
    Block_If,           // {#if
    Block_Else,         // {:else}
    Block_Else_If,      // {:else if
    Block_Each,         // {#each
    Block_End,          // {/if} or {/each}

    // Snippets
    Block_Snippet,      // {#snippet
    Block_End_Snippet,  // {/snippet}
    Render,             // {@render
    Html_Raw,           // {@html

    // Component
    Component_Name,     // pkg.ComponentName
}

Token :: struct {
    kind:  Kind,
    value: string,
    line:  int,
    col:   int,
}

Pos :: struct {
    line: int,
    col:  int,
}
```

- [ ] **Step 2: Verify it builds**

Run: `odin build src/ -out:odin-templ`
Expected: compiles (token package imported by main as placeholder)

- [ ] **Step 3: Commit**

```bash
git add src/token/
git commit -m "feat: define token types for .ohtml lexer"
```

---

## Task 3: Lexer — Script Block + HTML Basics

**Files:**
- Create: `src/lexer/lexer.odin`
- Create: `src/lexer/lexer_test.odin`
- Create: `testdata/simple/hello/Hello.ohtml`

- [ ] **Step 1: Create test fixture**

```html
<!-- testdata/simple/hello/Hello.ohtml -->
<div>
    <h1>Hello World</h1>
</div>
```

- [ ] **Step 2: Write the failing test — tokenize plain HTML**

```odin
// src/lexer/lexer_test.odin
package lexer

import "core:testing"
import "../token"

@(test)
test_plain_html :: proc(t: ^testing.T) {
    src := `<div>
    <h1>Hello World</h1>
</div>`

    tokens := tokenize(src)
    defer delete(tokens)

    // <div>
    testing.expect_value(t, tokens[0].kind, token.Kind.Tag_Open)
    testing.expect_value(t, tokens[1].kind, token.Kind.Tag_Name)
    testing.expect_value(t, tokens[1].value, "div")
    testing.expect_value(t, tokens[2].kind, token.Kind.Tag_Close)

    // text node
    testing.expect_value(t, tokens[3].kind, token.Kind.Text)

    // <h1>
    testing.expect_value(t, tokens[4].kind, token.Kind.Tag_Open)
    testing.expect_value(t, tokens[5].kind, token.Kind.Tag_Name)
    testing.expect_value(t, tokens[5].value, "h1")
    testing.expect_value(t, tokens[6].kind, token.Kind.Tag_Close)

    // Hello World
    testing.expect_value(t, tokens[7].kind, token.Kind.Text)
    testing.expect_value(t, tokens[7].value, "Hello World")

    // </h1>
    testing.expect_value(t, tokens[8].kind, token.Kind.Tag_End_Open)
    testing.expect_value(t, tokens[9].kind, token.Kind.Tag_Name)
    testing.expect_value(t, tokens[9].value, "h1")
    testing.expect_value(t, tokens[10].kind, token.Kind.Tag_Close)
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `odin test src/lexer/`
Expected: FAIL — `tokenize` not defined

- [ ] **Step 4: Implement lexer — HTML tokenization**

```odin
// src/lexer/lexer.odin
package lexer

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

// Core lexer procedures: peek, advance, emit, lex_all, lex_tag, lex_text, etc.
// (Full implementation of HTML tokenization — tags, attributes, text nodes,
//  self-closing tags, end tags, comments, doctype)
```

The full implementation covers:
- `lex_all` — main loop dispatching to `lex_tag` or `lex_text`
- `lex_tag` — handles `<tagname`, attributes, `>`, `/>`, `</tagname>`
- `lex_text` — collects text until `<` or `{`
- `lex_attrs` — handles `name="value"` and `name={expr}`
- Helper procs: `peek`, `advance`, `at_end`, `emit`

- [ ] **Step 5: Run test to verify it passes**

Run: `odin test src/lexer/`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/lexer/ testdata/simple/
git commit -m "feat: lexer tokenizes plain HTML elements and text"
```

---

## Task 4: Lexer — Script Block

**Files:**
- Modify: `src/lexer/lexer.odin`
- Modify: `src/lexer/lexer_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
@(test)
test_script_block :: proc(t: ^testing.T) {
    src := `<script lang="odin">
import "core:fmt"

Props :: struct {
    name: string,
}
</script>
<div>{name}</div>`

    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect_value(t, tokens[0].kind, token.Kind.Script_Open)
    testing.expect_value(t, tokens[1].kind, token.Kind.Script_Content)
    testing.expect(t, len(tokens[1].value) > 0, "script content should not be empty")
    testing.expect_value(t, tokens[2].kind, token.Kind.Script_Close)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/lexer/`
Expected: FAIL

- [ ] **Step 3: Implement script block tokenization**

Add `lex_script` proc to `lexer.odin`:
- Detects `<script lang="odin">` as `Script_Open`
- Captures everything until `</script>` as `Script_Content`
- Emits `Script_Close`

- [ ] **Step 4: Run test to verify it passes**

Run: `odin test src/lexer/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/lexer/
git commit -m "feat: lexer handles <script lang=\"odin\"> blocks"
```

---

## Task 5: Lexer — Expressions + Control Flow

**Files:**
- Modify: `src/lexer/lexer.odin`
- Modify: `src/lexer/lexer_test.odin`

- [ ] **Step 1: Write the failing test — expressions**

```odin
@(test)
test_expressions :: proc(t: ^testing.T) {
    src := `<h1>{title}</h1>`

    tokens := tokenize(src)
    defer delete(tokens)

    // Find the expression tokens
    found_expr := false
    for tok in tokens {
        if tok.kind == .Expr_Open {
            found_expr = true
            break
        }
    }
    testing.expect(t, found_expr, "should find Expr_Open token")
}

@(test)
test_control_flow :: proc(t: ^testing.T) {
    src := `{#if show}<span>Yes</span>{:else}<span>No</span>{/if}`

    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect_value(t, tokens[0].kind, token.Kind.Block_If)
    // Find Block_Else
    found_else := false
    for tok in tokens {
        if tok.kind == .Block_Else { found_else = true; break }
    }
    testing.expect(t, found_else, "should find Block_Else token")
}

@(test)
test_each_block :: proc(t: ^testing.T) {
    src := `{#each items as item}<li>{item.name}</li>{/each}`

    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect_value(t, tokens[0].kind, token.Kind.Block_Each)
}

@(test)
test_render_and_html :: proc(t: ^testing.T) {
    src := `{@render children()}{@html raw_content}`

    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect_value(t, tokens[0].kind, token.Kind.Render)
    // Find Html_Raw
    found_raw := false
    for tok in tokens {
        if tok.kind == .Html_Raw { found_raw = true; break }
    }
    testing.expect(t, found_raw, "should find Html_Raw token")
}

@(test)
test_snippet_block :: proc(t: ^testing.T) {
    src := `{#snippet row(item: Item)}<li>{item.name}</li>{/snippet}`

    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect_value(t, tokens[0].kind, token.Kind.Block_Snippet)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/lexer/`
Expected: FAIL

- [ ] **Step 3: Implement expression and control flow tokenization**

Extend `lex_all` to detect `{` and dispatch:
- `{#if` → `Block_If` + capture condition
- `{:else if` → `Block_Else_If` + capture condition
- `{:else}` → `Block_Else`
- `{/if}` or `{/each}` → `Block_End`
- `{#each` → `Block_Each` + capture expression
- `{#snippet` → `Block_Snippet` + capture signature
- `{/snippet}` → `Block_End_Snippet`
- `{@render` → `Render` + capture call
- `{@html` → `Html_Raw` + capture expression
- Otherwise → `Expr_Open` + `Expr_Content` + `Expr_Close`

Handle nested braces in expressions (e.g., `{fmt.tprintf("%d", count)}`).

- [ ] **Step 4: Run tests to verify they pass**

Run: `odin test src/lexer/`
Expected: PASS (all tests)

- [ ] **Step 5: Commit**

```bash
git add src/lexer/
git commit -m "feat: lexer handles expressions, control flow, snippets, render, html"
```

---

## Task 6: Lexer — Attributes (Static + Dynamic)

**Files:**
- Modify: `src/lexer/lexer.odin`
- Modify: `src/lexer/lexer_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
@(test)
test_static_attributes :: proc(t: ^testing.T) {
    src := `<div class="card" id="main"></div>`
    tokens := tokenize(src)
    defer delete(tokens)

    // <div
    testing.expect_value(t, tokens[0].kind, token.Kind.Tag_Open)
    testing.expect_value(t, tokens[1].kind, token.Kind.Tag_Name)
    // class="card"
    testing.expect_value(t, tokens[2].kind, token.Kind.Attr_Name)
    testing.expect_value(t, tokens[2].value, "class")
    testing.expect_value(t, tokens[3].kind, token.Kind.Attr_Eq)
    testing.expect_value(t, tokens[4].kind, token.Kind.Attr_Value)
    testing.expect_value(t, tokens[4].value, "card")
}

@(test)
test_dynamic_attributes :: proc(t: ^testing.T) {
    src := `<div class={cls}></div>`
    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect_value(t, tokens[2].kind, token.Kind.Attr_Name)
    testing.expect_value(t, tokens[2].value, "class")
    testing.expect_value(t, tokens[3].kind, token.Kind.Attr_Eq)
    testing.expect_value(t, tokens[4].kind, token.Kind.Expr_Open)
}

@(test)
test_boolean_attribute :: proc(t: ^testing.T) {
    src := `<button disabled={is_disabled}></button>`
    tokens := tokenize(src)
    defer delete(tokens)

    // Find disabled attr
    found_disabled := false
    for tok in tokens {
        if tok.kind == .Attr_Name && tok.value == "disabled" {
            found_disabled = true
            break
        }
    }
    testing.expect(t, found_disabled, "should find disabled attribute")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/lexer/`
Expected: FAIL

- [ ] **Step 3: Implement attribute tokenization in lex_tag**

Extend `lex_tag` / `lex_attrs` to handle:
- `name="value"` → Attr_Name, Attr_Eq, Attr_Value
- `name={expr}` → Attr_Name, Attr_Eq, Expr_Open, Expr_Content, Expr_Close
- `name` alone (boolean shorthand, no `=`)

- [ ] **Step 4: Run tests to verify they pass**

Run: `odin test src/lexer/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/lexer/
git commit -m "feat: lexer handles static, dynamic, and boolean attributes"
```

---

## Task 7: Lexer — Component References

**Files:**
- Modify: `src/lexer/lexer.odin`
- Modify: `src/lexer/lexer_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
@(test)
test_component_tag :: proc(t: ^testing.T) {
    src := `<card.Card title="Hello"></card.Card>`
    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect_value(t, tokens[0].kind, token.Kind.Tag_Open)
    testing.expect_value(t, tokens[1].kind, token.Kind.Component_Name)
    testing.expect_value(t, tokens[1].value, "card.Card")
}

@(test)
test_self_closing_component :: proc(t: ^testing.T) {
    src := `<button.Button label="Click" />`
    tokens := tokenize(src)
    defer delete(tokens)

    testing.expect_value(t, tokens[1].kind, token.Kind.Component_Name)
    testing.expect_value(t, tokens[1].value, "button.Button")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/lexer/`
Expected: FAIL

- [ ] **Step 3: Implement component name detection**

In `lex_tag`, after reading the tag name, check if it contains `.` or starts with uppercase — emit `Component_Name` instead of `Tag_Name`.

Detection rule: if tag name contains `.` (e.g., `card.Card`) → `Component_Name`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `odin test src/lexer/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/lexer/
git commit -m "feat: lexer detects component references (pkg.Component)"
```

---

## Task 8: AST Types

**Files:**
- Create: `src/ast/ast.odin`

- [ ] **Step 1: Define AST node types**

```odin
// src/ast/ast.odin
package ast

import "../token"

// Top-level document
Document :: struct {
    file:     string,
    script:   Maybe(Script_Block),
    children: [dynamic]Node,
}

// <script lang="odin"> block
Script_Block :: struct {
    imports: [dynamic]Import,
    props:   Maybe(Props_Def),
    raw:     string,   // full script content for passthrough
}

Import :: struct {
    alias: Maybe(string),
    path:  string,
}

Props_Def :: struct {
    fields: [dynamic]Prop_Field,
}

Prop_Field :: struct {
    name:       string,
    type_expr:  string,
    is_snippet: bool,       // true if proc(w: io.Writer, ...)
    snippet_arg_type: Maybe(string), // nil for Children, "Item" for Snippet(Item)
}

// AST Nodes (union)
Node :: union {
    Element,
    Text,
    Expression,
    Raw_Html,
    If_Block,
    Each_Block,
    Snippet_Def,
    Render_Call,
    Component,
}

Element :: struct {
    tag:        string,
    attributes: [dynamic]Attribute,
    children:   [dynamic]Node,
    self_close: bool,
    pos:        token.Pos,
}

Text :: struct {
    content: string,
    pos:     token.Pos,
}

Expression :: struct {
    content: string,  // e.g., "title" or "fmt.tprintf(\"%d\", count)"
    pos:     token.Pos,
}

Raw_Html :: struct {
    content: string,
    pos:     token.Pos,
}

Attribute :: struct {
    name:       string,
    value:      Attr_Value,
    pos:        token.Pos,
}

Attr_Value :: union {
    Static_Value,
    Dynamic_Value,
    Bool_Shorthand,  // attribute with no value, e.g., <input required>
}

Static_Value :: struct {
    value: string,
}

Dynamic_Value :: struct {
    expr: string,
}

Bool_Shorthand :: struct {}

If_Block :: struct {
    condition:   string,
    children:    [dynamic]Node,
    else_ifs:    [dynamic]Else_If,
    else_body:   Maybe([dynamic]Node),
    pos:         token.Pos,
}

Else_If :: struct {
    condition: string,
    children:  [dynamic]Node,
}

Each_Block :: struct {
    iterable:   string,  // e.g., "items"
    binding:    string,  // e.g., "item"
    index:      Maybe(string), // e.g., "i"
    children:   [dynamic]Node,
    else_body:  Maybe([dynamic]Node),
    pos:        token.Pos,
}

Snippet_Def :: struct {
    name:       string,
    param_name: Maybe(string),
    param_type: Maybe(string),
    children:   [dynamic]Node,
    pos:        token.Pos,
}

Render_Call :: struct {
    name: string,        // e.g., "children" or "row"
    args: Maybe(string), // e.g., "item"
    pos:  token.Pos,
}

Component :: struct {
    pkg:        string,  // e.g., "card"
    name:       string,  // e.g., "Card"
    attributes: [dynamic]Attribute,
    children:   [dynamic]Node,
    self_close: bool,
    pos:        token.Pos,
}
```

- [ ] **Step 2: Verify it builds**

Run: `odin build src/ -out:odin-templ`
Expected: compiles

- [ ] **Step 3: Commit**

```bash
git add src/ast/
git commit -m "feat: define AST node types for .ohtml documents"
```

---

## Task 9: Parser — Plain HTML

**Files:**
- Create: `src/parser/parser.odin`
- Create: `src/parser/parser_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
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

    div, ok := doc.children[0].(ast.Element)
    testing.expect(t, ok, "first child should be Element")
    testing.expect_value(t, div.tag, "div")
    testing.expect_value(t, len(div.children), 1)

    h1, ok2 := div.children[0].(ast.Element)
    testing.expect(t, ok2, "div child should be Element")
    testing.expect_value(t, h1.tag, "h1")

    text, ok3 := h1.children[0].(ast.Text)
    testing.expect(t, ok3, "h1 child should be Text")
    testing.expect_value(t, text.content, "Hello World")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/parser/`
Expected: FAIL

- [ ] **Step 3: Implement parser for HTML elements + text**

```odin
// src/parser/parser.odin
package parser

import "../ast"
import "../token"
import "../lexer"
import "../errors"

Parser :: struct {
    tokens: [dynamic]token.Token,
    pos:    int,
    file:   string,
}

parse :: proc(src: string, file: string) -> (ast.Document, Maybe(errors.Error)) {
    tokens := lexer.tokenize(src)
    p := Parser{ tokens = tokens, pos = 0, file = file }
    doc := ast.Document{ file = file }
    parse_children(&p, &doc.children)
    return doc, nil
}

// Core parsing procs:
// parse_children, parse_node, parse_element, parse_text
// Helper procs: peek, advance, expect, at_end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `odin test src/parser/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/parser/
git commit -m "feat: parser handles plain HTML elements and text nodes"
```

---

## Task 10: Parser — Script Block

**Files:**
- Modify: `src/parser/parser.odin`
- Modify: `src/parser/parser_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
@(test)
test_parse_script_block :: proc(t: ^testing.T) {
    src := `<script lang="odin">
import "core:fmt"

Props :: struct {
    name: string,
    count: int,
}
</script>
<div>{name}</div>`

    doc, err := parse(src, "test.ohtml")
    testing.expect(t, err == nil, "should parse without error")

    script, has_script := doc.script.?
    testing.expect(t, has_script, "should have script block")
    testing.expect_value(t, len(script.imports), 1)
    testing.expect_value(t, script.imports[0].path, "core:fmt")

    props, has_props := script.props.?
    testing.expect(t, has_props, "should have props")
    testing.expect_value(t, len(props.fields), 2)
    testing.expect_value(t, props.fields[0].name, "name")
    testing.expect_value(t, props.fields[0].type_expr, "string")
    testing.expect_value(t, props.fields[1].name, "count")
    testing.expect_value(t, props.fields[1].type_expr, "int")
}

@(test)
test_parse_snippet_prop :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    children: proc(w: io.Writer),
    row: proc(w: io.Writer, item: Item),
}
</script>
<div></div>`

    doc, err := parse(src, "test.ohtml")
    testing.expect(t, err == nil, "should parse without error")

    props, _ := doc.script.?.props.?
    testing.expect_value(t, props.fields[0].is_snippet, true)
    testing.expect(t, props.fields[0].snippet_arg_type == nil, "children has no arg type")
    testing.expect_value(t, props.fields[1].is_snippet, true)

    arg_type, has_arg := props.fields[1].snippet_arg_type.?
    testing.expect(t, has_arg, "row should have arg type")
    testing.expect_value(t, arg_type, "Item")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/parser/`
Expected: FAIL

- [ ] **Step 3: Implement script block parsing**

Add `parse_script` proc:
- Parses import statements (handles aliases)
- Parses `Props :: struct { ... }` — extracts field names, types
- Detects snippet props: `proc(w: io.Writer)` → Children, `proc(w: io.Writer, arg: T)` → Snippet(T)

- [ ] **Step 4: Run test to verify it passes**

Run: `odin test src/parser/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/parser/
git commit -m "feat: parser handles script blocks with imports and Props struct"
```

---

## Task 11: Parser — Expressions + Control Flow

**Files:**
- Modify: `src/parser/parser.odin`
- Modify: `src/parser/parser_test.odin`

- [ ] **Step 1: Write the failing test — expressions**

```odin
@(test)
test_parse_expression :: proc(t: ^testing.T) {
    src := `<h1>{title}</h1>`
    doc, _ := parse(src, "test.ohtml")

    h1 := doc.children[0].(ast.Element)
    expr, ok := h1.children[0].(ast.Expression)
    testing.expect(t, ok, "should be Expression")
    testing.expect_value(t, expr.content, "title")
}

@(test)
test_parse_raw_html :: proc(t: ^testing.T) {
    src := `<div>{@html raw_content}</div>`
    doc, _ := parse(src, "test.ohtml")

    div := doc.children[0].(ast.Element)
    raw, ok := div.children[0].(ast.Raw_Html)
    testing.expect(t, ok, "should be Raw_Html")
    testing.expect_value(t, raw.content, "raw_content")
}
```

- [ ] **Step 2: Write the failing test — if/else**

```odin
@(test)
test_parse_if_block :: proc(t: ^testing.T) {
    src := `{#if show}<span>Yes</span>{:else}<span>No</span>{/if}`
    doc, _ := parse(src, "test.ohtml")

    if_block, ok := doc.children[0].(ast.If_Block)
    testing.expect(t, ok, "should be If_Block")
    testing.expect_value(t, if_block.condition, "show")
    testing.expect_value(t, len(if_block.children), 1)

    else_body, has_else := if_block.else_body.?
    testing.expect(t, has_else, "should have else body")
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
```

- [ ] **Step 3: Write the failing test — each**

```odin
@(test)
test_parse_each_block :: proc(t: ^testing.T) {
    src := `{#each items as item}<li>{item.name}</li>{/each}`
    doc, _ := parse(src, "test.ohtml")

    each, ok := doc.children[0].(ast.Each_Block)
    testing.expect(t, ok, "should be Each_Block")
    testing.expect_value(t, each.iterable, "items")
    testing.expect_value(t, each.binding, "item")
}

@(test)
test_parse_each_with_index :: proc(t: ^testing.T) {
    src := `{#each items as item, i}<li>{i}</li>{/each}`
    doc, _ := parse(src, "test.ohtml")

    each := doc.children[0].(ast.Each_Block)
    idx, has_idx := each.index.?
    testing.expect(t, has_idx, "should have index")
    testing.expect_value(t, idx, "i")
}

@(test)
test_parse_each_else :: proc(t: ^testing.T) {
    src := `{#each items as item}<li>{item.name}</li>{:else}<p>Empty</p>{/each}`
    doc, _ := parse(src, "test.ohtml")

    each := doc.children[0].(ast.Each_Block)
    else_body, has_else := each.else_body.?
    testing.expect(t, has_else, "should have else body")
    testing.expect_value(t, len(else_body), 1)
}
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `odin test src/parser/`
Expected: FAIL

- [ ] **Step 5: Implement expression, if, each parsing**

Extend `parse_node` to handle:
- `Expr_Open` → `parse_expression`
- `Html_Raw` → `parse_raw_html`
- `Block_If` → `parse_if_block` (handles `{:else if}`, `{:else}`, `{/if}`)
- `Block_Each` → `parse_each_block` (handles binding, index, `{:else}`, `{/each}`)

- [ ] **Step 6: Run tests to verify they pass**

Run: `odin test src/parser/`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/parser/
git commit -m "feat: parser handles expressions, if/else, each blocks"
```

---

## Task 12: Parser — Snippets, Render, Components

**Files:**
- Modify: `src/parser/parser.odin`
- Modify: `src/parser/parser_test.odin`

- [ ] **Step 1: Write the failing tests**

```odin
@(test)
test_parse_snippet_def :: proc(t: ^testing.T) {
    src := `{#snippet row(item: Item)}<li>{item.name}</li>{/snippet}`
    doc, _ := parse(src, "test.ohtml")

    snippet, ok := doc.children[0].(ast.Snippet_Def)
    testing.expect(t, ok, "should be Snippet_Def")
    testing.expect_value(t, snippet.name, "row")

    pname, _ := snippet.param_name.?
    testing.expect_value(t, pname, "item")
    ptype, _ := snippet.param_type.?
    testing.expect_value(t, ptype, "Item")
}

@(test)
test_parse_render_call :: proc(t: ^testing.T) {
    src := `<div>{@render children()}{@render row(item)}</div>`
    doc, _ := parse(src, "test.ohtml")

    div := doc.children[0].(ast.Element)

    r1, ok1 := div.children[0].(ast.Render_Call)
    testing.expect(t, ok1, "should be Render_Call")
    testing.expect_value(t, r1.name, "children")

    r2, ok2 := div.children[1].(ast.Render_Call)
    testing.expect(t, ok2, "should be Render_Call")
    testing.expect_value(t, r2.name, "row")
    arg, _ := r2.args.?
    testing.expect_value(t, arg, "item")
}

@(test)
test_parse_component :: proc(t: ^testing.T) {
    src := `<card.Card title="Hello"><p>Child</p></card.Card>`
    doc, _ := parse(src, "test.ohtml")

    comp, ok := doc.children[0].(ast.Component)
    testing.expect(t, ok, "should be Component")
    testing.expect_value(t, comp.pkg, "card")
    testing.expect_value(t, comp.name, "Card")
    testing.expect_value(t, len(comp.attributes), 1)
    testing.expect_value(t, len(comp.children), 1)
}

@(test)
test_parse_self_closing_component :: proc(t: ^testing.T) {
    src := `<button.Button label="Click" />`
    doc, _ := parse(src, "test.ohtml")

    comp, ok := doc.children[0].(ast.Component)
    testing.expect(t, ok, "should be Component")
    testing.expect_value(t, comp.self_close, true)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `odin test src/parser/`
Expected: FAIL

- [ ] **Step 3: Implement snippet, render, component parsing**

Add to parser:
- `parse_snippet_def` — parses `{#snippet name(param: Type)}...{/snippet}`
- `parse_render_call` — parses `{@render name(args)}`
- `parse_component` — parses `<pkg.Name attrs>children</pkg.Name>` or `<pkg.Name attrs />`

- [ ] **Step 4: Run tests to verify they pass**

Run: `odin test src/parser/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/parser/
git commit -m "feat: parser handles snippets, render calls, and components"
```

---

## Task 13: Parser — Attributes (Static + Dynamic)

**Files:**
- Modify: `src/parser/parser.odin`
- Modify: `src/parser/parser_test.odin`

- [ ] **Step 1: Write the failing tests**

```odin
@(test)
test_parse_static_attr :: proc(t: ^testing.T) {
    src := `<div class="card" id="main"></div>`
    doc, _ := parse(src, "test.ohtml")

    div := doc.children[0].(ast.Element)
    testing.expect_value(t, len(div.attributes), 2)

    _, is_static := div.attributes[0].value.(ast.Static_Value)
    testing.expect(t, is_static, "class should be Static_Value")
}

@(test)
test_parse_dynamic_attr :: proc(t: ^testing.T) {
    src := `<div class={cls}></div>`
    doc, _ := parse(src, "test.ohtml")

    div := doc.children[0].(ast.Element)
    dyn, is_dyn := div.attributes[0].value.(ast.Dynamic_Value)
    testing.expect(t, is_dyn, "class should be Dynamic_Value")
    testing.expect_value(t, dyn.expr, "cls")
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `odin test src/parser/`
Expected: FAIL

- [ ] **Step 3: Implement attribute parsing**

Add `parse_attributes` proc that builds `[dynamic]ast.Attribute` from attribute tokens. Dispatches to `Static_Value`, `Dynamic_Value`, or `Bool_Shorthand` based on token pattern.

- [ ] **Step 4: Run tests to verify they pass**

Run: `odin test src/parser/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/parser/
git commit -m "feat: parser handles static, dynamic, and boolean attributes"
```

---

## Task 14: Runtime Generation

**Files:**
- Create: `src/runtime_gen/runtime_gen.odin`

- [ ] **Step 1: Implement runtime generator**

```odin
// src/runtime_gen/runtime_gen.odin
package runtime_gen

import "core:os"
import "core:fmt"
import "core:strings"

GENERATED_HEADER :: "// Code generated by odin-templ. DO NOT EDIT.\n"

// Writes gen/runtime/escape.odin and gen/runtime/snippet.odin
generate :: proc(out_dir: string) -> bool {
    runtime_dir := strings.concatenate({out_dir, "/runtime"})
    os.make_directory(runtime_dir)

    if !write_escape(runtime_dir) { return false }
    if !write_snippet(runtime_dir) { return false }
    return true
}

write_escape :: proc(dir: string) -> bool {
    // Writes escape.odin with html_escape proc
    // (exact code from spec)
}

write_snippet :: proc(dir: string) -> bool {
    // Writes snippet.odin with Children and Snippet($T) types
    // (exact code from spec)
}
```

- [ ] **Step 2: Verify it builds**

Run: `odin build src/ -out:odin-templ`
Expected: compiles

- [ ] **Step 3: Commit**

```bash
git add src/runtime_gen/
git commit -m "feat: runtime generator writes escape.odin and snippet.odin"
```

---

## Task 15: Code Generator — Basic Component

**Files:**
- Create: `src/codegen/codegen.odin`
- Create: `src/codegen/codegen_test.odin`
- Create: `testdata/simple/hello/Hello.ohtml`

- [ ] **Step 1: Create test fixture**

```html
<!-- testdata/simple/hello/Hello.ohtml -->
<div>
    <h1>Hello World</h1>
</div>
```

- [ ] **Step 2: Write the failing test**

```odin
// src/codegen/codegen_test.odin
package codegen

import "core:testing"
import "core:strings"
import "../parser"

@(test)
test_gen_plain_html :: proc(t: ^testing.T) {
    src := `<div><h1>Hello World</h1></div>`
    doc, _ := parser.parse(src, "test.ohtml")

    result := generate(doc, "hello")
    testing.expect(t, strings.contains(result, "package hello"), "should have package decl")
    testing.expect(t, strings.contains(result, "render :: proc(w: io.Writer)"), "should have render proc")
    testing.expect(t, strings.contains(result, `io.write_string(w, "<div><h1>Hello World</h1></div>")`), "should write static HTML")
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `odin test src/codegen/`
Expected: FAIL

- [ ] **Step 4: Implement basic code generator**

```odin
// src/codegen/codegen.odin
package codegen

import "core:strings"
import "../ast"

generate :: proc(doc: ast.Document, pkg_name: string) -> string {
    b := strings.builder_make()
    // Write header comment
    // Write package declaration
    // Write imports (core:io, gen/runtime)
    // Write Props struct if present
    // Write render proc
    //   - Walk AST children, emit io.write_string for static HTML
    //   - Collapse adjacent static text into single write calls
    return strings.to_string(b)
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `odin test src/codegen/`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/codegen/ testdata/simple/
git commit -m "feat: codegen generates render proc for plain HTML"
```

---

## Task 16: Code Generator — Props + Expressions

**Files:**
- Modify: `src/codegen/codegen.odin`
- Modify: `src/codegen/codegen_test.odin`
- Create: `testdata/props/greeting/Greeting.ohtml`

- [ ] **Step 1: Create test fixture**

```html
<!-- testdata/props/greeting/Greeting.ohtml -->
<script lang="odin">
Props :: struct {
    name: string,
    count: int,
}
</script>
<h1>Hello, {name}!</h1>
<span>{count} items</span>
```

- [ ] **Step 2: Write the failing test**

```odin
@(test)
test_gen_props_and_expressions :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    name: string,
    count: int,
}
</script>
<h1>Hello, {name}!</h1>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "greeting")

    testing.expect(t, strings.contains(result, "Props :: struct"), "should have Props struct")
    testing.expect(t, strings.contains(result, "render :: proc(w: io.Writer, props: Props)"), "should take Props param")
    testing.expect(t, strings.contains(result, "runtime.html_escape(w, props.name)"), "should escape string prop")
}

@(test)
test_gen_non_string_expression :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    count: int,
}
</script>
<span>{count}</span>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "counter")

    testing.expect(t, strings.contains(result, "runtime.html_escape(w, fmt.tprint(props.count))"), "should convert int via fmt.tprint and escape")
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `odin test src/codegen/`
Expected: FAIL

- [ ] **Step 4: Implement Props generation and expression escaping**

Extend `generate`:
- If `doc.script.props` exists, emit `Props :: struct { ... }`
- `render` proc signature becomes `proc(w: io.Writer, props: Props)`
- For `Expression` nodes: if prop type is `string`, emit `runtime.html_escape(w, props.<name>)`; otherwise emit `runtime.html_escape(w, fmt.tprint(props.<name>))`
- Add `import "core:fmt"` when `fmt.tprint` is used

- [ ] **Step 5: Run test to verify it passes**

Run: `odin test src/codegen/`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/codegen/ testdata/props/
git commit -m "feat: codegen generates Props struct and escaped expressions"
```

---

## Task 17: Code Generator — Raw HTML + Attributes

**Files:**
- Modify: `src/codegen/codegen.odin`
- Modify: `src/codegen/codegen_test.odin`

- [ ] **Step 1: Write the failing tests**

```odin
@(test)
test_gen_raw_html :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { content: string }
</script>
<div>{@html content}</div>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "raw")

    testing.expect(t, strings.contains(result, "io.write_string(w, props.content)"), "should write raw without escaping")
    testing.expect(t, !strings.contains(result, "html_escape") || strings.count(result, "html_escape") == 0 ||
        !strings.contains(result, "html_escape(w, props.content)"), "should NOT escape raw html content")
}

@(test)
test_gen_dynamic_attr :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { cls: string }
</script>
<div class={cls}></div>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "dynattr")

    // Dynamic attrs are double-quoted and escaped
    testing.expect(t, strings.contains(result, `io.write_string(w, " class=\"")`), "should open attr with quote")
    testing.expect(t, strings.contains(result, "runtime.html_escape(w, props.cls)"), "should escape attr value")
}

@(test)
test_gen_boolean_attr :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { disabled: bool }
</script>
<button disabled={disabled}></button>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "boolattr")

    testing.expect(t, strings.contains(result, "if props.disabled"), "should conditionally render bool attr")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/codegen/`
Expected: FAIL

- [ ] **Step 3: Implement raw HTML and attribute generation**

- `Raw_Html` node → `io.write_string(w, props.<name>)` (no escaping)
- Static attributes → baked into the HTML string
- Dynamic attributes → `io.write_string(w, " name=\"")` + `runtime.html_escape(w, expr)` + `io.write_string(w, "\"")`
- Boolean attributes → `if props.<name> { io.write_string(w, " disabled") }`

- [ ] **Step 4: Run tests to verify they pass**

Run: `odin test src/codegen/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/codegen/
git commit -m "feat: codegen handles raw HTML, dynamic attrs, boolean attrs"
```

---

## Task 18: Code Generator — Control Flow

**Files:**
- Modify: `src/codegen/codegen.odin`
- Modify: `src/codegen/codegen_test.odin`

- [ ] **Step 1: Write the failing tests**

```odin
@(test)
test_gen_if_block :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { show: bool }
</script>
{#if show}<span>Yes</span>{:else}<span>No</span>{/if}`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "iftest")

    testing.expect(t, strings.contains(result, "if props.show"), "should generate if statement")
    testing.expect(t, strings.contains(result, "} else {"), "should generate else branch")
}

@(test)
test_gen_each_block :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { items: []string }
</script>
{#each items as item}<li>{item}</li>{/each}`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "eachtest")

    testing.expect(t, strings.contains(result, "for item in props.items"), "should generate for loop")
}

@(test)
test_gen_each_with_index :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { items: []string }
</script>
{#each items as item, i}<li>{i}</li>{/each}`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "idxtest")

    testing.expect(t, strings.contains(result, "for item, i in props.items"),
                  "should generate for loop with index (value first, index second in Odin)")
}

@(test)
test_gen_each_else :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct { items: []string }
</script>
{#each items as item}<li>{item}</li>{:else}<p>Empty</p>{/each}`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "eachelse")

    testing.expect(t, strings.contains(result, "len(props.items) == 0") ||
                      strings.contains(result, "len(props.items) > 0"),
                  "should check collection length for else")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/codegen/`
Expected: FAIL

- [ ] **Step 3: Implement control flow generation**

- `If_Block` → `if <condition> { ... } else if <condition> { ... } else { ... }`
  - Prefix prop references: `show` → `props.show`
- `Each_Block` → `if len(props.<iterable>) > 0 { for item in props.<iterable> { ... } } else { ... }` (when else body present)
  - Without else: `for item in props.<iterable> { ... }`
  - With index: `for item, i in props.<iterable> { ... }` (Odin syntax: value first, index second)
- Loop variables (`item`, `i`) are NOT prefixed with `props.`
- **Scope stack**: the codegen maintains a `[dynamic]map[string]bool` scope stack. Push a new scope on entering `{#each}` or `{#snippet}` blocks, registering the binding/param names. When resolving a bare name in an expression, walk the scope stack top-down; if found in any scope, use the name bare (it's a local variable). If not found, prefix with `props.`. Pop scope on leaving the block.

- [ ] **Step 4: Run tests to verify they pass**

Run: `odin test src/codegen/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/codegen/
git commit -m "feat: codegen generates if/else and each loops with else fallback"
```

---

## Task 19: Code Generator — Children (runtime.Children)

**Files:**
- Modify: `src/codegen/codegen.odin`
- Modify: `src/codegen/codegen_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
@(test)
test_gen_children_prop :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    title: string,
    children: proc(w: io.Writer),
}
</script>
<div><h2>{title}</h2>{@render children()}</div>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "card")

    testing.expect(t, strings.contains(result, "children: runtime.Children"), "should translate to runtime.Children")
    testing.expect(t, strings.contains(result, "runtime.children_render(w, props.children)"), "should call children_render")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/codegen/`
Expected: FAIL

- [ ] **Step 3: Implement Children generation**

- In Props struct generation: `proc(w: io.Writer)` → `runtime.Children`
- `Render_Call` for "children" → `runtime.children_render(w, props.children)`

- [ ] **Step 4: Run test to verify it passes**

Run: `odin test src/codegen/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/codegen/
git commit -m "feat: codegen generates runtime.Children for child content"
```

---

## Task 20: Code Generator — Typed Snippets (runtime.Snippet)

**Files:**
- Modify: `src/codegen/codegen.odin`
- Modify: `src/codegen/codegen_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
@(test)
test_gen_typed_snippet :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    items: []Item,
    row: proc(w: io.Writer, item: Item),
}
</script>
{#each items as item}{@render row(item)}{/each}`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "list")

    testing.expect(t, strings.contains(result, "row: runtime.Snippet(Item)"), "should translate to runtime.Snippet(Item)")
    testing.expect(t, strings.contains(result, "runtime.snippet_render(Item, w, props.row, item)"),
        "should call snippet_render with type and arg")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/codegen/`
Expected: FAIL

- [ ] **Step 3: Implement typed snippet generation**

- In Props struct: `proc(w: io.Writer, item: Item)` → `runtime.Snippet(Item)`
- `Render_Call` with args → `runtime.snippet_render(T, w, props.<name>, <arg>)`

- [ ] **Step 4: Run test to verify it passes**

Run: `odin test src/codegen/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/codegen/
git commit -m "feat: codegen generates runtime.Snippet(T) for typed snippets"
```

---

## Task 21: Code Generator — Snippet Call Sites (Context Structs)

**Files:**
- Modify: `src/codegen/codegen.odin`
- Modify: `src/codegen/codegen_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
@(test)
test_gen_snippet_call_site :: proc(t: ^testing.T) {
    // Simulates: a page using <card.Card> with inline children
    // The codegen needs to produce a context struct + standalone render proc
    src := `<script lang="odin">
import "components/card"
Props :: struct { user_name: string }
</script>
<card.Card title="Welcome"><p>Hello, {user_name}!</p></card.Card>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "page")

    // Should generate context struct
    testing.expect(t, strings.contains(result, "_ctx :: struct"), "should generate context struct")
    // Should generate standalone render proc
    testing.expect(t, strings.contains(result, "_render :: proc(w: io.Writer, ctx: rawptr)"),
        "should generate standalone render proc")
    // Should create Snippet with func and ctx
    testing.expect(t, strings.contains(result, "runtime.Children{"), "should construct Children struct")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/codegen/`
Expected: FAIL

- [ ] **Step 3: Implement snippet call site generation**

When a `Component` node has children:
1. Analyze which outer-scope variables the children reference
2. Generate a `_<component>_children_ctx :: struct { ... }` with those captured vars
3. Generate a `_<component>_children_render :: proc(w: io.Writer, ctx: rawptr) { ... }`
4. In the render body, create the ctx instance and pass to `runtime.Children{ func = ..., ctx = &ctx }`

- [ ] **Step 4: Run test to verify it passes**

Run: `odin test src/codegen/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/codegen/
git commit -m "feat: codegen generates context structs for snippet call sites"
```

---

## Task 22: Code Generator — Inline Snippet Definitions

**Files:**
- Modify: `src/codegen/codegen.odin`
- Modify: `src/codegen/codegen_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
@(test)
test_gen_inline_snippet_def :: proc(t: ^testing.T) {
    src := `<script lang="odin">
import "components/table"
Props :: struct { items: []Item }
</script>
<table.Table items={items}>
{#snippet row(item: Item)}<tr><td>{item.name}</td></tr>{/snippet}
</table.Table>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "page")

    // Should generate a typed snippet render proc
    testing.expect(t, strings.contains(result, "_render :: proc(w: io.Writer, ctx: rawptr, arg: Item)"),
        "should generate typed snippet render proc")
    testing.expect(t, strings.contains(result, "runtime.Snippet(Item){"),
        "should construct typed Snippet")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/codegen/`
Expected: FAIL

- [ ] **Step 3: Implement inline snippet definition codegen**

When a `Component` contains `Snippet_Def` children:
1. Generate a context struct capturing any outer-scope variables referenced
2. Generate a render proc matching the snippet's signature: `proc(w: io.Writer, ctx: rawptr, arg: T)`
3. Pass as `runtime.Snippet(T){ func = ..., ctx = &ctx }` to the component

- [ ] **Step 4: Run test to verify it passes**

Run: `odin test src/codegen/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/codegen/
git commit -m "feat: codegen handles inline snippet definitions at call sites"
```

---

## Task 23: Resolver — Component + Import Validation

**Files:**
- Create: `src/resolver/resolver.odin`
- Create: `src/resolver/resolver_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
// src/resolver/resolver_test.odin
package resolver

import "core:testing"
import "../ast"
import "../parser"

@(test)
test_resolve_valid_component :: proc(t: ^testing.T) {
    // Simulate a project with known components
    registry := make_registry()
    register_component(&registry, "components/card", "Card")

    src := `<script lang="odin">
import "components/card"
</script>
<card.Card title="Hello"></card.Card>`

    doc, _ := parser.parse(src, "test.ohtml")
    errs := resolve(&doc, registry)
    testing.expect_value(t, len(errs), 0)
}

@(test)
test_resolve_unknown_component :: proc(t: ^testing.T) {
    registry := make_registry()

    src := `<script lang="odin">
import "components/card"
</script>
<card.Card title="Hello"></card.Card>`

    doc, _ := parser.parse(src, "test.ohtml")
    errs := resolve(&doc, registry)
    testing.expect(t, len(errs) > 0, "should report unknown component")
}

@(test)
test_resolve_missing_import :: proc(t: ^testing.T) {
    registry := make_registry()
    register_component(&registry, "components/card", "Card")

    src := `<card.Card title="Hello"></card.Card>`

    doc, _ := parser.parse(src, "test.ohtml")
    errs := resolve(&doc, registry)
    testing.expect(t, len(errs) > 0, "should report missing import")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/resolver/`
Expected: FAIL

- [ ] **Step 3: Implement resolver**

```odin
// src/resolver/resolver.odin
package resolver

import "../ast"
import "../errors"

Registry :: struct {
    components: map[string]map[string]bool, // pkg_path -> {component_names}
}

make_registry :: proc() -> Registry { ... }
register_component :: proc(r: ^Registry, pkg_path: string, name: string) { ... }

resolve :: proc(doc: ^ast.Document, registry: Registry) -> [dynamic]errors.Error {
    errs := make([dynamic]errors.Error)
    // 1. Build import map from doc.script.imports
    // 2. Walk AST, for each Component node:
    //    a. Check import exists for pkg
    //    b. Check component exists in registry
    // 3. Return collected errors
    return errs
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `odin test src/resolver/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/resolver/
git commit -m "feat: resolver validates component imports and references"
```

---

## Task 24: Resolver — Layout Chain

**Files:**
- Modify: `src/resolver/resolver.odin`
- Modify: `src/resolver/resolver_test.odin`

- [ ] **Step 1: Write the failing test**

```odin
@(test)
test_resolve_layout_chain :: proc(t: ^testing.T) {
    // Simulate file layout:
    // views/+layout.ohtml
    // views/about/+layout.ohtml
    // views/about/+page.ohtml
    chain := resolve_layout_chain("views/about/+page.ohtml", "views")
    testing.expect_value(t, len(chain), 2)
    testing.expect_value(t, chain[0], "views/+layout.ohtml")
    testing.expect_value(t, chain[1], "views/about/+layout.ohtml")
}

@(test)
test_resolve_layout_chain_no_nested :: proc(t: ^testing.T) {
    // views/blog/+page.ohtml — no blog layout, only root
    chain := resolve_layout_chain("views/blog/+page.ohtml", "views")
    testing.expect_value(t, len(chain), 1)
    testing.expect_value(t, chain[0], "views/+layout.ohtml")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/resolver/`
Expected: FAIL

- [ ] **Step 3: Implement layout chain resolution**

`resolve_layout_chain` walks from the page's directory up to the root, collecting `+layout.ohtml` files that exist on disk.

- [ ] **Step 4: Run test to verify it passes**

Run: `odin test src/resolver/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/resolver/
git commit -m "feat: resolver builds layout chain for page files"
```

---

## Task 25: Code Generator — Layout Inlining

**Files:**
- Modify: `src/codegen/codegen.odin`
- Modify: `src/codegen/codegen_test.odin`
- Create: `testdata/layouts/views/+layout.ohtml`
- Create: `testdata/layouts/views/+page.ohtml`
- Create: `testdata/layouts/views/about/+layout.ohtml`
- Create: `testdata/layouts/views/about/+page.ohtml`

- [ ] **Step 1: Create test fixtures**

```html
<!-- testdata/layouts/views/+layout.ohtml -->
<!DOCTYPE html>
<html><body>{@render children()}</body></html>
```

```html
<!-- testdata/layouts/views/about/+layout.ohtml -->
<div class="about-wrapper">{@render children()}</div>
```

```html
<!-- testdata/layouts/views/about/+page.ohtml -->
<script lang="odin">
Props :: struct {
    team: []string,
}
</script>
<h1>About Us</h1>
```

- [ ] **Step 2: Write the failing test**

```odin
@(test)
test_gen_layout_inlining :: proc(t: ^testing.T) {
    // Parse all three files
    root_layout, _ := parser.parse(`<!DOCTYPE html><html><body>{@render children()}</body></html>`, "views/+layout.ohtml")
    about_layout, _ := parser.parse(`<div class="about-wrapper">{@render children()}</div>`, "views/about/+layout.ohtml")
    about_page, _ := parser.parse(`<script lang="odin">
Props :: struct { title: string }
</script>
<h1>{title}</h1>`, "views/about/+page.ohtml")

    layout_chain := []ast.Document{root_layout, about_layout}
    result := generate_page(about_page, "about", layout_chain)

    // Should inline layouts around page content
    testing.expect(t, strings.contains(result, "<!DOCTYPE html>"), "should have doctype from root layout")
    testing.expect(t, strings.contains(result, "about-wrapper"), "should have about layout wrapper")
    testing.expect(t, strings.contains(result, "props.title"), "should have page content")
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `odin test src/codegen/`
Expected: FAIL

- [ ] **Step 4: Implement layout inlining**

Add `generate_page` proc that:
1. Takes the page AST and ordered layout chain (outermost first)
2. For each layout, finds the `{@render children()}` position
3. Emits layout HTML before children, then page content, then layout HTML after children
4. Nests multiple layouts: root wraps about wraps page

- [ ] **Step 5: Run test to verify it passes**

Run: `odin test src/codegen/`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/codegen/ testdata/layouts/
git commit -m "feat: codegen inlines layout chain around page content"
```

---

## Task 26: CLI — File Discovery + Generate Command

**Files:**
- Modify: `src/main.odin`

- [ ] **Step 1: Implement CLI argument parsing and file discovery**

```odin
// src/main.odin
package main

import "core:flags"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:path/filepath"

Args :: struct {
    command: string,
    src:     string,
    out:     string,
}

main :: proc() {
    args := parse_args()
    switch args.command {
    case "generate":
        exit_code := cmd_generate(args.src, args.out)
        os.exit(exit_code)
    case "watch":
        cmd_watch(args.src, args.out)
    case "fmt":
        exit_code := cmd_fmt(args.src)
        os.exit(exit_code)
    case:
        print_usage()
        os.exit(2)
    }
}

cmd_generate :: proc(src_dir: string, out_dir: string) -> int {
    // 1. Write runtime package to out_dir/runtime/
    // 2. Discover all .ohtml files recursively in src_dir
    // 3. Parse each file
    // 4. Build component registry from discovered files
    // 5. Resolve each file
    // 6. If any errors, print them all and return 1
    // 7. Generate .odin for each file, write to out_dir
    // 8. Handle +layout.ohtml / +page.ohtml with layout inlining
    // 9. Return 0
}
```

Full implementation of:
- `parse_args` — reads `os.args`, extracts command, `-o` flag
- `discover_ohtml_files` — walks directory tree, finds `*.ohtml`
- `cmd_generate` — orchestrates the full pipeline

- [ ] **Step 2: Verify it builds**

Run: `odin build src/ -out:odin-templ`
Expected: compiles

- [ ] **Step 3: Test manually with testdata**

Run: `./odin-templ generate testdata/simple -o /tmp/gen`
Expected: generates `/tmp/gen/hello/hello.odin`

Run: `cat /tmp/gen/hello/hello.odin`
Expected: valid Odin code with `render` proc

Run: `./odin-templ generate testdata/layouts -o /tmp/gen2`
Expected: generates layout-inlined page files

- [ ] **Step 4: Commit**

```bash
git add src/main.odin
git commit -m "feat: CLI generate command with file discovery and full pipeline"
```

---

## Task 27: CLI — Watch Command

**Files:**
- Modify: `src/main.odin`

- [ ] **Step 1: Implement watch mode**

Add `cmd_watch` proc:
- Uses `core:os` to poll for file modification times (simple approach — no OS-specific watchers needed for v1)
- On change: re-runs the pipeline for affected files + dependents
- Prints errors to stderr, keeps watching
- Per-file error recovery (successful files still get written)

```odin
cmd_watch :: proc(src_dir: string, out_dir: string) {
    fmt.eprintln("Watching", src_dir, "for changes...")
    // Track modification times
    // Poll loop (1 second interval)
    // On change: rebuild dependency graph, recompile changed + dependents
    // Print errors, continue
}
```

- [ ] **Step 2: Test manually**

Run: `./odin-templ watch testdata/simple -o /tmp/gen`
Expected: prints "Watching..." message, recompiles on file changes

- [ ] **Step 3: Commit**

```bash
git add src/main.odin
git commit -m "feat: CLI watch mode with polling-based file change detection"
```

---

## Task 28: CLI — Format Command

**Files:**
- Modify: `src/main.odin`

- [ ] **Step 1: Implement format command**

Add `cmd_fmt` proc:
- Discovers all `.ohtml` files
- For each file: parse, then re-emit with consistent formatting
- Consistent indentation (2 spaces default)
- Normalized attribute quoting (always double quotes)
- Does NOT touch `<script>` block content
- Writes back in place

- [ ] **Step 2: Test manually**

Create a messy `.ohtml` file, run formatter, verify output.

Run: `./odin-templ fmt testdata/simple`
Expected: files reformatted in place

- [ ] **Step 3: Commit**

```bash
git add src/main.odin
git commit -m "feat: CLI fmt command for .ohtml file formatting"
```

---

## Task 29: End-to-End Integration Test

**Files:**
- Create: `testdata/composition/components/card/Card.ohtml`
- Create: `testdata/composition/components/badge/Badge.ohtml`
- Create: `testdata/composition/pages/home/+page.ohtml`

- [ ] **Step 1: Create test fixtures**

```html
<!-- testdata/composition/components/card/Card.ohtml -->
<script lang="odin">
Props :: struct {
    title: string,
    children: proc(w: io.Writer),
}
</script>
<div class="card">
    <h2>{title}</h2>
    {@render children()}
</div>
```

```html
<!-- testdata/composition/components/badge/Badge.ohtml -->
<script lang="odin">
Props :: struct {
    label: string,
}
</script>
<span class="badge">{label}</span>
```

```html
<!-- testdata/composition/pages/home/+page.ohtml -->
<script lang="odin">
import "components/card"
import "components/badge"

Props :: struct {
    user: string,
    is_admin: bool,
}
</script>
<card.Card title="Welcome">
    <p>Hello, {user}!</p>
    {#if is_admin}
        <badge.Badge label="Admin" />
    {/if}
</card.Card>
```

- [ ] **Step 2: Run the full generate pipeline**

Run: `./odin-templ generate testdata/composition -o /tmp/gen_e2e`
Expected: exit code 0, generates:
- `/tmp/gen_e2e/runtime/escape.odin`
- `/tmp/gen_e2e/runtime/snippet.odin`
- `/tmp/gen_e2e/components/card/card.odin`
- `/tmp/gen_e2e/components/badge/badge.odin`
- `/tmp/gen_e2e/pages/home/page.odin`

- [ ] **Step 3: Verify generated code compiles with Odin**

Run: `odin build /tmp/gen_e2e/ -build-mode:obj`
Expected: compiles successfully (object file, since there's no main)

- [ ] **Step 4: Commit**

```bash
git add testdata/composition/
git commit -m "test: add end-to-end integration test fixtures"
```

---

## Task 30: Layout Integration Test

**Files:**
- Complete: `testdata/layouts/` fixtures (created in Task 25)

- [ ] **Step 1: Run generate on layout fixtures**

Run: `./odin-templ generate testdata/layouts -o /tmp/gen_layouts`
Expected: exit code 0

- [ ] **Step 2: Verify generated page has inlined layouts**

Run: `cat /tmp/gen_layouts/views/about/page.odin`
Expected: contains `<!DOCTYPE html>`, `about-wrapper`, page content — all inlined

- [ ] **Step 3: Verify generated code compiles**

Run: `odin build /tmp/gen_layouts/ -build-mode:obj`
Expected: compiles successfully

- [ ] **Step 4: Commit (if any fixes needed)**

```bash
git commit -m "fix: ensure layout integration works end-to-end"
```

---

## Task 31: Error Reporting Test

**Files:**
- Create: `testdata/errors/bad_component/Page.ohtml`

- [ ] **Step 1: Create error test fixture**

```html
<!-- testdata/errors/bad_component/Page.ohtml -->
<script lang="odin">
import "components/nonexistent"
</script>
<nonexistent.Foo />
```

- [ ] **Step 2: Run generate and verify error output**

Run: `./odin-templ generate testdata/errors -o /tmp/gen_err`
Expected: exit code 1, stderr contains:
```
bad_component/Page.ohtml:2:1 - error: import 'components/nonexistent' not found
```

- [ ] **Step 3: Commit**

```bash
git add testdata/errors/
git commit -m "test: add error reporting test fixture"
```

---

## Task 32: Whitespace Handling

**Files:**
- Modify: `src/codegen/codegen.odin`
- Modify: `src/codegen/codegen_test.odin`

- [ ] **Step 1: Write the failing tests**

```odin
@(test)
test_whitespace_collapse :: proc(t: ^testing.T) {
    src := `<div>
    <span>Hello</span>
    <span>World</span>
</div>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "ws")

    // Inter-tag whitespace should be collapsed to single space
    testing.expect(t, !strings.contains(result, "\\n    "), "should not contain raw newlines+indent in output")
}

@(test)
test_pre_whitespace_preserved :: proc(t: ^testing.T) {
    src := `<pre>
    line 1
    line 2
</pre>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "pre")

    // pre block whitespace must be preserved exactly
    testing.expect(t, strings.contains(result, "line 1\\n    line 2") ||
                      strings.contains(result, "line 1\n    line 2"),
        "should preserve whitespace inside <pre>")
}

@(test)
test_text_node_whitespace :: proc(t: ^testing.T) {
    src := `<p>Hello  World</p>`

    doc, _ := parser.parse(src, "test.ohtml")
    result := generate(doc, "txt")

    // Whitespace within text nodes is preserved
    testing.expect(t, strings.contains(result, "Hello  World"), "should preserve text node whitespace")
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `odin test src/codegen/`
Expected: FAIL

- [ ] **Step 3: Implement whitespace handling in codegen**

Add whitespace processing to the codegen's HTML emission:
- Track whether we're inside a `<pre>` or `<code>` block (set a `preserve_whitespace` flag)
- When NOT in preserve mode: collapse inter-tag whitespace (text nodes that are purely whitespace between tags) to a single space; preserve whitespace within text nodes that contain non-whitespace content
- When IN preserve mode: emit all whitespace exactly as-is
- Push preserve mode when entering `<pre>` or `<code>`, pop when leaving

- [ ] **Step 4: Run tests to verify they pass**

Run: `odin test src/codegen/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/codegen/
git commit -m "feat: codegen handles whitespace collapsing and pre/code preservation"
```

---

## Task 33: Snippet Arity Validation

**Files:**
- Modify: `src/parser/parser.odin` (or `src/resolver/resolver.odin`)
- Modify: `src/parser/parser_test.odin` (or `src/resolver/resolver_test.odin`)

- [ ] **Step 1: Write the failing test**

```odin
@(test)
test_reject_snippet_2_args :: proc(t: ^testing.T) {
    src := `<script lang="odin">
Props :: struct {
    callback: proc(w: io.Writer, a: Item, b: Other),
}
</script>
<div></div>`

    _, err := parser.parse(src, "test.ohtml")
    e, has_err := err.?
    testing.expect(t, has_err, "should report error for snippet with 2+ args")
    testing.expect(t, strings.contains(e.msg, "2") || strings.contains(e.msg, "argument"),
        "error should mention argument count")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `odin test src/parser/`
Expected: FAIL

- [ ] **Step 3: Implement snippet arity validation**

In `parse_script` when parsing Props struct fields, count the number of parameters after `io.Writer`. If more than 1, emit a parse error: "snippet props support at most 1 argument (got N). Wrap multiple values in a struct."

- [ ] **Step 4: Run test to verify it passes**

Run: `odin test src/parser/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/parser/
git commit -m "feat: reject snippet props with 2+ arguments as compile error"
```

---

## Task 34: Generate Mode All-or-Nothing Semantics

**Files:**
- Modify: `src/main.odin`

- [ ] **Step 1: Write a test fixture with mixed valid/invalid files**

Create `testdata/errors/mixed/`:
```html
<!-- testdata/errors/mixed/valid/Valid.ohtml -->
<div>Valid</div>
```

```html
<!-- testdata/errors/mixed/broken/Broken.ohtml -->
<script lang="odin">
import "nonexistent/pkg"
</script>
<nonexistent.Foo />
```

- [ ] **Step 2: Verify all-or-nothing behavior**

Run: `./odin-templ generate testdata/errors/mixed -o /tmp/gen_aon`
Expected:
- Exit code 1
- `/tmp/gen_aon/valid/valid.odin` does NOT exist (no partial output)
- Error message about nonexistent import printed to stderr

- [ ] **Step 3: Implement all-or-nothing in cmd_generate**

In `cmd_generate`:
1. Run the full pipeline (parse all, resolve all, collect errors)
2. If `len(errors) > 0`: print all errors, return 1 WITHOUT writing any files
3. Only if zero errors: write all generated files to output dir

- [ ] **Step 4: Verify again after fix**

Run same command, verify no output files written.

- [ ] **Step 5: Commit**

```bash
git add src/main.odin testdata/errors/mixed/
git commit -m "feat: generate mode is all-or-nothing on errors"
```

---

## Task 35: Handle [slug] Directory Names

**Files:**
- Modify: `src/main.odin` (file discovery and output path generation)
- Create: `testdata/layouts/views/blog/[slug]/+page.ohtml`

- [ ] **Step 1: Create test fixture**

```html
<!-- testdata/layouts/views/blog/[slug]/+page.ohtml -->
<script lang="odin">
Props :: struct {
    slug: string,
    title: string,
}
</script>
<h1>{title}</h1>
```

- [ ] **Step 2: Run generate and verify it handles bracket dirs**

Run: `./odin-templ generate testdata/layouts -o /tmp/gen_slug`
Expected: exit code 0, generates `/tmp/gen_slug/views/blog/slug/page.odin` (brackets stripped for valid Odin package name)

- [ ] **Step 3: Implement bracket directory handling**

In file discovery and output path generation:
- Strip `[` and `]` from directory names when computing output paths (brackets are not valid in Odin package names)
- `views/blog/[slug]/` → output package `slug`, path `gen/views/blog/slug/`

- [ ] **Step 4: Verify**

Check generated file exists and has `package slug`.

- [ ] **Step 5: Commit**

```bash
git add src/main.odin testdata/layouts/views/blog/
git commit -m "feat: handle [param] directory names in route structure"
```
