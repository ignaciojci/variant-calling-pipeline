#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=add_read_groups
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=1

# Run with:
# sbatch -a 1-201 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/05_add_read_groups.sh
# sbatch -a 1-254 --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/05_add_read_groups.sh
# sbatch -a 1-403 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/05_add_read_groups.sh
# sbatch -a 1-309 --export=project_idx=3 -t 00:30:00 /users/PAS1286/jignacio/projects/pm/src/05_add_read_groups.sh
# sbatch -a 1-15 --export=project_idx=4 -t 48:00:00 /users/PAS1286/jignacio/projects/pm/src/05_add_read_groups.sh
# sbatch -a 1-662 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/05_add_read_groups.sh
#
# i=0; a="4,12,29,35,45,62,72,86,94,98,105,112,129,133-134,136,139,141,144,163,171,183-184,196"
# sbatch -a $a --export=project_idx=${i} -t 04:00:00 /users/PAS1286/jignacio/projects/pm/src/05_add_read_groups.sh
# arange -t $a --log add_read_groups.log3 --summary
#
# arange -t 1-201 --log add_read_groups.log32400486 --summary
# arange -t 1-254 --log add_read_groups.log32404718 --summary
# sbatch -a 1-515,518-662 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/05_add_read_groups.sh
# arange -t 1-515,518-662 --log add_read_groups.log32432091 --summary
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

# Define env variables 'acc' in aenv_src_file
aenv_src_file="${projectdir}/SraAccList.csv.tmp"
aenv_src_file="${projectdir}/SraAccList.csv"
#head -n 3 "${projectdir}/SraAccList.csv" > "${aenv_src_file}"
source <(aenv --no_sniffer --data "${aenv_src_file}")
sample_name="${acc}"

indir="${projectdir}/bam"
outdir="${projectdir}/bam_with_read_groups"
mkdir -p $outdir

# Load necessary modules
module load picard
java -jar -Xmx4g $PICARD AddOrReplaceReadGroups \
    I="${indir}/${sample_name}.bam" \
    O="${outdir}/${sample_name}.bam" \
    RGID=$project \
    RGLB=$project \
    RGPL=$project \
    RGPU=$project \
    RGSM=$sample_name

# end logging
alog --state end  --exit $?