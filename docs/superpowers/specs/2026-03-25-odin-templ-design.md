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
    children: proc(w: io.Writer),
    row: proc(w: io.Writer, item: Item),
}
</script>
```

- **Package**: auto-derived from the directory the file is in. No `package` declaration needed.
- **Imports**: standard Odin `import` syntax. Used for both Odin packages and other `.ohtml` component packages. The compiler distinguishes them by checking whether the path contains `.ohtml` source files.
- **Props struct**: required if the component accepts data or snippets. Snippet props are typed as `proc(w: io.Writer, ...)`.

### HTML Markup

Svelte 5 syntax for expressions and control flow:

```html
<!-- Expressions (auto-escaped) -->
<h1>{title}</h1>

<!-- Raw HTML (unescaped) -->
{@html trusted_html}

<!-- Conditionals -->
{#if count > 0}
    <span>{count} items</span>
{:else}
    <p>No items</p>
{/if}

<!-- Loops -->
{#each items as item}
    <li>{item.name}</li>
{/each}

<!-- Render snippets -->
{@render children()}
{@render row(item)}

<!-- Snippet definition (inline, for passing to child components) -->
{#snippet row(item: Item)}
    <li>{item.name}</li>
{/snippet}
```

## Component Structure

Each component lives in its own directory:

```
components/
    card/
        Card.ohtml
        card.css          # optional co-located assets
    button/
        Button.ohtml
```

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

Same-package components need no prefix:

```html
<Header title="Page" />
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

### Layout Wrapping

The compiler automatically wires layouts. A page at `views/about/+page.ohtml` is wrapped by:
1. `views/+layout.ohtml` (root layout)
2. `views/about/+layout.ohtml` (if exists)

The user only calls the page's `render` proc — layout nesting is handled internally.

### Routing

The compiler does NOT generate a router. It only handles layout→page wiring. HTTP routing is the user's responsibility. The user calls the appropriate page render proc from their own router.

## Generated Code

### Output Structure

Output goes to a separate `gen/` directory (configurable via `-o`), mirroring source structure:

```
gen/
    runtime/
        escape.odin        # shared html_escape utility
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
package card

import "core:io"
import "gen/runtime"

Props :: struct {
    title: string,
    children: proc(w: io.Writer),
}

render :: proc(w: io.Writer, props: Props) {
    io.write_string(w, "<div class=\"card\"><h2>")
    runtime.html_escape(w, props.title)
    io.write_string(w, "</h2>")
    if props.children != nil {
        props.children(w)
    }
    io.write_string(w, "</div>")
}
```

### Generated Page with Layout Wiring

Given `views/about/+page.ohtml` with a root layout and about layout:

```odin
package about

import "core:io"
import root "gen/views"

Props :: struct {
    team: []Member,
}

render :: proc(w: io.Writer, props: Props) {
    root.layout_render(w, root.Layout_Props{
        children = proc(w: io.Writer) {
            layout_render(w, Layout_Props{
                children = proc(w: io.Writer) {
                    content_render(w, props)
                },
            })
        },
    })
}
```

Usage:

```odin
import about "gen/views/about"

about.render(w, about.Props{ team = members })
```

### Key Rules

- All `{expression}` values are auto-escaped via `runtime.html_escape`
- `{@html expression}` writes raw, unescaped output
- Snippet props get a nil check before invocation
- Static HTML is collapsed into single `io.write_string` calls
- Each component/page is its own Odin package with `Props` struct and `render` proc

## HTML Escaping

A shared runtime package is generated at `gen/runtime/escape.odin`:

```odin
package runtime

import "core:io"

html_escape :: proc(w: io.Writer, s: string) {
    for c in s {
        switch c {
        case '&':  io.write_string(w, "&amp;")
        case '<':  io.write_string(w, "&lt;")
        case '>':  io.write_string(w, "&gt;")
        case '"':  io.write_string(w, "&quot;")
        case '\'': io.write_string(w, "&#39;")
        default:   io.write_byte(w, u8(c))
        }
    }
}
```

## Compiler Architecture

The CLI is written in Odin. Three-stage pipeline:

```
.ohtml → [Parser] → AST → [Resolver] → Resolved AST → [CodeGen] → .odin
```

### 1. Parser

Reads `.ohtml` files and produces an AST:
- Parses `<script lang="odin">` → extracts imports, Props struct, Odin expressions
- Parses HTML markup → elements, expressions, control flow, snippets, component references

### 2. Resolver

Connects and validates:
- Maps `pkg.Component` references to their `.ohtml` source files
- Validates Props usage matches definitions
- Resolves `+layout.ohtml` / `+page.ohtml` nesting chains
- Reports errors with `.ohtml` file, line, and column

### 3. Code Generator

Emits `.odin` files:
- Generates `Props` struct and `render` proc per component/page
- Wires layout→page chain for route files
- Applies auto-escaping for expressions, raw pass-through for `{@html}`
- Collapses static HTML into single write calls

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

Watch mode recompiles only changed files and their dependents, prints errors to stderr, and keeps watching.
