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
bool running_cd = false;
bool subbed = false;
bool env = false;
bool nb = false;
bool setting_alias = false;
int arg_count = 0;
char *checked_input = "";

char* subAliases(char* name, bool using_env){
    char *first = strtok(name, " ");
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], first) == 0) {
            subbed = true;
            bool hasSpace = false;
            int size = sizeof(aliasTable.word[i])/sizeof(aliasTable.word[i][0]);
            char* withQuotes = (char*)malloc(sizeof(char)*(size+2));
            //looks for spaces but ignores first and last elements
            for(int j = 0; j < size; j++){
                if(aliasTable.word[i][j] == ' '){
                    hasSpace = true;
                }
            }
            //returning with quotation marks so the scanner doesn't separate the values
            if(hasSpace == true && using_env == false) {
                strncat(withQuotes, "\"", 1);
                strcat(withQuotes, aliasTable.word[i]);
                strncat(withQuotes, "\"", 1);
                return withQuotes;
            }
            free(withQuotes);
            return aliasTable.word[i];
        }
    }
    subbed = false;
    return name;
}
bool ifAlias(char* name, bool setting_env){
    char *first = strtok(name, " ");
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], first) == 0) {
            return true;
        }
    }
    if(setting_env == false){
        arg_count = 2;
    }
    return false;
}
char* expandENV(char* input, int len, bool inQuotes){
    char* varName = (char*)malloc(sizeof(char)*len);
    char* output = (char*)malloc(sizeof(char)*len);
    bool varFound = false;
    int before_position = 0;
    int after_position = 0;
    bool more_stuff = false;
    char open = '{';
    char close = '}';
    for(int i = 0; i < len; i++){
        if(varFound == true){
            if(input[i] == close){
                if(i + 1 < len){
                    more_stuff = true;
                    after_position = i + 1;
                }
                break;
            }
            strncat(varName, &input[i], 1);
        }
        else if(input[i] == open){
            varFound = true;
            before_position = i-1;
        }
    }
    if(varFound == true){
        if(inQuotes == true){
            for(int i = 0; i < before_position; i++){
                strncat(output, &input[i], 1);
            }
            for(int i = 0; i < varIndex; i++){
                if(strcmp(varTable.var[i], varName) == 0){
                    free(varName);
                    strcat(output, varTable.word[i]);
                    if(more_stuff == false){
                        return output;
                    }
                }
            }
            for(int i = after_position; i < len; i++){
                if(input[i] != '\"'){
                    strncat(output, &input[i], 1);
                }
                return output;
            }
            return input;
        } else {
            for(int i = 0; i < varIndex; i++){
                if(strcmp(varTable.var[i], varName) == 0){
                    free(varName);
                    return getenv(varTable.var[i]);
                }
            }
        }
    }else{
        free(varName);
        free(output);
    }
    return input;
}
%}
%array
%option noyywrap

CHAR                [:.A-Za-z0-9!\/_-][:.A-Za-z0-9!\/_-]*
ANYCHAR             [:}{)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(:*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
NONBUILTIN          ls|pwd|cat|echo|ssh|date|ping|rm|tty|touch|mkdir|rmdir|sort|wc|head|tail|rev|less
ARGSYMBOLS          [.!\/_\"'}{$ |><-]
VARSYMBOLS          $\{[.A-Za-z0-9!\/_-]+\}

%x string_condition
%%

<string_condition>{ANYCHAR}+    {yylval.string = strdup(expandENV(yytext, yyleng, true)); if(arg_count > 0){arg_count--;}; return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}

bye                 { return BYE; }
cd		            { running_cd = true; arg_count = 1; return CD; }
alias		        { arg_count = 2; setting_alias = true; return ALIAS; }
unalias             { check_unalias = true; arg_count = 1; return UNALIAS; }
"\n"		        { arg_count = 0; return END; }
[\"]                { BEGIN(string_condition); }
{VARSYMBOLS}        {   checked_input = expandENV(yytext, yyleng, false); arg_count = 0;
                        if(ifAlias(checked_input, env) && check_unalias == false) {
                            char *yycopy = strdup( subAliases(checked_input, true) );
                            for ( int i = strlen(subAliases(checked_input, true)) - 1; i >= 0; --i )
                                unput( yycopy[i] );
                            free( yycopy );
                        } else {
                            //printf("yytext: %s\n", yytext);
                            yylval.string = checked_input;
                            check_unalias = false;
                            if(arg_count > 0){
                                arg_count--; //arg_count will be 1 after first one is checked
                            }
                            return STRING;
                            };
                        }
setenv              { env = true; arg_count = 2; return SETENV; }
unsetenv            { arg_count = 1; return UNSETENV; }
printenv            { arg_count = 0; return PRINTENV; }
({NONBUILTIN}({ARGSYMBOLS}+{CHAR}*)*)        { yylval.string = strdup(expandENV(yytext, yyleng, true)); nb = true; return CMD; }
{CHAR}+             {   if(ifAlias(yytext, env) && running_cd == false && check_unalias == false && env == false && nb == false && (arg_count == 0 || arg_count == 2 || subbed == true)) {
                        //printf("yytext before sub: %s\n", yytext);
                            // source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                            // if there are no spaces, it is calling an alias
                            if(arg_count == 0){
                                setting_alias = false;
                            }
                            if(strcmp(yytext, strtok(yytext, " ")) == 0 && setting_alias == true) {
                                char *yycopy = strdup( subAliases(yytext, false) );
                                for ( int i = strlen(subAliases(yytext, false)) - 1; i >= 0; --i )
                                    unput( yycopy[i] );
                                free( yycopy );
                                //if setting was true, sets it to false after the first path
                                setting_alias = false;
                            }
                            else if(strcmp(yytext, strtok(yytext, " ")) == 0){
                                char *yycopy = strdup( subAliases(yytext, true) );
                                for ( int i = strlen(subAliases(yytext, true)) - 1; i >= 0; --i )
                                    unput( yycopy[i] );
                                free( yycopy );
                            } else {
                                char *yycopy = strdup( subAliases(yytext, false) );
                                for ( int i = strlen(subAliases(yytext, false)) - 1; i >= 0; --i )
                                    unput( yycopy[i] );
                                free( yycopy );
                            }
                    } else {
                        //printf("yytext: %s\n", yytext);
                        yylval.string = strdup(yytext);
                        check_unalias = false;
                        running_cd = false;
                        nb = false;
                        if(arg_count > 0){
                            
                            arg_count--; //arg_count decremented after it's used
                        }
                        if(arg_count == 0){
                            setting_alias = false;
                            env = false;
                        }
                        return STRING;
                        };
                    }
%%