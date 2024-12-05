setwd("/fs/scratch/PAS2444/jignacio/2024/pm/data/PM_Data/PM_Data")

library(gaston)

bed_files <- list.files(pattern=".bed")
bed_files <- bed_files[c(4,1,5,2,6,3)]
bf <- lapply(bed_files, read.bed.matrix)
lapply(bf, dim)

mout <- matrix(data=NA,nrow=length(bf),ncol=16)
intervals <- 0:10/20
colnames(mout) <- c("n.lines", "n.markers", "n.pm.dart.lines","n.snps.after.tagging","overall.call.rate", intervals)

i=1
for(i in 1:length(bf)){
  x <- bf[[i]]
  mout[i,1:2] <- dim(x)
  
  table(substr(x@ped$famid,1,4))
  
  dir.create("tmp",showWarnings = F)
  
  x1 <- select.inds(x, grepl("^3",famid)) # filter PM DArT lines
  
  ldfile <- "tmp/ld.filt"
  write.bed.matrix(x1,ldfile)
  
  plink <- "~/softwares/plink_1.9/plink"
  system(paste(plink,"--bfile",ldfile,"--allow-extra-chr","--indep-pairwise 250 10 0.8","--out",ldfile))
  ldfilt <- read.table(paste0(ldfile,".prune.in"))
  
  x1 <- select.snps(x1, id %in% ldfilt$V1)
  x1 <- set.stats(x1)
  mout[i,3:4] <- dim(x1)
  mout[i,5] <- mean(x1@snps$callrate)
  
  values <- x1@snps$maf
  
  # Use cut() to categorize the data into intervals
  categorized_values <- cut(values, breaks = intervals, include.lowest = TRUE, right = FALSE)
  
  # Create a frequency table
  freq_table <- table(categorized_values)
  
  # View the frequency table
  nmarkers_by_maf <- rev(cumsum(freq_table[length(freq_table):1]))
  names(nmarkers_by_maf) <- intervals[-length(intervals)]
  mout[i,6:15] <- nmarkers_by_maf
}

write.csv(mout,file="pm_dart_stats.csv")
