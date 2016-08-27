#!/bin/bash
#SBATCH --output=downloadResults-%J.out
#SBATCH --job-name=downL
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --partition=debug
#SBATCH --time=00:50:00

FINALDATA="csv/cat1987-2008_v1.csv"

# test with subset
#for year in {1987..1990}
for year in {1987..2008}
do
  wget -O csv/orig/"$year".csv.bz2 stat-computing.org/dataexpo/2009/"$year".csv.bz2
done

echo
echo "Extract all data."
bzip2 -dvk csv/orig/????.csv.bz2

echo
echo "Move over data to extracted directory."
mv -v csv/orig/????.csv csv/extracted/

echo
echo "Initialize data file with header."
head -n 1 csv/extracted/1987.csv > $FINALDATA

echo
echo "Concatenate all extracted data,"
echo "Drop header rows"
tail -q -n +2 csv/extracted/????.csv >> $FINALDATA

echo
echo "Done!"
echo
