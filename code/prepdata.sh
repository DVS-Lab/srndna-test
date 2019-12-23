#!/usr/bin/env bash

# Example code for heudiconv and pydeface. This will get your data read for analyses.
# This code will convert DICOMS to BIDS. Will also deface and run MRIQC.
 
# usage: bash prepdata.sh sub nruns
# example: bash prepdata.sh 104 3

# Notes: 
# 1) containers live under /data/tools on local computer
# 2) already created a dataset with datalad
# datalad create --description "creating srndna-all dataset" -c text2git srndna-all
# 3) other projects should use Jeff's python script for fixing the IntendedFor 


sub=$1
nruns=$2


# set up input and output directories.
dsroot=`pwd` # assume you are running from the root
codedir=$dsroot/code
sourcedata=/data/sourcedata/srndna

# make bids folder if it doesn't exist
if [ ! -d $dsroot/bids ]; then
	mkdir -p $dsroot/bids
fi


# PART 1: running heudiconv and fixing fieldmaps

if [ $sub -gt 121 ]; then
  singularity run --cleanenv -B $dsroot:/out -B $sourcedata:/sourcedata \
  /data/tools/heudiconv-0.5.4.simg -d /sourcedata/dicoms/SMITH-AgingDM-{subject}/*/DICOM/*.dcm -s $sub \
  -f /out/code/heuristics.py -c dcm2niix -b --minmeta -o /out/bids
else
  singularity run --cleanenv -B $dsroot:/out -B $sourcedata:/sourcedata \
  /data/tools/heudiconv-0.5.4.simg -d /sourcedata/dicoms/SMITH-AgingDM-{subject}/scans/*/DICOM/*.dcm -s $sub \
  -f /out/code/heuristics.py -c dcm2niix -b --minmeta -o /out/bids
fi

# run Jeff's code to fix field map, but first correct permissions
chmod -R ug+rw $dsroot/bids/sub-$sub
python $codedir/addIntendedFor.py



# PART 2: Defacing anatomicals to ensure compatibility with data sharing.

# note that pydeface.py should be in your path
bidsroot=$dsroot/bids
pydeface.py ${bidsroot}/sub-${sub}/anat/sub-${sub}_T1w.nii.gz
mv -f ${bidsroot}/sub-${sub}/anat/sub-${sub}_T1w_defaced.nii.gz ${bidsroot}/sub-${sub}/anat/sub-${sub}_T1w.nii.gz
pydeface.py ${bidsroot}/sub-${sub}/anat/sub-${sub}_T2w.nii.gz
mv -f ${bidsroot}/sub-${sub}/anat/sub-${sub}_T2w_defaced.nii.gz ${bidsroot}/sub-${sub}/anat/sub-${sub}_T2w.nii.gz



# PART 3: Run MRIQC on subject

# make derivatives folder if it doesn't exist. 
# let's keep this out of bids for now
if [ ! -d $dsroot/derivatives/mriqc ]; then
	mkdir -p $dsroot/derivatives/mriqc
fi

singularity run --cleanenv \
-B $dsroot/bids:/data \
-B $dsroot/derivatives/mriqc:/out \
-B /data/scratch:/scratch \
/data/tools/mriqc-0.15.1.simg \
/data /out \
participant --participant_label $sub --fft-spikes-detector --ica -w /scratch
