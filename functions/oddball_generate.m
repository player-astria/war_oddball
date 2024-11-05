function text_data = oddball_generate(~)
% generate a matrix of 5*50, which represents 5blocks and 50 trials, 0-9 
% represents target trials, 10-19 represents probes trials and 20-49 
% represents standard trials
clc;
clear;
text_data = zeros(5,225);

for i = 1:5 %block
n=1;
%45 probe
    for j = 1:5 % probe
        for k = 1:9 % probe_num

        text_data(i,n) = j*100+k*10+randi(9);
            n = n+1;
        end
    end

%45 target
    for n = 45:90
        text_data(i,n) = 600;
    end

%135 disrtactor
    for k = 1:15 % 15 repeated
        for j = 1:9 % 9 num
        text_data(i,n) = 6*100+j;
        n = n+1;
        end
    end
idx = randperm(225); % random
text_data(i,:) = text_data(i,idx);

end


end
