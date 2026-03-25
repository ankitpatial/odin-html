# odin-templ Design Spec

A standalone CLI tool that compiles `.ohtml` template files into `.odin` source files for server-side HTML rendering with zero runtime overhead.

## Template File Format (.ohtml)

A `.ohtml` file has two parts: an optional `<script lang="odin">` block and HTML markup.

### Script Block

```html
<script lang="odin">
import "core:fmt"
import "components/card"

Props :: struct {
    title: string,
    count: int,
    children: runtime.Children,
    row: runtime.Snippet(Item),
}
</script>
```

- **Package**: auto-derived from the directory the file is in. No `package` declaration needed.
- **Imports**: standard Odin `import` syntax. Used for both Odin packages and other `.ohtml` component packages. The compiler distinguishes them by checking whether the path contains `.ohtml` source files.
- **Props struct**: required if the component accepts data or snippets.
- **Auto-imports**: `core:io` and `gen/runtime` are automatically imported when snippet types or escaping are used. No need to declare them in the script block.

### Snippet Types (No Closures)

Odin does not support closures. Snippet props use a `Snippet` struct from the generated runtime that pairs a function pointer with a `rawptr` context:

```odin
// gen/runtime/snippet.odin

// Children snippet (no arguments, used for child content wrapping)
Children :: struct {
    func: proc(w: io.Writer, ctx: rawptr),
    ctx: rawptr,
}

children_render :: proc(w: io.Writer, c: Children) {
    if c.func != nil {
        c.func(w, c.ctx)
    }
}

// Typed snippet with one argument (generated per-type as needed)
Snippet :: struct($T: typeid) {
    func: proc(w: io.Writer, ctx: rawptr, arg: T),
    ctx: rawptr,
}

snippet_render :: proc($T: typeid, w: io.Writer, s: Snippet(T), arg: T) {
    if s.func != nil {
        s.func(w, s.ctx, arg)
    }
}
```

**Supported snippet signatures**: only two forms are supported in `.ohtml` templates:
- `children: proc(w: io.Writer)` — zero-argument snippet (children), compiles to `runtime.Children`
- `row: proc(w: io.Writer, item: Item)` — single-argument snippet, compiles to `runtime.Snippet(Item)`

Snippets with 2+ arguments are a compile error. If needed, wrap multiple values in a struct.

In `.ohtml` templates, users write the conceptual `proc` types. The compiler translates these to `runtime.Snippet` and `runtime.Snippet(T)` in generated code.

### HTML Markup

Svelte 5 syntax for expressions and control flow:

```html
<!-- Expressions (auto-escaped) -->
<h1>{title}</h1>
<span>{count} items</span>

<!-- Raw HTML (unescaped) -->
{@html trusted_html}

<!-- Conditionals -->
{#if count > 0}
    <span>{count} items</span>
{:else if count == 0}
    <p>No items yet</p>
{:else}
    <p>Error</p>
{/if}

<!-- Loops -->
{#each items as item}
    <li>{item.name}</li>
{/each}

<!-- Loop with index -->
{#each items as item, i}
    <li>{i}: {item.name}</li>
{/each}

<!-- Empty collection fallback -->
{#each items as item}
    <li>{item.name}</li>
{:else}
    <p>No items</p>
{/each}

<!-- Render snippets -->
{@render children()}
{@render row(item)}

<!-- Snippet definition (inline, for passing to child components) -->
{#snippet row(item: Item)}
    <li>{item.name}</li>
{/snippet}
```

### Expression Handling

