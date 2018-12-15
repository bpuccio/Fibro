#!/usr/bin/env bash
#
# Diffusion Preprocessing :
# fielmap correction - FSL fsl_prepare_fieldmap & fugue
# eddy correction - FSL eddy
# tensor fitting - FSL dtifit
# tractography - FSL probtrackx2
# diffusion to anatomical registration - FSL epi_reg
#
# Ben Puccio
# 2018-10-25

# set the timing
SECONDS=0

# set paths
mni_1mm=/usr/local/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz
mni_2mm=/usr/local/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz
mni_3mm=/Users/ben/Documents/cpac_image_resources/MNI_3mm/MNI152_T1_3mm_brain.nii.gz

data=/Users/ben/Documents/_FIBROMIALGIA/nifti
drive=/Volumes/ben_drive/_FIBROMIALGIA/nifti

#dwelltime
echo_spacing=0.000475
eff_echo_spacing=0.00030924672
#eff_echo_spacing=0.00061849345
asym_time=2.46
epi_factor=96

# loop through each subject and preprocess each session containing dmris
for fold in $(ls -d ${drive}/*/diff*.nii.gz); do

  # get subject and project names
  base_path=$(dirname ${fold})
  sub=$(basename ${base_path})

  # move folder from drive to computer
  if [ ! -d ${data}/${sub}/diff_processing ]; then
    mv ${drive}/${sub}/diff_processing ${data}/${sub}
  fi

  ## Get path names from each file
  bvals=$(ls -d ${base_path}/diff*.bval)
  bvecs=$(ls -d ${base_path}/diff*.bvec)

  f=$(ls -d ${base_path}/fieldmap_diff*.nii.gz)
  for pathed in $f; do
    if [[ ${pathed} == *"phase"* ]]; then
      fmapphase=${pathed}
    else
      fmapmag=${pathed}
    fi
  done

  ## Set up output folders
  diff_proc=${data}/${sub}/diff_processing
  t1out=${diff_proc}/t1_diff
  t2out=${diff_proc}/t2_diff
  diffout=${diff_proc}/diff
  fmapout=${diff_proc}/fmap

  if [ ! -f ${diffout}.nii.gz ]; then
    3dcopy ${fold} ${diffout}.nii.gz
    3drefit -deoblique ${diffout}.nii.gz
  fi

  ## Get b0 slice
  if [ ! -f ${diffout}_b0.nii.gz ]; then
    3dcalc -a ${diffout}.nii.gz[0] -expr 'a' -prefix ${diffout}_b0.nii.gz
  fi

  ## Create brain mask
  if [ ! -f ${diffout}_brain.nii.gz ]; then
    3dSkullStrip -input ${diffout}_b0.nii.gz -prefix ${diffout}_brain.nii.gz -init_radius 75 -orig_vol
    3dcalc -a ${diffout}_brain.nii.gz -expr "step(a)" -prefix ${diffout}_brain_mask.nii.gz
    3dmask_tool -input ${diffout}_brain_mask.nii.gz -prefix ${diffout}_smooth_brain_mask.nii.gz -dilate_input -1 1 -fill_holes
  fi

  ## Fieldmap Correction
  # copy to proccessing folder
  if [ ! -f ${fmapout}_mag.nii.gz ]; then
    3dcopy ${fmapmag} ${fmapout}_mag.nii.gz
    3drefit -deoblique ${fmapout}_mag.nii.gz
  fi
  if [ ! -f ${fmapout}_phase.nii.gz ]; then
    3dcopy ${fmapphase} ${fmapout}_phase.nii.gz
    3drefit -deoblique ${fmapout}_phase.nii.gz
  fi
  # Skull-strip fielmap magnitude image using bet twice (-B and -S), combine masks
  if [ ! -f ${fmapout}_brain_mag.nii.gz ]; then
    bet ${fmapout}_mag.nii.gz ${fmapout}_brain_mag_b.nii.gz -B -m
    bet ${fmapout}_mag.nii.gz ${fmapout}_brain_mag_s.nii.gz -S -m
    3dcalc -a ${fmapout}_brain_mag_b_mask.nii.gz -b ${fmapout}_brain_mag_s_mask.nii.gz -expr 'a*b' -prefix ${fmapout}_brain_mag_mask.nii.gz
    3dcalc -a ${fmapout}_mag.nii.gz -b ${fmapout}_brain_mag_mask.nii.gz -expr 'a*b' -prefix ${fmapout}_brain_mag.nii.gz
  fi
  # Register skull-stripped fieldmap to skull-stripped b0 for initial registration, then run flirt w/ -nosearch
  if [ ! -f ${fmapout}_fmap2diff_init.nii.gz ]; then
    flirt -v -noresample -dof 6 -in ${fmapout}_brain_mag.nii.gz -ref ${diffout}_brain.nii.gz -omat ${fmapout}_fmap2diff_init.mat -out ${fmapout}_fmap2diff_init.nii.gz
  fi
  if [ ! -f ${fmapout}_fmap2diff.nii.gz ]; then
    flirt -v -noresample -dof 6 -init ${fmapout}_fmap2diff_init.mat -in ${fmapout}_mag.nii.gz -ref ${diffout}_b0.nii.gz -omat ${fmapout}_fmap2diff.mat -out ${fmapout}_fmap2diff.nii.gz -nosearch
  fi
  ## Apply transform to phase and skullstripped
  if [ ! -f ${fmapout}_phase_reg.nii.gz ]; then
    flirt -v -noresample -applyxfm -init ${fmapout}_fmap2diff.mat -in ${fmapout}_phase.nii.gz -out ${fmapout}_phase_reg.nii.gz -ref ${diffout}_b0.nii.gz
  fi
  if [ ! -f ${fmapout}_brain_reg.nii.gz ]; then
    flirt -v -noresample -applyxfm -init ${fmapout}_fmap2diff.mat -in ${fmapout}_brain_mag.nii.gz -out ${fmapout}_brain_reg.nii.gz -ref ${diffout}_brain.nii.gz
  fi
  # Make brain mask, add zero pad to top of mask (for erosion), erode -2, remove zero pad, apply mask to fieldmap to skullstrip
  if [ ! -f ${fmapout}_brain.nii.gz ]; then
    3dcalc -a ${fmapout}_brain_reg.nii.gz -expr "step(a)" -prefix ${fmapout}_brain_mask.nii.gz
    3dzeropad -S 1 -prefix ${fmapout}_brain_mask_zpad.nii.gz ${fmapout}_brain_mask.nii.gz
    3dmask_tool -input ${fmapout}_brain_mask_zpad.nii.gz -prefix ${fmapout}_brain_ero_zpad.nii.gz -dilate_input -2 -fill_holes
    3dzeropad -S -1 -prefix ${fmapout}_brain_ero.nii.gz ${fmapout}_brain_ero_zpad.nii.gz
    3dcalc -a ${fmapout}_brain_ero.nii.gz -b ${fmapout}_fmap2diff.nii.gz -expr "a*b" -prefix ${fmapout}_brain.nii.gz
  fi
  # prepare fieldmap
  if [ ! -f ${fmapout}.nii.gz ]; then
    fsl_prepare_fieldmap SIEMENS ${fmapout}_phase_reg.nii.gz ${fmapout}_brain.nii.gz ${fmapout}.nii.gz ${asym_time}
    if [ ! -f ${fmapout}.nii.gz ]; then
      3dmask_tool -input ${fmapout}_brain_ero.nii.gz -prefix ${fmapout}_brain_ero2.nii.gz -dilate_input -2 -fill_holes
      3dcalc -a ${fmapout}_brain_ero2.nii.gz -b ${fmapout}_fmap2diff.nii.gz -expr "a*b" -prefix ${fmapout}_brainn.nii.gz
      fsl_prepare_fieldmap SIEMENS ${fmapout}_phase_reg.nii.gz ${fmapout}_brainn.nii.gz ${fmapout}.nii.gz ${asym_time}
    fi
  fi
  # FUGUE - fieldmap correction
  if [ ! -f ${diffout}_fugue.nii.gz ]; then
    fugue -i ${diffout}.nii.gz --dwell=${eff_echo_spacing} --loadfmap=${fmapout}.nii.gz --unwarpdir=y- -u ${diffout}_fugue.nii.gz -v
  fi

  ## Skull-strip diffusion (fieldmap corrected) using bet
  if [ ! -f ${diffout}_fugue_brain.nii.gz  ]; then
    bet ${diffout}_fugue.nii.gz ${diffout}_fugue_brain.nii.gz -f 0.2 -m
  fi

  ## Eddy current correction
  # Create acqparams.txt and index.txt for eddy
  if [ ! -f ${diffout}_acqparams.txt ]; then
    var=$(echo "${echo_spacing} * (${epi_factor} - 1)" | bc)
    printf "0 -1 0 ${var}\n0 1 0 ${var}" > ${diffout}_acqparams.txt
  fi
  if [ ! -f ${diffout}_index.txt ]; then
    volumes=$(3dinfo -nv ${diffout}.nii.gz)
    indx=""
    for ((i=1; i<=${volumes}; i+=1)); do indx="$indx 1"; done
    echo $indx > ${diffout}_index.txt
  fi
  ## Run eddy correction (fsl)
  if [ ! -f ${diffout}_eddy.nii.gz ]; then
    eddy --imain=${diffout}_fugue.nii.gz --mask=${diffout}_fugue_brain_mask.nii.gz --index=${diffout}_index.txt --acqp=${diffout}_acqparams.txt --bvecs=${bvecs} --bvals=${bvals}  --repol --out=${diffout}_eddy -v
  fi

  ## Skull-strip diffusion (eddy corrected) using bet (SHOULD SKULLSTRIP b=100?)
  if [ ! -f ${diffout}_eddy_brain.nii.gz ]; then
    bet ${diffout}_eddy.nii.gz ${diffout}_eddy_brain.nii.gz -f 0.2 -m
  fi
  if [ ! -f ${diffout}_eddy_brain_mask_fill.nii.gz ]; then
    3dmask_tool -input ${diffout}_eddy_brain_mask.nii.gz -prefix ${diffout}_eddy_brain_mask_fill.nii.gz -dilate_input 1 -2 -fill_holes
  fi

  # 3dAutomask 

  # # Register t2 to diff, use brain masks from t1 skullstrip
  # if [ ! -f ${diffout}_eddy_b0.nii.gz ]; then
  #   3dcalc -a ${diffout}_eddy.nii.gz[0] -expr 'a' -prefix ${diffout}_eddy_b0.nii.gz
  # fi
  # if [ ! -f ${t2out}_brain.nii.gz ]; then
  #   3dcopy ${drive}/${sub}/fmri_processing/t2_fmri_brain.nii.gz ${t2out}_brain.nii.gz
  #   3dcopy ${drive}/${sub}/fmri_processing/t2_fmri_1Warp.nii.gz ${t2out}_1Warp.nii.gz
  #   cp ${drive}/${sub}/fmri_processing/t2_fmri_0GenericAffine.mat ${t2out}_0GenericAffine.mat
  #   3dcopy ${drive}/${sub}/fmri_processing/t1_fmri_brain_mask.nii.gz ${t1out}_brain_mask_diff.nii.gz
  # else
  #   if [ ! -f ${t1out}_brain_mask_diff.nii.gz ]; then
  #     3dcopy ${t1out}_brain_mask.nii.gz ${t1out}_brain_mask_diff.nii.gz
  #   fi
  # fi
  # if [ ! -f ${t2out}_eddyreg_1Warp.nii.gz ]; then
  #   antsRegistrationSyNQuick.sh -d 3 -f ${diffout}_eddy_b0.nii.gz -m ${t2out}_brain.nii.gz -o ${t2out}_eddyreg_
  # fi
  # if [ ! -f ${diffout}_eddy_brain_maskk.nii.gz ]; then
  #   antsApplyTransforms -d 3 -i ${t1out}_brain_mask_diff.nii.gz -o ${diffout}_eddy_brain_maskk.nii.gz -r ${diffout}_eddy_b0.nii.gz -t ${t2out}_1Warp.nii.gz -t [${t2out}_0GenericAffine.mat,1] -t ${t2out}_eddyreg_1Warp.nii.gz -t ${t2out}_eddyreg_0GenericAffine.mat -v 1 -n NearestNeighbor
  # fi
  # if [ ! -f ${diffout}_eddy_brain_maskk_fill.nii.gz ]; then
  #   3dmask_tool -input ${diffout}_eddy_brain_maskk.nii.gz -prefix ${diffout}_eddy_brain_maskk_fill.nii.gz -dilate_input 1 -2 -fill_holes
  # fi

  ## Tensor fitting
  if [ ! -f ${diffout}_tensor_FA.nii.gz ]; then
    dtifit -k ${diffout}_eddy.nii.gz -o ${diffout}_tensor -m ${diffout}_eddy_brain_mask_fill.nii.gz -r ${diffout}_eddy.eddy_rotated_bvecs -b ${bvals} --sse --kurt -V
  fi
  # copy FA map to folder for tbss processing, MAKE SURE TO HAVE FOLDER IN DATA PATH
  if [ ! -f ${data}/mytbss/${sub}_FA.nii.gz ]; then
    3dcopy ${diffout}_tensor_FA.nii.gz ${data}/mytbss/${sub}.nii.gz
  fi

  ## Registration of DMRI
  # vecreg (FSL)???
  # use t2 from fmri session if there is no t2 from diffusion session
  # if [ ! -f ${t2out}_unifize.nii.gz ]; then
  #   t2out=${drive}/${sub}/fmri_processing/t2_fmri
  #   t1out=${drive}/${sub}/fmri_processing/t1_fmri
  # fi
  # # use ants to register FA map to t2 anat
  # if [ ! -f ${diffout}_1Warp.nii.gz ]; then
  #   antsRegistrationSyNQuick.sh -d 3 -f ${t2out}_brain.nii.gz -m ${diffout}_tensor_FA.nii.gz -o ${diffout}_
  # fi
  # # apply mni transform of t2 to FA map
  # if [ ! -f ${diffout}_tensor_FA_mni.nii.gz ]; then
  #   antsApplyTransforms -d 3 -i ${diffout}_tensor_FA.nii.gz -o ${diffout}_tensor_FA_mni.nii.gz -r ${mni_3mm} -t ${diffout}_1Warp.nii.gz -t ${diffout}_0GenericAffine.mat -t ${t1out}_1Warp.nii.gz -t ${t1out}_0GenericAffine.mat -v 1
  # fi

  # # Estimate Diff Parameters for Probabilistic Tracking - bedpostx
  # if [ ! -f ${diffout}_bedpost.nii.gz ]; then
  #   3dcopy ${diffout}_motion.nii.gz ${diff_proc}/data.nii.gz
  #   3dcopy ${diffout}_mask.nii.gz ${diff_proc}/nodif_brain_mask.nii.gz
  #   cp ${diffout}_eddy.eddy_rotated_bvecs ${diff_proc}/bvecs
  #   cp ${bvals} ${diff_proc}/bvals
  #   bedpostx ${diff_proc} -V
  # fi

  # Q-ball
  # qboot	-k data	-m mask	-r bvecs -b bvals

  # # Probabilistic Tracking
  # #CHOOSE SEED VOXEL (INTERNAL CAPSULE)
  # if [ ! -f ${diffout}_bedpost.nii.gz ]; then
  #   probtrackx2 -s <basename> -m ${t1out}_brain_mask_mni.nii.gz -x <seedfile> -o <output> --targetmasks=<textfile> -V
  # fi

  # delete unecessary files

  ## Move files back to drive
  if [ -d ${data}/${sub}/diff_processing ]; then
    mv ${data}/${sub}/diff_processing ${drive}/${sub}
  fi

done


#time elapsed
duration=$SECONDS
echo "Time elapsed $(( $duration / 3600 )) hours, $(( $duration / 60 )) minutes, $(( $duration % 60 )) seconds"
