/// <reference types="tree-sitter-cli/dsl" />

module.exports = grammar({
  name: "ohtml",

  externals: ($) => [
    $._script_content,
    $._expression_content,
    $._raw_text,
    $._comment,
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
        $.component,
        $.self_closing_component,
        $.expression,
        $.raw_html_expression,
        $.render_expression,
        $.if_block,
        $.each_block,
        $.snippet_block,
        $.doctype,
        $.comment,
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

    expression_content: ($) => $._expression_content,

    render_content: ($) => $._expression_content,

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
      seq("{#each", $.expression_content, "}"),

    each_end: (_$) => "{/each}",

    // --- Snippets ---

    snippet_block: ($) =>
      seq($.snippet_start, repeat($._node), $.snippet_end),

    snippet_start: ($) =>
      seq("{#snippet", $.snippet_name, "(", $.snippet_params, ")}"),

    snippet_name: (_$) => /[a-zA-Z_][a-zA-Z0-9_]*/,

    snippet_params: (_$) => /[^)]*/,

    snippet_end: (_$) => "{/snippet}",

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

    component_name: (_$) => /[a-zA-Z_][a-zA-Z0-9_]*\.[A-Z][a-zA-Z0-9_]*/,

    // --- Doctype & Comments ---

    doctype: (_$) => /<!DOCTYPE\s+html\s*>/i,

    comment: ($) => $._comment,

    // --- Text ---

    text: ($) => $._raw_text,
  },
});
