# Sudoku SAT Solver Makefile

OCAMLC = ocamlc
SUDOKU2CNF = sudoku2cnf
SOL2GRID = sol2grid

all: $(SUDOKU2CNF) $(SOL2GRID)

$(SUDOKU2CNF): sudoku2cnf.ml
	$(OCAMLC) -o $(SUDOKU2CNF) sudoku2cnf.ml

$(SOL2GRID): sol2grid.ml
	$(OCAMLC) -o $(SOL2GRID) sol2grid.ml

run: all
	./$(SUDOKU2CNF) input.txt > formula.cnf
	z3 -dimacs formula.cnf > sat_output.txt
	./$(SOL2GRID) sat_output.txt > output.txt

clean:
	rm -f $(SUDOKU2CNF) $(SOL2GRID) *.cmi *.cmo formula.cnf sat_output.txt output.txt

.PHONY: all run clean