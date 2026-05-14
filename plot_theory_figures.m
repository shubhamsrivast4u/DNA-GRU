%% =========================================================================
%  plot_theory_figures.m  (v2 — fixed visibility issues)
%
%  USAGE: Place alongside Experiments/ directory, then run.
%  Saves .fig and .eps into Experiments/TheoryFigures/
% =========================================================================

clear; clc; close all;

%% ── Configuration ──
datasets   = {'Erlich','Grass','Srinivasavaradhan','BinnedTestIllumina','BinnedNanoporeTwoFlowcells'};
short_names = {'Erlich','Grass','Sriniv.','Illumina','Nano2FC'};
colors = lines(5);
base_dir = './Experiments';
out_dir  = fullfile(base_dir, 'TheoryFigures');
if ~exist(out_dir,'dir'), mkdir(out_dir); end

%% ── Helper: read JSON ──
read_json = @(f) jsondecode(fileread(f));

%% ========================================================================
%  Figure 1: Effective Context Radius (grouped bar + value labels)
%  FIX: Add numeric labels on each bar so small values are visible
%% ========================================================================

figure('Position',[100 100 750 380]);

pct90 = zeros(1,5); pct99 = zeros(1,5); Ls = zeros(1,5);
for i = 1:length(datasets)
    ds = datasets{i};
    cr_file = fullfile(base_dir,[ds '_v4'],'TheoryAnalysis','Results','context_radius.json');
    if ~isfile(cr_file)
        cr_file = fullfile(base_dir,[ds '_v4'],'TheoryAnalysis','Results',['context_radius_' lower(ds) '.json']);
    end
    if isfile(cr_file)
        cr = read_json(cr_file);
        pct90(i) = cr.pct90.mean;
        pct99(i) = cr.pct99.mean;
    end
    sf = fullfile(base_dir,[ds '_v4'],'TheoryAnalysis','Results',['summary_' ds '.json']);
    if isfile(sf)
        sd = read_json(sf);
        Ls(i) = sd.label_seq_len;
    end
end

