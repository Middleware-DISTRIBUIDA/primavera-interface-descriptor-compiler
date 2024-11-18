%{
  #include <stdio.h>
  #include "y.tab.h"
  
  extern int yyerror (char *msg); 
%}

%%

[ \t\r]                 ;                  /* Ignorar espaços e tabs */
\n                       { yylineno++; }    /* Contar novas linhas */

"package"               { return PACKAGE; }
"import"                { return IMPORT; }
"server"                { return SERVER; }
"class"                 { return CLASS; }
"method"                { return METHOD; }
"param"                 { return PARAM; }
"type"                  { return TYPE; }
"GET"                   { return REQUEST; }
"POST"                  { return REQUEST; }
"route"                 { return ROUTE; }
"query"                 { return QUERY; }
"path"                  { return PATH; }

\/\/.*                  ;                  /* Ignorar comentários de linha */

"{"                     { return '{'; }
"}"                     { return '}'; }
";"                     { return ';'; }
"="                     { return '='; }
","                     { return ','; }
"("                     { return '('; }
")"                     { return ')'; }

[a-zA-Z_][a-zA-Z0-9_\.]*  {yylval.sValue = strdup(yytext); return ID;}

\"(?:[^"\\]|\\.)*\"   {yylval.sValue = strdup(yytext); return STRING;}

[a-zA-Z_][a-zA-Z0-9_]*  {yylval.sValue = strdup(yytext); return ID;}

.                       { yyerror("invalid character"); }  /* Qualquer outro caractere é inválido */

%%

#ifndef yywrap
   int yywrap (void) {return 1;}
#endif
