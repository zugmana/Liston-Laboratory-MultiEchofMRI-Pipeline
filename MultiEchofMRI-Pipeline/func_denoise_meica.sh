#!/bin/bash
# CJL; (cjl2007@med.cornell.edu)

Subject=$1
StudyFolder=$2
Subdir="$StudyFolder"/"$Subject"
NTHREADS=$3
MEPCA=$4
MaxIterations=$5
MaxRestarts=$6
StartSession=$7

#testing to see if this will make parallel work consistentl
export SHELL=$(type -p bash)

# count the number of sessions
sessions=("$Subdir"/func/rest/session_*)
sessions=$(seq $StartSession 1 "${#sessions[@]}")

# sweep the sessions;
for s in $sessions ; do

	# count number of runs for this session;
	runs=("$Subdir"/func/rest/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}")

	# sweep the runs;
	for r in $runs; do

		# "DataDirs.txt" contains 
		# dir. paths to every scan. 
		echo session_"$s"/run_"$r" \
		>> "$Subdir"/DataDirs.txt  

	done

done

# hardcode tedana path 
# TODO: fix this
#export PATH=/data/MLDSST/nielsond/target_test/other_repos/for_tedana/bin:$PATH


# define a list of directories;
DataDirs=$(cat "$Subdir"/DataDirs.txt) # note: this is used for parallel processing purposes.
#rm "$Subdir"/DataDirs.txt # remove intermediate file;
source activate me_v10
# Note: that in the make_adaptive_mask function in utils.py, following change is made... 
# masksum = (np.abs(echo_means) > lthrs).sum(axis=-1) <-- this is the original code in Tedana; uses an arbitrary 33rd percentile cutoff. 
# masksum = (np.abs(echo_means) > 0).sum(axis=-1) <--- this is effectively forces tedana to consider all in-brain voxels (with a R2 >= 0.8; see func_denoise_t2star.sh and fit_t2s.m) as "good".

