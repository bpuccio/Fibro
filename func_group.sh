#!/usr/bin/env bash
#
# Functional Group Analysis :
# 3dttest++ -
# 3dMEMA -
#
#
#
# Ben Puccio
# 2018-12-15

data=/Volumes/ben_drive/_FIBROMIALGIA/niftibeast
output=/Users/ben/Documents/_FIBROMIALGIA/niftibeast
group=${output}/fmri_group/fmri_group
if [ ! -d ${output}/fmri_group ]; then
  mkdir ${output}/fmri_group
fi

t1_brain_list=$(ls -d ${data}/*/fmri_processing/t1_fmri_brain_mni.nii.gz)
t1_mask_list=$(ls -d ${data}/*/fmri_processing/t1_fmri_brain_mask_mni.nii.gz)
fmri_gm_mask_list=$(ls -d ${data}/*/fmri_processing/fmri_*i*_gm_mni_mask.nii.gz)

if [ ! -f ${group}_brain.nii.gz ]; then
  3dMean -prefix ${group}_brain.nii.gz ${t1_brain_list}
fi
if [ ! -f ${group}_brain_mask.nii.gz ]; then
  3dmask_tool -input ${t1_mask_list} -prefix ${group}_brain_mask.nii.gz -frac 1.0
fi
if [ ! -f ${group}_gm_mask.nii.gz ]; then
  3dmask_tool -input ${fmri_gm_mask_list} -prefix ${group}_gm_mask.nii.gz -frac 0.5
fi

for task in physical social; do

  mask_list=$(ls -d ${data}/*/fmri_processing/fmri_${task}_mni_brain_mask_final.nii.gz)
  gm_mask_list=$(ls -d ${data}/*/fmri_processing/fmri_${task}_gm_mni_mask.nii.gz)

  if [ ! -f ${group}_${task}_mask.nii.gz ]; then
    3dmask_tool -input ${mask_list} -prefix ${group}_${task}_mask.nii.gz -frac 1.0
  fi
  if [ ! -f ${group}_${task}_gm_mask.nii.gz ]; then
    3dmask_tool -input ${gm_mask_list} -prefix ${group}_${task}_gm_mask.nii.gz -frac 0.5
  fi
  # if [ ! -f ${group}_${task}_gm_mask_mode.nii.gz ]; then
  #   3dcalc -a ${gm_mask_list} -expr 'lmode(a)' -prefix ${group}_${task}_gm_mask_mode .nii.gz
  # fi

  #
  if [ ! -f ${group}_${task}_p-n_ttest.nii.gz ]; then
    3dttest++ -prefix ${group}_${task}_p-n_ttest.nii.gz -mask ${group}_${task}_gm_mask.nii.gz -setA ${task}_pain-neutral \
        1 ${data}/01/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        2 ${data}/02/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        3 ${data}/03/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        4 ${data}/04/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        5 ${data}/05/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        6 ${data}/06/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        7 ${data}/07/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        8 ${data}/08/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        9 ${data}/09/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        10 ${data}/10/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        11 ${data}/11/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        12 ${data}/12/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        13 ${data}/13/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        14 ${data}/14/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        15 ${data}/15/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        16 ${data}/16/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        17 ${data}/17/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        18 ${data}/18/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        19 ${data}/19/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        20 ${data}/20/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        21 ${data}/21/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        22 ${data}/22/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        23 ${data}/23/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        24 ${data}/24/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz \
        -toz
        # -Clustsim
        # -covariates ${group}_pain_score.1D
        # -center DIFF
  fi

  #2 side t test
  if [ ! -f ${group}_${task}_p-n_ttest_2.nii.gz ]; then
    3dttest++ -prefix ${group}_${task}_p-n_ttest_2.nii.gz -mask ${group}_${task}_gm_mask.nii.gz -setA ${task}_pain \
        1 ${data}/01/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        2 ${data}/02/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        3 ${data}/03/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        4 ${data}/04/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        5 ${data}/05/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        6 ${data}/06/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        7 ${data}/07/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        8 ${data}/08/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        9 ${data}/09/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        10 ${data}/10/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        11 ${data}/11/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        12 ${data}/12/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        13 ${data}/13/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        14 ${data}/14/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        15 ${data}/15/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        16 ${data}/16/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        17 ${data}/17/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        18 ${data}/18/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        19 ${data}/19/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        20 ${data}/20/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        21 ${data}/21/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        22 ${data}/22/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        23 ${data}/23/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        24 ${data}/24/fmri_processing/fmri_${task}_pain_betas.nii.gz \
        -setB ${task}_neutral \
        1 ${data}/01/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        2 ${data}/02/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        3 ${data}/03/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        4 ${data}/04/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        5 ${data}/05/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        6 ${data}/06/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        7 ${data}/07/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        8 ${data}/08/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        9 ${data}/09/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        10 ${data}/10/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        11 ${data}/11/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        12 ${data}/12/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        13 ${data}/13/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        14 ${data}/14/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        15 ${data}/15/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        16 ${data}/16/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        17 ${data}/17/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        18 ${data}/18/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        19 ${data}/19/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        20 ${data}/20/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        21 ${data}/21/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        22 ${data}/22/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        23 ${data}/23/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        24 ${data}/24/fmri_processing/fmri_${task}_neutral_betas.nii.gz \
        -toz
        # -covariates ${group}_pain_score.1D
        # -center DIFF
  fi

  ## Mixed effects - 3dMEMA (requires 3dREMLfit)
  if [ ! -f ${group}_${task}_p-n_MEMA.nii.gz ]; then
    3dMEMA -prefix ${group}_${task}_p-n_MEMA.nii.gz -jobs 1 -mask ${group}_${task}_gm_mask.nii.gz \
        -set ${task}_pain-neutral_MEMA \
            1 ${data}/01/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/01/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            2 ${data}/02/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/02/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            3 ${data}/03/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/03/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            4 ${data}/04/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/04/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            5 ${data}/05/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/05/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            6 ${data}/06/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/06/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            7 ${data}/07/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/07/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            8 ${data}/08/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/08/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            9 ${data}/09/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/09/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            10 ${data}/10/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/10/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            11 ${data}/11/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/11/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            12 ${data}/12/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/12/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            13 ${data}/13/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/13/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            14 ${data}/14/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/14/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            15 ${data}/15/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/15/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            16 ${data}/16/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/16/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            17 ${data}/17/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/17/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            18 ${data}/18/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/18/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            19 ${data}/19/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/19/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            20 ${data}/20/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/20/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            21 ${data}/21/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/21/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            22 ${data}/22/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/22/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            23 ${data}/23/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/23/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz \
            24 ${data}/24/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz ${data}/24/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz
        # -missing_data pain neutral
  fi

  ## Mixed effects - 3dMEMA (requires 3dREMLfit)
  if [ ! -f ${group}_${task}_p-n_MEMA_2.nii.gz ]; then
    3dMEMA -prefix ${group}_${task}_p-n_MEMA_2.nii.gz -jobs 1 -groups ${task}_neutral_MEMA ${task}_pain_MEMA -mask ${group}_${task}_gm_mask.nii.gz \
      -set ${task}_neutral_MEMA \
          1 ${data}/01/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/01/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          2 ${data}/02/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/02/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          3 ${data}/03/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/03/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          4 ${data}/04/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/04/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          5 ${data}/05/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/05/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          6 ${data}/06/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/06/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          7 ${data}/07/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/07/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          8 ${data}/08/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/08/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          9 ${data}/09/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/09/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          10 ${data}/10/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/10/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          11 ${data}/11/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/11/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          12 ${data}/12/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/12/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          13 ${data}/13/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/13/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          14 ${data}/14/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/14/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          15 ${data}/15/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/15/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          16 ${data}/16/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/16/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          17 ${data}/17/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/17/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          18 ${data}/18/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/18/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          19 ${data}/19/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/19/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          20 ${data}/20/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/20/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          21 ${data}/21/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/21/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          22 ${data}/22/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/22/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          23 ${data}/23/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/23/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
          24 ${data}/24/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz ${data}/24/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz \
      -set ${task}_pain_MEMA \
          1 ${data}/01/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/01/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          2 ${data}/02/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/02/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          3 ${data}/03/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/03/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          4 ${data}/04/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/04/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          5 ${data}/05/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/05/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          6 ${data}/06/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/06/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          7 ${data}/07/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/07/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          8 ${data}/08/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/08/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          9 ${data}/09/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/09/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          10 ${data}/10/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/10/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          11 ${data}/11/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/11/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          12 ${data}/12/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/12/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          13 ${data}/13/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/13/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          14 ${data}/14/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/14/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          15 ${data}/15/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/15/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          16 ${data}/16/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/16/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          17 ${data}/17/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/17/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          18 ${data}/18/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/18/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          19 ${data}/19/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/19/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          20 ${data}/20/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/20/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          21 ${data}/21/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/21/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          22 ${data}/22/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/22/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          23 ${data}/23/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/23/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz \
          24 ${data}/24/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz ${data}/24/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz
        # -missing_data pain neutral
  fi

  ## Cluster simulations
  if [ ! -f ${group}_${task}_blur.1D ]; then
    touch ${group}_${task}_blur.1D
    for g in $(ls -d ${data}/*/fmri_processing/fmri_${task}_blur.1D); do
      acf=$(cat ${g} | awk 'FNR == 2 {print}')
      acf_array=( $acf )
      echo ${acf_array[@]} >> ${group}_${task}_blur.1D
    done
  fi
  if [ ! -f ${group}_${task}_blur_1.1D ]; then
    1d_tool.py -infile ${group}_${task}_blur.1D -select_cols '0' -write ${group}_${task}_blur_1.1D
  fi
  if [ ! -f ${group}_${task}_blur_2.1D ]; then
    1d_tool.py -infile ${group}_${task}_blur.1D -select_cols '1' -write ${group}_${task}_blur_2.1D
  fi
  if [ ! -f ${group}_${task}_blur_3.1D ]; then
    1d_tool.py -infile ${group}_${task}_blur.1D -select_cols '2' -write ${group}_${task}_blur_3.1D
  fi
  acf_1=$(1d_tool.py -show_mmms -infile ${group}_${task}_blur_1.1D)
  mean_1=$(echo ${acf_1[@]} | cut -d' ' -f12)
  mean_1=${mean_1/,/}
  acf_2=$(1d_tool.py -show_mmms -infile ${group}_${task}_blur_2.1D)
  mean_2=$(echo ${acf_2[@]} | cut -d' ' -f12)
  mean_2=${mean_2/,/}
  acf_3=$(1d_tool.py -show_mmms -infile ${group}_${task}_blur_3.1D)
  mean_3=$(echo ${acf_3[@]} | cut -d' ' -f12)
  mean_3=${mean_3/,/}
  echo ${task} $mean_1 $mean_2 $mean_3

  ## Run 3dClustSim using blur estimation
  if [ ! -f ${group}_${task}_clustsim.NN3_bisided.1D ]; then
    3dClustSim -both -acf ${mean_1} ${mean_2} ${mean_3} -mask ${group}_${task}_gm_mask.nii.gz -athr 0.05 -pthr 0.001 -cmd ${group}_${task}_clustsim.cmd -prefix ${group}_${task}_clustsim
  fi
  # cmd=$( cat ${fmri_task}_clustsim.cmd )
  # $cmd ${fmri_task}_bucket_orig.
  clustsize=$(1d_tool.py -verb 0 -infile ${group}_${task}_clustsim.NN3_bisided.1D -csim_show_clustsize)

  #
  voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_${task}_p-n_ttest.nii.gz'[1]')
  echo $clustsize $voxstat_thr
  #
  if [ ! -f ${group}_${task}_p-n_ttest_clusterize_report.txt ]; then
    3dClusterize -nosum -inset ${group}_${task}_p-n_ttest.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr 1 -idat 0 -NN 3 -clust_nvox ${clustsize} \
        -pref_map ${group}_${task}_p-n_ttest_clust_map.nii.gz -pref_dat ${group}_${task}_p-n_ttest_clust_dat.nii.gz > ${group}_${task}_p-n_ttest_clusterize_report.txt
  fi
  #whereami coordinates -atlas CA_N27_GW
  #
  if [ ! -f ${group}_${task}_p-n_ttest_clusters.axi.png ]; then
    @chauffeur_afni -ulay ${group}_brain.nii.gz -olay ${group}_${task}_p-n_ttest_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range 3 \
      -opacity 5 -prefix ${group}_${task}_p-n_ttest_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
  fi



  voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_${task}_p-n_ttest_2.nii.gz'[1]')
  echo $clustsize $voxstat_thr
  #
  if [ ! -f ${group}_${task}_p-n_ttest_2_clusterize_report.txt ]; then
    3dClusterize -nosum -inset ${group}_${task}_p-n_ttest_2.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr 1 -idat 0 -NN 3 -clust_nvox ${clustsize} \
        -pref_map ${group}_${task}_p-n_ttest_2_clust_map.nii.gz -pref_dat ${group}_${task}_p-n_ttest_2_clust_dat.nii.gz > ${group}_${task}_p-n_ttest_2_clusterize_report.txt
  fi
  #whereami coordinates -atlas CA_N27_GW
  #
  if [ ! -f ${group}_${task}_p-n_ttest_2_clusters.axi.png ]; then
    @chauffeur_afni -ulay ${group}_brain.nii.gz -olay ${group}_${task}_p-n_ttest_2_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range 3 \
      -opacity 5 -prefix ${group}_${task}_p-n_ttest_2_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
  fi



  voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_${task}_p-n_MEMA.nii.gz'[1]')
  echo $clustsize $voxstat_thr
  #
  if [ ! -f ${group}_${task}_p-n_MEMA_clusterize_report.txt ]; then
    3dClusterize -nosum -inset ${group}_${task}_p-n_MEMA.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr 1 -idat 0 -NN 3 -clust_nvox ${clustsize} \
        -pref_map ${group}_${task}_p-n_MEMA_clust_map.nii.gz -pref_dat ${group}_${task}_p-n_MEMA_clust_dat.nii.gz > ${group}_${task}_p-n_MEMA_clusterize_report.txt
  fi
  #whereami coordinates -atlas CA_N27_GW
  #
  if [ ! -f ${group}_${task}_p-n_MEMA_clusters.axi.png ]; then
    @chauffeur_afni -ulay ${group}_brain.nii.gz -olay ${group}_${task}_p-n_MEMA_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range 3 \
      -opacity 5 -prefix ${group}_${task}_p-n_MEMA_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
  fi


  voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_${task}_p-n_MEMA_2.nii.gz'[5]')
  echo $clustsize $voxstat_thr
  #
  if [ ! -f ${group}_${task}_p-n_MEMA_2_clusterize_report.txt ]; then
    3dClusterize -nosum -inset ${group}_${task}_p-n_MEMA_2.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr 5 -idat 4 -NN 3 -clust_nvox ${clustsize} \
        -pref_map ${group}_${task}_p-n_MEMA_2_clust_map.nii.gz -pref_dat ${group}_${task}_p-n_MEMA_2_clust_dat.nii.gz > ${group}_${task}_p-n_MEMA_2_clusterize_report.txt
  fi
  #whereami coordinates -atlas CA_N27_GW
  #
  if [ ! -f ${group}_${task}_p-n_MEMA_2_clusters.axi.png ]; then
    @chauffeur_afni -ulay ${group}_brain.nii.gz -olay ${group}_${task}_p-n_MEMA_2_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range 3 \
      -opacity 5 -prefix ${group}_${task}_p-n_MEMA_2_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
  fi

  # # Cluster explorer - AFNI
  # ClustExp_HistTable.py -StatDSET ${group}_${task}_pain-neutral_ttest+orig. -prefix ${group}_${task}_pain-neutral_table
  # @ClustExp_CatLab -input ${group}_${task}_pain-neutral_subjects.csv -prefix ${group}_${task}_pain-neutral_subjects.nii.gz
  # ClustExp_StatParse.py -StatDSET ${group}_${task}_pain-neutral_ttest+orig. -MeanBrik 0 -ThreshBrik 1 -SubjDSET ${group}_${task}_pain-neutral_subjects.nii.gz -SubjTable${group}_physical_pain-neutral_table.csv -master ~/abin/MNI152_T1_2009c+tlrc
  # @ClustExp_run_shiny My_ANOVA_ClustExp_shiny

