#!/bin/bash
#SBATCH --output=makeRnwResults-%J.out
#SBATCH --job-name=rnwJob
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
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

