#!/bin/bash

source /users/PAS1286/jignacio/projects/pm/src/config.sh

# List samples
for project in ${projects[@]}; do
    projectdir="${homedir}/data/${project}"
    ls ${projectdir}/sra | head -n 2 > ${projectdir}/sample.list
    #ls ${projectdir}/sra 3 > ${projectdir}/sample.list
done

## If paired end
# Extract fastqs
for project in ${projects[@]}; do
    projectdir="${homedir}/data/${project}"
    cat ${projectdir}/sample.list | while read line; do
        outdir="${projectdir}/fastqs"
        mkdir -p "$outdir"
        fasterq-dump "${projectdir}/sra/${line}" --outdir "${outdir}"
    done
done

# Remove optical duplicates using clumpify
outfolder="deduped"
for project in ${projects[@]}; do
    projectdir="${homedir}/data/${project}"
    cat ${projectdir}/sample.list | while read line; do
        outdir="${projectdir}/${outfolder}"
        mkdir -p "$outdir"
        $bbmap/clumpify.sh \
            -Xmx8g \
            dedupe \
            in="${projectdir}/fastqs/${line}_1.fastq" \
            in2="${projectdir}/fastqs/${line}_2.fastq" \
            out="${outdir}/${line}_1.fastq" \
            out2="${outdir}/${line}_2.fastq"
    done
done

module load bwa
infolder="deduped"
outfolder="bam"
for project in ${projects[@]}; do
    projectdir="${homedir}/data/${project}"
    cat ${projectdir}/sample.list | while read line; do
        indir="${projectdir}/${infolder}"
        outdir="${projectdir}/${outfolder}"
        mkdir -p "$outdir"
        bwa mem $ref "$indir/${line}_1.fastq" "${indir}/${line}_2.fastq" -t 1 > "${outdir}/${line}.sam"
    done
done

#bwa mem /users/PAS1286/jignacio/projects/pm/data/refs/843B/PearlMillet.843B.CHROMOSOMES.fasta /users/PAS1286/jignacio/projects/pm/data/01_PRJNA422966/deduped/SRR11078104_1.fastq /users/PAS1286/jignacio/projects/pm/data/01_PRJNA422966/deduped/SRR11078104_2.fastq -t 1 > /users/PAS1286/jignacio/projects/pm/data/01_PRJNA422966/bam/SRR11078104.sam