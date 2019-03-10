#!/usr/bin/env bash
#
# Functional Preprocessing :
# fieldmap correction - FSL fsl_prepare_fieldmap & epi_reg
# slice time correction - AFNI 3dTshift
# motion correction - AFNI 3dvolreg
# functional to anatomical registration - FSL epi_reg
# regression - AFNI 3dDeconvolve
# temporal filtering - AFNI 3dTproject
#
# Ben Puccio
# 2018-12-15

# set the timing
SECONDS=0

# set paths
mni_3mm=/Users/ben/Documents/cpac_image_resources/MNI_3mm/MNI152_T1_3mm_brain.nii.gz
mni_4mm=/Users/ben/Documents/cpac_image_resources/MNI_4mm/MNI152_T1_4mm_brain.nii.gz
mni_3mm_noss=/Users/ben/Documents/cpac_image_resources/MNI_3mm/MNI152_T1_3mm.nii.gz
mni_4mm_noss=/Users/ben/Documents/cpac_image_resources/MNI_4mm/MNI152_T1_4mm.nii.gz
PNAS_Smith09=/Users/ben/Documents/PNAS_Smith09_rsn10_4mm.nii.gz
PNAS_Smith09_BM=/Users/ben/Documents/PNAS_Smith09_bm10_4mm.nii.gz

# Use for ventricle extraction
suma_MNI_N27=/Users/ben/Documents/suma_MNI_N27/aparc+aseg.nii

# Choose seg
choose_seg=fast

data=/Users/ben/Documents/_FIBROMIALGIA/nifti_controls
drive=/Volumes/ben_drive/_FIBROMIALGIA/nifti_controls
stim_path=/Users/ben/Documents/FIBRO_BEHAV_DATA_HC

# dwelltime
eff_echo_spacing=0.00029000167
echo_spacing=0.00029
asym_time=2.46
epi_factor=64
TR=2