done


## Physical vs social task

#
if [ ! -f ${group}_physical_social_p_ttest.nii.gz ]; then
  3dttest++ -prefix ${group}_physical_social_p_ttest.nii.gz -mask ${group}_physical_gm_mask.nii.gz -setA physical_p \
    1 ${data}/01/fmri_processing/fmri_physical_pain_betas.nii.gz \
    2 ${data}/02/fmri_processing/fmri_physical_pain_betas.nii.gz \
    3 ${data}/03/fmri_processing/fmri_physical_pain_betas.nii.gz \
    4 ${data}/04/fmri_processing/fmri_physical_pain_betas.nii.gz \
    5 ${data}/05/fmri_processing/fmri_physical_pain_betas.nii.gz \
    6 ${data}/06/fmri_processing/fmri_physical_pain_betas.nii.gz \
    7 ${data}/07/fmri_processing/fmri_physical_pain_betas.nii.gz \
    8 ${data}/08/fmri_processing/fmri_physical_pain_betas.nii.gz \
    9 ${data}/09/fmri_processing/fmri_physical_pain_betas.nii.gz \
    10 ${data}/10/fmri_processing/fmri_physical_pain_betas.nii.gz \
    11 ${data}/11/fmri_processing/fmri_physical_pain_betas.nii.gz \
    12 ${data}/12/fmri_processing/fmri_physical_pain_betas.nii.gz \
    13 ${data}/13/fmri_processing/fmri_physical_pain_betas.nii.gz \
    14 ${data}/14/fmri_processing/fmri_physical_pain_betas.nii.gz \
    15 ${data}/15/fmri_processing/fmri_physical_pain_betas.nii.gz \
    16 ${data}/16/fmri_processing/fmri_physical_pain_betas.nii.gz \
    17 ${data}/17/fmri_processing/fmri_physical_pain_betas.nii.gz \
    18 ${data}/18/fmri_processing/fmri_physical_pain_betas.nii.gz \
    19 ${data}/19/fmri_processing/fmri_physical_pain_betas.nii.gz \
    20 ${data}/20/fmri_processing/fmri_physical_pain_betas.nii.gz \
    21 ${data}/21/fmri_processing/fmri_physical_pain_betas.nii.gz \
    22 ${data}/22/fmri_processing/fmri_physical_pain_betas.nii.gz \
    23 ${data}/23/fmri_processing/fmri_physical_pain_betas.nii.gz \
    24 ${data}/24/fmri_processing/fmri_physical_pain_betas.nii.gz \
    -setB social_p \
    1 ${data}/01/fmri_processing/fmri_social_pain_betas.nii.gz \
    2 ${data}/02/fmri_processing/fmri_social_pain_betas.nii.gz \
    3 ${data}/03/fmri_processing/fmri_social_pain_betas.nii.gz \
    4 ${data}/04/fmri_processing/fmri_social_pain_betas.nii.gz \
    5 ${data}/05/fmri_processing/fmri_social_pain_betas.nii.gz \
    6 ${data}/06/fmri_processing/fmri_social_pain_betas.nii.gz \
    7 ${data}/07/fmri_processing/fmri_social_pain_betas.nii.gz \
    8 ${data}/08/fmri_processing/fmri_social_pain_betas.nii.gz \
    9 ${data}/09/fmri_processing/fmri_social_pain_betas.nii.gz \
    10 ${data}/10/fmri_processing/fmri_social_pain_betas.nii.gz \
    11 ${data}/11/fmri_processing/fmri_social_pain_betas.nii.gz \
    12 ${data}/12/fmri_processing/fmri_social_pain_betas.nii.gz \
    13 ${data}/13/fmri_processing/fmri_social_pain_betas.nii.gz \
    14 ${data}/14/fmri_processing/fmri_social_pain_betas.nii.gz \
    15 ${data}/15/fmri_processing/fmri_social_pain_betas.nii.gz \
    16 ${data}/16/fmri_processing/fmri_social_pain_betas.nii.gz \
    17 ${data}/17/fmri_processing/fmri_social_pain_betas.nii.gz \
    18 ${data}/18/fmri_processing/fmri_social_pain_betas.nii.gz \
    19 ${data}/19/fmri_processing/fmri_social_pain_betas.nii.gz \
    20 ${data}/20/fmri_processing/fmri_social_pain_betas.nii.gz \
    21 ${data}/21/fmri_processing/fmri_social_pain_betas.nii.gz \
    22 ${data}/22/fmri_processing/fmri_social_pain_betas.nii.gz \
    23 ${data}/23/fmri_processing/fmri_social_pain_betas.nii.gz \
    24 ${data}/24/fmri_processing/fmri_social_pain_betas.nii.gz \
    -toz
