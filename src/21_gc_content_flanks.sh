#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=gc_content_flank
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A.out
#SBATCH --error=logs/%x-%A.err
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00

# Run with:
# sbatch --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/21_gc_content_flanks.sh
#
# tail logs/merge_bam-32401873.err

set -e -u -o pipefail -x

# module load python/2.7-conda5.2

# # start logging
# alog --state start

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

indir="${homedir}/data/d17_filtered_high_call_rate_vcf_stats"
outdir="${homedir}/data/d21_gc_content_flanks"
mkdir -p "$outdir"

# Load necessary modules
module load samtools
module load python/3.9-2022.05

regionsfile=$indir/SNP_Left_Flank_25bp.txt
infile=$indir/SNP_Left_Flank_25bp.fasta
#infile=$indir/head.fasta
outfile=$outdir/SNP_Left_Flank.txt

samtools faidx "$ref" -r "$regionsfile" -o "$infile"

python "${homedir}/src/21_gc_content_flanks.py" "$infile" "$outfile"

regionsfile=$indir/SNP_Right_Flank_25bp.txt
infile=$indir/SNP_Right_Flank_25bp.fasta
#infile=$indir/head.fasta
outfile=$outdir/SNP_Right_Flank.txt

samtools faidx "$ref" -r "$regionsfile" -o "$infile"

python "${homedir}/src/21_gc_content_flanks.py" "$infile" "$outfile"

# # end logging
# alog --state end  --exit $?