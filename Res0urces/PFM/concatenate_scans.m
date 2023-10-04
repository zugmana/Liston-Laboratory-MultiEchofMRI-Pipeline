function [Output,SessionIdx,FD] = concatenate_scans(Subdir,File,Sessions)

% preallocate 
ConcatenatedData = []; % concatenated dataset;
SessionIdx = []; % index of what frames belong to which session;
FD = []; % framewise displacement (head movement);

% sweep the sessions
for s = 1:length(Sessions)

    % count the number of runs for this session;
    run_dirs = dir([Subdir '/func/rest/session_' num2str(Sessions(s)) '/run_*']);

    % sweep the runs;
    for r = 1:length(run_dirs)
        
        % load head motion parameters;
        rp = load([run_dirs(r).folder '/' run_dirs(r).name '/MCF.par']);
        
        % define the TR
        TR = load([run_dirs(r).folder '/' run_dirs(r).name '/TR.txt']);

        % calculate FD;
        [fd] = calc_fd(rp,TR);
             
        % load the cifti file;
        c = ft_read_cifti_mod([run_dirs(r).folder '/' run_dirs(r).name '/' File '.dtseries.nii']);
        c.data = c.data - mean(c.data,2); % demean;
        
        % log the data;
        ConcatenatedData = [ConcatenatedData c.data]; % concatenate;
        SessionIdx = [SessionIdx ; ones(size(c.data,2),1) * s ones(size(c.data,2),1) * r]; %  session index;
        FD = [FD ; fd]; %  session index;
 
    end
        
end

Output = c; % this is the output cifti;
Output.data = ConcatenatedData;

end

function [fd]=calc_fd(rp,tr)

% nyquist freq.
nyq = (1/tr)/2;

% create a tailored
% stop band filter;
% if the top of the stop band is >= 1, just drop the filtering
if nyq > 0.2
    [B,A] = butter(10,stopband/nyq,'stop');

    % apply stopband filter 
    for i = 1:size(rp,2)
        rp(:,i) = filtfilt(B,A,rp(:,i));
    end
end
% calc. backward difference;
n_trs = round(2.5 / tr);

fd = rp; % preallocate
fd(1:n_trs,:) = 0; % by convention

% sweep the columns;
for i = 1:size(rp,2)
    for ii = (n_trs+1):size(fd,1)
        fd(ii,i) = abs(rp(ii,i)-rp(ii-n_trs,i));
    end
end

fd_ang = fd(:,1:3); % convert rotation columns into angular displacement...
fd_ang = fd_ang / (2 * pi); % fraction of circle
fd_ang = fd_ang * 100 * pi; % multiplied by circumference

fd(:,1:3) = []; % delete rotation columns,
fd = [fd fd_ang]; % add back in as angular displacement
fd = sum(fd,2); % sum

end
