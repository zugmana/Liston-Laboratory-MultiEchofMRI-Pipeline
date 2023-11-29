#!/usr/bin/bash
# CJL; (cjl2007@med.cornell.edu)
# note: this script is a wrapper for the HCP's anatomical preprocessing pipeline; 

OrigStudyFolder=$1 # location of Subject folder
Subject=$2 # space delimited list of subject IDs
export NSLOTS=$3 # set number of cores for FreeSurfer

echo "Starting anatomical pipeline for ${Subject}, in ${OrigStudyFolder}"
# reformat subject folder path  
if [ "${StudyFolder: -1}" = "/" ]; then
	StudyFolder=${StudyFolder%?};
fi

# make study folder in workdir with symlinks to unprocessed data
[[ -d "/work/" ]] || exit 101
StudyFolder="/work/studyfolder"
mkdir -p ${StudyFolder}/${Subject}/anat
mkdir -p ${StudyFolder}/${Subject}/func
cp -rv ${OrigStudyFolder}/${Subject}/field_maps ${StudyFolder}/${Subject}/field_maps
cp -rv ${OrigStudyFolder}/${Subject}/anat/unprocessed ${StudyFolder}/${Subject}/anat/unprocessed
cp -rv ${OrigStudyFolder}/${Subject}/func/unprocessed ${StudyFolder}/${Subject}/func/unprocessed

# setup mcr
ver=v93
mcr="/opt/mcr/v93"


# Set variable value that sets up environment
#SetUpHCPPipeline.sh does not work on the container. The variables are now set up in the build
#EnvironmentScript="/opt/HCPpipelines-4.7.0/Examples/Scripts/SetUpHCPPipeline.sh" # Pipeline environment script; users need to set this 
#source ${EnvironmentScript}	# Set up pipeline environment variables and software
source "$HCPPIPEDIR/global/scripts/finish_hcpsetup.shlib"
PRINTCOM="" # If PRINTCOM is not a null or empty string variable, then this script and other scripts that it calls will simply print out the primary commands it otherwise would run. This printing will be done using the command specified in the PRINTCOM variable

AvgrdcSTRING="NONE" # Readout Distortion Correction;
MagnitudeInputName="NONE" # The MagnitudeInputName variable should be set to a 4D magitude volume with two 3D timepoints or "NONE" if not used
PhaseInputName="NONE" # The PhaseInputName variable should be set to a 3D phase difference volume or "NONE" if not used
TE="NONE" # The TE variable should be set to 2.46ms for 3T scanner, 1.02ms for 7T scanner or "NONE" if not using

# Variables related to using Spin Echo Field Maps
SpinEchoPhaseEncodeNegative="NONE"
SpinEchoPhaseEncodePositive="NONE"
SEEchoSpacing="NONE"
SEUnwarpDir="NONE"
TopupConfig="NONE"
GEB0InputName="NONE"

# define some templates;
T1wTemplate="${HCPPIPEDIR_Templates}/MNI152_T1_0.8mm.nii.gz" # Hires T1w MNI template
T1wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T1_0.8mm_brain.nii.gz" # Hires brain extracted MNI template
T1wTemplate2mm="${HCPPIPEDIR_Templates}/MNI152_T1_2mm.nii.gz" # Lowres T1w MNI template
T2wTemplate="${HCPPIPEDIR_Templates}/MNI152_T2_0.8mm.nii.gz" # Hires T2w MNI Template
T2wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T2_0.8mm_brain.nii.gz" # Hires T2w brain extracted MNI Template
T2wTemplate2mm="${HCPPIPEDIR_Templates}/MNI152_T2_2mm.nii.gz" # Lowres T2w MNI Template
TemplateMask="${HCPPIPEDIR_Templates}/MNI152_T1_0.8mm_brain_mask.nii.gz" # Hires MNI brain mask template
Template2mmMask="${HCPPIPEDIR_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz" # Lowres MNI brain mask template

# Structural Scan Settings
# The values set below are for the HCP-YA Protocol using the Siemens Connectom Scanner
T1wSampleSpacing="NONE" # DICOM field (0019,1018) in s or "NONE" if not used
T2wSampleSpacing="NONE" # DICOM field (0019,1018) in s or "NONE" if not used
UnwarpDir="z" # z appears to be the appropriate polarity for the 3D structurals collected on Siemens scanners
BrainSize="170" # BrainSize in mm, 150-170 for humans
FNIRTConfig="${HCPPIPEDIR_Config}/T1_2_MNI152_2mm.cnf" # FNIRT 2mm T1w Config
GradientDistortionCoeffs="NONE" # Set to NONE to skip gradient distortion correction

echo -e "\nAnatomical Preprocessing and Surface Registration Pipeline" 

# clean slate;
rm -rf ${StudyFolder}/${Subject}/T*w/ > /dev/null 2>&1 
rm -rf ${StudyFolder}/${Subject}/MNINonLinear > /dev/null 2>&1 

# build list of full paths to T1w images; 
T1ws=`ls ${StudyFolder}/${Subject}/anat/unprocessed/T1w/T1w*.nii.gz`
echo $T1ws
T1wInputImages="" # preallocate 

# find all 
# T1w images;
for i in $T1ws ; do
	T1wInputImages=`echo "${T1wInputImages}$i@"`
done

# build list of full paths to T1w images;
T2ws=`ls ${StudyFolder}/${Subject}/anat/unprocessed/T2w/T2w*.nii.gz` > /dev/null 2>&1  
T2wInputImages="" # preallocate 

# find all 
# T2w images;
for i in $T2ws ; do
	T2wInputImages=`echo "${T2wInputImages}$i@"`
done

