clear all;
load('test1.mat');

test_seconds = 600;
picture_seconds = 10;
poor_radis = 20;
best_radis = 10;
neigh_max = 20;
test_duration = test_seconds*100;   %this is 600s
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


% j = 0;
% for i = 1:100
%     radis_ideal_neigh = pdist([coordinate_x(i),coordinate_y(i);coordinate_x(target_addr),coordinate_y(target_addr)]);
%     if (radis_ideal_neigh < poor_radis) && (i ~= target_addr)
%         j = j + 1;
%         ideal_neigh(j,1) = i;
%         ideal_neigh(j,2) = radis_ideal_neigh;
%     end
% end
% [Y, I] = sort(ideal_neigh(:,2), 'ascend');
% ideal_neigh_sort = ideal_neigh(I,:);

