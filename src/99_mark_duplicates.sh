#!/bin/bash

#SBATCH --account=PAS2444
#SBATCH --job-name=mark_duplicates
#SBATCH --output=logs/mark_duplicates_%A.out
#SBATCH --error=logs/mark_duplicates_%A.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=24:00:00

# Load necessary modules
module load picard

# Source the config file
source /users/PAS1286/jignacio/projects/pm/src/config.sh

# Set projects to single end
unset projects
projects=$projects_se
project=${projects[0]}

# Prepare the list of BAM files to merge
projectdir="${homedir}/data/${project}"
indir="${projectdir}/merged"
outdir="${projectdir}/marked_duplicates"
mkdir -p $outdir

# Mark duplicates
java -jar -Xmx16g $PICARD MarkDuplicates \
    I="${indir}/merged.bam" \
    O="${outdir}/marked_duplicates.bam" \
    M="${outdir}/marked_dup_metrics.txt"
