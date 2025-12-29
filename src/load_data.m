function [T, P, Q] = load_data(filename)
    % 读取 mat 文件并提取 T, P, Q 列向量
    if ~isfile(filename)
        error('文件 %s 不存在，请检查路径。', filename);
    end
    
    raw = load(filename);
    % 假设 mat 文件中有一个变量名为 'data' 或你需要获取第一个变量
    vars = fieldnames(raw);
    data_matrix = raw.(vars{1}); % 获取结构体中的数据矩阵
    
    % 确保数据是矩阵
    if size(data_matrix, 2) < 3
        error('数据列数不足，需要至少3列 (T, P, Q)');
    end
    
    % 提取数据 (假设顺序为 T, P, Q)
    T = data_matrix(:, 1);
    P = data_matrix(:, 2);
    Q = data_matrix(:, 3);
    
    % 转为列向量以防万一
    T = T(:); P = P(:); Q = Q(:);
end