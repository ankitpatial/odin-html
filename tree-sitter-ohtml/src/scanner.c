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
  bool has_content = false;
  while (lexer->lookahead != 0) {
    if (lexer->lookahead == '<') {
      lexer->mark_end(lexer);
      lexer->advance(lexer, false);
      if (lexer->lookahead == '/') {
        lexer->advance(lexer, false);
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
  // Skip leading whitespace
  while (lexer->lookahead != 0 &&
         (lexer->lookahead == ' ' || lexer->lookahead == '\t' ||
          lexer->lookahead == '\n' || lexer->lookahead == '\r')) {
    lexer->advance(lexer, true);
  }

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
