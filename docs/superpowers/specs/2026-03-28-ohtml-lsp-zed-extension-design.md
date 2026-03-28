# OHTML LSP & Zed Extension Design Spec

A Tree-sitter grammar, Zed editor extension, and LSP server for `.ohtml` template files — delivered in two phases.

## Overview

Phase 1 delivers syntax highlighting for `.ohtml` files in Zed via a Tree-sitter grammar with language injection (Odin inside `<script>` blocks and `{}` expressions). Phase 2 adds an LSP server written in Odin that reuses the existing compiler's lexer, parser, and resolver for diagnostics, go-to-definition, and completions.

Both deliverables live in this monorepo for now. They can be split into separate repos when ready for publishing.

## Phase 1: Tree-sitter Grammar + Zed Extension

### Tree-sitter Grammar (`tree-sitter-ohtml/`)

Standard Tree-sitter project structure:

```
tree-sitter-ohtml/
├── grammar.js              # Grammar definition
├── package.json            # Node.js tooling for grammar dev
├── bindings/               # Language bindings (auto-generated)
├── src/                    # Generated C parser (auto-generated)
│   ├── parser.c
│   ├── scanner.c           # Custom external scanner (for script content, expressions)
│   └── tree_sitter/
│       └── parser.h
├── queries/
│   ├── highlights.scm      # Syntax highlighting
│   ├── injections.scm      # Language injection (Odin)
│   ├── brackets.scm        # Bracket pairs
│   └── indents.scm         # Auto-indentation
├── test/
│   └── corpus/             # Tree-sitter test cases
│       ├── script_block.txt
│       ├── elements.txt
│       ├── expressions.txt
│       ├── control_flow.txt
│       ├── snippets.txt
│       ├── components.txt
│       └── attributes.txt
└── README.md
```

#### Node Hierarchy

The grammar produces a parse tree with the following structure. This mirrors the AST defined in `src/ast/ast.odin`.

```
document
├── script_element                  <script lang="odin"> ... </script>
│   ├── script_start_tag            <script lang="odin">
│   ├── raw_text                    (Odin code — injection target)
│   └── script_end_tag              </script>
├── doctype                         <!DOCTYPE html>
├── comment                         <!-- ... -->
├── element                         <div class="foo"> ... </div>
│   ├── start_tag
│   │   ├── tag_name
│   │   └── attribute*
│   │       ├── attribute_name
│   │       ├── "="
│   │       └── attribute_value     (quoted string or expression)
│   ├── [children]*                 (nested nodes)
│   └── end_tag
│       └── tag_name
├── self_closing_element            <img src="..." />
│   └── self_closing_tag
│       ├── tag_name
│       └── attribute*
├── component                       <pkg.ComponentName prop={val}>...</pkg.ComponentName>
│   ├── component_start_tag
│   │   ├── component_name          (dotted: pkg.Name)
│   │   └── attribute*
│   ├── [children]*
│   └── component_end_tag
│       └── component_name
├── self_closing_component          <pkg.ComponentName prop={val} />
│   └── component_self_closing_tag
│       ├── component_name
│       └── attribute*
├── text                            plain text content
├── expression                      {expr}
│   ├── "{"
│   ├── expression_content          (Odin expression — injection target)
│   └── "}"
├── raw_html_expression             {@html expr}
│   ├── "{@html"
│   ├── expression_content
│   └── "}"
├── if_block                        {#if cond} ... {:else if cond} ... {:else} ... {/if}
│   ├── if_start                    {#if cond}
│   │   └── expression_content
│   ├── [children]*
│   ├── else_if_clause*             {:else if cond}
│   │   ├── expression_content
│   │   └── [children]*
│   ├── else_clause?                {:else}
│   │   └── [children]*
│   └── if_end                      {/if}
├── each_block                      {#each items as item, idx} ... {:else} ... {/each}
│   ├── each_start                  {#each items as item, idx}
│   │   ├── expression_content      (iterable expression)
│   │   ├── binding                 (loop variable name)
│   │   └── index_binding?          (optional index variable)
│   ├── [children]*
│   ├── else_clause?                {:else}
│   │   └── [children]*
│   └── each_end                    {/each}
├── snippet_block                   {#snippet name(params)} ... {/snippet}
│   ├── snippet_start               {#snippet name(params)}
│   │   ├── snippet_name
│   │   └── snippet_params
│   ├── [children]*
│   └── snippet_end                 {/snippet}
└── render_expression               {@render name(args)}
    ├── "{@render"
    ├── render_content              (call expression)
    └── "}"
```

#### External Scanner (`scanner.c`)

A custom external scanner is needed to handle constructs that cannot be expressed with Tree-sitter's context-free grammar rules:

