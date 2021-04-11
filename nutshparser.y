%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run. 
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "global.h"
#include <dirent.h>
#include <stdbool.h>

int yylex();
int yyerror(char *s);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int runUnalias(char *name);
int runPrintAlias();
int runSetenv(char *var,char *word);
int runUnsetenv(char *var);
int runPrintenv();
int runPathCount(char *path);
int runCMD(char *command);
char** splitPath();
%}

%union {char *string;}

%start cmd_line
%token <string> BYE CD SETENV PRINTENV UNSETENV STRING ALIAS UNALIAS CMD END

%%
cmd_line    :
	BYE END 		                {exit(1); return 1; }

	| SETENV STRING STRING END		{runSetenv($2,$3); return 1;}
	| PRINTENV END					{runPrintenv(1); return 1;}
	| UNSETENV STRING END			{runUnsetenv($2); return 1;}

	| CD STRING END        			{runCD($2); return 1;}
	| ALIAS END						{runPrintAlias(1); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
	| UNALIAS STRING END			{runUnalias($2); return 1;}
	| CMD STRING END				{runCMD($2); return 1;}

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

int runCD(char* arg) {
	if (arg[0] != '/') { // arg is relative path
		strcat(varTable.word[0], "/");
		strcat(varTable.word[0], arg);

		if(chdir(varTable.word[0]) == 0) {
			strcpy(aliasTable.word[0], varTable.word[0]);
			strcpy(aliasTable.word[1], varTable.word[0]);
			char *pointer = strrchr(aliasTable.word[1], '/');
			while(*pointer != '\0') {
				*pointer ='\0';
				pointer++;
			}
		}
		else {
			//strcpy(varTable.word[0], varTable.word[0]); // fix
			printf("Directory not found\n");
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(aliasTable.word[0], arg);
			strcpy(aliasTable.word[1], arg);
			strcpy(varTable.word[0], arg);
			char *pointer = strrchr(aliasTable.word[1], '/');
			while(*pointer != '\0') {
			*pointer ='\0';
			pointer++;
			}
		}
		else {
			printf("Directory not found\n");
                       	return 1;
		}
	}
	return 1;
}

int runSetenv(char *var,char *word)
{
	setenv(var,word,1);
	return 0;
}

int runPrintenv()
{
	extern char **environ;
	for (int i=0;environ[i] != NULL; i++)
	{
		printf("%s\n",environ[i]);
	}
	return 0;
}

int runUnsetenv(char *var)
{
	printf("%s", var);
	if(strcmp(var, "HOME") == true) {
		printf("%s\n", "Cannot unset HOME environment variable");
	} 
	else if (strcmp(var, "PATH") == true) {
		printf("%s\n", "Cannot unset PATH environment variable");
	}
	else {
		unsetenv(var);
	}
	return 0;
}

int runSetAlias(char *name, char *word) {
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(name, word) == 0){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if(strcmp(aliasTable.name[i], name) == 0) {
			strcpy(aliasTable.word[i], word);
			return 1;
		}
	}
	strcpy(aliasTable.name[aliasIndex], name);
	strcpy(aliasTable.word[aliasIndex], word);
	aliasIndex++;

	return 1;
}

int runUnalias(char *name){
    int position = 0;
    bool remove = false;
    for(int i = 0; i < aliasIndex-1; i++) {
        if(strcmp(aliasTable.name[i], name) == true) {
            remove = true;
        }
        if(remove == true){
            strcpy(aliasTable.name[i], aliasTable.name[i+1]);
        }
    }
    aliasIndex--;
    return 0;
}

int runPrintAlias() {
	for(int i = 0; i < aliasIndex; i++) {
		printf("%s", aliasTable.name[i]);
		printf("%s", "=");
		printf("%s\n",aliasTable.word[i]);
	}
	return 0;
}

char** splitPath() {
	int count = 0;
	int i = 0;
	for(i = 0; i < varIndex; i++){
		if(strcmp(varTable.var[i], "PATH") == true) {
			char *token = strtok(varTable.word[i], ":");
			while( token != NULL ) {
				count++;
   			}
			break;
		}
	}
	char** split = malloc(sizeof(int)*count);;
	char *token = strtok(varTable.word[i], ":");
	while( token != NULL ) {
		split[i] = token;
	}
	return split;
}

int runCMD(char *command) {
	printf("in cmd function");
	char** path = splitPath();
	if(strcmp(command, "pwd") == true) {
		printf("cmd is pwd");
		for(int i = 0; i < varIndex; i++) {
			if(strcmp(varTable.var[i], "PWD") == true) {
				printf("found variable");
				printf("%s\n",varTable.word[i]);
				break;
			}
		}
	}
	return 0;
}