func () {

	# remove any existing Tedana dirs.;
	if [ ! -d "${1}/func/rest/${6}/Tedana" ]; then echo "No previous Tedana found in ${6}." ; else echo "Removing previous Tedana run" ; rm -rf "${1}/func/rest/${6}/Tedana" ; fi
	

	# make sure that the explicit brain mask and T2* map match; 
	fslmaths "$1"/func/rest/"$6"/Rest_E1_acpc.nii.gz -Tmin "$1"/func/rest/"$6"/tmp.nii.gz # remove any negative values introduced by spline interpolation;
	fslmaths "$1"/func/xfms/rest/T1w_acpc_brain_func.nii.gz -mas "$1"/func/rest/"$6"/tmp.nii.gz "$1"/func/rest/"$6"/brain_mask.nii.gz

	# run the "tedana" workflow; #Changed the call to explicitly use the python and binaries from the env as it was not always working with parallel.
	/opt/miniconda-latest/envs/me_v10/bin/python /opt/miniconda-latest/envs/me_v10/bin/tedana -d "$1"/func/rest/"$6"/Rest_E*_acpc.nii.gz -e $(cat "$1"/func/rest/"$6"/TE.txt) --out-dir "$1"/func/rest/"$6"/Tedana/ \
	--tedpca "$3" --fittype curvefit --mask "$1"/func/rest/"$6"/brain_mask.nii.gz --maxit "$4" --maxrestart "$5" --seed 42 \
    --convention orig --verbose --lowmem # specify more iterations / restarts to increase likelihood of ICA convergence (also increases possible runtime).

	# # remove temporary files;
	#rm "$1"/func/rest/"$6"/brain_mask.nii.gz
	#rm "$1"/func/rest/"$6"/tmp.nii.gz

	# move some files;
	cp "$1"/func/rest/"$6"/Tedana/ts_OC.nii.gz "$1"/func/rest/"$6"/Rest_OCME.nii.gz # optimally combined time-series;
	cp "$1"/func/rest/"$6"/Tedana/dn_ts_OC.nii.gz "$1"/func/rest/"$6"/Rest_OCME+MEICA.nii.gz # multi-echo denoised time-series;

	# make some folders for manual 
	# acceptance / rejection of ICA components; 
	mkdir "$1"/func/rest/"$6"/Tedana/figures/ManuallyAccepted/  
	mkdir "$1"/func/rest/"$6"/Tedana/figures/ManuallyRejected/ 

	# sweep through files of interest
	for i in betas_OC t2sv s0v ; do

		# sweep through hemispheres;
		for hemisphere in lh rh ; do

			# set a bunch of different 
			# ways of saying left and right
			if [ $hemisphere = "lh" ] ; then
				Hemisphere="L"
			elif [ $hemisphere = "rh" ] ; then
				Hemisphere="R"
			fi

			# define all of the the relevant surfaces & files;
			PIAL="$1"/anat/T1w/Native/"$2".$Hemisphere.pial.native.surf.gii
			WHITE="$1"/anat/T1w/Native/"$2".$Hemisphere.white.native.surf.gii
			MIDTHICK="$1"/anat/T1w/Native/"$2".$Hemisphere.midthickness.native.surf.gii
			MIDTHICK_FSLR32k="$1"/anat/T1w/fsaverage_LR32k/"$2".$Hemisphere.midthickness.32k_fs_LR.surf.gii
			ROI="$1"/anat/MNINonLinear/Native/"$2".$Hemisphere.roi.native.shape.gii
			ROI_FSLR32k="$1"/anat/MNINonLinear/fsaverage_LR32k/"$2".$Hemisphere.atlasroi.32k_fs_LR.shape.gii
			REG_MSMSulc="$1"/anat/MNINonLinear/Native/"$2".$Hemisphere.sphere.MSMSulc.native.surf.gii
			REG_MSMSulc_FSLR32k="$1"/anat/MNINonLinear/fsaverage_LR32k/"$2".$Hemisphere.sphere.32k_fs_LR.surf.gii

			# map functional data from volume to surface;
			wb_command -volume-to-surface-mapping "$1"/func/rest/"$6"/Tedana/"$i".nii.gz "$MIDTHICK" \
			"$1"/func/rest/"$6"/Tedana/"$hemisphere".native.shape.gii -ribbon-constrained "$WHITE" "$PIAL"
		
			# dilate metric file 10mm in geodesic space;
			wb_command -metric-dilate "$1"/func/rest/"$6"/Tedana/"$hemisphere".native.shape.gii \
			"$MIDTHICK" 10 "$1"/func/rest/"$6"/Tedana/"$hemisphere".native.shape.gii -nearest

			# remove medial wall in native mesh;  
			wb_command -metric-mask "$1"/func/rest/"$6"/Tedana/"$hemisphere".native.shape.gii \
			"$ROI" "$1"/func/rest/"$6"/Tedana/"$hemisphere".native.shape.gii 

			# resample metric data from native mesh to fs_LR_32k mesh;
			wb_command -metric-resample "$1"/func/rest/"$6"/Tedana/"$hemisphere".native.shape.gii "$REG_MSMSulc" \
			"$REG_MSMSulc_FSLR32k" ADAP_BARY_AREA "$1"/func/rest/"$6"/Tedana/"$hemisphere".32k_fs_LR.shape.gii \
			-area-surfs "$MIDTHICK" "$MIDTHICK_FSLR32k" -current-roi "$ROI"

			# remove medial wall in fs_LR_32k mesh;
			wb_command -metric-mask "$1"/func/rest/"$6"/Tedana/"$hemisphere".32k_fs_LR.shape.gii \
			"$ROI_FSLR32k" "$1"/func/rest/"$6"/Tedana/"$hemisphere".32k_fs_LR.shape.gii

		done

		# map betas to cortical surface (good for manual review of component classification)
		wb_command -cifti-create-dense-timeseries "$1"/func/rest/"$6"/Tedana/"$i".dtseries.nii -volume "$1"/func/rest/"$6"/Tedana/"$i".nii.gz "$1"/func/rois/Subcortical_ROIs_acpc.nii.gz \
		-left-metric "$1"/func/rest/"$6"/Tedana/lh.32k_fs_LR.shape.gii -roi-left "$1"/anat/MNINonLinear/fsaverage_LR32k/"$2".L.atlasroi.32k_fs_LR.shape.gii \
		-right-metric "$1"/func/rest/"$6"/Tedana/rh.32k_fs_LR.shape.gii -roi-right "$1"/anat/MNINonLinear/fsaverage_LR32k/"$2".R.atlasroi.32k_fs_LR.shape.gii 
		#rm "$1"/func/rest/"$6"/Tedana/*shape* # remove left over files 

	done

}

export -f func # run tedana;
#parallel --jobs $NTHREADS func ::: $Subdir ::: $Subject ::: $MEPCA ::: $MaxIterations ::: $MaxRestarts ::: $DataDirs # > /dev/null 2>&1
for i in ${DataDirs}; do echo "starting Tedana on ${i}" ; func ${Subdir} ${Subject} ${MEPCA} ${MaxIterations} ${MaxRestarts} ${i} ; done
rm "$Subdir"/DataDirs.txt  