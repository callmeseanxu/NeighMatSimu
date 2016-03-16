clear all;
load('test1.mat');

test_seconds = 500;
picture_seconds = 5;
poor_radis = 40;
best_radis = 10;
neigh_max = 10;
test_duration = test_seconds*100;   %this is 600s
target_addr = 65;
best_neigh_limit = 10;

neigh_present = zeros([test_seconds/picture_seconds, neigh_max]);

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

j = 0;
for i = 1:100
    radis_ideal_neigh = pdist([coordinate_x(i),coordinate_y(i);coordinate_x(target_addr),coordinate_y(target_addr)]);
    if (radis_ideal_neigh < poor_radis) && (i ~= target_addr)
        j = j + 1;
        ideal_neigh(j,1) = i;
        ideal_neigh(j,2) = radis_ideal_neigh;
    end
end
[Y, I] = sort(ideal_neigh(:,2), 'ascend');
ideal_neigh_sort = ideal_neigh(I,:);

show_frame = 0;
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
    
    if rem(test_frame, picture_seconds*100) == 0
        %predefine th size
        show_frame = show_frame + 1;
        missed_neigh_count = 0;
        for target_neigh_addr = 1:100
%             if(target_neigh_addr == 23)
%                 disp(['now process:' num2str(target_neigh_addr)]);
%             end
            find_target = 0;
            for i = 1:100
                for j = 1:neigh_max
                    if(target_neigh_addr == neigh_table(i,j).addr)
                        find_target = 1;
                        break
                    end
                end
                if find_target == 1
                    break
                end
            end
            if find_target == 0
                missed_neigh_count = missed_neigh_count + 1;
                missed_neigh_table(show_frame, missed_neigh_count) = target_neigh_addr;
            end
        end
    end
end

[a, b] = size(missed_neigh_table);
x = 1:a;
for i = 1:b
    scatter(x,missed_neigh_table(:,i),'.','LineWidth', 1.2)
    hold on
end

print('-dpng','-zbuffer','-r200','missed_neigh_view');