# determine if T2w images exist &
# adjust "processing mode" accordingly
if [ "$T2wInputImages" = "" ]; then
	T2wInputImages="NONE" # script will proceed in "legacy" mode
	ProcessingMode="LegacyStyleData"
else
	ProcessingMode="HCPStyleData"
fi

# make "QA" folder;
mkdir ${StudyFolder}/${Subject}/qa/ > /dev/null 2>&1 

# 

echo -e "\nRunning PreFreeSurferPipeline" 

# # run the Pre FreeSurfer pipeline;
${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh \
--path="$StudyFolder" \
--subject="$Subject" \
--t1="$T1wInputImages" \
--t2="$T2wInputImages" \
--t1template="$T1wTemplate" \
--t1templatebrain="$T1wTemplateBrain" \
--t1template2mm="$T1wTemplate2mm" \
--t2template="$T2wTemplate" \
--t2templatebrain="$T2wTemplateBrain" \
--t2template2mm="$T2wTemplate2mm" \
--templatemask="$TemplateMask" \
--template2mmmask="$Template2mmMask" \
--brainsize="$BrainSize" \
--fnirtconfig="$FNIRTConfig" \
--fmapmag="$MagnitudeInputName" \
--fmapphase="$PhaseInputName" \
--fmapgeneralelectric="$GEB0InputName" \
--echodiff="$TE" \
--SEPhaseNeg="$SpinEchoPhaseEncodeNegative" \
--SEPhasePos="$SpinEchoPhaseEncodePositive" \
--seechospacing="$SEEchoSpacing" \
--seunwarpdir="$SEUnwarpDir" \
--t1samplespacing="$T1wSampleSpacing" \
--t2samplespacing="$T2wSampleSpacing" \
--unwarpdir="$UnwarpDir" \
--gdcoeffs="$GradientDistortionCoeffs" \
--avgrdcmethod="$AvgrdcSTRING" \
--topupconfig="$TopupConfig" \
--processing-mode="$ProcessingMode" \
--printcom=$PRINTCOM > ${StudyFolder}/${Subject}/qa/PreFreeSurfer.txt

# define some input variables for FreeSurfer;
SubjectID="$Subject" #FreeSurfer Subject ID Name
SubjectDIR="${StudyFolder}/${Subject}/T1w" #Location to Put FreeSurfer Subject's Folder
T1wImage="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore.nii.gz" #T1w FreeSurfer Input (Full Resolution)
T1wImageBrain="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore_brain.nii.gz" #T1w FreeSurfer Input (Full Resolution)

# determine if T2w images exist & 
# adjust "T2wImage" input accordingly
if [ "$T2wInputImages" = "NONE" ]; then
	T2wImage="NONE" # no T2w image
else
	T2wImage="${StudyFolder}/${Subject}/T1w/T2w_acpc_dc_restore.nii.gz" #T2w FreeSurfer Input (Full Resolution)
fi

echo -e "Running FreeSurferPipeline" 

echo ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh

export PATH=${HCPPIPEDIR}/FreeSurfer/custom:$PATH

# run the FreeSurfer pipeline;
${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
--subject="$Subject" \
--subjectDIR="$SubjectDIR" \
--t1="$T1wImage" \
--t1brain="$T1wImageBrain" \
--t2="$T2wImage" \
--processing-mode="$ProcessingMode" > ${StudyFolder}/${Subject}/qa/FreeSurfer.txt

# define some input variables for "Post" FreeSurfer;
SurfaceAtlasDIR="${HCPPIPEDIR_Templates}/standard_mesh_atlases"
GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/91282_Greyordinates"
GrayordinatesResolutions="2" #Usually 2mm, if multiple delimit with @, must already exist in templates dir
HighResMesh="164" #Usually 164k vertices
LowResMeshes="32" #Usually 32k vertices, if multiple delimit with @, must already exist in templates dir
SubcorticalGrayLabels="${HCPPIPEDIR_Config}/FreeSurferSubcorticalLabelTableLut.txt"
FreeSurferLabels="${HCPPIPEDIR_Config}/FreeSurferAllLut.txt"
ReferenceMyelinMaps="${HCPPIPEDIR_Templates}/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii"
RegName="MSMSulc" #MSMSulc is recommended, if binary is not available use FS (FreeSurfer)

echo -e "Running PostFreeSurferPipeline" 

# run the Post FreeSurfer pipeline;
${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline.sh \
--path="$StudyFolder" \
--subject="$Subject" \
--surfatlasdir="$SurfaceAtlasDIR" \
--grayordinatesdir="$GrayordinatesSpaceDIR" \
--grayordinatesres="$GrayordinatesResolutions" \
--hiresmesh="$HighResMesh" \
--lowresmesh="$LowResMeshes" \
--subcortgraylabels="$SubcorticalGrayLabels" \
--freesurferlabels="$FreeSurferLabels" \
--refmyelinmaps="$ReferenceMyelinMaps" \
--regname="$RegName" \
--processing-mode="$ProcessingMode" > ${StudyFolder}/${Subject}/qa/PostFreeSurfer.txt

# move output folders into "anat";
mv ${StudyFolder}/${Subject}/T*w/ ${StudyFolder}/${Subject}/anat/ # T1w & T2w folders
mv ${StudyFolder}/${Subject}/MNINonLinear/ ${StudyFolder}/${Subject}/anat/ # MNINonLinear folder
mv ${StudyFolder}/${Subject}/qa/ ${StudyFolder}/${Subject}/anat/

# rsync back to origstudyfolder
rsync -ach --no-links ${StudyFolder}/${Subject}/anat/ ${OrigStudyFolder}/${Subject}/anat/
#chown -R :EDB ${OrigStudyFolder}/${Subject}/anat/
