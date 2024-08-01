#!/bin/bash

#SBATCH --account=PAS2444
#SBATCH --job-name=haplotype_caller
#SBATCH --output=logs/haplotype_caller_%A.out
#SBATCH --error=logs/haplotype_caller_%A.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=48:00:00

# Load necessary modules
module load gatk/4.4.0.0 samtools

# Source the config file
source /users/PAS1286/jignacio/projects/pm/src/config.sh

# Set projects to single end
unset projects
projects=$projects_se
project=${projects[0]}

# Prepare the list of BAM files to merge
projectdir="${homedir}/data/${project}"
indir="${projectdir}/base_recalibrated"
outdir="${projectdir}/11_output_vcf"
mkdir -p $outdir

#samtools index "${indir}/recalibrated.bam"

# HaplotypeCaller
gatk --java-options "-Xmx16g" HaplotypeCaller  \
    -R "$ref" \
    -I "${indir}/recalibrated.bam" \
    -O "${outdir}/${project}_calibrated.g.vcf.gz"