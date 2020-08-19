# flopTool
Flop counter in Matlab/Octave

## Author
Leonardo T. Rolla and Shiyi Chen

## License
GNU Lesser General Public License, either version 3 of the License, or any later version.

## Usage
1. Prepare all code within one M file if the script call multiple functions in different scripts, internalize the functions into the main file.

1. Put this file in the same folder with flop_update.m, flop_script.m, go to that folder, execute  `flop_script("fileName.m")` or `flop_script("fileName")`.

1. Notice the command window, if the program terminates without any output in command window, then there will be a temporary file called `fileName_tmp.m` generated under the same folder. If warning appears, the program will tell the user which line in the original file causes the problem. The user needs to check the line in the original file and fixes the error. There are two types of warning:

  1. `Warning: In line XX, unrecognized pattern` indicates the flop analyzer crashed at XX line. For example, there may be some brackets missing which caused the program fail to read the variables. In this case, the program will jump it and continue counting the rest of script. The user needs to check whether the brackets are missing in the line, then run `flop_script.m` again.

  1. `Warning: In line XX, can't find left variable, assigning value 1 to it`, in this case, program does not find variables corresponding to operators in this line. The program will automatically assign 1 to that unknown variable and continue counting in this line. The user need to add brackets around the variable they want the program to count at the original file and run `flop_script.m` again, the temporary file will be automatically overwritten if the user run it again.

1. Run the temporary file, if it is a function, enter the temporary function signature, for example `fileName_tmp(A)`; if it's a script, click run. The temporary code should be running like the original code with the same output. After executing, a variable called flop_counter should be created in the workspace. In Matlab, users can see it directly in the workspace. In Octave, users need to query the variable flop_counter in command window to get the result.

## Comparison
We want users to have a choice between our tool and former tool writen by [Qian Hang](http://hangqian.weebly.com/)(his work can be find [here](https://www.mathworks.com/matlabcentral/fileexchange/50608-counting-the-floating-point-operations-flops)).

The new tool |  ``FLOPS''
-------------|--------------
The new tool may be more convenient for counting with changing input variable sizes in the sense that it does not need profiling, saving or loading MAT files. | Need profiling, saving and loading MAT files.
Longer elapse time for the temporary counting tool, which makes our tool not suitable for a long script. | Same elapse time with the original file.
Cannot recognize functions containing multiple arguments. | Can accept some multiple arguments like sum(A,2). 
Cannot recognize functions handles. | Can recognize bsxfun. 
Cannot know exact flops in each line.  | Display flops at each line and their executed rounds. 
Support variable changes and slicing. | Does not support variable changes and slicing. 
Support sparse matrices.  | Does not support sparse matrices.
Support multiple functions in a script but not nested. | Support nested function.
Change the rules in TXT file. | Change the rules in EXCEL file.
Support Octave > 4.2.0 and Matlab. | Only support Matlab.
Generate transparent code in a separate M file for auditing. | Display the flop count on the command window for auditing.
