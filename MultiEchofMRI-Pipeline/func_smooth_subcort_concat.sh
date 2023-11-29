#!/bin/bash

MEDIR=$1
Subject=$2
StudyFolder=$3
Subdir="$StudyFolder"/"$Subject"


# fresh workspace dir.
rm -rf "$Subdir"/workspace/ > /dev/null 2>&1
mkdir "$Subdir"/workspace/ > /dev/null 2>&1

# create temp. find_epi_params.m 
cp -rf "$MEDIR"/res0urces/smooth_subcort_concat.m \
"$Subdir"/workspace/temp.m

# define some Matlab variables;
echo "addpath(genpath('/opt/Liston-Laboratory-MultiEchofMRI-Pipeline/Res0urces/jsonlab')); addpath(genpath('${MEDIR}'))" | cat - "$Subdir"/workspace/temp.m > temp && mv temp "$Subdir"/workspace/temp.m
echo Subdir=["'$Subdir'"] | cat - "$Subdir"/workspace/temp.m >> temp && mv temp "$Subdir"/workspace/temp.m # > /dev/null 2>&1 		
cd "$Subdir"/workspace/ # run script via Matlab 
matlab -nodesktop -nosplash -r "temp; exit" # > /dev/null 2>&1

# delete some files;
rm -rf "$Subdir"/workspace/
cd "$Subdir" # go back to subject dir. 