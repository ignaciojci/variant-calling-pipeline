setwd("/fs/scratch/PAS2444/jignacio/2024/pm/data")

library(dplyr)
library(gaston)
library(ggplot2)
library(tidyr)

vcf_files <- list("./28_filtered_markers_merged_three_vcfs/filtered.vcf.gz",
                  "./d16_merged_high_call_rate_vcf/merged.vcf.gz", # PM_DArT Only
                  "./26_filtered_markers_merged_vcf/selection_147_lines_x_32780_snps.vcf.gz" # 147 lines
                  # "./12_merged_vcf/tmp/vcf6_maf0.01.vcf.gz"
                  )
vcfs <- lapply(vcf_files, read.vcf, #max.snps=1000,
               convert.chr = FALSE)
lapply(vcfs, dim)
vcfs <- lapply(vcfs, function(vcf){
  vcf@snps$id <- paste(vcf@snps$chr,vcf@snps$pos,sep="_")
  return(vcf)
})
vcf <- vcfs[[1]]
#geno_data <- vcf
vcf <- vcf[,vcf@snps$id %in% vcfs[[3]]@snps$id]
dim(vcf)
geno_data <- vcf[,sample(1:ncol(vcf),1000,replace = F)]

# Extract marker information
markers <- geno_data@snps[, c("chr", "pos")]

# Extract individual/sample information
individuals <- geno_data@ped[, "famid"]

# Create array to sort samples
sort_array <- rep(1, nrow(geno_data))
sort_array[individuals %in% vcfs[[2]]@ped$famid] <- 2
sort_array[individuals %in% vcfs[[3]]@ped$famid] <- 9

# Convert geno_data to R/qtl format (1, 2, and NA for missing)
geno_matrix <- as.matrix(geno_data[order(sort_array),])
geno_matrix <-is.na(geno_matrix)
rownames(geno_matrix) <- 1:nrow(geno_matrix)
colnames(geno_matrix) <- 1:ncol(geno_matrix)

# Create dataframe
df <- as.data.frame.table(geno_matrix, responseName = "is.missing")
# add variable: performance

ggplot(data = df, aes(y = as.numeric(Var1), x = as.numeric(Var2))) +
  geom_raster(aes(fill = is.missing)) +
  theme_minimal() + geom_hline(yintercept=nrow(geno_matrix)-147, linetype='dashed') +
  geom_hline(yintercept=nrow(geno_matrix)-147-nrow(vcfs[[2]]), linetype='dashed') +
  xlab("1,000 randomly sampled markers") + ylab("lines") +
  ggtitle("Plot of missing genotypes. Lines from top to bottom: 147 high-call rate lines, 798 PM_DArT lines, and 838 other lines")


geno_data <- vcfs[[1]][,sample(1:ncol(vcf),1000,replace = F)]

# Extract marker information
markers <- geno_data@snps[, c("chr", "pos")]

# Extract individual/sample information
individuals <- geno_data@ped[, "famid"]

# Create array to sort samples
sort_array <- rep(1, nrow(geno_data))
sort_array[individuals %in% vcfs[[2]]@ped$famid] <- 2
sort_array[individuals %in% vcfs[[3]]@ped$famid] <- 9

# Convert geno_data to R/qtl format (1, 2, and NA for missing)
geno_matrix <- as.matrix(geno_data[order(sort_array),])
geno_matrix <-is.na(geno_matrix)
rownames(geno_matrix) <- 1:nrow(geno_matrix)
colnames(geno_matrix) <- 1:ncol(geno_matrix)

# Create dataframe
df <- as.data.frame.table(geno_matrix, responseName = "is.missing")
# add variable: performance

ggplot(data = df, aes(y = as.numeric(Var1), x = as.numeric(Var2))) +
  geom_raster(aes(fill = is.missing)) +
  theme_minimal() + geom_hline(yintercept=nrow(geno_matrix)-147, linetype='dashed') +
  geom_hline(yintercept=nrow(geno_matrix)-147-nrow(vcfs[[2]]), linetype='dashed') +
  xlab("1,000 randomly sampled markers") + ylab("lines") +
  ggtitle("Plot of missing genotypes. Lines from top to bottom: 147 high-call rate lines, 798 PM_DArT lines, and 838 other lines")

