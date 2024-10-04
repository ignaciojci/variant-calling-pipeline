setwd("/fs/scratch/PAS2444/jignacio/2024/pm/data/d22_unique_blast_hits/")

library(dplyr)

files <- list.files(pattern="^unique_hits_[0-9]+.csv")
ldf <- lapply(files, read.csv)
df <- do.call(rbind,ldf)
tab <- table(df$chr)
barplot(tab)
df2 <- df %>%
  mutate(pos.exp = pos.exp - 1) %>%
  arrange(chr, pos.exp)

outfile <- "/fs/scratch/PAS2444/jignacio/2024/pm/data/d16_merged_high_call_rate_vcf/filtered_marker_list.bed"
write.table(df2 %>% select(chr, pos.exp, pos.obs),outfile, row.names=F, col.names=F, quote=F, sep="\t")

# salloc -A pas2444 -t 24:00:00
# cd /fs/scratch/PAS2444/jignacio/2024/pm/data/16_merged_high_call_rate_vcf/
# module load bcftools/1.16
# bcftools index merged.vcf.gz
# bcftools view merged.vcf.gz -R filtered_marker_list.bed -o filtered.vcf.gz -O z
