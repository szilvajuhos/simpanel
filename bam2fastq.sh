#! /bin/bash -l

################################################################################
##
## This is a bash script for converting a BAM file to a pair of
## FASTQ files (gzip-compressed) using samtools and Picard.
##
## The conversion is done in 3 steps:
##   1. shuffle the input bam
##   2. run RevertSam to restore original qualities (if available)
##   3. run SamToFastq to produce paired fastq files
##
## To use the script, pass the BAM file as an argument to the script.
## The output FASTQ file names are created by stripping the .bam file
## extension and replacing it with _1.fastq.gz and _2.fastq.gz, respectively.
##
## Example:
##   bash bam2fastq.sh /path/to/bamfile.bam
##
##   This will yield the paired FASTQ files /path/to/bamfile_1.fastq.gz and
##   /path/to/bamfile_2.fastq.gz
##
## To submit the script as a job to a SLURM cluster, just submit with the
## UPPNEX id of your project, e.g.:
##   sbatch -A b2015999 bam2fastq.sh /path/to/bamfile.sh
##
################################################################################

#SBATCH -p core
#SBATCH -n 4
#SBATCH -N 1
#SBATCH -A ngi2016004
#SBATCH -J bam2fastq
#SBATCH -t 48:00:00
#SBATCH -o bam2fastq.%j.out
#SBATCH -e bam2fastq.%j.err

# exit on error
set -e
set -o pipefail

# load required modules
#module load bioinfo-tools
#module load picard/1.127
#module load samtools/0.1.19
module load samtools

PICARD_HOME=/sw/apps/bioinfo/picard/2.10.3/milou/
PICARD_TOOLS_DIR=${PICARD_HOME}


# define the input and output variables
IN="${1}"
F1="`basename ${IN/.bam/_1.fastq}`"
F2="`basename ${IN/.bam/_2.fastq}`"

# if running on a compute node, use the scratch area for output, otherwise write
# directly to the output directory
if [ -z "$SLURM_JOB_ID" ]
then
  SNIC_TMP="`dirname ${IN}`"
fi

# 1. shuffle the input bam
# 2. run RevertSam to restore original qualities (if available)
# 3. run SamToFastq to produce paired fastq files (readgroup information)

samtools bamshuf -Ou "${IN}" "$SNIC_TMP/shuf.tmp" | \
java -Xmx15G -jar "${PICARD_HOME}"/picard.jar RevertSam \
  INPUT=/dev/stdin \
  OUTPUT=/scratch/bugger.sam \
  REMOVE_ALIGNMENT_INFORMATION=true \
  REMOVE_DUPLICATE_INFORMATION=true \
  SORT_ORDER=unsorted \
  RESTORE_ORIGINAL_QUALITIES=true

#java -Xmx15G -jar "${PICARD_HOME}"/picard.jar SamToFastq \
#  INPUT=bugger.sam \
#  OUTPUT_DIR=$SNIC_TMP \
#  FASTQ=tumour_R1.fastq \
#  SECOND_END_FASTQ=tumour_R2.fastq \
#  UNPAIRED_FASTQ=unpaired.fastq \
#  INCLUDE_NON_PF_READS=true \
#  INCLUDE_NON_PRIMARY_ALIGNMENTS=false
java -Xmx15G -jar /sw/apps/bioinfo/picard/2.10.3/milou/picard.jar SamToFastq INPUT=/scratch/bugger.sam FASTQ=$F1 SECOND_END_FASTQ=$F2 INCLUDE_NON_PF_READS=true
# we do not have RGs right now
#  OUTPUT_PER_RG=false \
#  RG_TAG=ID \
# should we consider INTERLEAVE=true ?

# compress 
pigz -p 4 -v /scratch/${F1}
pigz -p 4 -v /scratch/${F2}

# copy the results back from the node to the output directory
if [ ! -z "$SLURM_JOB_ID" ]
then
  cp -v /scratch/${F1}.gz `dirname ${IN}`
  cp -v /scratch/${F2}.gz `dirname ${IN}`
fi
