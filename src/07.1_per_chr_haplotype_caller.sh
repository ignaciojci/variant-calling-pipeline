#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=per_chr_haplotype_caller
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --cpus-per-task=2
#SBATCH --time=48:00:00

# Run with:
# sbatch -a 1-150 --export=chr_idx=0 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-150 --export=chr_idx=1 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-150 --export=chr_idx=2 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-150 --export=chr_idx=3 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-150 --export=chr_idx=4 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-150 --export=chr_idx=5 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-150 --export=chr_idx=6 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-150 --export=chr_idx=7 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
#
# sbatch -a 1-17 --export=chr_idx=0 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-17 --export=chr_idx=1 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-17 --export=chr_idx=2 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-17 --export=chr_idx=3 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-17 --export=chr_idx=4 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-17 --export=chr_idx=5 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-17 --export=chr_idx=6 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 1-17 --export=chr_idx=7 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
#
# for i in `seq 32435385 32435392`; do arange -t 1-17 --log per_chr_haplotype_caller.log$i; done
#
# sbatch -a 16-17 --export=chr_idx=0 -t 72:00:00 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 16-17 --export=chr_idx=1 -t 72:00:00 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 16-17 --export=chr_idx=2 -t 72:00:00 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 16-17 --export=chr_idx=3 -t 72:00:00 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 16-17 --export=chr_idx=4 -t 72:00:00 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 16-17 --export=chr_idx=5 -t 72:00:00 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 16-17 --export=chr_idx=6 -t 72:00:00 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh
# sbatch -a 16-17 --export=chr_idx=7 -t 72:00:00 /users/PAS1286/jignacio/projects/pm/src/07.1_per_chr_haplotype_caller.sh

set -e -u -o pipefail -x

module load python/2.7-conda5.2

# start logging
alog --state start

source /users/PAS1286/jignacio/projects/pm/src/config.sh

source <(aenv --data "${homedir}/data/per_chr_haplotype_caller_envlist.csv")

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
source <(aenv --no_sniffer --id ${acc_idx} --data "${aenv_src_file}")
sample_name="${acc}"

chrnum=($(seq -f "%02g" 0 7))
chr=Chr${chrnum[$chr_idx]}

indir="${projectdir}/sorted"
outdir="${projectdir}/07.5_per_chr_output_vcf_uncalibrated/${chr}"
mkdir -p $outdir

# Load necessary modules
module load gatk/4.4.0.0 samtools

infile="${indir}/${sample_name}.bam" 

if [ -f ${infile}.bai ]; then
  echo "Index file already exist, skipping indexing."
elif [ $chr_idx == 0 ]; then
  echo "Index file does not exist, indexing bam file..."
  samtools index "$infile"
else
  echo "Index file does not exist and will be created by another job."
fi

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
    -ERC GVCF \
    -L $chr

# end logging
alog --state end  --exit $?