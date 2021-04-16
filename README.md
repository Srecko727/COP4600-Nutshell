# The Nutshell Term Project
# Rebecca Boes (1450-1929)/Srecko Markovic (1108-0530)

# Description
Our project somewhat acomplishes the goals of writing a command interpreter for a Korn shell-like command language in C using Lex and Yac running under Unix. Our project parses through command lines and executes some appropriate commands.
# Declaration of Team Member work
Rebecca Boes=RB / Srecko Markovic=SM
Built-in Commands - RB and SM along with Michaels original code
Non-built-in Commands - RB
Redirecting I/O with Non-built-in Commands - SM
Using Pipes with Non-built-in Commands - RB and SM
Running Non-built-in Commands in Background - RB and SM
Using both Pipes and I/O Redirection, combined, with Non-built-in Commands - RB and SM
Environment Variable Expansion - RB
Alias Expansion - RB
Wildcard Matching - RB
Shell Robustness (does not crash) - RB and SM
Error Handling and Reporting (potential point deduction) - RB and SM
README (potential point deduction) - RB and SM
Tilde Expansion (Extra Credit) - N/A
File Name Completion (Extra Credit) - N/A
# Design
### implemented
Built-in Commands
For setenv we used [1] to understand the setenv function and after we used the command we had to update the Variable table.
For printenv we used [2] to understand the environ function.
For unsetenv we used [3] to understand the unsetenv function and after we used the command we had to update the Variable table.
For CD it was given to us by Michaels code, which was very helpful in understanding how it worked.
For all the alias functions they were given to us by Michaels code, which was very helpful in understanding how it worked. What we added to it: made it match on the first word rather than all the words.
For bye it was given to us by Michaels code, which was very helpful in understanding how it worked.
Non-built-in Commands
they all work within nutshparser.y in our runCMD command, it splits the input up into an array of words and then it gets what the command was from the first word and then it splits up the environment variable path and apends the first word to every element of ./ than it checks if each path can be accessed and then execv is used [4]
Environment Variable Expansion
we created a function in our scanner to detect when the variables were used with "{}"........
Alias Expansion
............
Wildcard Matching
..............
### partialy implemented
Using Pipes with Non-built-in Commands
we split the input into words and looked through the iumput for "|" if there was one it was split based on pipes so that we could recieve an array of pipes. we went through the array of pipes with [8]. we split with a delimetor of pipes and from there we also split up the path to find if the imputs are both executables and from there we use execlp[9] to call the functions. we werent able to get it to fully work.
### not implemented
Redirecting I/O with Non-built-in Commands
We attempted to implement this with [5] [6] [7] but we could not get our shell to recognize the multiple pipes even after the multiple tutorials.
Using both Pipes and I/O Redirection, combined, with Non-built-in Commands
We attempted to do this along with Redirecting I/O with Non-built-in Commands and Using Pipes with Non-built-in Commands but we were not able to figure it out.
# Verification
Once someone has unzipped our project they can varify that the functionmality works as specified first do the command "make" to make all the required files for the shell and then do the command "./nutshell" to start the program. After this command "[nutshell]>>" will be on the screen and the user will be able to type their desired commands.
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