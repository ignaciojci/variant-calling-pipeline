setwd("/users/PAS1286/jignacio/projects/pm/data/12_merged_vcf/")

list.files()
library(dplyr)
library(gaston)
library(ggplot2)
library(gplots)
library(pheatmap)
library(GGally)
library(tidyr)
# install.packages("devtools")
# devtools::install_github("jgx65/hierfstat")
library(hierfstat)
library(pegas)
library(adegenet)

vcf <- gaston::read.vcf("merged.vcf.gz", convert.chr = FALSE)
dim(vcf@snps)
nmarkers <- dim(vcf@snps)[1]
vcf@ped$callrate <- with(vcf@ped, 1-(NAs/(N0+N1+N2+NAs)))
vcf@snps$id <- with(vcf@snps, paste(chr, pos, sep="_"))
plot(density(vcf@ped$callrate), main="Step 2: Sample call rate")
abline(v=0.2, lty=2)
vcf2 <- select.inds(vcf, callrate > 0.20)
hist(vcf2@ped$callrate)

vcf2 <- set.stats.snps(vcf2)
plot(density(vcf2@snps$callrate), main="Step 3: SNP call rate")
abline(v=0.5, lty=2)
vcf3 <- select.snps(vcf2, callrate > 0.5)
dim(vcf3)

vcf3 <- set.stats(vcf3)
X <- as.matrix(vcf3)
sum(is.na(X))/prod(dim(X))

vcf2@snps$id <- with(vcf2@snps, paste(chr, pos, sep="_"))
x <- vcf2

#save(x,file="filtered_marker_data.Rdata")

#rm(list=ls())
#load("filtered_marker_data.Rdata")

x[1:10,1:10]
#### Remove redundant SNPs in high LD
dim(x)
X.tmp <- as.matrix(x)
ifelse(!dir.exists("tmp"),dir.create("tmp"),print("dir exists"))
ldfile <- "tmp/ld.filt"
# write.bed.matrix(x,ldfile)
# 
# plink <- "/users/PAS1286/jignacio/softwares/plink_1.9/plink"
# system(paste(plink,"--bfile",ldfile,"--allow-extra-chr","--indep-pairwise 250 10 0.99","--out",ldfile))
ldfilt <- read.table(paste0(ldfile,".prune.in"))
#X <- X.tmp[sidx,ldfilt$V1]
#dim(X)
vcf4 <- select.snps(vcf2, id %in% ldfilt$V1)
dim(vcf4)
vcf4 <- set.stats(vcf4)
plot(density(vcf4@snps$callrate), main="Step 4: SNP call rate")
abline(v=0.5, lty=2)
vcf5 <- select.snps(vcf4, callrate > 0.5)
dim(vcf5)

# x <- vcf5
# # Compute LD
# ld.x <- LD(x, c(1,ncol(x)))
# #ld.x <- LD(x, c(1,1000), c(1,20))
# #LD.plot( ld.x[1:20,1:20], snp.positions = x@snps$pos[1:20] )
# 
# # Plot a tiny part of the LD matrix
# LD.plot( ld.x[1:20,1:20], snp.positions = x@snps$pos[1:20] )
# # Customize the plot
# LD.plot( ld.x[1:20,1:20], snp.positions = x@snps$pos[1:20],
#          graphical.par = list(cex = 1.3, bg = "gray"),
#          polygon.par = list(border = NA), write.ld = NULL )
plot(density(vcf4@snps$maf), main="Step 5: SNP minor allele frequency")
abline(v=0.01, lty=2)
plot(density(-log10(vcf4@snps$maf)))
abline(v=-log10(0.01), lty=2)
abline(v=-log10(0.05), lty=2)
abline(v=-log10(0.10), lty=2)

vcf5 <- select.snps(vcf4, callrate > 0.5 & maf > 0.01)
vcf5 <- set.stats(vcf5)
dim(vcf5)
vcf5@ped$callrate <- with(vcf5@ped, 1-(NAs/(N0+N1+N2+NAs)))
plot(density(vcf5@ped$callrate), main="Step 5: Sample call rate")
abline(v=0.5, lty=2)
vcf6 <- select.inds(vcf5, callrate > 0.6)
vcf6 <- set.stats(vcf6)
vcf6@ped$callrate <- with(vcf6@ped, 1-(NAs/(N0+N1+N2+NAs)))
dim(vcf6)
mean(vcf6@ped$callrate)
write.bed.matrix(vcf6,"tmp/vcf6_maf0.1")
write.csv(vcf6@ped, "working_set_1674_samples.csv")
write.csv(vcf6@snps, "working_set_33970_snps.csv")

