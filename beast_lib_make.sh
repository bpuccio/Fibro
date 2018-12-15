#!/usr/bin/env bash
#
# Create BEaST library using ants
#
# Ben Puccio
# 2018-11-18

mni_1mm=/usr/local/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz
mni_1mm_noss=/usr/local/fsl/data/standard/MNI152_T1_1mm.nii.gz
data=/Users/ben/Documents/NFBS
lib=/Users/ben/Documents/NFBS_lib

# make directory
if [ ! -d ${lib} ]; then
  mkdir ${lib}
fi
# make subdirectories
if [ ! -d ${lib}/NFBS ]; then
  mkdir ${lib}/NFBS
fi
if [ ! -d ${lib}/NFBS/stx ]; then
  mkdir ${lib}/NFBS/stx
fi
if [ ! -d ${lib}/NFBS/masks ]; then
  mkdir ${lib}/NFBS/masks
fi
if [ ! -d ${lib}/NFBS/stx/1mm ]; then
  mkdir ${lib}/NFBS/stx/1mm
fi
if [ ! -d ${lib}/NFBS/masks/1mm ]; then
  mkdir ${lib}/NFBS/masks/1mm
fi
if [ ! -d ${lib}/NFBS/stx/2mm ]; then
  mkdir ${lib}/NFBS/stx/2mm
fi
if [ ! -d ${lib}/NFBS/masks/2mm ]; then
  mkdir ${lib}/NFBS/masks/2mm
fi
if [ ! -d ${lib}/NFBS/stx/4mm ]; then
  mkdir ${lib}/NFBS/stx/4mm
fi
if [ ! -d ${lib}/NFBS/masks/4mm ]; then
  mkdir ${lib}/NFBS/masks/4mm
fi

