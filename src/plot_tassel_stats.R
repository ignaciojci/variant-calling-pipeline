setwd("/users/PAS1286/jignacio/projects/pm/data/12_merged_vcf/")


# Load the necessary package
library(stringr)
library(dplyr)
library(ggplot2)

files <- list.files(pattern = "summary.*.txt")
file=files[1]
#df <- read.table(file, sep="\t", header=T)
df <- lapply(files, read.table, sep="\t", header=T)
df[[1]]
str(df[[3]])
hist(df[[3]]$Proportion.Missing)
hist(df[[3]]$Minor.Allele.Frequency)
hist(df[[3]]$Proportion.Heterozygous)
plot(density(df[[3]]$Proportion.Missing))
hist(df[[4]]$Proportion.Missing)

vcf_list <- read.table("../bam_with_read_groups_list.txt")


# Define the array of file paths
file_paths <- vcf_list$V1
# Extract the project and sample
project <- str_extract(file_paths, "(?<=data/)[^/]+")
sample <- str_extract(file_paths, "(?<=07_output_vcf_uncalibrated/)[^/]+(?=\\.g\\.vcf\\.gz)")

# Create a data frame
df_sample <- data.frame(file_paths, project, sample)

# Print the data frame
print(df_sample)
unique(df_sample$project)
str(df[[4]])
lj <- left_join(df[[4]],df_sample,by=join_by(Taxa.Name == sample))
str(lj)
ggplot(lj, aes(x=project, y=Proportion.Missing)) + geom_boxplot() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
plot(density(lj$Proportion.Missing))

high_call_rate_lines <- lj %>%
  filter(Proportion.Missing < 0.04) %>%
  select(Taxa.Name)

write.table(high_call_rate_lines, "lines_with_call_rate_over_95.txt", row.names = F, col.names = F, quote = F)

hcr_dart <- lj %>%
  filter(project == "PM_DArT") %>%
  arrange(Proportion.Missing)
plot(hcr_dart$Proportion.Missing, type="o")

hcr_dart_lines <- hcr_dart %>%
  filter(Proportion.Missing < 0.7) %>%
  select(Taxa.Name)
write.table(hcr_dart_lines, "dart_lines_with_call_rate_over_30.txt", row.names = F, col.names = F, quote = F)

# /users/PAS1286/jignacio/projects/pm/data/12_merged_vcf/lines_with_call_rate_over_95.txt