# OHTML Tree-sitter Grammar & Zed Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Tree-sitter grammar for `.ohtml` files and a Zed editor extension that provides syntax highlighting with Odin language injection.

**Architecture:** A Tree-sitter grammar (`tree-sitter-ohtml/`) defines the parse tree for `.ohtml` template files. A Zed extension (`editors/zed/`) references the grammar and provides highlighting queries, injection rules, bracket matching, and indentation. The grammar uses a custom external scanner in C for brace-counted expression content and script block content.

**Tech Stack:** Tree-sitter (grammar.js + C scanner), Zed extension API (TOML config + S-expression queries), Node.js (dev tooling only)

**Spec:** `docs/superpowers/specs/2026-03-28-ohtml-lsp-zed-extension-design.md` (Phase 1 only)

---

## File Structure

```
tree-sitter-ohtml/
├── grammar.js                  # Grammar definition (all rules)
├── package.json                # Node deps: tree-sitter-cli
├── src/
│   └── scanner.c               # External scanner: script content, expression content, raw text
├── queries/
│   ├── highlights.scm          # Syntax highlighting queries
│   ├── injections.scm          # Odin language injection
│   ├── brackets.scm            # Bracket pairs
│   └── indents.scm             # Indentation rules
└── test/
    └── corpus/
        ├── script_block.txt    # Script element tests
        ├── elements.txt        # HTML elements + self-closing
        ├── attributes.txt      # Static, dynamic, shorthand attrs
        ├── expressions.txt     # Expressions + raw HTML + render
        ├── control_flow.txt    # if/else if/else/each blocks
        ├── snippets.txt        # snippet def + render
        └── components.txt      # Component elements

editors/zed/
├── extension.toml              # Extension metadata + grammar ref
└── languages/
    └── ohtml/
        ├── config.toml         # File type config
        ├── highlights.scm      # (copy from tree-sitter-ohtml/queries/)
        ├── injections.scm      # (copy from tree-sitter-ohtml/queries/)
        ├── brackets.scm        # (copy from tree-sitter-ohtml/queries/)
        └── indents.scm         # (copy from tree-sitter-ohtml/queries/)
```

---

## Task 1: Scaffold Tree-sitter Project

**Files:**
- Create: `tree-sitter-ohtml/package.json`
- Create: `tree-sitter-ohtml/grammar.js` (minimal skeleton)
- Create: `tree-sitter-ohtml/src/scanner.c` (empty stub)

- [ ] **Step 1: Create package.json**

Create `tree-sitter-ohtml/package.json`:

```json
{
  "name": "tree-sitter-ohtml",
  "version": "0.1.0",
  "description": "Tree-sitter grammar for OHTML (Odin HTML) template files",
  "main": "bindings/node",
  "keywords": ["tree-sitter", "parser", "ohtml", "odin"],
  "license": "MIT",
  "dependencies": {
    "nan": "^2.18.0"
  },
  "devDependencies": {
    "tree-sitter-cli": "^0.24.0"
  },
  "scripts": {
    "generate": "tree-sitter generate",
    "test": "tree-sitter test",
    "parse": "tree-sitter parse"
  },
  "tree-sitter": [
    {
      "scope": "source.ohtml",
      "file-types": ["ohtml"],
      "injection-regex": "^ohtml$"
    }
  ]
}
```

- [ ] **Step 2: Create minimal grammar.js skeleton**

Create `tree-sitter-ohtml/grammar.js`:

```javascript
/// <reference types="tree-sitter-cli/dsl" />

module.exports = grammar({
  name: "ohtml",

  externals: ($) => [
    $._script_content,
    $._expression_content,
    $._raw_text,
  ],

  rules: {
    document: ($) => repeat($._node),

    _node: ($) => choice($.text),

    text: (_$) => /[^<{]+/,
  },
});
```

- [ ] **Step 3: Create empty scanner.c stub**

Create `tree-sitter-ohtml/src/scanner.c`:

```c
#include "tree_sitter/parser.h"

enum TokenType {
  SCRIPT_CONTENT,
  EXPRESSION_CONTENT,
  RAW_TEXT,
};

void *tree_sitter_ohtml_external_scanner_create(void) { return NULL; }
void tree_sitter_ohtml_external_scanner_destroy(void *payload) {}
unsigned tree_sitter_ohtml_external_scanner_serialize(void *payload, char *buffer) { return 0; }
void tree_sitter_ohtml_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {}

bool tree_sitter_ohtml_external_scanner_scan(
  void *payload,
  TSLexer *lexer,
  const bool *valid_symbols
) {
  return false;
}
```

- [ ] **Step 4: Install dependencies and verify generation**

Run:
```bash
cd tree-sitter-ohtml && npm install && npx tree-sitter generate
```

Expected: `src/parser.c` and `src/tree_sitter/parser.h` are generated without errors.

- [ ] **Step 5: Commit**

