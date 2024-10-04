setwd("/fs/scratch/PAS2444/jignacio/2024/pm/data/d17_filtered_high_call_rate_vcf_stats/")

library(stringr)
library(dplyr)
library(parallel)

intervals <- 1:935

x=49

"interval_1/hwe.hwe"

get_maf_and_miss <- function(x){
  cat("Reading interval",x,"...")
  df <- read.table(paste0("interval_",x,"/maf.frq"), row.names=NULL, sep="\t", stringsAsFactors = F, header=T)
  if(nrow(df) > 0){
    colnames(df) <- colnames(df)[!grepl("row.names",colnames(df))]
    df2 <- df[,1:4]
    df2[,c("ALLELE1","ALLELE1_FREQ")] <- str_split_fixed(df[,5],":",2)
    df2[,c("ALLELE2","ALLELE2_FREQ")] <- str_split_fixed(df[,6],":",2)
    df2$ALLELE1_FREQ <- as.numeric(df2$ALLELE1_FREQ)
    df2$ALLELE2_FREQ <- as.numeric(df2$ALLELE2_FREQ)
    df2$MINOR_ALLELE_FREQ <- with(df2,ifelse(ALLELE1_FREQ < ALLELE2_FREQ, ALLELE1_FREQ, ALLELE2_FREQ))
    
    miss_df <- read.table(paste0("interval_",x,"/missing.lmiss"), sep="\t", stringsAsFactors = F, header = T)
    miss_df
    df2[,"F_MISS"] <- miss_df[,6]
    
    hwe <- read.table(paste0("interval_",x,"/hwe.hwe"), sep="\t", stringsAsFactors = F, header = T)
    df2[,"OBS.HOM1.HET.HOM2"] <- hwe$OBS.HOM1.HET.HOM2.
    df2[,"P_HWE"] <- hwe$P_HWE
    
    df2 <- df2 %>%
      select(-N_ALLELES, -N_CHR, -ALLELE1, -ALLELE2, -ALLELE1_FREQ, -ALLELE2_FREQ)
  }else{
    df2 <- df
  }
  
  cat("done!\n")
  return(df2)
}

# lout <- lapply(1:935, get_maf_and_miss)
# save(lout,file="all_stats.Rdata")
# load("all_stats.Rdata")
# dfout <- do.call(rbind,lout)
# save(dfout,file="all_stats_2.Rdata")
load("all_stats_2.Rdata")
str(dfout)

tab <- table(dfout$CHROM)
barplot(tab, main="Step 1: Histogram of chromosomes")
plot(density(dfout$MINOR_ALLELE_FREQ), main="Step 1: Density plot of minor allele frequency")
abline(v=0.05, lty=2)

values <- dfout$MINOR_ALLELE_FREQ
intervals <- 0:10/20

# Use cut() to categorize the data into intervals
categorized_values <- cut(values, breaks = intervals, include.lowest = TRUE, right = FALSE)

# Create a frequency table
(freq_table <- table(categorized_values))

# View the frequency table
print(freq_table)
cumsum(freq_table[length(freq_table):1])
with(dfout,hist(MINOR_ALLELE_FREQ))

# Distance to next SNP
filt_tmp <- dfout %>%
  filter(MINOR_ALLELE_FREQ > 0.05) %>%
  mutate(DIST_TO_PREV_SNP = POS - c(NA,POS[-length(POS)]),
         DIST_TO_NEXT_SNP = c(DIST_TO_PREV_SNP[-1],NA))

filt01 <- filt_tmp %>%
  filter(MINOR_ALLELE_FREQ > 0.05)
dim(filt01)

tab <- table(filt01$CHROM)
barplot(tab, main="Step 2: Histogram of chromosomes")
plot(density(filt01$F_MISS), main="Step 2: Density plot of missing proportion")
abline(v=0.7, lty=2)

filt02 <- filt01 %>%
  filter(F_MISS < 1.0)
sp <- str_split_fixed(filt02$OBS.HOM1.HET.HOM2, "/", 3)
sp <- apply(sp,2,as.numeric)
filt02$F_HET <- sp[,2] / (sp[,1] + sp[,3])
filt02$NEGLOG10_P_HWE <- -log10(filt02$P_HWE)

tab <- table(filt02$CHROM)
barplot(tab, main="Step 3: Histogram of chromosomes")
plot(density(filt02$NEGLOG10_P_HWE), main="Step 3: Density plot of -log10(HWE p-value)")
plot(density(filt02$F_HET), main="Step 3: Density plot of heterozygous proportion")

filt03 <- filt02 %>%
  filter(DIST_TO_PREV_SNP > 2,
         DIST_TO_NEXT_SNP > 2)
dim(filt03)
tab <- table(filt03$CHROM)
barplot(tab, main="Step 4: Histogram of chromosomes")

write.csv(filt03, file="maf20_callrate95_2141704_snps.csv", row.names=F)
write.table(filt03, file="maf20_callrate95_2141704_snps.txt", row.names = F, col.names = F, quote=F)
