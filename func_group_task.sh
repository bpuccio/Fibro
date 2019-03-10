#!/usr/bin/env bash
#
# Functional Group Analysis : task
# 3dttest++ -
# 3dMEMA -
#
#
#
# Ben Puccio
# 2018-12-15

patients=niftibeast
controls=nifti_controls
drive=/Volumes/ben_drive/_FIBROMIALGIA

for class in ${patients} ${controls}; do

  data=/Volumes/ben_drive/_FIBROMIALGIA/${class}
  output=/Users/ben/Documents/_FIBROMIALGIA/${class}
  group=${output}/fmri_group/fmri_group
  if [ ! -d ${output}/fmri_group ]; then
    mkdir ${output}/fmri_group
  fi

  t1_brain_list=$(ls -d ${data}/*/fmri_processing/t1_fmri_brain_mni.nii.gz)
  t1_mask_list=$(ls -d ${data}/*/fmri_processing/t1_fmri_brain_mask_mni.nii.gz)
  fmri_gm_mask_list=$(ls -d ${data}/*/fmri_processing/fmri_*i*_gm_mni_mask.nii.gz)

  # Group average anatomical T1
  if [ ! -f ${group}_brain.nii.gz ]; then
    3dMean -prefix ${group}_brain.nii.gz ${t1_brain_list}
  fi
  # Trim image for pictures later
  if [ ! -f ${group}_brain_abox.nii.gz ]; then
    3dAutobox -prefix ${group}_brain_abox.nii.gz -npad 3 -input ${group}_brain.nii.gz
  fi
  # Group average anatomical brain mask
  if [ ! -f ${group}_brain_mask.nii.gz ]; then
    3dmask_tool -input ${t1_mask_list} -prefix ${group}_brain_mask.nii.gz -frac 1.0
  fi
  # Group average anatomical gray matter mask
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

    # Make list of beta and tstat names of each subject for ttest/MEMA commands
    deconvolve_pn_betas=()
    deconvolve_p_betas=()
    deconvolve_n_betas=()
    reml_pn=()
    reml_p=()
    reml_n=()
    for numb in $(ls -d ${data}/*) ; do
      if [ -d ${numb} ]; then
        num=$(basename ${numb})
        # deconvolve_p_betas_brick+=${data}/${num}/fmri_processing/fmri_${task}_bucket+orig.[1]' '
        # deconvolve_n_betas_brick+=${data}/${num}/fmri_processing/fmri_${task}_bucket+orig.[4]' '
        deconvolve_pn_betas+=${data}/${num}/fmri_processing/fmri_${task}_pain-neutral_betas.nii.gz' '
        deconvolve_p_betas+=${data}/${num}/fmri_processing/fmri_${task}_pain_betas.nii.gz' '
        deconvolve_n_betas+=${data}/${num}/fmri_processing/fmri_${task}_neutral_betas.nii.gz' '
        reml_pn+=${num}' '${data}/${num}/fmri_processing/fmri_${task}_pain-neutral_betas_reml.nii.gz' '${data}/${num}/fmri_processing/fmri_${task}_pain-neutral_tstat_reml.nii.gz' '
        reml_p+=${num}' '${data}/${num}/fmri_processing/fmri_${task}_pain_betas_reml.nii.gz' '${data}/${num}/fmri_processing/fmri_${task}_pain_tstat_reml.nii.gz' '
        reml_n+=${num}' '${data}/${num}/fmri_processing/fmri_${task}_neutral_betas_reml.nii.gz' '${data}/${num}/fmri_processing/fmri_${task}_neutral_tstat_reml.nii.gz' '
      fi
    done
    if [[ ${task} == physical ]]; then
      physical_deconvolve_pn_betas=${deconvolve_pn_betas}
      physical_deconvolve_p_betas=${deconvolve_p_betas}
      physical_deconvolve_n_betas=${deconvolve_n_betas}
      physical_reml_pn=${reml_pn}
      physical_reml_p=${reml_p}
      physical_reml_n=${reml_n}
    else
      social_deconvolve_pn_betas=${deconvolve_pn_betas}
      social_deconvolve_p_betas=${deconvolve_p_betas}
      social_deconvolve_n_betas=${deconvolve_n_betas}
      social_reml_pn=${reml_pn}
      social_reml_p=${reml_p}
      social_reml_n=${reml_n}
    fi
    if [[ ${class} == ${patients} ]]; then
      pts_physical_deconvolve_pn_betas=${physical_deconvolve_pn_betas}
      pts_physical_deconvolve_p_betas=${physical_deconvolve_p_betas}
      pts_physical_deconvolve_n_betas=${physical_deconvolve_n_betas}
      pts_physical_reml_pn=${physical_reml_pn}
      pts_physical_reml_p=${physical_reml_p}
      pts_physical_reml_n=${physical_reml_n}
      pts_social_deconvolve_pn_betas=${social_deconvolve_pn_betas}
      pts_social_deconvolve_p_betas=${social_deconvolve_p_betas}
      pts_social_deconvolve_n_betas=${social_deconvolve_n_betas}
      pts_social_reml_pn=${social_reml_pn}
      pts_social_reml_p=${social_reml_p}
      pts_social_reml_n=${social_reml_n}
    else
      hc_physical_deconvolve_pn_betas=${physical_deconvolve_pn_betas}
      hc_physical_deconvolve_p_betas=${physical_deconvolve_p_betas}
      hc_physical_deconvolve_n_betas=${physical_deconvolve_n_betas}
      hc_physical_reml_pn=${physical_reml_pn}
      hc_physical_reml_p=${physical_reml_p}
      hc_physical_reml_n=${physical_reml_n}
      hc_social_deconvolve_pn_betas=${social_deconvolve_pn_betas}
      hc_social_deconvolve_p_betas=${social_deconvolve_p_betas}
      hc_social_deconvolve_n_betas=${social_deconvolve_n_betas}
      hc_social_reml_pn=${social_reml_pn}
      hc_social_reml_p=${social_reml_p}
      hc_social_reml_n=${social_reml_n}
    fi

    tests=()



    # 1 sample t test PAIN
    if [ ! -f ${group}_${task}_p_ttest.nii.gz ]; then
      3dttest++ -prefix ${group}_${task}_p_ttest.nii.gz -mask ${group}_${task}_gm_mask.nii.gz -setA ${deconvolve_p_betas}\
          -toz
          # -Clustsim
          # -covariates ${group}_pain_score.1D
          # -center DIFF
    fi
    tests+='p_ttest '


    # 1 sample t test NEUTRAL
    if [ ! -f ${group}_${task}_n_ttest.nii.gz ]; then
      3dttest++ -prefix ${group}_${task}_n_ttest.nii.gz -mask ${group}_${task}_gm_mask.nii.gz -setA ${deconvolve_n_betas}\
          -toz
          # -Clustsim
          # -covariates ${group}_pain_score.1D
          # -center DIFF
    fi
    tests+='n_ttest '




    # 1 sample t test (of individual level 2 sample t test)
    if [ ! -f ${group}_${task}_p-n_ttest.nii.gz ]; then
      3dttest++ -prefix ${group}_${task}_p-n_ttest.nii.gz -mask ${group}_${task}_gm_mask.nii.gz -setA ${deconvolve_pn_betas}\
          -toz
          # -Clustsim
          # -covariates ${group}_pain_score.1D
          # -center DIFF
    fi
    tests+='p-n_ttest '

    # Group level paired t test (pain - neutral)
    if [ ! -f ${group}_${task}_p-n_ttest_2.nii.gz ]; then
      3dttest++ -prefix ${group}_${task}_p-n_ttest_2.nii.gz -mask ${group}_${task}_gm_mask.nii.gz -setA ${deconvolve_p_betas}\
          -setB ${deconvolve_n_betas}\
          -toz
          # -covariates ${group}_pain_score.1D
          # -center DIFF
    fi
    tests+='p-n_ttest_2 '

    ## Mixed effects - 3dMEMA (requires 3dREMLfit)
    # 1 sample t test (of individual level 2 sample t test)
    if [ ! -f ${group}_${task}_p-n_MEMA.nii.gz ]; then
      3dMEMA -prefix ${group}_${task}_p-n_MEMA.nii.gz -jobs 1 -mask ${group}_${task}_gm_mask.nii.gz \
          -set ${task}_pain-neutral_MEMA \
              ${reml_pn[@]}
          # -missing_data pain neutral
    fi
    tests+='p-n_MEMA '
    echo ${reml_pn[@]}

    ## Mixed effects - 3dMEMA (requires 3dREMLfit)
    # Group level paired t test (pain - neutral)
    if [ ! -f ${group}_${task}_p-n_MEMA_2.nii.gz ]; then
      3dMEMA -prefix ${group}_${task}_p-n_MEMA_2.nii.gz -jobs 1 -groups ${task}_neutral_MEMA ${task}_pain_MEMA -mask ${group}_${task}_gm_mask.nii.gz \
        -set ${task}_neutral_MEMA \
            ${reml_n[@]} \
        -set ${task}_pain_MEMA \
            ${reml_p[@]}
          # -missing_data pain neutral
    fi
    tests+='p-n_MEMA_2 '
    echo ${reml_n[@]}
    echo ${reml_p[@]}

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
    echo ${class} ${task} $mean_1 $mean_2 $mean_3

    ## Run 3dClustSim using blur estimation
    if [ ! -f ${group}_${task}_clustsim.NN3_bisided.1D ]; then
      3dClustSim -both -acf ${mean_1} ${mean_2} ${mean_3} -mask ${group}_${task}_gm_mask.nii.gz -athr 0.05 -pthr 0.001 -cmd ${group}_${task}_clustsim.cmd -prefix ${group}_${task}_clustsim
    fi
    # cmd=$( cat ${fmri_task}_clustsim.cmd )
    # $cmd ${fmri_task}_bucket_orig.
    clustsize=$(1d_tool.py -verb 0 -infile ${group}_${task}_clustsim.NN3_bisided.1D -csim_show_clustsize)

    ## Create significant clusters for each ttest, print pictures
    echo ${tests}
    for type in $(echo ${tests}); do

      if [[ ${type} == p-n_MEMA_2 ]]; then
        subbrick='[5]'
        ithr=5
        idat=4
      else
        subbrick='[1]'
        ithr=1
        idat=0
      fi

      # Find vox stats
      voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_${task}_${type}.nii.gz${subbrick})
      echo ${type} ${clustsize} ${voxstat_thr}
      #
      if [ ! -f ${group}_${task}_${type}_clusterize_report.txt ]; then
        3dClusterize -nosum -inset ${group}_${task}_${type}.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr ${ithr} -idat ${idat} -NN 3 -clust_nvox ${clustsize} \
            -pref_map ${group}_${task}_${type}_clust_map.nii.gz -pref_dat ${group}_${task}_${type}_clust_dat.nii.gz > ${group}_${task}_${type}_clusterize_report.txt
      fi
      #whereami coordinates -atlas CA_N27_GW
      #
      if [ ! -f ${group}_${task}_${type}_clusters.axi.png ]; then
        @chauffeur_afni -ulay ${group}_brain_abox.nii.gz -olay ${group}_${task}_${type}_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range_perc_nz 98% \
          -opacity 5 -prefix ${group}_${task}_${type}_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
      fi

      # if [ ! -f ${group}_${task}_${type}_clust_map_step.nii.gz ]; then
      #   3dcalc -a ${group}_${task}_${type}_clust_map.nii.gz -expr "step(a)" -prefix ${group}_${task}_${type}_clust_map_step.nii.gz
      # fi

      # whereami -coord_file  -atlas CA_N27_GW -prefix

    done

    acf_1=()
    acf_2=()
    acf_3=()

  done


  ## Physical vs social task

  tests2=()

  #
  if [ ! -f ${group}_physical_social_p_ttest.nii.gz ]; then
    3dttest++ -prefix ${group}_physical_social_p_ttest.nii.gz -mask ${group}_physical_gm_mask.nii.gz -setA ${physical_deconvolve_p_betas}\
      -setB ${social_deconvolve_p_betas}\
      -toz
  fi
  tests2+='physical_social_p_ttest '
  echo physical ${physical_deconvolve_p_betas}
  echo social ${social_deconvolve_p_betas}

  #
  if [ ! -f ${group}_physical_social_p-n_ttest.nii.gz ]; then
    3dttest++ -prefix ${group}_physical_social_p-n_ttest.nii.gz -mask ${group}_physical_gm_mask.nii.gz -setA ${physical_deconvolve_pn_betas}\
      -setB ${social_deconvolve_pn_betas}\
      -toz
  fi
  tests2+='physical_social_p-n_ttest '
  echo physical ${physical_deconvolve_pn_betas}
  echo social ${social_deconvolve_pn_betas}

  #
  if [ ! -f ${group}_physical_social_p_MEMA.nii.gz ]; then
    3dMEMA -prefix ${group}_physical_social_p_MEMA.nii.gz -jobs 1 -groups social_p physical_p -mask ${group}_physical_gm_mask.nii.gz \
      -set social_p \
          ${social_reml_p[@]} \
      -set physical_p \
          ${physical_reml_p[@]}
  fi
  tests2+='physical_social_p_MEMA '
  echo physical ${physical_reml_p[@]}
  echo social ${social_reml_p[@]}

  #
  if [ ! -f ${group}_physical_social_p-n_MEMA.nii.gz ]; then
    3dMEMA -prefix ${group}_physical_social_p-n_MEMA.nii.gz -jobs 1 -groups social_p-n physical_p-n -mask ${group}_physical_gm_mask.nii.gz \
      -set social_p-n \
          ${social_reml_pn[@]} \
      -set physical_p-n \
          ${physical_reml_pn[@]}
  fi
  tests2+='physical_social_p-n_MEMA '
  echo physical ${physical_reml_pn[@]}
  echo social ${social_reml_pn[@]}

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
  echo 'combined task' ${mean_1} ${mean_2} ${mean_3}

  ## Run 3dClustSim using blur estimation
  if [ ! -f ${group}_clustsim.NN3_bisided.1D ]; then
    3dClustSim -both -acf ${mean_1} ${mean_2} ${mean_3} -mask ${group}_gm_mask.nii.gz -athr 0.05 -pthr 0.001 -cmd ${group}_clustsim.cmd -prefix ${group}_clustsim
  fi
  # cmd=$( cat ${fmri_task}_clustsim.cmd )
  # $cmd ${fmri_task}_bucket_orig.
  clustsize=$(1d_tool.py -verb 0 -infile ${group}_clustsim.NN3_bisided.1D -csim_show_clustsize)

  #
  echo ${tests2}
  for type2 in $(echo ${tests2}); do

    if [[ ${type2} == physical_social_p-n_MEMA ]] || [[ ${type2} == physical_social_p_MEMA ]]; then
      subbrick='[5]'
      ithr=5
      idat=4
    else
      subbrick='[1]'
      ithr=1
      idat=0
    fi

    # Find vox stats
    voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_${type2}.nii.gz${subbrick})
    echo ${type2} ${clustsize} ${voxstat_thr}
    #
    if [ ! -f ${group}_${type2}_clusterize_report.txt ]; then
      3dClusterize -nosum -inset ${group}_${type2}.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr ${ithr} -idat ${idat} -NN 3 -clust_nvox ${clustsize} \
          -pref_map ${group}_${type2}_clust_map.nii.gz -pref_dat ${group}_${type2}_clust_dat.nii.gz > ${group}_${type2}_clusterize_report.txt
    fi
    #whereami coordinates -atlas CA_N27_GW
    #
    if [ ! -f ${group}_${type2}_clusters.axi.png ]; then
      @chauffeur_afni -ulay ${group}_brain_abox.nii.gz -olay ${group}_${type2}_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range_perc_nz 98% \
        -opacity 5 -prefix ${group}_${type2}_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
    fi

    # 3dcalc -a ${group}_${type2}_clust_map.nii.gz

  done

  physical_deconvolve_pn_betas=()
  physical_deconvolve_p_betas=()
  physical_deconvolve_n_betas=()
  physical_reml_pn=()
  physical_reml_p=()
  physical_reml_n=()
  social_deconvolve_pn_betas=()
  social_deconvolve_p_betas=()
  social_deconvolve_n_betas=()
  social_reml_pn=()
  social_reml_p=()
  social_reml_n=()

  acf_1=()
  acf_2=()
  acf_3=()

done




## Patients vs controls


output=/Users/ben/Documents/_FIBROMIALGIA
group=${output}/fmri_group/fmri_group
if [ ! -d ${output}/fmri_group ]; then
  mkdir ${output}/fmri_group
fi

pt_data=/Volumes/ben_drive/_FIBROMIALGIA/${patients}
hc_data=/Volumes/ben_drive/_FIBROMIALGIA/${controls}
pt_t1_brain_list=$(ls -d ${pt_data}/*/fmri_processing/t1_fmri_brain_mni.nii.gz)
pt_t1_mask_list=$(ls -d ${pt_data}/*/fmri_processing/t1_fmri_brain_mask_mni.nii.gz)
pt_fmri_gm_mask_list=$(ls -d ${pt_data}/*/fmri_processing/fmri_*i*_gm_mni_mask.nii.gz)
hc_t1_brain_list=$(ls -d ${hc_data}/*/fmri_processing/t1_fmri_brain_mni.nii.gz)
hc_t1_mask_list=$(ls -d ${hc_data}/*/fmri_processing/t1_fmri_brain_mask_mni.nii.gz)
hc_fmri_gm_mask_list=$(ls -d ${hc_data}/*/fmri_processing/fmri_*i*_gm_mni_mask.nii.gz)

# Group average anatomical T1
if [ ! -f ${group}_brain.nii.gz ]; then
  3dMean -prefix ${group}_brain.nii.gz ${pt_t1_brain_list} ${hc_t1_brain_list}
fi
# Trim image for pictures later
if [ ! -f ${group}_brain_abox.nii.gz ]; then
  3dAutobox -prefix ${group}_brain_abox.nii.gz -npad 3 -input ${group}_brain.nii.gz
fi
# Group average anatomical brain mask
if [ ! -f ${group}_brain_mask.nii.gz ]; then
  3dmask_tool -input ${pt_t1_mask_list} ${hc_t1_mask_list} -prefix ${group}_brain_mask.nii.gz -frac 1.0
fi
# Group average anatomical gray matter mask
if [ ! -f ${group}_gm_mask.nii.gz ]; then
  3dmask_tool -input ${pt_fmri_gm_mask_list} ${pt_fmri_gm_mask_list} -prefix ${group}_gm_mask.nii.gz -frac 0.5
fi

test=()

# Pain physical
if [ ! -f ${group}_pts_hc_physical_p_ttest.nii.gz ]; then
  3dttest++ -prefix ${group}_pts_hc_physical_p_ttest.nii.gz -mask ${group}_gm_mask.nii.gz -setA ${pts_physical_deconvolve_p_betas}\
    -setB ${hc_physical_deconvolve_p_betas}\
    -toz
fi
test+='pts_hc_physical_p_ttest '
echo patients ${pts_physical_deconvolve_p_betas}
echo controls ${hc_physical_deconvolve_p_betas}


# Neutral physical
if [ ! -f ${group}_pts_hc_physical_n_ttest.nii.gz ]; then
  3dttest++ -prefix ${group}_pts_hc_physical_n_ttest.nii.gz -mask ${group}_gm_mask.nii.gz -setA ${pts_physical_deconvolve_n_betas}\
    -setB ${hc_physical_deconvolve_n_betas}\
    -toz
fi
test+='pts_hc_physical_n_ttest '
echo patients ${pts_physical_deconvolve_n_betas}
echo controls ${hc_physical_deconvolve_n_betas}


# Pain social
if [ ! -f ${group}_pts_hc_social_p_ttest.nii.gz ]; then
  3dttest++ -prefix ${group}_pts_hc_social_p_ttest.nii.gz -mask ${group}_gm_mask.nii.gz -setA ${pts_social_deconvolve_p_betas}\
    -setB ${hc_social_deconvolve_p_betas}\
    -toz
fi
test+='pts_hc_social_p_ttest '
echo patients ${pts_social_deconvolve_p_betas}
echo controls ${hc_social_deconvolve_p_betas}


# Neutral social
if [ ! -f ${group}_pts_hc_social_n_ttest.nii.gz ]; then
  3dttest++ -prefix ${group}_pts_social_hc_n_ttest.nii.gz -mask ${group}_gm_mask.nii.gz -setA ${pts_social_deconvolve_n_betas}\
    -setB ${hc_social_deconvolve_n_betas}\
    -toz
fi
test+='pts_hc_social_n_ttest '
echo patients ${pts_social_deconvolve_n_betas}
echo controls ${hc_social_deconvolve_n_betas}


# Pain physical MEMA
if [ ! -f ${group}_pts_hc_physical_p_MEMA.nii.gz ]; then
  3dMEMA -prefix ${group}_pts_hc_physical_p_MEMA.nii.gz -jobs 1 -groups hc_physical_reml_p pts_physical_reml_p -mask ${group}_gm_mask.nii.gz \
    -set hc_physical_reml_p \
        ${hc_physical_reml_p[@]} \
    -set pts_physical_reml_p \
        ${pts_physical_reml_p[@]}
fi
test+='pts_hc_physical_p_MEMA '
echo patients ${pts_physical_reml_p[@]}
echo controls ${hc_physical_reml_p[@]}

# Neutral physical MEMA
if [ ! -f ${group}_pts_hc_physical_n_MEMA.nii.gz ]; then
  3dMEMA -prefix ${group}_pts_hc_physical_n_MEMA.nii.gz -jobs 1 -groups hc_physical_reml_n pts_physical_reml_n -mask ${group}_gm_mask.nii.gz \
    -set hc_physical_reml_n \
        ${hc_physical_reml_n[@]} \
    -set pts_physical_reml_n \
        ${pts_physical_reml_n[@]}
fi
test+='pts_hc_physical_n_MEMA '
echo patients ${pts_physical_reml_n[@]}
echo controls ${hc_physical_reml_n[@]}

# Pain social MEMA
if [ ! -f ${group}_pts_hc_social_p_MEMA.nii.gz ]; then
  3dMEMA -prefix ${group}_pts_hc_social_p_MEMA.nii.gz -jobs 1 -groups hc_social_reml_p pts_social_reml_p -mask ${group}_gm_mask.nii.gz \
    -set hc_social_reml_p \
        ${hc_social_reml_p[@]} \
    -set pts_social_reml_p \
        ${pts_social_reml_p[@]}
fi
test+='pts_hc_social_p_MEMA '
echo patients ${pts_social_reml_p[@]}
echo controls ${hc_social_reml_p[@]}

# Neutral social MEMA
if [ ! -f ${group}_pts_hc_social_n_MEMA.nii.gz ]; then
  3dMEMA -prefix ${group}_pts_hc_social_n_MEMA.nii.gz -jobs 1 -groups hc_social_reml_n pts_social_reml_n -mask ${group}_gm_mask.nii.gz \
    -set hc_social_reml_n \
        ${hc_social_reml_n[@]} \
    -set pts_social_reml_n \
        ${pts_social_reml_n[@]}
fi
test+='pts_hc_social_n_MEMA '
echo patients ${pts_social_reml_n[@]}
echo controls ${hc_social_reml_n[@]}



# Average patient and control blur estimates
if [ ! -f ${group}_blur_1.1D ]; then
  cat ${output}/${patients}/fmri_group/fmri_group_blur_1.1D ${output}/${controls}/fmri_group/fmri_group_blur_1.1D > ${group}_blur_1.1D
fi
if [ ! -f ${group}_blur_2.1D ]; then
  cat ${output}/${patients}/fmri_group/fmri_group_blur_2.1D ${output}/${controls}/fmri_group/fmri_group_blur_2.1D > ${group}_blur_2.1D
fi
if [ ! -f ${group}_blur_3.1D ]; then
  cat ${output}/${patients}/fmri_group/fmri_group_blur_3.1D ${output}/${controls}/fmri_group/fmri_group_blur_3.1D > ${group}_blur_3.1D
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
echo 'combined task' ${mean_1} ${mean_2} ${mean_3}

## Run 3dClustSim using blur estimation
if [ ! -f ${group}_clustsim.NN3_bisided.1D ]; then
  3dClustSim -both -acf ${mean_1} ${mean_2} ${mean_3} -mask ${group}_gm_mask.nii.gz -athr 0.05 -pthr 0.001 -cmd ${group}_clustsim.cmd -prefix ${group}_clustsim
fi
# cmd=$( cat ${fmri_task}_clustsim.cmd )
# $cmd ${fmri_task}_bucket_orig.
clustsize=$(1d_tool.py -verb 0 -infile ${group}_clustsim.NN3_bisided.1D -csim_show_clustsize)

#
echo ${test}
for type in $(echo ${test}); do

  if [[ ${type} == *MEMA* ]]; then
    subbrick='[5]'
    ithr=5
    idat=4
  else
    subbrick='[1]'
    ithr=1
    idat=0
  fi

  # Find vox stats
  voxstat_thr=$(p2dsetstat -quiet -pval 0.001 -bisided -inset ${group}_${type}.nii.gz${subbrick})
  echo ${type} ${clustsize} ${voxstat_thr}
  #
  if [ ! -f ${group}_${type}_clusterize_report.txt ]; then
    3dClusterize -nosum -inset ${group}_${type}.nii.gz -bisided -${voxstat_thr} ${voxstat_thr} -ithr ${ithr} -idat ${idat} -NN 3 -clust_nvox ${clustsize} \
        -pref_map ${group}_${type}_clust_map.nii.gz -pref_dat ${group}_${type}_clust_dat.nii.gz > ${group}_${type}_clusterize_report.txt
  fi
  #whereami coordinates -atlas CA_N27_GW, DD_
  # whereami -atlas CA_PM_18_MNIA -coord_file ${group}_${type}_clusterize_report.txt'[1,2,3]' -tab -rai -dset MNI
  #
  if [ ! -f ${group}_${type}_clusters.axi.png ]; then
    @chauffeur_afni -ulay ${group}_brain_abox.nii.gz -olay ${group}_${type}_clust_dat.nii.gz -cbar Reds_and_Blues_Inv -ulay_range 0% 150% -func_range_perc_nz 98% \
      -opacity 5 -prefix ${group}_${type}_clusters -montx 3 -monty 3 -set_xhairs OFF -label_mode 1 -label_size 3 -do_clean
  fi

done


# 3dMVM



# 3dLME - individual betas for each stimuli



#fat_mvm_prep.py -p study -c allsubj.csv -m './GROUP/*/*_000.grid'
#fat_mvm_scripter.py -f VARLIST.txt -l study_MVMprep.log -t study_MVMtbl.txt -p study
#3dMVM
#fat_mat_sel.py -r 3  -m './GROUP/*/*_000.grid'


# # Cluster explorer - AFNI
# ClustExp_HistTable.py -StatDSET ${group}_${task}_pain-neutral_ttest+orig. -prefix ${group}_${task}_pain-neutral_table
# @ClustExp_CatLab -input ${group}_${task}_pain-neutral_subjects.csv -prefix ${group}_${task}_pain-neutral_subjects.nii.gz
# ClustExp_StatParse.py -StatDSET ${group}_${task}_pain-neutral_ttest+orig. -MeanBrik 0 -ThreshBrik 1 -SubjDSET ${group}_${task}_pain-neutral_subjects.nii.gz -SubjTable${group}_physical_pain-neutral_table.csv -master ~/abin/MNI152_T1_2009c+tlrc
# @ClustExp_run_shiny My_ANOVA_ClustExp_shiny


# 1 sample t-test against neurosynth pain dataset (http://neurosynth.org/analyses/terms/pain/)
# 3dTcorrelate
# 3dMatch

# 3dNetCorr -in_rois /Users/ben/Documents/pain_association-test_z_FDR_0.01.nii.gz



## CPAC
# Multivariate Distance Matrix Regression (CWAS) -
# Inter-Subject Correlation (ISC) - from brainiak
#

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
