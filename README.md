# Genomic Variant Calling Pipeline

This repository contains a set of shell scripts designed for processing genomic sequencing data and performing variant calling. The pipeline is orchestrated using SLURM for job scheduling on a high-performance computing cluster.

## Pipeline Stages

The pipeline consists of the following stages:

1.  **`02_extract_fastqs.sh`**: Extracts FASTQ files from SRA archives.
2.  **`03_dedup.sh`**: Removes optical duplicates from reads and calculates read length distribution.
3.  **`04_align.sh`**: Aligns reads to a reference genome using BWA.
4.  **`05_add_read_groups.sh`**: Adds read group information to BAM files.
5.  **`06_sort_sam.sh`**: Sorts BAM files by coordinate.
6.  **`07_haplotype_caller.sh`**: Performs variant calling using GATK's HaplotypeCaller to generate gVCFs.
7.  **`08.2_combine_gvcfs.sh`**: Combines gVCFs for joint genotyping.
8.  **`09.1_para_genotype_gvcf_gendb.sh`**: Performs joint genotyping using NVIDIA Parabricks (GPU-accelerated).
9.  **`10_mark_dp0_as_missing.sh`**:  Marks genotypes with zero depth as missing in the VCF files.
10. **`11se_haplotype_caller.sh`**:  HaplotypeCaller for single-end sequencing data.
11. **`12_merge_vcfs.sh`**: Merges multiple VCF files into a single VCF file.
12. **`15_filter_samples.sh`**: Filters VCF files based on sample call rate and other criteria.

## Dependencies

The pipeline relies on the following software:

* Bash shell
* SLURM job scheduler
* Python 2.7
* SRA Toolkit (`fasterq-dump`)
* BBMap (`clumpify.sh`, `readlength.sh`)
* BWA
* Samtools
* Picard Toolkit
* GATK 4
* bcftools
* NVIDIA Parabricks (for GPU-accelerated genotyping)
* Apptainer (for containerization of Parabricks)
* Java 21

## Configuration

The pipeline uses a configuration file (`src/config.sh`) to define project-specific settings, including:

* Reference genome path
* Input and output directories
* Project identifiers

You will need to modify this file to match your specific environment and project requirements.

## Usage

Each script includes `sbatch` commands (commented out) that show example usage for submitting jobs to the SLURM cluster.  You will need to adjust these commands based on your cluster's configuration and resource availability.

**Example:**

```bash
# Submit the 02_extract_fastqs.sh script as a SLURM job
sbatch -a 1-100 --export=project_idx=3 src/02_extract_fastqs.sh
