#!/usr/bin/env bash
#
# Move and convert Freesurfer recon-all results to data analysis folder
# freesurfer conversion - AFNI @SUMA_Make_Spec_FS
# calculate wm and ventricle masks - AFNI 3dcalc from afni_proc.py
# scan registration - FSL flirt
# mni registration - ANTS antsApplyTransforms
#
#
# Ben Puccio
# 2018-10-26

TEMPLATE_1mm=/usr/local/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz

nif=/Volumes/ben_drive/_FIBROMIALGIA/nifti
fs=/Volumes/ben_drive/_FIBROMIALGIA/FreeSurfer/output

for loop in $(ls -d ${fs}/*/mri); do
  path=$(dirname ${loop})
  sub=$(basename ${path})

  new=${nif}/${sub}/freesurfer

  if [ ! -d ${path}/SUMA ]; then
    @SUMA_Make_Spec_FS -NIFTI -sid ${sub} -fspath ${path}
  fi

  if [ ! -d ${new} ]; then
    mkdir ${new}
    cp -a ${path}/SUMA/. ${new}/
  fi

  if [ ! -f ${new}/fs_vent.nii ]; then
    3dcalc -a ${new}/aparc+aseg.nii -datum byte -prefix ${new}/fs_vent.nii -expr 'amongst(a,4,43)'
  fi
  if [ ! -f ${new}/fs_wm.nii ]; then
    3dcalc -a ${new}/aparc+aseg.nii -datum byte -prefix ${new}/fs_wm.nii -expr 'amongst(a,2,7,41,46,251,252,253,254,255)'
  fi

  # Linear Registration (TRY NON-LINEAR REGISTRATION)
  if [ ! -f ${new}/fs2afni.nii.gz ]; then
    flirt -v -nosearch -dof 6 -in ${new}/T1.nii -ref ${nif}/${sub}/diff_processing/t1_diff_unifize.nii.gz -omat ${new}/fs2afni.mat -out ${new}/fs2afni.nii.gz
  fi

  for i in $(ls -d ${new}/*.nii); do
    fsreg=${i/.nii/}
    if [ ! -f ${fsreg}_fs2afni.nii.gz ]; then
      flirt -v -noresample -applyxfm -init ${new}/fs2afni.mat -in ${i} -out ${fsreg}_fs2afni.nii.gz -ref ${nif}/${sub}/diff_processing/t1_diff.nii.gz -interp nearestneighbour
    fi
    if [ ! -f ${fsreg}_mni.nii.gz ]; then
      antsApplyTransforms -d 3 -i ${fsreg}_fs2afni.nii.gz -o ${fsreg}_mni.nii.gz -r ${TEMPLATE_1mm} -t ${nif}/${sub}/diff_processing/t1_diff_1Warp.nii.gz -t ${nif}/${sub}/diff_processing/t1_diff_0GenericAffine.mat -v 1 -n NearestNeighbor
    fi
  done

done

#3dresample
#https://github.com/ThomasYeoLab/CBIG/tree/master/stable_projects/registration/Wu2017_RegistrationFusion
#
