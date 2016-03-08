clear all;
load('test1.mat');

poor_radis = 20;
best_radis = 10;
neigh_max = 20;
test_duration = 10000;   %this is 100s
target_addr = 65;
best_neigh_limit = 10;

neigh_count = zeros([1 100]);
for i = 1:100
    for j = 1:100
        if i ~= j
            x = pdist([coordinate_x(i),coordinate_y(i);coordinate_x(j),coordinate_y(j)]);
            if x < poor_radis
                neigh_count(i) = neigh_count(i) + 1;
            end
        end
    end
end

hb_time = round(rand([1 100])*100);

%predefine th size
neigh_table(100,neigh_max).addr = 0;
neigh_table(100,neigh_max).last_seen = 0;
neigh_table(100,neigh_max).linkq = uint16(0);

neigh_table_d(100,neigh_max).addr = 0;
neigh_table_d(100,neigh_max).linkq = uint16(0);

for i = 1:100
    for j = 1:neigh_max
        neigh_table(i,j).addr = 0;
        neigh_table(i,j).last_seen = 0;
        neigh_table(i,j).linkq = uint16(0);
    end
end

for test_frame = 1:test_duration
    for node = 1:100
        if test_frame == hb_time(node)
            %fire a heart beat, check if neighbor heard this
            for othernode = 1:100
                if othernode ~= node
                    x = pdist([coordinate_x(othernode),coordinate_y(othernode);coordinate_x(node),coordinate_y(node)]);
                    if x < poor_radis
                        %this hb may be heart, make neigh
                        %table update
                        oldest_index = 0;
                        first_inactive = 0;
                        for neigh_index = 1:neigh_max
                            if(first_inactive == 0) && (neigh_table(othernode, neigh_index).addr ==0)
                                first_inactive = neigh_index;
                            end
                            
                            if (oldest_index == 0) || (neigh_table(othernode, neigh_index).last_seen < neigh_table(othernode, oldest_index).last_seen)
                                oldest_index = neigh_index;
                            end
                            
                            if node == neigh_table(othernode, neigh_index).addr
                                break
                            end
                        end
                        rand_num = round(rand(1)*poor_radis);
                        %if (x < best_radis) || (rand_num > (x - best_radis))
                        if rand_num > x
                            if neigh_index < neigh_max
                                neigh_table(othernode, neigh_index).linkq = neigh_table(othernode, neigh_index).linkq*2 + 1;
                                if neigh_table(othernode, neigh_index).linkq > 2^16
                                    neigh_table(othernode, neigh_index).linkq = neigh_table(othernode, neigh_index).linkq - 2^16;
                                end
                            else
                                if first_inactive == 0      %this means table is full
                                    neigh_table(othernode, oldest_index).addr = node;
                                    neigh_table(othernode, oldest_index).last_seen = test_frame;
                                    neigh_table(othernode, oldest_index).linkq = 1;
                                else
                                    neigh_table(othernode, first_inactive).addr = node;
                                    neigh_table(othernode, first_inactive).last_seen = test_frame;
                                    neigh_table(othernode, first_inactive).linkq = 1;                                    
                                end
                            end
                        else
                            if neigh_index < neigh_max
                                if(neigh_table(othernode, neigh_index).linkq >= 1)
                                    neigh_table(othernode, neigh_index).linkq = neigh_table(othernode, neigh_index).linkq*2;
                                    if neigh_table(othernode, neigh_index).linkq > 2^16
                                        neigh_table(othernode, neigh_index).linkq = neigh_table(othernode, neigh_index).linkq - 2^16;
                                    end
                                end
                            end
                        end
                    else
                        %need not to do anything, could not hear this hb
                        %no code here
                    end
                end                
            end
            hb_time(node) = hb_time(node) + 100 + round(rand(1)*10);
        end
    end
    if rem(test_frame, 500) == 0
        %predefine th size

for i = 1:100
    for j = 1:neigh_max
        d = double(neigh_table(i,j).linkq);
        [crap,e] = log2(max(d));
        neigh_table_d(i,j).linkq = sum(rem(floor(d*pow2(1-max(1,e):0)),2));
        neigh_table_d(i,j).addr = neigh_table(i,j).addr;
    end
end

j = 0;
for i = 1:neigh_max
    if neigh_table_d(target_addr,i).addr > 0
        j = j + 1;
        neigh_target(j,1) = neigh_table_d(target_addr,i).addr;
        neigh_target(j,2) = neigh_table_d(target_addr,i).linkq;
    end
end

group = zeros([1 100]);
[Y, I] = sort(neigh_target(:,2), 'descend');
neigh_target_sort = neigh_target(I,:);

%group 0 is all
%group 1 is within range
%group 2 is in neigh table
%group 3 is best neigh
%group 4 is self
for i = 1:length(neigh_target)
    group(neigh_target(i,1)) = 2;
end

if length(neigh_target) > best_neigh_limit
    for i = 1:best_neigh_limit
        group(neigh_target_sort(i,1)) = 3;
    end
end

for i = 1:100
    if(pdist([coordinate_x(target_addr),coordinate_y(target_addr);coordinate_x(i),coordinate_y(i)]) < poor_radis)
        if group(i) == 0
            group(i) = 1;
        end
    end
end

group(target_addr) = 4;
gscatter(coordinate_x, coordinate_y, group,'kmgrb','xosdp');
title(num2str(test_frame));

filename = sprintf(num2str(test_frame));
filename = regexprep(filename,':','-','all');
print('-dpng','-zbuffer','-r200',filename);
length(neigh_target)
        
    end
end


