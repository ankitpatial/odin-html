#include "tree_sitter/parser.h"

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 74
#define LARGE_STATE_COUNT 2
#define SYMBOL_COUNT 40
#define ALIAS_COUNT 0
#define TOKEN_COUNT 19
#define EXTERNAL_TOKEN_COUNT 3
#define FIELD_COUNT 0
#define MAX_ALIAS_SEQUENCE_LENGTH 4
#define PRODUCTION_ID_COUNT 1

enum ts_symbol_identifiers {
  sym_script_start_tag = 1,
  sym_script_end_tag = 2,
  anon_sym_LT = 3,
  anon_sym_GT = 4,
  anon_sym_LT_SLASH = 5,
  anon_sym_SLASH_GT = 6,
  sym_tag_name = 7,
  anon_sym_EQ = 8,
  sym_attribute_name = 9,
  anon_sym_DQUOTE = 10,
  aux_sym_quoted_attribute_value_token1 = 11,
  anon_sym_LBRACE = 12,
  anon_sym_RBRACE = 13,
  anon_sym_LBRACE_AThtml = 14,
  anon_sym_LBRACE_ATrender = 15,
  sym__script_content = 16,
  sym__expression_content = 17,
  sym__raw_text = 18,
  sym_document = 19,
  sym_script_element = 20,
  sym__node = 21,
  sym_element = 22,
  sym_self_closing_element = 23,
  sym_start_tag = 24,
  sym_end_tag = 25,
  sym_self_closing_tag = 26,
  sym__attribute_or_shorthand = 27,
  sym_attribute = 28,
  sym__attribute_value = 29,
  sym_quoted_attribute_value = 30,
  sym_attribute_shorthand = 31,
  sym_expression = 32,
  sym_raw_html_expression = 33,
  sym_render_expression = 34,
  sym_expression_content = 35,
  sym_render_content = 36,
  sym_text = 37,
  aux_sym_document_repeat1 = 38,
  aux_sym_start_tag_repeat1 = 39,
};

static const char * const ts_symbol_names[] = {
  [ts_builtin_sym_end] = "end",
  [sym_script_start_tag] = "script_start_tag",
  [sym_script_end_tag] = "script_end_tag",
  [anon_sym_LT] = "<",
  [anon_sym_GT] = ">",
  [anon_sym_LT_SLASH] = "</",
  [anon_sym_SLASH_GT] = "/>",
  [sym_tag_name] = "tag_name",
  [anon_sym_EQ] = "=",
  [sym_attribute_name] = "attribute_name",
  [anon_sym_DQUOTE] = "\"",
  [aux_sym_quoted_attribute_value_token1] = "quoted_attribute_value_token1",
  [anon_sym_LBRACE] = "{",
  [anon_sym_RBRACE] = "}",
  [anon_sym_LBRACE_AThtml] = "{@html",
  [anon_sym_LBRACE_ATrender] = "{@render",
  [sym__script_content] = "raw_text",
  [sym__expression_content] = "_expression_content",
  [sym__raw_text] = "_raw_text",
  [sym_document] = "document",
  [sym_script_element] = "script_element",
  [sym__node] = "_node",
  [sym_element] = "element",
  [sym_self_closing_element] = "self_closing_element",
  [sym_start_tag] = "start_tag",
  [sym_end_tag] = "end_tag",
  [sym_self_closing_tag] = "self_closing_tag",
  [sym__attribute_or_shorthand] = "_attribute_or_shorthand",
  [sym_attribute] = "attribute",
  [sym__attribute_value] = "_attribute_value",
  [sym_quoted_attribute_value] = "quoted_attribute_value",
  [sym_attribute_shorthand] = "attribute_shorthand",
  [sym_expression] = "expression",
  [sym_raw_html_expression] = "raw_html_expression",
  [sym_render_expression] = "render_expression",
  [sym_expression_content] = "expression_content",
  [sym_render_content] = "render_content",
  [sym_text] = "text",
  [aux_sym_document_repeat1] = "document_repeat1",
  [aux_sym_start_tag_repeat1] = "start_tag_repeat1",
};

static const TSSymbol ts_symbol_map[] = {
  [ts_builtin_sym_end] = ts_builtin_sym_end,
  [sym_script_start_tag] = sym_script_start_tag,
  [sym_script_end_tag] = sym_script_end_tag,
  [anon_sym_LT] = anon_sym_LT,
  [anon_sym_GT] = anon_sym_GT,
  [anon_sym_LT_SLASH] = anon_sym_LT_SLASH,
  [anon_sym_SLASH_GT] = anon_sym_SLASH_GT,
  [sym_tag_name] = sym_tag_name,
  [anon_sym_EQ] = anon_sym_EQ,
  [sym_attribute_name] = sym_attribute_name,
  [anon_sym_DQUOTE] = anon_sym_DQUOTE,
  [aux_sym_quoted_attribute_value_token1] = aux_sym_quoted_attribute_value_token1,
  [anon_sym_LBRACE] = anon_sym_LBRACE,
  [anon_sym_RBRACE] = anon_sym_RBRACE,
  [anon_sym_LBRACE_AThtml] = anon_sym_LBRACE_AThtml,
  [anon_sym_LBRACE_ATrender] = anon_sym_LBRACE_ATrender,
  [sym__script_content] = sym__script_content,
  [sym__expression_content] = sym__expression_content,
  [sym__raw_text] = sym__raw_text,
  [sym_document] = sym_document,
  [sym_script_element] = sym_script_element,
  [sym__node] = sym__node,
  [sym_element] = sym_element,
  [sym_self_closing_element] = sym_self_closing_element,
  [sym_start_tag] = sym_start_tag,
  [sym_end_tag] = sym_end_tag,
  [sym_self_closing_tag] = sym_self_closing_tag,
  [sym__attribute_or_shorthand] = sym__attribute_or_shorthand,
  [sym_attribute] = sym_attribute,
  [sym__attribute_value] = sym__attribute_value,
  [sym_quoted_attribute_value] = sym_quoted_attribute_value,
  [sym_attribute_shorthand] = sym_attribute_shorthand,
  [sym_expression] = sym_expression,
  [sym_raw_html_expression] = sym_raw_html_expression,
  [sym_render_expression] = sym_render_expression,
  [sym_expression_content] = sym_expression_content,
  [sym_render_content] = sym_render_content,
  [sym_text] = sym_text,
  [aux_sym_document_repeat1] = aux_sym_document_repeat1,
  [aux_sym_start_tag_repeat1] = aux_sym_start_tag_repeat1,
};

