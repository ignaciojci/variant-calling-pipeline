#!/bin/bash

# Input .fai file
fai_file=$ref.fai

# Output intervals file
output_file="/users/PAS1286/jignacio/projects/pm/data/843B-2Mbp-intervals.txt"

# Interval size in base pairs
interval_size=2000000

# Create or clear the output file
> $output_file

# Read the .fai file line by line
while IFS=$'\t' read -r name length offset linebases linewidth; do
    # Initialize the start position
    start=1

    # Loop to create intervals
    while [ $start -le $length ]; do
        # Calculate the stop position
        stop=$((start + interval_size - 1))

        # Ensure the stop position does not exceed the chromosome length
        if [ $stop -gt $length ]; then
            stop=$length
        fi

        # Write the interval to the output file
        echo "${name}:${start}-${stop}" >> $output_file

        # Move to the next interval
        start=$((stop + 1))
    done
done < $fai_file

echo "Intervals of 2,000,000 base pairs generated in $output_file"
