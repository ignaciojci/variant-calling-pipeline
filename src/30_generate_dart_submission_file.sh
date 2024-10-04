#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=generate_dart_file
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A.out
#SBATCH --error=logs/%x-%A.err
#SBATCH --cpus-per-task=1
#SBATCH --time=00:59:00

# Run with:
# sbatch --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/30_generate_dart_submission_file.sh input.vcf.gz
#
# tail logs/merge_bam-32401873.err


set -e -u -o pipefail -x

in_vcf=$1

source /users/PAS1286/jignacio/projects/pm/src/config.sh

FLANK_LENGTH=150
REF_VER="843B (Ramu et al. 2023) https://figshare.com/articles/dataset/Improved_assemblies_of_pearl_millet_genomes/21261129/1"
VCF_FILE=$in_vcf
REFERENCE_GENOME=$ref
abs_in_vcf_dir=$(readlink -f "$in_vcf") # Get the absolute path of the input file
in_vcf_dir="$(dirname "${abs_in_vcf_dir}")"
tmp_dir="${in_vcf_dir}/tmp"
out_file=$(echo "$abs_in_vcf_dir" | sed 's/\.vcf\.gz$/_dart_submission_template.csv/')

module load samtools
module load bcftools/1.16

mkdir -p "$tmp_dir"

#!/bin/bash

# Length of flanking sequence
FLANK_LENGTH=150

# Output files
LEFT_FLANK_FILE="${tmp_dir}/left_flank.txt"
REF_ALT_FILE="${tmp_dir}/ref_alt.txt"
RIGHT_FLANK_FILE="${tmp_dir}/right_flank.txt"
FLANK_SEQUENCES_FILE="${tmp_dir}/flanking_sequences.fa"
FINAL_OUTPUT="$out_file"

# Extract regions from VCF file
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' $VCF_FILE | awk -v len=$FLANK_LENGTH '{print $1":"$2-len"-"$2+len}' > regions.txt

# Extract flanking sequences using samtools
samtools faidx $REFERENCE_GENOME -r regions.txt -o "$FLANK_SEQUENCES_FILE"

# Process flanking sequences to separate left and right flanks
awk -v len=$FLANK_LENGTH  -v left_file=$LEFT_FLANK_FILE -v right_file=$RIGHT_FLANK_FILE 'BEGIN {RS=">"; ORS=""} NR > 1 {seq = $2$3$4$5$6$7; left = substr(seq, 1, len); right = substr(seq, len + 2, length(seq)); print left "\n" > left_file; print right "\n" > right_file}' "$FLANK_SEQUENCES_FILE"

# Extract reference and alternate alleles
bcftools query -f '%CHROM\t%POS\t\[%REF/%ALT\]\n' $VCF_FILE > $REF_ALT_FILE

# Combine left flanking sequences, ref/alt alleles, and right flanking sequences
paste $REF_ALT_FILE $LEFT_FLANK_FILE $RIGHT_FLANK_FILE |\
 awk -v ref_ver="$REF_VER" 'BEGIN {OFS=","; print "MarkerName","TargetSequence","ReferenceGenome","Chrom","ChromPosPhysical","ChromPosGenetic","VariantAllelesDef","MarkerType","EssentialMarker","MinorAlleleFrequency","Quality","Comments"} {print $1"_"$2"_"$3, $4$3$5, ref_ver, $1, $2, "", $3, "SNP", "", "", "", ""}' > $FINAL_OUTPUT

# # Print final output
# cat $FINAL_OUTPUT


# # Step 1: Extract the positions of variants (SNPs) from the VCF file using bcftools
# # This will give us chromosome, position, reference allele, and alternate allele
# bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' "$VCF_FILE" > variants.txt

# # Create files to store the flanking sequences, ref/alt alleles, and final output
# LEFT_FLANK="$tmp_dir/left_flank.txt"
# REF_ALT="$tmp_dir/ref_alt.txt"
# RIGHT_FLANK="$tmp_dir/right_flank.txt"
# FINAL_OUTPUT="$out_file"

# # Clear old files if they exist
# > "$LEFT_FLANK"
# > "$REF_ALT"
# > "$RIGHT_FLANK"
# > "$FINAL_OUTPUT"

# # Step 2: Loop through the variants and query n bp flanking sequences using samtools faidx
# while read -r chrom pos ref alt; do
#     # Extract n bp left flank
#     left_start=$((pos - $FLANK_LENGTH - 1))
#     left_end=$((pos - 1))
#     samtools faidx "$REFERENCE_FASTA" "$chrom:$left_start-$left_end" | sed '1d' | tr -d '\n' >> "$LEFT_FLANK"
#     echo "" >> "$LEFT_FLANK"  # Add a newline to separate each sequence

#     # Store ref/alt alleles
#     echo "[$ref/$alt]" >> "$REF_ALT"

#     # Extract n bp right flank
#     right_start=$((pos + 1))
#     right_end=$((pos + $FLANK_LENGTH))
#     samtools faidx "$REFERENCE_FASTA" "$chrom:$right_start-$right_end" | sed '1d' | tr -d '\n' >> "$RIGHT_FLANK"
#     echo "" >> "$RIGHT_FLANK"  # Add a newline to separate each sequence
# done < variants.txt

# # Step 3: Combine the flanking sequences and ref/alt alleles into the final output
# "MarkerName","TargetSequence","ReferenceGenome","Chrom","ChromPosPhysical","ChromPosGenetic","VariantAllelesDef","MarkerType","EssentialMarker","MinorAlleleFrequency","Quality","Comments" > "$FINAL_OUTPUT"
# paste variants.txt "$LEFT_FLANK" "$REF_ALT" "$RIGHT_FLANK" | awk '{print $1, $2, $5$6$7}' OFS=, > "$FINAL_OUTPUT"

# # Final output format:
# # Chr Pos Sequence
# # Example: Chr01 123 ACTCGATCGACTACGCATCG[C/G]ACGTCGATCGATGGATCGTA
# echo "Output written to $FINAL_OUTPUT"
