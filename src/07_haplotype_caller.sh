#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=haplotype_caller
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --cpus-per-task=2
#SBATCH --time=48:00:00

# Run with:
# sbatch -a 1-201 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# sbatch -a 1-254 --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# sbatch -a 1-403 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# sbatch -a 1-309 --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# sbatch -a 1-15 --export=project_idx=4 -t 168:00:00 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# sbatch -a 1-662 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# sbatch -a 1-859 --export=project_idx=6 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
#
# arange -t 1-201 --log haplotype_caller.log30679951 --summary
# sbatch -a 2-81 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# arange -t 2-81 --log haplotype_caller.log30680398 --summary
# sbatch -a 2-309 --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# sbatch -a 1 --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# arange -t 2-81 --log haplotype_caller.log30680398 --summary
# sbatch -a 1-859%200 --export=project_idx=6 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# arange -t 1-859 --log haplotype_caller.log30683705 --summary
# arange -t 1-200 --log haplotype_caller.log30682256 --summary
# arange -t 201-859 --log haplotype_caller.log30684011 --summary
# sbatch -a 201-859 --export=project_idx=6 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# sbatch -a 1 --export=project_idx=0 -t 24:00:00 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# arange -t 2-309 --log haplotype_caller.log32406447 --summary
# sbatch -a 116,141,250 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# arange -t 1-201 --log haplotype_caller.log32407620 --summary
# sbatch -a 516 --export=project_idx=5 -t 168:00:00 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# sbatch -a 517 --export=project_idx=5 -t 168:00:00 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# sbatch -a 37-228,247-438,520-662 --export=project_idx=5 -t 06:00:00 /users/PAS1286/jignacio/projects/pm/src/07_haplotype_caller.sh
# arange -t 37-228,247-438,520-662 --log haplotype_caller.log32435528 --summary
set -u -o pipefail -x

module load python/2.7-conda5.2

# start logging
alog --state start

source /users/PAS1286/jignacio/projects/pm/src/config.sh

if [ -z ${project_idx+0} ]; then
  echo "The environment variable project_idx does not exist or is empty." >&2
else
  echo "The environment variable project_idx exists and its value is: ${project_idx}." >&2
fi

# Define project path
project="${projects[${project_idx}]}"
projectdir="${homedir}/data/${project}"
seq_type="${projects_seq_type[${project_idx}]}"

# Define env variables 'acc' in aenv_src_file
aenv_src_file="${projectdir}/SraAccList.csv.tmp"
aenv_src_file="${projectdir}/SraAccList.csv"
#head -n 3 "${projectdir}/SraAccList.csv" > "${aenv_src_file}"
source <(aenv --no_sniffer --data "${aenv_src_file}")
sample_name="${acc}"

indir="${projectdir}/sorted"
outdir="${projectdir}/07_output_vcf_uncalibrated"
mkdir -p $outdir

# Load necessary modules
module load gatk/4.4.0.0 samtools

samtools index "${indir}/${sample_name}.bam" 

# Detect memory
if [ -z ${SLURM_MEM_PER_CPU+0} ]; then
  echo "The environment variable SLURM_MEM_PER_CPU does not exist or is empty." >&2
  if [ -z ${SLURM_MEM_PER_NODE+0} ]; then
    echo "The environment variable SLURM_MEM_PER_NODE does not exist or is empty." >&2
  else
    echo "The environment variable SLURM_MEM_PER_NODE exists and its value is: ${SLURM_MEM_PER_NODE}." >&2
    mem=$SLURM_MEM_PER_NODE
  fi
else
  echo "The environment variable SLURM_MEM_PER_CPU exists and its value is: ${SLURM_MEM_PER_CPU}." >&2
  mempercpu=${SLURM_MEM_PER_CPU%m}
  totalmem=$((mempercpu * $SLURM_CPUS_PER_TASK))
  mem="${totalmem}m"
fi

# HaplotypeCaller

# tmpdir="/fs/scratch/PAS2444/tmp/$SLURM_JOBID"
# mkdir -p "$tmpdir"
# gatk --java-options "-Djava.io.tmpdir=${tmpdir} -Xms${mem} -Xmx${mem} -XX:ParallelGCThreads=2" HaplotypeCaller \
#     -R "$ref" \
#     -I "${indir}/${sample_name}.bam" \
#     -O "${outdir}/${sample_name}.g.vcf.gz" \
#     -ERC GVCF

gatk --java-options -Xmx${mem} HaplotypeCaller  \
    -R "$ref" \
    -I "${indir}/${sample_name}.bam" \
    -O "${outdir}/${sample_name}.g.vcf.gz" \
    -ERC GVCF

# end logging
alog --state end  --exit $?