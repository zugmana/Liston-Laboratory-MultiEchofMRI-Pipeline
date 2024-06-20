#Using matlab dockerfile as base. Available @https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/Dockerfile
#Use matlab base image as start. Picked a version that runs on ubuntu 20.04


# Specify MATLAB Install Location.
ARG MATLAB_INSTALL_LOCATION="/opt/matlab/r2023a"
# When you start the build stage, this Dockerfile by default uses the Ubuntu-based matlab-deps image.
# To check the available matlab-deps images, see: https://hub.docker.com/r/mathworks/matlab-deps
FROM mathworks/matlab-deps:r2023a


# Install mpm dependencies.
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install --no-install-recommends --yes \
    wget \
    unzip \
    ca-certificates \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /
# Run mpm to install MATLAB in the target location and delete the mpm installation afterwards.
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm \
    && chmod +x mpm \
    && ./mpm install \
    --release=r2023a \
    --destination=/opt/matlab/r2023a \
    --products="MATLAB" \
    || (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && false) \
    && ./mpm install \
    --release=r2023a \
    --destination=/opt/matlab/r2023a \
    --products="Signal_Processing_Toolbox" \
    && ./mpm install \
    --release=r2023a \
    --destination=/opt/matlab/r2023a \
    --products="Statistics_and_Machine_Learning_Toolbox" \
    && ./mpm install \
    --release=r2023a \
    --destination=/opt/matlab/r2023a \
    --products="Image_Processing_Toolbox" \
    && ./mpm install \
    --release=r2023a \
    --destination=/opt/matlab/r2023a \
    --products="Parallel_Computing_Toolbox" \
    && rm -f mpm /tmp/mathworks_root.log \
    && rm -f install_matlab.sh \
    && rm -fr /tmp/*

#below are largely based on neurodocker for each dependencies
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu:/opt/MCR-2017b/v93/runtime/glnxa64:/opt/MCR-2017b/v93/bin/glnxa64:/opt/MCR-2017b/v93/sys/os/glnxa64:/opt/MCR-2017b/v93/extern/bin/glnxa64" \
    MATLABCMD="/opt/MCR-2017b/2017b/toolbox/matlab" \
    XAPPLRESDIR="/opt//opt/MCR-2017b/v93/x11/app-defaults" \
    MCRROOT="/opt/MCR-2017b/2017b"
RUN export TMPDIR="$(mktemp -d)" \
    && apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           bc \
           curl \
           dbus-x11 \
           libncurses5 \
           libxext6 \
           libxmu6 \
           libxpm-dev \
           libxt6 \
           openjdk-8-jre \
           unzip \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Downloading MATLAB Compiler Runtime ...." \
    && curl  -o "$TMPDIR/mcr.zip" https://ssd.mathworks.com/supportfiles/downloads/R2017b/deployment_files/R2017b/installers/glnxa64/MCR_R2017b_glnxa64_installer.zip \
    && unzip -q "$TMPDIR/mcr.zip" -d "$TMPDIR/mcrtmp" \
    && "$TMPDIR/mcrtmp/install" -destinationFolder /opt/MCR-2017b -mode silent -agreeToLicense yes \
    && rm -rf "$TMPDIR" \
    && unset TMPDIR
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
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           bc \
           ca-certificates \
           curl \
           libgomp1 \
           libxmu6 \
           libxt6 \
           perl \
           tcsh \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Downloading FreeSurfer ..." \
    && mkdir -p /opt/freesurfer-6.0.1 \
    && curl -fL ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.1/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz \
    | tar -xz -C /opt/freesurfer-6.0.1 --owner root --group root --no-same-owner --strip-components 1 \
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
         --exclude='trctrain'
ENV FSLDIR="/opt/fsl" \
    PATH="/opt/fsl/bin:$PATH" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLTCLSH="/opt/fsl/bin/fsltclsh" \
    FSLWISH="/opt/fsl/bin/fslwish" \
    FSLLOCKDIR="" \
    FSLMACHINELIST="" \
    FSLREMOTECALL="" \
    FSLGECUDAQ="cuda.q"
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           dc \
           file \
           libfontconfig1 \
           libfreetype6 \
           libgl1-mesa-dev \
           libgl1-mesa-dri \
           libglu1-mesa-dev \
           libgomp1 \
           libice6 \
           libopenblas-base \
           libxcursor1 \
           libxft2 \
           libxinerama1 \
           libxrandr2 \
           libxrender1 \
           libxt6 \
           nano \
           python3 \
           r-base \
           r-base-dev \
           rsync \
           git  \
           sudo \
           wget \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Installing FSL ..." \
    && curl -fsSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py | python3 - -d /opt/fsl --skip_ssl_verify
ENV ANTSPATH="/opt/ants-2.4.3/" \
    PATH="/opt/ants-2.4.3:$PATH"
RUN echo "Downloading ANTs ..." \
    && curl -fsSL -o ants.zip https://github.com/ANTsX/ANTs/releases/download/v2.4.3/ants-2.4.3-centos7-X64-gcc.zip \
    && unzip ants.zip -d /opt \
    && mv /opt/ants-2.4.3/bin/* /opt/ants-2.4.3 \
    && rm ants.zip
RUN echo "Downloading fix ..." \
    && git -c http.sslVerify=false clone https://git.fmrib.ox.ac.uk/fsl/fix.git /opt/fix \    
    && echo "Downloading Connectome WB..." \
    && wget -q https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v1.5.0.zip \
    && unzip workbench-linux64-v1.5.0.zip \
    && mv workbench /opt/workbench \
    && rm -f workbench-linux64-v1.5.0.zip \
   && echo "Downloading HCPpipelines..." \
    && wget -q https://github.com/Washington-University/HCPpipelines/archive/refs/tags/v4.7.0.zip \
    && unzip v4.7.0.zip \
    && mv HCPpipelines-4.7.0 /opt/HCPpipelines-4.7.0 \
    && rm v4.7.0.zip
COPY install_packages.R /tmp/
RUN Rscript /tmp/install_packages.R
# Get the pipeline
RUN echo "Downloading pipeline" \
    && echo "" \
    && echo "" \
    && echo "" \
    && git clone https://github.com/zugmana/Liston-Laboratory-MultiEchofMRI-Pipeline.git /opt/Liston-Laboratory-MultiEchofMRI-Pipeline \
    && cd /opt/Liston-Laboratory-MultiEchofMRI-Pipeline \
    && git checkout edb_template \
    && cd /opt/Liston-Laboratory-MultiEchofMRI-Pipeline/MultiEchofMRI-Pipeline \
    && chmod +x anat_highres_HCP_wrapper_par.sh func_denoise_ME_wrapper.sh func_denoise_manacc_meica.sh func_denoise_meica.sh func_denoise_mgtr.sh func_manacc_ME-fMRI_wrapper.sh func_preproc+denoise_ME-fMRI_wrapper.sh func_preproc_ME_wrapper.sh func_preproc_coreg.sh func_preproc_fm.sh func_preproc_headmotion.sh func_smooth.sh func_smooth_subcort_concat.sh func_vol2surf.sh \
    && cd - \
    && chmod +x /opt/Liston-Laboratory-MultiEchofMRI-Pipeline/Res0urces/coreg_rho.py
RUN git clone https://github.com/fangq/jsonlab.git /opt/Liston-Laboratory-MultiEchofMRI-Pipeline/Res0urces/jsonlab
RUN git clone https://github.com/MidnightScanClub/MSCcodebase.git /opt/Liston-Laboratory-MultiEchofMRI-Pipeline/Res0urces/PFM/MSCcodebase
RUN wget -P /opt/MSM/ https://github.com/ecr05/MSM_HOCR/releases/download/v3.0FSL/msm_ubuntu_v3 \
    && cd /opt/MSM/ \
    && mv msm_ubuntu_v3 msm \
    && chmod +rwx msm
#Forgot Tedana
ENV CONDA_DIR="/opt/miniconda-latest" \
    PATH="/opt/miniconda-latest/bin:$PATH"
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           bzip2 \
           parallel \
    && rm -rf /var/lib/apt/lists/* \
    # Install dependencies.
    && export PATH="/opt/miniconda-latest/bin:$PATH" \
    && echo "Downloading Miniconda installer ..." \
    && conda_installer="/tmp/miniconda.sh" \
    && curl -fsSL -o "$conda_installer" https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash "$conda_installer" -b -p /opt/miniconda-latest \
    && rm -f "$conda_installer" \
    && conda update -yq -nbase conda \
    # Prefer packages in conda-forge
    && conda config --system --prepend channels conda-forge \
    # Packages in lower-priority channels not considered if a package with the same
    # name exists in a higher priority channel. Can dramatically speed up installations.
    # Conda recommends this as a default
    # https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-channels.html
    && conda config --set channel_priority strict \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    # Enable `conda activate`
    && conda init bash \
    && conda create -y  --name me_v10 \
    && conda install -y  --name me_v10 \
           "nilearn" \
           "nibabel" \
           "numpy" \
           "scikit-learn" \
           "scipy" \
           "numpy" \
    && bash -c "source activate me_v10 \
    &&   python -m pip install --no-cache-dir  \
            "mapca" \
            "tedana"" \            
    # Clean up
    && sync && conda clean --all --yes && sync \
    && rm -rf ~/.cache/pip/*

# Update the PATH for Bash
ENV PATH=$PATH:/opt/workbench:/opt/workbench/bin_linux64:/opt/Liston-Laboratory-MultiEchofMRI-Pipeline/MultiEchofMRI-Pipeline/:/opt/matlab/r2023a/bin:/opt/ants-2.4.3
#Set ENV for HCPpipelines
ENV MSMBINDIR="/opt/MSM/" \
    HCPPIPEDIR="/opt/HCPpipelines-4.7.0/" \
    MATLAB_COMPILER_RUNTIME="/opt/mcr/v93/" \
    CARET7DIR="/opt/workbench/bin_linux64/" \
    HCPCIFTIRWDIR="/opt/HCPpipelines-4.7.0/global/matlab/cifti-matlab" \
    MSMCONFIGDIR="/opt/HCPpipelines-4.7.0/MSMConfig" \
    FSL_FIXDIR="/opt/fix"
# Set the runscript
ENTRYPOINT ["/opt/Liston-Laboratory-MultiEchofMRI-Pipeline/MultiEchofMRI-Pipeline/entrypoint.sh"]
