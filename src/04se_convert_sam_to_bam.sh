#!/bin/bash

#SBATCH --account=PAS2444
#SBATCH --job-name=convert_sam_to_bam
#SBATCH --output=logs/convert_sam_to_bam_%A_%a.out
#SBATCH --error=logs/convert_sam_to_bam_%A_%a.err
#SBATCH --array=1-10
#SBATCH --cpus-per-task=1

# Load necessary modules
module load samtools

# Source the config file
source /users/PAS1286/jignacio/projects/pm/src/config.sh

# Set projects to single end
unset projects
projects=$projects_se
project=${projects[0]}

# Determine which sample to process
project_index=${SLURM_ARRAY_TASK_ID}
projectdir="${homedir}/data/${project}"
sample=$(sed -n "${project_index}p" ${projectdir}/sample.list)

# Convert SAM to BAM
indir="${projectdir}/sam"
outdir="${projectdir}/bam"
mkdir -p "$outdir"

samtools view -bS "${indir}/${sample}.sam" > "${outdir}/${sample}.bam"
