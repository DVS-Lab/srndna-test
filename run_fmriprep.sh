# example code for FMRIPREP
# runs FMRIPREP on input subject
# usage: bash run_fmriprep.sh sub
# example: bash run_fmriprep.sh 102

sub=$1
maindir=`pwd`

# make derivatives folder if it doesn't exist. 
# let's keep this out of bids for now
if [ ! -d $maindir/derivatives ]; then
	mkdir -p $maindir/derivatives
fi

singularity run -B $maindir:/base -B /data/tools/licenses:/opts \
/data/tools/fmriprep-1.5.3.simg \
/base/bids /base/derivatives \
participant --participant_label $sub \
--use-aroma --fs-no-reconall --fs-license-file /opts/fs_license.txt

datalad save -m "preprocessed $sub"
