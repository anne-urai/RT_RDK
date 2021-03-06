function motionEnergy_kernels()
addpath('~/Desktop/code/gramm');
global mypath;


% Code to fit the history-dependent drift diffusion models as described in
% Urai AE, de Gee JW, Tsetsos K, Donner TH (2019) Choice history biases subsequent evidence accumulation. eLife, in press.
%
% MIT License
% Copyright (c) Anne Urai, 2019
% anne.urai@gmail.com


%{
    Psychophysical kernels were computed by averaging contrast fluctuations as a
function of the sample number of the test stimulus. We treated the reference grating
as if it had been shown at the same time of the test stimulus for the same duration.
The psychophysical kernel at time point t is then given by:
E(t) = hE(t)S i + hE(t)N i
E(t)S is the contrast fluctuation of the selected option at time t and E(t)N is the c
ontrast fluctuation of the non selected stimulus at time t. Absolute stimulus contrast
was transformed into contrast fluctuation by subtracting average generative contrast
values (e.g. QUEST threshold) for the respective trial type (0.5 + threshold or 0.5 ?
threshold). Average generative contrast values were computed in blocks of 100 trials,
corresponding to natural blocks in the experiment after which participants took a
short break. The expectation is across trials.
%}

close all;
path = '~/Data/psychophysicalKernels';

for maxcohlevel = 27; %[0,3,9,27,81],
    
    close all;
    
    % either all the data or only neutral
    load(sprintf('%s/%s', path, 'motionEnergyData_AnkeMEG.mat'));
    
    % use the normalized motion energy, so that the units are % coherence 'up'
    data.motionenergy = data.motionenergy_normalized;
    
    % only select trials without any objective evidence level - remove high
    % coherence trials!
    data.motionenergy = data.motionenergy([data.behavior.coherence] <= maxcohlevel, :);
    data.behavior     = data.behavior([data.behavior.coherence] <= maxcohlevel, :);
    
    % what is the time-course of evidence that leads subjects to make their
    % preferred vs non-preferred choice?
    kernelFun       = @(x, y) nanmean(x(y, :)) - nanmean(x(~y, :));
    
    % recode into choices that are biased or not
    data.behavior.repeat = (data.behavior.response == data.behavior.prevresp);
    
    % for each observers, compute their bias
    [gr, sjs]   = findgroups(data.behavior.subj_idx);
    sjrep       = splitapply(@nanmean, data.behavior.repeat, gr);
    sjrep       = sjs(sjrep < 0.5);
    
    % recode into biased and unbiased choices
    data.behavior.biased = data.behavior.repeat;
    altIdx      = ismember(data.behavior.subj_idx, sjrep);
    data.behavior.biased(altIdx) = double(~(data.behavior.biased(altIdx))); % flip
    
    % bin
    coh                   = [data.behavior.stimulus .* data.behavior.coherence];
    [gr, sj, coh]         = findgroups(data.behavior.subj_idx, coh);
    kernels               = splitapply(kernelFun, data.motionenergy, (data.behavior.response > 0), gr);
    
    % average within each subject!
    if numel(unique(coh)) > 1,
        kernels = splitapply(@nanmean, kernels, findgroups(sj));
    end
    
    % =============================== %
    % PSYCHOPHYSICAL KERNELS - without bias
    % =============================== %
    
    % then average over coherence levels within each subject
    subplot(441);
    hold on;
    colors(1, :) = [0.3 0.3 0.3]; c = 1;
    % plot(data.timeaxis, nanmean(kernels), 'color', colors(c, :), 'linewidth', 0.5);
    b{c} = boundedline(data.timeaxis(13:end), nanmean(kernels(:, 13:end)), ...
        nanstd(kernels(:, 13:end)) ./ sqrt(length(unique(sj))), 'cmap', colors(c, :), 'alpha');
    plot(data.timeaxis(13:end), nanmean(kernels(:, 13:end)), 'color', colors(c, :), 'linewidth', 1);
    axis tight;
    
    % do statistics on the timecourse
    [h, p, stat] = ttest_clustercorr(kernels(:, 13:end));
    ylims = get(gca, 'Ylim');
    mask = [zeros(1,12) double(h)];
    mask(mask==0) = nan;
    mask = ((ylims(2)*0.1)+ylims(1))*mask; % plot a tiny bit above the lower ylim
    plot(data.timeaxis, mask, '.', 'MarkerSize', 10, 'color', 'k');
    
    ylabel({'Excess motion'; 'energy fluctuations (%)'});
    xlabel('Time from stimulus onset (s)');
    axis tight; xlim([0.2 0.75]); set(gca, 'xtick', 0.2:0.1:0.7);
    box off; offsetAxes;
    set(gca, 'xcolor', 'k', 'ycolor', 'k');
    tightfig;
    print(gcf, '-dpdf', '~/Data/serialHDDM/psychophysicalKernels.pdf');
    close ;
    
    % %% COMPARE THE KERNELS WITH THE O-U EFFECTIVE LEAK PARAMETER
    % results     = readtable(sprintf('%s/summary/%s/allindividualresults_kostis.csv', mypath, 'Anke_MEG_transition'));
    % lambda      = results.ouD_vanilla_lambda;
    % kernelDiff  = nanmean(kernels(:, 13:29), 2) - nanmean(kernels(:, 30:45), 2);
    % [rho, pval] = corr(kernelDiff, lambda, 'type', 'spearman');
    % fprintf('\n\nCorrelation between kernels and O-U lambda, Spearmans rho: %.3f, p = %.3f \n', rho, pval);
  
end

end