static const TSSymbolMetadata ts_symbol_metadata[] = {
  [ts_builtin_sym_end] = {
    .visible = false,
    .named = true,
  },
  [sym_script_start_tag] = {
    .visible = true,
    .named = true,
  },
  [sym_script_end_tag] = {
    .visible = true,
    .named = true,
  },
  [anon_sym_LT] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_GT] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LT_SLASH] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_SLASH_GT] = {
    .visible = true,
    .named = false,
  },
  [sym_tag_name] = {
    .visible = true,
    .named = true,
  },
  [anon_sym_EQ] = {
    .visible = true,
    .named = false,
  },
  [sym_attribute_name] = {
    .visible = true,
    .named = true,
  },
  [anon_sym_DQUOTE] = {
    .visible = true,
    .named = false,
  },
  [aux_sym_quoted_attribute_value_token1] = {
    .visible = false,
    .named = false,
  },
  [anon_sym_LBRACE] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_RBRACE] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LBRACE_AThtml] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LBRACE_ATrender] = {
    .visible = true,
    .named = false,
  },
  [sym__script_content] = {
    .visible = true,
    .named = true,
  },
  [sym__expression_content] = {
    .visible = false,
    .named = true,
  },
  [sym__raw_text] = {
    .visible = false,
    .named = true,
  },
  [sym_document] = {
    .visible = true,
    .named = true,
  },
  [sym_script_element] = {
    .visible = true,
    .named = true,
  },
  [sym__node] = {
    .visible = false,
    .named = true,
  },
  [sym_element] = {
    .visible = true,
    .named = true,
  },
  [sym_self_closing_element] = {
    .visible = true,
    .named = true,
  },
  [sym_start_tag] = {
    .visible = true,
    .named = true,
  },
  [sym_end_tag] = {
    .visible = true,
    .named = true,
  },
  [sym_self_closing_tag] = {
    .visible = true,
    .named = true,
  },
  [sym__attribute_or_shorthand] = {
    .visible = false,
    .named = true,
  },
  [sym_attribute] = {
    .visible = true,
    .named = true,
  },
  [sym__attribute_value] = {
    .visible = false,
    .named = true,
  },
  [sym_quoted_attribute_value] = {
    .visible = true,
    .named = true,
  },
  [sym_attribute_shorthand] = {
    .visible = true,
    .named = true,
  },
  [sym_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_raw_html_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_render_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_expression_content] = {
    .visible = true,
    .named = true,
  },
  [sym_render_content] = {
    .visible = true,
    .named = true,
  },
  [sym_text] = {
    .visible = true,
    .named = true,
  },
  [aux_sym_document_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_start_tag_repeat1] = {
    .visible = false,
    .named = false,
  },
};

static const TSSymbol ts_alias_sequences[PRODUCTION_ID_COUNT][MAX_ALIAS_SEQUENCE_LENGTH] = {
  [0] = {0},
};

static const uint16_t ts_non_terminal_alias_map[] = {
  0,
};

