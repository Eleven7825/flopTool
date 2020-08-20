% flop_update
% Take the sizes of two variable as parameters -- type 1*2 array, update the flop
% globally

% Copyright (c) 2020 Shiyi Chen and Leonardo T. Rolla
% You can use, modify and redistribute this program under the terms of 
% the GNU Lesser General Public License, either version 3 of the License, 
% or any later version.

function new_flop = flop_update(opt,var1,var2,flop_counter)
  size1 = size(var1);
  size2 = size(var2);
  ncol1 = size1(2);
  nrow1 = size1(1);
  ncol2 = size2(2);
  nrow2 = size2(1);
  nrow = nrow1;
  ncol = ncol1;
  
% Below code contains modified copyright work, please follow the
% liscence of original copyright owner.  

% Copyright (c) 2015, Hang Qian
% All rights reserved.

% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:

% * Redistributions of source code must retain the above copyright notice, this
%  list of conditions and the following disclaimer.

% * Redistributions in binary form must reproduce the above copyright notice,
%  this list of conditions and the following disclaimer in the documentation
%  and/or other materials provided with the distribution
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% Load extended rules in the TXT file ExtendedRules.txt
if exist('ExtendedRules.txt','file') == 2
    try
        [op_list,for_list]=readrules('ExtendedRules.txt');
        NewRule = [op_list',for_list'];              
    catch
        NewRule = {};
    end
else
    NewRule = cell(0,2);
end


% User supplied new rules for arithmetic operations in ExtendedRules.txt
if ~isempty(NewRule)    
    for m = 1:size(NewRule,1)
        if strcmp(opt,NewRule{m,1})            
            try
                count = round(eval(NewRule{m,2}));
            catch
                count = 0;
                warning('User supplied rules %s cannot be evaluated.',NewRule{m,1})
            end
            new_flop = flop_counter + count;
            return
        end
    end    
end

switch opt
    
    case '+'
        
        count = max(nrow1*ncol1, nrow2*ncol2);
        
    case '-'
        
        count = max(nrow1*ncol1, nrow2*ncol2);
        
    case '*'
        
        if (nrow1==1 && ncol1==1) || (nrow2==1 && ncol2==1)
            count = max(nrow1*ncol1, nrow2*ncol2);
        else
            count = 2*nrow1*ncol1*ncol2;
        end
        
    case '.*'
        
        count = max(nrow1*ncol1, nrow2*ncol2);
        
    case '/'
        
        if nrow2==1 && ncol2==1            
            count = max(nrow1*ncol1, nrow2*ncol2);
        else            
            count = round(2/3*nrow2^3) + 2*nrow2^2*nrow1;
        end
        
    case './'
        
        count = max(nrow1*ncol1, nrow2*ncol2);
        
    case '\'
        
        if nrow1==1 && ncol1==1
            % Scalar right division
            count = max(nrow1*ncol1, nrow2*ncol2);
        elseif nrow1 == ncol1
            % Solving equations Ax=b
            count = round(2/3*ncol1^3) + 2*ncol1^2*ncol2;
        else
            % OLS (X'*X)\(X'*Y)
            count = 2*ncol1*nrow1*ncol1 + 2*ncol1*nrow1*ncol2 + round(2/3*ncol1^3) + 2*ncol1^2*ncol2;
        end        
        
    case '.\'
        
        count = max(nrow1*ncol1, nrow2*ncol2);
        
    case '^'
        
        temp1 = dec2bin(ncol2);
        temp2 = length(temp1) + sum(temp1=='1') - 1;
        count = 2*nrow1^3*temp2; 
        
    case '.^'
        
        count = 2 .* max(nrow1*ncol1, nrow2*ncol2);
        
    case {'>', '>=','<', '<=', '==','~='}
        
        count = 0;
        
    case {'sum','prod','cumsum','cumprod'}
        
        count = nrow*ncol;    
        
    case 'mean'
        
        count = (nrow+1)*ncol;
        
    case 'var'
        
        count = 4*nrow*ncol;
        
    case 'std'
        
        count = 4*nrow*ncol;
        
    case 'cov'
        
        count = 2*nrow*ncol*(ncol+1);
        
    case 'corr'
        
        count = 2*nrow*ncol*(ncol+1);
        
    case 'diff'
        
        count = (nrow-1)*ncol;
        
    case {'log','log10','log2','reallog','exp','sqrt','sin','cos','tan','asin','acos','atan'}
        
        count = nrow*ncol;
        
    case 'chol'
        
        count = round(nrow^3/3 + nrow^2/2 + nrow/6); 
        
    case 'lu'
        
        count = round(2/3*nrow^3); 
        
    case 'qr'
        
        count = round(2*nrow*ncol^2);
        
    case 'svd'
        
        count = round(2*nrow*ncol^2 + 2*ncol^3);
        
    case 'inv'
        
        % It is believed that inversion takes round(2/3*nrow^3) FLOPS; 
        count = round(2*nrow^3); 
        
    case 'det'
        
        count = round(2/3*nrow^3); 
        
    otherwise
        
        count = 0;
        
end
new_flop = flop_counter + count;
end

function [opt_list,expt_list] = readrules(filename)
fid = fopen(filename);
vecASCII = fread(fid,Inf,'*uint8');

% Ideally, the codes contain new-line markers (10) and return markers (13).
% The codes can also correctly displayed in Notepad. However, occasionally,
% codes only have new-line markers (10) without return markers (13). Such
% file will display as a single line in Notepad.
try
    if ~isempty(find(vecASCII==13,1))
        vecASCII = [13;10; vecASCII ; 13;10];
        ENTER_KEY = find(vecASCII==13);
        nline = length(ENTER_KEY) - 1;
        TXT = cell(nline,1);
        for m = 1:nline
            val = vecASCII(ENTER_KEY(m)+2:ENTER_KEY(m+1)-1)';
            TXT{m} = char(val);
        end
    else
        vecASCII = [10; vecASCII ; 10];
        ENTER_KEY = find(vecASCII==10);
        nline = length(ENTER_KEY) - 1;
        TXT = cell(nline,1);
        for m = 1:nline
            val = vecASCII(ENTER_KEY(m)+1:ENTER_KEY(m+1)-1)';
            TXT{m} = char(val);
        end
    end
    TXT = TXT(2:end);
    
catch
    % If the above algorithm fails, try to use text scan
    if nline <= 1
        TXT = textscan(fid,'%s','Delimiter','\n');
        fclose(fid);
        TXT = TXT(2:end);
        if size(TXT,1) == 1
            TXT = TXT{1};
        end
        nline = size(TXT,1);
        if nline <= 1
            opt_list = {};
            expt_list = {};
            warning('The ExtendedRules.txt contains no formula')
            return
        end
    end
end

% Close the file
fclose(fid);

opt_list = {};
expt_list = {};
for i = 1: length(TXT)
    if ismember(TXT{i},{''})
        continue
    end
    words = strtrim(strsplit(char(TXT{i}),' . '));
    opt_list = [opt_list,words(1)];
    expt_list = [expt_list,words(2)];
end
end
