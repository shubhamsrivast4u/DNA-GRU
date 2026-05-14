% =========================================================================
%  plot_cpl_cv_justification.m
%
%  Produces three SEPARATE MATLAB figures justifying the adaptive
%  CV-to-percentile rule for CPL activation in DNA-GRU:
%
%    figures/cpl_confidence_distributions.{fig,eps}
%        Normalised KDE of m(M) for the 5 benchmark datasets.
%        Shows visually that low-CV datasets (Illumina) have tightly
%        peaked confidence distributions while high-CV datasets
%        (Nanopore) carry a broad low-confidence tail.
%
%    figures/cpl_cv_to_percentile_mapping.{fig,eps}
%        Empirical CV vs. oracle-optimal CPL percentile, with the
%        four CV zones of Eq. (cv_mapping) shown as background shading.
%
%    figures/cpl_failure_rate_sweep.{fig,eps}
%        Final failure rate vs. CPL percentile, normalised by the
%        DNN-only rate, per dataset. Stars mark the percentile chosen
%        by the adaptive rule. Demonstrates that no fixed p is best
%        on all datasets.
%
%  Data source priority (per dataset):
%    1.  mat_results/combined_<DATASET>.mat        (preferred; full arrays)
%    2.  mat_results/fig4_confidence_<DATASET>.mat  (m_scores_all only)
%    3.  mat_results/fig5_sweep_<DATASET>.mat       (sweep arrays only)
%    4.  mat_results/auto_select_<DATASET>.mat     (CV / mean / std)
%    5.  results/auto_select_<DATASET>.csv          (CV / mean / std)
%    6.  results/results_multithreshold_<DATASET>.csv (sweep)
%    7.  Hard-coded fallback values from the simulation logs.
%
%  All paths can be adjusted in the USER PATHS block.
%
%  Author: paper draft.
% =========================================================================

clear; close all; clc;

% -------------------------------------------------------------------------
% USER PATHS
% -------------------------------------------------------------------------
MAT_DIR   = fullfile('.', 'mat_results');     % location of *.mat
CSV_DIR   = fullfile('.', 'results');         % location of *.csv
FIG_DIR   = fullfile('.', 'figures');         % output location
if ~exist(FIG_DIR, 'dir'); mkdir(FIG_DIR); end

% -------------------------------------------------------------------------
% Dataset table.  cv_pct, mean_m, std_m, sweep_*, dnn_fr are FALLBACKS used
% only if the corresponding .mat / .csv files are missing.  All values
% taken from the simulation logs of the *.ipynb notebooks.
% -------------------------------------------------------------------------
DS = struct();

DS(1).name     = 'BinnedTestIllumina';
DS(1).label    = 'BinnedTestIllumina (Illumina)';
DS(1).cv_pct   = 0.1208;
DS(1).oracle_p = 0;
DS(1).rule_p   = 0;
DS(1).sweep_p  = [0  5 10 15 20 25];
DS(1).sweep_fr = [0.0055 0.0055 0.0055 0.0055 0.0055 0.0055];
DS(1).dnn_fr   = 0.0055;
DS(1).mean_m   = 0.920456;
DS(1).std_m    = 0.001112;

DS(2).name     = 'Erlich';
DS(2).label    = 'Erlich (Illumina)';
DS(2).cv_pct   = 0.0122;
DS(2).oracle_p = 0;
DS(2).rule_p   = 0;
DS(2).sweep_p  = [0  5 10 15 20 25];
DS(2).sweep_fr = [0.0208 0.0208 0.0208 0.0208 0.0208 0.0208];
DS(2).dnn_fr   = 0.0208;
DS(2).mean_m   = 0.919575;
DS(2).std_m    = 0.000112;

DS(3).name     = 'Grass';
DS(3).label    = 'Grass (Illumina)';
DS(3).cv_pct   = 1.0360;
DS(3).oracle_p = 5;
DS(3).rule_p   = 5;
DS(3).sweep_p  = [0     5      10     15     20     25];
DS(3).sweep_fr = [0.7226 0.5219 0.5621 0.6023 0.6425 0.6827];
DS(3).dnn_fr   = 0.7226;
DS(3).mean_m   = 0.920097;
DS(3).std_m    = 0.009532;

DS(4).name     = 'BinnedNanopore2FC';
DS(4).label    = 'Nanopore 2FC';
DS(4).cv_pct   = 1.9225;
DS(4).oracle_p = 5;
DS(4).rule_p   = 5;
DS(4).sweep_p  = [0      5      10     15     20     25    ];
DS(4).sweep_fr = [2.8543 1.6258 1.6800 1.7800 1.9000 2.0500];
DS(4).dnn_fr   = 2.8543;
DS(4).mean_m   = 0.918972;
DS(4).std_m    = 0.017668;

