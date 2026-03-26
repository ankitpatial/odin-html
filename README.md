# ohtml

A CLI tool that compiles `.ohtml` template files into `.odin` source files for server-side HTML rendering with zero runtime overhead. Inspired by [templ](https://github.com/a-h/templ) (Go) and [Svelte](https://svelte.dev) syntax.

## Features

- Svelte 5 syntax: `{#if}`, `{#each}`, `{@render}`, `{@html}`, `{#snippet}`
- `<script lang="odin">` blocks for imports and Props
- Component composition via `pkg.Component` references
- SvelteKit-style `+layout.ohtml` / `+page.ohtml` filesystem convention
- Compile-time layout inlining (no runtime overhead)
- Auto-escaping of all expressions (XSS-safe by default)
- `{@html}` for trusted raw output
- Children (`runtime.Children`) and typed snippets (`runtime.Snippet(T)`)
- Written entirely in Odin with no external dependencies

## Install

```sh
odin build src/ -out:ohtml
```

## Usage

```sh
# Compile all .ohtml files
ohtml generate <src> -o <out>

# Watch for changes and recompile
ohtml watch <src> -o <out>

# Format .ohtml files
ohtml fmt <src>
```

`-o` defaults to `gen/` in the current directory.

## Template Syntax

### Basic Component

```html
<!-- components/greeting/Greeting.ohtml -->
<script lang="odin">
Props :: struct {
    name: string,
    count: int,
}
</script>

<h1>Hello, {name}!</h1>
<span>{count} items</span>
```

### Control Flow

```html
{#if is_admin}
    <span>Admin</span>
{:else if is_mod}
    <span>Moderator</span>
{:else}
    <span>User</span>
{/if}

{#each items as item, i}
    <li>{i}: {item.name}</li>
{:else}
    <p>No items</p>
{/each}
```

### Children and Snippets

```html
<!-- components/card/Card.ohtml -->
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

Usage:

```html
<script lang="odin">
import "components/card"
</script>

<card.Card title="Welcome">
    <p>Child content here</p>
</card.Card>
```

### Typed Snippets

```html
<script lang="odin">
Props :: struct {
    items: []Item,
    row: proc(w: io.Writer, item: Item),
}
</script>

<ul>
    {#each items as item}
        {@render row(item)}
    {/each}
</ul>
```

### Raw HTML

```html
{@html trusted_html_content}
```

### Dynamic Attributes

```html
<div class={dynamic_class}>...</div>
<button disabled={is_disabled}>Click</button>
```

## Layouts and Pages

Follows SvelteKit filesystem routing conventions. The root directory is configurable.

```
views/
    +layout.ohtml          # root layout
    +page.ohtml            # /
    about/
        +layout.ohtml      # nested layout
        +page.ohtml        # /about
    blog/
        +page.ohtml        # /blog
        [slug]/
            +page.ohtml    # /blog/:slug
```

Layouts wrap pages automatically. The compiler inlines the full layout chain at compile time.

```html
<!-- views/+layout.ohtml -->
<!DOCTYPE html>
<html>
<body>
    {@render children()}
</body>
</html>
```

The compiler does not generate a router. Call the page's `render` proc from your own router:

```odin
import about "gen/views/about"

about.render(w, about.Props{ title = "About Us" })
```

## Generated Output

Each `.ohtml` file becomes its own Odin package:

```
gen/
    runtime/
        escape.odin       # html_escape
        snippet.odin      # Children, Snippet(T)
    components/
        card/
            card.odin
    views/
        layout.odin
        about/
            page.odin
```

Generated code writes to `io.Writer` for streaming output with no allocations:

```odin
render :: proc(w: io.Writer, props: Props) {
    io.write_string(w, "<h1>Hello, ")
    runtime.html_escape(w, props.name)
    io.write_string(w, "!</h1>")
}
```

## Project Structure

```
src/
    main.odin          # CLI entry point
    token/             # Token types
    lexer/             # .ohtml tokenizer
    ast/               # AST node types
    parser/            # Token stream -> AST
    resolver/          # Validates imports, components, layout chains
    codegen/           # AST -> .odin source
    runtime_gen/       # Generates the runtime package
    errors/            # Error types
```

## Future

- LSP for editor support
- CSS co-location and bundling
- Named slots / multiple render targets
