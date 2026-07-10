/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "kanata",

  externals: $ => [
    $.raw_string,
  ],

  extras: $ => [
    /\s/,
    $.line_comment,
    $.block_comment,
  ],

  rules: {
    source_file: $ => repeat($._form),

    _form: $ => choice(
      $.list,
      $.string,
      $.raw_string,
      $.number,
      $.variable_reference,
      $.alias_reference,
      $.identifier,
    ),

    list: $ => seq("(", repeat($._form), ")"),

    string: _ => token(seq('"', /[^"\n]*/, '"')),

    number: _ => /-?\d+(\.\d+)?/,

    variable_reference: _ => /\$[^\s()"]+/,

    alias_reference: _ => /@[^\s()"]+/,

    identifier: _ => /[^\s()"]+/,

    line_comment: _ => token(prec(2, seq(";;", /[^\n]*/))),

    block_comment: _ => token(prec(2, seq("#|", /[^|]*\|+([^#|][^|]*\|+)*/, "#"))),
  },
});
