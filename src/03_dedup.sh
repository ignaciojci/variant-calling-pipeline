#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=clumpify
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1

# Run with:
# sbatch -a 1-403 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/02_extract_fastqs.sh

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
task_id=$SLURM_ARRAY_TASK_ID
seq_type=${projects_seq_type[${project_idx}]}

# Define env variables 'acc' in aenv_src_file
aenv_src_file="${projectdir}/SraAccList.csv.tmp"
aenv_src_file="${projectdir}/SraAccList.csv"
#head -n 3 "${projectdir}/SraAccList.csv" > "${aenv_src_file}"
source <(aenv --no_sniffer --data "${aenv_src_file}")

# # List samples
# for project in ${projects[@]}; do
#     projectdir="${homedir}/data/${project}"
#     ls ${projectdir}/sra | head -n 2 > ${projectdir}/sample.list
#     #ls ${projectdir}/sra 3 > ${projectdir}/sample.list
# done

# ## If paired end
# # Extract fastqs
# for project in ${projects[@]}; do
#     projectdir="${homedir}/data/${project}"
#     cat ${projectdir}/sample.list | while read line; do
#         outdir="${projectdir}/fastqs"
#         mkdir -p "$outdir"
#         fasterq-dump "${projectdir}/sra/${line}" --outdir "${outdir}"
#     done
# done

# ## If paired end
# # Extract fastqs
# outdir="${projectdir}/fastqs"
# mkdir -p "$outdir"
# line="${acc}"
# fasterq-dump "${projectdir}/sra/${line}" --outdir "${outdir}"

# Remove optical duplicates using clumpify
infolder="fastqs"
outfolder="deduped"
indir="${projectdir}/${infolder}"
outdir="${projectdir}/${outfolder}"
mkdir -p "$outdir"
if [ $seq_type == "paired" ]; then
    $bbmap/clumpify.sh \
        -Xmx8g \
        dedupe \
        in="${indir}/${line}_1.fastq" \
        in2="${indir}/${line}_2.fastq" \
        out="${outdir}/${line}_1.fastq" \
        out2="${outdir}/${line}_2.fastq"
else
    $bbmap/clumpify.sh \
        -Xmx8g \
        dedupe \
        in="${indir}/${line}.fastq" \
        out="${outdir}/${line}.fastq"
fi

# # Get read length distribution
# infolder="deduped"
# outfolder="read_length_distribution"
# indir="${projectdir}/${infolder}"
# outdir="${projectdir}/${outfolder}"
# mkdir -p "$outdir"
# if [ $seq_type == "paired" ]; then
#     $bbmap/readlength.sh \
#         -Xmx8g \
#         in="${indir}/${line}_1.fastq" \
#         in2="${indir}/${line}_2.fastq" \
#         out="${outdir}/${line}.txt"
# else
#     $bbmap/readlength.sh \
#         -Xmx8g \
#         in="${indir}/${line}.fastq" \
#         out="${outdir}/${line}.txt"
# fi

# module load bwa
# infolder="deduped"
# outfolder="bam"
# for project in ${projects[@]}; do
#     projectdir="${homedir}/data/${project}"
#     cat ${projectdir}/sample.list | while read line; do
#         indir="${projectdir}/${infolder}"
#         outdir="${projectdir}/${outfolder}"
#         mkdir -p "$outdir"
#         bwa mem $ref "$indir/${line}_1.fastq" "${indir}/${line}_2.fastq" -t 1 > "${outdir}/${line}.sam"
#     done
# done

#bwa mem /users/PAS1286/jignacio/projects/pm/data/refs/843B/PearlMillet.843B.CHROMOSOMES.fasta /users/PAS1286/jignacio/projects/pm/data/01_PRJNA422966/deduped/SRR11078104_1.fastq /users/PAS1286/jignacio/projects/pm/data/01_PRJNA422966/deduped/SRR11078104_2.fastq -t 1 > /users/PAS1286/jignacio/projects/pm/data/01_PRJNA422966/bam/SRR11078104.sam

# end logging
alog --state end  --exit $?
