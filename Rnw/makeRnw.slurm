#!/bin/bash
#SBATCH --output=preprocessingResults-%J.out
#SBATCH --job-name=procJob
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --mail-user=ahfoss@buffalo.edu
#SBATCH --mail-type=ALL
#SBATCH --partition=debug
#SBATCH --time=00:55:00
##SBATCH --partition=general-compute
##SBATCH --time=70:50:00

echo
echo "Starting now..."
echo

module load R/3.2.0
Rscript -e "require(knitr);knit('kamilaSummary.Rnw')"

echo "All done!"

