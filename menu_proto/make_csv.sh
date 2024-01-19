#!/bin/bash

# Define the input file and the output CSV file
input_file="input.txt"
output_csv="output.csv"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file not found."
    exit 1
fi

# Create or clear the output CSV file
> "$output_csv"

# Read each line from the input file
while IFS= read -r line
do
    # Extract the last part of the line as the name
    name=$(echo "$line" | awk '{print $NF}' | awk -F'/' '{print $NF}')
    
    # The module_type is always 'exploit'
    module_type="exploit"

    # The full module name with 'exploit/' prefixed to it
    full_module_name="$(echo "$line" | awk '{print $2}')"

    # Write to the CSV file
    echo "$name, $module_type, $full_module_name" >> "$output_csv"
done < "$input_file"

echo "CSV file created: $output_csv"
