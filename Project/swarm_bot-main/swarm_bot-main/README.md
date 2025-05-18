# Constrained Foraging - INFO-H-414 Final Project

This folder contains all necessary code, configuration files, and results for the report:

> **Scalable and Flexible Swarm Robotics for Constrained Foraging in ARGoS.pdf**

It is **strongly advised** to read the article first before diving into the code, as it explains the overall architecture, experimental design, and rationale behind key implementation choices.


## Contents

| File                          | Description                                                  |
|------------------------------|--------------------------------------------------------------|
| `swarm.lua`                  | Lua script implementing the **Swarm-Bot** paradigm           |
| `individuals.lua`            | Lua script implementing the **Indi-Bot** paradigm            |
| `foraging_s*.argos`          | ARGoS experiment files for running batch experiments         |
| `gui_foraging_*.argos`       | ARGoS experiment files for running GUI simulations manually  |
| `i_foraging_s1.argos`        | Variant of `foraging_s1.argos` using `individuals.lua`       |
| `run.sh`                     | Bash script that runs all 530 simulations and saves results  |
| `results_flexibility_scalability/scores.csv` | Output file with all recorded simulation scores         |
| `Scalable and Flexible Swarm Robotics for Constrained Foraging in ARGoS.pdf` | Project report explaining everything |


## How to Run the Simulations

> **Note:** This project was developed and tested under **WSL2 / Ubuntu on Windows 10**.  
> The **ARGoS simulator itself is not included** in this folder - it must be installed separately.

### Batch Experiments (540 simulations)

The script `run.sh` automates all runs for:
- **Scalability** tests with robot counts from 2 to 50
- **Flexibility** tests on 4 different scenarios

It is **resumable**: any result already recorded in `scores.csv` will be skipped.

> To re-run all experiments **from scratch**, delete the results file first:

```bash
rm results_flexibility_scalability/scores.csv
````

Then make the script executable and run it:

```bash
chmod +x run.sh
./run.sh
```

### GUI Visualization (manual runs)

The batch `.argos` files are designed for headless execution.
To explore a specific configuration **with the GUI**, run instead a `gui_*.argos` file:

```bash
argos3 -c gui_foraging_s1.argos
```

This will launch the ARGoS graphical simulator with the specified settings.

## Where to Find Results

All results (score per run, scenario, and seed) are logged to:

```
results_flexibility_scalability/scores.csv
```

This file is updated by `run.sh` after each simulation. It is read by the plotting scripts referenced in the report to produce all evaluation graphs.


## Final Notes

* This folder **does not require GitHub access** - all files mentioned in the article are included here. The originally referenced GitHub repository has been made private.
* You can modify or add `.argos` files to design your own experiments. Just make sure to update the controller used (`swarm.lua` or `individuals.lua`) and relevant robot counts accordingly.
* The `swarm_bot_constrained_foraging.mp4` video shows a live execution of Swarm-Bot with 10 robots, using `gui_foraging_s1.argos` and random seed 6526.
