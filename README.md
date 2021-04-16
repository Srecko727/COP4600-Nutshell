# The Nutshell Term Project
# Rebecca Boes (1450-1929)/Srecko Markovic (1108-0530)
# Description
Our Nutshell Term Project somewhat accomplishes the goals of writing a command interpreter for a Korn shell-like command language in C using Lex and Yacc running under Unix. It scans and parses through command line inputs and executes most of the required commands.
# Declaration of Team Member work
Rebecca Boes=RB / Srecko Markovic=SM
Built-in Commands - RB and SM along with Michael's original code
Non-built-in Commands - RB
Redirecting I/O with Non-built-in Commands - SM
Using Pipes with Non-built-in Commands - RB and SM
Running Non-built-in Commands in Background - RB
Using both Pipes and I/O Redirection, combined, with Non-built-in Commands - RB and SM
Environment Variable Expansion - RB
Alias Expansion - RB
Wildcard Matching - SM
Shell Robustness (does not crash) - RB and SM
Error Handling and Reporting (potential point deduction) - RB and SM
README (potential point deduction) - RB and SM
Tilde Expansion (Extra Credit) - N/A
File Name Completion (Extra Credit) - N/A
# Design
### Implemented Features
##### Built-in Commands
For setenv, we used [1] to understand the setenv function and after we used the command to create or update the specified environment variable we updated the variable table to include the change.
For printenv, we used [2] to understand the environ function and printed all the variables.
For unsetenv, we used [3] to understand the unsetenv function and after we used the command we had updated the variable table to no longer store the unset variable.
CD it was given to us by Michael's starter code, which was very helpful in understanding how it worked.
The alias function to set a new alias was also given in Michael's starter code. In addition to it we added a case where there were no arguments that printed all the current aliases as well as implememnted the unalias command which removed the given alias name and its word from the alias table. What we added to it: made it match on the first word rather than all the words.
Alias expansion was mostly given to us as well, but we modified the given code to only match on the first word rather than all words.
Bye was the last command given to us from the starter code and it is used to exit the shell.
##### Non-built-in Commands
For the non-built-in commands we had to hard code the values on the scanner side because we were unsure of how to make them match the inputs with reqular expressions since we already had one matching to any character to handle when the user wanted to use an alias. In our parser, all non-built-in commands work in our runCMD function. First, the input is split into an array of words and the PATH environment variable is also split up into its components. Knowing the first word is the command it will be looking for, it is then appended with a slash to each compenent of the path variable. Then, each of those paths are checked to look for one that can be accessed. The accessible path is then passed into execv [4] along with the rest of the arguments to execute the non-built-in command.
##### Environment Variable Expansion
To implement the environment variable expansion, we created a function that looked for curly braces within the input to determine if the user was trying to use a variable and then return the correct value from the variable table. This was done by appending the characters between the braces to get the name of the variable, then returning the value at that variable. If there is no match, it returns the input back.
### Not Implemented Features
##### Using Pipes with Non-built-in Commands
In trying to implement this, we looped through the input for "|" to determine if piping was needed. If so, the input would then be split based on a "|" delimiter to give an array of pipes. We went through the array of pipes with [8] and for each we split the path similar to what was done with the non-built-in commands. Then, the path/command combinations were checked to see if they existed, similar to the non-built-ins, and from there we used execlp [9] to call the functions. Unfortunately, we were unable to make this work and commented this out due to it causing our shell to crash sometimes.
##### Redirecting I/O with Non-built-in Commands
We attempted to implement I/O redirection with [5] [6] [7] but we could not get our shell to recognize the multiple pipes even after going through documentation and watching many tutorials. Even when we got it closer to working, it still exited the shell every time and crashed occasionally. So, it had to be taken out.
##### Using both Pipes and I/O Redirection, combined, with Non-built-in Commands
While our non-built-in commands do work properly, we were not able to get either of the I/O redirection or piping to be functional. Since our Nutshell cannot handle pipes or redirection at all on their own, we could not combine them to make them work with the non-built-ins all together.
##### Wildcard Matching
We attempted to implement wildcard matching with the glob function [10], but we were unsuccessful with implementing it because we had trouble understanding the glob and iglob functions fully. We tried to make the implementation similar to that of the environment variables function, but were unsucccessful and had to decide to leave this feature out as well.
# Verification
Once someone has unzipped our project they can varify that the functionmality works as specified by first using the command "make" to make all the required files for the shell. Then running the command "./nutshell" would start the program and our functionality can be verified from there. Once the shell is started, "[nutshell]>>" will be shown on the screen to indicate that our shell is still running until the "bye" command is run.
# Citing
[1]https://man7.org/linux/man-pages/man3/setenv.3.html
[2]https://man7.org/linux/man-pages/man7/environ.7.html
[3]https://linux.die.net/man/3/unsetenv
[4]https://www.qnx.com/developers/docs/6.5.0SP1.update/com.qnx.doc.neutrino_lib_ref/e/execv.html
[5]https://stackoverflow.com/questions/8389033/implementation-of-multiple-pipes-in-c
[6]http://www.rozmichelle.com/pipes-forks-dups/
[7]https://stackoverflow.com/questions/33884291/pipes-dup2-and-exec
[8]https://www.youtube.com/watch?v=pO1wuN3hJZ4&t=2s
[9]https://www.qnx.com/developers/docs/6.5.0SP1.update/com.qnx.doc.neutrino_lib_ref/e/execlp.html
[10]https://docs.python.org/3/library/glob.html