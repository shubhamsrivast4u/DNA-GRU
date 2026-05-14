% =========================================================================
%  plot_methods_comparison.m
%
%  Produces a grouped log-scale bar chart comparing the final cluster
%  failure rate of DNA-GRU (this work) against DNAformer and five
%  classical / DNN baselines on the four reconstruction benchmarks
%  used in the DNAformer paper.
%
%  Output:
%    figures/methods_comparison_bars.fig
%    figures/methods_comparison_bars.eps
%
%  All numbers are taken directly from:
%    - DNAformer paper, Fig. 3(a)  (DNAformer + 5 baselines)
%    - DNA-GRU notebooks (DNA-GRU-CPL-MultiThreshold-*.ipynb), final
%      result row "Best:" line, i.e. the rate AFTER auto-CPL post-processing.
%
%  Author: paper draft.
% =========================================================================

clear; close all; clc;

FIG_DIR = fullfile('.', 'figures');
if ~exist(FIG_DIR,'dir'); mkdir(FIG_DIR); end

% -------------------------------------------------------------------------
% Data.  Rows = datasets, columns = methods (in the order shown in legend).
% Failure rates in percent.
% -------------------------------------------------------------------------
datasets = { ...
    'Erlich (Illumina)', ...
    'Grass (Illumina)',  ...
    'BinnedTestIllumina', ...
    'BinnedNanopore2FC', ...
    'Srinivasavaradhan'};

methods = { ...
    'DNA-GRU (ours, auto-CPL)', ...   % This work
    'DNAformer', ...                   % bar2025scalable
    'Iterative', ...                   % Sabary 2023
    'BMA Lookahead', ...               % Maarouf 2022
    'Hybrid', ...                      % Sabary 2023
    'Divider BMA', ...                 % Sabary 2023
    'VS'};                             % Viswanathan-Swamy 2008

% Failure rates in %.  Order of columns matches `methods`.
% Rows in order of `datasets`.
%
% Sources:
%   row 1 (Erlich)             : DNAformer Fig.3a
%   row 2 (Grass)              : DNAformer Fig.3a
%   row 3 (BinnedTestIllumina) : "This work (Illumina)" row in DNAformer Fig.3a
%   row 4 (BinnedNanopore2FC)  : "This work (Nanopore)"  row in DNAformer Fig.3a
%   row 5 (Srinivasavaradhan)  : DNAformer Fig.3a
%
% Our DNA-GRU column is from the auto-CPL final result ("Best:" line)
% of each notebook.
%
FR = [ ...
%   ours    DNAformer  Iterative  BMA-LA  Hybrid  Div.BMA  VS
    0.02,  0.02,      0.02,     0.02,   0.02,   0.02,    0.02; ... % Erlich
    0.5219,  0.66,      0.62,     0.80,   1.00,   1.62,    3.09; ... % Grass
    0.0055,  0.0055,    0.0073,   0.0073, 0.0073, 0.0073,  0.0091; ... % BinnedTestIllumina
    1.6258,  1.65,      3.30,     8.66,  36.90,  43.25,   26.18; ... % BinnedNanopore2FC
   11.6235, 14.58,     16.72,    31.44,  84.77,  94.35,   91.36 ];  % Srinivasavaradhan

% Sanity: mark cells where a method reaches a hard floor of <=0 (we use NaN
% to signal "method does not apply / not reported").  None here, but kept
% as a safety net.
FR(FR <= 0) = NaN;

[nDS, nMethod] = size(FR);
assert(nDS == numel(datasets));
assert(nMethod == numel(methods));

% -------------------------------------------------------------------------
% Styling
% -------------------------------------------------------------------------
% Highlight our method in a distinct colour; group the rest as
% "comparison baselines" using a graded blue/grey palette.
clr = [
    0.84 0.15 0.16;   % ours          - red (highlight)
    0.12 0.47 0.71;   % DNAformer     - blue
    0.55 0.71 0.84;   %
    0.65 0.65 0.65;   %
    0.75 0.75 0.75;   %  classical    - greys
    0.55 0.55 0.55;   %
    0.40 0.40 0.40];

% -------------------------------------------------------------------------
% Build bar chart on a log y-axis
% -------------------------------------------------------------------------
hF = figure('Units','centimeters','Position',[2 2 22 11], ...
            'Color','w','PaperPositionMode','auto');
ax = axes(hF); hold(ax,'on'); box(ax,'on');

% bar uses one colour per series
b = bar(ax, 1:nDS, FR, 0.9, 'grouped');
for k = 1:nMethod
    b(k).FaceColor = clr(k,:);
    b(k).EdgeColor = 'k';
    b(k).LineWidth = 0.4;
end

% emphasise our bars with a slightly thicker border
b(1).LineWidth = 1.4;

% log y axis
set(ax,'YScale','log');
ylim(ax,[3e-3 200]);
ax.YTick = [1e-2 1e-1 1 10 100];
ax.YTickLabel = {'0.01','0.1','1','10','100'};

% x labels
set(ax,'XTick',1:nDS,'XTickLabel',datasets, ...
    'FontSize',10,'TickLabelInterpreter','latex','XTickLabelRotation',12);

ylabel(ax,'Cluster failure rate $[\%]$ \hspace{1mm}\textit{(log scale, lower is better)}', ...
    'Interpreter','latex','FontSize',11);

% Legend
lg = legend(ax, b, methods, 'Interpreter','latex', ...
    'Location','northoutside','Orientation','horizontal', ...
    'NumColumns',4,'Box','off','FontSize',9);

% Annotate the bar values for our method (column 1) with the actual %
% so the headline numbers are unambiguous.
xt = b(1).XEndPoints;
for i = 1:nDS
    txt = sprintf('%.4g',FR(i,1));
    if FR(i,1) >= 1
        txt = sprintf('%.2f',FR(i,1));
    end
    text(ax, xt(i), FR(i,1)*1.25, [txt '\%'], ...
        'Interpreter','latex','HorizontalAlignment','center', ...
        'FontSize',8.5,'Color',clr(1,:),'FontWeight','bold');
end

grid(ax,'on');
ax.YMinorGrid = 'on';
ax.GridAlpha = 0.18;
ax.MinorGridAlpha = 0.08;

% -------------------------------------------------------------------------
% Save
% -------------------------------------------------------------------------
savefig(hF, fullfile(FIG_DIR,'methods_comparison_bars.fig'));
print(  hF, fullfile(FIG_DIR,'methods_comparison_bars.eps'), ...
        '-depsc2','-painters');
fprintf('Wrote %s/methods_comparison_bars.{fig,eps}\n', FIG_DIR);
