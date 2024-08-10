#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=genomics_db_import
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --cpus-per-task=2
#SBATCH --time=48:00:00

# Run with:
# sbatch -a 1-8 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/08_genomics_db_import.sh
# sbatch -a 1-8 --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/08_genomics_db_import.sh
# sbatch -a 1-8 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/08_genomics_db_import.sh
# sbatch -a 1-8 --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/08_genomics_db_import.sh
# sbatch -a 1-8 --export=project_idx=4 /users/PAS1286/jignacio/projects/pm/src/08_genomics_db_import.sh
# sbatch -a 1-8 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/08_genomics_db_import.sh
# sbatch -a 1-8 --export=project_idx=6 /users/PAS1286/jignacio/projects/pm/src/08_genomics_db_import.sh
#
# tail logs/genomics_db_import-32401873.err
# sbatch -a 1 --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/08_genomics_db_import.sh

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

indir="${projectdir}/07_output_vcf_uncalibrated"
outdir="${homedir}/data/genomicsdb"
mkdir -p $outdir


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

tmpdir=/fs/scratch/PAS2444/jignacio/tmp/${SLURM_JOBID}_${SLURM_ARRAY_TASK_ID}
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


chrnum=($(seq -f "%02g" 0 7))
idx=$(( $SLURM_ARRAY_TASK_ID - 1))
j=${chrnum[$idx]}
#for j in $(seq -f "%02g" 0 7); do \
gdb=${outdir}/chr${j}_gdb
if [ -d "$gdb" ]; then
  echo "Genomics db exists."
  gdbws="--genomicsdb-update-workspace-path"
  # Back up genomics db
  cp -r $gdb ${gdb}_${SLURM_ARRAY_JOB_ID}_bak
  # rm -r "$gdb"
  # gdbws="--genomicsdb-workspace-path"
else
  echo "Genomics db does not exists."
  gdbws="--genomicsdb-workspace-path"
fi
gatk --java-options "-Djava.io.tmpdir=$tmpdir/tmp -Xms2G -Xmx2G -XX:ParallelGCThreads=2" GenomicsDBImport \
  $gdbws $gdb \
  -R $ref \
  --sample-name-map $output_file \
  --batch-size 50 \
  --tmp-dir "$tmpdir/tmp" \
  --max-num-intervals-to-import-in-parallel 3 \
  --intervals Chr${j} \
  --reader-threads 5
#done

# end logging
alog --state end  --exit $?