static const TSStateId ts_primary_state_ids[STATE_COUNT] = {
  [0] = 0,
  [1] = 1,
  [2] = 2,
  [3] = 3,
  [4] = 2,
  [5] = 3,
  [6] = 6,
  [7] = 7,
  [8] = 8,
  [9] = 9,
  [10] = 7,
  [11] = 11,
  [12] = 12,
  [13] = 13,
  [14] = 11,
  [15] = 13,
  [16] = 16,
  [17] = 17,
  [18] = 16,
  [19] = 19,
  [20] = 20,
  [21] = 21,
  [22] = 22,
  [23] = 17,
  [24] = 24,
  [25] = 25,
  [26] = 26,
  [27] = 24,
  [28] = 28,
  [29] = 29,
  [30] = 30,
  [31] = 31,
  [32] = 19,
  [33] = 20,
  [34] = 21,
  [35] = 25,
  [36] = 29,
  [37] = 26,
  [38] = 30,
  [39] = 39,
  [40] = 40,
  [41] = 41,
  [42] = 42,
  [43] = 43,
  [44] = 30,
  [45] = 45,
  [46] = 46,
  [47] = 47,
  [48] = 48,
  [49] = 45,
  [50] = 47,
  [51] = 48,
  [52] = 48,
  [53] = 53,
  [54] = 54,
  [55] = 55,
  [56] = 56,
  [57] = 57,
  [58] = 58,
  [59] = 59,
  [60] = 60,
  [61] = 61,
  [62] = 62,
  [63] = 63,
  [64] = 57,
  [65] = 65,
  [66] = 66,
  [67] = 55,
  [68] = 65,
  [69] = 54,
  [70] = 53,
  [71] = 65,
  [72] = 72,
  [73] = 56,
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(39);
      if (lookahead == '"') ADVANCE(50);
      if (lookahead == '/') ADVANCE(7);
      if (lookahead == '<') ADVANCE(43);
      if (lookahead == '=') ADVANCE(48);
      if (lookahead == '>') ADVANCE(44);
      if (lookahead == '{') ADVANCE(53);
      if (lookahead == '}') ADVANCE(54);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(0);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(47);
      END_STATE();
    case 1:
      if (lookahead == ' ') ADVANCE(23);
      END_STATE();
    case 2:
      if (lookahead == '"') ADVANCE(28);
      END_STATE();
    case 3:
      if (lookahead == '"') ADVANCE(8);
      END_STATE();
    case 4:
      if (lookahead == '/') ADVANCE(34);
      END_STATE();
    case 5:
      if (lookahead == '<') ADVANCE(4);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(5);
      END_STATE();
    case 6:
      if (lookahead == '=') ADVANCE(2);
      END_STATE();
    case 7:
      if (lookahead == '>') ADVANCE(46);
      END_STATE();
    case 8:
      if (lookahead == '>') ADVANCE(40);
      END_STATE();
    case 9:
      if (lookahead == '>') ADVANCE(41);
      END_STATE();
    case 10:
      if (lookahead == 'a') ADVANCE(26);
      END_STATE();
    case 11:
      if (lookahead == 'c') ADVANCE(31);
      END_STATE();
    case 12:
      if (lookahead == 'c') ADVANCE(33);
      END_STATE();
    case 13:
      if (lookahead == 'd') ADVANCE(16);
      END_STATE();
    case 14:
      if (lookahead == 'd') ADVANCE(20);
      END_STATE();
    case 15:
      if (lookahead == 'e') ADVANCE(25);
      END_STATE();
    case 16:
      if (lookahead == 'e') ADVANCE(32);
      END_STATE();
    case 17:
      if (lookahead == 'g') ADVANCE(6);
      END_STATE();
    case 18:
      if (lookahead == 'h') ADVANCE(35);
      if (lookahead == 'r') ADVANCE(15);
      END_STATE();
    case 19:
      if (lookahead == 'i') ADVANCE(29);
      END_STATE();
    case 20:
      if (lookahead == 'i') ADVANCE(27);
      END_STATE();
    case 21:
      if (lookahead == 'i') ADVANCE(30);
      END_STATE();
    case 22:
      if (lookahead == 'l') ADVANCE(55);
      END_STATE();
    case 23:
      if (lookahead == 'l') ADVANCE(10);
      END_STATE();
    case 24:
      if (lookahead == 'm') ADVANCE(22);
      END_STATE();
    case 25:
      if (lookahead == 'n') ADVANCE(13);
      END_STATE();
    case 26:
      if (lookahead == 'n') ADVANCE(17);
      END_STATE();
    case 27:
      if (lookahead == 'n') ADVANCE(3);
      END_STATE();
    case 28:
      if (lookahead == 'o') ADVANCE(14);
      END_STATE();
    case 29:
      if (lookahead == 'p') ADVANCE(36);
      END_STATE();
    case 30:
      if (lookahead == 'p') ADVANCE(37);
      END_STATE();
    case 31:
      if (lookahead == 'r') ADVANCE(19);
      END_STATE();
    case 32:
      if (lookahead == 'r') ADVANCE(56);
      END_STATE();
    case 33:
      if (lookahead == 'r') ADVANCE(21);
      END_STATE();
    case 34:
      if (lookahead == 's') ADVANCE(12);
      END_STATE();
    case 35:
      if (lookahead == 't') ADVANCE(24);
      END_STATE();
    case 36:
      if (lookahead == 't') ADVANCE(1);
      END_STATE();
    case 37:
      if (lookahead == 't') ADVANCE(9);
      END_STATE();
    case 38:
      if (eof) ADVANCE(39);
      if (lookahead == '/') ADVANCE(7);
      if (lookahead == '<') ADVANCE(42);
      if (lookahead == '=') ADVANCE(48);
      if (lookahead == '>') ADVANCE(44);
      if (lookahead == '{') ADVANCE(53);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(38);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 39:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 40:
      ACCEPT_TOKEN(sym_script_start_tag);
      END_STATE();
    case 41:
      ACCEPT_TOKEN(sym_script_end_tag);
      END_STATE();
    case 42:
      ACCEPT_TOKEN(anon_sym_LT);
      if (lookahead == '/') ADVANCE(45);
      END_STATE();
    case 43:
      ACCEPT_TOKEN(anon_sym_LT);
      if (lookahead == '/') ADVANCE(45);
      if (lookahead == 's') ADVANCE(11);
      END_STATE();
    case 44:
      ACCEPT_TOKEN(anon_sym_GT);
      END_STATE();
    case 45:
      ACCEPT_TOKEN(anon_sym_LT_SLASH);
      END_STATE();
    case 46:
      ACCEPT_TOKEN(anon_sym_SLASH_GT);
      END_STATE();
    case 47:
      ACCEPT_TOKEN(sym_tag_name);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(47);
      END_STATE();
    case 48:
      ACCEPT_TOKEN(anon_sym_EQ);
      END_STATE();
    case 49:
      ACCEPT_TOKEN(sym_attribute_name);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(49);
      END_STATE();
    case 50:
      ACCEPT_TOKEN(anon_sym_DQUOTE);
      END_STATE();
    case 51:
      ACCEPT_TOKEN(aux_sym_quoted_attribute_value_token1);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(51);
      if (lookahead != 0 &&
          lookahead != '"') ADVANCE(52);
      END_STATE();
    case 52:
      ACCEPT_TOKEN(aux_sym_quoted_attribute_value_token1);
      if (lookahead != 0 &&
          lookahead != '"') ADVANCE(52);
      END_STATE();
    case 53:
      ACCEPT_TOKEN(anon_sym_LBRACE);
      if (lookahead == '@') ADVANCE(18);
      END_STATE();
    case 54:
      ACCEPT_TOKEN(anon_sym_RBRACE);
      END_STATE();
    case 55:
      ACCEPT_TOKEN(anon_sym_LBRACE_AThtml);
      END_STATE();
    case 56:
      ACCEPT_TOKEN(anon_sym_LBRACE_ATrender);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0, .external_lex_state = 1},
  [1] = {.lex_state = 0, .external_lex_state = 2},
  [2] = {.lex_state = 38, .external_lex_state = 2},
  [3] = {.lex_state = 38, .external_lex_state = 2},
  [4] = {.lex_state = 38, .external_lex_state = 2},
  [5] = {.lex_state = 38, .external_lex_state = 2},
  [6] = {.lex_state = 38, .external_lex_state = 2},
  [7] = {.lex_state = 38, .external_lex_state = 2},
  [8] = {.lex_state = 38, .external_lex_state = 2},
  [9] = {.lex_state = 38, .external_lex_state = 2},
  [10] = {.lex_state = 38, .external_lex_state = 2},
  [11] = {.lex_state = 38},
  [12] = {.lex_state = 38},
  [13] = {.lex_state = 38},
  [14] = {.lex_state = 38},
  [15] = {.lex_state = 38},
  [16] = {.lex_state = 38, .external_lex_state = 2},
  [17] = {.lex_state = 38, .external_lex_state = 2},
  [18] = {.lex_state = 38, .external_lex_state = 2},
  [19] = {.lex_state = 38, .external_lex_state = 2},
  [20] = {.lex_state = 38, .external_lex_state = 2},
  [21] = {.lex_state = 38, .external_lex_state = 2},
  [22] = {.lex_state = 38, .external_lex_state = 2},
  [23] = {.lex_state = 38, .external_lex_state = 2},
  [24] = {.lex_state = 38, .external_lex_state = 2},
  [25] = {.lex_state = 38, .external_lex_state = 2},
  [26] = {.lex_state = 38, .external_lex_state = 2},
  [27] = {.lex_state = 38, .external_lex_state = 2},
  [28] = {.lex_state = 38, .external_lex_state = 2},
  [29] = {.lex_state = 38, .external_lex_state = 2},
  [30] = {.lex_state = 38, .external_lex_state = 2},
  [31] = {.lex_state = 38, .external_lex_state = 2},
  [32] = {.lex_state = 38, .external_lex_state = 2},
  [33] = {.lex_state = 38, .external_lex_state = 2},
  [34] = {.lex_state = 38, .external_lex_state = 2},
  [35] = {.lex_state = 38, .external_lex_state = 2},
  [36] = {.lex_state = 38, .external_lex_state = 2},
  [37] = {.lex_state = 38, .external_lex_state = 2},
  [38] = {.lex_state = 38, .external_lex_state = 2},
  [39] = {.lex_state = 0},
  [40] = {.lex_state = 38},
  [41] = {.lex_state = 38},
  [42] = {.lex_state = 38},
  [43] = {.lex_state = 38},
  [44] = {.lex_state = 38},
  [45] = {.lex_state = 0, .external_lex_state = 3},
  [46] = {.lex_state = 0, .external_lex_state = 3},
  [47] = {.lex_state = 0, .external_lex_state = 3},
  [48] = {.lex_state = 0, .external_lex_state = 3},
  [49] = {.lex_state = 0, .external_lex_state = 3},
  [50] = {.lex_state = 0, .external_lex_state = 3},
  [51] = {.lex_state = 0, .external_lex_state = 3},
  [52] = {.lex_state = 0, .external_lex_state = 3},
  [53] = {.lex_state = 0},
  [54] = {.lex_state = 0},
  [55] = {.lex_state = 0},
  [56] = {.lex_state = 0},
  [57] = {.lex_state = 0},
  [58] = {.lex_state = 0},
  [59] = {.lex_state = 0},
  [60] = {.lex_state = 0, .external_lex_state = 4},
  [61] = {.lex_state = 5},
  [62] = {.lex_state = 0},
  [63] = {.lex_state = 51},
  [64] = {.lex_state = 0},
  [65] = {.lex_state = 0},
  [66] = {.lex_state = 0},
  [67] = {.lex_state = 0},
  [68] = {.lex_state = 0},
  [69] = {.lex_state = 0},
  [70] = {.lex_state = 0},
  [71] = {.lex_state = 0},
  [72] = {.lex_state = 0},
  [73] = {.lex_state = 0},
};