```bash
git add tree-sitter-ohtml/
git commit -m "feat: scaffold tree-sitter-ohtml project with minimal grammar"
```

---

## Task 2: Grammar — Script Element

**Files:**
- Modify: `tree-sitter-ohtml/grammar.js`
- Modify: `tree-sitter-ohtml/src/scanner.c`
- Create: `tree-sitter-ohtml/test/corpus/script_block.txt`

- [ ] **Step 1: Write test for script element**

Create `tree-sitter-ohtml/test/corpus/script_block.txt`:

```
===
Script block with props
===
<script lang="odin">
Props :: struct {
    title: string,
}
</script>
<div>hello</div>
---

(document
  (script_element
    (script_start_tag)
    (raw_text)
    (script_end_tag))
  (element
    (start_tag (tag_name))
    (text)
    (end_tag (tag_name))))

===
Document without script block
===
<div>hello</div>
---

(document
  (element
    (start_tag (tag_name))
    (text)
    (end_tag (tag_name))))

===
Script block with imports
===
<script lang="odin">
import "components/badge"
import card "components/card"

Props :: struct {
    name: string,
}
</script>
---

(document
  (script_element
    (script_start_tag)
    (raw_text)
    (script_end_tag)))
```

- [ ] **Step 2: Update grammar.js with script element and basic HTML element rules**

Update `tree-sitter-ohtml/grammar.js`:

```javascript
/// <reference types="tree-sitter-cli/dsl" />

module.exports = grammar({
  name: "ohtml",

  externals: ($) => [
    $._script_content,
    $._expression_content,
    $._raw_text,
  ],

  rules: {
    document: ($) =>
      seq(optional($.script_element), repeat($._node)),

    script_element: ($) =>
      seq($.script_start_tag, alias($._script_content, $.raw_text), $.script_end_tag),

    script_start_tag: (_$) => '<script lang="odin">',

    script_end_tag: (_$) => "</script>",

    _node: ($) =>
      choice(
        $.element,
        $.text,
      ),

    element: ($) =>
      choice(
        seq($.start_tag, repeat($._node), $.end_tag),
        $.self_closing_element,
      ),

    self_closing_element: ($) => $.self_closing_tag,

    start_tag: ($) =>
      seq("<", $.tag_name, repeat($.attribute), ">"),

    end_tag: ($) => seq("</", $.tag_name, ">"),

    self_closing_tag: ($) =>
      seq("<", $.tag_name, repeat($.attribute), "/>"),

    tag_name: (_$) => /[a-zA-Z][a-zA-Z0-9\-]*/,

    attribute: ($) =>
      seq(
        $.attribute_name,
        optional(seq("=", $._attribute_value)),
      ),

    attribute_name: (_$) => /[a-zA-Z_][a-zA-Z0-9_\-]*/,

    _attribute_value: ($) =>
      choice($.quoted_attribute_value),

    quoted_attribute_value: (_$) =>
      seq('"', /[^"]*/, '"'),

    text: (_$) => alias($._raw_text, "text"),
  },
});
```

- [ ] **Step 3: Implement script content scanning in scanner.c**

Update `tree-sitter-ohtml/src/scanner.c`:

```c
#include "tree_sitter/parser.h"
#include <string.h>

enum TokenType {
  SCRIPT_CONTENT,
  EXPRESSION_CONTENT,
  RAW_TEXT,
};

void *tree_sitter_ohtml_external_scanner_create(void) { return NULL; }
void tree_sitter_ohtml_external_scanner_destroy(void *payload) {}
unsigned tree_sitter_ohtml_external_scanner_serialize(void *payload, char *buffer) { return 0; }
void tree_sitter_ohtml_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {}

static bool scan_script_content(TSLexer *lexer) {
  // Read until we find </script>
  bool has_content = false;
  while (lexer->lookahead != 0) {
    if (lexer->lookahead == '<') {
      lexer->mark_end(lexer);
      lexer->advance(lexer, false);
      if (lexer->lookahead == '/') {
        lexer->advance(lexer, false);
        // Check for "script>"
        const char *closing = "script>";
        bool match = true;
        for (int i = 0; closing[i] != '\0'; i++) {
          if (lexer->lookahead != closing[i]) {
            match = false;
            break;
          }
          lexer->advance(lexer, false);
        }
        if (match) {
          lexer->result_symbol = SCRIPT_CONTENT;
          return has_content;
        }
      }
      has_content = true;
      continue;
    }
    has_content = true;
    lexer->advance(lexer, false);
  }
  return false;
}

static bool scan_raw_text(TSLexer *lexer) {
  bool has_content = false;
  while (lexer->lookahead != 0) {
    if (lexer->lookahead == '<' || lexer->lookahead == '{') {
      break;
    }
    has_content = true;
    lexer->advance(lexer, false);
  }
  if (has_content) {
    lexer->mark_end(lexer);
    lexer->result_symbol = RAW_TEXT;
    return true;
  }
  return false;
}

bool tree_sitter_ohtml_external_scanner_scan(
  void *payload,
  TSLexer *lexer,
  const bool *valid_symbols
) {
  if (valid_symbols[SCRIPT_CONTENT]) {
    return scan_script_content(lexer);
  }

  if (valid_symbols[RAW_TEXT]) {
    return scan_raw_text(lexer);
  }

  return false;
}
```

