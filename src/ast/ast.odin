// src/ast/ast.odin
package ast

import "../token"

Document :: struct {
    file:     string,
    script:   Maybe(Script_Block),
    children: [dynamic]Node,
}

Script_Block :: struct {
    imports: [dynamic]Import,
    props:   Maybe(Props_Def),
    raw:     string,
}

Import :: struct {
    alias: Maybe(string),
    path:  string,
}

Props_Def :: struct {
    fields: [dynamic]Prop_Field,
}

Prop_Field :: struct {
    name:             string,
    type_expr:        string,
    is_snippet:       bool,
    snippet_arg_type: Maybe(string),
}

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
    content: string,
    pos:     token.Pos,
}

Raw_Html :: struct {
    content:    string,
    pos:        token.Pos,
    // is_literal: true when content is a literal HTML string (e.g. DOCTYPE declaration),
    // false when content is an Odin expression variable (e.g. from {@html my_var}).
    is_literal: bool,
}

Attribute :: struct {
    name:  string,
    value: Attr_Value,
    pos:   token.Pos,
}

Attr_Value :: union {
    Static_Value,
    Dynamic_Value,
    Bool_Shorthand,
}

Static_Value :: struct {
    value: string,
}

Dynamic_Value :: struct {
    expr: string,
}

Bool_Shorthand :: struct {}

If_Block :: struct {
    condition: string,
    children:  [dynamic]Node,
    else_ifs:  [dynamic]Else_If,
    else_body: Maybe([dynamic]Node),
    pos:       token.Pos,
}

Else_If :: struct {
    condition: string,
    children:  [dynamic]Node,
}

Each_Block :: struct {
    iterable:  string,
    binding:   string,
    index:     Maybe(string),
    children:  [dynamic]Node,
    else_body: Maybe([dynamic]Node),
    pos:       token.Pos,
}

Snippet_Def :: struct {
    name:       string,
    param_name: Maybe(string),
    param_type: Maybe(string),
    children:   [dynamic]Node,
    pos:        token.Pos,
}

Render_Call :: struct {
    name: string,
    args: Maybe(string),
    pos:  token.Pos,
}

Component :: struct {
    pkg:        string,
    name:       string,
    attributes: [dynamic]Attribute,
    children:   [dynamic]Node,
    self_close: bool,
    pos:        token.Pos,
}
