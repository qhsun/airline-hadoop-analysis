#!/bin/bash
#SBATCH --output=preprocessingResults-%J.out
#SBATCH --job-name=procJob
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --partition=debug
#SBATCH --time=00:50:00

echo
echo "Starting now..."
echo


python py/preprocKamila.py
python py/subsampleSqlData.py db/cat1987-2008_v1.db finalDataSet 2000 csv/subsampled_2000_cat1987-2008_v1_rmvna_norm_con.csv continuous

echo "All done!"

