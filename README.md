# Decentralized Control Strategies for Swarm Robotics in Predator-Prey Capture

## Overview:
This project focuses on developing and evaluating control software for a swarm of robots tasked with capturing a mobile intruder (prey) in a predator-prey scenario. The study explores the use of swarm intelligence and collective behavior to efficiently locate and immobilize the prey. Key objectives include understanding the scalability and locality properties of swarms and designing cooperative swarm robots.

## PROJECT ROOT

                    |-- Results/                             # Directory containing all project results
                    |   |-- locality/                        # Directory for locality results
                    |   |   |-- cam/                         # Directory for camera-related results
                    |   |   |-- range_and_bearing/           # Directory for range and bearing results
                    |   |
                    |   |-- Scalability/                     # Directory for scalability results
                    |   |
                    |   |-- Statistics_analysis/             # Directory for statistical analysis results
                    |
                    |-- build/                               # Directory for build-related files
                    |-- src/                                 # Directory for source code
                    | 
                    |-- predator.lua                         # Lua script for predator behavior
                    |-- prey.lua                             # Lua script for prey behavior
                    |
                    |-- Project description.pdf              # Project description document
                    |-- instable_state_seed_88852.mp4        # Video demonstrating an unstable state
                    |-- Paper.pdf                            # My research paper for this project
                    |-- Futurwork.pdf                        # Additional document extending project
                    |-- build.sh                             # Script for building the project
                    |-- combine_outputs.sh                   # Script for combining project outputs
                    |-- run_experiments.sh                   # Script for running project experiments
                    |-- ************************************************************************


## Instructions for Running the Project:
- Ensure that you have the necessary software and libraries installed as specified in the project description file.
- Clone the project repository to your local machine.

Make sure you are in the project directory when executing this command.
  
### 1. Running Single Simulation :
To run a single simulation, use the following command: `argos3 -c predatorprey.argos`

### 2. Running Multiple Simulations:
If you want to run 100 simulations, use the `run_experiments.sh` script. Before running the script, please follow these steps:
1. Ensure visualization is turned off the visualization by modifying the visualization section in the `predatorprey.argos` configuration file. Replace it with:
```xml
<visualization />
```
2. Run the run_experiments.sh script using the following command: `./run_experiments.sh`
3. Next, run the combine_output.sh script to combine the latest line from all outputs, using the following command: `./combine_output.sh`
   
## Contact:
For questions or inquiries about the project, please contact:
- Ndinga Oba Olivier: [obavertu@gmail.com](mailto:obavertu@gmail.com) 

Feel free to reach out with any questions, feedback, or suggestions regarding the project. Thank you for your interest!
