#!/bin/bash

#SBATCH --account=PAS2444
#SBATCH --job-name=base_recal
#SBATCH --output=logs/base_recal_%A.out
#SBATCH --error=logs/base_recal_%A.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=24:00:00

# Load necessary modules
module load gatk/4.4.0.0

# Source the config file
source /users/PAS1286/jignacio/projects/pm/src/config.sh

# Set projects to single end
unset projects
projects=$projects_se
project=${projects[0]}

# Prepare the list of BAM files to merge
projectdir="${homedir}/data/${project}"
indir="${projectdir}/sorted"
outdir="${projectdir}/base_recalibrated"
mkdir -p $outdir

gatk BaseRecalibrator \
    -I "${indir}/sorted.bam" \
    -R $ref \
    --known-sites sites_of_variation.vcf \
    --known-sites another/optional/setOfSitesToMask.vcf \
    -O recal_data.table
 