fi

if [ ! -f ${group}_physical_social_p-n_ttest.nii.gz ]; then
  3dttest++ -prefix ${group}_physical_social_p-n_ttest.nii.gz -mask ${group}_physical_gm_mask.nii.gz -setA physical_p-n \
    1 ${data}/01/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    2 ${data}/02/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    3 ${data}/03/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    4 ${data}/04/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    5 ${data}/05/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    6 ${data}/06/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    7 ${data}/07/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    8 ${data}/08/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    9 ${data}/09/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    10 ${data}/10/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    11 ${data}/11/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    12 ${data}/12/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    13 ${data}/13/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    14 ${data}/14/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    15 ${data}/15/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    16 ${data}/16/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    17 ${data}/17/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    18 ${data}/18/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    19 ${data}/19/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    20 ${data}/20/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    21 ${data}/21/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    22 ${data}/22/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    23 ${data}/23/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    24 ${data}/24/fmri_processing/fmri_physical_pain-neutral_betas.nii.gz \
    -setB social_p-n \
    1 ${data}/01/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    2 ${data}/02/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    3 ${data}/03/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    4 ${data}/04/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    5 ${data}/05/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    6 ${data}/06/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    7 ${data}/07/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    8 ${data}/08/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    9 ${data}/09/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    10 ${data}/10/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    11 ${data}/11/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    12 ${data}/12/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    13 ${data}/13/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    14 ${data}/14/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    15 ${data}/15/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    16 ${data}/16/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    17 ${data}/17/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    18 ${data}/18/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    19 ${data}/19/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    20 ${data}/20/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    21 ${data}/21/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    22 ${data}/22/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    23 ${data}/23/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    24 ${data}/24/fmri_processing/fmri_social_pain-neutral_betas.nii.gz \
    -toz
