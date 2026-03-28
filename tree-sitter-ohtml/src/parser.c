#include "tree_sitter/parser.h"

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 50
#define LARGE_STATE_COUNT 2
#define SYMBOL_COUNT 29
#define ALIAS_COUNT 0
#define TOKEN_COUNT 15
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
  sym__script_content = 12,
  sym__expression_content = 13,
  sym__raw_text = 14,
  sym_document = 15,
  sym_script_element = 16,
  sym__node = 17,
  sym_element = 18,
  sym_self_closing_element = 19,
  sym_start_tag = 20,
  sym_end_tag = 21,
  sym_self_closing_tag = 22,
  sym_attribute = 23,
  sym__attribute_value = 24,
  sym_quoted_attribute_value = 25,
  sym_text = 26,
  aux_sym_document_repeat1 = 27,
  aux_sym_start_tag_repeat1 = 28,
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
  [sym_attribute] = "attribute",
  [sym__attribute_value] = "_attribute_value",
  [sym_quoted_attribute_value] = "quoted_attribute_value",
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
  [sym_attribute] = sym_attribute,
  [sym__attribute_value] = sym__attribute_value,
  [sym_quoted_attribute_value] = sym_quoted_attribute_value,
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
  [9] = 6,
  [10] = 10,
  [11] = 11,
  [12] = 12,
  [13] = 13,
  [14] = 12,
  [15] = 11,
  [16] = 16,
  [17] = 17,
  [18] = 18,
  [19] = 19,
  [20] = 20,
  [21] = 21,
  [22] = 22,
  [23] = 17,
  [24] = 24,
  [25] = 25,
  [26] = 26,
  [27] = 27,
  [28] = 28,
  [29] = 29,
  [30] = 30,
  [31] = 21,
  [32] = 32,
  [33] = 30,
  [34] = 20,
  [35] = 22,
  [36] = 24,
  [37] = 29,
  [38] = 32,
  [39] = 39,
  [40] = 40,
  [41] = 41,
  [42] = 42,
  [43] = 43,
  [44] = 44,
  [45] = 45,
  [46] = 46,
  [47] = 41,
  [48] = 39,
  [49] = 44,
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(30);
      if (lookahead == '"') ADVANCE(41);
      if (lookahead == '/') ADVANCE(7);
      if (lookahead == '<') ADVANCE(34);
      if (lookahead == '=') ADVANCE(39);
      if (lookahead == '>') ADVANCE(35);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(0);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(38);
      END_STATE();
    case 1:
      if (lookahead == ' ') ADVANCE(18);
      END_STATE();
    case 2:
      if (lookahead == '"') ADVANCE(21);
      END_STATE();
    case 3:
      if (lookahead == '"') ADVANCE(8);
      END_STATE();
    case 4:
      if (lookahead == '/') ADVANCE(26);
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
      if (lookahead == '>') ADVANCE(37);
      END_STATE();
    case 8:
      if (lookahead == '>') ADVANCE(31);
      END_STATE();
    case 9:
      if (lookahead == '>') ADVANCE(32);
      END_STATE();
    case 10:
      if (lookahead == 'a') ADVANCE(19);
      END_STATE();
    case 11:
      if (lookahead == 'c') ADVANCE(24);
      END_STATE();
    case 12:
      if (lookahead == 'c') ADVANCE(25);
      END_STATE();
    case 13:
      if (lookahead == 'd') ADVANCE(16);
      END_STATE();
    case 14:
      if (lookahead == 'g') ADVANCE(6);
      END_STATE();
    case 15:
      if (lookahead == 'i') ADVANCE(22);
      END_STATE();
    case 16:
      if (lookahead == 'i') ADVANCE(20);
      END_STATE();
    case 17:
      if (lookahead == 'i') ADVANCE(23);
      END_STATE();
    case 18:
      if (lookahead == 'l') ADVANCE(10);
      END_STATE();
    case 19:
      if (lookahead == 'n') ADVANCE(14);
      END_STATE();
    case 20:
      if (lookahead == 'n') ADVANCE(3);
      END_STATE();
    case 21:
      if (lookahead == 'o') ADVANCE(13);
      END_STATE();
    case 22:
      if (lookahead == 'p') ADVANCE(27);
      END_STATE();
    case 23:
      if (lookahead == 'p') ADVANCE(28);
      END_STATE();
    case 24:
      if (lookahead == 'r') ADVANCE(15);
      END_STATE();
    case 25:
      if (lookahead == 'r') ADVANCE(17);
      END_STATE();
    case 26:
      if (lookahead == 's') ADVANCE(12);
      END_STATE();
    case 27:
      if (lookahead == 't') ADVANCE(1);
      END_STATE();
    case 28:
      if (lookahead == 't') ADVANCE(9);
      END_STATE();
    case 29:
      if (eof) ADVANCE(30);
      if (lookahead == '/') ADVANCE(7);
      if (lookahead == '<') ADVANCE(33);
      if (lookahead == '=') ADVANCE(39);
      if (lookahead == '>') ADVANCE(35);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(29);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(40);
      END_STATE();
    case 30:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 31:
      ACCEPT_TOKEN(sym_script_start_tag);
      END_STATE();
    case 32:
      ACCEPT_TOKEN(sym_script_end_tag);
      END_STATE();
    case 33:
      ACCEPT_TOKEN(anon_sym_LT);
      if (lookahead == '/') ADVANCE(36);
      END_STATE();
    case 34:
      ACCEPT_TOKEN(anon_sym_LT);
      if (lookahead == '/') ADVANCE(36);
      if (lookahead == 's') ADVANCE(11);
      END_STATE();
    case 35:
      ACCEPT_TOKEN(anon_sym_GT);
      END_STATE();
    case 36:
      ACCEPT_TOKEN(anon_sym_LT_SLASH);
      END_STATE();
    case 37:
      ACCEPT_TOKEN(anon_sym_SLASH_GT);
      END_STATE();
    case 38:
      ACCEPT_TOKEN(sym_tag_name);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(38);
      END_STATE();
    case 39:
      ACCEPT_TOKEN(anon_sym_EQ);
      END_STATE();
    case 40:
      ACCEPT_TOKEN(sym_attribute_name);
      if (lookahead == '-' ||
          ('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(40);
      END_STATE();
    case 41:
      ACCEPT_TOKEN(anon_sym_DQUOTE);
      END_STATE();
    case 42:
      ACCEPT_TOKEN(aux_sym_quoted_attribute_value_token1);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(42);
      if (lookahead != 0 &&
          lookahead != '"') ADVANCE(43);
      END_STATE();
    case 43:
      ACCEPT_TOKEN(aux_sym_quoted_attribute_value_token1);
      if (lookahead != 0 &&
          lookahead != '"') ADVANCE(43);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0, .external_lex_state = 1},
  [1] = {.lex_state = 0, .external_lex_state = 2},
  [2] = {.lex_state = 29, .external_lex_state = 2},
  [3] = {.lex_state = 29, .external_lex_state = 2},
  [4] = {.lex_state = 29, .external_lex_state = 2},
  [5] = {.lex_state = 29, .external_lex_state = 2},
  [6] = {.lex_state = 29, .external_lex_state = 2},
  [7] = {.lex_state = 29, .external_lex_state = 2},
  [8] = {.lex_state = 29, .external_lex_state = 2},
  [9] = {.lex_state = 29, .external_lex_state = 2},
  [10] = {.lex_state = 29, .external_lex_state = 2},
  [11] = {.lex_state = 29},
  [12] = {.lex_state = 29},
  [13] = {.lex_state = 29},
  [14] = {.lex_state = 29},
  [15] = {.lex_state = 29},
  [16] = {.lex_state = 29},
  [17] = {.lex_state = 29, .external_lex_state = 2},
  [18] = {.lex_state = 29, .external_lex_state = 2},
  [19] = {.lex_state = 29, .external_lex_state = 2},
  [20] = {.lex_state = 29, .external_lex_state = 2},
  [21] = {.lex_state = 29, .external_lex_state = 2},
  [22] = {.lex_state = 29, .external_lex_state = 2},
  [23] = {.lex_state = 29, .external_lex_state = 2},
  [24] = {.lex_state = 29, .external_lex_state = 2},
  [25] = {.lex_state = 0},
  [26] = {.lex_state = 29, .external_lex_state = 2},
  [27] = {.lex_state = 29},
  [28] = {.lex_state = 29},
  [29] = {.lex_state = 29, .external_lex_state = 2},
  [30] = {.lex_state = 29, .external_lex_state = 2},
  [31] = {.lex_state = 29, .external_lex_state = 2},
  [32] = {.lex_state = 29, .external_lex_state = 2},
  [33] = {.lex_state = 29, .external_lex_state = 2},
  [34] = {.lex_state = 29, .external_lex_state = 2},
  [35] = {.lex_state = 29, .external_lex_state = 2},
  [36] = {.lex_state = 29, .external_lex_state = 2},
  [37] = {.lex_state = 29, .external_lex_state = 2},
  [38] = {.lex_state = 29, .external_lex_state = 2},
  [39] = {.lex_state = 0},
  [40] = {.lex_state = 5},
  [41] = {.lex_state = 0},
  [42] = {.lex_state = 42},
  [43] = {.lex_state = 0},
  [44] = {.lex_state = 0},
  [45] = {.lex_state = 0},
  [46] = {.lex_state = 0, .external_lex_state = 3},
  [47] = {.lex_state = 0},
  [48] = {.lex_state = 0},
  [49] = {.lex_state = 0},
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
    [sym__script_content] = ACTIONS(1),
    [sym__expression_content] = ACTIONS(1),
    [sym__raw_text] = ACTIONS(1),
  },
  [1] = {
    [sym_document] = STATE(45),
    [sym_script_element] = STATE(8),
    [sym__node] = STATE(10),
    [sym_element] = STATE(10),
    [sym_self_closing_element] = STATE(33),
    [sym_start_tag] = STATE(2),
    [sym_self_closing_tag] = STATE(21),
    [sym_text] = STATE(10),
    [aux_sym_document_repeat1] = STATE(10),
    [ts_builtin_sym_end] = ACTIONS(3),
    [sym_script_start_tag] = ACTIONS(5),
    [anon_sym_LT] = ACTIONS(7),
    [sym__raw_text] = ACTIONS(9),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 8,
    ACTIONS(11), 1,
      anon_sym_LT,
    ACTIONS(13), 1,
      anon_sym_LT_SLASH,
    ACTIONS(15), 1,
      sym__raw_text,
    STATE(4), 1,
      sym_start_tag,
    STATE(30), 1,
      sym_self_closing_element,
    STATE(31), 1,
      sym_self_closing_tag,
    STATE(38), 1,
      sym_end_tag,
    STATE(3), 4,
      sym__node,
      sym_element,
      sym_text,
      aux_sym_document_repeat1,
  [28] = 8,
    ACTIONS(11), 1,
      anon_sym_LT,
    ACTIONS(13), 1,
      anon_sym_LT_SLASH,
    ACTIONS(15), 1,
      sym__raw_text,
    STATE(4), 1,
      sym_start_tag,
    STATE(22), 1,
      sym_end_tag,
    STATE(30), 1,
      sym_self_closing_element,
    STATE(31), 1,
      sym_self_closing_tag,
    STATE(6), 4,
      sym__node,
      sym_element,
      sym_text,
      aux_sym_document_repeat1,
  [56] = 8,
    ACTIONS(11), 1,
      anon_sym_LT,
    ACTIONS(15), 1,
      sym__raw_text,
    ACTIONS(17), 1,
      anon_sym_LT_SLASH,
    STATE(4), 1,
      sym_start_tag,
    STATE(30), 1,
      sym_self_closing_element,
    STATE(31), 1,
      sym_self_closing_tag,
    STATE(32), 1,
      sym_end_tag,
    STATE(5), 4,
      sym__node,
      sym_element,
      sym_text,
      aux_sym_document_repeat1,
  [84] = 8,
    ACTIONS(11), 1,
      anon_sym_LT,
    ACTIONS(15), 1,
      sym__raw_text,
    ACTIONS(17), 1,
      anon_sym_LT_SLASH,
    STATE(4), 1,
      sym_start_tag,
    STATE(30), 1,
      sym_self_closing_element,
    STATE(31), 1,
      sym_self_closing_tag,
    STATE(35), 1,
      sym_end_tag,
    STATE(6), 4,
      sym__node,
      sym_element,
      sym_text,
      aux_sym_document_repeat1,
  [112] = 7,
    ACTIONS(19), 1,
      anon_sym_LT,
    ACTIONS(22), 1,
      anon_sym_LT_SLASH,
    ACTIONS(24), 1,
      sym__raw_text,
    STATE(4), 1,
      sym_start_tag,
    STATE(30), 1,
      sym_self_closing_element,
    STATE(31), 1,
      sym_self_closing_tag,
    STATE(6), 4,
      sym__node,
      sym_element,
      sym_text,
      aux_sym_document_repeat1,
  [137] = 7,
    ACTIONS(9), 1,
      sym__raw_text,
    ACTIONS(27), 1,
      ts_builtin_sym_end,
    ACTIONS(29), 1,
      anon_sym_LT,
    STATE(2), 1,
      sym_start_tag,
    STATE(21), 1,
      sym_self_closing_tag,
    STATE(33), 1,
      sym_self_closing_element,
    STATE(9), 4,
      sym__node,
      sym_element,
      sym_text,
      aux_sym_document_repeat1,
  [162] = 7,
    ACTIONS(9), 1,
      sym__raw_text,
    ACTIONS(29), 1,
      anon_sym_LT,
    ACTIONS(31), 1,
      ts_builtin_sym_end,
    STATE(2), 1,
      sym_start_tag,
    STATE(21), 1,
      sym_self_closing_tag,
    STATE(33), 1,
      sym_self_closing_element,
    STATE(7), 4,
      sym__node,
      sym_element,
      sym_text,
      aux_sym_document_repeat1,
  [187] = 7,
    ACTIONS(22), 1,
      ts_builtin_sym_end,
    ACTIONS(33), 1,
      anon_sym_LT,
    ACTIONS(36), 1,
      sym__raw_text,
    STATE(2), 1,
      sym_start_tag,
    STATE(21), 1,
      sym_self_closing_tag,
    STATE(33), 1,
      sym_self_closing_element,
    STATE(9), 4,
      sym__node,
      sym_element,
      sym_text,
      aux_sym_document_repeat1,
  [212] = 7,
    ACTIONS(9), 1,
      sym__raw_text,
    ACTIONS(29), 1,
      anon_sym_LT,
    ACTIONS(31), 1,
      ts_builtin_sym_end,
    STATE(2), 1,
      sym_start_tag,
    STATE(21), 1,
      sym_self_closing_tag,
    STATE(33), 1,
      sym_self_closing_element,
    STATE(9), 4,
      sym__node,
      sym_element,
      sym_text,
      aux_sym_document_repeat1,
  [237] = 4,
    ACTIONS(39), 1,
      anon_sym_GT,
    ACTIONS(41), 1,
      anon_sym_SLASH_GT,
    ACTIONS(43), 1,
      sym_attribute_name,
    STATE(13), 2,
      sym_attribute,
      aux_sym_start_tag_repeat1,
  [251] = 4,
    ACTIONS(43), 1,
      sym_attribute_name,
    ACTIONS(45), 1,
      anon_sym_GT,
    ACTIONS(47), 1,
      anon_sym_SLASH_GT,
    STATE(11), 2,
      sym_attribute,
      aux_sym_start_tag_repeat1,
  [265] = 3,
    ACTIONS(51), 1,
      sym_attribute_name,
    ACTIONS(49), 2,
      anon_sym_GT,
      anon_sym_SLASH_GT,
    STATE(13), 2,
      sym_attribute,
      aux_sym_start_tag_repeat1,
  [277] = 4,
    ACTIONS(43), 1,
      sym_attribute_name,
    ACTIONS(45), 1,
      anon_sym_GT,
    ACTIONS(54), 1,
      anon_sym_SLASH_GT,
    STATE(15), 2,
      sym_attribute,
      aux_sym_start_tag_repeat1,
  [291] = 4,
    ACTIONS(39), 1,
      anon_sym_GT,
    ACTIONS(43), 1,
      sym_attribute_name,
    ACTIONS(56), 1,
      anon_sym_SLASH_GT,
    STATE(13), 2,
      sym_attribute,
      aux_sym_start_tag_repeat1,
  [305] = 2,
    ACTIONS(60), 1,
      anon_sym_EQ,
    ACTIONS(58), 3,
      anon_sym_GT,
      anon_sym_SLASH_GT,
      sym_attribute_name,
  [314] = 2,
    ACTIONS(62), 1,
      anon_sym_LT,
    ACTIONS(64), 2,
      sym__raw_text,
      anon_sym_LT_SLASH,
  [322] = 1,
    ACTIONS(66), 3,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
  [328] = 2,
    ACTIONS(68), 1,
      anon_sym_LT,
    ACTIONS(70), 2,
      sym__raw_text,
      anon_sym_LT_SLASH,
  [336] = 1,
    ACTIONS(72), 3,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
  [342] = 1,
    ACTIONS(74), 3,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
  [348] = 1,
    ACTIONS(76), 3,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
  [354] = 1,
    ACTIONS(64), 3,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
  [360] = 1,
    ACTIONS(78), 3,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
  [366] = 2,
    ACTIONS(80), 1,
      anon_sym_DQUOTE,
    STATE(27), 2,
      sym__attribute_value,
      sym_quoted_attribute_value,
  [374] = 2,
    ACTIONS(82), 1,
      anon_sym_LT,
    ACTIONS(84), 2,
      sym__raw_text,
      anon_sym_LT_SLASH,
  [382] = 1,
    ACTIONS(86), 3,
      anon_sym_GT,
      anon_sym_SLASH_GT,
      sym_attribute_name,
  [388] = 1,
    ACTIONS(88), 3,
      anon_sym_GT,
      anon_sym_SLASH_GT,
      sym_attribute_name,
  [394] = 2,
    ACTIONS(90), 1,
      anon_sym_LT,
    ACTIONS(92), 2,
      sym__raw_text,
      anon_sym_LT_SLASH,
  [402] = 2,
    ACTIONS(94), 1,
      anon_sym_LT,
    ACTIONS(96), 2,
      sym__raw_text,
      anon_sym_LT_SLASH,
  [410] = 2,
    ACTIONS(98), 1,
      anon_sym_LT,
    ACTIONS(74), 2,
      sym__raw_text,
      anon_sym_LT_SLASH,
  [418] = 2,
    ACTIONS(100), 1,
      anon_sym_LT,
    ACTIONS(102), 2,
      sym__raw_text,
      anon_sym_LT_SLASH,
  [426] = 1,
    ACTIONS(96), 3,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
  [432] = 2,
    ACTIONS(104), 1,
      anon_sym_LT,
    ACTIONS(72), 2,
      sym__raw_text,
      anon_sym_LT_SLASH,
  [440] = 2,
    ACTIONS(106), 1,
      anon_sym_LT,
    ACTIONS(76), 2,
      sym__raw_text,
      anon_sym_LT_SLASH,
  [448] = 2,
    ACTIONS(108), 1,
      anon_sym_LT,
    ACTIONS(78), 2,
      sym__raw_text,
      anon_sym_LT_SLASH,
  [456] = 1,
    ACTIONS(92), 3,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
  [462] = 1,
    ACTIONS(102), 3,
      sym__raw_text,
      ts_builtin_sym_end,
      anon_sym_LT,
  [468] = 1,
    ACTIONS(110), 1,
      sym_tag_name,
  [472] = 1,
    ACTIONS(112), 1,
      sym_script_end_tag,
  [476] = 1,
    ACTIONS(114), 1,
      anon_sym_GT,
  [480] = 1,
    ACTIONS(116), 1,
      aux_sym_quoted_attribute_value_token1,
  [484] = 1,
    ACTIONS(118), 1,
      anon_sym_DQUOTE,
  [488] = 1,
    ACTIONS(120), 1,
      sym_tag_name,
  [492] = 1,
    ACTIONS(122), 1,
      ts_builtin_sym_end,
  [496] = 1,
    ACTIONS(124), 1,
      sym__script_content,
  [500] = 1,
    ACTIONS(126), 1,
      anon_sym_GT,
  [504] = 1,
    ACTIONS(128), 1,
      sym_tag_name,
  [508] = 1,
    ACTIONS(130), 1,
      sym_tag_name,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(2)] = 0,
  [SMALL_STATE(3)] = 28,
  [SMALL_STATE(4)] = 56,
  [SMALL_STATE(5)] = 84,
  [SMALL_STATE(6)] = 112,
  [SMALL_STATE(7)] = 137,
  [SMALL_STATE(8)] = 162,
  [SMALL_STATE(9)] = 187,
  [SMALL_STATE(10)] = 212,
  [SMALL_STATE(11)] = 237,
  [SMALL_STATE(12)] = 251,
  [SMALL_STATE(13)] = 265,
  [SMALL_STATE(14)] = 277,
  [SMALL_STATE(15)] = 291,
  [SMALL_STATE(16)] = 305,
  [SMALL_STATE(17)] = 314,
  [SMALL_STATE(18)] = 322,
  [SMALL_STATE(19)] = 328,
  [SMALL_STATE(20)] = 336,
  [SMALL_STATE(21)] = 342,
  [SMALL_STATE(22)] = 348,
  [SMALL_STATE(23)] = 354,
  [SMALL_STATE(24)] = 360,
  [SMALL_STATE(25)] = 366,
  [SMALL_STATE(26)] = 374,
  [SMALL_STATE(27)] = 382,
  [SMALL_STATE(28)] = 388,
  [SMALL_STATE(29)] = 394,
  [SMALL_STATE(30)] = 402,
  [SMALL_STATE(31)] = 410,
  [SMALL_STATE(32)] = 418,
  [SMALL_STATE(33)] = 426,
  [SMALL_STATE(34)] = 432,
  [SMALL_STATE(35)] = 440,
  [SMALL_STATE(36)] = 448,
  [SMALL_STATE(37)] = 456,
  [SMALL_STATE(38)] = 462,
  [SMALL_STATE(39)] = 468,
  [SMALL_STATE(40)] = 472,
  [SMALL_STATE(41)] = 476,
  [SMALL_STATE(42)] = 480,
  [SMALL_STATE(43)] = 484,
  [SMALL_STATE(44)] = 488,
  [SMALL_STATE(45)] = 492,
  [SMALL_STATE(46)] = 496,
  [SMALL_STATE(47)] = 500,
  [SMALL_STATE(48)] = 504,
  [SMALL_STATE(49)] = 508,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_document, 0, 0, 0),
  [5] = {.entry = {.count = 1, .reusable = true}}, SHIFT(46),
  [7] = {.entry = {.count = 1, .reusable = false}}, SHIFT(39),
  [9] = {.entry = {.count = 1, .reusable = true}}, SHIFT(37),
  [11] = {.entry = {.count = 1, .reusable = false}}, SHIFT(48),
  [13] = {.entry = {.count = 1, .reusable = true}}, SHIFT(44),
  [15] = {.entry = {.count = 1, .reusable = true}}, SHIFT(29),
  [17] = {.entry = {.count = 1, .reusable = true}}, SHIFT(49),
  [19] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(48),
  [22] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0),
  [24] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(29),
  [27] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_document, 2, 0, 0),
  [29] = {.entry = {.count = 1, .reusable = true}}, SHIFT(39),
  [31] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_document, 1, 0, 0),
  [33] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(39),
  [36] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_document_repeat1, 2, 0, 0), SHIFT_REPEAT(37),
  [39] = {.entry = {.count = 1, .reusable = true}}, SHIFT(26),
  [41] = {.entry = {.count = 1, .reusable = true}}, SHIFT(24),
  [43] = {.entry = {.count = 1, .reusable = true}}, SHIFT(16),
  [45] = {.entry = {.count = 1, .reusable = true}}, SHIFT(19),
  [47] = {.entry = {.count = 1, .reusable = true}}, SHIFT(20),
  [49] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_start_tag_repeat1, 2, 0, 0),
  [51] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_start_tag_repeat1, 2, 0, 0), SHIFT_REPEAT(16),
  [54] = {.entry = {.count = 1, .reusable = true}}, SHIFT(34),
  [56] = {.entry = {.count = 1, .reusable = true}}, SHIFT(36),
  [58] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_attribute, 1, 0, 0),
  [60] = {.entry = {.count = 1, .reusable = true}}, SHIFT(25),
  [62] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_end_tag, 3, 0, 0),
  [64] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_end_tag, 3, 0, 0),
  [66] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_script_element, 3, 0, 0),
  [68] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_start_tag, 3, 0, 0),
  [70] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_start_tag, 3, 0, 0),
  [72] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_self_closing_tag, 3, 0, 0),
  [74] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_self_closing_element, 1, 0, 0),
  [76] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_element, 3, 0, 0),
  [78] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_self_closing_tag, 4, 0, 0),
  [80] = {.entry = {.count = 1, .reusable = true}}, SHIFT(42),
  [82] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_start_tag, 4, 0, 0),
  [84] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_start_tag, 4, 0, 0),
  [86] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_attribute, 3, 0, 0),
  [88] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_quoted_attribute_value, 3, 0, 0),
  [90] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_text, 1, 0, 0),
  [92] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_text, 1, 0, 0),
  [94] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_element, 1, 0, 0),
  [96] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_element, 1, 0, 0),
  [98] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_self_closing_element, 1, 0, 0),
  [100] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_element, 2, 0, 0),
  [102] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_element, 2, 0, 0),
  [104] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_self_closing_tag, 3, 0, 0),
  [106] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_element, 3, 0, 0),
  [108] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_self_closing_tag, 4, 0, 0),
  [110] = {.entry = {.count = 1, .reusable = true}}, SHIFT(12),
  [112] = {.entry = {.count = 1, .reusable = true}}, SHIFT(18),
  [114] = {.entry = {.count = 1, .reusable = true}}, SHIFT(23),
  [116] = {.entry = {.count = 1, .reusable = true}}, SHIFT(43),
  [118] = {.entry = {.count = 1, .reusable = true}}, SHIFT(28),
  [120] = {.entry = {.count = 1, .reusable = true}}, SHIFT(41),
  [122] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
  [124] = {.entry = {.count = 1, .reusable = true}}, SHIFT(40),
  [126] = {.entry = {.count = 1, .reusable = true}}, SHIFT(17),
  [128] = {.entry = {.count = 1, .reusable = true}}, SHIFT(14),
  [130] = {.entry = {.count = 1, .reusable = true}}, SHIFT(47),
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

static const bool ts_external_scanner_states[4][EXTERNAL_TOKEN_COUNT] = {
  [1] = {
    [ts_external_token__script_content] = true,
    [ts_external_token__expression_content] = true,
    [ts_external_token__raw_text] = true,
  },
  [2] = {
    [ts_external_token__raw_text] = true,
  },
  [3] = {
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
