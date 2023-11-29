FROM ubuntu:jammy-20230308 as download
# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
     ca-certificates \
     curl \
     git  \
     make \
     net-tools \
     sudo \
     unzip \
     python3 \
     wget\
     r-base \
     r-base-dev \
    && rm -rf /var/lib/apt/lists/* \
RUN echo "Downloading Matlab..." \
    && wget -q https://www.mathworks.com/mpm/glnxa64/mpm \
    && chmod +x mpm \
    && ./mpm install \
    --release=r2023a \
    --destination=/opt/matlab/2023a \
    --products="MATLAB" \
    || (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && false) \
    && ./mpm install \
    --release=r2023a \
    --destination=/opt/matlab/2023a \
    --products="Signal_Processing_Toolbox" \
    && rm -f mpm /tmp/mathworks_root.log \
    && ln -s /opt/matlab/2023a /usr/local/bin/matlab \
    && rm -f install_matlab.sh \
    && rm -fr /tmp/*
RUN echo "install Matlab compiler" \
    && wget https://ssd.mathworks.com/supportfiles/downloads/R2017b/deployment_files/R2017b/installers/glnxa64/MCR_R2017b_glnxa64_installer.zip \
    && unzip MCR_R2017b_glnxa64_installer.zip -d /tmp/mcrv93 \
    && /tmp/mcrv93/install -agreeToLicense yes -destinationFolder /opt/mcr/v93 -mode silent \
    && rm -fr /tmp/* \
    && rm MCR_R2017b_glnxa64_installer.zip
RUN echo "Downloading fix ..." \
    && git clone https://git.fmrib.ox.ac.uk/fsl/fix.git /opt/fix \    
    && echo "Downloading Connectome WB..." \
    && wget -q https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v1.5.0.zip \
    && unzip workbench-linux64-v1.5.0.zip \
    && mv workbench /opt/workbench \
    && rm -f workbench-linux64-v1.5.0.zip \
    && echo "Downloading FreeSurfer ..." \
    && mkdir -p /opt/freesurfer-6.0.1 \
    && wget -q https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.1/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz \
    && tar -xf freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz -C /opt/freesurfer-6.0.1 --owner root --group root --no-same-owner --strip-components 1 \
         --exclude='average/mult-comp-cor' \
         --exclude='lib/cuda' \
         --exclude='lib/qt' \
         --exclude='subjects/V1_average' \
         --exclude='subjects/bert' \
         --exclude='subjects/cvs_avg35' \
         --exclude='subjects/cvs_avg35_inMNI152' \
         --exclude='subjects/fsaverage3' \
         --exclude='subjects/fsaverage4' \
         --exclude='subjects/fsaverage5' \
         --exclude='subjects/fsaverage6' \
         --exclude='subjects/fsaverage_sym' \
         --exclude='trctrain' \
    && echo "Downloading MSM..." \
    && wget -P /opt/MSM/ https://github.com/ecr05/MSM_HOCR/releases/download/v3.0FSL/msm_centos_v3 \
    && echo "Downloading HCPpipelines..." \
    && wget -q https://github.com/Washington-University/HCPpipelines/archive/refs/tags/v4.7.0.zip \
    && unzip v4.7.0.zip \
    && mv HCPpipelines-4.7.0 /opt/HCPpipelines-4.7.0 \
    && rm v4.7.0.zip
COPY install_packages.R /tmp/
RUN Rscript /tmp/install_packages.R
RUN echo "Installing FSL ..." \
    && curl -fsSLk https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py | python3 - -d /opt/fsl-6.0.6.4 -V 6.0.6.4 --skip_ssl_verify
# Get the pipeline
RUN git clone https://github.com/zugmana/Liston-Laboratory-MultiEchofMRI-Pipeline.git /opt/Liston-Laboratory-MultiEchofMRI-Pipeline \
    && cd /opt/Liston-Laboratory-MultiEchofMRI-Pipeline \
    && git checkout edb_template \
    && cd /opt/Liston-Laboratory-MultiEchofMRI-Pipeline/MultiEchofMRI-Pipeline \
    && chmod +x anat_highres_HCP_wrapper_par.sh func_denoise_ME_wrapper.sh func_denoise_manacc_meica.sh func_denoise_meica.sh func_denoise_mgtr.sh func_manacc_ME-fMRI_wrapper.sh func_preproc+denoise_ME-fMRI_wrapper.sh func_preproc_ME_wrapper.sh func_preproc_coreg.sh func_preproc_fm.sh func_preproc_headmotion.sh func_smooth.sh func_smooth_subcort_concat.sh func_vol2surf.sh \
    && cd - 
RUN git clone https://github.com/fangq/jsonlab.git /opt/Liston-Laboratory-MultiEchofMRI-Pipeline/Res0urces/jsonlab
RUN wget -P /opt/MSM/ https://github.com/ecr05/MSM_HOCR/releases/download/v3.0FSL/msm_ubuntu_v3 \
    && cd /opt/MSM/ \
    && chmod +rwx msm_ubuntu_v3 \
    && wget -P /opt/MSM/ https://github.com/ecr05/MSM_HOCR/releases/download/v3.0FSL/MSM_HOCR_v3.zip \
    && unzip MSM_HOCR_v3.zip \
    && rm MSM_HOCR_v3.zip
#FINAL
FROM ubuntu:jammy-20230308
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"
#Set ENV for freesurfer
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
        bc \
        libasound2 \
        libc6 \
        libcairo-gobject2 \
        libcairo2 \
        libcap2 \
        libcups2 \
        libdrm2 \
        libgbm1 \
        libgdk-pixbuf-2.0-0 \
        libgl1 \
        libglib2.0-0 \
        libgstreamer-plugins-base1.0-0 \
        libgstreamer1.0-0 \
        libgtk-3-0 \
        libice6 \
        libltdl7 \
        libnspr4 \
        libnss3 \
        libpam0g \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libpangoft2-1.0-0 \
        libsndfile1 \
        libuuid1 \
        libwayland-client0 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxfixes3 \
        libxft2 \
        libxinerama1 \
        libxrandr2 \
        libxt6 \
        libxtst6 \
        libxxf86vm1 \
        locales \
        locales-all \
        procps \
        zlib1g \
        tcsh \
        perl \
        libxmu6 \
        dc \
        file \
        libfontconfig1 \
        libfreetype6 \
        libgl1-mesa-dev \
        libgl1-mesa-dri \
        libglu1-mesa-dev \
        libgomp1 \
        nano \
        python3 

ENV OS="Linux" \
    PATH="/opt/freesurfer-6.0.1/bin:/opt/freesurfer-6.0.1/fsfast/bin:/opt/freesurfer-6.0.1/tktools:/opt/freesurfer-6.0.1/mni/bin:$PATH" \
    FREESURFER_HOME="/opt/freesurfer-6.0.1" \
    FREESURFER="/opt/freesurfer-6.0.1" \
    SUBJECTS_DIR="/opt/freesurfer-6.0.1/subjects" \
    LOCAL_DIR="/opt/freesurfer-6.0.1/local" \
    FSFAST_HOME="/opt/freesurfer-6.0.1/fsfast" \
    FMRI_ANALYSIS_DIR="/opt/freesurfer-6.0.1/fsfast" \
    FUNCTIONALS_DIR="/opt/freesurfer-6.0.1/sessions" \
    FS_OVERRIDE="0" \
    FIX_VERTEX_AREA="" \
    FSF_OUTPUT_FORMAT="nii.gz# mni env requirements" \
    MINC_BIN_DIR="/opt/freesurfer-6.0.1/mni/bin" \
    MINC_LIB_DIR="/opt/freesurfer-6.0.1/mni/lib" \
    MNI_DIR="/opt/freesurfer-6.0.1/mni" \
    MNI_DATAPATH="/opt/freesurfer-6.0.1/mni/data" \
    MNI_PERL5LIB="/opt/freesurfer-6.0.1/mni/share/perl5" \
    PERL5LIB="/opt/freesurfer-6.0.1/mni/share/perl5"
#Set ENV for FSL
ENV FSLDIR="/opt/fsl-6.0.6.4" \
    PATH="/opt/fsl-6.0.6.4/bin:$PATH" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLTCLSH="/opt/fsl-6.0.6.4/bin/fsltclsh" \
    FSLWISH="/opt/fsl-6.0.6.4/bin/fslwish" \
    FSLLOCKDIR="" \
    FSLMACHINELIST="" \
    FSLREMOTECALL="" \
    FSL_FIX_R_CMD="/usr/bin/R" \
    FSLGECUDAQ="cuda.q"
#Set ENV for HCPpipelines
ENV MSMBINDIR="/opt/MSM" \
    HCPPIPEDIR="/opt/HCPpipelines-4.7.0/" \
    MATLAB_COMPILER_RUNTIME="/opt/mcr/v93/" \
    CARET7DIR="/opt/workbench/bin_linux64/wb_command" \
    HCPCIFTIRWDIR="/opt/HCPpipelines-4.7.0/global/matlab/cifti-matlab"
    


COPY --from=download /opt/HCPpipelines-4.7.0 /opt/HCPpipelines-4.7.0
COPY --from=download /opt/Liston-Laboratory-MultiEchofMRI-Pipeline /opt/Liston-Laboratory-MultiEchofMRI-Pipeline
COPY --from=download /opt/fsl-6.0.6.4 /opt/fsl-6.0.6.4
COPY --from=download /opt/MSM /opt/MSM
COPY --from=download /opt/fix /opt/fix
COPY --from=download /opt/freesurfer-6.0.1 /opt/freesurfer-6.0.1
COPY --from=download /opt/matlab /opt/matlab
COPY --from=download /opt/workbench /opt/workbench
COPY --from=download /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=download /opt/mcr/v93 /opt/mcr/v93
# Update the PATH for Bash
ENV PATH=$PATH:/opt/workbench:/opt/workbench/bin_linux64:/opt/Liston-Laboratory-MultiEchofMRI-Pipeline/MultiEchofMRI-Pipeline/

# Set the runscript
CMD ["/opt/Liston-Laboratory-MultiEchofMRI-Pipeline/MultiEchofMRI-Pipeline/entrypoint.sh"]

# Labels and help
LABEL Version="v0.0"
