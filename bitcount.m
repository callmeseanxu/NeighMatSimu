function y = bitcount(x)
    d = double(x);
    [crap,e] = log2(max(d));
    y = sum(rem(floor(d*pow2(1-max(1,e):0)),2));