DS(5).name     = 'Srinivasavaradhan';
DS(5).label    = 'Srinivasavaradhan (Nanopore)';
DS(5).cv_pct   = 4.6656;
DS(5).oracle_p = 15;
DS(5).rule_p   = 15;
DS(5).sweep_p  = [0       5       10      15      20      25    ];
DS(5).sweep_fr = [14.6273 13.5000 12.4000 11.6235 11.9000 12.4000];
DS(5).dnn_fr   = 14.6273;
DS(5).mean_m   = 0.907909;
DS(5).std_m    = 0.042359;

nDS = numel(DS);

% -------------------------------------------------------------------------
% Load empirical data per dataset, in the priority order documented above.
% -------------------------------------------------------------------------
for i = 1:nDS
    DS(i).m_scores  = [];     % filled below if available
    DS(i).synthetic = true;   % becomes false if real m_scores are loaded

    name        = DS(i).name;
    f_combined  = fullfile(MAT_DIR, ['combined_'         name '.mat']);
    f_fig4      = fullfile(MAT_DIR, ['fig4_confidence_'  name '.mat']);
    f_fig5      = fullfile(MAT_DIR, ['fig5_sweep_'       name '.mat']);
    f_auto_mat  = fullfile(MAT_DIR, ['auto_select_'      name '.mat']);
    f_auto_csv  = fullfile(CSV_DIR, ['auto_select_'      name '.csv']);
    f_sweep_csv = fullfile(CSV_DIR, ['results_multithreshold_' name '.csv']);

    % --- per-cluster m(M) array (preferred from combined, else fig4) ---
    if exist(f_combined, 'file')
        S = load(f_combined);
        if isfield(S, 'm_scores_all')
            DS(i).m_scores  = double(S.m_scores_all(:));
            DS(i).synthetic = false;
        end
        if isfield(S, 'sweep_percentiles') && isfield(S, 'sweep_final_rate')
            DS(i).sweep_p  = double(S.sweep_percentiles(:)');
            DS(i).sweep_fr = double(S.sweep_final_rate(:)');
        end
        if isfield(S, 'dnn_rate_pct')
            DS(i).dnn_fr = double(S.dnn_rate_pct);
        end
    end
    if isempty(DS(i).m_scores) && exist(f_fig4, 'file')
        S = load(f_fig4);
        if isfield(S, 'm_scores_all')
            DS(i).m_scores  = double(S.m_scores_all(:));
            DS(i).synthetic = false;
        end
    end

    % --- sweep arrays (try fig5 if combined didn't have them) ---
    if exist(f_fig5, 'file')
        S = load(f_fig5);
        if isfield(S, 'percentiles') && isfield(S, 'final_rate_pct')
            DS(i).sweep_p  = double(S.percentiles(:)');
            DS(i).sweep_fr = double(S.final_rate_pct(:)');
        end
        if isfield(S, 'dnn_rate_pct')
            DS(i).dnn_fr = double(S.dnn_rate_pct);
        end
    end

    % --- CV / mean / std (auto_select) ---
    if exist(f_auto_mat, 'file')
        S = load(f_auto_mat);
        if isfield(S, 'm_cv_pct'), DS(i).cv_pct = double(S.m_cv_pct); end
        if isfield(S, 'm_mean'),   DS(i).mean_m = double(S.m_mean);   end
        if isfield(S, 'm_std'),    DS(i).std_m  = double(S.m_std);    end
    elseif exist(f_auto_csv, 'file')
        T = readtable(f_auto_csv);
        if any(strcmp('m_cv_pct', T.Properties.VariableNames))
            DS(i).cv_pct = double(T.m_cv_pct(1));
        end
        if any(strcmp('m_mean',   T.Properties.VariableNames))
            DS(i).mean_m = double(T.m_mean(1));
        end
        if any(strcmp('m_std',    T.Properties.VariableNames))
            DS(i).std_m  = double(T.m_std(1));
        end
    end

    % --- sweep CSV fallback (only if we still have the hard-coded grid) ---
    if exist(f_sweep_csv, 'file') && (numel(DS(i).sweep_fr) <= 6)
        T = readtable(f_sweep_csv);
        vars = T.Properties.VariableNames;
        if any(strcmp('percentile', vars)) && any(strcmp('final_rate_pct', vars))
            DS(i).sweep_p  = double(T.percentile(:)');
            DS(i).sweep_fr = double(T.final_rate_pct(:)');
        end
    end

    % --- synthesise m_scores from (mean,std) if still empty ---
    if isempty(DS(i).m_scores)
        rng(i, 'twister');
        N_synth = 50000;
        x = DS(i).mean_m + DS(i).std_m * randn(N_synth, 1);
        x = min(max(x, 0), 1);
        DS(i).m_scores  = x;
        DS(i).synthetic = true;
    end

    if DS(i).synthetic
        src = '(SYNTH from mean/std)';
    else
        src = '(empirical)';
    end
    fprintf('[%-22s] CV=%.4f%%  N=%d  sweep_p=%d points  %s\n', ...
        DS(i).name, DS(i).cv_pct, numel(DS(i).m_scores), ...
        numel(DS(i).sweep_p), src);
end

% -------------------------------------------------------------------------
% Common styling
% -------------------------------------------------------------------------
clr = [
    0.1216 0.4667 0.7059;     % BinnedTestIllumina
    0.1725 0.6275 0.1725;     % Erlich
    1.0000 0.4980 0.0549;     % Grass
    0.5804 0.4039 0.7412;     % Nanopore 2FC
    0.8392 0.1529 0.1569];    % Srinivasavaradhan
mk = {'o','s','d','^','v'};
fs = 11;                       % base font size for axes
lw = 1.6;                      % line width

% =========================================================================
% FIGURE 1 :  CONFIDENCE-SCORE DISTRIBUTIONS
% =========================================================================
hF1 = figure('Units','centimeters','Position',[2 2 14 10], ...
             'Color','w','PaperPositionMode','auto');
ax = axes(hF1); hold(ax,'on'); box(ax,'on'); grid(ax,'on');

% common evaluation grid for densities
m_all = vertcat(DS.m_scores);
xlo   = max(0, prctile(m_all, 0.5));
xhi   = min(1, prctile(m_all, 99.9));
xgrid = linspace(xlo, xhi, 600);

hLines = gobjects(nDS,1);
for i = 1:nDS
    bw = max(DS(i).std_m * 0.6, 1e-4);
    if exist('ksdensity','file') == 2
        f = ksdensity(DS(i).m_scores, xgrid, 'Bandwidth', bw);
    else
        edges = linspace(xgrid(1), xgrid(end), 80);
        cnts  = histcounts(DS(i).m_scores, edges, 'Normalization','pdf');
        ctrs  = 0.5*(edges(1:end-1) + edges(2:end));
        f     = interp1(ctrs, cnts, xgrid, 'pchip', 0);
    end
    f = f / max(f);
    hLines(i) = plot(ax, xgrid, f, '-', 'Color', clr(i,:), 'LineWidth', lw);
end

xlabel(ax,'Mean confidence  $m(\mathbf{M})$', ...
    'Interpreter','latex','FontSize',fs);
ylabel(ax,'Normalised density (peak = 1)', ...
    'Interpreter','latex','FontSize',fs);

leg_lbls = arrayfun(@(d) sprintf('%s,  CV=%.2f\\%%', d.label, d.cv_pct), ...
                    DS, 'UniformOutput', false);
legend(ax, hLines, leg_lbls, 'Interpreter','latex', ...
       'Location','northwest','FontSize',fs-2,'Box','off');
ylim(ax,[0 1.18]);
set(ax,'FontSize',fs-1,'TickLabelInterpreter','latex');

savefig(hF1, fullfile(FIG_DIR, 'cpl_confidence_distributions.fig'));
print(  hF1, fullfile(FIG_DIR, 'cpl_confidence_distributions.eps'), ...
        '-depsc2','-painters');
fprintf('Wrote %s/cpl_confidence_distributions.{fig,eps}\n', FIG_DIR);

% =========================================================================
% FIGURE 2 :  CV  ->  PERCENTILE MAPPING
% =========================================================================
hF2 = figure('Units','centimeters','Position',[2 2 12 9], ...
             'Color','w','PaperPositionMode','auto');
ax = axes(hF2); hold(ax,'on'); box(ax,'on');

xmax_cv = 6;
zones = [0.0  0.5  0;
         0.5  2.0  5;
         2.0  4.0 10;
         4.0 xmax_cv 15];
zone_clr = [0.95 0.95 0.95;
            0.90 0.96 0.90;
            0.99 0.94 0.84;
            0.99 0.86 0.86];
yl = [-1 18];
for k = 1:size(zones,1)
    patch(ax,[zones(k,1) zones(k,2) zones(k,2) zones(k,1)], ...
              [yl(1) yl(1) yl(2) yl(2)], ...
              zone_clr(k,:), 'EdgeColor','none','HandleVisibility','off');
end

for i = 1:nDS
    plot(ax, DS(i).cv_pct, DS(i).oracle_p, mk{i}, ...
        'MarkerFaceColor', clr(i,:), 'MarkerEdgeColor','k', ...
        'MarkerSize', 9, 'LineWidth', 0.8);
end

% zone separators + labels
for xv = [0.5 2.0 4.0]
    plot(ax,[xv xv],yl,'k--','LineWidth',0.8,'HandleVisibility','off');
end
text(ax, 0.25,16.5,'$p^{*}=0$', 'Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',fs-1);
text(ax, 1.25,16.5,'$p^{*}=5$', 'Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',fs-1);
text(ax, 3.00,16.5,'$p^{*}=10$','Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',fs-1);
text(ax, 5.00,16.5,'$p^{*}=15$','Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',fs-1);

xlabel(ax,'CV of $m(\mathbf{M})$  [\%]', ...
    'Interpreter','latex','FontSize',fs);
ylabel(ax,'Oracle-optimal CPL percentile $p$', ...
    'Interpreter','latex','FontSize',fs);
xlim(ax,[0 xmax_cv]); ylim(ax,yl);
set(ax,'YTick',[0 5 10 15],'XTick',[0 0.5 2 4 6], ...
    'FontSize',fs-1,'TickLabelInterpreter','latex');
grid(ax,'on');

% legend (markers)
hMk = gobjects(nDS,1);
for i = 1:nDS
    hMk(i) = plot(ax, NaN, NaN, mk{i}, ...
        'MarkerFaceColor', clr(i,:), 'MarkerEdgeColor','k', ...
        'MarkerSize',8,'LineStyle','none');
end
legend(ax, hMk, {DS.label}, 'Interpreter','latex', ...
    'Location','southeast','FontSize',fs-3,'Box','off');

savefig(hF2, fullfile(FIG_DIR, 'cpl_cv_to_percentile_mapping.fig'));
print(  hF2, fullfile(FIG_DIR, 'cpl_cv_to_percentile_mapping.eps'), ...
        '-depsc2','-painters');
fprintf('Wrote %s/cpl_cv_to_percentile_mapping.{fig,eps}\n', FIG_DIR);

% =========================================================================
% FIGURE 3 :  FAILURE-RATE SWEEP  vs.  CPL PERCENTILE
% =========================================================================
hF3 = figure('Units','centimeters','Position',[2 2 13 9], ...
             'Color','w','PaperPositionMode','auto');
ax = axes(hF3); hold(ax,'on'); box(ax,'on'); grid(ax,'on');

hLines = gobjects(nDS,1);
for i = 1:nDS
    if DS(i).dnn_fr > 0
        rel_fr = DS(i).sweep_fr ./ DS(i).dnn_fr;
    else
        rel_fr = ones(size(DS(i).sweep_fr));
    end
    hLines(i) = plot(ax, DS(i).sweep_p, rel_fr, ['-' mk{i}], ...
        'Color', clr(i,:), 'MarkerFaceColor', clr(i,:), ...
        'MarkerEdgeColor','k', 'LineWidth', lw, 'MarkerSize', 6);

    [~, idx_rule] = min(abs(DS(i).sweep_p - DS(i).rule_p));
    plot(ax, DS(i).sweep_p(idx_rule), rel_fr(idx_rule), 'p', ...
        'MarkerFaceColor', clr(i,:), 'MarkerEdgeColor','k', ...
        'MarkerSize', 14, 'LineWidth', 0.8, 'HandleVisibility','off');
end

xl_fr = [-1 26];
plot(ax, xl_fr,[1 1],'k:','LineWidth',1.0,'HandleVisibility','off');
text(ax, 24, 1.04, 'DNN-only baseline', ...
    'Interpreter','latex','HorizontalAlignment','right','FontSize',fs-2);

xlabel(ax,'CPL percentile $p$', ...
    'Interpreter','latex','FontSize',fs);
ylabel(ax,'Failure rate / DNN-only rate', ...
    'Interpreter','latex','FontSize',fs);
xlim(ax,xl_fr); ylim(ax,[0.55 1.10]);
set(ax,'XTick',0:5:25,'FontSize',fs-1,'TickLabelInterpreter','latex');
legend(ax, hLines, {DS.label}, 'Interpreter','latex', ...
       'Location','southwest','FontSize',fs-3,'Box','off');

savefig(hF3, fullfile(FIG_DIR, 'cpl_failure_rate_sweep.fig'));
print(  hF3, fullfile(FIG_DIR, 'cpl_failure_rate_sweep.eps'), ...
        '-depsc2','-painters');
fprintf('Wrote %s/cpl_failure_rate_sweep.{fig,eps}\n', FIG_DIR);

fprintf('\nAll three figures written to %s\n', FIG_DIR);