- **Scope resolution**: bare names in expressions (e.g., `{title}`) are resolved as `props.<name>`. Loop variables (`{#each items as item}`) and snippet parameters (`{#snippet row(item: Item)}`) shadow prop names within their block.
- **Type conversion**: all expressions are converted to `string` before escaping. `string` values pass through directly. Non-string types (`int`, `f64`, `bool`, etc.) are converted via `fmt.tprint`. The compiler inserts the conversion call automatically.
- **Auto-escaping**: all `{expression}` values are escaped via `runtime.html_escape`. `{@html expression}` writes raw output with no escaping.
- **Snippet capture rules**: inline `{#snippet}` blocks can reference any variable in their enclosing scope — props fields, `{#each}` loop variables, and parent snippet parameters. The compiler analyzes which variables are referenced and generates a context struct containing only those values. Snippets cannot reference other snippet definitions (only invoke them via `{@render}`).

### Attribute Handling

```html
<!-- Dynamic attribute values (auto-escaped) -->
<div class={class_name}>...</div>
<a href={url}>Link</a>

<!-- Boolean attributes -->
<button disabled={is_disabled}>Click</button>
<!-- renders as <button disabled>Click</button> when true, omits attribute when false -->

<!-- Static attributes work as normal HTML -->
<div class="card" id="main">...</div>
```

- Dynamic attribute values are always rendered inside double quotes and escaped using the same `runtime.html_escape` function (which covers `& < > " '`). This is safe because generated attributes are always double-quoted.
- Boolean attributes: `true` renders the attribute name only, `false` omits the attribute entirely.
- Spread attributes and event handlers are not supported (SSR-only, no client-side interactivity).

### `{#each}` Semantics

- **Iterable types**: Odin slices (`[]T`) and dynamic arrays (`[dynamic]T`).
- **Index variable**: optional second binding `{#each items as item, i}` where `i` is `int`.
- **`{:else}` clause**: rendered when `len(collection) == 0` (works for both nil slices and zero-length dynamic arrays).
- **No destructuring**: the `as` binding is a single name.

## Component Structure

Each component lives in its own directory. One `.ohtml` file per directory to avoid name collisions in the generated Odin package (since each component generates `Props` and `render`):

```
components/
    card/
        Card.ohtml
    button/
        Button.ohtml
```

Co-located assets (CSS, etc.) may exist in the same directory but are not processed by the compiler in v1. They are available for `#embed` in hand-written Odin code.

### Using Components

Components are referenced as `pkg.ComponentName` in markup, matching their import:

```html
<script lang="odin">
import "components/card"
import "components/button"
</script>

<card.Card title="Hello">
    <p>Child content</p>
</card.Card>

<button.Button label="Click me" />
```

## Layout and Page Convention

Follows SvelteKit's filesystem-based routing pattern. The root directory is configurable (e.g., `views/`, `pages/`, `routes/`).

### Structure

```
views/                     # configurable root
    +layout.ohtml          # root layout
    +page.ohtml            # / (home)
    about/
        +layout.ohtml      # optional nested layout
        +page.ohtml        # /about
    blog/
        +page.ohtml        # /blog
        [slug]/
            +page.ohtml    # /blog/:slug (dynamic param)
```

### Dynamic Route Parameters

Directory names like `[slug]` denote dynamic route segments. The compiler does NOT extract or provide these values. They exist purely as a naming convention to communicate route structure. The user is responsible for parsing URL parameters and passing them as props when calling the page's `render` proc.

### Layout Wrapping

The compiler automatically wires layouts. A page at `views/about/+page.ohtml` is wrapped by:
1. `views/+layout.ohtml` (root layout)
2. `views/about/+layout.ohtml` (if exists)

The user only calls the page's `render` proc — layout nesting is handled internally.

Since Odin has no closures, layout wiring is done by **compile-time inlining**: the compiler knows the full layout chain statically and generates a single `render` proc that emits the layout HTML directly around the page content, rather than composing at runtime.

### Layout Props

Layouts are pure wrappers — their only prop is `children` (the content they wrap). Layouts must NOT define additional props. If a layout needs dynamic data (e.g., a nav bar with user info), extract that into a component and use it inside the page or pass data through Odin's implicit `context` system.

This keeps layout inlining simple: the compiler only needs to splice the layout HTML around the page content without merging prop structs.

### Routing

