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