X = categorical(short_names);
X = reordercats(X, short_names);
b = bar(X, [pct90; pct99]', 'grouped');
b(1).FaceColor = [0.2 0.4 0.8]; b(1).FaceAlpha = 0.85;
b(2).FaceColor = [0.85 0.25 0.2]; b(2).FaceAlpha = 0.85;

ylabel('Context Radius $w$','Interpreter','latex','FontSize',12);
legend({'$w_{90}$ (90\%)','$w_{99}$ (99\%)'},'Interpreter','latex','Location','northwest','FontSize',10);
title('Effective Context Radius by Dataset','Interpreter','latex','FontSize',13);
set(gca,'FontSize',11,'TickLabelInterpreter','latex');
grid on; box on;

% Add value labels on top of each bar
hold on;
for k = 1:2
    xdata = b(k).XEndPoints;
    ydata = b(k).YEndPoints;
    vals = [pct90; pct99];
    for j = 1:length(xdata)
        text(xdata(j), ydata(j)+2, sprintf('%.1f', vals(k,j)), ...
            'HorizontalAlignment','center','FontSize',8,'FontWeight','bold');
    end
end
% Add L= annotations at top
for i = 1:length(datasets)
    text(i, max(pct99(i),pct90(i))+8, sprintf('$L{=}%d$',Ls(i)), ...
        'HorizontalAlignment','center','FontSize',8,'Interpreter','latex','Color',[0.3 0.3 0.3]);
end
hold off;

savefig(fullfile(out_dir,'fig_context_radius.fig'));
exportgraphics(gcf, fullfile(out_dir,'fig_context_radius.eps'),'ContentType','vector');
fprintf('Saved fig_context_radius\n');


%% ========================================================================
%  Figure 2: Cluster Size vs Failure Rate
%  FIX: Don't filter by total>10. Show Erlich/Illumina as single K=16
%       annotated points since they have almost no data at other sizes.
%% ========================================================================

figure('Position',[100 100 750 420]);

% Datasets with data across K=1..16
rich_ds    = {'Grass','Srinivasavaradhan','BinnedNanoporeTwoFlowcells'};
rich_names = {'Grass','Sriniv.','Nano2FC'};
rich_idx   = [2, 3, 5];

for ii = 1:length(rich_ds)
    ds = rich_ds{ii};
    ci = rich_idx(ii);
    mf = fullfile(base_dir,[ds '_v4'],'TheoryAnalysis','MatFiles',['theory_clustersize_' ds '.mat']);
    if ~isfile(mf), continue; end
    d = load(mf);
    semilogy(d.cluster_sizes, d.failure_rate_pct, 'o-', ...
        'Color',colors(ci,:),'LineWidth',1.8,'MarkerSize',6, ...
        'MarkerFaceColor',colors(ci,:),'DisplayName',rich_names{ii});
    hold on;
end

% Datasets where nearly all clusters have K=16 — show as annotated squares
sparse_ds = {'Erlich','BinnedTestIllumina'};
sparse_ci = [1, 4];
sparse_names = {'Erlich','Illumina'};
for ii = 1:length(sparse_ds)
    ds = sparse_ds{ii};
    ci = sparse_ci(ii);
    mf = fullfile(base_dir,[ds '_v4'],'TheoryAnalysis','MatFiles',['theory_clustersize_' ds '.mat']);
    if ~isfile(mf), continue; end
    d = load(mf);
    idx16 = find(d.cluster_sizes == 16);
    if ~isempty(idx16)
        semilogy(16, d.failure_rate_pct(idx16), 's', ...
            'Color',colors(ci,:),'MarkerSize',10,'LineWidth',2, ...
            'MarkerFaceColor',colors(ci,:),'DisplayName',[sparse_names{ii} ' ($K{=}16$)']);
    end
end
hold off;

xlabel('Cluster Size $K$','Interpreter','latex','FontSize',12);
ylabel('Failure Rate (\%)','Interpreter','latex','FontSize',12);
title('DNA-GRU: Failure Rate vs.\ Cluster Size','Interpreter','latex','FontSize',13);
legend('show','Location','northeast','Interpreter','latex','FontSize',9);
set(gca,'FontSize',11,'TickLabelInterpreter','latex');
xlim([0.5 16.5]); xticks(1:16);
grid on; box on;

savefig(fullfile(out_dir,'fig_clustersize.fig'));
exportgraphics(gcf, fullfile(out_dir,'fig_clustersize.eps'),'ContentType','vector');
fprintf('Saved fig_clustersize\n');


%% ========================================================================
%  Figure 3: Edit Distance Distribution of Failures
%% ========================================================================

figure('Position',[100 100 750 320]);
hard_ds = {'Srinivasavaradhan','BinnedNanoporeTwoFlowcells'};
hard_names = {'Srinivasavaradhan','BinnedNanopore2FC'};
hard_colors = [colors(3,:); colors(5,:)];

for i = 1:length(hard_ds)
    ds = hard_ds{i};
    mf = fullfile(base_dir,[ds '_v4'],'TheoryAnalysis','MatFiles',['theory_errors_' ds '.mat']);
    if ~isfile(mf), continue; end
    d = load(mf);
    
    eds = d.edit_distances;
    max_ed = min(10, max(eds));
    edges = 0.5:(max_ed+1.5);
    
    subplot(1,2,i);
    histogram(eds, edges, 'FaceColor',hard_colors(i,:), 'FaceAlpha',0.75, 'EdgeColor','w');
    xlabel('Edit Distance','Interpreter','latex','FontSize',11);
    ylabel('Count','Interpreter','latex','FontSize',11);
    title(hard_names{i},'Interpreter','latex','FontSize',12);
    set(gca,'FontSize',10,'TickLabelInterpreter','latex');
    xlim([0.5 max_ed+1.5]);
    grid on; box on;
    
    % Annotate
    n_total = length(eds);
    ed1_n = sum(eds==1); ed2_n = sum(eds==2);
    text(1, ed1_n + n_total*0.03, sprintf('%.0f\\%%', ed1_n/n_total*100), ...
        'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
    text(max_ed*0.7, n_total*0.7, sprintf('ED$\\leq$2: %.0f\\%%', (ed1_n+ed2_n)/n_total*100), ...
        'Interpreter','latex','FontSize',9,'BackgroundColor','w','EdgeColor',[0.5 0.5 0.5]);
end

savefig(fullfile(out_dir,'fig_error_breakdown.fig'));
exportgraphics(gcf, fullfile(out_dir,'fig_error_breakdown.eps'),'ContentType','vector');
fprintf('Saved fig_error_breakdown\n');


%% ========================================================================
%  Figure 4: Per-Position Error Rate (2x2 subplot)
%% ========================================================================

figure('Position',[100 100 750 520]);
plot_ds = {'BinnedTestIllumina','Grass','BinnedNanoporeTwoFlowcells','Srinivasavaradhan'};
plot_names = {'BinnedTestIllumina','Grass','BinnedNanopore2FC','Srinivasavaradhan'};
plot_ci = [4, 2, 5, 3];

for i = 1:length(plot_ds)
    ds = plot_ds{i};
    mf = fullfile(base_dir,[ds '_v4'],'TheoryAnalysis','MatFiles',['theory_perpos_' ds '.mat']);
    if ~isfile(mf), continue; end
    d = load(mf);
    
    subplot(2,2,i);
    bar(d.positions, d.error_rate, 'FaceColor',colors(plot_ci(i),:), ...
        'FaceAlpha',0.7, 'EdgeColor','none');
    xlabel('Position $t$','Interpreter','latex','FontSize',10);
    ylabel('Error Rate','Interpreter','latex','FontSize',10);
    title(plot_names{i},'Interpreter','latex','FontSize',11);
    set(gca,'FontSize',9,'TickLabelInterpreter','latex');
    grid on; box on;
    
    % Mark max error position
    [mx, mx_idx] = max(d.error_rate);
    hold on;
    plot(d.positions(mx_idx), mx, 'rv', 'MarkerSize',6, 'MarkerFaceColor','r');
    hold off;
end

savefig(fullfile(out_dir,'fig_perposition.fig'));
exportgraphics(gcf, fullfile(out_dir,'fig_perposition.eps'),'ContentType','vector');
fprintf('Saved fig_perposition\n');


%% ========================================================================
%  Figure 5: DNA-GRU vs DNAformer Context Radius Comparison
%  Side-by-side grouped bar for BinnedNanoporeTwoFlowcells
%% ========================================================================

figure('Position',[100 100 700 380]);

ds = 'BinnedNanoporeTwoFlowcells';

% DNA-GRU data (hardcoded from results — or load from JSON)
gru_cr_file = fullfile(base_dir,[ds '_v4'],'TheoryAnalysis','Results','context_radius.json');
dnaf_cr_file = fullfile(base_dir,[ds '_v4'],'TheoryAnalysis','Results',['dnaformer_context_radius_' ds '.json']);

gru_w  = [3.4, 13.1, 45.2, 69.3, 85.8];   % fallback values
dnaf_w = [33.4, 61.6, 82.0, 89.0, 94.6];   % fallback values

if isfile(gru_cr_file)
    g = read_json(gru_cr_file);
    gru_w = [g.pct50.mean, g.pct75.mean, g.pct90.mean, g.pct95.mean, g.pct99.mean];
end
if isfile(dnaf_cr_file)
    d = read_json(dnaf_cr_file);
    dnaf_w = [d.pct50.mean, d.pct75.mean, d.pct90.mean, d.pct95.mean, d.pct99.mean];
end

pct_labels = {'$w_{50}$','$w_{75}$','$w_{90}$','$w_{95}$','$w_{99}$'};
X = categorical(pct_labels);
X = reordercats(X, pct_labels);

b = bar(X, [gru_w; dnaf_w]', 'grouped');
b(1).FaceColor = [0.2 0.6 0.3]; b(1).FaceAlpha = 0.85;  % green for DNA-GRU
b(2).FaceColor = [0.8 0.3 0.2]; b(2).FaceAlpha = 0.85;  % red for DNAformer

ylabel('Context Radius (positions)','Interpreter','latex','FontSize',12);
legend({'DNA-GRU (3.4M)','DNAformer (103.4M)'},'Interpreter','latex','Location','northwest','FontSize',10);
title('Effective Context Radius: DNA-GRU vs.\ DNAformer (BinnedNanopore2FC, $L{=}128$)','Interpreter','latex','FontSize',12);
set(gca,'FontSize',11,'TickLabelInterpreter','latex');
grid on; box on;

% Add value labels
hold on;
for k = 1:2
    xd = b(k).XEndPoints;
    yd = b(k).YEndPoints;
    vals = [gru_w; dnaf_w];
    for j = 1:length(xd)
        text(xd(j), yd(j)+1.5, sprintf('%.1f', vals(k,j)), ...
            'HorizontalAlignment','center','FontSize',8,'FontWeight','bold');
    end
end

% Add dashed line at L=128
yline(128, 'k--', '$L=128$','Interpreter','latex','FontSize',9,...
    'LabelHorizontalAlignment','right','Alpha',0.5);
hold off;

savefig(fullfile(out_dir,'fig_context_comparison.fig'));
exportgraphics(gcf, fullfile(out_dir,'fig_context_comparison.eps'),'ContentType','vector');
fprintf('Saved fig_context_comparison\n');


%% ── Done ──
fprintf('\nAll figures saved to: %s\n', out_dir);
d = dir(fullfile(out_dir,'*.*'));
for i = 1:length(d)
    if ~d(i).isdir, fprintf('  %s\n', d(i).name); end
end