- [ ] **Step 4: Generate and run tests**

Run:
```bash
cd tree-sitter-ohtml && npx tree-sitter generate && npx tree-sitter test
```

Expected: All 3 tests in `script_block.txt` pass.

- [ ] **Step 5: Commit**

```bash
git add tree-sitter-ohtml/
git commit -m "feat: add script element parsing with external scanner"
```

---

## Task 3: Grammar — Expressions, Raw HTML, and Render

**Files:**
- Modify: `tree-sitter-ohtml/grammar.js`
- Modify: `tree-sitter-ohtml/src/scanner.c`
- Create: `tree-sitter-ohtml/test/corpus/expressions.txt`

- [ ] **Step 1: Write expression tests**

Create `tree-sitter-ohtml/test/corpus/expressions.txt`:

```
===
Simple expression
===
<span>{label}</span>
---

(document
  (element
    (start_tag (tag_name))
    (expression (expression_content))
    (end_tag (tag_name))))

===
Raw HTML expression
===
<div>{@html story_html}</div>
---

(document
  (element
    (start_tag (tag_name))
    (raw_html_expression (expression_content))
    (end_tag (tag_name))))

===
Render expression
===
<main>{@render children()}</main>
---

(document
  (element
    (start_tag (tag_name))
    (render_expression (render_content))
    (end_tag (tag_name))))

===
Render with argument
===
{@render item(p)}
---

(document
  (render_expression (render_content)))

===
Expression with nested braces
===
<span>{fmt.tprintf("%v", map[string]int{})}</span>
---

(document
  (element
    (start_tag (tag_name))
    (expression (expression_content))
    (end_tag (tag_name))))
```

- [ ] **Step 2: Add expression rules to grammar.js**

Update `tree-sitter-ohtml/grammar.js` — replace the entire file. Key changes: add `expression`, `raw_html_expression`, `render_expression` rules and wire `_expression_content` external into them. Add dynamic attribute value support.

```javascript
/// <reference types="tree-sitter-cli/dsl" />

module.exports = grammar({
  name: "ohtml",

  externals: ($) => [
    $._script_content,
    $._expression_content,
    $._raw_text,
  ],

  rules: {
    document: ($) =>
      seq(optional($.script_element), repeat($._node)),

    script_element: ($) =>
      seq(
        $.script_start_tag,
        alias($._script_content, $.raw_text),
        $.script_end_tag,
      ),

    script_start_tag: (_$) => '<script lang="odin">',
    script_end_tag: (_$) => "</script>",

    _node: ($) =>
      choice(
        $.element,
        $.self_closing_element,
        $.expression,
        $.raw_html_expression,
        $.render_expression,
        $.text,
      ),

    // --- HTML Elements ---

    element: ($) =>
      seq($.start_tag, repeat($._node), $.end_tag),

    self_closing_element: ($) => $.self_closing_tag,

    start_tag: ($) =>
      seq("<", $.tag_name, repeat($._attribute_or_shorthand), ">"),

    end_tag: ($) => seq("</", $.tag_name, ">"),

    self_closing_tag: ($) =>
      seq("<", $.tag_name, repeat($._attribute_or_shorthand), "/>"),

    tag_name: (_$) => /[a-zA-Z][a-zA-Z0-9\-]*/,

    // --- Attributes ---

    _attribute_or_shorthand: ($) =>
      choice($.attribute, $.attribute_shorthand),

    attribute: ($) =>
      seq($.attribute_name, optional(seq("=", $._attribute_value))),

    attribute_name: (_$) => /[a-zA-Z_][a-zA-Z0-9_\-]*/,

    _attribute_value: ($) =>
      choice($.quoted_attribute_value, $.expression),

    quoted_attribute_value: (_$) => seq('"', /[^"]*/, '"'),

    // Shorthand: {disabled} in attribute position
    attribute_shorthand: ($) =>
      seq("{", $.expression_content, "}"),

    // --- Expressions ---

    expression: ($) =>
      seq("{", $.expression_content, "}"),

    raw_html_expression: ($) =>
      seq("{@html", $.expression_content, "}"),

    render_expression: ($) =>
      seq("{@render", $.render_content, "}"),

    expression_content: ($) => alias($._expression_content, $.expression_content),

    render_content: ($) => alias($._expression_content, $.render_content),

    // --- Text ---

    text: ($) => alias($._raw_text, $.text),
  },
});
```