1. **Script block content** — Everything between `<script lang="odin">` and `</script>`. Must track nesting to avoid false matches on `</script>` appearing in string literals.
2. **Expression content** — Content inside `{}` delimiters. Must count brace depth for nested Odin expressions like `{fmt.tprintf("%v", map[string]int{})}`.
3. **Raw text** — Plain text between tags that isn't an expression or block delimiter.

#### Attribute Forms

The grammar recognizes three attribute syntaxes:

| Form | Example | Parse |
|------|---------|-------|
| Static | `class="container"` | `attribute_name` `=` `quoted_attribute_value` |
| Dynamic | `class={get_class()}` | `attribute_name` `=` `expression` |
| Shorthand | `{disabled}` | `expression` (in attribute position) |

#### Language Injection (`injections.scm`)

```scheme
; Script block → Odin
((script_element (raw_text) @content)
 (#set! "language" "odin"))

; Expressions → Odin
((expression (expression_content) @content)
 (#set! "language" "odin"))

; Raw HTML expressions → Odin
((raw_html_expression (expression_content) @content)
 (#set! "language" "odin"))

; Render expressions → Odin
((render_expression (render_content) @content)
 (#set! "language" "odin"))

; If/else-if conditions → Odin
((if_start (expression_content) @content)
 (#set! "language" "odin"))
((else_if_clause (expression_content) @content)
 (#set! "language" "odin"))

; Each iterable → Odin
((each_start (expression_content) @content)
 (#set! "language" "odin"))

; Dynamic attribute values → Odin
((attribute (expression (expression_content) @content))
 (#set! "language" "odin"))
```

### Syntax Highlighting (`highlights.scm`)

| Node | Highlight Scope | Colors |
|------|----------------|--------|
| `tag_name` | `@tag` | HTML tags: `<div>`, `</div>` |
| `component_name` | `@type` | Components: `<shop.ProductCard>` |
| `attribute_name` | `@attribute` | `class=`, `disabled=` |
| `quoted_attribute_value` | `@string` | `"container"` |
| `{#if}`, `{#each}`, `{#snippet}` | `@keyword.control` | Block openers |
| `{/if}`, `{/each}`, `{/snippet}` | `@keyword.control` | Block closers |
| `{:else}`, `{:else if}` | `@keyword.control` | Branch keywords |
| `{@html}` | `@keyword.directive` | Raw HTML directive |
| `{@render}` | `@keyword.directive` | Render directive |
| `{`, `}` (expression delimiters) | `@punctuation.special` | Expression braces |
| `<`, `>`, `/>`, `</` | `@punctuation.bracket` | Tag angle brackets |
| `=` in attributes | `@operator` | Assignment |
| `comment` | `@comment` | `<!-- ... -->` |
| `doctype` | `@keyword` | `<!DOCTYPE html>` |
| `snippet_name` | `@function` | Snippet definitions |
| `binding`, `index_binding` | `@variable` | Loop variables |
| `text` | (default) | Plain text |

### Brackets (`brackets.scm`)

Auto-close pairs:
- `{` / `}` — expression delimiters
- `<` / `>` — tag brackets (contextual)
- `"` / `"` — attribute values
- `(` / `)` — snippet params, render args

### Indentation (`indents.scm`)

Indent after:
- Opening tags: `<div>`, `<section>`, etc.
- Component opening tags
- Block openers: `{#if}`, `{#each}`, `{#snippet}`
- `{:else}`, `{:else if}` (dedent then indent)

Dedent at:
- Closing tags: `</div>`, etc.
- Block closers: `{/if}`, `{/each}`, `{/snippet}`

### Zed Extension (`editors/zed/`)

```
editors/zed/
├── extension.toml
└── languages/
    └── ohtml/
        ├── config.toml
        ├── highlights.scm
        ├── injections.scm
        ├── brackets.scm
        └── indents.scm
```

#### `extension.toml`

```toml
[package]
name = "ohtml"
version = "0.1.0"
description = "Odin HTML template language support"
authors = ["Ankit Patial"]
repository = "https://github.com/ankitpatial/odin-html"

[grammars.ohtml]
repository = "https://github.com/ankitpatial/odin-html"
path = "tree-sitter-ohtml"
```

During local development, the grammar path points to the monorepo's `tree-sitter-ohtml/` directory.

#### `languages/ohtml/config.toml`

```toml
name = "OHTML"
grammar = "ohtml"
path_suffixes = ["ohtml"]
line_comments = ["<!-- ", " -->"]
block_comment = ["<!-- ", " -->"]
autoclose_before = ";:.,=}])|>"
brackets = [
    { start = "{", end = "}", close = true, newline = true },
    { start = "<", end = ">", close = false, newline = false },
    { start = "(", end = ")", close = true, newline = false },
    { start = "\"", end = "\"", close = true, newline = false },
]
```

