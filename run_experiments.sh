#!/bin/bash

# Loop through 100 experiments
for ((i = 1; i <= 100; i++)); do
  # Run ARGoS with the configuration file
  argos3 -c predatorprey.argos

  # Wait for ARGoS to generate the output file
  sleep 5

  # Find the generated output file and rename it
  generated_output_file=$(find . -maxdepth 1 -name 'output.csv' -print -quit)
  mv "${generated_output_file}" "output${i}.csv"

  # Optional: Add a delay if needed between experiments
  # sleep 1
done