fi

if [ ! -f ${group}_physical_social_p_MEMA.nii.gz ]; then
  3dMEMA -prefix ${group}_physical_social_p_MEMA.nii.gz -jobs 1 -groups social_p physical_p -mask ${group}_physical_gm_mask.nii.gz \
    -set social_p \
        1 ${data}/01/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/01/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        2 ${data}/02/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/02/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        3 ${data}/03/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/03/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        4 ${data}/04/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/04/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        5 ${data}/05/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/05/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        6 ${data}/06/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/06/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        7 ${data}/07/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/07/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        8 ${data}/08/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/08/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        9 ${data}/09/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/09/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        10 ${data}/10/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/10/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        11 ${data}/11/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/11/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        12 ${data}/12/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/12/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        13 ${data}/13/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/13/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        14 ${data}/14/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/14/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        15 ${data}/15/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/15/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        16 ${data}/16/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/16/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        17 ${data}/17/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/17/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        18 ${data}/18/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/18/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        19 ${data}/19/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/19/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        20 ${data}/20/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/20/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        21 ${data}/21/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/21/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        22 ${data}/22/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/22/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        23 ${data}/23/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/23/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
        24 ${data}/24/fmri_processing/fmri_social_pain_betas_reml.nii.gz ${data}/24/fmri_processing/fmri_social_pain_tstat_reml.nii.gz \
    -set physical_p \
        1 ${data}/01/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/01/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        2 ${data}/02/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/02/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        3 ${data}/03/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/03/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        4 ${data}/04/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/04/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        5 ${data}/05/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/05/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        6 ${data}/06/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/06/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        7 ${data}/07/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/07/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        8 ${data}/08/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/08/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        9 ${data}/09/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/09/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        10 ${data}/10/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/10/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        11 ${data}/11/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/11/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        12 ${data}/12/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/12/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        13 ${data}/13/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/13/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        14 ${data}/14/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/14/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        15 ${data}/15/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/15/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        16 ${data}/16/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/16/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        17 ${data}/17/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/17/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        18 ${data}/18/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/18/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        19 ${data}/19/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/19/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        20 ${data}/20/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/20/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        21 ${data}/21/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/21/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        22 ${data}/22/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/22/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        23 ${data}/23/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/23/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz \
        24 ${data}/24/fmri_processing/fmri_physical_pain_betas_reml.nii.gz ${data}/24/fmri_processing/fmri_physical_pain_tstat_reml.nii.gz