The compiler does NOT generate a router. It only handles layout→page wiring. HTTP routing is the user's responsibility. The user calls the appropriate page render proc from their own router.

## Generated Code

All generated files include a header comment: `// Code generated by odin-templ. DO NOT EDIT.`

### Output Structure

Output goes to a separate `gen/` directory (configurable via `-o`), mirroring source structure:

```
gen/
    runtime/
        escape.odin        # shared html_escape utility
        snippet.odin       # Snippet types for closure-free composition
    components/
        card/
            card.odin
        button/
            button.odin
    views/
        layout.odin
        page.odin
        about/
            layout.odin
            page.odin
```

### Generated Component

Given `components/card/Card.ohtml`:

```html
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

Generates `gen/components/card/card.odin`:

```odin
// Code generated by odin-templ. DO NOT EDIT.
package card

import "core:io"
import "gen/runtime"

Props :: struct {
    title: string,
    children: runtime.Children,
}

render :: proc(w: io.Writer, props: Props) {
    io.write_string(w, "<div class=\"card\"><h2>")
    runtime.html_escape(w, props.title)
    io.write_string(w, "</h2>")
    runtime.children_render(w, props.children)
    io.write_string(w, "</div>")
}
```

### Generated Page with Layout Wiring (Compile-Time Inlining)

Given `views/about/+page.ohtml` with a root layout and about layout, the compiler inlines the full layout chain:

```odin
// Code generated by odin-templ. DO NOT EDIT.
package about

import "core:io"
import "gen/runtime"

Props :: struct {
    team: []Member,
}

render :: proc(w: io.Writer, props: Props) {
    // --- root layout start ---
    io.write_string(w, "<!DOCTYPE html><html><body>")
    // --- about layout start ---
    io.write_string(w, "<div class=\"about-wrapper\">")
    // --- page content ---
    io.write_string(w, "<h1>About Us</h1><ul>")
    for member in props.team {
        io.write_string(w, "<li>")
        runtime.html_escape(w, member.name)
        io.write_string(w, "</li>")
    }
    io.write_string(w, "</ul>")
    // --- about layout end ---
    io.write_string(w, "</div>")
    // --- root layout end ---
    io.write_string(w, "</body></html>")
}
```

Usage:

```odin
import about "gen/views/about"

about.render(w, about.Props{ team = members })
```

### Snippet Call Sites (Closure-Free)

When a component is used with children or inline snippets, the compiler generates a context struct and a standalone proc at the call site:

```html
<!-- In some page using Card -->
<card.Card title="Welcome">
    <p>Hello, {user.name}!</p>
</card.Card>
```

Generated at the call site:

```odin
// Context struct captures referenced outer variables
_card_children_ctx :: struct {
    name: string,
}

_card_children_render :: proc(w: io.Writer, ctx: rawptr) {
    data := (^_card_children_ctx)(ctx)
    io.write_string(w, "<p>Hello, ")
    runtime.html_escape(w, data.name)
    io.write_string(w, "!</p>")
}

// In the render proc:
ctx := _card_children_ctx{ name = props.user.name }
card.render(w, card.Props{
    title = "Welcome",
    children = runtime.Children{
        func = _card_children_render,
        ctx = &ctx,
    },
})
```

### Key Rules

- All `{expression}` values are auto-escaped via `runtime.html_escape`
- Non-string expressions are converted via `fmt.tprint` before escaping
- `{@html expression}` writes raw, unescaped output
- Snippet props use `runtime.Children` / `runtime.Snippet(T)` (no closures), nil-checked before invocation
- **Snippet lifetime**: snippets are invoked synchronously during `render` and must NOT be stored or called after `render` returns. The context `rawptr` points to stack-allocated data that becomes invalid after the enclosing `render` call completes.
- Static HTML is collapsed into single `io.write_string` calls
- Layout→page wiring is inlined at compile time
- Each component/page is its own Odin package with `Props` struct and `render` proc

## HTML Escaping

A shared runtime package is generated at `gen/runtime/escape.odin`:

```odin
// Code generated by odin-templ. DO NOT EDIT.
package runtime

