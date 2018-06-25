
%%
path = '~/Data/psychophysicalKernels';
files = {'motionEnergyData_Bharath.mat', 'motionEnergyData_AnkeMEG.mat'};
axis_square =  @(gramm_obj) gramm_obj.axe_property('PlotBoxAspectRatio', [1 1 1]);

for f = 2:length(files),
    
    load(sprintf('%s/%s', path, files{f}));
    
    % RESCALE THE SINGLE-TRIAL MOTION ENERGY TRACES SO THEY MATCH THEIR
    % AVERAGE COHERENCE LEVEL
    if all(data.behavior.coherence < 1),
        data.behavior.coherence = data.behavior.coherence * 100; % express in percent
    end
    c = [data.behavior.coherence].* [data.behavior.stimulus];
    e = nanmean(data.motionenergy(:, 13:end), 2);
    a = splitapply(@nanmean, e, findgroups(c));
    
    plot(unique(c), a, 'o'); grid on; lsline;
    b = glmfit(a, unique(c));
    
    % NORMALIZE
    data.motionenergy_normalized = data.motionenergy * b(2);
    subplot(221);plot( c, data.motionenergy(:, end), '.')
    subplot(222);plot( c, data.motionenergy_normalized(:, end), '.')
    [gr, idx] = findgroups(c);
    avg = splitapply(@nanmean, nanmean(data.motionenergy_normalized(:, 13:end), 2), gr);
    subplot(223); plot(idx, avg, 'o'); refline(1);
    
    % SAVE THE NORMALIZED RESULTS
    savefast(sprintf('%s/%s', path, files{f}), 'data');
  
    %% NOW MAKE A NICE-LOOKING PLOT FOR THE PAPER
    
    % use the normalized motion energy for these plots
    data.motionenergy = data.motionenergy_normalized;
    
    data.motionenergy = data.motionenergy([data.behavior.transitionprob] == 0.5, :);
    data.behavior = data.behavior([data.behavior.transitionprob] == 0.5, :);
    
    stim = data.behavior.coherence .* data.behavior.stimulus;
    close all;
    set(groot, 'defaultAxesColorOrder', coolwarm(9));
    subplot(4,4,1); % timecourse
    hold on;
    avg = splitapply(@nanmean, data.motionenergy, findgroups(stim));
    plot(data.timeaxis(1:13), avg(:, 1:13), 'linewidth', 0.5);
    plot(data.timeaxis(13:end), avg(:, 13:end), 'linewidth', 1.5);
    axis tight; xlim([0 0.8]);
    set(gca, 'ytick', unique(stim), 'yticklabel', {'-81', '-27', ' ', ' ', '0', '', ' ', '27', '81'}, 'xtick', 0:0.25:0.75); box off;
    offsetAxes; %axis square;
    xlabel('Time from stimulus onset (s)'); ylabel('Motion energy (%)');
    
    subplot(442);
    colormap(coolwarm);
    scatter(stim, nanmean(data.motionenergy(:, 13:end), 2), 1, stim, 'jitter','on', 'jitterAmount', 1);
    xlabel('Motion coherence (%)');
    ylabel('Motion energy (%)');
    set(gca, 'xtick', unique(stim), 'xticklabel', {'-81', '-27', ' ', '', '0', '', ' ', '27', '81'});
    axis tight;
    offsetAxes; axis square;
    
    tightfig;
    print(gcf, '-dpdf', sprintf('%s/%s', path, regexprep(files{f}, '.mat', '.pdf')));
    print(gcf, '-dpdf', '~/Data/serialHDDM/motionEnergyFluctuations.pdf');
    
    % =============================== %
    % WRITE TO CSV FOR HDDM
    % =============================== %
    
    dat = data.behavior;
    dat = dat(dat.transitionprob == 0.5, :);
    
    % include previous trial info
    dat.prevresp    = circshift(dat.response, 1);
    dat.prevstim    = circshift(dat.stimulus, 1);
    dat.prevrt      = circshift(dat.RT, 1);
    
    dat.prev2resp    = circshift(dat.response, 2);
    dat.prev2stim    = circshift(dat.stimulus, 2);
    
    % recode
    dat.Properties.VariableNames{'RT'}          = 'rt'; % from stimulus offset?
    dat.Properties.VariableNames{'trialnum'}    = 'trial';
    dat.stimulus    = dat.coherence .* dat.stimulus;
    dat.response    = (dat.response > 0);
    
    % remove the trials that cannot be used
    wrongTrls       = ([NaN; diff(dat.trial)] ~= 1);
    dat(wrongTrls, :) = [];
    
    % take only a subset of variables for hddm fits
    dat             = dat(:, {'subj_idx', 'session', 'block', 'trial', 'stimulus', 'coherence', ...
        'response', 'rt', 'prevstim', 'prevresp', 'prev2resp', 'prev2stim', 'prevrt'});
    
    % remove trials with any NaN left in them
    dat(isnan(mean(dat{:, :}, 2)), :) = [];
    
    % write
    dat.rt = dat.rt + 0.25;
    writetable(dat, sprintf('%s/%s', path, regexprep(files{f}, '.mat', '.csv')));
    writetable(dat, '~/Data/HDDM/Anke_MEG_neutral/Anke_MEG_neutral.csv');
    
end