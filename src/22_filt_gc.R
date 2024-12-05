rm(list=ls())
setwd("/fs/scratch/PAS2444/jignacio/2024/pm/data/21_gc_content_flanks")

library(dplyr)

lf <- read.table(file = "SNP_Left_Flank.txt", sep="\t", header = T)
colnames(lf)[2] <- "Left.GC"
rf <- read.table(file = "SNP_Right_Flank.txt", sep="\t", header = T)
colnames(rf)[2] <- "Right.GC"
df <- bind_cols(lf, rf)
plot(density(df$Left.GC))
plot(density(df$Right.GC), "Step 5: Density plot of GC content of 25 bp flanking region")
# abline(v=80, lty=2)
# abline(v=34, lty=2)
abline(v=60, lty=2)
abline(v=40, lty=2)
df2 <- df %>%
  filter(Left.GC >= 40 & Left.GC <= 60,
         Right.GC >= 40 & Right.GC <= 60)

snps <- read.csv("/fs/scratch/PAS2444/jignacio/2024/pm/data/17_filtered_high_call_rate_vcf_stats/SNP_repeats_removed.csv")
snps$Left.GC <- df$Left.GC
snps$Right.GC <- df$Right.GC

snps2 <- snps %>%
  filter(Left.GC >= 34 & Left.GC <= 80,
         Right.GC >= 34 & Right.GC <= 80)

snps3 <- snps %>%
  mutate(Ave.GC = (Left.GC + Right.GC) / 2)
plot(density(snps3$Ave.GC))
# abline(v=80, lty=2)
# abline(v=32, lty=2)
abline(v=61, lty=2)
abline(v=35, lty=2)
snps3 <- snps %>%
  mutate(Ave.GC = (Left.GC + Right.GC) / 2) %>%
  filter(Ave.GC >= 35 & Ave.GC <= 61)
dim(snps3)
snps2 <- snps3
tab <- table(snps2$Chromosome)
barplot(tab)
max_pos <- snps2 %>%
  group_by(Chromosome) %>%
  summarise(max(POS))
barplot(tab/(max_pos[,2]/max(max_pos[,2]))[,1])

SNP_flanking <- snps2

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
#write.table(SNP_Left_Flank %>% select(-Index),"SNP_Left_Flank.bed", quote=F,row.names = F,col.names = F)
#write.table(SNP_Right_Flank %>% select(-Index),"SNP_Right_Flank.bed", quote=F,row.names = F,col.names = F)
write.csv(SNP_flanking %>% filter(!Overlap), "SNP_repeats_removed_gc_filtered.csv", row.names = F)
