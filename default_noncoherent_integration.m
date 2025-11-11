function output_data = default_noncoherent_integration(input_data, params)
% DEFAULT_NONCOHERENT_INTEGRATION 非相参积累预处理
%
% 对雷达数据进行非相参积累处理，提高信噪比
%
% 参数定义：
% PARAM: integration_number, int, 4
% PARAM: dimension, string, row
% PARAM: method, string, average
% PARAM: normalize, bool, true

    % 获取参数
    integration_number = getParam(params, 'integration_number', 4);
    dimension = getParam(params, 'dimension', 'row');
    method = getParam(params, 'method', 'average');
    normalize = getParam(params, 'normalize', true);

    % 确保输入为复数矩阵
    if ~isnumeric(input_data)
        error('输入数据必须是数值类型');
    end

    % 获取数据大小
    [rows, cols] = size(input_data);

    % 根据维度进行积累
    if strcmp(dimension, 'row')
        % 按行方向积累
        if mod(rows, integration_number) ~= 0
            % 如果不能整除，截断多余的行
            rows = floor(rows / integration_number) * integration_number;
            input_data = input_data(1:rows, :);
        end

        % 重塑数据
        reshaped = reshape(input_data, integration_number, rows / integration_number, cols);

        % 计算幅度的平方（能量）
        energy = abs(reshaped).^2;

        % 积累
        if strcmp(method, 'sum')
            accumulated = sum(energy, 1);
        else  % average
            accumulated = mean(energy, 1);
        end

        % 转换回复数形式（使用幅度和相位）
        % 对于非相参积累，我们只保留幅度信息
        magnitude = sqrt(accumulated);

        % 重塑回原始维度
        output_data = squeeze(magnitude);

        % 确保输出是复数形式
        if isreal(output_data)
            output_data = complex(output_data, zeros(size(output_data)));
        end

    elseif strcmp(dimension, 'col')
        % 按列方向积累
        if mod(cols, integration_number) ~= 0
            % 如果不能整除，截断多余的列
            cols = floor(cols / integration_number) * integration_number;
            input_data = input_data(:, 1:cols);
        end

        % 重塑数据
        reshaped = reshape(input_data, rows, integration_number, cols / integration_number);

        % 计算幅度的平方（能量）
        energy = abs(reshaped).^2;

        % 积累
        if strcmp(method, 'sum')
            accumulated = sum(energy, 2);
        else  % average
            accumulated = mean(energy, 2);
        end

        % 转换回复数形式
        magnitude = sqrt(accumulated);

        % 重塑回原始维度
        output_data = squeeze(magnitude);

        % 确保输出是复数形式
        if isreal(output_data)
            output_data = complex(output_data, zeros(size(output_data)));
        end

    else
        error('dimension参数必须是"row"或"col"');
    end

    % 归一化
    if normalize
        max_val = max(abs(output_data(:)));
        if max_val > 0
            output_data = output_data / max_val;
        end
    end

end

function value = getParam(params, name, default_value)
    % 辅助函数：从params结构体中获取参数值
    if isfield(params, name)
        value = params.(name);
    else
        value = default_value;
    end
end
