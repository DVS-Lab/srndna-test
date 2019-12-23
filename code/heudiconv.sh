#!/usr/bin/env bash

# Example code for heudiconv
# This code will convert DICOMS to BIDS and log changes with datalad
 
# usage: bash run_heudiconv.sh sub nruns
# example: bash run_heudiconv.sh 104 3

# Notes: 
# 1) containers live under /data/tools on local computer
# 2) already created a dataset with datalad
# datalad create --description "creating srndna-all dataset" -c text2git srndna-all
# 3) other projects should use Jeff's python script for fixing the IntendedFor 


sub=$1
nruns=$2


# set up input and output directories.
# NB: bidsroot should be the pwd
bidsroot=`pwd`
sourcedata=/data/sourcedata/srndna

# make bids folder if it doesn't exist
if [ ! -d $bidsroot/bids ]; then
	mkdir -p $bidsroot/bids
fi

if [ $sub -gt 121 ]; then
  singularity run -B $bidsroot:/out -B $sourcedata:/sourcedata \
  /data/tools/heudiconv-0.5.4.simg -d /sourcedata/dicoms/SMITH-AgingDM-{subject}/*/DICOM/*.dcm -s $sub \
  -f /out/heuristics.py -c dcm2niix -b --minmeta -o /out/bids
else
  singularity run -B $bidsroot:/out -B $sourcedata:/sourcedata \
  /data/tools/heudiconv-0.5.4.simg -d /sourcedata/dicoms/SMITH-AgingDM-{subject}/scans/*/DICOM/*.dcm -s $sub \
  -f /out/heuristics.py -c dcm2niix -b --minmeta -o /out/bids
fi

# run Jeff's code to fix field map, but first correct permissions
chmod -R ug+rw $bidsroot/bids/sub-$sub
python addIntendedFor.py

# track changes in datalad. should we do this now or later? 
datalad save -m "add $sub with corrected IntendedFor field"

