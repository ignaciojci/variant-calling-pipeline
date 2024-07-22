#!/bin/bash

# Determine number of files

#SBATCH --account=PAS2444
#SBATCH --job-name=preprocess_sequences
#SBATCH --output=logs/preprocess_sequences_%A_%a.out
#SBATCH --error=logs/preprocess_sequences_%A_%a.err
#SBATCH --array=4-859
#SBATCH --cpus-per-task=1

# Load the necessary modules
module load bowtie2

# Source the config file
source /users/PAS1286/jignacio/projects/pm/src/config.sh

# Set projects to single end
unset projects
projects=$projects_se
project=${projects[0]}

# Determine which sample to process
project_index=${SLURM_ARRAY_TASK_ID}


# Remove optical duplicates using clumpify
infolder=fastqs
outfolder=deduped

projectdir="${homedir}/data/${project}"
sample=$(sed -n "${project_index}p" ${projectdir}/sample.list)
outdir="${projectdir}/${outfolder}"
mkdir -p "$outdir"
$bbmap/clumpify.sh \
    -Xmx4g \
    dedupe \
    optical \
    dupedist=2500 \
    in="${projectdir}/${infolder}/${sample}.FASTQ.gz" \
    out="${outdir}/${sample}.fastq"

# Align to ref
infolder=deduped
outfolder=sam
indir="${projectdir}/${infolder}"
outdir="${projectdir}/${outfolder}"
mkdir -p "$outdir"
bowtie2 -x ${ref%.fasta} -U "$indir/${sample}.fastq" -S "${outdir}/${sample}.sam"

