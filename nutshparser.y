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
#include <sys/stat.h>

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
int runCMD();
char** split(char* to_split, char* delimiter, char **arr);
char* change_spaces(char* str_input);
char* revert_spaces(char* str_input);
char* remove_quotes(char* str_input);
bool built_in;
int piping(char** pipes);
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
	| CMD END						{runCMD(1); return 1;}

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
	setenv(var, word, 1);
	strcpy(varTable.var[varIndex], var);
	strcpy(varTable.word[varIndex], word);
	varIndex++;
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
	if(strcmp(var, "HOME") == 0) {
		printf("\n%s\n", "Cannot unset HOME environment variable");
	} 
	else if (strcmp(var, "PATH") == 0) {
		printf("\n%s\n", "Cannot unset PATH environment variable");
	}
	else {
		unsetenv(var);

		//modifying table as well
		bool remove = false;
		for(int i = 0; i < varIndex-1; i++) {
			if(strcmp(varTable.var[i], var) == 0) {
				remove = true;
			}
			if(remove == true){
				strcpy(varTable.var[i], varTable.var[i+1]);
				strcpy(varTable.word[i], varTable.word[i+1]);
			}
    	}
    	varIndex--;
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
    bool remove = false;
    for(int i = 0; i < aliasIndex-1; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            remove = true;
        }
        if(remove == true){
            strcpy(aliasTable.name[i], aliasTable.name[i+1]);
			strcpy(aliasTable.word[i], aliasTable.word[i+1]);
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

char** split(char* to_split, char* delimiter, char** arr) {
	char* word = strtok(to_split, delimiter);
	int count = 0;
	while(word != NULL) {
		arr[count] = word;
		word = strtok(NULL, delimiter);
		count++;
	}
	arr[count] = NULL;
	return arr;
}

//these two handle quotations by changing spaces to @ so quotes don't get split up
char* change_spaces(char* str_input){
	int quote_indicator = -1;
	int size = sizeof(str_input);
	for(int i = 0; i < size; i++){
		if(strcmp(&str_input[i], "\"") == 0){
			quote_indicator *= -1;
		}
		else if(quote_indicator > 0){ //quote_indicator = 1 when the index is within quotations
			if(strcmp(&str_input[i], " ") == 0){
				strcpy(&str_input[i], "@");
			}
		}
	}
	
	return str_input;
}

char* revert_spaces(char* str_input){
	int size = sizeof(str_input);
	for(int i = 0; i < size; i++){
		if(strcmp(&str_input[i], "@") == 0){
			strcpy(&str_input[i], " ");
		}
	}
	return str_input;
}

char* remove_quotes(char* str_input){
	int size = sizeof(str_input);
	for(int i = 0; i < size; i++){
		if(strcmp(&str_input[i], "\"") == 0){
			strcpy(&str_input[i], "");
		}
	}
	return str_input;
}


int piping(char **pipes)
{
	char* sending;
	char* receiving;
	int index = 1;
	while(pipes[index] != NULL){
		sending = pipes[index-1];
		receiving = pipes[index];
	
		printf("sending: %s\n", "sending");
		printf("receiving: %s\n", "receiving");
		int ipipe[2],status;
		pid_t one;

		char **arr = (char**)malloc(sizeof(char)*500);
		char* path = strdup(getenv("PATH"));
		arr = split(path, ":", arr);
		char* s_str = (char*)malloc(sizeof(char)*100);
		char* r_str = (char*)malloc(sizeof(char)*100);
		char *sendPath;
		char *receivePath;

		int size = sizeof(arr);
		
		for(int i = 0; i < size; i++){
			strcpy(s_str, arr[i]);
			strcpy(r_str, arr[i]);
			//adding the command to the path string
			strcat(s_str, "/");
			strcat(r_str, "/");
			strcat(s_str, sending);
			strcat(r_str, receiving);
			
			if(access(s_str, X_OK) == 0){
				sendPath = s_str; //setting first argument to full path
				break;
			}
			if(access(r_str, X_OK) == 0){
				receivePath = r_str;
				break;
			}
		}

		one = fork();
		if(one == 0)
		{
			close(ipipe[0]);
			printf("%s\n","child");
			dup2(ipipe[1],STDOUT_FILENO);
			execlp(arr[0],sending,(char*)NULL);
			printf("%s\n","child done");
		}
		
		if(one > 0)
		{
			printf("%s\n","parent");
			close(ipipe[1]);
			dup2(ipipe[0],STDIN_FILENO);
			execlp(arr[0],receiving,(char*)NULL);
			printf("%s\n","parent done");
		} else {
			wait(0);
		}
		close(ipipe[0]);
		close(ipipe[1]);

		//waitpid(-1,&status,0);
		//waitpid(-1,&status,0);
	}
	return 0;
}

int runCMD() {
	char* input = yylval.string;
	char **tempArg = (char**)malloc(sizeof(char)*200);
	tempArg = split(input, " ", tempArg);

	bool needsPipe = false;
	int s, r, index = 0;
	while(tempArg[index] != NULL)
	{
		//printf("%s\n",tempArg[index]);
		if (strcmp(tempArg[index],">") == 0){
			needsPipe = true;
		}
		else if(strcmp(tempArg[index],"|") == 0){
			needsPipe = true;
		}
		index++;
	}
	if (needsPipe == true)
	{
		char **pipes = (char**)malloc(sizeof(char)*200);
		pipes = split(input, "|", pipes);
		piping(pipes);
		printf("%s\n", "piping exited");
		free(pipes);
		free(tempArg);
	}
	else
	{
		char **arr = (char**)malloc(sizeof(char)*500);
		char* path = strdup(getenv("PATH"));
		arr = split(path, ":", arr);
		char* p_str = (char*)malloc(sizeof(char)*100);

		int size = sizeof(arr);
		
		for(int i = 0; i < size; i++){
			strcpy(p_str, arr[i]);
			//adding the command to the path string
			strcat(p_str, "/");
			strcat(p_str, tempArg[0]);
			
			if(access(p_str, X_OK) == 0){
				tempArg[0] = p_str; //setting first argument to full path
				break;
			}
		}
		int pid = fork();
		if(pid == 0){ //child
			execv(p_str, tempArg);
			exit(0);
		}
		else if (pid > 0){ //parent
			wait(0);
		}
		free(tempArg);
	}
	return 0;
}
