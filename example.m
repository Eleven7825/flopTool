% Copyright (c) 2020 Shiyi Chen and Leonardo T. Rolla
% You can use, modify and redistribute this program under the terms of the
% GNU Lesser General Public License, either version 3 of the License, or 
% any later version.

% example script

a = sin(11);
B = randi(3,3);
C = B + a;
d = rand(3,1);
n = 3;

for i = 1 : n
    B(:,1 : i) = B(:, 1 : i) * i;
    y = B/a;
end