- [ ] **Step 3: Add expression content scanning to scanner.c**

Add the `scan_expression_content` function to `tree-sitter-ohtml/src/scanner.c`. This function counts brace depth to handle nested Odin expressions like `map[string]int{}`.

Replace the `tree_sitter_ohtml_external_scanner_scan` function and add the new scanner:

```c
static bool scan_expression_content(TSLexer *lexer) {
  // We're inside { already (or after @html/@render keyword).
  // Read until we hit the matching closing } at depth 0.
  int depth = 0;
  bool has_content = false;

  // Skip leading whitespace
  while (lexer->lookahead == ' ' || lexer->lookahead == '\t' ||
         lexer->lookahead == '\n' || lexer->lookahead == '\r') {
    lexer->advance(lexer, true);
  }

  while (lexer->lookahead != 0) {
    if (lexer->lookahead == '{') {
      depth++;
      has_content = true;
      lexer->advance(lexer, false);
    } else if (lexer->lookahead == '}') {
      if (depth == 0) {
        lexer->mark_end(lexer);
        lexer->result_symbol = EXPRESSION_CONTENT;
        return has_content;
      }
      depth--;
      has_content = true;
      lexer->advance(lexer, false);
    } else {
      has_content = true;
      lexer->advance(lexer, false);
    }
  }
  return false;
}
```

Update the main scan function:

```c
bool tree_sitter_ohtml_external_scanner_scan(
  void *payload,
  TSLexer *lexer,
  const bool *valid_symbols
) {
  if (valid_symbols[SCRIPT_CONTENT]) {
    return scan_script_content(lexer);
  }

  if (valid_symbols[EXPRESSION_CONTENT]) {
    return scan_expression_content(lexer);
  }

  if (valid_symbols[RAW_TEXT]) {
    return scan_raw_text(lexer);
  }

  return false;
}
```

- [ ] **Step 4: Generate and run tests**

Run:
```bash
cd tree-sitter-ohtml && npx tree-sitter generate && npx tree-sitter test
```

Expected: All tests in `script_block.txt` and `expressions.txt` pass.

- [ ] **Step 5: Commit**

```bash
git add tree-sitter-ohtml/
git commit -m "feat: add expression, raw HTML, and render expression parsing"
```

---

## Task 4: Grammar — Attributes (Static, Dynamic, Shorthand)

**Files:**
- Create: `tree-sitter-ohtml/test/corpus/attributes.txt`
- (Grammar rules already added in Task 3)

- [ ] **Step 1: Write attribute tests**

Create `tree-sitter-ohtml/test/corpus/attributes.txt`:

```
===
Static attribute
===
<div class="container">hello</div>
---

(document
  (element
    (start_tag
      (tag_name)
      (attribute (attribute_name) (quoted_attribute_value)))
    (text)
    (end_tag (tag_name))))

===
Dynamic attribute
===
<a href={slug}>link</a>
---

(document
  (element
    (start_tag
      (tag_name)
      (attribute (attribute_name) (expression (expression_content))))
    (text)
    (end_tag (tag_name))))

===
Shorthand attribute
===
<input {disabled} />
---

(document
  (self_closing_element
    (self_closing_tag
      (tag_name)
      (attribute_shorthand (expression_content)))))

===
Multiple attributes
===
<img src={image_url} alt={name} class="thumb" />
---

(document
  (self_closing_element
    (self_closing_tag
      (tag_name)
      (attribute (attribute_name) (expression (expression_content)))
      (attribute (attribute_name) (expression (expression_content)))
      (attribute (attribute_name) (quoted_attribute_value)))))

===
Boolean attribute without value
===
<input disabled />
---

(document
  (self_closing_element
    (self_closing_tag
      (tag_name)
      (attribute (attribute_name)))))
```

- [ ] **Step 2: Generate and run tests**

Run:
```bash
cd tree-sitter-ohtml && npx tree-sitter generate && npx tree-sitter test
```

Expected: All tests pass including the new attribute tests.

- [ ] **Step 3: Commit**

```bash
git add tree-sitter-ohtml/
git commit -m "test: add attribute parsing tests (static, dynamic, shorthand)"
```

---

## Task 5: Grammar — Control Flow (if/else if/else, each)

**Files:**
- Modify: `tree-sitter-ohtml/grammar.js`
- Create: `tree-sitter-ohtml/test/corpus/control_flow.txt`

- [ ] **Step 1: Write control flow tests**

Create `tree-sitter-ohtml/test/corpus/control_flow.txt`:

```
===
Simple if block
===
{#if on_sale}
    <span>Sale!</span>
{/if}
---

(document
  (if_block
    (if_start (expression_content))
    (element
      (start_tag (tag_name))
      (text)
      (end_tag (tag_name)))
    (if_end)))

===
If/else if/else block
===
{#if on_sale}
    <span>Sale</span>
{:else if is_new}
    <span>New</span>
{:else}
    <span>Regular</span>
{/if}
---

(document
  (if_block
    (if_start (expression_content))
    (element
      (start_tag (tag_name))
      (text)
      (end_tag (tag_name)))
    (else_if_clause
      (expression_content)
      (element
        (start_tag (tag_name))
        (text)
        (end_tag (tag_name))))
    (else_clause
      (element
        (start_tag (tag_name))
        (text)
        (end_tag (tag_name))))
    (if_end)))

===
Each block
===
{#each products as p}
    <span>{p.name}</span>
{/each}
---

(document
  (each_block
    (each_start
      (expression_content)
      (binding))
    (element
      (start_tag (tag_name))
      (expression (expression_content))
      (end_tag (tag_name)))
    (each_end)))

===
Each with index and else
===
{#each items as item, idx}
    <span>{item}</span>
{:else}
    <p>No items.</p>
{/each}
---

(document
  (each_block
    (each_start
      (expression_content)
      (binding)
      (index_binding))
    (element
      (start_tag (tag_name))
      (expression (expression_content))
      (end_tag (tag_name)))
    (else_clause
      (element
        (start_tag (tag_name))
        (text)
        (end_tag (tag_name))))
    (each_end)))
```

- [ ] **Step 2: Add control flow rules to grammar.js**

Add these rules to `tree-sitter-ohtml/grammar.js`. Update `_node` to include `if_block` and `each_block`. Add the new rules:

In the `_node` choice, add `$.if_block` and `$.each_block` (component rules will be added in Task 7):

```javascript
    _node: ($) =>
      choice(
        $.element,
        $.self_closing_element,
        $.expression,
        $.raw_html_expression,
        $.render_expression,
        $.if_block,
        $.each_block,
        $.text,
      ),
```

Add these new rules:

```javascript
    // --- Control Flow ---

    if_block: ($) =>
      seq(
        $.if_start,
        repeat($._node),
        repeat($.else_if_clause),
        optional($.else_clause),
        $.if_end,
      ),

    if_start: ($) =>
      seq("{#if", $.expression_content, "}"),

    else_if_clause: ($) =>
      seq("{:else if", $.expression_content, "}", repeat($._node)),

    else_clause: ($) =>
      seq("{:else}", repeat($._node)),

    if_end: (_$) => "{/if}",

    each_block: ($) =>
      seq(
        $.each_start,
        repeat($._node),
        optional($.else_clause),
        $.each_end,
      ),

    each_start: ($) =>
      seq(
        "{#each",
        $.expression_content,
        "as",
        $.binding,
        optional(seq(",", $.index_binding)),
        "}",
      ),

    binding: (_$) => /[a-zA-Z_][a-zA-Z0-9_]*/,

    index_binding: (_$) => /[a-zA-Z_][a-zA-Z0-9_]*/,

    each_end: (_$) => "{/each}",
```

- [ ] **Step 3: Generate and run tests**

Run:
```bash
cd tree-sitter-ohtml && npx tree-sitter generate && npx tree-sitter test
```

Expected: All tests pass including control flow tests.

- [ ] **Step 4: Commit**

```bash
git add tree-sitter-ohtml/
git commit -m "feat: add if/else if/else and each block parsing"
```

---

## Task 6: Grammar — Snippets

**Files:**
- Modify: `tree-sitter-ohtml/grammar.js`
- Create: `tree-sitter-ohtml/test/corpus/snippets.txt`

- [ ] **Step 1: Write snippet tests**

Create `tree-sitter-ohtml/test/corpus/snippets.txt`:

```
===
Snippet definition without params
===
{#snippet header()}
    <h1>Title</h1>
{/snippet}
---

(document
  (snippet_block
    (snippet_start
      (snippet_name)
      (snippet_params))
    (element
      (start_tag (tag_name))
      (text)
      (end_tag (tag_name)))
    (snippet_end)))

===
Snippet with typed parameter
===
{#snippet item(p: Product)}
    <span>{p.name}</span>
{/snippet}
---

(document
  (snippet_block
    (snippet_start
      (snippet_name)
      (snippet_params))
    (element
      (start_tag (tag_name))
      (expression (expression_content))
      (end_tag (tag_name)))
    (snippet_end)))
```

- [ ] **Step 2: Add snippet rules to grammar.js**

Add `$.snippet_block` to the `_node` choice. Add these rules:

```javascript
    // --- Snippets ---

    snippet_block: ($) =>
      seq($.snippet_start, repeat($._node), $.snippet_end),

    snippet_start: ($) =>
      seq("{#snippet", $.snippet_name, "(", $.snippet_params, ")"),

    snippet_name: (_$) => /[a-zA-Z_][a-zA-Z0-9_]*/,

    snippet_params: (_$) => /[^)]*/,

    snippet_end: (_$) => "{/snippet}",
```

- [ ] **Step 3: Generate and run tests**

