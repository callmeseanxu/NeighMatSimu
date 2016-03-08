function y = bitcount(x)
y = 0;
for i = 0 : 15
    if(x - 2^(15-i)) > 0
        x = x - 2^(15-i);
        y = y + 1;
    end
    
    if(x == 1)
        y = y + 1;
        break
    end
end
%if x == 1
%    y = y + 1;
%end