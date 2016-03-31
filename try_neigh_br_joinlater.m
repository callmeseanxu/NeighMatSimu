clear all;
load('test1.mat');

test_seconds = 2000;
picture_seconds = 5;
poor_radis = 40;
best_radis = 10;
neigh_max = 10;
test_duration = test_seconds*100;   %this is 600s
target_addr = 65;
best_neigh_limit = 10;
mutual_best_num = 5;
later_join_addr = 65;
later_join_seconds = 501;
debug_addr = 0;

hb_time = round(rand([1 100])*100);
last_hb_time = zeros([1 100]);
hb_count = zeros([1 100]);

%predefine th size
neigh_table(100,neigh_max).addr = 0;
neigh_table(100,neigh_max).last_seen = 0;
neigh_table(100,neigh_max).linkq = 0;

neigh_table_d(100,neigh_max).addr = 0;
neigh_table_d(100,neigh_max).linkq = 0;

neigh_table_addr = zeros(100,neigh_max);

for i = 1:100
    for j = 1:neigh_max
        neigh_table(i,j).addr = 0;
        neigh_table(i,j).last_seen = 0;
        neigh_table(i,j).linkq = 0;
        neigh_table(i,j).extra_score = 0;
        neigh_table(i,j).protection_time = 0;
    end
end

neigh_match_count = zeros(1,test_seconds/picture_seconds);
neigh_match_gt_count = zeros(1,test_seconds/picture_seconds);

node_distance = zeros([100 100]);
for i = 1:100
    for j = 1:100
        node_distance(i,j) = pdist([coordinate_x(i),coordinate_y(i);coordinate_x(j),coordinate_y(j)]);
    end
end

ideal_best_count = 0;
for i = 1:100
    if (node_distance(i, later_join_addr) < best_radis) && (i ~= later_join_addr)
        ideal_best_count = ideal_best_count + 1;
    end
end

ideal_poor_count = 0;
for i = 1:100
    if (node_distance(i, later_join_addr) < poor_radis) && (i ~= later_join_addr)
        ideal_poor_count = ideal_poor_count + 1;
    end
end

%later join target fire first heartbeat after whole system get stable
hb_time(later_join_addr) = later_join_seconds*100;

later_join_ground_truth = zeros([1 1]);
later_join_ideal_neigh_total = 0;
for target_addr = 1:100
    j = 0;
    ideal_neigh = zeros([2 1]);
    for i = 1:100
        radis_ideal_neigh = node_distance(i, target_addr);
        if (radis_ideal_neigh < poor_radis) && (i ~= target_addr)
            j = j + 1;
            ideal_neigh(j,1) = i;
            ideal_neigh(j,2) = radis_ideal_neigh;
        end
    end

    [~, I] = sort(ideal_neigh(:,2), 'ascend');
    ideal_neigh_sort = ideal_neigh(I,:);

    neigh_match_count = 0;
    neigh_max_compare = min(length(ideal_neigh_sort(:,1)),neigh_max);
    for i = 1:neigh_max_compare
        if ideal_neigh_sort(i,1) == later_join_addr;
            later_join_ideal_neigh_total = later_join_ideal_neigh_total + 1;
            later_join_ground_truth(later_join_ideal_neigh_total) = target_addr;
        end
    end
end

