setwd("/fs/scratch/PAS2444/jignacio/2024/pm/data")

library(dplyr)
library(gaston)

vcf_files <- list("./d16_merged_high_call_rate_vcf/merged.vcf.gz", # PM_DArT Only
                  "./26_filtered_markers_merged_vcf/selection_147_lines_x_32780_snps.vcf.gz", # 147 lines
                  "./12_merged_vcf/tmp/vcf6_maf0.01.vcf.gz") # All lines

vcf_file <- "./28_filtered_markers_merged_three_vcfs/filtered_imp.vcf.gz"
vcf <- read.vcf(vcf_file, convert.chr = F)

vcf_file0 <- "./26_filtered_markers_merged_vcf/selection_147_lines_x_32780_snps.vcf.gz"
vcf0 <- read.vcf(vcf_file0, convert.chr = F)
vcf <- select.inds(vcf, ! vcf@ped$id %in% vcf0@ped$id)
vcf@snps$id <- paste(vcf@snps$chr,vcf@snps$pos,sep="_")
vcf0@snps$id <- paste(vcf0@snps$chr,vcf0@snps$pos,sep="_")
vcf <- select.snps(vcf, vcf@snps$id %in% vcf0@snps$id)
vcf <- set.stats(vcf)
hist(vcf@snps$maf)
hist(vcf0@snps$maf)


values <- vcf@snps$maf
intervals <- 0:10/20

# Use cut() to categorize the data into intervals
categorized_values <- cut(values, breaks = intervals, include.lowest = TRUE, right = FALSE)

# Create a frequency table
(freq_table <- table(categorized_values))
pie(freq_table)
# View the frequency table
print(freq_table)
cs <- cumsum(freq_table[length(freq_table):1])
dim(vcf)
dim(vcf0)
signif(cs/dim(vcf)[2]*100,2)
cs
