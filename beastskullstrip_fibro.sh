#!/usr/bin/env bash
#
# BEaSTSkullStrip.sh
# Using BEaST to do SkullStriping
# [see here](https://github.com/FCP-INDI/C-PAC/wiki/Concise-Installation-Guide-for-BEaST) for instructions for BEaST.
#
#
# The script requires AFNI, BEaST, MINC toolkit.

do_anyway=1

# set the timing
SECONDS=0

MincPATH=/opt/minc/1.9.16
source $MincPATH/minc-toolkit-config.sh

MincLibPATH='/Users/ben/Documents/NFBS_lib'

cwd=`pwd`

if [ $# -lt 1  ]
then
  echo " USAGE ::  "
  echo "  beastskullstrip.sh <input> [output prefix] "
  echo "   input: anatomical image with skull, in nifti format "
  echo "   output: The program will output: "
  echo "      1) a skull stripped brain image in scanner space; "
  echo "      2) skull stripped brain masks in mni spcae and scanner space. "
  echo "      3) anatomical image transformed to mni space "
  echo "      4) minc files of brain mask and anatomical, both in mni space (for beast library)"
  echo "   Option: output prefix: the filename of the output files without extention"
  echo " Example: beastskullstrip.sh ~/data/head.nii.gz ~/brain "
  exit
fi

if [ $# -ge 1 ]
then
    inputDir=$(dirname $1)
    if [ $inputDir == "." ]
    then
        inputDir=$cwd
    fi

    filename=$(basename $1)
    inputFile=$inputDir/$filename

    extension="${filename##*.}"
    if [ $extension == "gz" ]
    then
        filename="${filename%.*}"
    fi

    filename="${filename%.*}"
    out=$inputDir/$filename
fi

if [ $# -ge 2 ]
then
    outputDir=$(dirname $2)
    if [ $outputDir == "." ]
    then
        outputDir=$cwd
        out=$outputDir/$2
    else
        mkdir -p $outputDir
        out=$2
    fi
fi

workingDir=`mktemp -d`
#workingDir=`pwd`
echo " ++ working directory is $workingDir"
cd $workingDir

if [ ! -f head.nii ]
then
    3dcopy $inputFile head.nii
fi

if [ ! -f head.mnc ]
then
    nii2mnc head.nii head.mnc
fi
flist=head.mnc
flist="$flist head.nii"

# Run BEaST to do SkullStripping

if [ ! -f brain_mask_mni.mnc ] || [ $do_anyway -eq 1 ]
then
    mincbeast -verbose -same_res -fill -conf $MincLibPATH/default.1mm.new.conf $MincLibPATH head.mnc brain_mask_mni.mnc
fi
flist="$flist brain_mask_mni.mnc"


# Resample to head.mnc
if [ ! -f brain_mask_tmp.mnc ] || [ $do_anyway -eq 1 ]
then
    mincresample -like head.mnc brain_mask_mni.mnc brain_mask_tmp.mnc
fi
flist="$flist brain_mask_tmp.mnc"


# Convert image from MNC to NII format.
if [ ! -f brain_mask_tmp.nii ] || [ $do_anyway -eq 1 ]
then
    mnc2nii brain_mask_tmp.mnc brain_mask_tmp.nii
fi
flist="$flist brain_mask_tmp.nii"

if [ ! -f brain_mask_mni.nii ] || [ $do_anyway -eq 1 ]
then
    3dresample -orient RPI -prefix brain_mask_mni.nii -inset brain_mask_tmp.nii
fi
flist="$flist brain_mask_mni.nii"


# Generate and output brain image and brain mask
if [ ! -f head_brain.nii.gz ] || [ $do_anyway -eq 1 ]
then
    3dcalc -a brain_mask_mni.nii -b head.nii -expr "a*b" -prefix head_brain.nii.gz
fi
flist="$flist head_brain.nii"


# output files
3dcopy head_brain.nii.gz ${out}_brain.nii.gz
3dcopy brain_mask_mni.nii ${out}_brain_mask.nii.gz

# delete all intermediate files
rm -rf $flist
echo "  ++ working directory is $workingDir"
cd $cwd

duration=$SECONDS
echo "Time elapsed $(( $duration / 3600 )) hours, $(( $duration / 60 )) minutes, $(( $duration % 60 )) seconds"
