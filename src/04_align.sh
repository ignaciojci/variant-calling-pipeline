#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=align
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=1

# Run with:
# sbatch -a 1-201 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# sbatch -a 1-200 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# sbatch -a 1-254 --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# sbatch -a 1-403 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# sbatch -a 1-309 --export=project_idx=3 -t 00:30:00 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# sbatch -a 1-15 --export=project_idx=4 --cpus-per-task=4 -t 24:00:00 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# sbatch -a 1-662 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# i=0; a="4,12,29,35,45,62,72,86,94,98,105,112,129,133-134,136,139,141,144,163,171,183-184,196"
# i=1; a="1-10,21-32,86-93,105-108,111-112,115-116,123,129-130,151-152,181,183-190,192,210-220"
# i=1; a="24,28"
# sbatch -a $a --export=project_idx=${i} -t 08:00:00 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# sbatch -a 128 --export=project_idx=3 -t 01:00:00 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# arange -t 4,12,29,35,45,62,72,86,94,98,105,112,129,133-134,136,139,141,144,163,171,183-184,196 --log align.log32398015 --summary
# arange -t 1-10,21-32,86-93,105-108,111-112,115-116,123,129-130,151-152,181,183-190,192,210-220 --log align.log32398016 --summary
# arange -t 1-15 --log align.log32398171 --summary
# sbatch -a 24,28 --export=project_idx=1 -t 12:00:00 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# arange -t 24,28 --log align.log32400455 --summary
# sbatch -a 1-15 --export=project_idx=4 --cpus-per-task=14 -t 24:00:00 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# arange -t 1-15 --log align.log32401156 --summary
# sbatch -a 1-662 --export=project_idx=5 -t 00:30:00 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# sbatch -a 37-228,247-438,520-662 --export=project_idx=5 -t 01:00:00 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# arange -t 37-228,247-438,520-662 --log align.log30677565 --summary
# sbatch -a 516,517 --export=project_idx=5 --cpus-per-task=14 -t 168:00:00 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# tail -n20 logs/align-32401473_516.err
# sbatch -a 1-36,229-246,439-515,518-519 --export=project_idx=5 --cpus-per-task=14 -t 48:00:00 /users/PAS1286/jignacio/projects/pm/src/04_align.sh
# arange -t 1-36,229-246,439-515,518-519 --log align.log32401513 --summary
set -u -o pipefail -x

module load python/2.7-conda5.2

# start logging
alog --state start

source /users/PAS1286/jignacio/projects/pm/src/config.sh
task_id=$SLURM_ARRAY_TASK_ID

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

# # Remove optical duplicates using clumpify
# infolder="fastqs"
# outfolder="deduped"
# indir="${projectdir}/${infolder}"
# outdir="${projectdir}/${outfolder}"
# mkdir -p "$outdir"


# if [ "$seq_type" == "paired" ]; then
#     set +u
#     $bbmap/clumpify.sh \
#         -Xmx${mem} \
#         dedupe \
#         in="${indir}/${line}_1.fastq" \
#         in2="${indir}/${line}_2.fastq" \
#         out="${outdir}/${line}_1.fastq" \
#         out2="${outdir}/${line}_2.fastq"
#     set -u
# elif [ "$seq_type" == "single" ]; then
#     set +u
#     $bbmap/clumpify.sh \
#         -Xmx${mem} \
#         dedupe \
#         in="${indir}/${line}.fastq" \
#         out="${outdir}/${line}.fastq"
#     set -u
# else
#     echo "Unknown value: $seq_type"
# fi


# # Get read length distribution
# infolder="deduped"
# outfolder="read_length_distribution"
# indir="${projectdir}/${infolder}"
# outdir="${projectdir}/${outfolder}"
# mkdir -p "$outdir"
# if [ "$seq_type" == "paired" ]; then
#     $bbmap/readlength.sh \
#         -Xmx${mem} \
#         in="${indir}/${line}_1.fastq" \
#         in2="${indir}/${line}_2.fastq" \
#         out="${outdir}/${line}.txt"
# elif [ "$seq_type" == "single" ]; then
#     $bbmap/readlength.sh \
#         -Xmx${mem} \
#         in="${indir}/${line}.fastq" \
#         out="${outdir}/${line}.txt"
# else
#     echo "Unknown value: $seq_type"
# fi

module load bwa
module load samtools
infolder="deduped"
outfolder="bam"
indir="${projectdir}/${infolder}"
outdir="${projectdir}/${outfolder}"
mkdir -p "$outdir"

ncpus=$SLURM_CPUS_PER_TASK

if [ "$seq_type" == "paired" ]; then
    bwa mem $ref "$indir/${line}_1.fastq" "${indir}/${line}_2.fastq" -t $ncpus | samtools view -bS > "${outdir}/${line}.bam"
elif [ "$seq_type" == "single" ]; then
    bwa mem $ref "$indir/${line}.fastq" -t $ncpus | samtools view -bS > "${outdir}/${line}.bam"
else
    echo "Unknown value: $seq_type"
fi

#bwa mem /users/PAS1286/jignacio/projects/pm/data/refs/843B/PearlMillet.843B.CHROMOSOMES.fasta /users/PAS1286/jignacio/projects/pm/data/01_PRJNA422966/deduped/SRR11078104_1.fastq /users/PAS1286/jignacio/projects/pm/data/01_PRJNA422966/deduped/SRR11078104_2.fastq -t 1 > /users/PAS1286/jignacio/projects/pm/data/01_PRJNA422966/bam/SRR11078104.sam

# end logging
alog --state end  --exit $?
