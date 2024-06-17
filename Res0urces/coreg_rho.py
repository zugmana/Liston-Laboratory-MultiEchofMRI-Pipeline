#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jun 16 23:31:42 2024

@author: zugmana2
"""
import os
import sys
import numpy as np
import nibabel as nib
from scipy.stats import spearmanr
from scipy.io import savemat

def process_subdir(Subdir):
    # Infer subject name
    Subject = Subdir.split('/')[-1]

    # Read the brain mask and target image
    BrainMask = nib.load(os.path.join(Subdir, 'func/xfms/rest/T1w_acpc_brain_func_mask.nii.gz')).get_fdata()
    TargetImage = nib.load(os.path.join(Subdir, 'func/xfms/rest/AvgSBref2acpc_EpiReg+BBR.nii.gz')).get_fdata()

    # Define the number of sessions
    sessions = [d for d in os.listdir(os.path.join(Subdir, 'func/rest')) if d.startswith('session_')]

    count = 0  # tick
    Rho = []

    # Sweep the scans
    for s in range(len(sessions)):
        print(s + 1)
        # This is the number of runs for this session
        session_path = os.path.join(Subdir, 'func/rest', sessions[s])
        runs = [d for d in os.listdir(session_path) if d.startswith('run_')]

        # Sweep the runs
        for r in range(len(runs)):
            print(r + 1)
            # tick
            count += 1

            # Extract the SBref coregistered to target volume using average field map information
            Volume_path = os.path.join(Subdir, f'func/qa/CoregQA/SBref2acpc_EpiReg+BBR_AvgFM_S{s + 1}_R{r + 1}.nii.gz')
            Volume = nib.load(Volume_path).get_fdata()

            # Log spatial correlation
            Rho1, _ = spearmanr(Volume[BrainMask == 1], TargetImage[BrainMask == 1])
            Rho.append([Rho1, np.nan])

            # If scan-specific field map exists; otherwise use NaN place-holder
            scan_specific_path = os.path.join(Subdir, f'func/qa/CoregQA/SBref2acpc_EpiReg+BBR_ScanSpecificFM_S{s + 1}_R{r + 1}.nii.gz')
            if os.path.exists(scan_specific_path):
                Volume = nib.load(scan_specific_path).get_fdata()
                Rho2, _ = spearmanr(Volume[BrainMask == 1], TargetImage[BrainMask == 1])
                Rho[-1][1] = Rho2

            # Check which approach works best
            if Rho[count - 1][0] > Rho[count - 1][1] or np.isnan(Rho[count - 1][1]):
                with open(os.path.join(Subdir, f'func/rest/session_{s + 1}/run_{r + 1}/IntermediateCoregTarget.txt'), 'w') as f:
                    f.write(os.path.join(Subdir, 'func/xfms/rest/AvgSBref.nii.gz'))
                with open(os.path.join(Subdir, f'func/rest/session_{s + 1}/run_{r + 1}/Intermediate2ACPCWarp.txt'), 'w') as f:
                    f.write(os.path.join(Subdir, 'func/xfms/rest/AvgSBref2acpc_EpiReg+BBR_warp.nii.gz'))
            else:
                with open(os.path.join(Subdir, f'func/rest/session_{s + 1}/run_{r + 1}/IntermediateCoregTarget.txt'), 'w') as f:
                    f.write(os.path.join(Subdir, f'func/rest/session_{s + 1}/run_{r + 1}/SBref.nii.gz'))
                with open(os.path.join(Subdir, f'func/rest/session_{s + 1}/run_{r + 1}/Intermediate2ACPCWarp.txt'), 'w') as f:
                    f.write(os.path.join(Subdir, f'func/xfms/rest/SBref2acpc_EpiReg+BBR_S{s + 1}_R{r + 1}_warp.nii.gz'))

    print('done')

    # Save Rho variable
    savemat(os.path.join(Subdir, 'func/qa/CoregQA/Rho.mat'), {'Rho': Rho})

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <Subdir>")
        sys.exit(1)

    Subdir = sys.argv[1]
    process_subdir(Subdir)

