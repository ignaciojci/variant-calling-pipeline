setwd("/users/PAS1286/jignacio/projects/pm")
cmd <- "find \".\" -type f -name \"*.sra\" -exec stat --format=\"%s %n\" {} \\; > data/file_sizes.txt"
# system(cmd)
library(dplyr)
df <- read.table("data/file_sizes.txt")
head(df)
hist(log(df$V1,10))
df$V3 <- log(df$V1, 10)
df$V4 <- df$V1/1024/1024
df <- df[order(df$V1, decreasing = T),]
head(df, 100)

df[df$V3<10,]
df <- df[order(df$V2, decreasing = F),]
df$V5 <- gsub("./data/(.*)/sra.*","\\1",df$V2)
df <- df %>%
  group_by(V5) %>%
  mutate(n=row_number())
library(dplyr)
df %>%
  group_by(V5) %>%
  summarise(mean=mean(V4),
            median=median(V4),
            max=max(V4))

collapse_intervals <- function(nums) {
  nums <- sort(nums)
  result <- c()
  start <- nums[1]
  end <- start
  
  for (i in 2:length(nums)) {
    if (nums[i] == end + 1) {
      end <- nums[i]
    } else {
      if (start == end) {
        result <- c(result, as.character(start))
      } else {
        result <- c(result, paste(start, end, sep = "-"))
      }
      start <- nums[i]
      end <- start
    }
  }
  
  # Add the last interval
  if (start == end) {
    result <- c(result, as.character(start))
  } else {
    result <- c(result, paste(start, end, sep = "-"))
  }
  
  return(paste(result, collapse = ","))
}

p6 <- df %>% 
  filter(grepl("^06_",V5)) %>%
  arrange(desc(V1)) %>%
  mutate(acc=gsub(".*(SRR\\d+)/.*","\\1",V2))

sra <- read.csv("data/06_PRJNA805042/SraAccList.csv")
p6$idx <- match(p6$acc, sra$acc)
plot(p6$V4, type='o')
sel <- p6 %>%
  filter(V4 < 1000) %>%
  pull(idx)
collapse_intervals(sel)
sel <- p6 %>%
  filter(V4 > 1000) %>%
  pull(idx)
collapse_intervals(sel)
p7 <- p6[p6$idx %in% c(1:36,52,54:70,105:114,116:117,229:246,414:421,425,427,429,432:435,437:519,524,526:530,532,534:536,538:543,569:573,575:579,601,603,606:614,639:652),]
sel <- p7 %>%
  filter(V4 > 1000) %>%
  pull(idx)
sel <- sel[order(sel)]
plot(p7$V1,type="o")

p8 <- p6[!p6$idx %in% c(1:36,52,54:70,105:114,116:117,229:246,414:421,425,427,429,432:435,437:519,524,526:530,532,534:536,538:543,569:573,575:579,601,603,606:614,639:652),]
plot(p8$V1,type="o")

p9 <- p6[c(which(p6$idx %in% c(1:36,52,54:70,105:114,116:117,229:246,414:421,425,427,429,432:435,437:519,524,526:530,532,534:536,538:543,569:573,575:579,601,603,606:614,639:652)),
           which(!p6$idx %in% c(1:36,52,54:70,105:114,116:117,229:246,414:421,425,427,429,432:435,437:519,524,526:530,532,534:536,538:543,569:573,575:579,601,603,606:614,639:652))),]
plot(p9$V1, type="o")

plot(p6$V1[match(acc_rld,p6$acc)],type="o")
View(p6[match(acc_rld,p6$acc),] %>%
  arrange(desc(V1)))


# Example usage
nums <- c(1, 2, 3, 4, 5, 6, 8, 11, 12, 13, 15, 17)
collapse_intervals(nums)

collapse_intervals(sel)
