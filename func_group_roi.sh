#!/usr/bin/env bash
#
# ROI Group Analysis : task
#
#
#
#
# Ben Puccio
# 2019-03-06


patients=niftibeast
controls=nifti_controls
drive=/Volumes/ben_drive/_FIBROMIALGIA
output=/Users/ben/Documents/_FIBROMIALGIA
group=${output}/roi_group/fmri_group
if [ ! -d ${output}/roi_group ]; then
  mkdir ${output}/roi_group
fi


## ROI analysis
#ROIs - Harvard-Oxford from FSLeyes
for typ in ${patients} ${controls} ; do

  if [[ ${typ} == ${patients} ]]; then
    peeps=patients
  else
    peeps=controls
  fi

  for tsk in physical social ; do

    if [ ! -f ${group}_${peeps}_${tsk}_neutral_betas+orig.HEAD ]; then
      for sb in $(ls -d ${drive}/${typ}/*/fmri_processing/fmri_${tsk}_pain_betas.nii.gz); do
        ppath=$(dirname ${sb})
        pppath=$(dirname ${ppath})
        sbb=$(basename ${pppath})
        3dbucket -aglueto ${group}_${peeps}_${tsk}_pain_betas+orig.HEAD ${drive}/${typ}/${sbb}/fmri_processing/fmri_${tsk}_bucket+orig.'[1]'
        3dbucket -aglueto ${group}_${peeps}_${tsk}_neutral_betas+orig.HEAD ${drive}/${typ}/${sbb}/fmri_processing/fmri_${tsk}_bucket+orig.'[4]'
      done
    fi

    for gg in $(ls -d /Users/ben/Documents/Harvard-Oxford_ROI/*_prob.nii.gz); do
      filename=$(basename ${gg})
      filename=${filename%_prob.nii.gz}
      base_path=$(dirname ${gg})

      # threshold prob maps
      if [ ! -f ${base_path}/${filename}.nii.gz ]; then
        3dcalc -a ${gg} -expr "step(a-50)" -prefix ${base_path}/${filename}.nii.gz
      fi

      if [ ! -f ${base_path}/${filename}_resamp.nii.gz ]; then
        3dresample -master ${group}_${peeps}_${tsk}_pain_betas+orig.HEAD[1] -inset ${base_path}/${filename}.nii.gz -prefix ${base_path}/${filename}_resamp.nii.gz
      fi

      if [ ! -f ${group}_${tsk}_${filename}.txt ]; then
        3dmaskave -q -mask ${base_path}/${filename}_resamp.nii.gz ${group}_${peeps}_${tsk}_pain_betas+orig.HEAD > ${group}_${peeps}_${tsk}_pain_${filename}.txt
        3dmaskave -q -mask ${base_path}/${filename}_resamp.nii.gz ${group}_${peeps}_${tsk}_neutral_betas+orig.HEAD > ${group}_${peeps}_${tsk}_neutral_${filename}.txt
      fi

      #3dROIstats

    done
  done

done


# # rACC
# # dACC
# # preSMA
# # medial prefrontal cortex
# # amygdala
# # dlPFC
# # left anterior insula
# # right anterior insula
# # periaqueductal grey
# # Raphe nuclei

#AFNI ROIs
#Spherical ROI (need coordinates - neurosynth?)
#3dUndump -xyz coordinates -orient RPI -srad 5 -master data -prefix ROI
#extract betas
#extract values from masks
#compare values (graph, take average & stdev)

# 3dmaskdump
# 1dsvd
#3dROIstats

# Double dissociation
