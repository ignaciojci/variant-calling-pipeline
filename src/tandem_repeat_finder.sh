## Tandem repeat finder

salloc -A pas2444 -c 1 --time=01:00:00

cd /fs/scratch/PAS2444/jignacio/2024/pm/data/refs/843B/trf_run

~/softwares/trf/trf409.linux64 PearlMillet.843B.CHROMOSOMES.fasta 2 7 7 80 10 50 150 -d -m 

~/softwares/trf/trf409.linux64 test_seq.txt trf genome.fasta 2 7 7 80 10 50 150 -d -m 

