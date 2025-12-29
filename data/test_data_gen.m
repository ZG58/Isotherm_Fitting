% create_dummy_data.m (仅用于生成测试数据)
if ~exist('data', 'dir'), mkdir('data'); end
T_vals = [298; 313; 333]; % 温度点
P_range = linspace(0.1, 10, 20)';
data_all = [];

% 模拟 EX-L 2 行为
a=5; b=1000; c=0.1; d=1500; 
for i = 1:length(T_vals)
    T = T_vals(i);
    P = P_range;
    % 加入一点随机噪声
    q = (a*exp(b/T).*P) ./ (1 + c*exp(d/T).*P) + 0.05*rand(size(P));
    data_all = [data_all; repmat(T, size(P)), P, q];
end
save('data/test_data.mat', 'data_all');
disp('测试数据已生成至 data/test_data.mat');