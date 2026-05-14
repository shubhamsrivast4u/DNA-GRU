%==========================================================================
% plot_latency_vs_batchsize.m
%
% Reads latency_vs_batch_size.csv (produced by the
% DNAformer_vs_Compact_Analysis notebook) and produces THREE separate
% MATLAB figures, each saved as both a .fig and an .eps file:
%
%   latency_total_vs_B.{fig,eps}        - total per-batch latency
%   latency_per_cluster_vs_B.{fig,eps}  - amortised per-cluster latency
%   latency_speedup_vs_B.{fig,eps}      - DNA-GRU speed-up over DNAformer
%
% Run from the directory that contains latency_vs_batch_size.csv.
%==========================================================================

clear; close all; clc;

%---------------- USER SETTINGS -------------------------------------------
csv_file       = 'latency_vs_batch_size.csv';
deployment_B   = 200;          % vertical reference line in the plots
font_name      = 'Times';      % change to 'Helvetica', 'Arial', etc. as needed
font_size      = 12;
line_width     = 1.6;
marker_size    = 7;
color_dnaf     = [0.85 0.37 0.10];   % orange
color_compact  = [0.10 0.62 0.47];   % teal/green
color_speedup  = [0.46 0.44 0.70];   % purple
%--------------------------------------------------------------------------

% ---------- Read CSV ----------------------------------------------------
T = readtable(csv_file);

bs           = T.batch_size;
dnaf_ms      = T.DNAformer_ms;
dnaf_ms_std  = T.DNAformer_ms_std;
dnaf_per_cl  = T.DNAformer_ms_per_cluster;
cm_ms        = T.Compact_ms;
cm_ms_std    = T.Compact_ms_std;
cm_per_cl    = T.Compact_ms_per_cluster;
speedup      = T.Speedup_x;

% Mask for valid (non-NaN) DNAformer measurements (in case of OOM at large B)
mask_dnaf = ~isnan(dnaf_ms);

% =========================================================================
% FIGURE 1: TOTAL PER-BATCH LATENCY (log-log)
% =========================================================================
fig1 = figure('Name', 'Total latency vs batch size', ...
              'Units', 'inches', 'Position', [1 1 5 4], ...
              'PaperPositionMode', 'auto');

ax1 = axes('Parent', fig1);
hold(ax1, 'on');

% DNAformer with errorbars
h1 = errorbar(ax1, bs(mask_dnaf), dnaf_ms(mask_dnaf), dnaf_ms_std(mask_dnaf), ...
              '-o', 'Color', color_dnaf, 'MarkerFaceColor', color_dnaf, ...
              'LineWidth', line_width, 'MarkerSize', marker_size, ...
              'CapSize', 4, 'DisplayName', 'DNAformer');

% DNA-GRU with errorbars
h2 = errorbar(ax1, bs, cm_ms, cm_ms_std, ...
              '-s', 'Color', color_compact, 'MarkerFaceColor', color_compact, ...
              'LineWidth', line_width, 'MarkerSize', marker_size, ...
              'CapSize', 4, 'DisplayName', 'DNA-GRU (ours)');

% Deployment-batch reference line
yl = ylim(ax1);
h3 = plot(ax1, [deployment_B deployment_B], yl, ':', ...
          'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
          'DisplayName', sprintf('deployment B=%d', deployment_B));

set(ax1, 'XScale', 'log', 'YScale', 'log');
set(ax1, 'XTick', bs, 'XTickLabel', arrayfun(@num2str, bs, 'UniformOutput', false));
xlabel(ax1, 'Batch size $B$', 'Interpreter', 'latex');
ylabel(ax1, 'Latency per batch (ms)', 'Interpreter', 'latex');
title(ax1, 'Total forward-pass latency', 'Interpreter', 'latex');
legend(ax1, [h1 h2 h3], 'Location', 'northwest', 'Interpreter', 'latex');
grid(ax1, 'on'); box(ax1, 'on');
set(ax1, 'FontName', font_name, 'FontSize', font_size);
set(ax1, 'GridAlpha', 0.25, 'MinorGridAlpha', 0.12);
xlim(ax1, [min(bs)*0.8, max(bs)*1.25]);
hold(ax1, 'off');

savefig(fig1, 'latency_total_vs_B.fig');
print(fig1, 'latency_total_vs_B.eps', '-depsc2', '-r300');
fprintf('Saved: latency_total_vs_B.{fig,eps}\n');


% =========================================================================
% FIGURE 2: AMORTISED PER-CLUSTER LATENCY (log-log)
% =========================================================================
fig2 = figure('Name', 'Per-cluster latency vs batch size', ...
              'Units', 'inches', 'Position', [1 1 5 4], ...
              'PaperPositionMode', 'auto');

ax2 = axes('Parent', fig2);
hold(ax2, 'on');

