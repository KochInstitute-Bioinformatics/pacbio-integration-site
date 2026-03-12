# PacBio Integration Site Pipeline - Setup Complete ✅

## What's Been Created

Your complete Nextflow pipeline is ready for GitHub! Here's what you have:

### Core Pipeline Files
- ✅ **main.nf** - Main Nextflow workflow (passes `nextflow lint`)
- ✅ **nextflow.config** - Default configuration with Docker/Singularity profiles
- ✅ **custom.config** - SLURM-specific configuration for your cluster

### Execution Scripts
- ✅ **submit.sh** - SLURM submission script (ready to use with `sbatch`)
- ✅ **run_example.sh** - Local execution example with Docker

### Data Files
- ✅ **samplesheet.csv** - Example samplesheet with your 4 samples

### Documentation
- ✅ **README.md** - Complete documentation with usage examples
- ✅ **GITHUB_SETUP.md** - Step-by-step GitHub repository setup
- ✅ **LICENSE** - MIT License
- ✅ **.gitignore** - Git ignore patterns for Nextflow projects

## Key Changes Made

### 1. Container Configuration ✨
- **NANOPLOT_QC** now uses `bumproo/nanoplotchopper`
- Other processes use `bumproo/general_genomics`
- Containers are specified per-process in `nextflow.config`

### 2. SLURM Configuration 🖥️
- `custom.config` configured for your cluster:
  - Queue: `bcc`
  - Singularity cache: `/net/bmc-lab3/data/bcc/charliew/.singularity_cache`
  - Optimized resources per process
  - Execution reports in `results/pipeline_info/`

### 3. Submission Script 📝
- `submit.sh` ready for your SLURM cluster
- Loads required modules (miniconda3, singularity)
- Activates `nf-core_Feb26` conda environment
- Sets work directory to `/net/bmc-lab3/data/bcc/sp_work_dir/`

## Next Steps to Create GitHub Repository

### Quick Setup (Copy & Paste)

```bash
# 1. Initialize repository
git init
git add .
git commit -m "Initial commit: PacBio integration site analysis pipeline"

# 2. Create repository on GitHub
# Go to: https://github.com/KochInstitute-Bioinformatics
# Click "New" → Name: "pacbio-integration-site" → Create (don't initialize)

# 3. Connect and push
git remote add origin https://github.com/KochInstitute-Bioinformatics/pacbio-integration-site.git
git branch -M main
git push -u origin main
```

See **GITHUB_SETUP.md** for detailed instructions!

## How to Use on Your Cluster

### Option 1: Submit to SLURM (Recommended)

```bash
# 1. Edit custom.config (if needed - paths, email, etc.)
# 2. Edit submit.sh (set your email, adjust paths)
# 3. Submit the job
sbatch submit.sh
```

### Option 2: Interactive Run

```bash
# Load modules
module add miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate nf-core_Feb26
module add singularity/3.10.4

# Set work directory
export NXF_WORK="/net/bmc-lab3/data/bcc/sp_work_dir/"

# Run pipeline
nextflow run main.nf \
    -c custom.config \
    --samplesheet samplesheet.csv \
    --vector_fasta /path/to/vector.fasta \
    --genome_fasta /path/to/genome.fasta \
    --outdir results \
    -profile singularity \
    -resume
```

## Pipeline Overview

### Workflow Steps
1. **Quality Control** (NanoPlot) → `results/qc/`
2. **Vector Alignment** (minimap2 + samtools) → `results/vector_alignment/`
3. **Extract Vector Hits** (Python script) → `results/vector_hits/`
4. **Genome Alignment** (minimap2 + samtools) → `results/genome_alignment/`

### Output Files
- **QC Reports**: HTML reports with read statistics
- **Vector BAMs**: Reads aligned to vector (sorted, indexed)
- **Vector Hits**: FASTQ files with reads containing vector sequences (`vecHits_*.fq.gz`)
- **Genome BAMs**: Vector-containing reads aligned to genome (IGV-ready!)

## Configuration Files Explained

### nextflow.config (Default)
- Contains base configuration
- Defines container images per process
- Sets default resource allocations
- Good for Docker/local runs

### custom.config (Your Cluster)
- Overrides settings for SLURM
- Singularity configuration
- Cluster-specific paths
- Use with: `-c custom.config`

**Priority**: Command line > custom.config > nextflow.config

## Verification Checklist

Before pushing to GitHub:

- ✅ Pipeline passes `nextflow lint`
- ✅ All required files present
- ✅ Documentation complete
- ✅ Example files included
- ✅ Proper .gitignore configured
- ✅ License file included

## Testing the Pipeline

Before running on all samples, test with one:

```bash
# Create test samplesheet
echo "sample,fastq" > test.csv
echo "bc2085,/net/bmc-lab3/data/bcc/projects/tfal23-Knouse/PacBio_031126/ObLiGaRe_Seq_Data/data/bc2085.fq.gz" >> test.csv

# Run with test data
nextflow run main.nf \
    -c custom.config \
    --samplesheet test.csv \
    --vector_fasta /net/bmc-lab3/data/bcc/projects/tfal23-Knouse/PacBio_031126/ObLiGaRe_Seq_Data/vector/inducible_cas9.fasta \
    --genome_fasta /net/bmc-lab3/data/bcc/projects/tfal23-Knouse/PacBio_031126/ObLiGaRe_Seq_Data/genome/Mus_musculus.GRCm39.dna.primary_assembly.fa \
    --outdir test_results \
    -profile singularity
```

## Support

- **Documentation**: See README.md
- **GitHub Setup**: See GITHUB_SETUP.md
- **Issues**: Open an issue on GitHub after setup

## Summary

🎉 **Your pipeline is production-ready!**

- Modern Nextflow DSL2 syntax
- Lint-validated code
- Optimized for your SLURM cluster
- Comprehensive documentation
- Ready for version control

Follow the instructions in **GITHUB_SETUP.md** to create your repository and start tracking changes!