Run:
```bash
cd tree-sitter-ohtml && npx tree-sitter generate && npx tree-sitter test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add tree-sitter-ohtml/
git commit -m "feat: add snippet block parsing"
```

---

## Task 7: Grammar — Components

**Files:**
- Modify: `tree-sitter-ohtml/grammar.js`
- Create: `tree-sitter-ohtml/test/corpus/components.txt`

- [ ] **Step 1: Write component tests**

Create `tree-sitter-ohtml/test/corpus/components.txt`:

```
===
Self-closing component
===
<badge.Badge label="Sale" variant="badge--sale" />
---

(document
  (self_closing_component
    (component_self_closing_tag
      (component_name)
      (attribute (attribute_name) (quoted_attribute_value))
      (attribute (attribute_name) (quoted_attribute_value)))))

===
Component with children
===
<product_grid.ProductGrid title={category} products={products}>
    <p>child content</p>
</product_grid.ProductGrid>
---

(document
  (component
    (component_start_tag
      (component_name)
      (attribute (attribute_name) (expression (expression_content)))
      (attribute (attribute_name) (expression (expression_content))))
    (element
      (start_tag (tag_name))
      (text)
      (end_tag (tag_name)))
    (component_end_tag
      (component_name))))

===
Component with dynamic attributes
===
<price.Price amount={amount} sale_amount={sale_amount} on_sale={on_sale} />
---

(document
  (self_closing_component
    (component_self_closing_tag
      (component_name)
      (attribute (attribute_name) (expression (expression_content)))
      (attribute (attribute_name) (expression (expression_content)))
      (attribute (attribute_name) (expression (expression_content))))))
```

- [ ] **Step 2: Add component rules to grammar.js**

Components are distinguished from regular HTML elements by having a dotted name (e.g., `pkg.Name`). Add `$.component` and `$.self_closing_component` to the `_node` choice. Add these rules:

```javascript
    // --- Components ---

    component: ($) =>
      seq(
        $.component_start_tag,
        repeat($._node),
        $.component_end_tag,
      ),

    self_closing_component: ($) => $.component_self_closing_tag,

    component_start_tag: ($) =>
      seq("<", $.component_name, repeat($._attribute_or_shorthand), ">"),

    component_end_tag: ($) =>
      seq("</", $.component_name, ">"),

    component_self_closing_tag: ($) =>
      seq("<", $.component_name, repeat($._attribute_or_shorthand), "/>"),

    // Dotted name: pkg.ComponentName
    component_name: (_$) => /[a-zA-Z_][a-zA-Z0-9_]*\.[A-Z][a-zA-Z0-9_]*/,
```

- [ ] **Step 3: Generate and run tests**

Run:
```bash
cd tree-sitter-ohtml && npx tree-sitter generate && npx tree-sitter test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add tree-sitter-ohtml/
git commit -m "feat: add component element parsing with dotted names"
```

---

## Task 8: Grammar — HTML Elements (doctype, comments, self-closing)

**Files:**
- Modify: `tree-sitter-ohtml/grammar.js`
- Create: `tree-sitter-ohtml/test/corpus/elements.txt`

- [ ] **Step 1: Write element tests**

Create `tree-sitter-ohtml/test/corpus/elements.txt`:

```
===
DOCTYPE declaration
===
<!DOCTYPE html>
<html lang="en">
</html>
---

(document
  (doctype)
  (element
    (start_tag (tag_name) (attribute (attribute_name) (quoted_attribute_value)))
    (end_tag (tag_name))))

===
HTML comment
===
<!-- This is a comment -->
<div>content</div>
---

(document
  (comment)
  (element
    (start_tag (tag_name))
    (text)
    (end_tag (tag_name))))

===
Self-closing elements
===
<meta charset="utf-8" />
<img src="photo.jpg" alt="A photo" />
---

(document
  (self_closing_element
    (self_closing_tag
      (tag_name)
      (attribute (attribute_name) (quoted_attribute_value))))
  (self_closing_element
    (self_closing_tag
      (tag_name)
      (attribute (attribute_name) (quoted_attribute_value))
      (attribute (attribute_name) (quoted_attribute_value)))))

===
Nested elements
===
<div class="outer">
    <span class="inner">text</span>
</div>
---

(document
  (element
    (start_tag (tag_name) (attribute (attribute_name) (quoted_attribute_value)))
    (element
      (start_tag (tag_name) (attribute (attribute_name) (quoted_attribute_value)))
      (text)
      (end_tag (tag_name)))
    (end_tag (tag_name))))
```

- [ ] **Step 2: Add doctype and comment rules to grammar.js**

Add `$.doctype` and `$.comment` to the `_node` choice. Add these rules:

```javascript
    // --- Doctype & Comments ---

    doctype: (_$) => /<!DOCTYPE\s+html\s*>/i,

    comment: (_$) => seq("<!--", /[^]*?/, "-->"),
```