fi

if [ ! -f ${group}_physical_social_p-n_MEMA.nii.gz ]; then
  3dMEMA -prefix ${group}_physical_social_p-n_MEMA.nii.gz -jobs 1 -groups social_p-n physical -mask ${group}_physical_gm_mask.nii.gz \
    -set social_p-n \
        1 ${data}/01/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/01/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        2 ${data}/02/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/02/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        3 ${data}/03/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/03/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        4 ${data}/04/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/04/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        5 ${data}/05/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/05/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        6 ${data}/06/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/06/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        7 ${data}/07/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/07/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        8 ${data}/08/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/08/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        9 ${data}/09/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/09/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        10 ${data}/10/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/10/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        11 ${data}/11/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/11/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        12 ${data}/12/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/12/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        13 ${data}/13/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/13/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        14 ${data}/14/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/14/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        15 ${data}/15/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/15/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        16 ${data}/16/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/16/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        17 ${data}/17/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/17/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        18 ${data}/18/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/18/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        19 ${data}/19/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/19/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        20 ${data}/20/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/20/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        21 ${data}/21/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/21/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        22 ${data}/22/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/22/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        23 ${data}/23/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/23/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
        24 ${data}/24/fmri_processing/fmri_social_pain-neutral_betas_reml.nii.gz ${data}/24/fmri_processing/fmri_social_pain-neutral_tstat_reml.nii.gz \
    -set physical_p-n \
        1 ${data}/01/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/01/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        2 ${data}/02/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/02/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        3 ${data}/03/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/03/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        4 ${data}/04/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/04/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        5 ${data}/05/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/05/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        6 ${data}/06/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/06/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        7 ${data}/07/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/07/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        8 ${data}/08/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/08/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        9 ${data}/09/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/09/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        10 ${data}/10/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/10/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        11 ${data}/11/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/11/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        12 ${data}/12/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/12/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        13 ${data}/13/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/13/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        14 ${data}/14/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/14/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        15 ${data}/15/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/15/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        16 ${data}/16/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/16/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        17 ${data}/17/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/17/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        18 ${data}/18/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/18/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        19 ${data}/19/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/19/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        20 ${data}/20/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/20/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        21 ${data}/21/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/21/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        22 ${data}/22/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/22/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        23 ${data}/23/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/23/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz \
        24 ${data}/24/fmri_processing/fmri_physical_pain-neutral_betas_reml.nii.gz ${data}/24/fmri_processing/fmri_physical_pain-neutral_tstat_reml.nii.gz
