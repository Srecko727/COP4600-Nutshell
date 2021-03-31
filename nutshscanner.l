/* -*- indented-text -*- */
%{
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"
#include "stdbool.h"

#ifdef DOESNT_HAVE_STRDUP
#warning DOESNT_HAVE_STRDUP
char *strdup(const char *s);
#endif

char* command_t;

char* subVars(char* var)
{
    int i;
    for (i = 0; i < varIndex; i++) {
        if(strcmp(varTable.var[i], var) == 0) {
            return varTable.word[i];
        }
    }
}

char* subAliases(char* name)
{
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            //printf("exists");
            return aliasTable.word[i];
        }
    }
    //printf("doesn't exist");
    return name;
}

bool ifAlias(char* name)
{
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {

            printf("returning true");
            return true;
        }
    }
    //printf("returning false");
    return false;
}
%}

%array

%option noyywrap

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR            [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
SPACE           [\032]

%x string_condition var_expansion

%%

<string_condition>{ANYCHAR}+     { yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}

<var_expansion>{CHAR}+     { yylval.string = strdup(subVars(yytext)); return STRING;}
<var_expansion>"}"          {BEGIN(INITIAL);}

[ ]		            { }
bye                 { return BYE; }
cd		            { return CD;}
setenv		        { return SETENV;}
printenv		    { return PRINTENV; }
unsetenv		    { return UNSETENV; }
alias		        { return ALIAS; }
unalias		        { return UNALIAS; }
"\n"		        { return END; }
">"	                { return OUTPUT;}
"<"		            { return INPUT;}
"|"                 { return PIPE;}
\\                   {return BACKSLASH;}
\&                   {return AND;}
[\"]                 { BEGIN(string_condition); }
"${"                 { BEGIN(var_expansion); }
{CHAR}+              {if(ifAlias(yytext)){
                        printf("yytext: %s\n", yytext);
                        //source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                           char *yycopy = strdup( subAliases(yytext) );
                           for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                               unput( yycopy[i] );
                           free( yycopy );
                    }else
                    {
                        printf("yytext: %s\n", yytext);
                        yylval.string = strdup(yytext);
                        return STRING;
                    };
                     }
%%

