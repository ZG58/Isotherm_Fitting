%% 吸附等温线绘制脚本
clear; clc; close all;

%% 1. 设置部分 (用户可修改)
% 参数文件名
filename = 'results\5A_CO2\5A_CO2_EXL2_params.csv'; 

% 选择模型类型
% 可选: 'EX-L 2', 'EX-L 3', 'Dual-site'
model_type = 'EX-L 2'; 

% 定义温度列表 (单位: K)
T_list = [298.15, 308.15, 318.15]; 

% 定义压力范围 (单位: bar)
P_max = 5;       % 最大压力
P_points = 100;  % 绘图点数

%% 2. 读取参数文件
if ~isfile(filename)
    error('文件 %s 未找到，请确保文件在当前路径下。', filename);
end

data = readtable(filename);
% 将参数转换为 Map 以便通过名称调用
% 兼容不同版本的 MATLAB (处理 cell 或 string 类型)
if iscell(data.Param)
    keys = data.Param;
else
    keys = cellstr(data.Param);
end
params = containers.Map(keys, data.Value);

% 定义获取参数的辅助函数
get_p = @(name) params(name);

%% 3. 定义等温线模型函数
% P: 压力 (bar), T: 温度 (K)

% EX-L 2: q = (a*exp(b/T)*P)/(1+c*exp(d/T)*P)
ex_l_2 = @(P, T) (get_p('a') .* exp(get_p('b')./T) .* P) ./ ...
                 (1 + get_p('c') .* exp(get_p('d')./T) .* P);

% EX-L 3: q = ((a-b*T)*c*exp(d/T)*P)/(1+c*exp(d/T)*P)
% 注意：此模型要求参数文件中的 b 与 EX-L 2 中的 b 物理意义不同
ex_l_3 = @(P, T) ((get_p('a') - get_p('b').*T) .* get_p('c') .* exp(get_p('d')./T) .* P) ./ ...
                 (1 + get_p('c') .* exp(get_p('d')./T) .* P);

% Dual-site: 两项叠加
% 需要参数: a, b, c, d, e, f, g, h
dual_site = @(P, T) (get_p('a') .* exp(get_p('b')./T) .* P) ./ (1 + get_p('c') .* exp(get_p('d')./T) .* P) + ...
                    (get_p('e') .* exp(get_p('f')./T) .* P) ./ (1 + get_p('g') .* exp(get_p('h')./T) .* P);

%% 4. 根据选择计算并绘图
P_range = linspace(0, P_max, P_points);
figure('Name', 'Adsorption Isotherms', 'Color', 'w');
hold on;
colors = lines(length(T_list)); % 生成区分度高的颜色

% 选择模型函数
try
    switch model_type
        case 'EX-L 2'
            model_func = ex_l_2;
        case 'EX-L 3'
            model_func = ex_l_3;
        case 'Dual-site'
            model_func = dual_site;
        otherwise
            error('未知的模型类型: %s', model_type);
    end
    
    % 循环温度绘图
    for i = 1:length(T_list)
        T = T_list(i);
        q = model_func(P_range, T);
        plot(P_range, q, 'LineWidth', 2, 'DisplayName', sprintf('T = %.2f K', T), 'Color', colors(i,:));
    end
    
catch ME
    if strcmp(ME.identifier, 'MATLAB:Containers:Map:NoKey')
        errordlg(['参数文件缺少当前模型所需的参数。错误信息: ' ME.message], '参数错误');
    else
        rethrow(ME);
    end
end

% 5. 图形美化
xlabel('Pressure (bar)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Loading (mmol/g)', 'FontSize', 12, 'FontWeight', 'bold');
title(['Adsorption Isotherms (' model_type ')'], 'FontSize', 14);
legend('Location', 'best', 'FontSize', 10);
grid on;
box on;
hold off;