#### Query Files

The query files in `editors/zed/languages/ohtml/` are copies of (or symlinks to) the canonical queries in `tree-sitter-ohtml/queries/`. Zed loads them from the extension's `languages/` directory.

#### Development Workflow

1. Build the Tree-sitter grammar: `cd tree-sitter-ohtml && npm install && npx tree-sitter generate`
2. Test the grammar: `npx tree-sitter test`
3. Install in Zed: Use Zed's **Extensions > Install Dev Extension** pointing to `editors/zed/`
4. Open any `.ohtml` file to verify highlighting

## Phase 2: LSP Server (Future)

### Architecture

```
Editor (Zed/any LSP client)
    ↕ stdio JSON-RPC
ohtml-lsp (Odin binary)
    ├── lsp/server.odin       — JSON-RPC message loop, dispatch
    ├── lsp/types.odin        — LSP protocol types (InitializeParams, etc.)
    ├── lsp/handlers.odin     — Request/notification handlers
    ├── lsp/document.odin     — Open document state management
    ├── lexer/                — (existing) tokenizer
    ├── parser/               — (existing) AST builder
    └── resolver/             — (existing) component resolution
```

The LSP server is a new binary target built from the existing codebase. It reuses the lexer, parser, and resolver without modification — they already produce errors with file path, line, and column information suitable for LSP diagnostics.

### Protocol Support

**Phase 2 capabilities:**

| LSP Method | Purpose |
|------------|---------|
| `initialize` / `initialized` | Capability negotiation |
| `textDocument/didOpen` | Track open documents |
| `textDocument/didChange` | Re-parse on edit, push diagnostics |
| `textDocument/didClose` | Clean up document state |
| `textDocument/publishDiagnostics` | Parse errors as diagnostics |
| `textDocument/definition` | Component name → `.ohtml` file |
| `textDocument/completion` | Component names from resolver registry |

**Not in Phase 2:** `textDocument/rename`, `textDocument/hover`, `textDocument/formatting` (could wire to existing `fmt` command), workspace symbols.

### Document Management

The LSP maintains an in-memory map of open documents. On each `didChange` notification:

1. Update the document buffer
2. Run lexer + parser on the buffer
3. If errors: publish diagnostics with line/col positions
4. If clean: clear diagnostics, update resolver registry for the file

This is lightweight — the existing parser already handles single-file parsing and produces errors with positions.

### Go-to-Definition

When the cursor is on a `<pkg.ComponentName>` tag:

1. Extract the component name from the AST node
2. Look up the component in the resolver's registry
3. Return the file path of the component's `.ohtml` file

### Completions

When typing in a component position (after `<`):

1. Query the resolver for all known component names
2. Return them as completion items with `CompletionItemKind.Class`

When typing in an attribute position on a component:

1. Look up the component's `Props` struct from its parsed AST
2. Return prop names as completion items

### Zed Integration (Phase 2 Addition)

The Zed extension gains a Rust WASM component to manage the LSP binary:

```
editors/zed/
├── extension.toml          # Add [language_servers.ohtml-lsp]
├── Cargo.toml              # Rust WASM build
├── src/
│   └── lib.rs              # Implements language_server_command()
└── languages/
    └── ohtml/
        └── ...             # (unchanged from Phase 1)
```

The `language_server_command()` implementation:
1. Checks if `ohtml-lsp` is on the user's `PATH`
2. If not, downloads the appropriate binary from a GitHub release
3. Returns the command to launch it with `--stdio`

## Deliverables Summary

| Phase | Deliverable | Location | Dependencies |
|-------|------------|----------|-------------|
| 1 | Tree-sitter grammar | `tree-sitter-ohtml/` | Node.js (dev only) |
| 1 | Zed extension (highlighting) | `editors/zed/` | Tree-sitter grammar |
| 2 | LSP server | `src/lsp/` | Existing lexer/parser/resolver |
| 2 | Zed LSP integration | `editors/zed/src/lib.rs` | LSP server binary |

## Testing Strategy

### Phase 1

- **Tree-sitter corpus tests** in `tree-sitter-ohtml/test/corpus/` — one file per syntax category (script blocks, elements, expressions, control flow, snippets, components, attributes)
- **Manual testing** in Zed with the dev extension installed, using the example `.ohtml` files in `examples/`

### Phase 2

- **LSP protocol tests** — Send JSON-RPC messages to the server via stdio and assert responses
- **Integration tests** — Open example `.ohtml` files, verify diagnostics and completions
