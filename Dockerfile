#Use the base image
FROM ubuntu:jammy-20230308 as download
# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
COPY install_packages.R /tmp/
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
     ca-certificates \
     curl \
     git  \
     r-base \
     r-base-dev \
     make \
     net-tools \
     sudo \
     unzip \
     python3 \
     wget\
    && rm -rf /var/lib/apt/lists/* \
    && echo "Installing FSL ..." \
    && curl -fsSLk https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py | python3 - -d /opt/fsl-6.0.6.4 -V 6.0.6.4 --skip_ssl_verify \
    && wget -q http://www.fmrib.ox.ac.uk/~steve/ftp/fix.tar.gz \
    && tar -xf fix.tar.gz -C /opt/ \
    && rm fix.tar.gz \
    && wget -q https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v1.5.0.zip \
    && unzip workbench-linux64-v1.5.0.zip \
    && mv workbench /opt/workbench \
    && rm -f workbench-linux64-v1.5.0.zip \
    && echo "Downloading FreeSurfer ..." \
    && mkdir -p /opt/freesurfer-6.0.1 \
    && wget -q https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.1/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz \
    && tar -xf freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz-C /opt/freesurfer-6.0.1 --owner root --group root --no-same-owner --strip-components 1 \
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
    && wget -P /opt/MSM/ https://github.com/ecr05/MSM_HOCR/releases/download/v3.0FSL/msm_centos_v3 \
    && wget -q https://github.com/Washington-University/HCPpipelines/archive/refs/tags/v4.7.0.zip \
    && unzip v4.7.0.zip \
    && mv HCPpipelines-4.7.0 /opt/HCPpipelines-4.7.0 \
    && rm v4.7.0.zip \
    && wget -q https://www.mathworks.com/mpm/glnxa64/mpm \
    && chmod +x mpm \
    && echo "#!/bin/bash" > install_matlab.sh \
    && echo "./mpm install \\" >> install_matlab.sh \
    && echo "--release=r2023a \\" >> install_matlab.sh \
    && echo "--destination=\"/opt/matlab/r2023a/\" \\" >> install_matlab.sh \
    && echo "--products \"MATLAB\" \\" >> install_matlab.sh \
    && echo "|| (echo 'MPM Installation Failure. See below for more information:' && cat /tmp/mathworks_root.log && false)" >> install_matlab.sh \
    && chmod +x install_matlab.sh \
    && ./install_matlab.sh \
    && rm -f mpm /tmp/mathworks_root.log \
    && rm -f install_matlab.sh \
    && ln -s /opt/matlab/r2023a/bin/matlab /usr/local/bin/matlab \
    && Rscript /tmp/install_packages.R 
# Get the pipeline
RUN git clone https://github.com/zugmana/Liston-Laboratory-MultiEchofMRI-Pipeline.git /opt/Liston-Laboratory-MultiEchofMRI-Pipeline \
    && cd /opt/Liston-Laboratory-MultiEchofMRI-Pipeline \
    && git checkout edb_template \
    && cd /opt/Liston-Laboratory-MultiEchofMRI-Pipeline/MultiEchofMRI-Pipeline \
    && chmod +x anat_highres_HCP_wrapper_par.sh func_denoise_ME_wrapper.sh func_denoise_manacc_meica.sh func_denoise_meica.sh func_denoise_mgtr.sh func_manacc_ME-fMRI_wrapper.sh func_preproc+denoise_ME-fMRI_wrapper.sh func_preproc_ME_wrapper.sh func_preproc_coreg.sh func_preproc_fm.sh func_preproc_headmotion.sh func_smooth.sh func_smooth_subcort_concat.sh func_vol2surf.sh \
    && cd -


#Set up final layer
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
    FSLGECUDAQ="cuda.q"

COPY --from=download /opt/HCPpipelines-4.7.0 /opt/HCPpipelines-4.7.0
COPY --from=download /opt/Liston-Laboratory-MultiEchofMRI-Pipeline /opt/Liston-Laboratory-MultiEchofMRI-Pipeline
COPY --from=download /opt/fsl-6.0.6.4 /opt/fsl-6.0.6.4
COPY --from=download /opt/MSM /opt/MSM
COPY --from=download /opt/fix /opt/fix
COPY --from=download /opt/freesurfer-6.0.1 /opt/freesurfer-6.0.1
COPY --from=download /opt/matlab /opt/matlab
COPY --from=download /opt/workbench /opt/workbench
COPY --from=download /usr/local/lib/R/site-library /usr/local/lib/R/site-library
# Update the PATH for Bash
#ENV PATH=$PATH:/opt/workbench:/opt/workbench/bin_linux64:/opt/Liston-Laboratory-MultiEchofMRI-Pipeline/MultiEchofMRI-Pipeline/

# Set the runscript
#CMD ["/opt/Liston-Laboratory-MultiEchofMRI-Pipeline/MultiEchofMRI-Pipeline/entrypoint.sh"]

# Labels and help
LABEL Version="v0.0"
