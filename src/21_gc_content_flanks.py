import argparse
from Bio import SeqIO
import pandas as pd

def calculate_gc_content(sequence):
    """Calculate the GC content of a sequence."""
    g = sequence.count('G')
    c = sequence.count('C')
    return (g + c) / len(sequence) * 100

def process_fasta(input_file):
    """Process the FASTA file and calculate GC content for each sequence."""
    data = []
    
    for record in SeqIO.parse(input_file, "fasta"):
        gc_content = calculate_gc_content(record.seq)
        data.append({"Sequence ID": record.id, "GC Content (%)": gc_content})
    
    return pd.DataFrame(data)

def main(input_file, output_file):
    """Main function to calculate GC content and save it to a tab-delimited file."""
    # Process the input FASTA file
    df = process_fasta(input_file)
    
    # Save the DataFrame to a tab-delimited file
    df.to_csv(output_file, sep='\t', index=False)
    
    print(f"GC content table has been written to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate GC content for sequences in a FASTA file.")
    parser.add_argument("input_file", help="Path to the input FASTA file")
    parser.add_argument("output_file", help="Path to the output tab-delimited file")
    
    args = parser.parse_args()
    main(args.input_file, args.output_file)
