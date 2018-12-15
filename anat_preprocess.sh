#!/usr/bin/env bash
#
# Anatomical Preprocessing :
# bias correction - ANTs N4BiasFieldCorrection
# intensity normalization - AFNI 3dUnifize
# brain extraction - BEaST (minctoolkit)
# registration - ANTs antsRegistrationSyN.sh
# segmentation - FSL FAST
#
# Ben Puccio
# 2018-12-14

# set the timing
SECONDS=0

# set paths
mni_1mm=/usr/local/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz
mni_2mm=/usr/local/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz
mni_1mm_noss=/usr/local/fsl/data/standard/MNI152_T1_1mm.nii.gz

drive=/Volumes/ben_drive/_FIBROMIALGIA/niftibeast
data=/Users/ben/Documents/_FIBROMIALGIA/niftibeast
if [ ! -d ${data} ]; then
  mkdir ${data}
fi

# loop through each subject and preprocess each
for fold in $(ls -d ${drive}/*/t1_mprage*.nii.gz); do

  ## Get path names from each file
  base_path=$(dirname ${fold})
  sub=$(basename ${base_path})
  if [ ! -d ${data}/${sub} ]; then
    mkdir ${data}/${sub}
  fi

  fmri_drive=${drive}/${sub}/fmri_processing
  diff_drive=${drive}/${sub}/diff_processing
  fmri_proc=${data}/${sub}/fmri_processing
  diff_proc=${data}/${sub}/diff_processing

  ## Use t1 name to set up output folders, find t2 files, set up output filenames
  if [[ ${fold} == *"fmri"* ]]; then

    # Set up fmri processing directory
    if [ ! -d ${fmri_drive} ]; then
      if [ ! -d ${fmri_proc} ]; then
        mkdir ${fmri_proc}
      fi
    else
      mv ${fmri_drive} ${data}/${sub}
    fi

    # Copy t1 and t2 to fmri processing directory
    t1out=${fmri_proc}/t1_fmri
    if [ ! -f ${t1out}.nii.gz ]; then
      3dcopy ${fold} ${t1out}.nii.gz
    fi
    if [[ $(ls -d ${base_path}/*) == *"t2_spc_fmri"* ]]; then
      t2=$(ls -d ${drive}/${sub}/t2_spc_fmri*.nii.gz)
      t2out=${fmri_proc}/t2_fmri
      if [ ! -f ${t2out}.nii.gz ]; then
        3dcopy ${t2} ${t2out}.nii.gz
      fi
    else
      t2=na
    fi

  elif [[ ${fold} == *"diff"* ]]; then

    # Set up diff processing directory
    if [ ! -d ${diff_drive} ]; then
      if [ ! -d ${diff_proc} ]; then
        mkdir ${diff_proc}
      fi
    else
      mv ${diff_drive} ${data}/${sub}
    fi

    # Copy t1 and t2 to diff processing directory
    t1out=${diff_proc}/t1_diff
    if [ ! -f ${t1out}.nii.gz ]; then
      3dcopy ${fold} ${t1out}.nii.gz
    fi
    if [[ $(ls -d ${base_path}/*) == *"t2_spc_diff"* ]]; then
      t2=$(ls -d ${drive}/${sub}/t2_spc_diff*.nii.gz)
      t2out=${diff_proc}/t2_diff
      if [ ! -f ${t2out}.nii.gz ]; then
        3dcopy ${t2} ${t2out}.nii.gz
      fi
    else
      t2=na
    fi

  fi

  ## Deoblique, N4 bias correction, intensity normalization
  if [ ! -f ${t1out}_unifize.nii.gz ]; then

    ## Deoblique and orient
    3drefit -deoblique ${t1out}.nii.gz
    #3dresample -orient RPI -prefix ${t1out}.nii -inset ${t1out}.nii.gz

    ## Bias Field Correction
    N4BiasFieldCorrection -d 3 -i ${t1out}.nii.gz -o ${t1out}_bc.nii.gz -v

    #3dUnifize: for better 3dskullstrip (bad results at pons) - GM???
    3dUnifize -input ${t1out}_bc.nii.gz -prefix ${t1out}_unifize.nii.gz
  fi

  # ## 3dSkullStrip
  # if [ ! -f ${t1out}_brain.nii.gz ]; then
  #   3dSkullStrip -input ${t1out}_unifize.nii.gz -prefix ${t1out}_brain.nii.gz -init_radius 75
  # fi
  # # create mask
  # if [ ! -f ${t1out}_brain_mask.nii.gz ]; then
  #   3dcalc -a ${t1out}_brain.nii.gz -expr "step(a)" -prefix ${t1out}_brain_mask.nii.gz
  # fi
  # if [ ! -f ${t1out}_brain_mask_fill.nii.gz ]; then
  #   3dmask_tool -prefix ${t1out}_brain_mask_fill.nii.gz -input ${t1out}_brain_mask.nii.gz -fill_holes
  # fi

  ## BEaST
  if [ ! -f ${t1out}_init_1Warp.nii.gz ]; then
   antsRegistrationSyNQuick.sh -d 3 -n 2 -f ${mni_1mm_noss} -m ${t1out}_unifize.nii.gz -o ${t1out}_init_
  fi
  if [ ! -f ${t1out}_mni_init_brain.nii.gz ]; then
   antsApplyTransforms -d 3 -i ${t1out}_unifize.nii.gz -o ${t1out}_mni_init.nii.gz -r ${mni_1mm_noss} -t ${t1out}_init_1Warp.nii.gz -t ${t1out}_init_0GenericAffine.mat -v 1
   /Users/ben/Fibro/beastskullstrip_fibro.sh ${t1out}_mni_init.nii.gz
  fi
  if [ ! -f ${t1out}_brain.nii.gz ]; then
   antsApplyTransforms -d 3 -i ${t1out}_mni_init_brain.nii.gz -o ${t1out}_brain.nii.gz -r ${t1out}_unifize.nii.gz -t [ ${t1out}_init_0GenericAffine.mat, 1] -t ${t1out}_init_1InverseWarp.nii.gz -v 1
   antsApplyTransforms -d 3 -i ${t1out}_mni_init_brain_mask.nii.gz -o ${t1out}_brain_mask.nii.gz -r ${t1out}_unifize.nii.gz -t [ ${t1out}_init_0GenericAffine.mat, 1] -t ${t1out}_init_1InverseWarp.nii.gz -n NearestNeighbor -v 1
  fi
  if [ ! -f ${t1out}_brain_mask_fill.nii.gz ]; then
    3dmask_tool -prefix ${t1out}_brain_mask_fill.nii.gz -input ${t1out}_brain_mask.nii.gz -fill_holes
  fi
  # 3dAutomask, multiply by mask to remove outliers from beast mask
  # 3dAutomask -prefix ${t1out}_automask.nii.gz ${t1out}_unifize.nii.gz
  #
  if [ ! -f ${t1out}_1Warp.nii.gz ]; then
    antsRegistrationSyNQuick.sh -d 3 -n 2 -i ${t1out}_init_1Warp.nii.gz -i ${t1out}_init_0GenericAffine.mat -t so -f ${mni_1mm} -m ${t1out}_brain.nii.gz -o ${t1out}_
  fi
  # Apply transforms
  if [ ! -f ${t1out}_brain_mni.nii.gz ]; then
    antsApplyTransforms -d 3 -i ${t1out}_unifize.nii.gz -o ${t1out}_mni.nii.gz -r ${mni_1mm_noss} -t ${t1out}_2Warp.nii.gz -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
    antsApplyTransforms -d 3 -i ${t1out}_brain.nii.gz -o ${t1out}_brain_mni.nii.gz -r ${mni_1mm} -t ${t1out}_2Warp.nii.gz -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
    antsApplyTransforms -d 3 -i ${t1out}_brain_mask_fill.nii.gz -o ${t1out}_brain_mask_mni.nii.gz -r ${mni_1mm} -t ${t1out}_2Warp.nii.gz -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -n NearestNeighbor -v 1
  fi
  if [ ! -f ${t1out}_brain_mask_mni_fill.nii.gz ]; then
    3dmask_tool -prefix ${t1out}_brain_mask_mni_fill.nii.gz -input ${t1out}_brain_mask_mni.nii.gz -fill_holes
  fi

  # ## Normalization - ANTs
  # if [ ! -f ${t1out}_1Warp.nii.gz ]; then
  #   antsRegistrationSyNQuick.sh -d 3 -n 2 -f ${mni_1mm} -m ${t1out}_brain.nii.gz -o ${t1out}_
  # fi

  # # Apply transforms
  # if [ ! -f ${t1out}_brain_mni.nii.gz ]; then
  #   antsApplyTransforms -d 3 -i ${t1out}_unifize.nii.gz -o ${t1out}_mni.nii.gz -r ${mni_1mm_noss} -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
  #   antsApplyTransforms -d 3 -i ${t1out}_brain.nii.gz -o ${t1out}_brain_mni.nii.gz -r ${mni_1mm} -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
  #   antsApplyTransforms -d 3 -i ${t1out}_brain_mask.nii.gz -o ${t1out}_brain_mask_mni.nii.gz -r ${mni_1mm} -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -n NearestNeighbor -v 1
  # fi
  # if [ ! -f ${t1out}_brain_mask_mni_fill.nii.gz ]; then
  #   3dmask_tool -prefix ${t1out}_brain_mask_mni_fill.nii.gz -input ${t1out}_brain_mask_mni.nii.gz -fill_holes
  # fi

  ## T2 preprocessing
  if [[ ! ${t2} == "na" ]]; then

    if [ ! -f ${t2out}_unifize.nii.gz ]; then
      3drefit -deoblique ${t2out}.nii.gz
      #3dresample -orient RPI -prefix ${t2out}.nii -inset ${t2out}_anat.nii
      3dUnifize -input ${t2out}.nii.gz -prefix ${t2out}_unifize.nii.gz
    fi
    # t2 to t1 space
    if [ ! -f ${t2out}_1Warp.nii.gz ]; then
      antsRegistrationSyNQuick.sh -d 3 -n 2 -f ${t1out}_unifize.nii.gz -m ${t2out}_unifize.nii.gz -o ${t2out}_
    fi
    if [ ! -f ${t2out}_align.nii.gz ]; then
      antsApplyTransforms -d 3 -i ${t2out}_unifize.nii.gz -o ${t2out}_align.nii.gz -r ${t1out}_unifize.nii.gz -t ${t2out}_1Warp.nii.gz -t ${t2out}_0GenericAffine.mat -v 1
    fi
    # apply t1 skullstrip to t2
    if [ ! -f ${t2out}_brain.nii.gz ]; then
      3dcalc -a ${t1out}_brain_mask.nii.gz -b ${t2out}_align.nii.gz -expr "a*b" -prefix ${t2out}_brain.nii.gz
    fi
    # t2 to mni space
    if [ ! -f ${t2out}_mni.nii.gz ]; then
      antsApplyTransforms -d 3 -i ${t2out}_align.nii.gz -o ${t2out}_mni.nii.gz -r ${mni_1mm_noss} -t ${t1out}_2Warp.nii.gz -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
    fi
    if [ ! -f ${t2out}_brain_mni.nii.gz ]; then
      3dcalc -a ${t1out}_brain_mask_mni_fill.nii.gz -b ${t2out}_mni.nii.gz -expr "a*b" -prefix ${t2out}_brain_mni.nii.gz
    fi
  fi

  ## Segmentation
  # csf mask
  if [ ! -f ${t1out}_fast_pve_0.nii.gz ]; then
    fast -v -o ${t1out}_fast ${t1out}_brain.nii.gz
  fi
  if [ ! -f ${t1out}_csfmask_mni.nii.gz ]; then
    antsApplyTransforms -d 3 -i ${t1out}_fast_pve_0.nii.gz -o ${t1out}_csf_mni.nii.gz -r ${mni_1mm} -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
    3dcalc -a ${t1out}_csf_mni.nii.gz -expr 'step(a-.8)' -prefix ${t1out}_csfmask_mni.nii.gz -datum short
  fi
  # grey matter mask
  if [ ! -f ${t1out}_gm_mni.nii.gz ]; then
    antsApplyTransforms -d 3 -i ${t1out}_fast_pve_1.nii.gz -o ${t1out}_gm_mni.nii.gz -r ${mni_1mm} -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
    3dcalc -a ${t1out}_gm_mni.nii.gz -expr 'step(a-.8)' -prefix ${t1out}_gm_mni_short.nii.gz -datum short
  fi
  # white matter mask
  if [ ! -f ${t1out}_wmask_mni.nii.gz ]; then
    fslmaths ${t1out}_fast_pve_2.nii.gz -thr 0.5 -bin ${t1out}_wmseg.nii.gz -odt input
    antsApplyTransforms -d 3 -i ${t1out}_fast_pve_2.nii.gz -o ${t1out}_wm_mni.nii.gz -r ${mni_1mm} -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
    3dcalc -a ${t1out}_wm_mni.nii.gz -expr 'step(a-.8)' -prefix ${t1out}_wmask_mni.nii.gz -datum short
  fi

  # Print skullstripping pictures
  if [ ! -f ${t1out}_skullstrip.axi.png ]; then
    @chauffeur_afni -ulay ${t1out}_unifize.nii.gz -olay ${t1out}_brain_mask_fill.nii.gz -prefix ${t1out}_skullstrip \
      -opacity 4 -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
  fi

  ## Delete unecessary files

  echo 'done preprocessing subject '${sub}' '

  ## Move files back to drive
  if [ -d ${fmri_proc} ]; then
    mv ${fmri_proc} ${drive}/${sub}
  fi
  if [ -d ${diff_proc} ]; then
    mv ${diff_proc} ${drive}/${sub}
  fi

done

#time elapsed
duration=$SECONDS
echo "Time elapsed $(( $duration / 3600 )) hours, $(( $duration / 60 )) minutes, $(( $duration % 60 )) seconds"
