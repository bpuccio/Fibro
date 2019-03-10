#!/usr/bin/env bash
#
# TBSS analysis
#
#
#
# Ben Puccio
# 2019-02-20

# set the timing
SECONDS=0

#TBSS
cd /Users/ben/Documents/_FIBROMIALGIA/tbss_2/
tbss_1_preproc *.nii.gz
tbss_2_reg -T
tbss_3_postreg -S
tbss_4_prestats 0.2
cd stats
design_ttest2 design 24 16 -m
randomise -i all_FA_skeletonised -o tbss -m mean_FA_skeleton_mask -d design.mat -t design.con -n 500 --T2 -V

#cluster -i tbss_tfce_corrp_tstat1.nii.gz -t 0.95 --mm > cluster_t1_95.output

# tbss_fill tbss_tfce_corrp_tstat4 0.95 mean_FA tbss_tfce_corrp_tstat4_fill


# fsleyes -std1mm mean_FA_skeleton -cm green -dr .3 .7 \
#   tbss_tstat4 -cm red-yellow -dr 1.5 3 \
#   tbss_tfce_corrp_tstat4 -cm blue-lightblue -dr 0.949 1

# fsl_glm


# tbss_x

# tbss_sym FA
#
# fslmaths tbss_tfce_corrp_tstat1 -thr 0.95 grot
# tbss_deproject grot 1
#
# tbss_deproject grot 2



#ROI analysis
#fslstats -t all_FA_skeletonised -k roi_mask -M


#time elapsed
duration=$SECONDS
echo "Time elapsed $(( $duration / 3600 )) hours, $(( $duration / 60 )) minutes, $(( $duration % 60 )) seconds"