# get list of t1 images in NFBS dataset
list=$(ls -d ${data}/*/*T1w.nii.gz)
# length=$(wc -l ${list})

# set counter
c=1

if [ ! -f ${lib}/NFBS/stx/4mm/001.mnc ]; then
  # loop through each subject and register each
  for fold in ${list}; do

    base_path=$(dirname ${fold})
    filename=$(basename ${fold})
    filename="${filename%.*}"
    filename="${filename%.*}"
    file=${base_path}/${filename}

    #make subject number
    if [ ${c} -gt 9 ]; then
      if [ ${c} -gt 99 ]; then
        sub=${c}
      else
        sub=0${c}
      fi
    else
      sub=00${c}
    fi
    c=$(expr ${c} + 1)
    echo 'Subject #'${sub}

    #output path
    out1=${lib}/NFBS/stx/1mm/${sub}
    out2=${lib}/NFBS/stx/2mm/${sub}
    out4=${lib}/NFBS/stx/4mm/${sub}
    mout1=${lib}/NFBS/masks/1mm/${sub}
    mout2=${lib}/NFBS/masks/2mm/${sub}
    mout4=${lib}/NFBS/masks/4mm/${sub}

    if [[ ! -f ${out1}.nii ]]; then

      # copy files to lib directory
      if [ ! -f ${out1}_orig.nii.gz ]; then
        3dcopy ${fold} ${out1}_orig.nii.gz
        3dcopy ${file}_brainmask.nii.gz ${out1}_brain_mask.nii.gz
      fi

      # preprocess t1 and register to mni space
      if [ ! -f ${out1}_unifize.nii.gz ]; then

        ## Deoblique and orient
        3drefit -deoblique ${out1}_orig.nii.gz
        if [ $(3info -orient ${out1}_orig.nii.gz) != 'RPI' ]; then
          3dresample -orient RPI -prefix ${out1}.nii -inset ${out1}_orig.nii.gz
          rm ${out1}_orig.nii.gz
          3dcopy ${out1}.nii ${out1}_orig.nii.gz
          rm ${out1}.nii
        fi

        ## Bias Field Correction
        N4BiasFieldCorrection -d 3 -i ${out1}_orig.nii.gz -o ${out1}_bc.nii.gz -v

        #3dUnifize: for better skullstrip (bad results at pons)
        3dUnifize -input ${out1}_bc.nii.gz -prefix ${out1}_unifize.nii.gz
      fi

      if [ ! -f ${out1}_brain.nii.gz ]; then
        3dcalc -a ${out1}_unifize.nii.gz -b ${out1}_brain_mask.nii.gz -expr 'a*b' -prefix ${out1}_brain.nii.gz
      fi

      ## Normalization - ANTs
      if [ ! -f ${out1}_1Warp.nii.gz ]; then
        antsRegistrationSyNQuick.sh -d 3 -n 2 -f ${mni_1mm_noss} -m ${out1}_unifize.nii.gz -o ${out1}_
      fi
      if [ ! -f ${out1}_brain_mni.nii.gz ]; then
        antsApplyTransforms -d 3 -i ${out1}_unifize.nii.gz -o ${out1}_mni.nii.gz -r ${mni_1mm_noss} -t ${out1}_1Warp.nii.gz -t ${out1}_0GenericAffine.mat -v 1
        antsApplyTransforms -d 3 -i ${out1}_brain.nii.gz -o ${out1}_brain_mni.nii.gz -r ${mni_1mm} -t ${out1}_1Warp.nii.gz -t ${out1}_0GenericAffine.mat -v 1
        antsApplyTransforms -d 3 -i ${out1}_brain_mask.nii.gz -o ${out1}_brain_mask_mni.nii.gz -r ${mni_1mm} -t ${out1}_1Warp.nii.gz -t ${out1}_0GenericAffine.mat -n NearestNeighbor -v 1
      fi

      3dcopy ${out1}_mni.nii.gz ${out1}.nii

      ## delete unecessart files
      rm ${out1}_orig.nii.gz ${out1}_bc.nii.gz ${out1}_unifize.nii.gz ${out1}_brain_mask.nii.gz ${out1}_brain.nii.gz ${out1}_mni.nii.gz ${out1}_brain_mni.nii.gz
      rm ${out1}_1Warp.nii.gz ${out1}_Warped.nii.gz ${out1}_1InverseWarp.nii.gz ${out1}_InverseWarped.nii.gz ${out1}_0GenericAffine.mat

    fi

    ## Move 1mm masks to masks directory
    if [ ! -f ${mout1}.nii ]; then
      3dcopy ${out1}_brain_mask_mni.nii.gz ${mout1}.nii
      rm ${out1}_brain_mask_mni.nii.gz
    fi

    # Downsample head images
    if [ ! -f ${out2}.nii ]; then
      3dresample -dxyz 2.0 2.0 2.0 -rmode Li -prefix ${out2}.nii -inset ${out1}.nii
    fi
    if [ ! -f ${out4}.nii ]; then
      3dresample -dxyz 4.0 4.0 4.0 -rmode Li -prefix ${out4}.nii -inset ${out1}.nii
    fi

    if [ ! -f ${mout2}.nii ]; then
      3dresample -master ${out2}.nii -prefix ${mout2}.nii -inset ${mout1}.nii
    fi
    if [ ! -f ${mout4}.nii ]; then
      3dresample -master ${out4}.nii -prefix ${mout4}.nii -inset ${mout1}.nii
    fi

    #make config files
    if [ ! -f ${lib}/library.stx.1mm ]; then
      touch ${lib}/library.stx.1mm
    fi
    if [ ! -f ${lib}/library.masks.1mm ]; then
      touch ${lib}/library.masks.1mm
    fi
    if [ ! -f ${lib}/library.stx.2mm ]; then
      touch ${lib}/library.stx.2mm
    fi
    if [ ! -f ${lib}/library.masks.2mm ]; then
      touch ${lib}/library.masks.2mm
    fi
    if [ ! -f ${lib}/library.stx.4mm ]; then
      touch ${lib}/library.stx.4mm
    fi
    if [ ! -f ${lib}/library.masks.4mm ]; then
      touch ${lib}/library.masks.4mm
    fi

    # append file to config files
    echo 'NFBS/stx/1mm/'${sub}'.mnc' >> ${lib}/library.stx.1mm
    echo 'NFBS/stx/1mm/'${sub}'_flip.mnc' >> ${lib}/library.stx.1mm
    echo 'NFBS/masks/1mm/'${sub}'.mnc' >> ${lib}/library.masks.1mm
    echo 'NFBS/masks/1mm/'${sub}'_flip.mnc' >> ${lib}/library.masks.1mm
    echo 'NFBS/stx/2mm/'${sub}'.mnc' >> ${lib}/library.stx.2mm
    echo 'NFBS/stx/2mm/'${sub}'_flip.mnc' >> ${lib}/library.stx.2mm
    echo 'NFBS/masks/2mm/'${sub}'.mnc' >> ${lib}/library.masks.2mm
    echo 'NFBS/masks/2mm/'${sub}'_flip.mnc' >> ${lib}/library.masks.2mm
    echo 'NFBS/stx/4mm/'${sub}'.mnc' >> ${lib}/library.stx.4mm
    echo 'NFBS/stx/4mm/'${sub}'_flip.mnc' >> ${lib}/library.stx.4mm
    echo 'NFBS/masks/4mm/'${sub}'.mnc' >> ${lib}/library.masks.4mm
    echo 'NFBS/masks/4mm/'${sub}'_flip.mnc' >> ${lib}/library.masks.4mm

  done
fi

# MincPATH='/opt/minc-itk4'
# source $MincPATH/minc-toolkit-config.sh

if [ -f ${lib}/NFBS/stx/4mm/001.nii ]; then
  for res in 1 2 4 ; do
    for g in $(ls -d ${lib}/NFBS/*/${res}mm/*.nii); do

      # get names
      base=$(dirname ${g})
      name=$(basename ${g})
      name="${name%.*}"
      file=${base}/${name}

      #convert to mnc file
      if [ ! -f ${file}.mnc ]; then
        nii2mnc ${g} ${file}.mnc
      fi

      #flip
      if [ ! -f ${file}_flip.mnc ]; then
        flip_volume ${file}.mnc ${file}_flip.mnc
      fi

      #delete nifti file
      rm ${g}

    done
  done
fi

cd ${lib}
mincmath -or $(cat ${lib}/library.masks.1mm | xargs ) ${lib}/union_mask.mnc -clob
mincmath -and $(cat ${lib}/library.masks.1mm | xargs ) ${lib}/intersection_mask.mnc -clob
minccalc -expr "if (A[0]) 0 else A[1]" ${lib}/intersection_mask.mnc ${lib}/union_mask.mnc ${lib}/margin_mask.mnc -clob
