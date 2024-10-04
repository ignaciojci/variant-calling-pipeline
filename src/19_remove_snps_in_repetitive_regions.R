rm(list=ls())
setwd("/fs/scratch/PAS2444/jignacio/2024/pm/data/d17_filtered_high_call_rate_vcf_stats/")

library(IRanges)
library(stringr)
library(dplyr)
library(parallel)
library(tibble)

repeats.file <- "/fs/scratch/PAS2444/jignacio/2024/pm/data/refs/843B/trf_run/PearlMillet.843B.CHROMOSOMES.fasta.2.7.7.80.10.50.150.dat"

# split repeats file per sequence

cmd <- paste("awk","\'/Sequence:/{n++} {print > \"repeats_sequence_\" n \".txt\"}\'",repeats.file)
system(cmd)
repeats.files <- list.files(".","^repeats.*_[1-9].txt")
x <- repeats.files[8]
system(paste("head -n 100",x))

read_repeats <- function(x){
  chr <- read.table(file = x,header = F,nrows = 1)[1,2]
  df <- read.table(x,skip=7)
  df$chr <- chr
  df
}
lout <- lapply(repeats.files, read_repeats)
df <- do.call(rbind, lout)
str(df)

df <- df %>%
  mutate(Chromosome = chr,
         Start = V1,
         End = V2)

flank_bp_size <- 25
snps <- read.csv("maf20_callrate95_2141704_snps.csv")
str(snps)

snps <- snps %>%
  mutate(Chromosome = CHROM,
         Start = POS-25,
         End = POS+25)

SNP_flanking <- data.frame(
  Chromosome = c("Chr01", "Chr01", "Chr02", "Chr02", "Chr03", "Chr03"),
  Start = c(3, 10, 5, 10, 2, 18),
  End = c(6, 16, 16, 19, 4, 19)
)

Avoid_range <- data.frame(
  Chromosome = c("Chr01", "Chr01", "Chr02", "Chr03", "Chr03"),
  Start = c(7, 14, 1, 6, 12),
  End = c(9, 20, 4, 9, 15)
)

SNP_flanking <- snps
Avoid_range <- df

SNP_ranges <- SNP_flanking %>%
  group_by(Chromosome) %>%
  do(ranges = IRanges(start = .$Start, end = .$End))

Avoid_ranges <- Avoid_range %>%
  group_by(Chromosome) %>%
  do(ranges = IRanges(start = .$Start, end = .$End))

SNP_flanking$Overlap <- FALSE

for (chr in unique(SNP_flanking$Chromosome)) {
  snp_chr_ranges <- SNP_ranges %>% filter(Chromosome == chr) %>% pull(ranges)
  avoid_chr_ranges <- Avoid_ranges %>% filter(Chromosome == chr) %>% pull(ranges)
  
  if (length(avoid_chr_ranges) > 0) {
    overlaps <- findOverlaps(snp_chr_ranges[[1]], avoid_chr_ranges[[1]])
    SNP_flanking$Overlap[SNP_flanking$Chromosome == chr] <- as.logical(countOverlaps(snp_chr_ranges[[1]], avoid_chr_ranges[[1]]))
  }
}

SNP_flanking %>%
  filter(Overlap, CHROM == "Chr00")
sum(SNP_flanking$Overlap)
sum(!SNP_flanking$Overlap)

SNP_flanking %>%
  filter(CHROM == "Chr00")

flank_bp_size <- 25
SNP_Left_Flank <- SNP_flanking %>%
  filter(!Overlap) %>%
  mutate(Chromosome = CHROM,
         Start = POS-flank_bp_size,
         End = POS-1,
         Index = sprintf("%s:%d-%d",Chromosome,Start,End)) %>%
  select(Chromosome, Start, End, Index)

SNP_Right_Flank <- SNP_flanking %>%
  filter(!Overlap) %>%
  mutate(Chromosome = CHROM,
         Start = POS+1,
         End = POS+flank_bp_size,
         Index = sprintf("%s:%d-%d",Chromosome,Start,End)) %>%
  select(Chromosome, Start, End, Index)
dim(SNP_Right_Flank)

write.table(SNP_Left_Flank %>% select(Index),paste0("SNP_Left_Flank_",flank_bp_size,"bp.txt"), quote=F,row.names = F,col.names = F)
write.table(SNP_Right_Flank %>% select(Index),paste0("SNP_Right_Flank_",flank_bp_size,"bp.txt"), quote=F,row.names = F,col.names = F)
write.table(SNP_Left_Flank %>% select(-Index),"SNP_Left_Flank.bed", quote=F,row.names = F,col.names = F)
write.table(SNP_Right_Flank %>% select(-Index),"SNP_Right_Flank.bed", quote=F,row.names = F,col.names = F)
write.csv(SNP_flanking %>% filter(!Overlap), "SNP_repeats_removed.csv", row.names = F)

