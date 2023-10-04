function [fd,rp]=calc_fd(rp,tr)

% nyquist freq.
nyq = (1/tr)/2;

% create a tailored
% stop band filter;
% if the top of the stop band is >= 1, need to bump it down a bit
if nyq <= 0.2
    stopband = [(nyq-0.00001) (nyq-0.019)];
else
    stopband = [0.2 (nyq-0.019)];
end

[B,A] = butter(10,stopband/nyq,'stop'); 

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

rp(:,1:3) = [];
rp = [rp fd_ang];

end
