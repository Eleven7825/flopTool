% Copyright (c) 2020 Shiyi Chen and Leonardo T. Rolla
% You can use, modify and redistribute this program under the terms of
% the GNU Lesser General Public License, either version 3 of the License, 
% or any later version.


function flop_script(nametxt)
% take the signiture as parameter, create two script. 
% for example, example.m contains a funtion called example with parameter
% A, B, C, D. Them the signiture is 'example(A,B,C,D)'. If it isn't a
% function then the signiture should be 'example'.
% The first script Copy.m is a script to get the imformation about
% variables, the second script calculate the flops in total

fprintf('Begin generating flop count script for %s ...',nametxt)

% Create the names
if ~isempty(strfind(nametxt,'.m'))
    fileName_tmp = [nametxt(1:end-2),'_tmp'];
else
    fileName_tmp = [nametxt,'_tmp'];
end   

% create a cell containing each line of the code
TXTcell = readText(nametxt);

% dertermine whether the original file is a function or a script
emptNum = 0;
comNum = 0;
firstFunloc = 0;
for n = 1:length(TXTcell)
    expt = char(TXTcell{n});
    TXTlist = strsplit(strtrim(char(TXTcell{n})));
    if isempty(char(strtrim(TXTcell{n})))
        emptNum = emptNum + 1;
        continue
    end
    
    start = char(TXTlist(1));
    if start(1) == '%'
        comNum = comNum + 1;
        continue
    end

    % Delete the comment at the end of the line
    comloc = [strfind(expt,'%'),strfind(expt,'#')];
    if ~isempty(comloc)
        if ~isBetPr(expt,'%') && ~isBetPr(expt,'#') 
            firstcom = min(comloc);
            expt = expt(1:firstcom-1);
            TXTcell{n} = expt;
        end
    end    

    if ismember('function',TXTlist)
        firstFunloc = n;
        break
    end
end 
  
if firstFunloc-1 == emptNum+comNum
    isfun = true;
else
    isfun = false;
end

% make a copy of the TXTcell
new_TXTcell = TXTcell;
Nlines = 0;

% rewrite the TXTcell, generate a new text cell--new_TXTcell
for n = 1:length(TXTcell)
    expt = char(TXTcell{n});
    TXTlist = strsplit(strtrim(char(TXTcell{n})));
    % Jump the empty line
    if isempty(char(strtrim(TXTcell{n})))
        continue
    end
    
    % Jump the comment
    start = char(TXTlist(1));
    if  start(1) == '%'
        continue
    end
      
    
    % try to call the fpExpt function, if any error occures,display the
    % warning, keep the program running
    try
        [add,warning] = fpExpt(expt);
    catch
        fprintf('\n warning: in line %d: unrecognised pattern.\n',n)
        continue
    end
    
    try
        if ~isempty(warning)
            warning = char(warning);
            warn = ['Warning: in line ',num2str(n), ', ',warning,'\n\n'];
            fprintf(warn)
        end
    catch
        fprintf('\n warning: error occures at line %d, continue analyzing...\n',n)
    end
    
    % If the header is 'function', delare flop_counter as global variable
    if ismember('function',TXTlist)
        
        % if the file is function, set flop_counter to be zero at first
        % function.
        if isfun && (n == firstFunloc)
            funexpt = TXTcell{n};
            new_TXTcell{n} = strrep(funexpt,nametxt,fileName_tmp);
            hnew_TXTcell = new_TXTcell.';
            new_TXTcell = {hnew_TXTcell{1:n+Nlines},{'global flop_counter'},...
                hnew_TXTcell{n+Nlines+1:end}}.';
            Nlines = Nlines + 2;
            
            % Delare flop_counter as a global variables for functions other than
            % first.
        else
            hnew_TXTcell = new_TXTcell.';
            new_TXTcell = {hnew_TXTcell{1:n+Nlines},{'global flop_counter'},...
                hnew_TXTcell{n+Nlines+1:end}}.';
            Nlines = Nlines + 1;
        end
    end
    % add the flop count formulas before the command
    hnew_TXTcell = new_TXTcell.';
    
    try
        new_TXTcell = {hnew_TXTcell{1:n+Nlines-1},add{1:end},hnew_TXTcell{n+Nlines:end}}.';
        Nlines = Nlines + length(add);
    catch
        fpritnf("\nwarning: can't add the flop count formulas.\n")
        continue
    end
    
