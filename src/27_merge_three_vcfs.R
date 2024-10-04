setwd("/fs/scratch/PAS2444/jignacio/2024/pm/data")

library(dplyr)
library(gaston)

vcf_files <- list("./d16_merged_high_call_rate_vcf/merged.vcf.gz", # PM_DArT Only
          "./26_filtered_markers_merged_vcf/selection_147_lines_x_32780_snps.vcf.gz", # 147 lines
          "./12_merged_vcf/tmp/vcf6_maf0.01.vcf.gz") # All lines

vcfs <- lapply(vcf_files, read.vcf, #max.snps=100,
               convert.chr = FALSE)
lapply(vcfs, dim)

vcf <- vcfs[[1]]
vcf@snps

snps_list  <- lapply(vcfs, function(vcf){
  df <- vcf@snps
  df <- df %>%
    mutate(chr2 = ifelse(substr(chr ,start = 1, stop = 3) == "Chr",chr,
                         sprintf("Chr%02d",as.numeric(chr))),
           #pos = pos + 1,
           start = pos - 1) %>%
    select(chr2, start, pos)
})
snps <- do.call(rbind, snps_list)
snps2 <- snps %>%
  arrange(chr2, start) %>%
  distinct()
snps2 <- snps2 %>%
  mutate(arrchr = ifelse(chr2 == "Chr00", 1, 0)) %>%
  arrange(arrchr) %>%
  select(chr2, start, pos)
outdir <- "27_filter_markers_three_vcfs/"
dir.create(outdir, showWarnings = F)
write.table(snps2, paste0(outdir,"markers_of_three_vcfs.bed"), quote = F, row.names = F, col.names = F, sep = "\t")

write.table(snps2 %>%
              #mutate(pos = pos+1) %>%
              select(chr2, pos), paste0(outdir,"two_col_markers_of_three_vcfs.txt"), quote = F, row.names = F, col.names = F, sep = "\t")
grep("^230847$",snps2$pos)
