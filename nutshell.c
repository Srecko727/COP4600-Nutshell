#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include "global.h"

// CATCH ALL CTRL TERMINAL ATTEMPTS TO KILL
static void recvfrom_alarm(int signo) {
   return;         /* just interrupt the recvfrom() */
}

static void ctrl_c_alarm(int signo) {
   return;         /* just interrupt the recvfrom() */
}

int main()
{
    counter = 0;
    aliasIndex = 0;
    varIndex = 0;

    strcpy(varTable.var[varIndex], "PWD");
    strcpy(varTable.word[varIndex], "/Users/michaelperez/Desktop/diy");
    varIndex++;
    strcpy(varTable.var[varIndex], "HOME");
    strcpy(varTable.word[varIndex], "/Users/michaelperez/Desktop/diy");
    varIndex++;
    strcpy(varTable.var[varIndex], "PROMPT");
    strcpy(varTable.word[varIndex], "nutshell");
    varIndex++;
    strcpy(varTable.var[varIndex], "PATH");
    strcpy(varTable.word[varIndex], ".:/bin");
    varIndex++;

    strcpy(aliasTable.name[aliasIndex], ".");
    strcpy(aliasTable.word[aliasIndex], "/Users/michaelperez/Desktop/diy");
    aliasIndex++;
    strcpy(aliasTable.name[aliasIndex], "..");
    strcpy(aliasTable.word[aliasIndex], "/Users/michaelperez/Desktop");
    aliasIndex++;

   char  prompt[20];
   char  input[128];
   enum states 
   {
      RUNNING = 0,
      EXIT = 1
   } state;

   //Signal handler
   signal(SIGTERM, SIG_IGN);
   //signal(SIGKILL, SIG_IGN); 
   signal(SIGINT, SIG_IGN);  //This one handles ctrl+c
   signal(SIGINT, ctrl_c_alarm);		//CTRL-C killing process
   signal(SIGTSTP, recvfrom_alarm);	//CTRL-Z killing process
   signal(SIGQUIT, recvfrom_alarm);	//CTRL-$ and CTRL-\

   system("clear");
   //env = getEnvVars();
   while(1)
   {
      //printf("%s\n", env.pwd);
      printf("[%s]>> ", varTable.word[2]);
      yyparse();
   }

   return 0;
}