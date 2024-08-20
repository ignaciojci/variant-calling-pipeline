#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=combine_gvcfs
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --cpus-per-task=14
#SBATCH --time=01:00:00

# Run with:
# sbatch -a 1-281 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/08.1_genomics_db_import.sh
# sbatch -a 1-281 --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/08.1_genomics_db_import.sh
# sbatch -a 1-281 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/08.1_genomics_db_import.sh
# sbatch -a 1-281 --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/08.1_genomics_db_import.sh
# sbatch -a 1-281 --export=project_idx=4 /users/PAS1286/jignacio/projects/pm/src/08.1_genomics_db_import.sh
# sbatch -a 1-281 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/08.1_genomics_db_import.sh
# sbatch -a 1-281 --export=project_idx=6 /users/PAS1286/jignacio/projects/pm/src/08.1_genomics_db_import.sh
#
# tail logs/genomics_db_import-32401873.err
# sbatch -a 1 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/08.2_combine_gvcfs.sh

set -e -u -o pipefail -x

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

indir="${homedir}/data/*/07_output_vcf_uncalibrated"
outdir="${homedir}/data/combined_gvcfs"
mkdir -p $outdir

gvcflist="${homedir}/data/bam_with_read_groups_list.txt"
# > $bamlist

if [ ! -f $gvcflist ]; then
  ls -d ${indir}/*.g.vcf.gz > $gvcflist
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

# # Prepare the list of BAM files to merge
# inputlist="${projectdir}/uncalibrated_vcf_list.txt"
# ls -d ${indir}/*.vcf.gz > $inputlist
# # Generate INPUT=... syntax for each BAM file
# input_args=$(cat $inputlist | awk '{print "-V " $0}' | sed 's/$/\\/g')

# Load necessary modules
module load gatk/4.4.0.0

# List the .vcf.gz files and .vcf.gz.tbi files, then sort them
vcf_files=$(ls -d ${indir}/*.vcf.gz)

tmpdir=/fs/scratch/PAS2444/jignacio/tmp/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}
mkdir -p "$tmpdir/tmp"

# Create the output file
output_file="${tmpdir}/uncalibrated_vcf_list.txt"
> $output_file

# Iterate over the .vcf.gz files and generate the required columns
for vcf in $vcf_files; do
  # Extract the sample name (removing the .vcf.gz extension)
  sample_name=$(basename $vcf .g.vcf.gz)
  dir_name=$(dirname "${vcf}")

  # Find the corresponding .vcf.gz.tbi file
  tbi_file="${dir_name}/${sample_name}.g.vcf.gz.tbi"

  # Write to the output file
  echo -e "${sample_name}\t${vcf}\t${tbi_file}" >> $output_file
done


#chrnum=($(seq -f "%02g" 0 7))
#idx=$(( $SLURM_ARRAY_TASK_ID - 1))
#j=${chrnum[$idx]}
interval_num=$SLURM_ARRAY_TASK_ID
intervals_file="/users/PAS1286/jignacio/projects/pm/data/843B-300-intervals.txt"
source <(aenv --no_sniffer --data "${intervals_file}")
#for j in $(seq -f "%02g" 0 7); do \


# Generate INPUT=... syntax for each BAM file
input_args=$(cat $gvcflist | awk '{print "--variant " $0}' | tr '\n' ' ')
#input_args=$(cat $bamrglist | head -n10 | awk '{print "INPUT=" $0}' | tr '\n' ' ')

outvcf=${outdir}/interval_${interval_num}.vcf.gz

gatk --java-options "-Djava.io.tmpdir=$tmpdir/tmp -Xms${mem} -Xmx${mem} -XX:ParallelGCThreads=14" CombineGVCFs \
  -R $ref \
  $input_args \
  --tmp-dir "$tmpdir/tmp" \
  --intervals $interval \
  -O $outvcf

# gatk --java-options "-Djava.io.tmpdir=$tmpdir/tmp -Xms2G -Xmx2G -XX:ParallelGCThreads=2" GenomicsDBImport \
#   $gdbws $gdb \
#   -R $ref \
#   --sample-name-map $output_file \
#   --batch-size 50 \
#   --tmp-dir "$tmpdir/tmp" \
#   --max-num-intervals-to-import-in-parallel 3 \
#   --intervals $interval \
#   --reader-threads 5
#done

# end logging
alog --state end  --exit $?