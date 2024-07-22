#!/bin/bash

#SBATCH --account=PAS2444
#SBATCH --job-name=add_read_groups
#SBATCH --output=logs/add_read_groups_%A_%a.out
#SBATCH --error=logs/add_read_groups_%A_%a.err
#SBATCH --array=11-859
#SBATCH --cpus-per-task=1

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

bamlist="${projectdir}/bamlist.txt"
sampleidlist="${projectdir}/read_groups.txt"

indir="${projectdir}/bam"
outdir="${projectdir}/bam_with_read_groups"
mkdir -p $outdir

if [ ! -e "$bamlist" ]; then
    ls -d ${indir}/*.bam > $bamlist
    echo "File $bamlist already exists. Skipping creation."
fi

if [ ! -e "$sampleidlist" ]; then
    ls ${indir}/*.bam | tr '\n' '\0' | xargs -0 -n 1 basename | sed 's/.bam//g' > $sampleidlist
else
    echo "File $sampleidlist already exists. Skipping creation."
fi

# Determine which sample to process
task_id=${SLURM_ARRAY_TASK_ID}

bam=$(sed -n "${task_id}p" $bamlist)
sample_name=$(sed -n "${task_id}p" $sampleidlist)

java -jar -Xmx4g $PICARD AddOrReplaceReadGroups \
    I="${bam}" \
    O="${outdir}/${sample_name}.bam" \
    RGID=$project \
    RGLB=$project \
    RGPL=$project \
    RGPU=$project \
    RGSM=$sample_name
