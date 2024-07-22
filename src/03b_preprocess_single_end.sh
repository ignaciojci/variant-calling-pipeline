#!/bin/bash

source /users/PAS1286/jignacio/projects/pm/src/config.sh

# Set projects to single end
unset projects
projects=$projects_se

# List fastqs
infolder=fastqs
for project in ${projects[@]}; do
    projectdir="${homedir}/data/${project}"
    indir="${projectdir}/${infolder}"
    ls ${indir} | sed 's/.FASTQ.gz//g' > ${projectdir}/sample.list
    #ls ${projectdir}/sra 3 > ${projectdir}/sample.list
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
            optical \
            dupedist=2500 \
            in="${projectdir}/fastqs/${line}.FASTQ.gz" \
            out="${outdir}/${line}.fastq"
    done
done

# Align to ref
module load bowtie2

infolder="deduped"
outfolder="bam"
for project in ${projects[@]}; do
    projectdir="${homedir}/data/${project}"
    cat ${projectdir}/sample.list | while read line; do
        indir="${projectdir}/${infolder}"
        outdir="${projectdir}/${outfolder}"
        mkdir -p "$outdir"
        bowtie2 -x ${ref%.fasta} -U "$indir/${line}.fastq" -S "${outdir}/${line}.sam"
    done
done
