#!/bin/bash
set -e

echo "Cleaning..."
rm -f *.cmo *.cmi lexer.ml parser.ml parser.mli main

echo "Removing generated parser.mli to avoid type mismatch..."
rm -f parser.mli

echo "Compiling files..."
ocamlc -c types.mli
ocamlc -c types.ml
ocamlc -c env.mli
ocamlc -c env.ml
ocamlc -c Assignment2a.mli
ocamlc -c Assignment2a.ml
ocamlc -c token.ml
ocamlc -c Ast.ml
ocamlyacc parser.mly
rm -f parser.mli
ocamlc -c parser.ml
ocamllex lexer.mll
ocamlc -c lexer.ml
ocamlc -c typecheck.mli
ocamlc -c typecheck.ml
ocamlc -c main.ml

echo "Linking..."
ocamlc -o main \
  Assignment2a.cmo \
  types.cmo \
  env.cmo \
  token.cmo \
  Ast.cmo \
  parser.cmo \
  lexer.cmo \
  typecheck.cmo \
  main.cmo

echo ""
echo "============================="
echo "        LEXER OUTPUT         "
echo "============================="
./main lex input.txt

echo ""
echo "============================="
echo "       PARSER OUTPUT         "
echo "============================="
./main parse input.txt

echo ""
echo "============================="
echo "     TYPECHECK OUTPUT        "
echo "============================="
./main typecheck input.txt