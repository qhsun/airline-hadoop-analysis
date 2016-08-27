#!/bin/bash
#SBATCH --output=preprocessingResults-%J.out
#SBATCH --job-name=procJob
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --mail-user=ahfoss@buffalo.edu
#SBATCH --mail-type=ALL
##SBATCH --partition=debug
##SBATCH --time=00:50:00
#SBATCH --partition=general-compute
#SBATCH --time=70:50:00

echo
echo "Starting now..."
echo


#python py/my_preprocKamila.py
#python py/subsampleSqlData.py db/cat1987-2008_v1.db finalDataSet 2000 csv/subsampled_2000_cat1987-2008_v1_rmvna_norm_con.csv continuous
python py/preprocHL.py csv/cat1987-2008_v1.csv csv/cat1987-2008_v1_types.csv 3 6 7 8 10 11 13 20 21 22 23 24 25 26 27 28 29

echo "All done!"

# 1) Year,
# 2) Month,
# 3) DayofMonth,
# 4) DayOfWeek,
# 5) DepTime,
# 6) CRSDepTime,
# 7) ArrTime,
# 8) CRSArrTime,
# 9) UniqueCarrier,
# 10) FlightNum,
# 11) TailNum,
# 12) ActualElapsedTime,
# 13) CRSElapsedTime,
# 14) AirTime,
# 15) ArrDelay,
# 16) DepDelay,
# 17) Origin,
# 18) Dest,
# 19) Distance,
# 20) TaxiIn,
# 21) TaxiOut,
# 22) Cancelled,
# 23) CancellationCode,
# 24) Diverted,
# 25) CarrierDelay,
# 26) WeatherDelay,
# 27) NASDelay,
# 28) SecurityDelay,
# 29) LateAircraftDelay

