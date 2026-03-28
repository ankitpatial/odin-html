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
