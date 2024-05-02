# Decentralized Control Strategies for Swarm Robotics in Predator-Prey Capture

## Overview:
This project focuses on developing and evaluating control software for a swarm of robots tasked with capturing a mobile intruder (prey) in a predator-prey scenario. The study explores the use of swarm intelligence and collective behavior to efficiently locate and immobilize the prey. Key objectives include understanding the scalability and locality properties of swarms and designing cooperative swarm robots.

## 						 PROJECT ROOT

		|-- Results/                            # Contains all results
  
		|    |-- locality/                    	# An example of file
		|    |    |--cam                        #
                |    |    |--range_and bearing          #
		|    |                                  #
                |    |-- Scalability                    #
                |    |                                  #
		|    |-- Statistics_analysis            #
		|-- build/             	                # An empty file
		|         
                |
		|-- predator.lua                 	# 
		|-- prey.lua                     	# 

		|-- lstm_train.py             	       	# Contains the definition of the forward and reverse train
		|-- preprocess.py                  	# LSTM to train a short sequence
		|-- main_short_term_prediction.ipynb	# Contains an example of execution and the analysis part 

		|-- ************************************************************************

## Instructions for Running the Project:
- Ensure that you have the necessary software and libraries installed as specified in the project documentation.
- Clone the project repository to your local machine.

Make sure you are in the project directory when executing this command.
  
### 1. Exécution d'une simulation :
To run a single simulation, use the following command: `argos3 -c predatorprey.argos`

### 2. Running Multiple Simulations:
If you want to run 100 simulations, use the `run_experiments.sh` script. Before running the script, please follow these steps:
1. Ensure visualization is turned off the visualization by modifying the visualization section in the `predatorprey.argos` configuration file. Replace it with:
```xml
<visualization />
```
2. Run the run_experiments.sh script using the following command: `./run_experiments.sh`
## Getting Started:
To get started with the project, follow these steps:
1. Clone the repository: `git clone <repository_url>`
2. Create an empty folder and name it build
3. Install the required dependencies and software as specified in the project documentation.
4. Run the simulations using the provided control software.
5. Analyze the results and refer to the README for insights and conclusions drawn from the experiments.

## Contact:
For questions or inquiries about the project, please contact:
- Ndinga Oba Olivier: [obavertu@gmail.com](mailto:obavertu@gmail.com) 

Feel free to reach out with any questions, feedback, or suggestions regarding the project. Thank you for your interest!
