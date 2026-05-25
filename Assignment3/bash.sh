rm -f *.cmi *.cmx *.o
ocamlfind ocamlopt -c Ast.ml
ocamlfind ocamlopt -c krivine_1.ml
ocamlfind ocamlopt -c krivine_2.ml
ocamlfind ocamlopt -c SECD_1.ml
ocamlfind ocamlopt -c SECD_2.ml
ocamlfind ocamlopt -c test.ml
ocamlfind ocamlopt -linkpkg Ast.cmx krivine_1.cmx krivine_2.cmx SECD_1.cmx SECD_2.cmx test.cmx -o run_tests
./run_tests