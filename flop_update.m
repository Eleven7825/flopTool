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
  ncol1 = size1(1);
  nrow1 = size1(2);
  ncol2 = size2(1);
  nrow2 = size2(2);
  nrow = nrow1;
  ncol = ncol1;

  
% Below code contains modified copyright work, please follow the
% liscence of original copyright owner.  
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