function make_distance_matrix(RefCifti,MidthickSurfs,OutDir,nThreads)
% cjl2007@med.cornell.edu; 

try % make tmp directory
    mkdir([OutDir '/tmp/']);
catch
end

% load ref. CIFTI
if ischar(RefCifti)
    RefCifti = ft_read_cifti_mod(RefCifti);
end

RefCifti.data=[]; % remove data, not needed

% load midthickness surfaces 
LH = gifti(MidthickSurfs{1});
RH = gifti(MidthickSurfs{2});

% find cortical vertices on surface cortex (not medial wall)
LH_idx = RefCifti.brainstructure(1:length(LH.vertices))~=-1;
RH_idx = RefCifti.brainstructure((length(LH.vertices)+1):(length(LH.vertices)+length(RH.vertices)))~=-1;

% preallocate "reference verts"
LH_verts=1:length(LH.vertices);
RH_verts=1:length(RH.vertices);

% cortical vertices only
LH_verts=LH_verts(LH_idx);
RH_verts=RH_verts(RH_idx);

% preallocate mats
LH_mats = zeros(length(LH_verts), length(LH_verts), "uint16");
RH_mats = zeros(length(RH_verts), length(RH_verts), "uint16");

% start parpool;
pool = parpool('local',nThreads);

% sweep through vertices
parfor i = 1:length(LH_verts)
    
    % calculate geodesic distances from vertex i
    system(['wb_command -surface-geodesic-distance ' MidthickSurfs{1} ' ' num2str(LH_verts(i)-1) ' ' OutDir '/tmp/temp_' num2str(i) '.shape.gii']);
    temp = gifti([OutDir '/tmp/temp_' num2str(i) '.shape.gii']);
    system(['rm ' OutDir '/tmp/temp_' num2str(i) '.shape.gii']);
    LH_mats(:,i) = temp.cdata(LH_idx); % log distances
        
end

% sweep through vertices
parfor i = 1:length(RH_verts)
    
    % calculate geodesic distances from vertex i
    system(['wb_command -surface-geodesic-distance ' MidthickSurfs{2} ' ' num2str(RH_verts(i)-1) ' ' OutDir '/tmp/temp_' num2str(i) '.shape.gii']);
    temp = gifti([OutDir '/tmp/temp_' num2str(i) '.shape.gii']);
    system(['rm ' OutDir '/tmp/temp_' num2str(i) '.shape.gii']);
    RH_mats(:,i) = temp.cdata(RH_idx); % log distances
    
end

% delete 
% parpool
delete(pool);

% remove temp dir.;
[~,~]=system(['rm -rf ' OutDir '/tmp/']);


% piece together results (999 = inter-hemispheric)
Top = [LH_mats ones(length(LH_mats),length(RH_mats))*999]; % lh & dummy rh
Bottom = [ones(length(RH_mats),length(LH_mats))*999 RH_mats]; % dummy lh & rh
D = uint16([Top;Bottom]); % combine hemispheres; cortical surface only so far
%D = [Top; Bottom];

% extract coordinates for all cortical vertices 
SurfaceCoords=[LH.vertices; RH.vertices]; % combine hemipsheres 
SurfaceIndex = RefCifti.brainstructure > 0 & RefCifti.brainstructure < 3;
SurfaceIndex = SurfaceIndex(1:size(SurfaceCoords,1));
SurfaceCoords = SurfaceCoords(SurfaceIndex,:);
SubcorticalCoords = RefCifti.pos(RefCifti.brainstructure>2,:);
AllCoords = [SurfaceCoords;SubcorticalCoords]; % combine 

% compute euclidean distance 
% between all vertices & voxels 
D2 = uint16(pdist2(AllCoords,AllCoords));
% D2 = pdist2(AllCoords,AllCoords);

% combine distance matrices; geodesic & euclidean  
D = [D ; D2(size(D,1)+1:end,1:size(D,2))]; % vertcat
D = [D  D2(1:size(D,1),size(D,2)+1:end)]; % horzcat 
clear D2;

% save distance matrix;
save([OutDir '/DistanceMatrix'],'D','-v7.3');

% clear 
% distances
clear D;

end