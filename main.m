%% 初始化
clear; clc; close all;
addpath('src'); 

%% ================= 配置区域 (Configuration) =================

% --- 1. 多点启动次数 (Retry Count) ---
% 含义: 在参数范围内随机生成初值进行重复拟合的次数。
% 建议: 
%   - 10: 日常调试，速度快。
%   - 50~100: 最终出图或写论文时使用。对于 Dual-site 这种 8 参数模型，次数越多越能保证找到全局最优。
config.retry_count = 20;      

% --- 2. 鲁棒拟合模式 (Robust Mode) ---
% 含义: 决定如何处理数据中的"离群点"或噪声。
% 选项:
%   - 'Off':      (默认) 标准最小二乘法。权重相同，对离群点非常敏感。如果数据质量极高（如模拟数据），选此项。
%   - 'LAR':      (Least Absolute Residuals) 最小绝对残差。通过最小化绝对偏差来拟合，比 'Off' 抗噪，适合长尾分布误差。
%   - 'Bisquare': (推荐) 双平方加权法。抗噪能力最强，会自动忽略严重偏离趋势的坏点。
config.robust_mode = 'LAR';   

% --- 3. 优化算法 (Algorithm) ---
% 含义: 寻找最小误差的数值迭代方法。
% 选项:
%   - 'Trust-Region':       (强烈推荐) 信赖域算法。目前唯一能完美支持 Lower/Upper 边界约束的算法。
%                           由于我们需要限制吸附参数 > 0，这是最安全的选择。
%   - 'Levenberg-Marquardt': LM 算法。收敛速度通常比 Trust-Region 快，但在 MATLAB 中往往忽略边界约束，
%                           容易导致参数算出负数（无物理意义），除非不设置 Lower/Upper。
%   - 'Gauss-Newton':       高斯-牛顿法。较老的方法，通常不如上述两种稳定。
config.algorithm   = 'Levenberg-Marquardt'; 

% --- 4. 其它微调 (Advanced) ---
% 最大迭代次数 (默认 400，复杂模型建议 1000+)
config.max_iter = 1000; 

% 终止容差 (DiffMinChange/DiffMaxChange)
% 如果发现拟合提前停止且精度不够，可以调小此值 (如 1e-8)，但会增加计算时间
config.tol_fun = 1e-6; 

% ===========================================================
% ===========================================

%% 1. 加载数据与路径解析 【修改】
data_file = fullfile('data', 'NaY_CO2.mat');

% --- 【核心修改开始】：自动提取文件名并建立独立文件夹 ---
[~, data_name, ~] = fileparts(data_file); % 提取 "NaY_CO2"
output_dir = fullfile('results', data_name); % 构建路径 "results/NaY_CO2"

% 创建专属输出文件夹
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('已创建输出目录: %s\n', output_dir);
end
% --- 【核心修改结束】 ---

% (数据生成逻辑保持不变)
if ~isfile(data_file)
    T_sim = linspace(273, 353, 10)'; P_sim = linspace(0, 10, 20)';
    [TT, PP] = meshgrid(T_sim, P_sim);
    QQ = (2*exp(500./TT).*PP) ./ (1 + 0.1*exp(600./TT).*PP) + 0.05 * randn(size(TT));
    raw_data = [TT(:), PP(:), QQ(:)];
    if ~exist('data', 'dir'), mkdir('data'); end
    save(data_file, 'raw_data');
end

[T, P, Q] = load_data(data_file);
if any(T==0), error('温度不能为0，请使用开尔文(K)'); end

%% 2. 准备拟合
models = define_models();
run_list = fieldnames(models); 
summary_table = table(); 

