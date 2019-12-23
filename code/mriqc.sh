# example code for MRIQC
# runs MRIQC on input subject
# usage: bash run_mriqc.sh sub
# example: bash run_mriqc.sh 102

sub=$1
maindir=`pwd`

# make derivatives folder if it doesn't exist. 
# let's keep this out of bids for now
if [ ! -d $maindir/derivatives ]; then
	mkdir -p $maindir/derivatives
fi

singularity run --cleanenv \
-B $maindir/bids:/data \
-B $maindir/derivatives:/out \
-B /data/scratch:/scratch \
/data/tools/mriqc-0.15.1.simg \
/data /out \
participant --participant_label $sub --fft-spikes-detector --ica -w /scratch

datalad save -m "add mriqc for $sub"

# remove "--participant_label $sub" to run all subjects.