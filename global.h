#include "stdbool.h"

struct evTable {
   char var[128][100];
   char word[128][100];
};

struct aTable {
	char name[128][100];
	char word[128][100];
};

char command_line [30][80];
int counter;

struct evTable varTable;

struct aTable aliasTable;

int aliasIndex, varIndex;

char* subVars(char* var);

char* subAliases(char* name);

bool has_alias;