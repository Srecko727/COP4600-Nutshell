%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run. 
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"
#include <stdbool.h>
#include <dirent.h>

//#define unput(c) {yytchar= (c); if(yytchar=='\n') {yylineno--; *yysptr++=yytchar;}
bool check_unalias = false;
int arg_count = 0;
char* subAliases(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return aliasTable.word[i];
        }
    }
    return name;
}
bool ifAlias(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return true;
        }
    }
    return false;
}
char* expandENV(char* input, int len, bool inQuotes){
    printf("input: %s\n", input);
    char* varName = (char*)malloc(sizeof(char)*len);
    char* output = (char*)malloc(sizeof(char)*len);
    bool varFound = false;
    int position = 0;
    for(int i = 0; i < len; i++){
        if(varFound == true){
            if(input[i] == '}'){
                break;
            }
            strncat(varName, &input[i], 1);
        }
        else if(input[i] == '{'){
            varFound = true;
            position = i - 1;
        }
    }
    if(varFound == true){
        if(inQuotes == true){
            for(int i = 0; i < position; i++){
                strncat(output, &input[i], 1);
            }
            for(int i = 0; i < varIndex; i++){
                printf("table_var: %s\n", varTable.var[i]);
                if(strcmp(varTable.var[i], varName) == 0){
                    free(varName);
                    printf("word: %s\n", getenv(varTable.var[i]));
                    strcat(output, varTable.word[i]);
                    return output;
                }
            }
            return input;
        } else {
            printf("variable: %s\n", varName);
            printf("num: %d\n", varIndex);
            for(int i = 0; i < varIndex; i++){
                printf("table_var: %s\n", varTable.var[i]);
                if(strcmp(varTable.var[i], varName) == 0){
                    free(varName);
                    printf("word: %s\n", getenv(varTable.var[i]));
                    return varTable.word[i];
                }
            }
        }
    }else{
        free(varName);
    }
    return input;
}
%}
%array
%option noyywrap

CHAR                [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR             [}{)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
NONBUILTIN          ls|pwd|cat|echo|ssh|date|ping|rm|tty|touch|mkdir|rmdir|sort|wc|head|tail|rev|less
ARGSYMBOLS          [ .!\/_\"' -]
VARSYMBOLS          $\{[.A-Za-z0-9!\/_-]+\}

%x string_condition
%%

<string_condition>{ANYCHAR}+    { printf("%s\n", "quotes matching"); yylval.string = strdup(expandENV(yytext, yyleng, true)); arg_count--; return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}


bye                 { return BYE; }
cd		            { return CD; }
alias		        { arg_count = 2; return ALIAS; }
unalias             { check_unalias = true; return UNALIAS; }
"\n"		        { return END; }
[\"]                { BEGIN(string_condition); }
{VARSYMBOLS}        { yylval.string = strdup(expandENV(yytext, yyleng, false)); arg_count = 0; return STRING;}
setenv              { arg_count = 2; return SETENV; }
unsetenv            { return UNSETENV; }
printenv            { return PRINTENV; }
({NONBUILTIN}({ARGSYMBOLS}{CHAR})*)        { yylval.string = strdup(yytext); return CMD; }
{CHAR}+             {if(ifAlias(yytext) && check_unalias == false && (arg_count == 0 || arg_count == 2)) {
                        //printf("%s\n", "why am i here");
                        printf("yytext before sub: %s\n", yytext);
                        // source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                           char *yycopy = strdup( subAliases(yytext) );
                           for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                               unput( yycopy[i] );
                           free( yycopy );
                    } else {
                        printf("yytext: %s\n", yytext);
                        yylval.string = strdup(yytext);
                        check_unalias = false;
                        //printf("%d\n", arg_count);
                        if(arg_count > 0){
                            arg_count--; //arg_count will be 1 after first one is checked
                        }
                        return STRING;
                        };
                    }
%%