end

% if the file is a not function, set flop_counter to be zero
if ~isfun
    new_TXTcell = [{'global flop_counter'};new_TXTcell];
end

% add comment
new_TXTcell = [{'% This file was generated automatically by flop_script.m.'};
{'% It is not a good idea to edit it directly as it will be overwritten later.'};
{''};new_TXTcell];


% write the cell to a .m script
fileID = fopen([fileName_tmp,'.m'],'w');
for m = 1:length(new_TXTcell)
    expt = char(new_TXTcell{m});
    fprintf(fileID,'%s\n',expt);
end
fclose(fileID);
fprintf('done!\n')
end


function [addcell,warning] = fpExpt(expt)

% generate flops count formula for each line
% - input: the command line(type:list): expt
%         
% - return: A string cell containing all flops count forumla
%           Type: cell
%           display warning message on command window
%           if variable is not found

addcell = {};
warning = '';
expt = char(expt);
tran = char("'");
Tran = char(".'");

% detect the number of the blank space before the expression
blk = '';
for i = 1:length(expt)
    chr = expt(i);
    if strcmp(chr,' ')
        blk = [blk,chr];
    else
        break
    end
end

% Load extended rules in the EXCEL file ExtendedRules.xlsx
try
    [Newopt,Newexpt]=readrules('ExtendedRules.txt');
catch
    Newopt = {};
end
    

