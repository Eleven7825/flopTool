% Copyright (c) 2020 Shiyi Chen and Leonardo T. Rolla
% You can use, modify and redistribute this program under the terms of the
% GNU Lesser General Public License, either version 3 of the License, or 
% any later version.

% Runtest for the flop count tool

fprintf('This test will show you how to use the flopTool.\n\n')
fprintf('Calling the flop_script.m: \n')
fprintf(">> flop_script('example')\n")

flop_script('example')

fprintf("\nCalling the example_tmp.m:\n")
fprintf(">> example_tmp\n\n")

example_tmp

fprintf("Checking the flop count:\n")
fprintf(">> flop_counter\n")

flop_counter
