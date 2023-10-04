
% define subject 
% directory and surface files;
str = strsplit(Subdir,'/'); Subject = str{end};
MidthickSurfs{1} = [Subdir '/anat/T1w/fsaverage_LR32k/' Subject '.L.midthickness.32k_fs_LR.surf.gii'];
MidthickSurfs{2} = [Subdir '/anat/T1w/fsaverage_LR32k/' Subject '.R.midthickness.32k_fs_LR.surf.gii'];

% denoising QC;
%. grayplot_qa_func(Subdir);

% concatenate and smooth resting-state fMRI datasets;
nSessions = length(dir([Subdir '/func/rest/session_*']));
[C,ScanIdx,FD] = concatenate_scans(Subdir,'Rest_OCME+MEICA+MGTR',1:nSessions);
mkdir([Subdir '/func/rest/ConcatenatedCiftis']);
cd([Subdir '/func/rest/ConcatenatedCiftis']);

% make distance matrix and then regress
% adjacent cortical signals from subcortical voxels;
make_distance_matrix(C,MidthickSurfs,[Subdir '/anat/T1w/fsaverage_LR32k/'],8);
[C] = regress_cortical_signals(C,[Subdir '/anat/T1w/fsaverage_LR32k/DistanceMatrix.mat'],20);
ft_write_cifti_mod([Subdir '/func/rest/ConcatenatedCiftis/Rest_OCME+MEICA+MGTR_Concatenated+SubcortRegression.dtseries.nii'],C);
save([Subdir '/func/rest/ConcatenatedCiftis/ScanIdx'],'ScanIdx');
save([Subdir '/func/rest/ConcatenatedCiftis/FD'],'FD');
clear C % clear intermediate file
    
% sweep a range of
% smoothing kernels;
for k = [2.55, 5.0]
    smooth_cifti(Subdir,'Rest_OCME+MEICA+MGTR_Concatenated+SubcortRegression.dtseries.nii',['Rest_OCME+MEICA+MGTR_Concatenated+SubcortRegression+SpatialSmoothing' num2str(k) '.dtseries.nii'],k,k);
end