# loop through each subject and preprocess each session containing fmris
for fold in $(ls -d ${drive}/*/fmri*.nii.gz); do

  # get subject and project names
  base_path=$(dirname ${fold})
  sub=$(basename ${base_path})

  # move directory from drive to computer
  if [ ! -d ${data}/${sub}/fmri_processing ]; then
    mv ${drive}/${sub}/fmri_processing ${data}/${sub}
  fi

  ## Set up output paths
  fmri_proc=${data}/${sub}/fmri_processing
  t1out=${fmri_proc}/t1_fmri
  t2out=${fmri_proc}/t2_fmri
  frestout=${fmri_proc}/fmri_rest
  fphysout=${fmri_proc}/fmri_physical
  fsocialout=${fmri_proc}/fmri_social
  fmapout=${fmri_proc}/fmap
  fs=${base_path}/freesurfer

  ## Look for specific study string in each fmri file name
  if [[ $fold == *"rest"* ]]; then
    num=1
    fmri=${frestout}
    fmapout=${fmapout}_1
    task=NA
    mni=${mni_4mm}
    mni_noss=${mni_4mm_noss}
  elif [[ $fold == *"physical"* ]]; then
    task=physical
    mni=${mni_3mm}
    mni_noss=${mni_3mm_noss}
    if [[ $fold == *"_1"* ]]; then
      num=1
      fmri=${fphysout}_1
      fmapout=${fmapout}_1
      fmri_task=${fphysout}
    elif [[ $fold == *"_2"* ]]; then
      num=2
      fmri=${fphysout}_2
      fmapout=${fmapout}_2
      fmri_task=${fphysout}
    fi
  elif [[ $fold == *"social"* ]]; then
    task=social
    mni=${mni_3mm}
    mni_noss=${mni_3mm_noss}
    if [[ $fold == *"_1"* ]]; then
      num=1
      fmri=${fsocialout}_1
      fmapout=${fmapout}_1
      fmri_task=${fsocialout}
    elif [[ $fold == *"_2"* ]]; then
      num=2
      fmri=${fsocialout}_2
      fmapout=${fmapout}_2
      fmri_task=${fsocialout}
    fi
  fi

  ## Copy fmri file to fmri_processing directory
  if [ ! -f ${fmri}.nii.gz ]; then
    3dcopy ${fold} ${fmri}.nii.gz
  fi

  ## Fieldmap Correction
  ## Get path names from each file
  f=$(ls -d ${base_path}/fieldmap_fMRI_${num}*.nii.gz)
  fmapmag=0
  for fname in ${f}; do
    if [[ ${fname} == *"ph"* ]]; then
      fmapphase=${fname}
    else
      if [[ ${fmapmag} == 0 ]]; then
        fmapmag=${fname}
      fi
    fi
  done
  # copy to proccessing directory
  if [ ! -f ${fmapout}_mag.nii.gz ]; then
    3dcopy ${fmapmag} ${fmapout}_mag.nii.gz
    3drefit -deoblique ${fmapout}_mag.nii.gz
  fi
  fmapmag=0
  if [ ! -f ${fmapout}_phase.nii.gz ]; then
    3dcopy ${fmapphase} ${fmapout}_phase.nii.gz
    3drefit -deoblique ${fmapout}_phase.nii.gz
  fi
  # Skullstrip using bet twice, combine masks
  if [ ! -f ${fmapout}_brain_mag.nii.gz ]; then
    bet ${fmapout}_mag.nii.gz ${fmapout}_brain_mag_b.nii.gz -B -m
    bet ${fmapout}_mag.nii.gz ${fmapout}_brain_mag_s.nii.gz -S -m
    3dcalc -a ${fmapout}_brain_mag_b_mask.nii.gz -b ${fmapout}_brain_mag_s_mask.nii.gz -expr 'a*b' -prefix ${fmapout}_brain_mag_mask.nii.gz
    3dcalc -a ${fmapout}_mag.nii.gz -b ${fmapout}_brain_mag_mask.nii.gz -expr 'a*b' -prefix ${fmapout}_brain_mag.nii.gz
  fi
  # Add zero pad to top of mask (for erosion), erode -2, remove zero pad, apply mask to fieldmap to skullstrip
  if [ ! -f ${fmapout}_brain.nii.gz ]; then
    3dzeropad -S 1 -prefix ${fmapout}_brain_mag_mask_zpad.nii.gz ${fmapout}_brain_mag_mask.nii.gz
    3dmask_tool -input ${fmapout}_brain_mag_mask_zpad.nii.gz -prefix ${fmapout}_brain_ero_zpad.nii.gz -dilate_input -2 -fill_holes
    3dzeropad -S -1 -prefix ${fmapout}_brain_ero.nii.gz ${fmapout}_brain_ero_zpad.nii.gz
    3dcalc -a ${fmapout}_brain_ero.nii.gz -b ${fmapout}_mag.nii.gz -expr "a*b" -prefix ${fmapout}_brain.nii.gz
  fi
  # prepare fieldmap
  if [ ! -f ${fmapout}.nii.gz ]; then
    fsl_prepare_fieldmap SIEMENS ${fmapout}_phase.nii.gz ${fmapout}_brain.nii.gz ${fmapout}.nii.gz ${asym_time}
  fi

  ## Functional Processing

  # Copy relevant anatomical images from diffusion session dir to functional dir
  if [[ ${t1out} == ${fmri_proc}/t1_diff ]]; then
    if [ ! -f ${t1out}_0GenericAffine.mat ]; then
      cp ${drive}/${sub}/diff_processing/t1_diff_0GenericAffine.mat ${t1out}_0GenericAffine.mat
    fi
    if [ ! -f ${t1out}_1Warp.nii.gz]; then
      3dcopy ${drive}/${sub}/diff_processing/t1_diff_1Warp.nii.gz ${t1out}_1Warp.nii.gz
    fi
    if [ ! -f ${t1out}_brain.nii.gz ]; then
      3dcopy ${drive}/${sub}/diff_processing/t1_diff_brain.nii.gz ${t1out}_brain.nii.gz
    fi
    if [ ! -f ${t1out}_brain_mask.nii.gz ]; then
      3dcopy ${drive}/${sub}/diff_processing/t1_diff_brain_mask.nii.gz ${t1out}_brain_mask.nii.gz
    fi
    if [ ! -f ${t1out}_csfmask_mni.nii.gz ]; then
      3dcopy ${drive}/${sub}/diff_processing/t1_diff_csfmask_mni.nii.gz ${t1out}_csfmask_mni.nii.gz
    fi
    if [ ! -f ${t1out}_gm_mni.nii.gz ]; then
      3dcopy ${drive}/${sub}/diff_processing/t1_diff_gm_mni.nii.gz ${t1out}_gm_mni.nii.gz
    fi
    if [ ! -f ${t1out}_unifize.nii.gz ]; then
      3dcopy ${drive}/${sub}/diff_processing/t1_diff_unifize.nii.gz ${t1out}_unifize.nii.gz
    fi
    if [ ! -f ${t1out}_wmask_mni.nii.gz ]; then
      3dcopy ${drive}/${sub}/diff_processing/t1_diff_wmask_mni.nii.gz ${t1out}_wmask_mni.nii.gz
    fi
    if [ ! -f ${t1out}_wmseg.nii.gz ]; then
      3dcopy ${drive}/${sub}/diff_processing/t1_diff_wmseg.nii.gz ${t1out}_wmseg.nii.gz
    fi
  fi

  # Deoblique and Refit to RPI
  if [ ! -f ${fmri}_reorient.nii.gz ]; then
    3drefit -deoblique ${fmri}.nii.gz
    3dresample -orient RPI -prefix ${fmri}_reorient.nii.gz -inset ${fmri}.nii.gz
  fi

  # Count outliers
  if [ ! -f ${fmri}_outcount.1D ]; then
    3dToutcount -automask -fraction -polort 3 -legendre ${fmri}.nii.gz > ${fmri}_outcount.1D
  fi

  ## Slice Time Correction - voxshift, -slice ${MIDSLICE}
  if [ ! -f ${fmri}_tshift.nii.gz ]; then
    3dTshift -verbose -Fourier -tpattern alt+z2 -TR ${TR}s -prefix ${fmri}_tshift.nii.gz ${fmri}_reorient.nii.gz
  fi

  ## Motion correction - zpad?
  if [ ! -f ${fmri}_motion.nii.gz ]; then
    3dvolreg -verbose -Fourier -prefix ${fmri}_motion.nii.gz -zpad 1 -1Dfile ${fmri}_motion.1D -1Dmatrix_save ${fmri}_motion_matrix.1D ${fmri}_tshift.nii.gz
  fi

  ## Freesurfer wm and csf mask in mni space - copy from FS folder, change to short data type
  if [[ ${choose_seg} == 'fs' ]]; then
    if [ ! -f ${t1out}_wmseg_fs_mni.nii.gz ]; then
      3dcopy ${fs}/fs_wm_mni.nii.gz ${t1out}_wmseg_fs_mni.nii.gz
    fi
    if [ ! -f ${t1out}_wmseg_fs_mni_short.nii.gz ]; then
      3dcalc -a ${t1out}_wmseg_fs_mni.nii.gz -expr "a" -datum short -prefix ${t1out}_wmseg_fs_mni_short.nii.gz
    fi
    if [ ! -f ${t1out}_vent_fs_mni.nii.gz ]; then
      3dcopy ${fs}/fs_vent_mni.nii.gz ${t1out}_vent_fs_mni.nii.gz
    fi
    if [ ! -f ${t1out}_vent_fs_mni_short.nii.gz ]; then
      3dcalc -a ${t1out}_vent_fs_mni.nii.gz -expr "a" -datum short -prefix ${t1out}_vent_fs_mni_short.nii.gz
    fi
    if [ ! -f ${t1out}_aseg_rank_mni.nii.gz ]; then
      3dcopy ${fs}/aseg_rank_mni.nii.gz ${t1out}_aseg_rank_mni.nii.gz
    fi
    if [ ! -f ${t1out}_gm_fs_mni.nii.gz ]; then
      3dcalc -a ${fs}/aseg_mni.nii.gz -b ${t1out}_wmseg_fs_mni_short.nii.gz -c ${t1out}_vent_fs_mni.nii.gz -expr "(step(a))-(b+c)" -datum short -prefix ${t1out}_gm_fs_mni.nii.gz
    fi
  fi

  # Choose wm mask based on freesurfer (using t1 from diff session) or fsl fast
  if [[ ${choose_seg} == 'fs' ]]; then
    if [[ ${t1out} == ${fmri_proc}/t1_diff ]]; then
      if [ ! -f ${t1out}_wmseg_fs.nii.gz ]; then
        3dcopy ${fs}/fs_wm_fs2afni.nii.gz ${t1out}_wmseg_fs.nii.gz
      fi
      wmseg=${t1out}_wmseg_fs.nii.gz
    else
      wmseg=${t1out}_wmseg.nii.gz
    fi
  else
    wmseg=${t1out}_wmseg.nii.gz
  fi

  ## Registration of FMRI to T1 anatomical
  # downsample anat for registration (so epi doesn't get upsampled)
  dimensions=$(3dinfo -ad3 ${fmri}.nii.gz)
  if [ ! -f ${fmri}_unifize_downsample.nii.gz ]; then
    3dresample -dxyz ${dimensions} -rmode Li -prefix ${fmri}_unifize_downsample.nii.gz -inset ${t1out}_unifize.nii.gz
  fi

  ## Run epi_reg on first slice of EPI, apply warp to entire 4D EPI
  if [ ! -f ${fmri}_slice.nii.gz ]; then
    3dcalc -a ${fmri}_motion.nii.gz[0] -expr 'a' -prefix ${fmri}_slice.nii.gz
  fi
  if [ ! -f ${fmri}_epi2anat.nii.gz ]; then
    epi_reg -v --epi=${fmri}_slice.nii.gz --t1=${fmri}_unifize_downsample.nii.gz --t1brain=${t1out}_brain.nii.gz --wmseg=${wmseg} --fmap=${fmapout}.nii.gz --fmapmag=${fmapout}_mag.nii.gz --fmapmagbrain=${fmapout}_brain.nii.gz --echospacing=${echo_spacing} --pedir=-y --out=${fmri}_epi2anat.nii.gz
  fi
  # apply warp to 4D
  if [ ! -f ${fmri}_epi2anat_4d.nii.gz ]; then
    applywarp -i ${fmri}_motion.nii.gz -o ${fmri}_epi2anat_4d.nii.gz -r ${fmri}_unifize_downsample.nii.gz -w ${fmri}_epi2anat_warp.nii.gz
  fi

  ## Mask FMRI data set with T1 brainmask - use to skull strip (can combine with 3dAutomask)
  if [ ! -f ${fmri}_brain_mask_fill.nii.gz ]; then
    3dresample -master ${fmri}_epi2anat_4d.nii.gz -input ${t1out}_brain_mask_fill.nii.gz -prefix ${fmri}_brain_mask_fill.nii.gz -rmode Li
  fi

  ## Registration of FMRI to mni space - apply previous mni transform to bold file (-e 3 is important)
  if [ ! -f ${fmri}_mni_brain_mask.nii.gz ]; then
    antsApplyTransforms -d 3 -e 3 -i ${fmri}_brain_mask_fill.nii.gz -o ${fmri}_mni_brain_mask.nii.gz -r ${mni} -t ${t1out}_2Warp.nii.gz -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -n NearestNeighbor -v 1
  fi
  if [ ! -f ${fmri}_mni.nii.gz ]; then
    antsApplyTransforms -d 3 -e 3 -i ${fmri}_epi2anat_4d.nii.gz -o ${fmri}_mni.nii.gz -r ${mni_noss} -t ${t1out}_2Warp.nii.gz -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
  fi

  ## Extents mask - AFNI
  # create an all-1 dataset to mask the extents of the warp
  if [ ! -f ${fmri}_all1.nii.gz ]; then
    3dcalc -overwrite -a ${fmri}_tshift.nii.gz -expr 1 -prefix ${fmri}_all1.nii.gz
  fi
  # apply warps to all-1 dataset - volreg, epi2anat, ants
  if [ ! -f ${fmri}_all1_motion.nii.gz ]; then
    3dAllineate -base ${fmri}_motion.nii.gz -input ${fmri}_all1.nii.gz -1Dmatrix_apply ${fmri}_motion_matrix.1D -prefix ${fmri}_all1_motion.nii.gz
  fi
  if [ ! -f ${fmri}_all1_epi2anat.nii.gz ]; then
    applywarp -i ${fmri}_all1_motion.nii.gz -o ${fmri}_all1_epi2anat.nii.gz -r ${fmri}_unifize_downsample.nii.gz -w ${fmri}_epi2anat_warp.nii.gz
  fi
  if [ ! -f ${fmri}_all1_mni.nii.gz ]; then
    antsApplyTransforms -d 3 -e 3 -i ${fmri}_all1_epi2anat.nii.gz -o ${fmri}_all1_mni.nii.gz -r ${mni_noss} -t ${t1out}_2Warp.nii.gz -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
  fi
  # make an extents intersection mask of this run
  if [ ! -f ${fmri}_all1_mni_min.nii.gz ]; then
    3dTstat -min -prefix ${fmri}_all1_mni_min.nii.gz ${fmri}_all1_mni.nii.gz
  fi
  # create the extents mask: mask_epi_extents+orig (this is a mask of voxels that have valid data at every TR)
  if [ ! -f ${fmri}_all1_mni_mean.nii.gz ]; then
    3dMean -datum short -prefix ${fmri}_all1_mni_mean.nii.gz ${fmri}_all1_mni_min.nii.gz
  fi
  if [ ! -f ${fmri}_mni_mask_extents.nii.gz ]; then
    3dcalc -a ${fmri}_all1_mni_mean.nii.gz -expr 'step(a-0.999)' -prefix ${fmri}_mni_mask_extents.nii.gz
  fi
  # and apply the extents mask to the EPI data (delete any time series with missing data)
  if [ ! -f ${fmri}_mni_brain_extents.nii.gz ]; then
    3dcalc -a ${fmri}_mni.nii.gz -b ${fmri}_mni_mask_extents.nii.gz -expr 'a*b' -prefix ${fmri}_mni_brain_extents.nii.gz
  fi

  ## Combine anat skull strip with extents mask - intersection
  if [ ! -f ${fmri}_mni_brain_mask_final.nii.gz ]; then
    3dmask_tool -input ${fmri}_mni_brain_mask.nii.gz ${fmri}_mni_mask_extents.nii.gz -prefix ${fmri}_mni_brain_mask_final.nii.gz -frac 1.0 -fill_holes
  fi

  ## Use combined mask to skullstrip fmri data
  if [ ! -f ${fmri}_mni_brain.nii.gz ]; then
    3dcalc -a ${fmri}_mni_brain_mask_final.nii.gz -b ${fmri}_mni.nii.gz -expr "a*b" -prefix ${fmri}_mni_brain.nii.gz
  fi

  ## Blur & scale (blur only in task, blur after 3dDeconvolve for resting state)
  if [ ${fmri} != ${frestout} ]; then
    ## Blur
    if [ ! -f ${fmri}_mni_blur.nii.gz ]; then
      3dmerge -1blur_fwhm 4.0 -doall -prefix ${fmri}_mni_blur.nii.gz ${fmri}_mni_brain.nii.gz
    fi
    ## Scaling
    if [ ! -f ${fmri}_mni_mean.nii.gz ]; then
      3dTstat -prefix ${fmri}_mni_mean.nii.gz ${fmri}_mni_blur.nii.gz
    fi
    if [ ! -f ${fmri}_mni_scaled.nii.gz ]; then
      3dcalc -a ${fmri}_mni_blur.nii.gz -b ${fmri}_mni_mean.nii.gz -c ${fmri}_mni_brain_mask_final.nii.gz -expr 'c * min(200, a/b*100)*step(a)*step(b)' -prefix ${fmri}_mni_scaled.nii.gz
    fi
  else
    ## Scaling
    if [ ! -f ${fmri}_mni_mean.nii.gz ]; then
      3dTstat -prefix ${fmri}_mni_mean.nii.gz ${fmri}_mni_brain.nii.gz
    fi
    if [ ! -f ${fmri}_mni_scaled.nii.gz ]; then
      3dcalc -a ${fmri}_mni_brain.nii.gz -b ${fmri}_mni_mean.nii.gz -c ${fmri}_mni_brain_mask_final.nii.gz -expr 'c * min(200, a/b*100)*step(a)*step(b)' -prefix ${fmri}_mni_scaled.nii.gz
    fi
  fi
  # #Normalized intensity = (TrueValue*10000)/global4Dmean
  # if [ ! -f ${fmri}_mni_fslscaled.nii.gz ]; then
  #   fslmaths ${fmri}_mni_brain.nii.gz -ing 10000 ${fmri}_mni_fslscaled.nii.gz -odt float
  # fi

  ## Nuisance Signal Regression

  # Resample masks to EPI dimensions - perform only once for tasks
  if [[ ${fmri} != ${fphysout}_2 ]] || [[ ${fmri} != ${fsocialout}_2 ]]; then

    # Choose between FSL or freesurfer masks
    if [[ ${choose_seg} == 'fast' ]]; then
      # FSL Fast masks thresholded first to 80%, GM prob mask blurred 4mm FWHM then thresholded to 25%
      if [ ! -f ${fmri}_csf_mni_mask.nii.gz ]; then
        3dresample -master ${fmri}_mni_brain.nii.gz -input ${t1out}_csf_mni.nii.gz -prefix ${fmri}_csf_mni.nii.gz -rmode Li
        3dcalc -a ${fmri}_csf_mni.nii.gz -b ${fmri}_mni_brain_mask_final.nii.gz -expr 'b * step(a-0.8)' -prefix ${fmri}_csf_mni_mask.nii.gz -datum short
      fi
      if [ ! -f ${fmri}_wm_mni_mask.nii.gz ]; then
        3dresample -master ${fmri}_mni_brain.nii.gz -input ${t1out}_wm_mni.nii.gz -prefix ${fmri}_wm_mni.nii.gz -rmode Li
        3dcalc -a ${fmri}_wm_mni.nii.gz -b ${fmri}_mni_brain_mask_final.nii.gz -expr 'b * step(a-0.8)' -prefix ${fmri}_wm_mni_mask.nii.gz -datum short
      fi
      if [ ! -f ${t1out}_gm_mni_blur.nii.gz ]; then
        3dmerge -1blur_fwhm 4 -doall -prefix ${t1out}_gm_mni_blur.nii.gz ${t1out}_gm_mni.nii.gz
      fi
      if [ ! -f ${fmri}_gm_mni_mask.nii.gz ]; then
        3dresample -master ${fmri}_mni_brain.nii.gz -input ${t1out}_gm_mni_blur.nii.gz -prefix ${fmri}_gm_mni_blur.nii.gz -rmode Li
        3dcalc -a ${fmri}_gm_mni_blur.nii.gz -b ${fmri}_mni_brain_mask_final.nii.gz -expr 'b * step(a-0.25)' -prefix ${fmri}_gm_mni_mask.nii.gz -datum short
      fi

      # ventricle extraction - use ventricle mask from suma_MNI_N27, intersect with FAST csf mask
      if [ ! -f ${t1out}_vent_N27_mni.nii.gz ]; then
        3dcalc -a ${suma_MNI_N27} -datum byte -prefix ${t1out}_vent_N27_mni.nii.gz -expr 'amongst(a,4,43)'
      fi
      if [ ! -f ${fmri}_vent_N27_mni.nii.gz ]; then
        3dresample -master ${fmri}_mni_brain.nii.gz -input ${t1out}_vent_N27_mni.nii.gz -prefix ${fmri}_vent_N27_mni.nii.gz -rmode Li
      fi
      if [ ! -f ${fmri}_vent_mni_inter.nii.gz ]; then
        3dmask_tool -input ${fmri}_vent_N27_mni.nii.gz ${fmri}_csf_mni_mask.nii.gz -prefix ${fmri}_vent_mni_inter.nii.gz -inter
      fi
      if [[ $task == 'NA' ]]; then
        #extract timecourses
        if [ ! -f ${fmri}_vent_tc.1D ]; then
          3dmaskave -q -mask ${fmri}_vent_mni_inter.nii.gz ${fmri}_mni_scaled.nii.gz > ${fmri}_vent_tc.1D
        fi
        if [ ! -f ${fmri}_wm_tc.1D ]; then
          3dmaskave -q -mask ${fmri}_wm_mni_mask.nii.gz ${fmri}_mni_scaled.nii.gz > ${fmri}_wm_tc.1D
        fi
      fi
    else
      # fractionize freesurfer masks (clip 0.25)
      if [ ! -f ${fmri}_wmseg_fs_mni_frac.nii.gz ]; then
        3dfractionize -template ${fmri}_mni_brain.nii.gz -input ${t1out}_wmseg_fs_mni_short.nii.gz -preserve -prefix ${fmri}_wmseg_fs_mni_frac.nii.gz -clip 0.25
      fi
      if [ ! -f ${fmri}_vent_fs_mni_frac.nii.gz ]; then
        3dfractionize -template ${fmri}_mni_brain.nii.gz -input ${t1out}_vent_fs_mni_short.nii.gz -preserve -prefix ${fmri}_vent_fs_mni_frac.nii.gz -clip 0.25
      fi
      if [ ! -f ${fmri}_gm_mni_mask.nii.gz  ]; then
        3dfractionize -template ${fmri}_mni_brain.nii.gz -input ${t1out}_gm_fs_mni.nii.gz -preserve -prefix ${fmri}_gm_mni_mask.nii.gz  -clip 0.25
      fi
      #extract wm and vent timecourses
      if [ ! -f ${fmri}_vent_tc.1D ]; then
        3dmaskave -q -mask ${fmri}_vent_fs_mni_frac.nii.gz ${fmri}_mni_scaled.nii.gz > ${fmri}_vent_tc.1D
      fi
      if [ ! -f ${fmri}_wm_tc.1D ]; then
        3dmaskave -q -mask ${fmri}_wmseg_fs_mni_frac.nii.gz ${fmri}_mni_scaled.nii.gz > ${fmri}_wm_tc.1D
      fi
    fi
  fi

  ## ROIs - set up regions of interest, (maybe ACC, raphe nuclei)
  # Freesurfer ROIs - copy from folder
  # if [ ! -f ${t1out}_parce_fs_mni.nii.gz ]; then
  #   3dcopy ${fs}/aparc.a2009s+aseg_mni.nii.gz ${t1out}_parce_fs_mni.nii.gz
  # fi
  # # Posterior cingulate cortex (PCC)
  # if [ ! -f ${t1out}_pcc.nii.gz ]; then
  #   3dcalc -a ${t1out}_parce_fs_mni.nii.gz -datum byte -prefix ${t1out}_pcc.nii.gz -expr 'amongst(a,11109,11110,12109,12110)'
  # fi

  # compute de-meaned motion parameters (for use in regression)
  if [ ! -f ${fmri}_motion_demean.1D ]; then
    1d_tool.py -infile ${fmri}_motion.1D -set_nruns 1 -demean -write ${fmri}_motion_demean.1D
  fi
  # compute motion parameter derivatives (for use in regression)
  if [ ! -f ${fmri}_motion_derive.1D ]; then
    1d_tool.py -infile ${fmri}_motion.1D -set_nruns 1 -derivative -demean -write ${fmri}_motion_derive.1D
  fi
  # # create censor file motion_${subj}_censor.1D, for censoring motion
  # if [ ! -f ${fmri}_motion_censor.1D ]; then
  #   1d_tool.py -infile ${fmri}_motion.1D -set_nruns 1 -show_censor_count -censor_prev_TR -censor_motion 0.2 ${fmri}_motion
  # fi
  # # combine multiple censor files - calculate outliers into outcount file
  # if [ ! -f ${fmri}_censor_combined_2.1D ]; then
  #   1deval -a ${fmri}_motion_censor.1D -b ${fmri}_outcount_censor.1D -expr "a*b" > ${fmri}_censor_combined_2.1D
  # fi
  # split_into_pad_runs for multi-runs

  ## Deconvolution

  ## Resting state analysis
  if [[ ${fmri} == ${frestout} ]]; then


    # 1dBport -nodata 150 ${tr} -band 0.01 1 -invert -nozero > bandpass_rall.1D

    ## 3dDeconvolve - regress out motion (demean & derivative), wm & ventricle masks
    if [ ! -f ${fmri}_x1D.xmat.1D ]; then
      3dDeconvolve -polort A -num_stimts 14 \
        -stim_file 1 ${fmri}_motion_demean.1D'[0]' -stim_base 1 -stim_label 1 'roll' \
        -stim_file 2 ${fmri}_motion_demean.1D'[1]' -stim_base 2 -stim_label 2 'pitch' \
        -stim_file 3 ${fmri}_motion_demean.1D'[2]' -stim_base 3 -stim_label 3 'yaw' \
        -stim_file 4 ${fmri}_motion_demean.1D'[3]' -stim_base 4 -stim_label 4 'dS' \
        -stim_file 5 ${fmri}_motion_demean.1D'[4]' -stim_base 5 -stim_label 5 'dL' \
        -stim_file 6 ${fmri}_motion_demean.1D'[5]' -stim_base 6 -stim_label 6 'dP' \
        -stim_file 7 ${fmri}_motion_derive.1D'[0]' -stim_base 7 -stim_label 7 'roll_deriv' \
        -stim_file 8 ${fmri}_motion_derive.1D'[1]' -stim_base 8 -stim_label 8 'pitch_deriv' \
        -stim_file 9 ${fmri}_motion_derive.1D'[2]' -stim_base 9 -stim_label 9 'yaw_deriv' \
        -stim_file 10 ${fmri}_motion_derive.1D'[3]' -stim_base 10 -stim_label 10 'dS_deriv' \
        -stim_file 11 ${fmri}_motion_derive.1D'[4]' -stim_base 11 -stim_label 11 'dL_deriv' \
        -stim_file 12 ${fmri}_motion_derive.1D'[5]' -stim_base 12 -stim_label 12 'dP_deriv' \
        -stim_file 13 ${fmri}_vent_tc.1D -stim_base 13 -stim_label 13 'vent' \
        -stim_file 14 ${fmri}_wm_tc.1D -stim_base 14 -stim_label 14 'wm' \
        -TR_1D ${TR}s -bucket ${fmri}_bucket -cbucket ${fmri}_cbucket \
        -x1D ${fmri}_x1D.xmat.1D -input ${fmri}_mni_scaled.nii.gz \
        -errts ${fmri}_clean.nii.gz
        # -x1D_uncensored ${fmri}_x1D.nocensor.xmat.1D -x1D_stop
    fi

    ## anatICOR , use -nuisance, (MAYBE HAVE TO USE ASEG_RANK)
    # if [[ ${choose_seg} == 'fs' ]]; then
        # if [ ! -f ${fmri}_anaticor.nii.gz ]; then
        #   @ANATICOR -ts ${fmri}_mni_scaled.nii.gz -polort 0 -motion ${fmri}_motion.1D -aseg ${t1out}_aseg_rank_mni.nii.gz -prefix ${fmri}_anaticor
        # fi
    # fi

    # # fast ANATICOR: generate local WMe time series averages
    # # mask white matter eroded before blurring
    # 3dmask_tool
    # 3dcalc -a  -b ${fmri}_wmask_mni_frac.nii.gz -expr "a*bool(b)" -datum float -prefix ${fmri}_wmask_mni_epi.nii.gz
    # # generate ANATICOR voxelwise regressors via blur
    # 3dmerge -1blur_fwhm 30 -doall -prefix ${fmri}_wmask_mni_local.nii.gz ${fmri}_wmask_mni_epi.nii.gz
    # # -- use 3dTproject to project out regression matrix --
    # 3dTproject -polort 0 -bandpass 0.01 0.1 -blur 4 -input ${fmri}_mni_scaled.nii.gz -dsort ${fmri}_wmask_mni_local.nii.gz -ort ${fmri}_x1D.xmat.1D -prefix ${fmri}_fanaticor.nii.gz

    #3dTproject, after -x1D_stop in 3dDeconvolve ( -censor ${fmri}_motion.1D -cenmode ZERO -dsort ${fmri}_anaticor.nii.gz)
    if [ ! -f ${fmri}_blur_filtered.nii.gz ]; then
      3dTproject -verb -polort 0 -bandpass 0.01 0.1 -blur 4 -input ${fmri}_mni_scaled.nii.gz -ort ${fmri}_x1D.xmat.1D -prefix ${fmri}_blur_filtered.nii.gz
    fi

    # Display any large pairwise correlations from the X-matrix
    if [ ! -f ${fmri}_cormat_warn.txt ]; then
      1d_tool.py -show_cormat_warnings -infile ${fmri}_x1D.xmat.1D | tee ${fmri}_cormat_warn.txt
    fi

    ## Seed based connectivity
    # Extract timecourse
    if [ ! -f ${fmri}_TCs.1D ]; then
      fsl_glm -i ${fmri}_clean.nii.gz -d ${PNAS_Smith09} -o ${fmri}_TCs.1D
    fi
    # if [ ! -f ${fmri}_TC.1D ]; then
    #   3dmaskave -q -mask ${PNAS_Smith09} ${fmri}_clean.nii.gz > ${fmri}_TC.1D
    # fi
    # Calculate FC map for each extracted timecourse
    if [ ! -f ${fmri}_fcs.nii.gz ]; then
      3dTcorr1D -prefix ${fmri}_fcs.nii.gz -mask ${fmri}_mni_brain_mask_final.nii.gz ${fmri}_clean.nii.gz ${fmri}_TCs.1D
    fi
    # if [ ! -f ${fmri}_fc.nii.gz ]; then
    #   3dTcorrelate -polort -1 -pearson -prefix ${fmri}_fc.nii.gz ${PNAS_Smith09} ${fmri}_clean.nii.gz
    # fi

    # Regional homogeneity, do smoothing afterwards
    if [ ! -f ${fmri}_reho.nii.gz ]; then
      3dReHo -prefix ${fmri}_reho.nii.gz -inset ${fmri}_clean.nii.gz -mask ${fmri}_mni_brain_mask_final.nii.gz -chi_sq
    fi
    # normalize map (does chi_sqi already do that?)
    # extract kendall coefficients
    if [ ! -f ${fmri}_reho_Kendall.1D ]; then
      3dmaskdump -noijk -mask ${fmri}_gm_mni_mask.nii.gz ${fmri}_reho.nii.gz[0] > ${fmri}_reho_Kendall.1D
    fi
    # take mean, subtract mean from each voxel, divide by the KCC stdev across all voxels in the whole-brain mask
      mmms=$(1d_tool.py -show_mmms -infile ${fmri}_reho_Kendall.1D)
      mean=$(echo ${mmms[@]} | cut -d' ' -f12)
      mean=${mean/,/}
      stdev=$(echo ${mmms[@]} | cut -d' ' -f18)
      stdev=${stdev/,/}
    if [ ! -f ${fmri}_reho_normalized.nii.gz ]; then
      3dcalc -a ${fmri}_reho.nii.gz[0] -b ${fmri}_gm_mni_mask.nii.gz -expr "((a-$mean)/$stdev*b)" -prefix ${fmri}_reho_normalized.nii.gz
    fi

    ## ALFF & fALFF - use -mask (can use CPAC calculation as well)
    if [ ! -f ${fmri}_fALFF+orig.BRIK ]; then
      3dRSFC -nodetrend -blur 4 -mask ${fmri}_mni_brain_mask_final.nii.gz -prefix ${fmri} 0.01 0.1 ${fmri}_clean.nii.gz
    fi

    ## Estimate blur from error time series
    if [ ! -f ${fmri}_fwhmx_acf.1D ]; then
      3dFWHMx -acf ${fmri}_fwhmx_acf.1D -ShowMeClassicFWHM -input ${fmri}_blur_filtered.nii.gz -out ${fmri}_fwhmx_out.1D >> ${fmri}_blur.1D
    fi

    ## Network analysis - degree centrality, etc
    #modularity - modularity index, participation coefficient
    #community detection

    ## Correlation analysis
    # if [ ! -f ${fmri}_netcorr ]; then
    #   3dNetCorr -inset ${fmri}_blur_filtered.nii.gz -in_rois ${t1out}_pcc.nii.gz -fish_z -ts_wb_corr -prefix ${fmri}_netcorr
    # fi
    ## convert r score to z score
    # if [ ! -f ${fmri}_netcorr_z_score.nii.gz ]; then
    #   3dcalc -a ${fmri}_netcorr_r_score.nii.gz -expr 'log((1+a)/(1-a))/2' -prefix ${fmri}_netcorr_z_score.nii.gz
    # fi

  fi

  # Task based analysis
  if [[ ${fmri} == ${fphysout}_${num} ]] || [[ ${fmri} == ${fsocialout}_${num} ]]; then

    # Convert stimulus timing files to afni format
    sub_formatted=$(expr ${sub} / 1 )
    if [ ! -f ${fmri}_stim.1D ]; then
      timing_tool.py -fsl_timing_files ${stim_path}/${sub_formatted}_${task}_stimtimes_${num}.txt -write_timing ${fmri}_stim.1D
    fi
    if [ ! -f ${fmri}_stim_pain.1D ]; then
      timing_tool.py -fsl_timing_files ${stim_path}/${sub_formatted}_${task}_pain_${num}.txt -write_timing ${fmri}_stim_pain.1D
      timing_tool.py -fsl_timing_files ${stim_path}/${sub_formatted}_${task}_neutral_${num}.txt -write_timing ${fmri}_stim_neutral.1D
    fi

    ## Combine both task session scans if the first is already processed
    if [[ ${fmri} == ${fphysout}_2 ]] || [[ ${fmri} == ${fsocialout}_2 ]]; then

      # Get number of volumes
      volumes=$(3dinfo -nv ${fmri_task}_1_mni.nii.gz)

      # Concatenate fmri data from each session into one nifti file
      if [ ! -f ${fmri_task}_mni.nii.gz ]; then
        3dTcat ${fmri_task}_1_mni.nii.gz ${fmri_task}_2_mni.nii.gz -tr ${TR} -prefix ${fmri_task}_mni.nii.gz
        check=$(3dinfo -nv ${fmri_task}_mni.nii.gz)
        if [ ${check} != "$((${volumes} * 2))" ]; then
          echo 'ERROR IN CONCATENATION'
        fi
      fi
      if [ ! -f ${fmri_task}_mni_scaled.nii.gz ]; then
        3dTcat ${fmri_task}_1_mni_scaled.nii.gz ${fmri_task}_2_mni_scaled.nii.gz -tr ${TR} -prefix ${fmri_task}_mni_scaled.nii.gz
        check=$(3dinfo -nv ${fmri_task}_mni_scaled.nii.gz)
        if [ ${check} != "$((${volumes} * 2))" ]; then
          echo 'ERROR IN CONCATENATION'
        fi
      fi

      # concat file - add to -concat in 3dDeconvolve
      if [ ! -f ${fmri_task}_runs.1D ]; then
        echo '0 '${volumes} > ${fmri_task}_runs.1D
      fi

      # Find stimulus duration time from original fsl-like stimulus file
      t=$(timing_tool.py -fsl_timing_files ${stim_path}/${sub_formatted}_${task}_stimtimes_${num}.txt -show_duration_stats)
      t=$(echo ${t} | cut -d' ' -f6)
      stype='BLOCK('${t}'1)'

      # Concatenate stim timing files from each session into one file - local type
      if [ ! -f ${fmri_task}_stim_pain_local.1D ]; then
        timing_tool.py -timing ${fmri_task}_1_stim_pain.1D -add_rows ${fmri_task}_2_stim_pain.1D -sort -write_timing ${fmri_task}_stim_pain_local.1D
      fi
      if [ ! -f ${fmri_task}_stim_neutral_local.1D ]; then
        timing_tool.py -timing ${fmri_task}_1_stim_neutral.1D -add_rows ${fmri_task}_2_stim_neutral.1D -sort -write_timing ${fmri_task}_stim_neutral_local.1D
      fi

      # Concatenate two motion files (if demean, do this before concatenation)
      if [ ! -f ${fmri_task}_motion.1D ]; then
        cat ${fmri_task}_1_motion.1D ${fmri_task}_2_motion.1D > ${fmri_task}_motion.1D
      fi
      if [ ! -f ${fmri_task}_motion_demean.1D ]; then
        cat ${fmri_task}_1_motion_demean.1D ${fmri_task}_2_motion_demean.1D > ${fmri_task}_motion_demean.1D
      fi
      if [ ! -f ${fmri_task}_motion_derive.1D ]; then
        cat ${fmri_task}_1_motion_derive.1D ${fmri_task}_2_motion_derive.1D > ${fmri_task}_motion_derive.1D
      fi
      # compute de-meaned motion parameters (for use in regression)
      if [ ! -f ${fmri_task}_motion_demean_2.1D ]; then
        1d_tool.py -infile ${fmri_task}_motion.1D -set_nruns 2 -demean -write ${fmri_task}_motion_demean_2.1D
      fi
      # compute motion parameter derivatives (for use in regression)
      if [ ! -f ${fmri_task}_motion_derive_2.1D ]; then
        1d_tool.py -infile ${fmri_task}_motion.1D -set_nruns 2 -derivative -demean -write ${fmri_task}_motion_derive_2.1D
      fi
      # # # create censor file motion_${subj}_censor.1D, for censoring motion
      # # if [ ! -f ${fmri}_motion_censor.1D ]; then
      # #   1d_tool.py -infile ${fmri}_motion.1D -set_nruns 1 -show_censor_count -censor_prev_TR -censor_motion 0.2 ${fmri}_motion
      # # fi
      # # # combine multiple censor files - calculate outliers into outcount file
      # # if [ ! -f ${fmri}_censor_combined_2.1D ]; then
      # #   1deval -a ${fmri}_motion_censor.1D -b ${fmri}_outcount_censor.1D -expr "a*b" > ${fmri}_censor_combined_2.1D
      # # fi
      # # split_into_pad_runs for multi-runs

      ## Masks
      # Concatenate brain masks - compute intersection
      if [ ! -f ${fmri_task}_mni_brain_mask_final.nii.gz ]; then
        3dmask_tool -input ${fmri_task}_1_mni_brain_mask_final.nii.gz ${fmri_task}_2_mni_brain_mask_final.nii.gz -prefix ${fmri_task}_mni_brain_mask_final.nii.gz -frac 1.0 -fill_holes
      fi

      # Segmentation masks - fast or freesurfer
      if [[ ${choose_seg} == 'fast' ]]; then
        if [ ! -f ${fmri_task}_csf_mni_mask.nii.gz ]; then
          3dcalc -a ${fmri_task}_1_csf_mni_mask.nii.gz -b ${fmri_task}_2_mni_brain_mask_final.nii.gz -expr 'a * b' -prefix ${fmri_task}_csf_mni_mask.nii.gz
        fi
        if [ ! -f ${fmri_task}_wm_mni_mask.nii.gz ]; then
          3dcalc -a ${fmri_task}_1_wm_mni_mask.nii.gz -b ${fmri_task}_2_mni_brain_mask_final.nii.gz -expr 'a * b' -prefix ${fmri_task}_wm_mni_mask.nii.gz
        fi
        if [ ! -f ${fmri_task}_gm_mni_mask.nii.gz ]; then
          3dcalc -a ${fmri_task}_1_gm_mni_mask.nii.gz -b ${fmri_task}_2_mni_brain_mask_final.nii.gz -expr 'a * b' -prefix ${fmri_task}_gm_mni_mask.nii.gz
        fi
        # ventricle extraction
        if [ ! -f ${fmri_task}_vent_mni_inter.nii.gz ]; then
          3dcopy ${fmri_task}_1_vent_mni_inter.nii.gz ${fmri_task}_vent_mni_inter.nii.gz
        fi
        #extract timecourses
        if [ ! -f ${fmri_task}_vent_tc.1D ]; then
          3dmaskave -q -mask ${fmri_task}_vent_mni_inter.nii.gz ${fmri_task}_mni_scaled.nii.gz > ${fmri_task}_vent_tc.1D
        fi
        if [ ! -f ${fmri_task}_wm_tc.1D ]; then
          3dmaskave -q -mask ${fmri_task}_wm_mni_mask.nii.gz ${fmri_task}_mni_scaled.nii.gz > ${fmri_task}_wm_tc.1D
        fi
      else
        if [ ! -f ${fmri_task}_vent_fs_mni_frac.nii.gz ]; then
          3dcopy ${fmri_task}_1_vent_fs_mni_frac.nii.gz ${fmri_task}_vent_fs_mni_frac.nii.gz
        fi
        if [ ! -f ${fmri_task}_wmseg_fs_mni_frac.nii.gz ]; then
          3dcopy ${fmri_task}_1_wmseg_fs_mni_frac.nii.gz ${fmri_task}_wmseg_fs_mni_frac.nii.gz
        fi
        #extract timecourses
        if [ ! -f ${fmri_task}_vent_tc.1D ]; then
          3dmaskave -q -mask ${fmri_task}_vent_fs_mni_frac.nii.gz ${fmri_task}_mni_scaled.nii.gz > ${fmri_task}_vent_tc.1D
        fi
        if [ ! -f ${fmri_task}_wm_tc.1D ]; then
          3dmaskave -q -mask ${fmri_task}_wmseg_fs_mni_frac.nii.gz ${fmri_task}_mni_scaled.nii.gz > ${fmri_task}_wm_tc.1D
        fi
      fi

      ## 3dDeconvolve - use stim times, motion (demean & derivative), wm & ventricle masks
      if [ ! -f ${fmri_task}_x1D.xmat.1D ]; then
        3dDeconvolve -polort A -num_stimts 16 \
          -stim_times 1 ${fmri_task}_stim_pain_local.1D ${stype} -stim_label 1 'pain' \
          -stim_times 2 ${fmri_task}_stim_neutral_local.1D ${stype} -stim_label 2 'neutral' \
          -gltsym 'SYM: pain -neutral' -glt_label 1 'pain-neutral' \
          -stim_file 3 ${fmri_task}_motion_demean.1D'[0]' -stim_base 3 -stim_label 3 'roll' \
          -stim_file 4 ${fmri_task}_motion_demean.1D'[1]' -stim_base 4 -stim_label 4 'pitch' \
          -stim_file 5 ${fmri_task}_motion_demean.1D'[2]' -stim_base 5 -stim_label 5 'yaw' \
          -stim_file 6 ${fmri_task}_motion_demean.1D'[3]' -stim_base 6 -stim_label 6 'dS' \
          -stim_file 7 ${fmri_task}_motion_demean.1D'[4]' -stim_base 7 -stim_label 7 'dL' \
          -stim_file 8 ${fmri_task}_motion_demean.1D'[5]' -stim_base 8 -stim_label 8 'dP' \
          -stim_file 9 ${fmri_task}_motion_derive.1D'[0]' -stim_base 9 -stim_label 9 'roll_deriv' \
          -stim_file 10 ${fmri_task}_motion_derive.1D'[1]' -stim_base 10 -stim_label 10 'pitch_deriv' \
          -stim_file 11 ${fmri_task}_motion_derive.1D'[2]' -stim_base 11 -stim_label 11 'yaw_deriv' \
          -stim_file 12 ${fmri_task}_motion_derive.1D'[3]' -stim_base 12 -stim_label 12 'dS_deriv' \
          -stim_file 13 ${fmri_task}_motion_derive.1D'[4]' -stim_base 13 -stim_label 13 'dL_deriv' \
          -stim_file 14 ${fmri_task}_motion_derive.1D'[5]' -stim_base 14 -stim_label 14 'dP_deriv' \
          -stim_file 15 ${fmri_task}_vent_tc.1D -stim_base 15 -stim_label 15 'vent' \
          -stim_file 16 ${fmri_task}_wm_tc.1D -stim_base 16 -stim_label 16 'wm' \
          -TR_1D ${TR}s -bucket ${fmri_task}_bucket -cbucket ${fmri_task}_cbucket \
          -x1D ${fmri_task}_x1D.xmat.1D -input ${fmri_task}_mni_scaled.nii.gz \
          -concat ${fmri_task}_runs.1D -local_times -fout -tout -xjpeg ${fmri_task}_X.jpg
      fi

      # 3dDeconvolve - DONT CONCATENATE BUT PUT TWO FILES FOR EACH

      # Display any large pairwise correlations from the X-matrix
      if [ ! -f ${fmri_task}_cormat_warn.txt ]; then
        1d_tool.py -show_cormat_warnings -infile ${fmri_task}_x1D.xmat.1D | tee ${fmri_task}_cormat_warn.txt
      fi

      # can use -gltsym -Rglt or -Oglt or Obuck (-dsort anaticor -dsort_nods)
      if [ ! -f ${fmri_task}_reml.nii.gz ]; then
        3dREMLfit -matrix ${fmri_task}_x1D.xmat.1D -input ${fmri_task}_mni_scaled.nii.gz -Rbeta ${fmri_task}_cbucket_reml -Rbuck ${fmri_task}_bucket_reml -Rvar ${fmri_task}_bucket_reml_var -Rerrts ${fmri_task}_reml.nii.gz -fout -tout -verb
      fi

      # Create ideal files for stim types
      if [ ! -f ${fmri_task}_ideal_pain.1D ]; then
        1dcat ${fmri_task}_x1D.xmat.1D'[8]' > ${fmri_task}_ideal_pain.1D
      fi
      if [ ! -f ${fmri_task}_ideal_neutral.1D ]; then
        1dcat ${fmri_task}_x1D.xmat.1D'[9]' > ${fmri_task}_ideal_neutral.1D
      fi

      # Create stat files
      if [ ! -f ${fmri_task}_pain_betas.nii.gz ]; then
        3dbucket -prefix ${fmri_task}_pain_betas.nii.gz ${fmri_task}_bucket+orig.'[1]'
        3dbucket -prefix ${fmri_task}_pain_tstat.nii.gz ${fmri_task}_bucket+orig.'[2]'
        3dbucket -prefix ${fmri_task}_neutral_betas.nii.gz ${fmri_task}_bucket+orig.'[4]'
        3dbucket -prefix ${fmri_task}_neutral_tstat.nii.gz ${fmri_task}_bucket+orig.'[5]'
        3dbucket -prefix ${fmri_task}_pain-neutral_betas.nii.gz ${fmri_task}_bucket+orig.'[7]'
        3dbucket -prefix ${fmri_task}_pain-neutral_tstat.nii.gz ${fmri_task}_bucket+orig.'[8]'
      fi

      # REML stats
      if [ ! -f ${fmri_task}_pain_betas_reml.nii.gz ]; then
        3dbucket -prefix ${fmri_task}_pain_betas_reml.nii.gz ${fmri_task}_bucket_reml+orig.'[1]'
        3dbucket -prefix ${fmri_task}_pain_tstat_reml.nii.gz ${fmri_task}_bucket_reml+orig.'[2]'
        3dbucket -prefix ${fmri_task}_neutral_betas_reml.nii.gz ${fmri_task}_bucket_reml+orig.'[4]'
        3dbucket -prefix ${fmri_task}_neutral_tstat_reml.nii.gz ${fmri_task}_bucket_reml+orig.'[5]'
        3dbucket -prefix ${fmri_task}_pain-neutral_betas_reml.nii.gz ${fmri_task}_bucket_reml+orig.'[7]'
        3dbucket -prefix ${fmri_task}_pain-neutral_tstat_reml.nii.gz ${fmri_task}_bucket_reml+orig.'[8]'
      fi

      # 3dSynthesize takes out regressors of no interest, 3dcalc to subtract from fitted dataset
      if [ ! -f ${fmri_task}_synth.nii.gz ]; then
        3dSynthesize -cbucket ${fmri_task}_cbucket+orig. -matrix ${fmri_task}_x1D.xmat.1D -select 0 1 2 3 4 5 6 7 10 11 12 13 14 15 16 17 18 19 20 21 22 23 -prefix ${fmri_task}_synth.nii.gz
        3dcalc -a ${fmri_task}_mni.nii.gz -b ${fmri_task}_synth.nii.gz -expr 'a-b' -prefix ${fmri_task}_clean.nii.gz
        3dSynthesize -cbucket ${fmri_task}_cbucket+orig. -matrix ${fmri_task}_x1D.xmat.1D -select 8 -prefix ${fmri_task}_pain.nii.gz
        3dSynthesize -cbucket ${fmri_task}_cbucket+orig. -matrix ${fmri_task}_x1D.xmat.1D -select 9 -prefix ${fmri_task}_neutral.nii.gz
      fi

      ## Temporal filtering
      if [ ! -f ${fmri_task}_blur_filtered.nii.gz ]; then
        3dTproject -bandpass 0.01 0.1 -input ${fmri_task}_clean.nii.gz -concat ${fmri_task}_runs.1D -prefix ${fmri_task}_blur_filtered.nii.gz -verb
      fi

      ## Estimate blur from error time series
      if [ ! -f ${fmri_task}_blur.1D ]; then
        3dFWHMx -acf ${fmri_task}_fwhmx_acf.1D -ShowMeClassicFWHM -input ${fmri_task}_blur_filtered.nii.gz -out ${fmri_task}_fwhmx_out.1D >> ${fmri_task}_blur.1D
      fi

    fi

  fi

  if [ -f ${fmri}_gcor.1D ]; then
    @compute_gcor -verb 0 -input ${fmri}_blur_filtered.nii.gz -corr_vol ${fmri}_FTcorr.nii.gz > ${fmri}_gcor.1D
  fi

  # scrubbing - FD and DVARS, used for seed-based correlation analysis
  if [ -f ${fmri}_motion_outliers ]; then
    fsl_motion_outliers -i ${fmri}_mni_brain.nii.gz -o ${fmri}_motion_outliers --nomoco
  fi

  ## Delete unecessary files
  # delete skull-stripped fieldmaps before combining them
  if [ -f ${fmapout}_brain_mag_b.nii.gz ]; then
    rm ${fmapout}_brain_mag_b.nii.gz ${fmapout}_brain_mag_s.nii.gz ${fmapout}_brain_mag_b_mask.nii.gz ${fmapout}_brain_mag_s_mask.nii.gz
    rm ${fmapout}_brain_mag_s_skull.nii.gz ${fmapout}_brain_ero_zpad.nii.gz ${fmapout}_brain_mag_mask_zpad.nii.gz
  fi

  # delete mask files

  # delete files from epi_reg
  if [ -f ${fmri}_epi2anat_init.mat ]; then
    rm ${fmri}_epi2anat_1vol.nii.gz ${fmri}_epi2anat_fast_wmedge.nii.gz ${fmri}_epi2anat_fast_wmseg.nii.gz ${fmri}_epi2anat_fieldmap2str.mat
    rm ${fmri}_epi2anat_fieldmap2str.nii.gz ${fmri}_epi2anat_fieldmap2str_init.mat ${fmri}_epi2anat_fieldmaprads2epi.mat ${fmri}_epi2anat_fieldmaprads2epi.nii.gz
    rm ${fmri}_epi2anat_fieldmaprads2epi_shift.nii.gz ${fmri}_epi2anat_fieldmaprads2str.nii.gz ${fmri}_epi2anat_fieldmaprads2str_dilated.nii.gz ${fmri}_epi2anat_fieldmaprads2str_pad0.nii.gz
    rm ${fmri}_epi2anat_init.mat ${fmri}_epi2anat_inv.mat rm ${fmri}_epi2anat.mat
  fi

  ## Move files back to drive
  # get list of files, find out index of file in list
  list=($(ls -d ${drive}/*/fmri*.nii.gz))
  for i in ${!list[@]}; do
    if [[ ${list[$i]} == ${fold} ]]; then
      c=$i
    fi
  done
  # determine if next file is same subject, if it isn't than move back to drive
  next=$(expr ${c} + 1)
  if [[ ${list[${next}]} != *"/"${sub}"/"* ]]; then
    if [ -d ${data}/${sub}/fmri_processing ]; then
      mv ${data}/${sub}/fmri_processing ${drive}/${sub}
    fi
  fi

done

#time elapsed
duration=$SECONDS
echo "Time elapsed $(( $duration / 3600 )) hours, $(( $duration / 60 )) minutes, $(( $duration % 60 )) seconds"
