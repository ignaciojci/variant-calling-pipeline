#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=clumpify_dedup
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --mem=32G
#SBATCH --time=02:00:00

# Run with:
# sbatch -a 1-201 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 1-254 --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 1-403 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 1-309 --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 1-15 --export=project_idx=4 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 1-662 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 1-201 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 19,26,44-45,48-49,51,64,73,75,89,132,165-166 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 9 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 34-41 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 497 --export=project_idx=5 --mem=16G --time=02:00:00 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 517 --export=project_idx=5 --mem=32G --time=06:00:00 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 516 --export=project_idx=5 --mem=32G --time=06:00:00 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 573 --export=project_idx=5 --mem=8G --time=02:00:00 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 639 --export=project_idx=5 --mem=2G --time=00:30:00 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# sbatch -a 19 --export=project_idx=5 --mem=16G --time=06:00:00 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
# a="52,54-70,105-114,116-117,414-421,425,427,429,432-435,437-438,524,526-530,532,534-536,538-543,569-573,575-579,601,603,606-614,639-652"
# a="1-18,20-36,229-246,439-515,518-519"
# a="2-5,7-12,17-18,20-36,229-239,241-246,439-515,518"
# sbatch -a $a --export=project_idx=5 --mem=32G --time=06:00:00 /users/PAS1286/jignacio/projects/pm/src/03_dedup.sh
set -e -u -o pipefail -x

module load python/2.7-conda5.2

# start logging
alog --state start

source /users/PAS1286/jignacio/projects/pm/src/config.sh
mem="${SLURM_MEM_PER_NODE}m"

if [ -z ${project_idx+0} ]; then
  echo "The environment variable project_idx does not exist or is empty." >&2
else
  echo "The environment variable project_idx exists and its value is: ${project_idx}." >&2
fi

# Define project path
project="${projects[${project_idx}]}"
projectdir="${homedir}/data/${project}"
task_id=$SLURM_ARRAY_TASK_ID
seq_type="${projects_seq_type[${project_idx}]}"

# Define env variables 'acc' in aenv_src_file
aenv_src_file="${projectdir}/SraAccList.csv.tmp"
aenv_src_file="${projectdir}/SraAccList.csv"
#head -n 3 "${projectdir}/SraAccList.csv" > "${aenv_src_file}"
source <(aenv --no_sniffer --data "${aenv_src_file}")
line="${acc}"

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
# fasterq-dump "${projectdir}/sra/${line}" --outdir "${outdir}"

# Remove optical duplicates using clumpify
infolder="fastqs"
outfolder="deduped"
indir="${projectdir}/${infolder}"
outdir="${projectdir}/${outfolder}"
mkdir -p "$outdir"


if [ "$seq_type" == "paired" ]; then
    set +u
    $bbmap/clumpify.sh \
        -Xmx${mem} \
        dedupe \
        in="${indir}/${line}_1.fastq" \
        in2="${indir}/${line}_2.fastq" \
        out="${outdir}/${line}_1.fastq" \
        out2="${outdir}/${line}_2.fastq"
    set -u
elif [ "$seq_type" == "single" ]; then
    set +u
    $bbmap/clumpify.sh \
        -Xmx${mem} \
        dedupe \
        in="${indir}/${line}.fastq" \
        out="${outdir}/${line}.fastq"
    set -u
else
    echo "Unknown value: $seq_type"
fi


# Get read length distribution
infolder="deduped"
outfolder="read_length_distribution"
indir="${projectdir}/${infolder}"
outdir="${projectdir}/${outfolder}"
mkdir -p "$outdir"
if [ "$seq_type" == "paired" ]; then
    $bbmap/readlength.sh \
        -Xmx${mem} \
        in="${indir}/${line}_1.fastq" \
        in2="${indir}/${line}_2.fastq" \
        out="${outdir}/${line}.txt"
elif [ "$seq_type" == "single" ]; then
    $bbmap/readlength.sh \
        -Xmx${mem} \
        in="${indir}/${line}.fastq" \
        out="${outdir}/${line}.txt"
else
    echo "Unknown value: $seq_type"
fi


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
