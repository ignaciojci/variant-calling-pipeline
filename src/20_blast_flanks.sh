#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=blast_flank
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --cpus-per-task=1
#SBATCH --time=00:59:00

# Run with:
# sbatch -a 1 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/20_blast_flanks.sh
# sbatch -a 1-400 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/20_blast_flanks.sh
# sbatch -a 401-800 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/20_blast_flanks.sh
# tail logs/merge_bam-32401873.err

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

indir="${homedir}/data/d21_gc_content_flanks"
outdir="${homedir}/data/d20_blast_flanks"
mkdir -p "$outdir"

# Load necessary modules
module load blast/2.13.0+
# module load samtools
# cd /users/PAS1286/jignacio/projects/pm/data/d21_gc_content_flanks
# ref="/users/PAS1286/jignacio/projects/pm/data/refs/843B/PearlMillet.843B.CHROMOSOMES.fasta"
# samtools faidx "$ref" -r SNP_Right_Flank_25bp.txt -o SNP_Right_Flank_25bp.fasta
# samtools faidx "$ref" -r SNP_Left_Flank_25bp.txt -o SNP_Left_Flank_25bp.fasta

# makeblastdb -in PearlMillet.843B.CHROMOSOMES.fasta -dbtype nucl -parse_seqids -out PearlMillet.843B.CHROMOSOMES -title "PearlMillet.843B"

infile=$indir/SNP_Right_Flank_25bp.fasta
#infile=$indir/head.fasta
outfile=$outdir/SNP_Right_Flank_blast_result_${SLURM_ARRAY_TASK_ID}.txt

# Define the input file and the number of lines per chunk
input_file="$infile"
records_per_chunk=$(($(wc -l < "$input_file") / 2 / 800))  # Adjust the divisor based on the number of chunks

# Calculate the start and end lines for this task
start_record=$(($SLURM_ARRAY_TASK_ID * $records_per_chunk + 1))
end_record=$(($start_record + $records_per_chunk - 1))
start_line=$(($start_record * 2 - 1))
end_line=$(($end_record * 2))

# Extract the chunk for this task
chunk_file=$outdir/chunk_right_${SLURM_ARRAY_TASK_ID}.txt
sed -n "${start_line},${end_line}p" "$input_file" > "$chunk_file"

blastdb=/users/PAS1286/jignacio/projects/pm/data/refs/843B/PearlMillet.843B.CHROMOSOMES
blastn -task blastn-short -query "$chunk_file" -db "$blastdb" -out "$outfile" \
  -dust no -soft_masking false -penalty -3 -reward 1 -gapopen 5 -gapextend 2 -outfmt 6 -num_threads 1 -max_target_seqs 5

infile=$indir/SNP_Left_Flank_25bp.fasta
#infile=$indir/head.fasta
outfile=$outdir/SNP_Left_Flank_blast_result_${SLURM_ARRAY_TASK_ID}.txt

# Define the input file and the number of lines per chunk
input_file="$infile"
records_per_chunk=$(($(wc -l < "$input_file") / 2 / 800))  # Adjust the divisor based on the number of chunks

# Calculate the start and end lines for this task
start_record=$(($SLURM_ARRAY_TASK_ID * $records_per_chunk + 1))
end_record=$(($start_record + $records_per_chunk - 1))
start_line=$(($start_record * 2 - 1))
end_line=$(($end_record * 2))

# Extract the chunk for this task
chunk_file=$outdir/chunk_left_${SLURM_ARRAY_TASK_ID}.txt
sed -n "${start_line},${end_line}p" "$input_file" > "$chunk_file"

blastdb=/users/PAS1286/jignacio/projects/pm/data/refs/843B/PearlMillet.843B.CHROMOSOMES
blastn -task blastn-short -query "$chunk_file" -db "$blastdb" -out "$outfile" \
  -dust no -soft_masking false -penalty -3 -reward 1 -gapopen 5 -gapextend 2 -outfmt 6 -num_threads 1 -max_target_seqs 5

# end logging
alog --state end  --exit $?