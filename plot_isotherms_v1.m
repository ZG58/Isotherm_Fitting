%% 提示词：将这个脚本程序在进行图像绘制和保存的时候，将filename 中具体的数据信息显示出来

%% 吸附等温线绘制脚本 (带文件名解析与自动保存)
clear; clc; close all;

%% 1. 设置部分 (用户可修改)
% 参数文件名
% 假设文件名格式为: 路径\材料_气体_模型_params.csv
% filename = 'results\5A_CO\5A_CO_EXL3_params.csv'; 
% filename = 'results\5A_CO2\5A_CO2_EXL3_params.csv'; 

% filename = 'results\NaY_CO\NaY_CO_EXL3_params.csv'; 
filename = 'results\NaY_CO2\NaY_CO2_EXL3_params.csv'; 
% filename = 'results\NaY_H2\NaY_H2_EXL3_params.csv'; 

% 选择模型类型
% 可选: 'EX-L 2', 'EX-L 3', 'Dual-site'
model_type = 'EX-L 3'; 

% 定义温度列表 (单位: K)
T_list = [298.15, 308.15, 318.15]; 

% 定义压力范围 (单位: bar)
P_max = 5;       % 最大压力
P_points = 100;  % 绘图点数

%% 2. 解析文件名信息 (新增功能)
if ~isfile(filename)
    error('文件 %s 未找到，请确保文件在当前路径下。', filename);
end

% 提取文件名核心部分
[filepath, name, ext] = fileparts(filename);

% 数据清洗：去除 "_params" 后缀，保留核心标识 (如 5A_CO_EXL3)
data_info = strrep(name, '_params', '');

% 如果想进一步提取纯粹的材料和气体名 (假设格式标准，去除模型名)
% 例如将 '5A_CO_EXL3' 变为 '5A_CO' (可选，视文件命名规范而定)
% split_info = strsplit(data_info, '_');
% if length(split_info) >= 2
%     system_name = [split_info{1} '-' split_info{2}]; % 将下划线换为连字符
% else
%     system_name = data_info;
% end

%% 3. 读取参数文件
data = readtable(filename);
% 兼容性处理
if iscell(data.Param)
    keys = data.Param;
else
    keys = cellstr(data.Param);
end
params = containers.Map(keys, data.Value);
get_p = @(name) params(name);

%% 4. 定义等温线模型函数
% EX-L 2
ex_l_2 = @(P, T) (get_p('a') .* exp(get_p('b')./T) .* P) ./ ...
                 (1 + get_p('c') .* exp(get_p('d')./T) .* P);
% EX-L 3
ex_l_3 = @(P, T) ((get_p('a') - get_p('b').*T) .* get_p('c') .* exp(get_p('d')./T) .* P) ./ ...
                 (1 + get_p('c') .* exp(get_p('d')./T) .* P);
% Dual-site
dual_site = @(P, T) (get_p('a') .* exp(get_p('b')./T) .* P) ./ (1 + get_p('c') .* exp(get_p('d')./T) .* P) + ...
                    (get_p('e') .* exp(get_p('f')./T) .* P) ./ (1 + get_p('g') .* exp(get_p('h')./T) .* P);

%% 5. 根据选择计算并绘图
P_range = linspace(0, P_max, P_points);
f = figure('Name', ['Isotherms: ' data_info], 'Color', 'w'); % 图窗标题也带上信息
hold on;
colors = lines(length(T_list)); 

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
    
    for i = 1:length(T_list)
        T = T_list(i);
        q = model_func(P_range, T);
        plot(P_range, q, 'LineWidth', 2, 'DisplayName', sprintf('T = %.2f K', T), 'Color', colors(i,:));
    end
    
catch ME
    if strcmp(ME.identifier, 'MATLAB:Containers:Map:NoKey')
        errordlg(['参数缺少。错误: ' ME.message], '参数错误');
        return;
    else
        rethrow(ME);
    end
end

%% 6. 图形美化与信息显示
xlabel('Pressure (bar)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Loading (mmol/g)', 'FontSize', 12, 'FontWeight', 'bold');

% --- 关键修改：标题包含文件名中的信息 ---
% Interpreter 'none' 很重要，否则文件名中的下划线 '_' 会把后面的字符变成下标
title_str = {['System: ' data_info]; ['Model: ' model_type]};
title(title_str, 'FontSize', 14, 'Interpreter', 'none'); 

legend('Location', 'best', 'FontSize', 10);
grid on;
box on;
hold off;

%% 7. 自动保存图片 (新增功能)
% 生成保存的文件名，例如: Plot_5A_CO_EXL3.png
save_filename = ['Plot_' data_info '.png'];

% 检查当前目录下是否有 output 文件夹，没有则创建
if ~exist('output', 'dir')
    mkdir('output');
end
save_path = fullfile('output', save_filename);

% 保存图片 (推荐使用 exportgraphics 获得更好的分辨率，适用于 R2020a 及以上)
% 如果是旧版本 MATLAB，可以使用 saveas(gcf, save_path);
try
    exportgraphics(gcf, save_path, 'Resolution', 300);
    fprintf('图片已保存至: %s\n', save_path);
catch
    saveas(gcf, save_path);
    fprintf('图片(低清版)已保存至: %s\n', save_path);
end