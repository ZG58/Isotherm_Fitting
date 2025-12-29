function models = define_models()
    % define_models 定义等温线拟合模型库
    % 输出 models 是一个结构体，包含不同模型的 fittype 对象和建议的参数初值
    
    models = struct();

    %% 1. EX-L 2 模型
    % 公式: Q = (a*exp(b/T)*P) / (1 + c*exp(d/T)*P)
    % 这是一个由温度依赖的 Langmuir 模型
    form_exl2 = '(a*exp(b/T)*P) ./ (1 + c*exp(d/T)*P)';
    models.EXL2.type = fittype(form_exl2, ...
        'independent', {'P', 'T'}, 'dependent', 'Q', ...
        'coefficients', {'a', 'b', 'c', 'd'});
    % 建议初值 (需要根据实际数据量级调整)
    models.EXL2.start = [1, 100, 0.1, 100]; 

    %% 2. EX-L 3 模型
    % 公式: Q = ((a-b*T)*c*exp(d/T)*P) / (1 + c*exp(d/T)*P)
    % 饱和吸附量随温度线性变化
    form_exl3 = '((a - b*T) .* c .* exp(d/T) .* P) ./ (1 + c .* exp(d/T) .* P)';
    models.EXL3.type = fittype(form_exl3, ...
        'independent', {'P', 'T'}, 'dependent', 'Q', ...
        'coefficients', {'a', 'b', 'c', 'd'});
    models.EXL3.start = [10, 0.01, 0.1, 500];

    %% 3. Dual-site 模型 (双位点)
    % 公式: Site1 + Site2
    % 注意: 参数较多，拟合极易陷入局部最优，强烈建议设置 Lower bound (下界)
    form_dual = ['(a*exp(b/T)*P) ./ (1 + c*exp(d/T)*P) + ' ...
                 '(e*exp(f/T)*P) ./ (1 + g*exp(h/T)*P)'];
    models.Dual.type = fittype(form_dual, ...
        'independent', {'P', 'T'}, 'dependent', 'Q', ...
        'coefficients', {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'});
    models.Dual.start = [1, 100, 0.1, 100, 1, 100, 0.1, 100];
end