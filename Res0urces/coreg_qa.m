
% infer subject name;
Subject = strsplit(Subdir,'/');
Subject = Subject{length(Subject)};

% this is the brain mask in functional volume space;
BrainMask = niftiread([Subdir '/func/xfms/rest/T1w_acpc_brain_func_mask.nii.gz']);

% this is the target image (the average SBref image in ACPC volume space);
TargetImage = niftiread([Subdir '/func/xfms/rest/AvgSBref2acpc_EpiReg+BBR.nii.gz']);

% define the number of sessions;
sessions = dir([Subdir '/func/rest/session_*']);

count = 0; % tick

% sweep the scans;
for s = 1:length(sessions)
    disp(s)
    % this is the number of runs for this session;
    runs = dir([Subdir '/func/rest/session_' num2str(s) '/run_*']);
    
    % sweep the runs;
    for r = 1:length(runs)
        %disp(r)   
        % tick
        count = count+1;

        % extract the SBref coregistered to target volume using average field map information;
        Volume = niftiread([Subdir '/func/qa/CoregQA/SBref2acpc_EpiReg+BBR_AvgFM_S' num2str(s) '_R' num2str(r) '.nii.gz']);
        disp(Volume)
        % log spatial correlation;
        Rho(count,1) = corr(Volume(BrainMask==1),TargetImage(BrainMask==1),'type','Spearman');
        disp(Rho)
        % if scan-specific field map exists; otherwise use NaN place-holder;
        if exist([Subdir '/func/qa/CoregQA/SBref2acpc_EpiReg+BBR_ScanSpecificFM_S' num2str(s) '_R' num2str(r) '.nii.gz'])
            Volume = niftiread([Subdir '/func/qa/CoregQA/SBref2acpc_EpiReg+BBR_ScanSpecificFM_S' num2str(s) '_R' num2str(r) '.nii.gz']);
            Rho(count,2) = corr(Volume(BrainMask==1),TargetImage(BrainMask==1),'type','Spearman');
        else
            Rho(count,2) = nan;
        end
        
        % check which approach works best;
        if Rho(count,1) > Rho(count,2) || isnan(Rho(count,2))
            system(['echo ' Subdir '/func/xfms/rest/AvgSBref.nii.gz > ' Subdir '/func/rest/session_' num2str(s) '/run_' num2str(r) '/IntermediateCoregTarget.txt']);
            system(['echo ' Subdir '/func/xfms/rest/AvgSBref2acpc_EpiReg+BBR_warp.nii.gz > ' Subdir '/func/rest/session_' num2str(s) '/run_' num2str(r) '/Intermediate2ACPCWarp.txt']);
        else
            system(['echo ' Subdir '/func/rest/session_' num2str(s) '/run_' num2str(r) '/SBref.nii.gz > ' Subdir '/func/rest/session_' num2str(s) '/run_' num2str(r) '/IntermediateCoregTarget.txt']);
            system(['echo ' Subdir '/func/xfms/rest/SBref2acpc_EpiReg+BBR_S' num2str(s) '_R' num2str(r) '_warp.nii.gz > ' Subdir '/func/rest/session_' num2str(s) '/run_' num2str(r) '/Intermediate2ACPCWarp.txt']);
        end

    end
    
end

% save Rho variable
save([Subdir '/func/qa/CoregQA/Rho'],'Rho');
exit