%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "global.h"

int yylex(void);
int yyerror(char *s);
%}

%union {
       char *string;
}

%start cmd_line
%token <string> BYE CD STRING SETENV ALIAS END PIPE PRINTENV UNSETENV UNALIAS OUTPUT INPUT ANYSTRING BACKSLASH AND
%token <string> DEFAULT RESULT

%%
cmd_line    :
	builtin_command END			{return 1;}
	| other_command	END			{execute_command(); return 1;}
	| STRING END				{runDefault2($1); return 1; }
        | STRING STRING END			{runDefault($1, $2); return 1; };

builtin_command :
        BYE		                	{exit(1); }
        | CD 					{runDefaultCD(); }
        | CD STRING        			{runCD($2);}
	| PRINTENV				{runPrintEnv(); }
	| SETENV STRING STRING 			{runSetEnv($2, $3); }
	| UNSETENV STRING 			{runUnSetEnv($2); }
	| ALIAS STRING STRING			{runSetAlias($2, $3); }
        | ALIAS					{runPrintAlias(); }
        | UNALIAS STRING			{runUnAlias($2); };

other_command :
	STRING OUTPUT other_command		{addToCTable1($1); }
	| STRING PIPE other_command		{addToCTable1($1); }
	| STRING				{addToCTable1($1); };
%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

int addToCTable2(char* arg1, char* arg2) {
	printf("adding to c table 2\n");
	printf("arg1: %s\n", arg1);
	printf("arg2: %s\n", arg2);
}

int addToCTable1(char* arg1) {
	printf("adding to c table 1\n");
	printf("arg1: %s\n", arg1);
	//strcpy(command_line[counter],arg1);
}

int execute_command(char* arg) {
	printf("executing command\n");
}

int runDefaultCD() {
	strcpy(varTable.word[0], varTable.word[1]);
	strcpy(aliasTable.word[0], varTable.word[1]);
	strcpy(aliasTable.word[1], "/Users/michaelperez/Desktop");
	chdir(varTable.word[1]);
	return 1;
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
			/*char *pointer = strrchr(aliasTable.word[1], '/');
			while(*pointer != '\0') {
			*pointer ='\0';
			pointer++;
			}*/
		}
		else {
			printf("Directory not found\n");
                       	return 1;
		}
	}
	return 1;
}

int runPrintEnv() {
	int i;
	for (i = 0; i < varIndex; i++) {
		printf("%s=%s\n", varTable.var[i], varTable.word[i]);
	}
	return 1;
}

int runSetEnv(char *variable, char *word) {
	for (int i = 0; i < varIndex; i++) {
		if(strcmp(varTable.var[i], variable) == 0) {
			if(i == 0 || i == 1 || i == 2){
				printf("current directory, home, and parent directory environment variables cannot be changed.\n");
				return 1;
			}
			else if(i == 3){
				if(strcmp(varTable.word[i], "") != 0) {
					strcat(varTable.word[i], ":");
				}
				strcat(varTable.word[i], word);
				return 1;
			} else {
				strcpy(varTable.word[i], word);
				return 1;
			}
		}
	}

	strcpy(varTable.var[varIndex], variable);
	strcpy(varTable.word[varIndex], word);
	varIndex++;  //increment index value

	return 1;
}

int runUnSetEnv(char *variable)
{
	int i;
	for (i = 0; i < varIndex; i++) {
		if(strcmp(varTable.var[i], variable) == 0) {
			if(i == 0 || i == 1 || i == 2){
                        	printf("current directory, home, and parent directory environment variables cannot be changed.\n");
				return 1;
			}
			else if (i == 3 || i == 4){
				strcpy(varTable.word[i], "");
			}else {
				strcpy(varTable.var[i], "");
				strcpy(varTable.word[i], "");
				varIndex--;
				for (int j = i + 1; j <= varIndex; j++) {
					strcpy(varTable.var[j-1], varTable.var[j]);
					strcpy(varTable.word[j-1], varTable.word[j]);
				}
				return 1;
				}
		}
	}

	return 1;
}

int runPrintAlias()
{
	int i;
	for (i = 0; i < aliasIndex; i++) {
		printf("%s=%s\n", aliasTable.name[i], aliasTable.word[i]);
	}
	return 1;
}

int runSetAlias(char *name, char *word)
{
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(name, word) == 0)
		{
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0))
		{
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
	aliasIndex++;  //increment index value

	return 1;
}

int runUnAlias(char *name)
{
	int i;
	for (i = 0; i < aliasIndex; i++) {
		if(strcmp(aliasTable.name[i], name) == 0) {
			strcpy(aliasTable.name[i], "");
                       	strcpy(aliasTable.word[i], "");
                       	break;
		}
	}
	aliasIndex--;
	if(aliasIndex > 0) {
		for (int j = i + 1; j <= aliasIndex; j++) {
			strcpy(aliasTable.name[j-1], aliasTable.name[j]);
                        strcpy(aliasTable.word[j-1], aliasTable.word[j]);
		}
	}
	return 1;
}

int runDefault(char *arg1, char *arg2)
{
	pid_t newPID;
	newPID = fork();
	if (newPID == 0) {
		char delims[] = ":";
		char* token = strtok(varTable.word[3], delims);
		while( token != NULL ) {
			token = strtok( NULL, delims );
		   	strcat(token, "/");
		 	strcat(token, arg1);
			if (execl(token, token, arg2, (char*)NULL) == -1) {
				perror("Command not found");
				return 1;
			}
		}
	}
	wait(newPID);
	return 1;
}

int runDefault2(char *arg1)
{
	pid_t newPID;
	printf("\n");
	newPID = fork();
	if (newPID == 0) {
		if (strchr(varTable.word[3], ':') == NULL) { // if path has no colons
			char* temp;
			strcpy(temp, varTable.word[3]);
			strcat(temp, "/");
			strcat(temp, arg1);

			if (execl(temp, arg1, (char*)NULL) == -1) {
				perror("Command not found");
				return 1;
			}
		}
		else {
			char delims[] = ":";
			char* token = strtok(varTable.word[3], delims);
			while( token != NULL ) {
				token = strtok( NULL, delims );
				strcat(token, "/");
				strcat(token, arg1);
				if (execl(token, arg1, (char*)NULL) == -1) {
					perror("Command not found");
					return 1;
				}
			}
		}
	}
	wait(newPID);
	return 1;
}