import "core:io"
import "core:unicode/utf8"

html_escape :: proc(w: io.Writer, s: string) {
    for r in s {
        switch r {
        case '&':  io.write_string(w, "&amp;")
        case '<':  io.write_string(w, "&lt;")
        case '>':  io.write_string(w, "&gt;")
        case '"':  io.write_string(w, "&quot;")
        case '\'': io.write_string(w, "&#39;")
        case:
            buf: [4]u8
            n := utf8.encode_rune(buf[:], r)
            io.write(w, buf[:n])
        }
    }
}
```

### Whitespace Handling

- Inter-tag whitespace is collapsed (multiple spaces/newlines become a single space).
- Whitespace within text nodes is preserved.
- `<pre>` and `<code>` blocks preserve all whitespace exactly as written.

## Compiler Architecture

The CLI is written in Odin. Three-stage pipeline:

```
.ohtml → [Parser] → AST → [Resolver] → Resolved AST → [CodeGen] → .odin
```

### 1. Parser

Reads `.ohtml` files and produces an AST:
- Parses `<script lang="odin">` → extracts imports, Props struct, Odin expressions
- Parses HTML markup → elements, attributes, expressions, control flow, snippets, component references

### 2. Resolver

Connects and validates:
- Maps `pkg.Component` references to their `.ohtml` source files
- Validates Props usage matches definitions
- Resolves `+layout.ohtml` / `+page.ohtml` nesting chains
- Builds a dependency graph (which components depend on which)
- Reports errors with `.ohtml` file, line, and column

### 3. Code Generator

Emits `.odin` files:
- Generates `Props` struct and `render` proc per component/page
- Inlines layout→page chain for route files
- Generates context structs and standalone procs for snippet call sites
- Applies auto-escaping for expressions, raw pass-through for `{@html}`
- Inserts `fmt.tprint` conversion for non-string expressions
- Collapses static HTML into single write calls
- Handles boolean and dynamic attributes

## Compiler Errors

Errors reference the `.ohtml` source with file, line, and column:

```
components/card/Card.ohtml:12:5 - error: undefined variable 'titl', did you mean 'title'?
components/card/Card.ohtml:8:3 - error: Props struct missing required field 'children'
views/about/+page.ohtml:3:1 - error: import 'components' has no component 'Cardz'
```

Error categories:
- **Parse errors**: malformed HTML, unclosed tags, bad control flow syntax
- **Resolution errors**: unknown components, missing props, bad imports
- **Type errors**: snippet signature mismatches, wrong prop types

### Error Recovery

- **`generate` mode**: all-or-nothing. If any file has errors, no output files are written. This prevents partial/inconsistent generated code.
- **`watch` mode**: files that compile successfully are written to `gen/`. Files with errors are skipped (previous generated version is left in place). Errors are printed to stderr and the watcher continues.

## CLI Interface

```
odin-templ generate <src> -o <out>
    Compiles all .ohtml files in <src>, writes .odin files to <out>

odin-templ watch <src> -o <out>
    Watches <src> for changes, recompiles affected files incrementally

odin-templ fmt <src>
    Formats .ohtml files in place (indentation, tag alignment)
```

- `-o` defaults to `gen/` in the current directory
- `<src>` is required

Exit codes:
- `0` — success
- `1` — compile errors
- `2` — CLI usage error

### Watch Mode

Recompiles only changed files and their dependents. The resolver's dependency graph is rebuilt on each change event (not persisted across runs). Errors print to stderr; the watcher keeps running.

### Formatter

`odin-templ fmt` formats `.ohtml` files:
- Consistent indentation (spaces, configurable width)
- HTML tag alignment
- Normalizes attribute quoting
- Does NOT format Odin code inside `<script>` blocks (use `odinfmt` for that)