h1 = plot(ax2, bs(mask_dnaf), dnaf_per_cl(mask_dnaf), ...
          '-o', 'Color', color_dnaf, 'MarkerFaceColor', color_dnaf, ...
          'LineWidth', line_width, 'MarkerSize', marker_size, ...
          'DisplayName', 'DNAformer');

h2 = plot(ax2, bs, cm_per_cl, ...
          '-s', 'Color', color_compact, 'MarkerFaceColor', color_compact, ...
          'LineWidth', line_width, 'MarkerSize', marker_size, ...
          'DisplayName', 'DNA-GRU (ours)');

yl = ylim(ax2);
h3 = plot(ax2, [deployment_B deployment_B], yl, ':', ...
          'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
          'DisplayName', sprintf('deployment B=%d', deployment_B));

set(ax2, 'XScale', 'log', 'YScale', 'log');
set(ax2, 'XTick', bs, 'XTickLabel', arrayfun(@num2str, bs, 'UniformOutput', false));
xlabel(ax2, 'Batch size $B$', 'Interpreter', 'latex');
ylabel(ax2, 'Latency per cluster (ms)', 'Interpreter', 'latex');
title(ax2, 'Amortised per-cluster latency', 'Interpreter', 'latex');
legend(ax2, [h1 h2 h3], 'Location', 'northeast', 'Interpreter', 'latex');
grid(ax2, 'on'); box(ax2, 'on');
set(ax2, 'FontName', font_name, 'FontSize', font_size);
set(ax2, 'GridAlpha', 0.25, 'MinorGridAlpha', 0.12);
xlim(ax2, [min(bs)*0.8, max(bs)*1.25]);
hold(ax2, 'off');

savefig(fig2, 'latency_per_cluster_vs_B.fig');
print(fig2, 'latency_per_cluster_vs_B.eps', '-depsc2', '-r300');
fprintf('Saved: latency_per_cluster_vs_B.{fig,eps}\n');


% =========================================================================
% FIGURE 3: SPEED-UP CURVE (semilog-x)
% =========================================================================
fig3 = figure('Name', 'Speed-up vs batch size', ...
              'Units', 'inches', 'Position', [1 1 5 4], ...
              'PaperPositionMode', 'auto');

ax3 = axes('Parent', fig3);
hold(ax3, 'on');

valid = ~isnan(speedup);
h1 = plot(ax3, bs(valid), speedup(valid), ...
          '-d', 'Color', color_speedup, 'MarkerFaceColor', color_speedup, ...
          'LineWidth', line_width, 'MarkerSize', marker_size+1, ...
          'DisplayName', 'DNA-GRU speed-up');

% Annotate each point with its speed-up value
for k = 1:numel(bs)
    if valid(k)
        text(ax3, bs(k), speedup(k), sprintf(' %.2f$\\times$', speedup(k)), ...
             'Interpreter', 'latex', ...
             'FontName', font_name, 'FontSize', font_size-1, ...
             'VerticalAlignment', 'bottom', ...
             'HorizontalAlignment', 'left');
    end
end

% 1x reference line
h2 = plot(ax3, [min(bs)*0.8 max(bs)*1.25], [1 1], '--', ...
          'Color', [0.4 0.4 0.4], 'LineWidth', 1.0, ...
          'DisplayName', 'parity (1$\times$)');

% Deployment-batch reference line
yl = ylim(ax3);
h3 = plot(ax3, [deployment_B deployment_B], yl, ':', ...
          'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
          'DisplayName', sprintf('deployment B=%d', deployment_B));

set(ax3, 'XScale', 'log');
set(ax3, 'XTick', bs, 'XTickLabel', arrayfun(@num2str, bs, 'UniformOutput', false));
xlabel(ax3, 'Batch size $B$', 'Interpreter', 'latex');
ylabel(ax3, 'Speed-up over DNAformer ($\times$)', 'Interpreter', 'latex');
title(ax3, 'Wall-clock speed-up grows with batch size', 'Interpreter', 'latex');
legend(ax3, [h1 h2 h3], 'Location', 'northwest', 'Interpreter', 'latex');
grid(ax3, 'on'); box(ax3, 'on');
set(ax3, 'FontName', font_name, 'FontSize', font_size);
set(ax3, 'GridAlpha', 0.25, 'MinorGridAlpha', 0.12);
xlim(ax3, [min(bs)*0.8, max(bs)*1.25]);
ylim(ax3, [0, max(speedup(valid))*1.20]);
hold(ax3, 'off');

savefig(fig3, 'latency_speedup_vs_B.fig');
print(fig3, 'latency_speedup_vs_B.eps', '-depsc2', '-r300');
fprintf('Saved: latency_speedup_vs_B.{fig,eps}\n');

fprintf('\nDone. Three figures generated.\n');
