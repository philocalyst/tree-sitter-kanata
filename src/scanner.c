#include "tree_sitter/parser.h"

#include <wctype.h>

enum TokenType { RAW_STRING };

void *tree_sitter_kanata_external_scanner_create(void) { return NULL; }

void tree_sitter_kanata_external_scanner_destroy(void *payload) {}

unsigned tree_sitter_kanata_external_scanner_serialize(void *payload, char *buffer) { return 0; }

void tree_sitter_kanata_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {}

bool tree_sitter_kanata_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
    if (!valid_symbols[RAW_STRING]) return false;

    while (iswspace(lexer->lookahead)) lexer->advance(lexer, true);

    if (lexer->lookahead != 'r') return false;
    lexer->advance(lexer, false);
    if (lexer->lookahead != '#') return false;
    lexer->advance(lexer, false);
    if (lexer->lookahead != '"') return false;
    lexer->advance(lexer, false);

    while (!lexer->eof(lexer)) {
        if (lexer->lookahead == '"') {
            lexer->advance(lexer, false);
            if (lexer->lookahead == '#') {
                lexer->advance(lexer, false);
                lexer->result_symbol = RAW_STRING;
                return true;
            }
        } else {
            lexer->advance(lexer, false);
        }
    }
    return false;
}
