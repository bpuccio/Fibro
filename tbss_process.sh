#!/usr/bin/env bash
#
# TBSS analysis
#
#
#
# Ben Puccio
# 2017-12-27

# set the timing
SECONDS=0

#TBSS
cd /Users/ben/Documents/_FIBROMIALGIA/nifti/mytbss/
tbss_1_preproc *.nii.gz
tbss_2_reg -T
tbss_3_postreg -S
tbss_4_prestats 0.2
# cd FA
# cd stats
# design_ttest2 design 23 23 -m
# randomise -i all_FA_skeletonised -o tbss -m mean_FA_skeleton_mask -d design.mat -t design.con -n 500 --T2 -V

# fsl_glm

# tbss_fill tbss_clustere_corrp_tstat1 0.95 mean_FA tbss_clustere_corrp_tstat1_filled

# tbss_x

# tbss_sym FA
#
# fslmaths tbss_tfce_corrp_tstat1 -thr 0.95 grot
# tbss_deproject grot 1
#
# tbss_deproject grot 2

#time elapsed
duration=$SECONDS
echo "Time elapsed $(( $duration / 3600 )) hours, $(( $duration / 60 )) minutes, $(( $duration % 60 )) seconds"