%% 3. 循环拟合
for i = 1:length(run_list)
    m_name = run_list{i};
    model_struct = models.(m_name);
    ft = model_struct.type;
    
    fprintf('\n========================================\n');
    fprintf('正在优化模型: %s (Multi-Start 模式)\n', m_name);
    
    % 参数初始化
    start_guess = model_struct.start;
    n_coeffs = numel(start_guess);
    lb = zeros(1, n_coeffs); 
    ub = ones(1, n_coeffs) * 20000; 
    ub(1:2:end) = 1000; 
    
    best_fit = [];
    best_gof = [];
    best_sse = inf;
    
    % Multi-Start 循环
    for k = 1:config.retry_count
        opts = fitoptions(ft);
        opts.Algorithm = config.algorithm;
        opts.Display = 'Off';
        % 在 main.m 的循环内部：
        opts = fitoptions(ft);
        opts.Algorithm = config.algorithm;
        opts.Display = 'Off';

        % --- 应用新的配置 ---
        opts.MaxIter = config.max_iter; % 设置最大迭代次数
        opts.TolFun  = config.tol_fun;  % 设置函数容差
        opts.TolX    = config.tol_fun;  % 设置参数容差
        % -------------------

        opts.Lower = lb;
        opts.Upper = ub;
        % ... 后续代码不变
        if strcmpi(config.robust_mode, 'Bisquare') || strcmpi(config.robust_mode, 'LAR')
             opts.Robust = config.robust_mode;
        end
        
        if k == 1
            current_start = start_guess;
        else
            r = rand(1, n_coeffs);
            current_start = lb + r .* (ub - lb);
            current_start(2:2:end) = 100 + rand(1, floor(n_coeffs/2)) * 4900; 
        end
        opts.StartPoint = current_start;
        
        try
            [f_res, gof] = fit([P, T], Q, ft, opts);
            if gof.sse < best_sse
                best_sse = gof.sse;
                best_fit = f_res;
                best_gof = gof;
            end
        catch
        end
    end
    
    if isempty(best_fit)
        fprintf(2, '模型 %s 拟合失败。\n', m_name);
        continue;
    end
    
    %% 4. 计算高级指标
    n = length(Q);
    p = numargs(best_fit);
    sse = best_gof.sse;
    aic = n * log(sse/n) + 2*p;
    bic = n * log(sse/n) + p * log(n);
    fprintf('最终结果 %s: R^2=%.4f, AIC=%.2f\n', m_name, best_gof.rsquare, aic);

    %% 5. 绘图与保存 【修改】
    fig = figure('Name', ['Best Fit - ' m_name], 'Visible', 'on'); 
    plot3(P, T, Q, 'ko', 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerSize', 4); hold on;
    plot(best_fit, [P, T], Q);
    xlabel('Pressure (Bar)'); ylabel('Temperature (K)'); zlabel('Uptake');
    title({[data_name ' - ' m_name ' Model'], ['R^2=' num2str(best_gof.rsquare, '%.4f') ', AIC=' num2str(aic, '%.1f')]});
    grid on; alpha(0.6);
    
    % --- 【文件名修改】：增加前缀 data_name ---
    img_filename = [data_name '_' m_name '_fit.png'];
    saveas(fig, fullfile(output_dir, img_filename));
    
    % 保存参数
    new_row = table({m_name}, best_gof.rsquare, best_gof.rmse, aic, bic, ...
        'VariableNames', {'Model', 'R_Square', 'RMSE', 'AIC', 'BIC'});
    summary_table = [summary_table; new_row];
    
    c_vals = coeffvalues(best_fit);
    c_names = coeffnames(best_fit);
    T_params = table(c_names, c_vals', 'VariableNames', {'Param', 'Value'});
    
    % --- 【文件名修改】：增加前缀 data_name ---
    csv_filename = [data_name '_' m_name '_params.csv'];
    writetable(T_params, fullfile(output_dir, csv_filename));
end

%% 6. 输出最终对比 【修改】
fprintf('\n================== 模型对比汇总 ==================\n');
disp(summary_table);
% --- 【文件名修改】：汇总表也增加前缀 ---
summary_filename = [data_name '_Model_Comparison.csv'];
writetable(summary_table, fullfile(output_dir, summary_filename));

fprintf('所有结果已保存至文件夹: %s\n', output_dir);