barplot(table(vcf6@snps$chr))
dim(vcf6)

X <- as.matrix(vcf6)
X2 <- apply(X, 2, function(x){
  x[is.na(x)] <- mean(x,na.rm=T)
  return(x)
})
pc <- prcomp(X2,)
plot(pc$x[,1],pc$x[,2])
vcf5@ped

# get sample grouping

fn <- read.csv("/users/PAS1286/jignacio/projects/pm/data/bam_with_read_groups_list.txt", header=F)
metadata <- stringr::str_match(fn$V1, 'data/([^ ]*)/07_output_vcf_uncalibrated/([^ ]*).g.vcf.gz')[,c(2:3)]
metadata2 <- metadata[,2:1]
write.table(metadata2, "tmp/indfile.txt", row.names = F, quote = F, col.names =F)
write.bed.matrix(x,"tmp/fS_run")
df <- data.frame(vcf6@ped, pc$x[,1:5])
df <- df %>%
  mutate(dataset=metadata[match(id, metadata[,2]),1])

write.table(df %>% pull(dataset), row.names = F, col.names = F, quote = F, file="tmp/pop_names_1674.txt")

ggplot(data=df, aes(x=PC1, y=PC2, color=dataset)) +
  geom_point()

plot(density(vcf6@snps$maf))

ggpairs(data=df, columns = c("PC1","PC2","PC3","PC4","PC5"), mapping=ggplot2::aes(colour = dataset))

n<-20
pcvars <- (pc$sdev^2/sum(pc$sdev^2))[1:n]
names(pcvars) <- paste0("PC",1:n)
barplot(pcvars, las=2, main="Proportion variance explained")
cumsum(pcvars)
filt.X <- vcf6

pop <- df$dataset

# fst.out <- Fst(filt.X, pop, quiet = F)
# hist(fst.out[,2])
# apply(fst.out, 2, mean)

# ranx <- sample(1:nrow(filt.X),100)
# rany <- sample(1:ncol(filt.X),1000)
# 
# rfst.out <- Fst(filt.X[ranx,rany], pop[ranx], quiet = F)
# hist(rfst.out[,2])

#vcf6_plink <- read.PLINK("tmp/vcf6")
#gi <- loci2genind(filt.X[ranx,rany])

#pegas_vcf <- pegas::read.vcf("merged.vcf.gz")
#hierfstat_vcf <- hierfstat::read.VCF("merged.vcf.gz", conver)

#pairwise.neifst(gi)
# markers_idx <- vcf@snps$id %in% vcf6@snps$id
# samples_idx <- vcf@ped$id %in% vcf6@ped$id
#filt.X <- pegas_vcf[samples_idx, markers_idx]
# X0 <- as.matrix(vcf6)
X <- as.matrix(vcf6)
# X <- gsub(2, 22, X)
# X <- gsub(1, 12, X)
# X <- gsub(0, 11, X)
# X <- as.numeric(X)
# X <- matrix(X, nrow=nrow(vcf6))
dim(X)
X[1:10,1:10]
# bs.nc <- basic.stats(hfs)
# boxplot(bs.nc$perloc[,1:3]) # boxplot of Ho, Hs, Ht
# wc(hfs)
# varcomp.glob(data.frame(hfs[,1]),hfs[,-1])
# 
# boot.vc(hfs[,1],hfs[,-1])
# 
Í <- fs.dosage(X,pop=pop)
fs.pgt <- pairwise.fst.dosage(X,pop=pop)

image(1:5,1:5,fs.gt$FsM,main=expression(F[ST]^{XY}))
# Sample data: a 5x5 numerical matrix
mat <- fs.pgt

# Plot heatmap with values in each cell

heatmap.2(mat, 
          cellnote = round(mat, 2),  # show values in cells, rounded to 2 decimals
          notecol = "black",         # color of the text
          trace = "none",            # no trace lines inside the heatmap
          dendrogram = "none",       # no dendrograms
          Colv = NA,                 # no column clustering
          Rowv = NA,                 # no row clustering
          key = TRUE,                # color key legend
          margins = c(5, 5))         # margins for the heatmap

# Plot heatmap with values in each cell
pheatmap(mat, 
         display_numbers = TRUE,          # display values in cells
         number_format = "%.2f",          # format for the numbers
         fontsize_number = 10,            # font size for the numbers
         cluster_rows = FALSE,            # no row clustering
         cluster_cols = FALSE)            # no column clustering
