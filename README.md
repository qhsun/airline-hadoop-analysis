# airline-hadoop-analysis

    # Analysis of the ASA Data Expo airline data using ahfoss/kamilaStreamingHadoop
    # package on [github](github.com). See the associated README file for that
    # package for more information including software dependencies.

    # To replicate the analysis, run the commands below.

## Analysis pipeline:

    # download and format the airline data
    sbatch download.slurm

    ## **Wait for batch job to terminate before executing next command.**

    # Clean data file and generate useful metadata
    sbatch preprocessing.slurm

    ## **Wait for batch job to terminate before executing next command.**

    # Run four differently seeded sets of KAMILA runs; each consists of four
    # random initializations and ten iterations.
    sbatch kamila1.slurm
    sbatch kamila2.slurm
    sbatch kamila3.slurm
    sbatch kamila4.slurm

    ## **Wait for batch jobs to terminate before executing next command.**

    # Generate a report on the clustering
    cd Rnw/
    # Modify JOBID variable in the section "User-Supplied Values" in
    # kamilaSummary.Rnw to be the SLURM job ID used in kamila.slurm.
    Rscript -e "require(knitr);knit('kamilaSummary.Rnw')"
    # (Document may be knit using Rnw/makeRnw.slurm instead.)
    pdflatex kamilaSummary.tex
    !!
    evince kamilaSummary.pdf &