for test_frame = 1:test_duration
    for node = 1:100
        if test_frame == hb_time(node)
            %fire a heart beat, check if neighbor heard this
            for othernode = 1:100
                if (othernode ~= node)
                    if((othernode == later_join_addr) && (test_frame < later_join_seconds*100))
                        continue;
                    end

                    x = node_distance(othernode,node);
                    if x < poor_radis
                        %this hb may be heart, make neigh
                        %table update
                        worst_index = 0;
                        first_inactive = 0;
                        found_in_neigh_table = 0;
                        protection_neigh_count = 0;
                        for neigh_index = 1:neigh_max
                            if(first_inactive == 0) && (neigh_table(othernode, neigh_index).addr == 0)
                                first_inactive = neigh_index;
                            end

                            if (neigh_table(othernode, neigh_index).protection_time <= 0) && ((worst_index == 0) || ((bitcount(neigh_table(othernode, neigh_index).linkq) + neigh_table(othernode, neigh_index).extra_score) < (bitcount(neigh_table(othernode, worst_index).linkq) + neigh_table(othernode, worst_index).extra_score)))
                                worst_index = neigh_index;
                            end
                            
                            if neigh_table(othernode, neigh_index).protection_time > 0
                                protection_neigh_count = protection_neigh_count + 1;
                            end

                            if node == neigh_table(othernode, neigh_index).addr
                                found_in_neigh_table = 1;
                                break
                            end
                        end
                        rand_num = round(rand(1)*poor_radis);
                        %if (x < best_radis) || (rand_num > (x - best_radis))
                        if rand_num > x
                            if found_in_neigh_table > 0
                                neigh_table(othernode, neigh_index).linkq = neigh_table(othernode, neigh_index).linkq*2 + 1;
                                if neigh_table(othernode, neigh_index).linkq >= 65536
                                    neigh_table(othernode, neigh_index).linkq = neigh_table(othernode, neigh_index).linkq - 65536;
                                end
                                if(neigh_table(othernode, neigh_index).protection_time > 0)
                                    neigh_table(othernode, neigh_index).protection_time = neigh_table(othernode, neigh_index).protection_time - 1;
                                    if neigh_table(othernode, neigh_index).protection_time == 0
                                        neigh_table(othernode, neigh_index).extra_score = 0;
                                    end
                                end
                            else
                                if first_inactive == 0      %this means table is full
                                    if protection_neigh_count < neigh_max
                                        neigh_table(othernode, worst_index).addr = node;
                                        neigh_table(othernode, worst_index).last_seen = test_frame;
                                        neigh_table(othernode, worst_index).linkq = 1;
                                        neigh_table(othernode, worst_index).extra_score = 0;
                                        neigh_table(othernode, worst_index).protection_time = 16;
                                    end
                                else
                                    neigh_table(othernode, first_inactive).addr = node;
                                    neigh_table(othernode, first_inactive).last_seen = test_frame;
                                    neigh_table(othernode, first_inactive).linkq = 1;
                                    neigh_table(othernode, first_inactive).extra_score = 0;
                                    neigh_table(othernode, first_inactive).protection_time = 16;
                                end
                            end
                        else
                            if found_in_neigh_table > 0
                                if(neigh_table(othernode, neigh_index).linkq >= 1)
                                    neigh_table(othernode, neigh_index).linkq = neigh_table(othernode, neigh_index).linkq*2;
                                    if neigh_table(othernode, neigh_index).linkq >= 65536
                                        neigh_table(othernode, neigh_index).linkq = neigh_table(othernode, neigh_index).linkq - 65536;
                                    end
                                end
                                
                                if(neigh_table(othernode, neigh_index).protection_time > 0)
                                    neigh_table(othernode, neigh_index).protection_time = neigh_table(othernode, neigh_index).protection_time - 1;
                                    if neigh_table(othernode, neigh_index).protection_time == 0
                                        neigh_table(othernode, neigh_index).extra_score = 0;
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
            last_hb_time(node) = hb_time(node);
            hb_time(node) = hb_time(node) + 100 + round(rand(1)*10);
            hb_count(node) = hb_count(node) + 1;
        end
        if (rem(hb_count(node), 16) == 15) && (test_frame == last_hb_time(node))
            if((node == later_join_addr) && (test_frame < later_join_seconds*100))
                continue;
            end
            if((node == later_join_addr) && (test_frame >= later_join_seconds*100))
                j = 0;
            end
            if((node == later_join_addr) && (test_frame >= 1900*100))
                j = 0;
            end
            %first, find best neighs
            j = 0;
            neigh_target = 0;
            for i = 1:neigh_max
                if neigh_table(node,i).addr > 0
                    j = j + 1;
                    neigh_target(j,1) = neigh_table(node,i).addr;
                    neigh_target(j,2) = bitcount(neigh_table(node,i).linkq);
                end
            end

            if j > 0
                [~, I] = sort(neigh_target(:,2), 'descend');
                neigh_target_sort = neigh_target(I,:);
                for brother_index = 1:min(mutual_best_num,length(neigh_target_sort(:,1)))
                    worst_index = 0;
                    least_extra_index = 0;
                    first_inactive = 0;
                    found_in_neigh_table = 0;
                    protection_neigh_count = 0;
                    for neigh_index = 1:neigh_max
                        if(first_inactive == 0) && (neigh_table(neigh_target_sort(brother_index,1), neigh_index).addr ==0)
                            first_inactive = neigh_index;
                        end
                        
                        if (neigh_table(neigh_target_sort(brother_index,1), neigh_index).protection_time <= 0) && ((worst_index == 0) || ((bitcount(neigh_table(neigh_target_sort(brother_index,1), neigh_index).linkq) + neigh_table(neigh_target_sort(brother_index,1), neigh_index).extra_score) < (bitcount(neigh_table(neigh_target_sort(brother_index,1), worst_index).linkq) + neigh_table(neigh_target_sort(brother_index,1), worst_index).extra_score)))
                            worst_index = neigh_index;
                        end
                        
                        if neigh_table(neigh_target_sort(brother_index,1), neigh_index).protection_time > 0
                            protection_neigh_count = protection_neigh_count + 1;
                        end
                            
                        if ((least_extra_index == 0) || (neigh_table(neigh_target_sort(brother_index,1), neigh_index).extra_score < neigh_table(neigh_target_sort(brother_index,1), least_extra_index).extra_score))
                            least_extra_index = neigh_index;
                        end
                        
                        if node == neigh_table(neigh_target_sort(brother_index,1), neigh_index).addr
                            found_in_neigh_table = 1;
                            break
                        end
                    end
                    
                    if found_in_neigh_table == 1
                        if brother_index  == 1
                            neigh_table(neigh_target_sort(brother_index,1), neigh_index).extra_score = 16;
                        else
                            neigh_table(neigh_target_sort(brother_index,1), neigh_index).extra_score = 8;
                        end
                        neigh_table(neigh_target_sort(brother_index,1), neigh_index).protection_time = 32;
                    else
                        if first_inactive == 0      %this means table is full
                            if protection_neigh_count < neigh_max
                                neigh_table(neigh_target_sort(brother_index,1), worst_index).addr = node;
                                neigh_table(neigh_target_sort(brother_index,1), worst_index).last_seen = test_frame;
                                neigh_table(neigh_target_sort(brother_index,1), worst_index).linkq = 1;
                                neigh_table(neigh_target_sort(brother_index,1), worst_index).protection_time = 32;
                                if brother_index  == 1
                                    neigh_table(neigh_target_sort(brother_index,1), worst_index).extra_score = 16;
                                else
                                    neigh_table(neigh_target_sort(brother_index,1), worst_index).extra_score = 8;
                                end
                            else
                                %means all neigh of this node need to keep
                                if brother_index == 1
                                    tmp_extra_score = 16;
                                else
                                    tmp_extra_score = 8;
                                end
                                
                                if tmp_extra_score > neigh_table(neigh_target_sort(brother_index,1), least_extra_index).extra_score
                                    neigh_table(neigh_target_sort(brother_index,1), least_extra_index).addr = node;
                                    neigh_table(neigh_target_sort(brother_index,1), least_extra_index).last_seen = test_frame;
                                    neigh_table(neigh_target_sort(brother_index,1), least_extra_index).linkq = 1;
                                    neigh_table(neigh_target_sort(brother_index,1), least_extra_index).protection_time = 32;
                                    neigh_table(neigh_target_sort(brother_index,1), least_extra_index).extra_score = tmp_extra_score;
                                end                                
                            end
                        else
                            neigh_table(neigh_target_sort(brother_index,1), first_inactive).addr = node;
                            neigh_table(neigh_target_sort(brother_index,1), first_inactive).last_seen = test_frame;
                            neigh_table(neigh_target_sort(brother_index,1), first_inactive).linkq = 1;
                            neigh_table(neigh_target_sort(brother_index,1), first_inactive).protection_time = 32;
                            if brother_index  == 1
                                neigh_table(neigh_target_sort(brother_index,1), first_inactive).extra_score = 16;
                            else
                                neigh_table(neigh_target_sort(brother_index,1), first_inactive).extra_score = 8;
                            end
                        end
                    end
                end
            end
        end
    end
    
    if rem(test_frame, picture_seconds*100) == 0
        %predefine the size
        if rem(test_frame, picture_seconds*100*10) == 0
            disp([' ongoing,  ' num2str(test_frame/100) ' sec ']);            
        end
        
        if rem(test_frame, picture_seconds*100*100) == 0
            disp([' ongoing,  ' num2str(test_frame/100) ' sec ']);            
        end
        
        later_join_neigh_count = 0;  
        for i = 1:later_join_ideal_neigh_total
            for j = 1:neigh_max
                if neigh_table(later_join_ground_truth(i),j).addr == later_join_addr
                    later_join_neigh_count = later_join_neigh_count + 1;
                end
            end
        end
        neigh_match_gt_count(1, test_frame/picture_seconds/100) = later_join_neigh_count; 
                
        later_join_neigh_count = 0;  
        for i = 1:100
            for j = 1:neigh_max
                if neigh_table(i,j).addr == later_join_addr
                    later_join_neigh_count = later_join_neigh_count + 1;
                end
            end
        end
        neigh_match_count(1, test_frame/picture_seconds/100) = later_join_neigh_count;
    end

    if rem(test_frame, picture_seconds*100*100) == 0
        plot(neigh_match_count(1:test_frame/picture_seconds/100));
        xlabel([' ideal best:  ' num2str(ideal_best_count) '  ideal poor:  ' num2str(ideal_poor_count) ' ']);
        print('-dpng','-zbuffer','-r200','match_count');
        
        plot(neigh_match_gt_count(1:test_frame/picture_seconds/100));
        xlabel([' ideal best:  ' num2str(ideal_best_count) '  ideal poor:  ' num2str(ideal_poor_count) ' ']);
        print('-dpng','-zbuffer','-r200','match_ground_truth_count');
    end
end

%save br_10_result neigh_match_percent mutual_match_percent neigh_best_match_percent mutual_best_match_percent mutual_five_match_percent neigh_table