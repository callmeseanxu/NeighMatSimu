function y = bitcount(x)
    d = double(x);
    [crap,e] = log2(max(d));
    y = sum(rem(floor(d*pow2(1-max(1,e):0)),2));

%     y = 0;
%     for i = 1:16
%         if bitand(x, uint16(1)) > 0
%             y = y + 1;
%         end
%         x = bitsra(x, 1);
%     end

%     if x < 0
%         y = 0;
%     elseif x > 65535
%         y = 16;
%     else
%         c = uint16(0);
%         c = uint16(x) - bitand(bitsra(uint16(x), 1), uint16(21845));
%         c = bitand(bitsra(c, 2), uint16(13107)) + bitand(c, uint16(13107));
%         c = bitand((bitsra(c, 4) + c), uint16(3855));
%         c = bitand((bitsra(c, 8) + c), uint16(255));
%         if (c>15) 
%             c = 15;
%         end
%         y = c;
%     end