fi

# Average physical and social blur estimates
if [ ! -f ${group}_blur_1.1D ]; then
  cat ${group}_physical_blur_1.1D ${group}_social_blur_1.1D > ${group}_blur_1.1D
fi
if [ ! -f ${group}_blur_2.1D ]; then
  cat ${group}_physical_blur_2.1D ${group}_social_blur_2.1D > ${group}_blur_2.1D
fi
if [ ! -f ${group}_blur_3.1D ]; then
  cat ${group}_physical_blur_3.1D ${group}_social_blur_3.1D > ${group}_blur_3.1D
fi
acf_1=$(1d_tool.py -show_mmms -infile ${group}_blur_1.1D)
mean_1=$(echo ${acf_1[@]} | cut -d' ' -f12)
mean_1=${mean_1/,/}
acf_2=$(1d_tool.py -show_mmms -infile ${group}_blur_2.1D)
mean_2=$(echo ${acf_2[@]} | cut -d' ' -f12)
mean_2=${mean_2/,/}
acf_3=$(1d_tool.py -show_mmms -infile ${group}_blur_3.1D)
mean_3=$(echo ${acf_3[@]} | cut -d' ' -f12)
mean_3=${mean_3/,/}
echo 'combined task' $mean_1 $mean_2 $mean_3

## Run 3dClustSim using blur estimation
if [ ! -f ${group}_clustsim.NN3_bisided.1D ]; then
  3dClustSim -both -acf ${mean_1} ${mean_2} ${mean_3} -mask ${group}_gm_mask.nii.gz -athr 0.05 -pthr 0.001 -cmd ${group}_clustsim.cmd -prefix ${group}_clustsim
fi
# cmd=$( cat ${fmri_task}_clustsim.cmd )
# $cmd ${fmri_task}_bucket_orig.
clustsize=$(1d_tool.py -verb 0 -infile ${group}_clustsim.NN3_bisided.1D -csim_show_clustsize)


voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_physical_social_p_ttest.nii.gz'[1]')
echo $clustsize $voxstat_thr
#
if [ ! -f ${group}_physical_social_p_ttest_clusterize_report.txt ]; then
  3dClusterize -nosum -inset ${group}_physical_social_p_ttest.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr 1 -idat 0 -NN 3 -clust_nvox ${clustsize} \
      -pref_map ${group}_physical_social_p_ttest_clust_map.nii.gz -pref_dat ${group}_physical_social_p_ttest_clust_dat.nii.gz > ${group}_physical_social_p_ttest_clusterize_report.txt
fi
#whereami coordinates -atlas CA_N27_GW
#
if [ ! -f ${group}_physical_social_p_ttest_clusters.axi.png ]; then
  @chauffeur_afni -ulay ${group}_brain.nii.gz -olay ${group}_physical_social_p_ttest_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range 3 \
    -opacity 5 -prefix ${group}_physical_social_p_ttest_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
fi



voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_physical_social_p-n_ttest.nii.gz'[1]')
echo $clustsize $voxstat_thr
#
if [ ! -f ${group}_physical_social_p-n_ttest_clusterize_report.txt ]; then
  3dClusterize -nosum -inset ${group}_physical_social_p-n_ttest.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr 1 -idat 0 -NN 3 -clust_nvox ${clustsize} \
      -pref_map ${group}_physical_social_p-n_ttest_clust_map.nii.gz -pref_dat ${group}_physical_social_p-n_ttest_clust_dat.nii.gz > ${group}_physical_social_p-n_ttest_clusterize_report.txt
fi
#whereami coordinates -atlas CA_N27_GW
#
if [ ! -f ${group}_physical_social_p-n_ttest_clusters.axi.png ]; then
  @chauffeur_afni -ulay ${group}_brain.nii.gz -olay ${group}_physical_social_p-n_ttest_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range 3 \
    -opacity 5 -prefix ${group}_physical_social_p-n_ttest_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
fi


voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_physical_social_p-n_MEMA.nii.gz'[5]')
echo $clustsize $voxstat_thr
#
if [ ! -f ${group}_physical_social_p-n_MEMA_clusterize_report.txt ]; then
  3dClusterize -nosum -inset ${group}_physical_social_p-n_MEMA.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr 5 -idat 4 -NN 3 -clust_nvox ${clustsize} \
      -pref_map ${group}_physical_social_p-n_MEMA_clust_map.nii.gz -pref_dat ${group}_physical_social_p-n_MEMA_clust_dat.nii.gz > ${group}_physical_social_p-n_MEMA_clusterize_report.txt
fi
#whereami coordinates -atlas CA_N27_GW
#
if [ ! -f ${group}_physical_social_p-n_MEMA_clusters.axi.png ]; then
  @chauffeur_afni -ulay ${group}_brain.nii.gz -olay ${group}_physical_social_p-n_MEMA_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range 3 \
    -opacity 5 -prefix ${group}_physical_social_p-n_MEMA_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
fi



voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_physical_social_p_MEMA.nii.gz'[5]')
echo $clustsize $voxstat_thr
#
if [ ! -f ${group}_physical_social_p_MEMA_clusterize_report.txt ]; then
  3dClusterize -nosum -inset ${group}_physical_social_p_MEMA.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr 5 -idat 4 -NN 3 -clust_nvox ${clustsize} \
      -pref_map ${group}_physical_social_p_MEMA_clust_map.nii.gz -pref_dat ${group}_physical_social_p_MEMA_clust_dat.nii.gz > ${group}_physical_social_p_MEMA_clusterize_report.txt
fi
#whereami coordinates -atlas CA_N27_GW
#
if [ ! -f ${group}_physical_social_p_MEMA_clusters.axi.png ]; then
  @chauffeur_afni -ulay ${group}_brain.nii.gz -olay ${group}_physical_social_p_MEMA_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range 3 \
    -opacity 5 -prefix ${group}_physical_social_p_MEMA_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
fi

# # Cluster explorer - AFNI
# ClustExp_HistTable.py -StatDSET ${group}_${task}_pain-neutral_ttest+orig. -prefix ${group}_${task}_pain-neutral_table
# @ClustExp_CatLab -input ${group}_${task}_pain-neutral_subjects.csv -prefix ${group}_${task}_pain-neutral_subjects.nii.gz
# ClustExp_StatParse.py -StatDSET ${group}_${task}_pain-neutral_ttest+orig. -MeanBrik 0 -ThreshBrik 1 -SubjDSET ${group}_${task}_pain-neutral_subjects.nii.gz -SubjTable${group}_physical_pain-neutral_table.csv -master ~/abin/MNI152_T1_2009c+tlrc
# @ClustExp_run_shiny My_ANOVA_ClustExp_shiny



# 1 sample t-test against neurosynth pain dataset (http://neurosynth.org/analyses/terms/pain/)
# 3dTcorrelate
#

