function b4_renamePPCfiles(datasets)

close all; clc;
mypath  = '/nfs/aeurai/HDDM';
mdls = {'stimcoding_nohist', ...
'stimcoding_dc_prevresp', ...
'stimcoding_z_prevresp', ...
'stimcoding_dc_z_prevresp', ...
'stimcoding_dc_z_prevresp_st', ...
'stimcoding_dc_z_prevresp_pharma', ...
'stimcoding_dc_z_prevcorrect', ...
'stimcoding_prevcorrect', ...
'stimcoding_dc_z_prev2resp', ...
'stimcoding_dc_z_prevresp_multiplicative', ...
'stimcoding_dc_prevresp_multiplicative'};

for d = 1:length(datasets),
for m = 1:length(mdls),
	try
	copyfile(sprintf('%s/%s/%s/ppc_data.csv', mypath, datasets{d}, mdls{m}), ...
	sprintf('%s/summary/%s/%s_ppc_data.csv', mypath, datasets{d}, mdls{m}));
end
end
end
