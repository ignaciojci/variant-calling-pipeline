setwd("/fs/scratch/PAS2444/jignacio/2024/pm/data/28_filtered_markers_merged_three_vcfs/")

library(gaston)
library(ggplot2)
library(dplyr)

vcf_file <- "filtered_imp.vcf.gz"

vcf <- read.vcf(vcf_file, convert.chr = F)

sel.chr <- 6
sel.chr2 <- sprintf("Chr%02d",sel.chr)
sel.proportion <- 0.25
vcftmp <- select.snps(vcf, maf > 0.1)
# vcftmp <- select.snps(vcf, chr == sel.chr2 & maf > 0.1)
n.markers <- dim(vcftmp)[2] 
sel.n <- round(n.markers * sel.proportion)
vcftmp@snps$id <- 1:n.markers
sel.markers <- sample(1:n.markers, sel.n)

vcftmp2 <- select.snps(vcftmp, id %in% sel.markers)

ldfile <- "tmp/ld.filt"
write.bed.matrix(vcftmp2,ldfile)

plink <- "~/softwares/plink_1.9/plink"
# system(paste(plink,"--bfile",ldfile,"--allow-extra-chr","--indep-pairwise 250 10 0.8","--out",ldfile))
# ldfilt <- read.table(paste0(ldfile,".prune.in"))


# Run PLINK to calculate pairwise LD for all SNPs on a chromosome
system(paste(
  plink,
  "--bfile", ldfile,
  "--r2",
  "--ld-window", 1e6,
  "--ld-window-kb", 100000000,
  "--ld-window-r2 0",  # Include all pairwise comparisons
  "--out", "tmp/ld_results"
))

# Read PLINK LD output
ld_data <- read.table("tmp/ld_results.ld", header = TRUE, stringsAsFactors = FALSE)

# Inspect columns (important ones: SNP positions, R^2 values)
head(ld_data)  # Columns: SNP_A, SNP_B, BP_A, BP_B, R2
tail(ld_data)  # Columns: SNP_A, SNP_B, BP_A, BP_B, R2

pdf("ld_blocks.pdf")
for(sel.chr in 1:7){
  print(sel.chr)
  # Create a dataframe for ggplot (x: position of SNP_A, y: position of SNP_B, fill: R2)
  ld_plot_data <- ld_data %>%
    filter(CHR_A == sel.chr) %>%
    select(BP_A, BP_B, R2) %>%
    mutate(
      BP_A = as.numeric(as.factor(BP_A)),
      BP_B = as.numeric(as.factor(BP_B))
    )
  
  tail(ld_plot_data)
  
  # Plot using geom_raster
  p <- ggplot(ld_plot_data, aes(x = BP_A/sel.proportion, y = BP_B/sel.proportion, fill = R2)) +
    geom_tile() +
    scale_fill_gradient(low = "white", high = "blue", na.value = "grey50") +
    #theme_minimal() +
    labs(title = paste("Pairwise Linkage Disequilibrium (R2) of Chromosome", sel.chr),
         x = "SNP A Index",
         y = "SNP B Index",
         fill = expression(R^2)) +
    coord_fixed()  # Ensures square cells
  print(p)
}
dev.off()