#Group in Corr - AFNI , resting state, can use -byte for setup to save memory
#3dSetupGroupInCorr -mask ${group}_brain_mask.nii.gz -prefix ${group}_GIC_fibro -short ${data}/*/fmri_processing/fmri_physical_
#3dSetupGroupInCorr -mask ${group}_brain_mask.nii.gz -prefix ${group}_GIC_control -short ${cdata}/*/fmri_processing/fmri_physical_
#3dGroupInCorr -setA ${group}_GIC_fibro.grpincorr.niml -setB BBB.grpincorr.niml ${group}_GIC_control.grpincorr.niml
#GCOR

# 3dTcorr1D, 3dRegAna (calculate corr after w/ 3dcalc)
# 3dTcorrelate
# 3dTcorrMap -input ${fmri}_blur_filter.nii.gz -seed  -mask ${fmri}_gmask_mni_frac.nii.gz
# 3dAutoTcorrelate -polort -1 -mask ${fmri}_gmask_mni_frac.nii.gz -prefix ${fmri}_autocorr ${fmri}_blur_filter.nii.gz -eta2?

## CPAC
# Multivariate Distance Matrix Regression (CWAS) -
# Inter-Subject Correlation (ISC) - from brainiak
#

## ROI analysis
  #AFNI ROIs
  #Spherical ROI (need coordinates - neurosynth?)
    #3dUndump -xyz coordinates -orient RPI -srad 5 -master data -prefix ROI
  #extract betas
    #for sub
    # 3dbucket -aglueto betas+orig $sub_oldset+orig'[7]'
    #done
  #extract values from masks
    #3dmaskave -mask ROI -quiet pain_betas+orig > pain_betas.txt
    #3dmaskave -mask ROI -quiet neutral_betas+orig > neutral_betas.txt
  #compare values (graph, take average & stdev)

  # 3dmaskdump
  # 1dsvd
  #3dROIstats

#Double dissociation


#FSL (MAYBE USE ICA-AROMA https://github.com/maartenmennes/ICA-AROMA)
#group-ICA - multisession temporal concatenation?, need all same volumes?,
#melodic i input_files.txt -o groupICA15 --tr=2 --nobet -a concat -m ${group}_brain_mask.nii.gz --report --Oall -d 15
## Dual regression after group-ICA
#dual_regression groupICA15/melodic_IC 1 design/unpaired_ttest.mat design/unpaired_ttest.con 5000 groupICA15.dr `cat input_files.txt`
#dual_regression PCC_func.nii.gz 0 -1 0 SCA_DR filtered_func_data.nii.gz
##FSLnets
#USE OCTAVE - fslnets.m

#fslmerge -t zmaps
#fslmaths merged.nii.gz -abs -Tmin -bin mean_mask.nii.gz
#flameo --copefile = merged.nii.gz --covsplitfile = anova_with_meanFD.grp --designfile = anova_with_meanFD.mat --fcontrastsfile = anova_with_meanFD.fts --ld=stats --maskfile = mean_mask.nii.gz --runmode=ols --tcontrastsfile = anova_with_meanFD.con
#easythresh <raw_zstat> <brain_mask> <z_thresh> <prob_thresh> <background_image> <output_root> [--mm]


##Correlation map analysis
#3dMatch -inset CORREL_DATA+orig -refset STANDARD_RSNs+orig -mask mask+orig -in_min 0.4 -ref_min 2.3 -prefix MATCHED -only_dice_thr

#fat_mvm_prep.py -p study -c allsubj.csv -m './GROUP/*/*_000.grid'
#fat_mvm_scripter.py -f VARLIST.txt -l study_MVMprep.log -t study_MVMtbl.txt -p study
#3dMVM
#fat_mat_sel.py -r 3  -m './GROUP/*/*_000.grid'



## ROIs - set up regions of interest
# Freesurfer ROIs - copy from folder
# if [ ! -f ${t1out}_parce_fs_mni.nii.gz ]; then
#   3dcopy ${fs}/aparc.a2009s+aseg_mni.nii.gz ${t1out}_parce_fs_mni.nii.gz
# fi
# # Posterior cingulate cortex (PCC)
# if [ ! -f ${t1out}_pcc.nii.gz ]; then
#   3dcalc -a ${t1out}_parce_fs_mni.nii.gz -datum byte -prefix ${t1out}_pcc.nii.gz -expr 'amongst(a,11109,11110,12109,12110)'
# fi
# # internal capsule?
# # anterior cingulate cortex?
# # periaqueductal grey
# # Raphe nuclei
# #
# 3dresample -master data -inset ROI -prefix ROI_resample
# 3dfractionize
# 3dROIMaker -echo_edu -inset SOME_ICA_NETS_in_DWI+orig -thresh 3.0 -volthr 130 -inflate 2 -wm_skel DTI/DT_FA+orig. -skel_thr 0.2 -skel_stop -mask mask_DWI+orig -prefix ./ROI_ICMAP -nifti
