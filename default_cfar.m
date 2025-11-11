function output_data = default_cfar(input_data, params)
% DEFAULT_CFAR 默认CFAR检测预处理
%
% 使用CFAR算法对雷达数据进行恒虚警检测
%
% 参数定义：
% PARAM: threshold_factor, double, 3.0
% PARAM: guard_cells, int, 4
% PARAM: training_cells, int, 16
% PARAM: method, string, CA

    % 获取参数
    threshold_factor = getParam(params, 'threshold_factor', 3.0);
    guard_cells = getParam(params, 'guard_cells', 4);
    training_cells = getParam(params, 'training_cells', 16);
    method = getParam(params, 'method', 'CA');

    % 确保输入为复数矩阵
    if ~isnumeric(input_data)
        error('输入数据必须是数值类型');
    end

    % 计算幅度
    magnitude = abs(input_data);

    % 获取数据大小
    [rows, cols] = size(magnitude);

    % 初始化输出
    detected = zeros(size(magnitude));
    thresholds = zeros(size(magnitude));
    training_means = zeros(size(magnitude));

    % 对每一列进行CFAR检测
    for col = 1:cols
        for row = 1:rows
            % 计算窗口范围
            start_idx = max(1, row - training_cells - guard_cells);
            end_idx = min(rows, row + training_cells + guard_cells);

            % 提取训练窗口
            training_window = magnitude(start_idx:end_idx, col);

            % 排除保护单元和测试单元
            guard_start = max(1, row - guard_cells);
            guard_end = min(rows, row + guard_cells);
            guard_indices = (guard_start:guard_end) - start_idx + 1;
            guard_indices = guard_indices(guard_indices > 0 & guard_indices <= length(training_window));
            training_window(guard_indices) = [];

            % 计算训练窗口均值
            mean_value = mean(training_window);
            training_means(row, col) = mean_value;

            % 计算阈值
            if strcmp(method, 'CA')
                % Cell Averaging CFAR
                threshold = mean_value * threshold_factor;
            elseif strcmp(method, 'GO')
                % Greatest Of CFAR
                half = floor(length(training_window) / 2);
                threshold = max(mean(training_window(1:half)), mean(training_window(half+1:end))) * threshold_factor;
            elseif strcmp(method, 'SO')
                % Smallest Of CFAR
                half = floor(length(training_window) / 2);
                threshold = min(mean(training_window(1:half)), mean(training_window(half+1:end))) * threshold_factor;
            else
                threshold = mean_value * threshold_factor;
            end

            % 保存阈值
            thresholds(row, col) = threshold;

            % 检测
            if magnitude(row, col) > threshold
                detected(row, col) = 1;
            end
        end
    end

    % 创建输出结构体
    output_data = struct();
    output_data.complex_matrix = input_data .* detected;  % 用于显示的复数矩阵
    output_data.detection_mask = detected;  % 检测掩码
    output_data.thresholds = thresholds;  % 阈值矩阵
    output_data.training_means = training_means;  % 训练窗口均值
    output_data.processing_params = params;  % 使用的处理参数
    output_data.method = method;  % CFAR方法
    output_data.timestamp = datetime('now');  % 处理时间戳

end

function value = getParam(params, name, default_value)
    % 辅助函数：从params结构体中获取参数值
    if isfield(params, name)
        value = params.(name);
    else
        value = default_value;
    end
end
