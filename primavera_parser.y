%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>

#include "../lib/entry.h"
#include "../lib/hash_table.h"
#include "../lib/stack.h"

int yylex(void);
int yyerror(char *s);
char *cat(int, ...);
void insert_imports(const char*, const char*);
char * generateId();

void printVariables(const char*, const char*);

extern int yylineno;
extern char* yytext;
extern FILE* yyin, * yyout;
HashTable* type_table;
Stack* scope_stack;
int Errors = 0;
int scopeId = 1;
%}

%union {
	char* sValue;  /* string value */
	struct entry* ent;
};

%token <sValue> ID STRING TYPE REQUEST
%token PACKAGE IMPORT SERVER CLASS METHOD ROUTE QUERY PARAM PATH

%type <ent> header class_definition import_statements server_definition import_statement route parameter method field_definition inner_class inner_classes field_definitions methods parameters parameters_metadata query_params path_params
%start file

%%

file            : header class_definition {
                    fprintf(yyout, "%s\n", $1->code);
                    fprintf(yyout, "%s\n", $2->code);
                    free_entry($1);
                    free_entry($2);
                }
                ;

header          : PACKAGE ID ';' import_statements server_definition {
                    char* code = cat(4, "package ", $2, ";\n\n", $4->code, $5->code);
                    $$ = create_entry(code, "");
                    free($2);
                    free(code);
                    free_entry($4);
                    free_entry($5);
                }
                ;

import_statements: import_statements import_statement 
                | /* vazio */ { $$ = create_entry("", ""); }
                ;

import_statement : IMPORT ID ';' {
                    char* s = cat(3, "import ", $2, ";\n");
                    $$ = create_entry(s, "");
                    free(s);
                    free($2);
                }
                ;

server_definition: SERVER '=' STRING ';' {
                    char* s = cat(2, "// Server URL: ", $3, "\n\n");
                    $$ = create_entry(s, "");
                    free($3);
                }
                ;

class_definition : CLASS ID '{' inner_classes methods '}' {
                    char* code = cat(4, "public class ", $2, " {\n", $4->code, $5->code, "\n}\n");
                    $$ = create_entry(code, "");
                    free($2);
                    free_entry($4);
                    free_entry($5);
                }
                ;

inner_classes   : inner_classes inner_class 
                | /* vazio */ { $$ = create_entry("", ""); }
                ;

inner_class     : CLASS ID '{' field_definitions '}' {
                    char* class_code = cat(4, "public static class ", $2, " {\n", $4->code, "\n}\n");
                    $$ = create_entry(class_code, "");
                    free($2);
                    free_entry($4);
                }
                ;

field_definitions : field_definitions field_definition 
                  | /* vazio */ { $$ = create_entry("", ""); }
                ;

field_definition : TYPE ID ID ';' {
                    char* field_code = cat(3, "public ", $1, " ", $2, ";\n");
                    $$ = create_entry(field_code, "");
                    free($1);
                    free($2);
                }
                ;

methods         : methods method 
                | /* vazio */ { $$ = create_entry("", ""); }
                ;

method          : METHOD ID ID '(' parameters ')' REQUEST route parameters_metadata {
                    char* method_code = cat(6, "public ", $2, " ", $3, "(", $5->code, ") {\n\t// TODO: Implement method\n}\n", $7, $8->code);
                    $$ = create_entry(method_code, "");
                    free($2);
                    free($3);
                    free_entry($5);
                    free($7);
                    free_entry($8);
                }
                ;

parameters      : parameters ',' parameter 
                | parameter 
                | /* vazio */ { $$ = create_entry("", ""); }
                ;

parameter       : ID ID {
                    char* param_code = cat(3, $1, " ", $2);
                    $$ = create_entry(param_code, "");
                    free($1);
                    free($2);
                }
                ;

route           : ROUTE '=' STRING ';' {
                    char* route_comment = cat(3, "/* Route: ", $3, " */\n");
                    $$ = create_entry(route_comment, "");
                    free($3);
                }
                ;

parameters_metadata : query_params path_params 
                    | /* vazio */ { $$ = create_entry("", ""); }
                    ;

query_params    : QUERY PARAM '=' '(' query_parameters ')' { /* Define query parameters */ };
path_params     : PATH PARAM '=' '(' path_parameters ')' { /* Define path parameters */ };

query_parameters: query_parameters ',' query_parameter | query_parameter;
query_parameter : ID '=' ID;

path_parameters : path_parameters ',' path_parameter | path_parameter;
path_parameter  : ID '=' ID;

%%

int main(int argc, char** argv) {
    srand(time(NULL));
    int status;
    yylineno = 1;

    if (argc != 2) {
       printf("Usage: $./primavera input.primavera\nClosing application...\n");
       exit(0);
    }

    char* outputFilename = cat(1, "ClientProxyGenerated.java");

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        free(outputFilename);
        yyerror("Unable to open input file");
    }

    yyout = fopen(outputFilename, "w");
    if (yyout == NULL) {
        fclose(yyin);
        free(outputFilename);
        yyerror("Unable to open output file");
    }

    type_table = create_table();
    scope_stack = create_stack();

    status = yyparse();

    iterate_table(type_table, printVariables);

    fclose(yyin);
    fclose(yyout);
    free(outputFilename);
    free_table(type_table);

    return status;
}

void printVariables(const char* key, const char* value) {
    printf("-> %s : %s \n", key, value);
}

void insert_imports(const char* key, const char* value) {
    if (strcmp(value, "#IMPORT") == 0) {
        fprintf(yyout, "%s\n", key);
    }
}

int yyerror(char* msg) {
    Errors++;
    fprintf(stderr, "line %d: %s at '%s'\n", yylineno, msg, yytext);
    return 0;
}

char* cat(int num, ...) {
    va_list args;
    int total_length = 0;

    va_start(args, num);
    for (int i = 0; i < num; i++) {
        char* s = va_arg(args, char*);
        total_length += strlen(s);
    }
    va_end(args);

    char* output = (char*)malloc((total_length + 1) * sizeof(char));
    if (!output) {
        printf("Allocation problem. Closing application...\n");
        exit(0);
    }

    output[0] = '\0';
    va_start(args, num);
    for (int i = 0; i < num; i++) {
        char* s = va_arg(args, char*);
        strcat(output, s);
    }
    va_end(args);

    return output;
}
