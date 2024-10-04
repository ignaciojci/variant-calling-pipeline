setwd("/fs/scratch/PAS2444/jignacio/2024/pm/data/d20_blast_flanks/")

list.files()
# Load necessary library
library(dplyr)
library(stringr)
library(parallel)

# Get a list of the file names
side="right"
x <- 1
x <- Sys.getenv("SLURM_ARRAY_TASK_ID")
outdir <- "/users/PAS1286/jignacio/projects/pm/data/d22_unique_blast_hits/"
dir.create(outdir, showWarnings = F)

get_snps_with_one_hit <- function(side, x){
  file_name <- list.files(pattern = paste0("^SNP_",side,".*result_",x,".txt"), ignore.case = TRUE)
  df <- read.table(file_name)
  names(df) <- c("query_acc_ver","subject_acc_ver","percent_identity", 
                 "alignment_length","mismatches","gap_opens",
                 "q_start","q_end","s_start","s_end","evalue","bit_score")
  split <- str_split_fixed(gsub(":","-",df$query_acc_ver), "-", 3)
  df$chr <- split[,1]
  if(side == "left"){
    df$pos.exp <- as.numeric(split[,3]) + 1
    df$pos.obs <- df$s_end + 1
  }else if(side == "right"){
    df$pos.exp <- as.numeric(split[,2]) - 1
    df$pos.obs <- df$s_start - 1
  }
  if(side == "left"){
    df2 <- df %>%
      filter(q_end > 21) %>%
      group_by(query_acc_ver) %>%
      mutate(hits = n()) %>%
      ungroup()
  }else if(side == "right"){
    df2 <- df %>%
      filter(q_start < 5) %>%
      group_by(query_acc_ver) %>%
      mutate(hits = n()) %>%
      ungroup()
  }
  df2$side <- side
  df3 <- df2 %>%
    filter(hits == 1, pos.exp == pos.obs)
}

merge_flanks <- function(x){
  cat("Processing chunk",x,"...")
  left_x <- get_snps_with_one_hit("left",x)
  right_x <- get_snps_with_one_hit("right",x)
  #lj <- full_join(left_x, right_x, by=join_by(pos.exp), keep=F)
  lj <- left_x %>%
    full_join(right_x, by = join_by(pos.exp), suffix = c(".x", ".y")) %>%
    mutate(across(ends_with(".x"), 
                  ~ coalesce(.x, get(sub(".x", ".y", cur_column()))))) %>%
    rename_with(~ sub(".x", "", .), ends_with(".x")) %>%
    select(-ends_with(".y"))
  outfile <- paste0(outdir,"unique_hits_",x,".csv")
  write.csv(lj,outfile,row.names=F)
  cat("done! Results written to",outfile,"\n")
}

merge_flanks(x)
