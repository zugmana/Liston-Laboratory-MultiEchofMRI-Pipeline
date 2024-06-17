#!/bin/bash
# CJL; (cjl2007@med.cornell.edu)

export StudyFolder=$1 # location of Subject folder
export Subject=$2 # space delimited list of subject IDs
export NTHREADS=$3 # set number of threads; larger values will reduce runtime (but also increase RAM usage);
echo "Starting functional pipeline for ${Subject}, in ${OrigStudyFolder}"
# define the 
# starting point 
if [ -z "$4" ]
	then
	    StartSession=1
	else
	    StartSession=$4
fi

# reformat subject folder path;
if [ "${StudyFolder: -1}" = "/" ]; then
	StudyFolder=${StudyFolder%?};
fi

# setup mcr
# setup mcr
ver=v93
mcr="/opt/mcr/v93"


# define subject directory;
export Subdir="$StudyFolder"/"$Subject"

# define some directories containing 
# custom matlab scripts and various atlas files;
export MEDIR="/opt/Liston-Laboratory-MultiEchofMRI-Pipeline/MultiEchofMRI-Pipeline"

# check to see if there's a symlink to res0urces here
if ! [[ -e ${MEDIR}/res0urces ]]; then
    ln -s ${MEDIR}/../Res0urces ${MEDIR}/res0urces
fi

# these variables should not be changed unless you have a very good reason
DOF=6 # this is the degrees of freedom (DOF) used for SBref --> T1w and EPI --> SBref coregistrations;
CiftiList="$MEDIR"/config/CiftiList.txt # .txt file containing list of files to be mapped to surface. user can specify OCME, OCME+MEICA, OCME+MEICA+MGTR, and/or OCME+MEICA+MGTR_Betas
AtlasTemplate="$MEDIR/res0urces/FSL/MNI152_T1_2mm.nii.gz" # define a lowres MNI template; 
AtlasSpace="T1w" # define either native space ("T1w") or MNI space ("MNINonlinear")
MEPCA=kundu # set the pca decomposition method (see "tedana -h" for more information)
MaxIterations=500 
MaxRestarts=5

# set variable value that sets up environment
EnvironmentScript="/opt/HCPpipelines-4.7.0/Examples/Scripts/SetUpHCPPipeline.sh" # Pipeline environment script; users need to set this 
#source ${EnvironmentScript}	# Set up pipeline environment variables and software
source "$HCPPIPEDIR/global/scripts/finish_hcpsetup.shlib"
echo -e "\nMulti-Echo Preprocessing & Denoising Pipeline" 

echo -e "\nProcessing the Field Maps"

# process all field maps & create an average image 
# for cases where scan-specific maps are unavailable;
echo "$MEDIR"/func_preproc_fm.sh "$MEDIR" "$Subject" \
"$StudyFolder" "$NTHREADS" "$StartSession"

"$MEDIR"/func_preproc_fm.sh "$MEDIR" "$Subject" \
"$StudyFolder" "$NTHREADS" "$StartSession"

echo -e "Coregistering SBrefs to the Anatomical Image"
echo "$MEDIR"/func_preproc_coreg.sh "$MEDIR" "$Subject" "$StudyFolder" \
"$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession"
# create an avg. sbref image and co-register that 
# image & all individual SBrefs to the T1w image;AtlasSpace
"$MEDIR"/func_preproc_coreg.sh "$MEDIR" "$Subject" "$StudyFolder" \
"$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession"

echo -e "Correcting for Slice Time Differences, Head Motion, & Spatial Distortion"

# correct func images for slice time differences and head motion;
echo "$MEDIR"/func_preproc_headmotion.sh "$MEDIR" "$Subject" "$StudyFolder" \
"$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession"

"$MEDIR"/func_preproc_headmotion.sh "$MEDIR" "$Subject" "$StudyFolder" \
"$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession"

echo -e "Performing Signal-Decay Based Denoising"

# perform signal-decay denoising; 
echo "$MEDIR"/func_denoise_meica.sh "$Subject" "$StudyFolder" "$NTHREADS" \
"$MEPCA" "$MaxIterations" "$MaxRestarts" "$StartSession"

"$MEDIR"/func_denoise_meica.sh "$Subject" "$StudyFolder" "$NTHREADS" \
"$MEPCA" "$MaxIterations" "$MaxRestarts" "$StartSession"

echo -e "Removing Spatially Diffuse Noise via MGTR"

# remove spatially diffuse noise; 
echo "$MEDIR"/func_denoise_mgtr.sh "$Subject" \
"$StudyFolder" "$MEDIR" "$StartSession"

"$MEDIR"/func_denoise_mgtr.sh "$Subject" \
"$StudyFolder" "$MEDIR" "$StartSession"

echo -e "Mapping Denoised Functional Data to Surface"

# volume-to-surface + spatial smoothing mapping;
echo "$MEDIR"/func_vol2surf.sh "$Subject" "$StudyFolder" \
"$MEDIR" "$CiftiList" "$StartSession"

"$MEDIR"/func_vol2surf.sh "$Subject" "$StudyFolder" \
"$MEDIR" "$CiftiList" "$StartSession"

