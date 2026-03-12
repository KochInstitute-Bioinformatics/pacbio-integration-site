#!/bin/bash

# Example command to run the PacBio HiFi Vector Alignment Pipeline locally with Docker

nextflow run main.nf \
    --samplesheet samplesheet.csv \
    --vector_fasta /net/bmc-lab3/data/bcc/projects/tfal23-Knouse/PacBio_031126/ObLiGaRe_Seq_Data/vector/inducible_cas9.fasta \
    --genome_fasta /net/bmc-lab3/data/bcc/projects/tfal23-Knouse/PacBio_031126/ObLiGaRe_Seq_Data/genome/Mus_musculus.GRCm39.dna.primary_assembly.fa \
    --outdir results \
    -profile docker \
    -resume

# For SLURM cluster execution, use: sbatch submit.sh
# For custom configuration: nextflow run main.nf -c custom.config ...
