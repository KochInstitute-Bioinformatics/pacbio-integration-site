#!/bin/bash
#SBATCH -N 1                          # Number of nodes - always set -N 1
#SBATCH -n 1                          # Number of CPUs.
#SBATCH --mail-type=END               # Type of email notification- BEGIN,END,FAIL,ALL.
#SBATCH --mail-user=charliew@mit.edu  # Email for notifications

# Load required modules
module add miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate nf-core_Feb26
module add singularity/3.10.4

# Set Nextflow work directory
export NXF_WORK="/net/bmc-lab3/data/bcc/sp_work_dir/"

# Run the workflow with custom config
nextflow run main.nf \
    -c custom.config \
    --samplesheet samplesheet.csv \
    --vector_fasta /net/bmc-lab3/data/bcc/projects/tfal23-Knouse/PacBio_031126/ObLiGaRe_Seq_Data/vector/inducible_cas9.fasta \
    --genome_fasta /net/bmc-lab3/data/bcc/projects/tfal23-Knouse/PacBio_031126/ObLiGaRe_Seq_Data/genome/Mus_musculus.GRCm39.dna.primary_assembly.fa \
    --outdir results \
    -profile singularity \
    -resume

# To submit: sbatch submit.sh
