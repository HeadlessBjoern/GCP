% Load your data into MATLAB, assuming you have converted it to a table format
clc
clear
close all
data = readtable('/Volumes/methlab/Students/Arne/GCP/data/features/merged_data.csv');
variables = {'Accuracy', 'ReactionTime', 'GazeDeviation', 'MSRate', 'GammaPower', 'GammaFreq'};

% Split the data by contrast condition
low_contrast = data(data.Condition == 1, :);
high_contrast = data(data.Condition == 2, :);

% Calculate descriptive statistics
% disp('Descriptive Statistics for Low Contrast:');
% summary(low_contrast)
% disp('Descriptive Statistics for High Contrast:');
% summary(high_contrast)

%% BOXPLOTS
close all
figure;
set(gcf, 'Position', [100, 200, 2000, 1200], 'Color', 'w');

% Unique subject identifiers
subjects = unique(data.ID);

for i = 1:length(variables)
    subplot(2, 3, i);
    hold on;

    % Set axis limits
    ylim([min(data.(variables{i})) max(data.(variables{i}))])
    xlim([0.5 2.5])

    % Create boxplot
    boxplot(data.(variables{i}), data.Condition, 'Labels', {'Low Contrast', 'High Contrast'});

    % Overlay individual data points and connect them
    for subj = 1:length(subjects)
        % Extract data for this subject
        subj_data = data(data.ID == subjects(subj), :);

        if height(subj_data) == 2 % Ensure the subject has data for both conditions
            % X coordinates: condition indices
            x = subj_data.Condition;
            % Y coordinates: variable values
            y = subj_data.(variables{i});

            % Connect points with a line
            plot(x, y, '-o', 'Color', [0.5, 0.5, 0.5, 0.5], 'LineWidth', 0.5);
        end
    end

    % Scatter individual data points
    scatter(data.Condition, data.(variables{i}), 'jitter', 'on', 'jitterAmount', 0.00001, ...
        'MarkerEdgeColor', [0.2, 0.2, 0.8], 'MarkerFaceColor', [0.2, 0.6, 0.8], 'SizeData', 36);

    % Add title and labels
    title(variables{i}, "FontSize", 20);
    ylabel(variables{i});
    hold off;
end

saveas(gcf, '/Volumes/methlab/Students/Arne/GCP/figures/stats/GCP_stats_overview_boxplots.png');

%% PERCENTAGE CHANGE BARPLOTS
close all
% Preallocate percentage change matrix
percent_change = zeros(length(subjects), length(variables));

% Loop through each variable to calculate percentage change
for i = 1:length(variables)
    for subj = 1:length(subjects)
        % Extract data for this subject
        subj_data = data(data.ID == subjects(subj), :);

        if height(subj_data) == 2 % Ensure the subject has data for both conditions
            % Low and high contrast values
            low_value = subj_data{subj_data.Condition == 1, variables{i}};
            high_value = subj_data{subj_data.Condition == 2, variables{i}};

            % Calculate percentage change ((high - low) / low) * 100
            percent_change(subj, i) = ((high_value - low_value) / low_value) * 100;
        else
            percent_change(subj, i) = NaN; % Handle missing data
        end
    end
end

% Plot percentage change bar plots
figure;
set(gcf, 'Position', [100, 200, 2000, 1200], 'Color', 'w');

for i = 1:length(variables)
    subplot(2, 3, i);
    hold on;

    % Bar plot for each participant
    bar(1:length(subjects), percent_change(:, i), 'FaceColor', 'k', 'EdgeColor', 'none');

    % Formatting
    xlim([0.5, length(subjects) + 0.5]);
    abw = max(abs([min(percent_change(:, i), [], 'omitnan'), max(percent_change(:, i), [], 'omitnan')]));
    ylim([-abw*1.25 abw*1.25]);
    if i == 5
        ylim([-100 100])
    end
    xticks(1:length(subjects));
    xticklabels(subjects);
    xlabel('Subjects');
    ylabel('% Change');
    title(variables{i}, 'FontSize', 20);
    hold off;
end
sgtitle('Percentage Change (HC - LC)', 'FontSize', 24);
saveas(gcf, '/Volumes/methlab/Students/Arne/GCP/figures/stats/GCP_stats_overview_barplots_percentage_change.png');

%% CORRELATION matrix
% Calculate the correlation matrix between variables
corr_matrix = corr(table2array(data(:, variables)), 'Rows', 'pairwise');

% Correlation matrix
% Generate heatmap
figure('Color', 'white');
set(gcf, 'Position', [200, 400, 1200, 1500]);
h = heatmap(corr_matrix);

% Define and add color map
num_colors = 256;
cpoints = [0, 0, 0, 1;      % blue at the lowest value
           0.46, 1, 1, 1;  % transition to white starts
           0.54, 1, 1, 1;  % transition from white ends
           1, 1, 0, 0];    % red at the highest value

% Preallocate the colormap array.
cmap = zeros(num_colors, 3);

% Linearly interpolate to fill in the colormap.
for i=1:size(cmap,1)
    % Normalize the current index to the 0-1 range based on the colormap size.
    val = (i-1)/(num_colors-1);
    % Find the first point where the value is greater than the current normalized value.
    idx = find(cpoints(:,1) >= val, 1);
    if idx == 1
        % Use the first colour for values below the first point.
        cmap(i,:) = cpoints(1,2:4);
    else
        % Linearly interpolate between the two bounding colours.
        range = cpoints(idx,1) - cpoints(idx-1,1);
        frac = (val - cpoints(idx-1,1)) / range;
        cmap(i,:) = (1-frac)*cpoints(idx-1,2:4) + frac*cpoints(idx,2:4);
    end
end
colormap(h, cmap);

% Customization
h.Title = 'Correlation Heatmap';
h.XDisplayLabels = variables; % Assuming varNames contains variable names excluding 'Date', 'Weekday', and 'Overall Score'
h.YDisplayLabels = variables;
h.ColorLimits = [-1, 1]; % Color limits to ensure proper color mapping
h.FontSize = 12; % Increase the size of the x and y axis tick labels
hTitle.FontSize = 25;
saveas(gcf, '/Volumes/methlab/Students/Arne/GCP/figures/stats/GCP_stats_overview_correlation_matrix.png');
