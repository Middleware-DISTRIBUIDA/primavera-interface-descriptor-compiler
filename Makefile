BIN_DIRECTORY := bin

all: build test
	
build: clean create_bin_directory
	@echo "BUILDING COMPILER"

	lex -o bin/primavera.yy.c primavera_lexer.l

	yacc primavera_parser.y -d -v

	mv y.tab.c bin/y.tab.c
	mv y.tab.h bin/y.tab.h
	mv y.output bin/y.output

	gcc -o primavera bin/primavera.yy.c bin/y.tab.c lib/entry.c lib/hash_table.c lib/stack.c

test: clean build
	@echo "COMPILING TESTS\n"

	@echo "TEST 1\n"

	./primavera example.primavera

clean:
	clear
	
	@echo "CLEANING"

	rm -f primavera
	rm -f bin/*.yy.c
	rm -f bin/*.dot
	rm -f bin/*.tab.c
	rm -f bin/*.tab.h
	rm -f bin/*.output

	rm -f *.java

create_bin_directory:
	@if [ ! -d "$(BIN_DIRECTORY)" ]; then \
        mkdir -p "$(BIN_DIRECTORY)"; \
    fi

sint:
	lex primavera_lexer.l

	yacc primavera_parser.y -d -v -g  

	gcc lex.yy.c y.tab.c -o parser.exe 
	./parser.exe < example.primavera