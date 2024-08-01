#!/bin/bash

#SBATCH --account=PAS2444
#SBATCH --job-name=merge_bam
#SBATCH --output=logs/merge_bam_%A.out
#SBATCH --error=logs/merge_bam_%A.err
#SBATCH --cpus-per-task=6
#SBATCH --mem=32G
#SBATCH --time=12:00:00

# Load necessary modules
module load picard

# Source the config file
source /users/PAS1286/jignacio/projects/pm/src/config.sh

# Set projects to single end
unset projects
projects=$projects_se
project=${projects[0]}

# Prepare the list of BAM files to merge
mergedir="${homedir}/data/${project}/merged"
mkdir -p "$mergedir"
bamrglist="${homedir}/data/${project}/bam_with_read_groups_list.txt"
# > $bamlist

projectdir="${homedir}/data/${project}"
bamdir="${projectdir}/bam_with_read_groups"
ls -d ${bamdir}/*.bam > $bamrglist

# Generate INPUT=... syntax for each BAM file
input_args=$(cat $bamrglist | awk '{print "INPUT=" $0}' | tr '\n' ' ')
#input_args=$(cat $bamrglist | head -n10 | awk '{print "INPUT=" $0}' | tr '\n' ' ')

# Merge  files using Picard
java -jar -Xmx16g $PICARD MergeSamFiles \
    $input_args \
    OUTPUT="${mergedir}/merged.bam" \
    USE_THREADING=true \
    MAX_RECORDS_IN_RAM=5000000