Note: The comment regex uses a non-greedy match to find the first `-->`.

- [ ] **Step 3: Generate and run tests**

Run:
```bash
cd tree-sitter-ohtml && npx tree-sitter generate && npx tree-sitter test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add tree-sitter-ohtml/
git commit -m "feat: add doctype, comment, and nested element tests"
```

---

## Task 9: Integration Test — Parse Real Example Files

**Files:**
- (no new files — uses existing examples)

- [ ] **Step 1: Parse each example file and verify no errors**

Run each example through the parser and verify there are no ERROR nodes:

```bash
cd tree-sitter-ohtml
npx tree-sitter parse ../examples/ecomm/components/badge/Badge.ohtml
npx tree-sitter parse ../examples/ecomm/components/product_card/ProductCard.ohtml
npx tree-sitter parse ../examples/ecomm/views/+layout.ohtml
npx tree-sitter parse ../examples/ecomm/views/+page.ohtml
npx tree-sitter parse ../examples/ecomm/views/about/+page.ohtml
npx tree-sitter parse ../examples/ecomm/views/products/+page.ohtml
```

Expected: Each file produces a valid parse tree. No `(ERROR)` nodes appear.

- [ ] **Step 2: Fix any parsing issues discovered**

If any files fail to parse, examine the output to find which construct causes the `ERROR` node. Common issues:
- Expression content scanning not handling edge cases
- Component name regex not matching actual names
- Whitespace handling between tokens

Fix the grammar rules or scanner as needed, then re-run all corpus tests + example parses.

- [ ] **Step 3: Commit any fixes**

```bash
git add tree-sitter-ohtml/
git commit -m "fix: resolve parsing issues found in integration testing"
```

---

## Task 10: Query Files — Highlights, Injections, Brackets, Indents

**Files:**
- Create: `tree-sitter-ohtml/queries/highlights.scm`
- Create: `tree-sitter-ohtml/queries/injections.scm`
- Create: `tree-sitter-ohtml/queries/brackets.scm`
- Create: `tree-sitter-ohtml/queries/indents.scm`

- [ ] **Step 1: Create highlights.scm**

Create `tree-sitter-ohtml/queries/highlights.scm`:

```scheme
; --- Tags ---
(start_tag (tag_name) @tag)
(end_tag (tag_name) @tag)
(self_closing_tag (tag_name) @tag)
(script_start_tag) @tag
(script_end_tag) @tag

; --- Components ---
(component_start_tag (component_name) @type)
(component_end_tag (component_name) @type)
(component_self_closing_tag (component_name) @type)

; --- Attributes ---
(attribute (attribute_name) @attribute)
(quoted_attribute_value) @string

; --- Control Flow Keywords ---
(if_start) @keyword.control
(if_end) @keyword.control
(else_if_clause) @keyword.control
(else_clause) @keyword.control
(each_start) @keyword.control
(each_end) @keyword.control

; --- Snippets ---
(snippet_start) @keyword.control
(snippet_end) @keyword.control
(snippet_name) @function

; --- Directives ---
(raw_html_expression) @keyword.directive
(render_expression) @keyword.directive

; --- Bindings ---
(binding) @variable
(index_binding) @variable

; --- Punctuation ---
"<" @punctuation.bracket
">" @punctuation.bracket
"</" @punctuation.bracket
"/>" @punctuation.bracket
"=" @operator
"{" @punctuation.special
"}" @punctuation.special

; --- Comments ---
(comment) @comment

; --- Doctype ---
(doctype) @keyword
```

- [ ] **Step 2: Create injections.scm**

Create `tree-sitter-ohtml/queries/injections.scm`:

```scheme
; Script block content -> Odin
((script_element (raw_text) @content)
 (#set! "language" "odin"))

; Expression content -> Odin
((expression (expression_content) @content)
 (#set! "language" "odin"))

; Raw HTML expression content -> Odin
((raw_html_expression (expression_content) @content)
 (#set! "language" "odin"))

; Render expression content -> Odin
((render_expression (render_content) @content)
 (#set! "language" "odin"))

; If condition -> Odin
((if_start (expression_content) @content)
 (#set! "language" "odin"))

; Else-if condition -> Odin
((else_if_clause (expression_content) @content)
 (#set! "language" "odin"))

; Each iterable -> Odin
((each_start (expression_content) @content)
 (#set! "language" "odin"))
```

- [ ] **Step 3: Create brackets.scm**

Create `tree-sitter-ohtml/queries/brackets.scm`:

```scheme
("{" @open "}" @close)
("(" @open ")" @close)
("<" @open ">" @close)
```

- [ ] **Step 4: Create indents.scm**

Create `tree-sitter-ohtml/queries/indents.scm`:

```scheme
; Indent after opening tags
(element (start_tag) @indent)
(element (end_tag) @outdent)

; Indent after component opening tags
(component (component_start_tag) @indent)
(component (component_end_tag) @outdent)

; Indent after control flow openers
(if_block (if_start) @indent)
(if_block (if_end) @outdent)
(each_block (each_start) @indent)
(each_block (each_end) @outdent)
(snippet_block (snippet_start) @indent)
(snippet_block (snippet_end) @outdent)

; Else clauses: outdent then indent
(else_if_clause) @outdent @indent
(else_clause) @outdent @indent
```

- [ ] **Step 5: Verify highlights work with tree-sitter**

Run:
```bash
cd tree-sitter-ohtml && npx tree-sitter highlight ../examples/ecomm/components/badge/Badge.ohtml
```

Expected: Output shows colored/tagged text with highlight scopes applied.

- [ ] **Step 6: Commit**

```bash
git add tree-sitter-ohtml/queries/
git commit -m "feat: add highlight, injection, bracket, and indent queries"
```

---

## Task 11: Zed Extension

**Files:**
- Create: `editors/zed/extension.toml`
- Create: `editors/zed/languages/ohtml/config.toml`
- Copy: `editors/zed/languages/ohtml/highlights.scm` (from `tree-sitter-ohtml/queries/`)
- Copy: `editors/zed/languages/ohtml/injections.scm`
- Copy: `editors/zed/languages/ohtml/brackets.scm`
- Copy: `editors/zed/languages/ohtml/indents.scm`

- [ ] **Step 1: Create extension.toml**

Create `editors/zed/extension.toml`:

```toml
[package]
name = "ohtml"
version = "0.1.0"
description = "Odin HTML template language support — syntax highlighting with Odin injection"
authors = ["Ankit Patial"]
repository = "https://github.com/ankitpatial/odin-html"

[grammars.ohtml]
repository = "https://github.com/ankitpatial/odin-html"
path = "tree-sitter-ohtml"
```

- [ ] **Step 2: Create languages/ohtml/config.toml**

Create `editors/zed/languages/ohtml/config.toml`:

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

- [ ] **Step 3: Copy query files to Zed extension**

```bash
mkdir -p editors/zed/languages/ohtml
cp tree-sitter-ohtml/queries/highlights.scm editors/zed/languages/ohtml/
cp tree-sitter-ohtml/queries/injections.scm editors/zed/languages/ohtml/
cp tree-sitter-ohtml/queries/brackets.scm editors/zed/languages/ohtml/
cp tree-sitter-ohtml/queries/indents.scm editors/zed/languages/ohtml/
```

- [ ] **Step 4: Commit**

```bash
git add editors/
git commit -m "feat: add Zed extension with OHTML language support"
```

---

## Task 12: Manual Verification in Zed

- [ ] **Step 1: Install dev extension in Zed**

In Zed:
1. Open **Extensions** panel (Cmd+Shift+X or via menu)
2. Click **Install Dev Extension**
3. Select the `editors/zed/` directory from this repo

- [ ] **Step 2: Open an .ohtml file and verify highlighting**

Open `examples/ecomm/components/product_card/ProductCard.ohtml` in Zed. Verify:
- `<script lang="odin">` tag is colored as a tag
- Odin code inside the script block has Odin syntax highlighting (imports, struct, types)
- HTML tags (`<div>`, `<span>`) are colored as tags
- Component names (`<badge.Badge>`, `<price.Price>`) are colored as types
- Expressions (`{name}`, `{slug}`) have highlighted delimiters and Odin content
- Control flow (`{#if on_sale}`, `{:else if is_new}`, `{/if}`) are colored as keywords
- `{@render children()}` is colored as a directive
- Attributes (`class=`, `href=`) are colored as attributes
- String values (`"product-card"`) are colored as strings

- [ ] **Step 3: Open layout file and verify**

Open `examples/ecomm/views/+layout.ohtml`. Verify:
- `<!DOCTYPE html>` is highlighted as a keyword
- Nested HTML structure is properly parsed
- `{@render children()}` is highlighted as a directive

- [ ] **Step 4: Fix any issues found and commit**

If anything doesn't highlight correctly, check:
- The grammar is generating the expected tree (use `tree-sitter parse` to debug)
- The highlight queries match the actual node names in the grammar
- The injection queries use the correct node structure

```bash
git add -A
git commit -m "fix: address highlighting issues found during Zed testing"
```

---

## Task Dependency Graph

```
Task 1 (scaffold)
  └── Task 2 (script element)
        └── Task 3 (expressions)
              ├── Task 4 (attributes - tests only)
              ├── Task 5 (control flow)
              │     └── Task 6 (snippets)
              └── Task 7 (components)
                    └── Task 8 (doctype, comments)
                          └── Task 9 (integration test)
                                └── Task 10 (query files)
                                      └── Task 11 (Zed extension)
                                            └── Task 12 (manual verification)
```

Tasks 4-8 can be parallelized after Task 3 is complete. Tasks 10-12 are sequential.
