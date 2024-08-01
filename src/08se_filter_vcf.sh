#!/bin/bash

module load bcftools/1.16

# Step 0: Compute Raw VCF stats
$tassel -Xmx16g -vcf PM_DArT_uncalibrated.g.vcf.gz -sortPositions -GenotypeSummary all -export summary_stats

# Step 1: Filter for biallelic SNPs only
bcftools view -m2 -M2 -v snps PM_DArT_uncalibrated.g.vcf.gz -Oz -o temp_biallelic_snps.vcf.gz

# Step 2: Index the filtered VCF
bcftools index temp_biallelic_snps.vcf.gz

# Step 3: Filter for MAF > 0.05
bcftools filter -i 'MAF[0] > 0.05' temp_biallelic_snps.vcf.gz -Ob -o temp_filtered_maf.vcf.gz

# Step 4: Index the filtered VCF
bcftools index temp_filtered_maf.vcf.gz

# Step 5: Calculate call rate and filter for call rate > 10%
export BCFTOOLS_PLUGINS=/usr/local/bcftools/1.16/libexec/bcftools
bcftools +fill-tags temp_filtered_maf.vcf.gz -Ou -- -t AN,AC | \
bcftools filter -i 'F_MISSING < 0.90' -Oz -o final_filtered.vcf.gz

# Step 6: Compute filtered VCF stats
$tassel -Xmx4g -vcf final_filtered.vcf.gz -sortPositions -GenotypeSummary all -export filtered_summary_stats