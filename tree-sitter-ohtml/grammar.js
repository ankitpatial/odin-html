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

    text: ($) => $._raw_text,
  },
});