OperationCell_1 = {'^','.^','*','.*','/','./','\','.\','+','-'};
OperationCell_2 = {'sum','prod','cumsum','cumprod','mean','std','cov'...
    'var','corr','diff','log','log10','log2','reallog','exp','sqrt','sin',...
    'cos','tan','asin','acos','atan','chol','lu','qr','svd','inv','det'};

if ~isempty(Newopt)
    try
        for index = 1:length(Newexpt)
            expt_1 = Newexpt{index};
            for i = 1:length(expt)
                chara = expt(i);
                if isletter(chara) || ~isnan(str2double(chara)) || strcmp(chara,'_') || strcmp(chara,'.')
                    continue
                else
                    expt_1(i) = ' ';
                end
            end
            wordlist = strsplit(expt_1);
            if ismember('ncol1',wordlist) || ismember('ncol2',wordlist) || ismember('nrow1',wordlist)||ismember('nrow2',wordlist)
                OperationCell_1 = [OperationCell_1, Newopt(index)];
                
            else
                OperationCell_2 = [OperationCell_2, Newopt(index)];
            end
        end
    catch
        fprintf('please check the new rule.\n');
    end
end
    
astp = strtrim(expt);
if isempty(expt)
    return
end

if strcmp(astp(1), '%')
    return
end

expt1 = expt;
for i = 1:length(expt)
    chr = expt(i);
    % replace with blank space if non alphanumeric or underscore
    if isletter(chr) || ~isnan(str2double(chr)) || strcmp(chr,'_') || (strcmp(chr,'.')&&~ismember(char(expt(i:i+1)),OperationCell_1))
        continue
    else
        expt1(i) = ' ';
    end
end
varNames = strsplit(expt1);
    
% loop examing OperationCell_2
for i = 1:length(OperationCell_2)
    Operation = char(OperationCell_2{i});
    len = length(Operation);
    OpLocList = strfind(expt,Operation);
    % If there is no such sign in the expression, continue
    if isempty(OpLocList)
        continue
    end
    
    % If the operation is between two primes, continue
    if isBetPr(expt,Operation)
        continue
    end
    
    % get the the variable
    for indx = 1:length(OpLocList)
        OpLoc = OpLocList(indx);
        
        if expt(OpLoc+len) ~= '('
            continue
        end
        
        if strcmp(expt(OpLoc-1),'a')
            continue
        end
        
        rbrakloc = findbrak(expt,'right',OpLoc+len);
        
        var = expt(OpLoc+len:rbrakloc);
        var1 = var;
        var2 = var;        
        
        % formulate the flop count formula
        cmd = [blk,...
            sprintf('flop_counter = flop_update("%s",%s,%s,flop_counter);',...
            Operation,var1,var2)];
        addcell = [{cmd};addcell];
    end
end

% recognize the operators fom first ten of the OperationCell, this is a 
% loop examing OperationCell_1

for i = 1 : length(OperationCell_1)
    Operation = char(OperationCell_1{i});
    len = length(Operation);
    OpLocList = strfind(expt,Operation);
    % If there is no such sign in the expression, continue
    if isempty(OpLocList)
        continue
    end
    
%     % If the operation is between two primes, continue
%     if isBetPr(expt,Operation)
%         continue
%     end
    
    
    % get the left and right side of the variable
    for indx = 1:length(OpLocList)
        cmd = '';
        OpLoc = OpLocList(indx);
        
        % some machanism to jump the ".", makes the '.\','.*' operation
        % possible
        if strcmp(expt(OpLoc-1),'.')
            continue
        end        
        
        % remove the spaces around the operators
        while isspace(expt(OpLoc-1))
            expt = [expt(1:OpLoc-2),expt(OpLoc:end)];
            OpLocList = strfind(expt,Operation);
            OpLoc = OpLocList(indx);
        end
        
        while isspace(expt(OpLoc+len))
            OpLocList = strfind(expt,Operation);
            OpLoc = OpLocList(indx);
            expt = [expt(1:OpLoc),expt(OpLoc+2:end)];
        end
        
        % get the left operator
        var1 = '';
        
        % for transpose sign
        transpose = false;
        Transpose = false;
        if OpLoc-3>= 1
            if strcmp(expt(OpLoc-2:OpLoc-1),Tran)
                OpLoc = OpLoc - 2;
                Transpose = ture;
            end
        end
        
        if OpLoc-2 >=1
            if strcmp(expt(OpLoc-1), tran) && ~strcmp(expt(OpLoc-2:OpLoc-1),Tran)               
                OpLoc = OpLoc - 1;
                transpose = true;
            end
        end

        % for [somemat]*somevar
        if expt(OpLoc-1) == ']'
            lbrakloc = findbrak(expt,'left',OpLoc-1); 
            var1 = expt(lbrakloc:OpLoc-1);
               
        % For somevariable(1,2:3)*anothervariable or (somevar)*anothervar
        elseif expt(OpLoc-1) == ')'              
            lbrakloc = findbrak(expt,'left',OpLoc-1);
            var1 = expt(lbrakloc : OpLoc-1);
            % search for the variable name
            startloc = lbrakloc - 1;
            varname1 = readName(expt,varNames,startloc,'left');
            var1 = [varname1,var1];
        
        
        % For onevariable*anothervariable
        elseif ~strcmp(expt(OpLoc-1),tran) 
            startloc = OpLoc - 1;
            var1 = readName(expt,varNames,startloc,'left');   
        end
        
        if transpose
            var1 = [var1, tran];
            OpLoc = OpLoc + 1;
        
        elseif Transpose
            var1 = [var1,Tran];
            OpLoc = OpLoc + 2;
        end
        
        if isempty(var1)
            warning = sprintf("can't find left variable around '%s' in position %d, assigning value 1 to it.",Operation,OpLoc);
            var1 = '1';
        end
        
        % get the right variable
        var2 = '';
        
        % for somevar*[somemat]
        if expt(OpLoc+len) == '['
            rbrakloc = findbrak(expt,'right',OpLoc+len);
            var2 = expt(OpLoc+len:rbrakloc);

        % FOR somevariable*(anothervariable)
        elseif expt(OpLoc+len) == '('
            rbrakloc = findbrak(expt,'right',OpLoc+1);
            var2 = expt(OpLoc+len:rbrakloc);
              
        else
        % for anothervar * onevariable or anothervar*onevar(:)
        var2 = readName(expt,varNames,OpLoc+len,'right');
        end
        
       
        % for onevar*onevarible(1:10)
        newloc = OpLoc+len+length(var2);
        if newloc <= length(expt)
            if expt(newloc) == '('
                rbrakloc = findbrak(expt,'right',newloc);
                var2 = expt(OpLoc+len:rbrakloc);
            end
        end
        
        % for onevar*onevariable(1:10).'
        newloc = OpLoc+len+length(var2);
        
        if newloc+1 <=length(expt)
            if strcmp(expt(newloc:newloc+1),Tran)
                var2 = [var2,Tran];
            end
        end
        
        if newloc <=length(expt)
            if strcmp(expt(newloc),tran) && ~strcmp(expt(newloc:newloc+1),Tran)
                var2 = [var2,tran];
            end
        end     
        
        % If nothing find
        if isempty(var2)
            warning = sprintf("can't find right variable around '%s' in position %d, assigning value 1 to it.",Operation,OpLoc);
            var2 = '1';
        end

        % formulate the flop count formula
        cmd = [blk,sprintf('flop_counter = flop_update("%s",%s,%s,flop_counter);',Operation,var1,var2)];
        addcell = [addcell(1:end);{cmd}];
    
        % add the middle opperation into the varNames
        if strcmp(Operation,'.^') || strcmp(Operation, '^') || strcmp(Operation,'*') || ...
                strcmp(Operation,'.*') || strcmp(Operation, '/')||strcmp(Operation,'./')||...
                strcmp(Operation,'\')||strcmp(Operation, './')
            leftlen = length(var1);
            rightlen = length(var2);
            expt = [expt(1:OpLoc - leftlen-1),'(',expt(OpLoc - leftlen:...
                OpLoc+rightlen+len-1),')',expt(OpLoc+rightlen+len:end)];
            OpLocList = strfind(expt,Operation);
        end       
    end
end

function name = readName(expt,varNames,startloc,direction)

% find the variable name in a string
% input: - expt: the command line without blankspace between operators(string)
%        - varNames: a cell containing all potential varibles (cell)
%        - startloc: the start location in the string for searching
%           (double)
%        - direction: either search from left or right (string: 'left' or 'right')

% output:
%        - name: the name of the variable in string needed to be searching
%        (string)

name = '';
% If searching is from left to right
if strcmp(direction,'right')
    contain = true;
    txloc = startloc;
    while contain && txloc <= length(expt)
        
        if expt(startloc) == '('
            break
        end
        
        searchtxt = expt(startloc:txloc);
        if ismember(searchtxt,varNames)
            name = searchtxt;
        end
        
        txloc = txloc +1;
        if txloc == length(expt) +1
            break
        end
        
        for j = 1:length(varNames)
            varName = varNames{j};
            if ~isempty(strfind(varName,expt(startloc:txloc)))
                contain = true;
                break
            end
            contain = false;
        end
    end
end

% if start from left to right
if strcmp(direction,'left')
    contain = true;
    txloc = startloc;
    while contain && txloc>=1 
        if expt(startloc) == ')'
            break
        end
        searchtxt = expt(txloc:startloc);
        if ismember(searchtxt,varNames)
            name = searchtxt;
        end
        
        txloc = txloc - 1;
        if txloc == 0
            break
        end
        
        for j = 1:length(varNames)
            varName = varNames{j};
            if ~isempty(strfind(varName,expt(txloc:startloc)))
                contain = true;
                break
            end
            contain = false;
        end
    end
end

end
function tgtloc = findbrak(expt,dirct,loc)
% find coresponding bracket location using giving direction, location and
% expression

% assign the step according to the step
% input: 
%       - expt: string
%       - dirt: searching direction "left" or "right"
%       - loc: the location of bracket.

% output:
%       - tgtlc: the location of the targeting bracket

brak = expt(loc);
switch brak
    case '(';           tgtbrak = ')';
    case '[';           tgtbrak = ']';
    case '{';           tgtbrak = '}';
    case ')';           tgtbrak = '(';
    case '}';           tgtbrak = '{';
    case ']';           tgtbrak = '[';
    otherwise
        tgtloc = loc;
        warning('Unknow bracket')
        return
end

flag = 0;
brakList = strfind(expt,brak);
tgtbrakList = strfind(expt,tgtbrak);

%search for the right bracket
switch dirct
    case 'right'
        for txloc = loc:length(expt)
            if ismember(txloc, brakList)
                flag = flag - 1;
            end
            
            if ismember(txloc,tgtbrakList)
                flag = flag + 1;
            end
            
            if flag == 0
                tgtloc = txloc;
                break
            end
        end
        
    case 'left'
        for txloc = loc:-1:1
            if ismember(txloc, brakList)
                flag = flag - 1;
            end
            
            if ismember(txloc,tgtbrakList)
                flag = flag + 1;
            end
            
            if flag == 0
                tgtloc = txloc;
                break
            end
        end   
        
    otherwise
        tgtloc = loc;
        warning('Unknow direction')
        return
end
end
end

function boo = isBetPr(expt,Operation)
% Pass an expression,
% determine whether the operator sign is between primes or not
% input: 
%       - expt: stirng
%       - Operation: string
%output:
%       - boo: false or true boolean

%create location lists of ' " and the operator

prlist = strfind(expt, "'");
Prlist = strfind(expt, '"');
Oplist = strfind(expt, Operation);
in_prime = [];
in_pr = false;
in_Pr = false;

if mod(length(prlist),2) == 1
    boo = false;
    return
end

if mod(length(Prlist),2) == 1
    boo = false;
    return
end

for i = 1:length(expt)
    if ismember(i,prlist)
        in_pr = ~in_pr;
        continue
    end
    
    if ismember(i,Prlist) 
        in_Pr = ~in_Pr;
        continue
    end
    
    if in_Pr || in_pr
        in_prime = [in_prime,i];
    end   

end   

for i = 1:length(Oplist)
    Op = Oplist(i);
    if ismember(Op,in_prime)
        boo = true;
        break
    end
    boo = false;
end
end




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

function TXT = readText(fileName)
%readText Scan a text file and load the contents in a cell array.
%
% Syntax:
%
%   TXT = readText(fileName)
%
% Description:
%
%   By partial matching the file name in the current folder, the program
%   scans the text and then load the contents in a cell array. Each cell
%   element contains a line of codes. If there are multiple matches, MATLAB
%   codes take the priority, followed by the TXT file.
%
% Input Arguments:
%
%   fileName - A string that specifies the MATLAB file name.
%              It can be a full name with extension, or a partial name.
%
% Output Arguments:
%
%   TXT -  a n-by-1 cell array that contains each line of the codes.
%
% Written by Hang Qian
% Contact: matlabist@gmail.com


if ~ischar(fileName)
    error('File name must be a string.')
end

% Open the file
if ~isempty(strfind(fileName,'.'))
    % File name contains an extension, thus no ambiguity
    fid = fopen(fileName,'r');
else
    % Search current folder to match the file name
    % Partial match is supported
    listing = dir;
    nameAIO = {listing(:).name}';
    mask = strncmp(nameAIO,fileName,length(fileName));
    nmatch = sum(mask);
    if nmatch == 0
        mask = strncmpi(nameAIO,fileName,length(fileName));
        nmatch = sum(mask);
    end
    
    switch nmatch
        case 0
            % It works when fileName contains full path without extension
            fid = fopen([fileName,'.m'],'r');
            if fid == -1
                fid = fopen([fileName,'.txt'],'r');
            end
        case 1
            % Successful match
            nameAIOcut = nameAIO(mask);
            fid = fopen(nameAIOcut{1},'r');
        otherwise
            % Multiple match: MATLAB file takes priority and then txt file
            nameAIOcut = nameAIO(mask);
            maskMATLAB = strcmp(nameAIOcut(max(1,end-1):end),'.m');
            if any(maskMATLAB)
                nameAIOcut = nameAIOcut(maskMATLAB);
            else
                maskTXT = strcmp(nameAIOcut(max(1,end-3):end),'.txt');
                if any(maskTXT)
                    nameAIOcut = nameAIOcut(maskTXT);
                end
            end
            fid = fopen(nameAIOcut{1},'r');
    end
end

if fid == -1
    error('Unable to open the file.')
end

% Read MATLAB codes
vecASCII = fread(fid,Inf,'*uint8');

% Ideally, the codes contain new-line markers (10) and return markers (13).
% The codes can also correctly displayed in Notepad. However, occasionally,
% codes only have new-line markers (10) without return markers (13). Such
% file will display as a single line in Notepad.
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

% If the above algorithm fails, try to use text scan
if nline <= 1
    TXT = textscan(fid,'%s','Delimiter','\n');
    if size(TXT,1) == 1
        TXT = TXT{1};
    end
    nline = size(TXT,1);
    if nline <= 1
        warning('Unable to read the text in the file.')
    end
end

% Close the file
fclose(fid);
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
        TXT = TXT(2:end);
        if size(TXT,1) == 1
            TXT = TXT{1};
        end
        nline = size(TXT,1);
        if nline <= 1
            opt_list = {};
            expt_list = {};
            warning('The ExtendedRules.txt contains no formula')
            fclose(fid);
            return
        end
    end
end

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

% Close the file
fclose(fid);
end