static const uint16_t ts_parse_table[LARGE_STATE_COUNT][SYMBOL_COUNT] = {
  [0] = {
    [ts_builtin_sym_end] = ACTIONS(1),
    [sym_script_start_tag] = ACTIONS(1),
    [anon_sym_LT] = ACTIONS(1),
    [anon_sym_GT] = ACTIONS(1),
    [anon_sym_LT_SLASH] = ACTIONS(1),
    [anon_sym_SLASH_GT] = ACTIONS(1),
    [sym_tag_name] = ACTIONS(1),
    [anon_sym_EQ] = ACTIONS(1),
    [anon_sym_DQUOTE] = ACTIONS(1),
    [anon_sym_LBRACE] = ACTIONS(1),
    [anon_sym_RBRACE] = ACTIONS(1),
    [anon_sym_LBRACE_AThtml] = ACTIONS(1),
    [anon_sym_LBRACE_ATrender] = ACTIONS(1),
    [sym__script_content] = ACTIONS(1),
    [sym__expression_content] = ACTIONS(1),
    [sym__raw_text] = ACTIONS(1),
  },
  [1] = {
    [sym_document] = STATE(62),
    [sym_script_element] = STATE(6),
    [sym__node] = STATE(9),
    [sym_element] = STATE(9),
    [sym_self_closing_element] = STATE(9),
    [sym_start_tag] = STATE(2),
    [sym_self_closing_tag] = STATE(37),
    [sym_expression] = STATE(9),
    [sym_raw_html_expression] = STATE(9),
    [sym_render_expression] = STATE(9),
    [sym_text] = STATE(9),
    [aux_sym_document_repeat1] = STATE(9),
    [ts_builtin_sym_end] = ACTIONS(3),
    [sym_script_start_tag] = ACTIONS(5),
    [anon_sym_LT] = ACTIONS(7),
    [anon_sym_LBRACE] = ACTIONS(9),
    [anon_sym_LBRACE_AThtml] = ACTIONS(11),
    [anon_sym_LBRACE_ATrender] = ACTIONS(13),
    [sym__raw_text] = ACTIONS(15),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 10,
    ACTIONS(17), 1,
      anon_sym_LT,
    ACTIONS(19), 1,
      anon_sym_LT_SLASH,
    ACTIONS(21), 1,
      anon_sym_LBRACE,
    ACTIONS(23), 1,
      anon_sym_LBRACE_AThtml,
    ACTIONS(25), 1,
      anon_sym_LBRACE_ATrender,
    ACTIONS(27), 1,
      sym__raw_text,
    STATE(4), 1,
      sym_start_tag,
    STATE(24), 1,
      sym_end_tag,
    STATE(26), 1,
      sym_self_closing_tag,
    STATE(3), 8,
      sym__node,
      sym_element,
      sym_self_closing_element,
      sym_expression,
      sym_raw_html_expression,
      sym_render_expression,
      sym_text,
      aux_sym_document_repeat1,
  [38] = 10,
    ACTIONS(17), 1,
      anon_sym_LT,
    ACTIONS(19), 1,
      anon_sym_LT_SLASH,
    ACTIONS(21), 1,
      anon_sym_LBRACE,
    ACTIONS(23), 1,
      anon_sym_LBRACE_AThtml,
    ACTIONS(25), 1,
      anon_sym_LBRACE_ATrender,
    ACTIONS(27), 1,
      sym__raw_text,
    STATE(4), 1,
      sym_start_tag,
    STATE(20), 1,
      sym_end_tag,
    STATE(26), 1,
      sym_self_closing_tag,
    STATE(7), 8,
      sym__node,
      sym_element,
      sym_self_closing_element,
      sym_expression,
      sym_raw_html_expression,
      sym_render_expression,
      sym_text,
      aux_sym_document_repeat1,
  [76] = 10,
    ACTIONS(17), 1,
      anon_sym_LT,
    ACTIONS(21), 1,
      anon_sym_LBRACE,
    ACTIONS(23), 1,
      anon_sym_LBRACE_AThtml,
    ACTIONS(25), 1,
      anon_sym_LBRACE_ATrender,
    ACTIONS(27), 1,
      sym__raw_text,
    ACTIONS(29), 1,
      anon_sym_LT_SLASH,
    STATE(4), 1,
      sym_start_tag,
    STATE(26), 1,
      sym_self_closing_tag,
    STATE(27), 1,
      sym_end_tag,
    STATE(5), 8,
      sym__node,
      sym_element,
      sym_self_closing_element,
      sym_expression,
      sym_raw_html_expression,
      sym_render_expression,
      sym_text,
      aux_sym_document_repeat1,
  [114] = 10,
    ACTIONS(17), 1,
      anon_sym_LT,
    ACTIONS(21), 1,
      anon_sym_LBRACE,
    ACTIONS(23), 1,
      anon_sym_LBRACE_AThtml,
    ACTIONS(25), 1,
      anon_sym_LBRACE_ATrender,
    ACTIONS(27), 1,
      sym__raw_text,
    ACTIONS(29), 1,
      anon_sym_LT_SLASH,
    STATE(4), 1,
      sym_start_tag,
    STATE(26), 1,
      sym_self_closing_tag,
    STATE(33), 1,
      sym_end_tag,
    STATE(7), 8,
      sym__node,
      sym_element,
      sym_self_closing_element,
      sym_expression,
      sym_raw_html_expression,
      sym_render_expression,
      sym_text,
      aux_sym_document_repeat1,
  [152] = 9,
    ACTIONS(9), 1,
      anon_sym_LBRACE,
    ACTIONS(11), 1,
      anon_sym_LBRACE_AThtml,
    ACTIONS(13), 1,
      anon_sym_LBRACE_ATrender,
    ACTIONS(15), 1,
      sym__raw_text,
    ACTIONS(31), 1,
      ts_builtin_sym_end,
    ACTIONS(33), 1,
      anon_sym_LT,
    STATE(2), 1,
      sym_start_tag,
    STATE(37), 1,
      sym_self_closing_tag,
    STATE(8), 8,
      sym__node,
      sym_element,
      sym_self_closing_element,
      sym_expression,
      sym_raw_html_expression,
      sym_render_expression,
      sym_text,
      aux_sym_document_repeat1,
  [187] = 9,
    ACTIONS(35), 1,
      anon_sym_LT,
    ACTIONS(38), 1,
      anon_sym_LT_SLASH,
    ACTIONS(40), 1,
      anon_sym_LBRACE,
    ACTIONS(43), 1,
      anon_sym_LBRACE_AThtml,
    ACTIONS(46), 1,
      anon_sym_LBRACE_ATrender,
    ACTIONS(49), 1,
      sym__raw_text,
    STATE(4), 1,
      sym_start_tag,
    STATE(26), 1,
      sym_self_closing_tag,
    STATE(7), 8,
      sym__node,
      sym_element,
      sym_self_closing_element,
      sym_expression,
      sym_raw_html_expression,
      sym_render_expression,
      sym_text,
      aux_sym_document_repeat1,
  [222] = 9,
    ACTIONS(9), 1,
      anon_sym_LBRACE,
    ACTIONS(11), 1,
      anon_sym_LBRACE_AThtml,
    ACTIONS(13), 1,
      anon_sym_LBRACE_ATrender,
    ACTIONS(15), 1,
      sym__raw_text,
    ACTIONS(33), 1,
      anon_sym_LT,
    ACTIONS(52), 1,
      ts_builtin_sym_end,
    STATE(2), 1,
      sym_start_tag,
    STATE(37), 1,
      sym_self_closing_tag,
    STATE(10), 8,
      sym__node,
      sym_element,
      sym_self_closing_element,
      sym_expression,
      sym_raw_html_expression,
      sym_render_expression,
      sym_text,
      aux_sym_document_repeat1,
  [257] = 9,
    ACTIONS(9), 1,
      anon_sym_LBRACE,
    ACTIONS(11), 1,
      anon_sym_LBRACE_AThtml,
    ACTIONS(13), 1,
      anon_sym_LBRACE_ATrender,
    ACTIONS(15), 1,
      sym__raw_text,
    ACTIONS(31), 1,
      ts_builtin_sym_end,
    ACTIONS(33), 1,
      anon_sym_LT,
    STATE(2), 1,
      sym_start_tag,
    STATE(37), 1,
      sym_self_closing_tag,
    STATE(10), 8,
      sym__node,
      sym_element,
      sym_self_closing_element,
      sym_expression,
      sym_raw_html_expression,
      sym_render_expression,
      sym_text,
      aux_sym_document_repeat1,
  [292] = 9,
    ACTIONS(38), 1,
      ts_builtin_sym_end,
    ACTIONS(54), 1,
      anon_sym_LT,
    ACTIONS(57), 1,
      anon_sym_LBRACE,
    ACTIONS(60), 1,
      anon_sym_LBRACE_AThtml,
    ACTIONS(63), 1,
      anon_sym_LBRACE_ATrender,
    ACTIONS(66), 1,
      sym__raw_text,
    STATE(2), 1,
      sym_start_tag,
    STATE(37), 1,
      sym_self_closing_tag,
    STATE(10), 8,
      sym__node,
      sym_element,
      sym_self_closing_element,
      sym_expression,
      sym_raw_html_expression,
      sym_render_expression,
      sym_text,
      aux_sym_document_repeat1,
  [327] = 5,
    ACTIONS(69), 1,
      anon_sym_GT,
    ACTIONS(71), 1,
      anon_sym_SLASH_GT,
    ACTIONS(73), 1,
      sym_attribute_name,
    ACTIONS(75), 1,
      anon_sym_LBRACE,
    STATE(12), 4,
      sym__attribute_or_shorthand,
      sym_attribute,
      sym_attribute_shorthand,
      aux_sym_start_tag_repeat1,
  [346] = 4,
    ACTIONS(79), 1,
      sym_attribute_name,
    ACTIONS(82), 1,
      anon_sym_LBRACE,
    ACTIONS(77), 2,
      anon_sym_GT,
      anon_sym_SLASH_GT,
    STATE(12), 4,
      sym__attribute_or_shorthand,
      sym_attribute,
      sym_attribute_shorthand,
      aux_sym_start_tag_repeat1,
  [363] = 5,
    ACTIONS(73), 1,
      sym_attribute_name,
    ACTIONS(75), 1,
      anon_sym_LBRACE,
    ACTIONS(85), 1,
      anon_sym_GT,
    ACTIONS(87), 1,
      anon_sym_SLASH_GT,
    STATE(11), 4,
      sym__attribute_or_shorthand,
      sym_attribute,
      sym_attribute_shorthand,
      aux_sym_start_tag_repeat1,
  [382] = 5,
    ACTIONS(69), 1,
      anon_sym_GT,
    ACTIONS(73), 1,
      sym_attribute_name,
    ACTIONS(75), 1,
      anon_sym_LBRACE,
    ACTIONS(89), 1,
      anon_sym_SLASH_GT,
    STATE(12), 4,
      sym__attribute_or_shorthand,
      sym_attribute,
      sym_attribute_shorthand,
      aux_sym_start_tag_repeat1,
  [401] = 5,
    ACTIONS(73), 1,
      sym_attribute_name,
    ACTIONS(75), 1,
      anon_sym_LBRACE,
    ACTIONS(85), 1,
      anon_sym_GT,
    ACTIONS(91), 1,
      anon_sym_SLASH_GT,
    STATE(14), 4,
      sym__attribute_or_shorthand,
      sym_attribute,
      sym_attribute_shorthand,
      aux_sym_start_tag_repeat1,
  [420] = 2,
    ACTIONS(93), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(95), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [431] = 2,
    ACTIONS(99), 1,
      anon_sym_LBRACE,
    ACTIONS(97), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [442] = 2,
    ACTIONS(93), 1,
      anon_sym_LBRACE,
    ACTIONS(95), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [453] = 2,
    ACTIONS(103), 1,
      anon_sym_LBRACE,
    ACTIONS(101), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [464] = 2,
    ACTIONS(107), 1,
      anon_sym_LBRACE,
    ACTIONS(105), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [475] = 2,
    ACTIONS(111), 1,
      anon_sym_LBRACE,
    ACTIONS(109), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [486] = 2,
    ACTIONS(113), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(115), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [497] = 2,
    ACTIONS(99), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(97), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [508] = 2,
    ACTIONS(119), 1,
      anon_sym_LBRACE,
    ACTIONS(117), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [519] = 2,
    ACTIONS(123), 1,
      anon_sym_LBRACE,
    ACTIONS(121), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [530] = 2,
    ACTIONS(125), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(127), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [541] = 2,
    ACTIONS(119), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(117), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [552] = 2,
    ACTIONS(131), 1,
      anon_sym_LBRACE,
    ACTIONS(129), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [563] = 2,
    ACTIONS(133), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(135), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [574] = 2,
    ACTIONS(137), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(139), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [585] = 2,
    ACTIONS(141), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(143), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [596] = 2,
    ACTIONS(103), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(101), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [607] = 2,
    ACTIONS(107), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(105), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [618] = 2,
    ACTIONS(111), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(109), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [629] = 2,
    ACTIONS(123), 2,
      anon_sym_LT,
      anon_sym_LBRACE,
    ACTIONS(121), 4,
      sym__raw_text,
      anon_sym_LT_SLASH,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [640] = 2,
    ACTIONS(133), 1,
      anon_sym_LBRACE,
    ACTIONS(135), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [651] = 2,
    ACTIONS(125), 1,
      anon_sym_LBRACE,
    ACTIONS(127), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [662] = 2,
    ACTIONS(137), 1,
      anon_sym_LBRACE,
    ACTIONS(139), 5,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
      anon_sym_LBRACE_AThtml,
      anon_sym_LBRACE_ATrender,
  [673] = 3,
    ACTIONS(145), 1,
      anon_sym_DQUOTE,
    ACTIONS(147), 1,
      anon_sym_LBRACE,
    STATE(41), 3,
      sym__attribute_value,
      sym_quoted_attribute_value,
      sym_expression,
  [685] = 2,
    ACTIONS(151), 1,
      anon_sym_EQ,
    ACTIONS(149), 4,
      anon_sym_GT,
      anon_sym_SLASH_GT,
      sym_attribute_name,
      anon_sym_LBRACE,
  [695] = 1,
    ACTIONS(153), 4,
      anon_sym_GT,
      anon_sym_SLASH_GT,
      sym_attribute_name,
      anon_sym_LBRACE,
  [702] = 1,
    ACTIONS(155), 4,
      anon_sym_GT,
      anon_sym_SLASH_GT,
      sym_attribute_name,
      anon_sym_LBRACE,
  [709] = 1,
    ACTIONS(157), 4,
      anon_sym_GT,
      anon_sym_SLASH_GT,
      sym_attribute_name,
      anon_sym_LBRACE,
  [716] = 1,
    ACTIONS(139), 4,
      anon_sym_GT,
      anon_sym_SLASH_GT,
      sym_attribute_name,
      anon_sym_LBRACE,
  [723] = 2,
    ACTIONS(159), 1,
      sym__expression_content,
    STATE(57), 1,
      sym_render_content,
  [730] = 2,
    ACTIONS(161), 1,
      sym__expression_content,
    STATE(58), 1,
      sym_expression_content,
  [737] = 2,
    ACTIONS(161), 1,
      sym__expression_content,
    STATE(53), 1,
      sym_expression_content,
  [744] = 2,
    ACTIONS(161), 1,
      sym__expression_content,
    STATE(65), 1,
      sym_expression_content,
  [751] = 2,
    ACTIONS(159), 1,
      sym__expression_content,
    STATE(64), 1,
      sym_render_content,
  [758] = 2,
    ACTIONS(161), 1,
      sym__expression_content,
    STATE(70), 1,
      sym_expression_content,
  [765] = 2,
    ACTIONS(161), 1,
      sym__expression_content,
    STATE(71), 1,
      sym_expression_content,
  [772] = 2,
    ACTIONS(161), 1,
      sym__expression_content,
    STATE(68), 1,
      sym_expression_content,
  [779] = 1,
    ACTIONS(163), 1,
      anon_sym_RBRACE,
  [783] = 1,
    ACTIONS(165), 1,
      sym_tag_name,
  [787] = 1,
    ACTIONS(167), 1,
      anon_sym_GT,
  [791] = 1,
    ACTIONS(169), 1,
      sym_tag_name,
  [795] = 1,
    ACTIONS(171), 1,
      anon_sym_RBRACE,
  [799] = 1,
    ACTIONS(173), 1,
      anon_sym_RBRACE,
  [803] = 1,
    ACTIONS(175), 1,
      anon_sym_RBRACE,
  [807] = 1,
    ACTIONS(177), 1,
      sym__script_content,
  [811] = 1,
    ACTIONS(179), 1,
      sym_script_end_tag,
  [815] = 1,
    ACTIONS(181), 1,
      ts_builtin_sym_end,
  [819] = 1,
    ACTIONS(183), 1,
      aux_sym_quoted_attribute_value_token1,
  [823] = 1,
    ACTIONS(185), 1,
      anon_sym_RBRACE,
  [827] = 1,
    ACTIONS(187), 1,
      anon_sym_RBRACE,
  [831] = 1,
    ACTIONS(189), 1,
      anon_sym_RBRACE,
  [835] = 1,
    ACTIONS(191), 1,
      anon_sym_GT,
  [839] = 1,
    ACTIONS(193), 1,
      anon_sym_RBRACE,
  [843] = 1,
    ACTIONS(195), 1,
      sym_tag_name,
  [847] = 1,
    ACTIONS(197), 1,
      anon_sym_RBRACE,
  [851] = 1,
    ACTIONS(199), 1,
      anon_sym_RBRACE,
  [855] = 1,
    ACTIONS(201), 1,
      anon_sym_DQUOTE,
  [859] = 1,
    ACTIONS(203), 1,
      sym_tag_name,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(2)] = 0,
  [SMALL_STATE(3)] = 38,
  [SMALL_STATE(4)] = 76,
  [SMALL_STATE(5)] = 114,
  [SMALL_STATE(6)] = 152,
  [SMALL_STATE(7)] = 187,
  [SMALL_STATE(8)] = 222,
  [SMALL_STATE(9)] = 257,
  [SMALL_STATE(10)] = 292,
  [SMALL_STATE(11)] = 327,
  [SMALL_STATE(12)] = 346,
  [SMALL_STATE(13)] = 363,
  [SMALL_STATE(14)] = 382,
  [SMALL_STATE(15)] = 401,
  [SMALL_STATE(16)] = 420,
  [SMALL_STATE(17)] = 431,
  [SMALL_STATE(18)] = 442,
  [SMALL_STATE(19)] = 453,
  [SMALL_STATE(20)] = 464,
  [SMALL_STATE(21)] = 475,
  [SMALL_STATE(22)] = 486,
  [SMALL_STATE(23)] = 497,
  [SMALL_STATE(24)] = 508,
  [SMALL_STATE(25)] = 519,
  [SMALL_STATE(26)] = 530,
  [SMALL_STATE(27)] = 541,
  [SMALL_STATE(28)] = 552,
  [SMALL_STATE(29)] = 563,
  [SMALL_STATE(30)] = 574,
  [SMALL_STATE(31)] = 585,
  [SMALL_STATE(32)] = 596,
  [SMALL_STATE(33)] = 607,
  [SMALL_STATE(34)] = 618,
  [SMALL_STATE(35)] = 629,
  [SMALL_STATE(36)] = 640,
  [SMALL_STATE(37)] = 651,
  [SMALL_STATE(38)] = 662,
  [SMALL_STATE(39)] = 673,
  [SMALL_STATE(40)] = 685,
  [SMALL_STATE(41)] = 695,
  [SMALL_STATE(42)] = 702,
  [SMALL_STATE(43)] = 709,
  [SMALL_STATE(44)] = 716,
  [SMALL_STATE(45)] = 723,
  [SMALL_STATE(46)] = 730,
  [SMALL_STATE(47)] = 737,
  [SMALL_STATE(48)] = 744,
  [SMALL_STATE(49)] = 751,
  [SMALL_STATE(50)] = 758,
  [SMALL_STATE(51)] = 765,
  [SMALL_STATE(52)] = 772,
  [SMALL_STATE(53)] = 779,
  [SMALL_STATE(54)] = 783,
  [SMALL_STATE(55)] = 787,
  [SMALL_STATE(56)] = 791,
  [SMALL_STATE(57)] = 795,
  [SMALL_STATE(58)] = 799,
  [SMALL_STATE(59)] = 803,
  [SMALL_STATE(60)] = 807,
  [SMALL_STATE(61)] = 811,
  [SMALL_STATE(62)] = 815,
  [SMALL_STATE(63)] = 819,
  [SMALL_STATE(64)] = 823,
  [SMALL_STATE(65)] = 827,
  [SMALL_STATE(66)] = 831,
  [SMALL_STATE(67)] = 835,
  [SMALL_STATE(68)] = 839,
  [SMALL_STATE(69)] = 843,
  [SMALL_STATE(70)] = 847,
  [SMALL_STATE(71)] = 851,
  [SMALL_STATE(72)] = 855,
  [SMALL_STATE(73)] = 859,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_document, 0, 0, 0),
  [5] = {.entry = {.count = 1, .reusable = true}}, SHIFT(60),
  [7] = {.entry = {.count = 1, .reusable = false}}, SHIFT(54),
  [9] = {.entry = {.count = 1, .reusable = false}}, SHIFT(48),
  [11] = {.entry = {.count = 1, .reusable = true}}, SHIFT(47),
  [13] = {.entry = {.count = 1, .reusable = true}}, SHIFT(45),
  [15] = {.entry = {.count = 1, .reusable = true}}, SHIFT(17),
  [17] = {.entry = {.count = 1, .reusable = false}}, SHIFT(69),
  [19] = {.entry = {.count = 1, .reusable = true}}, SHIFT(56),
  [21] = {.entry = {.count = 1, .reusable = false}}, SHIFT(51),
  [23] = {.entry = {.count = 1, .reusable = true}}, SHIFT(50),
  [25] = {.entry = {.count = 1, .reusable = true}}, SHIFT(49),
  [27] = {.entry = {.count = 1, .reusable = true}}, SHIFT(23),
  [29] = {.entry = {.count = 1, .reusable = true}}, SHIFT(73),
  [31] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_document, 1, 0, 0),
  [33] = {.entry = {.count = 1, .reusable = true}}, SHIFT(54),
  [35] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(69),
  [38] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0),
  [40] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(51),
  [43] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(50),
  [46] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(49),
  [49] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(23),
  [52] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_document, 2, 0, 0),
  [54] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(54),
  [57] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(48),
  [60] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(47),
  [63] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(45),
  [66] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(17),
  [69] = {.entry = {.count = 1, .reusable = true}}, SHIFT(22),
  [71] = {.entry = {.count = 1, .reusable = true}}, SHIFT(21),
  [73] = {.entry = {.count = 1, .reusable = true}}, SHIFT(40),
  [75] = {.entry = {.count = 1, .reusable = true}}, SHIFT(46),
  [77] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_start_tag_repeat1, 2, 0, 0),
  [79] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_start_tag_repeat1, 2, 0, 0), SHIFT_REPEAT(40),
  [82] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_start_tag_repeat1, 2, 0, 0), SHIFT_REPEAT(46),
  [85] = {.entry = {.count = 1, .reusable = true}}, SHIFT(31),
  [87] = {.entry = {.count = 1, .reusable = true}}, SHIFT(36),
  [89] = {.entry = {.count = 1, .reusable = true}}, SHIFT(34),
  [91] = {.entry = {.count = 1, .reusable = true}}, SHIFT(29),
  [93] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_raw_html_expression, 3, 0, 0),
  [95] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_raw_html_expression, 3, 0, 0),
  [97] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_text, 1, 0, 0),
  [99] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_text, 1, 0, 0),
  [101] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_render_expression, 3, 0, 0),
  [103] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_render_expression, 3, 0, 0),
  [105] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_element, 3, 0, 0),
  [107] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_element, 3, 0, 0),
  [109] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_self_closing_tag, 4, 0, 0),
  [111] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_self_closing_tag, 4, 0, 0),
  [113] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_start_tag, 4, 0, 0),
  [115] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_start_tag, 4, 0, 0),
  [117] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_element, 2, 0, 0),
  [119] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_element, 2, 0, 0),
  [121] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_end_tag, 3, 0, 0),
  [123] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_end_tag, 3, 0, 0),
  [125] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_self_closing_element, 1, 0, 0),
  [127] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_self_closing_element, 1, 0, 0),
  [129] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_script_element, 3, 0, 0),
  [131] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_script_element, 3, 0, 0),
  [133] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_self_closing_tag, 3, 0, 0),
  [135] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_self_closing_tag, 3, 0, 0),
  [137] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_expression, 3, 0, 0),
  [139] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expression, 3, 0, 0),
  [141] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_start_tag, 3, 0, 0),
  [143] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_start_tag, 3, 0, 0),
  [145] = {.entry = {.count = 1, .reusable = true}}, SHIFT(63),
  [147] = {.entry = {.count = 1, .reusable = true}}, SHIFT(52),
  [149] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_attribute, 1, 0, 0),
  [151] = {.entry = {.count = 1, .reusable = true}}, SHIFT(39),
  [153] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_attribute, 3, 0, 0),
  [155] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_attribute_shorthand, 3, 0, 0),
  [157] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_quoted_attribute_value, 3, 0, 0),
  [159] = {.entry = {.count = 1, .reusable = true}}, SHIFT(59),
  [161] = {.entry = {.count = 1, .reusable = true}}, SHIFT(66),
  [163] = {.entry = {.count = 1, .reusable = true}}, SHIFT(18),
  [165] = {.entry = {.count = 1, .reusable = true}}, SHIFT(13),
  [167] = {.entry = {.count = 1, .reusable = true}}, SHIFT(25),
  [169] = {.entry = {.count = 1, .reusable = true}}, SHIFT(55),
  [171] = {.entry = {.count = 1, .reusable = true}}, SHIFT(19),
  [173] = {.entry = {.count = 1, .reusable = true}}, SHIFT(42),
  [175] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_render_content, 1, 0, 0),
  [177] = {.entry = {.count = 1, .reusable = true}}, SHIFT(61),
  [179] = {.entry = {.count = 1, .reusable = true}}, SHIFT(28),
  [181] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
  [183] = {.entry = {.count = 1, .reusable = true}}, SHIFT(72),
  [185] = {.entry = {.count = 1, .reusable = true}}, SHIFT(32),
  [187] = {.entry = {.count = 1, .reusable = true}}, SHIFT(38),
  [189] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expression_content, 1, 0, 0),
  [191] = {.entry = {.count = 1, .reusable = true}}, SHIFT(35),
  [193] = {.entry = {.count = 1, .reusable = true}}, SHIFT(44),
  [195] = {.entry = {.count = 1, .reusable = true}}, SHIFT(15),
  [197] = {.entry = {.count = 1, .reusable = true}}, SHIFT(16),
  [199] = {.entry = {.count = 1, .reusable = true}}, SHIFT(30),
  [201] = {.entry = {.count = 1, .reusable = true}}, SHIFT(43),
  [203] = {.entry = {.count = 1, .reusable = true}}, SHIFT(67),
};

