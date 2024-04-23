#!/bin/bash

# Specify the name of the combined output file
combined_output="combined_output.csv"

# Remove the existing combined output file, if it exists
rm -f "${combined_output}"

# Loop through each output file
for output_file in output*.csv; do
  echo "Processing ${output_file}"
  # Get the last line of the current output file and append it to the combined output
  tail -n 1 "${output_file}" >> "${combined_output}"
done

echo "Combined output created: ${combined_output}"

