setwd("/users/PAS1286/jignacio/projects/pm")

library(dplyr)

list.dirs("data",recursive = F)
files <- list.files("data/06_PRJNA805042/read_length_distribution/",full.names = T)
df <- do.call(rbind,lapply(files, function(x){
  df <- read.table(x)
  df$filename <- tools::file_path_sans_ext(basename(x))
  return(df)
}))
df %>%
  group_by(V1) %>%
  summarise(mean=mean(V2),
            median=median(V2),
            max=max(V2),
            sum=sum(V2))

df %>%
  group_by(filename) %>%
  summarise(mean=mean(V2),
            median=median(V2),
            max=max(V2),
            sum=sum(V2)) %>%
  arrange(desc(sum))


grep("SRR18500096",files,value=T)
acc_rld <- gsub(".*(SRR\\d+)/*.txt","\\1",files)