enum ts_external_scanner_symbol_identifiers {
  ts_external_token__script_content = 0,
  ts_external_token__expression_content = 1,
  ts_external_token__raw_text = 2,
};

static const TSSymbol ts_external_scanner_symbol_map[EXTERNAL_TOKEN_COUNT] = {
  [ts_external_token__script_content] = sym__script_content,
  [ts_external_token__expression_content] = sym__expression_content,
  [ts_external_token__raw_text] = sym__raw_text,
};

static const bool ts_external_scanner_states[5][EXTERNAL_TOKEN_COUNT] = {
  [1] = {
    [ts_external_token__script_content] = true,
    [ts_external_token__expression_content] = true,
    [ts_external_token__raw_text] = true,
  },
  [2] = {
    [ts_external_token__raw_text] = true,
  },
  [3] = {
    [ts_external_token__expression_content] = true,
  },
  [4] = {
    [ts_external_token__script_content] = true,
  },
};

#ifdef __cplusplus
extern "C" {
#endif
void *tree_sitter_ohtml_external_scanner_create(void);
void tree_sitter_ohtml_external_scanner_destroy(void *);
bool tree_sitter_ohtml_external_scanner_scan(void *, TSLexer *, const bool *);
unsigned tree_sitter_ohtml_external_scanner_serialize(void *, char *);
void tree_sitter_ohtml_external_scanner_deserialize(void *, const char *, unsigned);

#ifdef TREE_SITTER_HIDE_SYMBOLS
#define TS_PUBLIC
#elif defined(_WIN32)
#define TS_PUBLIC __declspec(dllexport)
#else
#define TS_PUBLIC __attribute__((visibility("default")))
#endif

TS_PUBLIC const TSLanguage *tree_sitter_ohtml(void) {
  static const TSLanguage language = {
    .version = LANGUAGE_VERSION,
    .symbol_count = SYMBOL_COUNT,
    .alias_count = ALIAS_COUNT,
    .token_count = TOKEN_COUNT,
    .external_token_count = EXTERNAL_TOKEN_COUNT,
    .state_count = STATE_COUNT,
    .large_state_count = LARGE_STATE_COUNT,
    .production_id_count = PRODUCTION_ID_COUNT,
    .field_count = FIELD_COUNT,
    .max_alias_sequence_length = MAX_ALIAS_SEQUENCE_LENGTH,
    .parse_table = &ts_parse_table[0][0],
    .small_parse_table = ts_small_parse_table,
    .small_parse_table_map = ts_small_parse_table_map,
    .parse_actions = ts_parse_actions,
    .symbol_names = ts_symbol_names,
    .symbol_metadata = ts_symbol_metadata,
    .public_symbol_map = ts_symbol_map,
    .alias_map = ts_non_terminal_alias_map,
    .alias_sequences = &ts_alias_sequences[0][0],
    .lex_modes = ts_lex_modes,
    .lex_fn = ts_lex,
    .external_scanner = {
      &ts_external_scanner_states[0][0],
      ts_external_scanner_symbol_map,
      tree_sitter_ohtml_external_scanner_create,
      tree_sitter_ohtml_external_scanner_destroy,
      tree_sitter_ohtml_external_scanner_scan,
      tree_sitter_ohtml_external_scanner_serialize,
      tree_sitter_ohtml_external_scanner_deserialize,
    },
    .primary_state_ids = ts_primary_state_ids,
  };
  return &language;
}
#ifdef __cplusplus
}
#endif
