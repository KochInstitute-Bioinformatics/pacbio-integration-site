# PacBio Integration Site Analysis Pipeline

A Nextflow DSL2 workflow for analyzing PacBio HiFi reads to identify vector integration sites in genomes.

## Overview

This pipeline processes PacBio HiFi sequencing data to:

1. **Quality Control**: Generate comprehensive QC reports using NanoPlot
2. **Vector Alignment**: Align reads to a vector sequence using minimap2
3. **Hit Extraction**: Identify and extract reads containing vector sequences
4. **Genome Alignment**: Align vector-containing reads to a reference genome for integration site identification

## Pipeline Workflow

```
PacBio HiFi Reads (FASTQ)
    ↓
┌───────────────────┐
│  NANOPLOT_QC      │ → QC Reports
└───────────────────┘
    ↓
┌───────────────────┐
│ ALIGN_TO_VECTOR   │ → vector.sorted.bam + .bai
└───────────────────┘
    ↓
┌───────────────────┐
│ EXTRACT_VECTOR    │ → vecHits_*.fq.gz
│      HITS         │
└───────────────────┘
    ↓
┌───────────────────┐
│ ALIGN_TO_GENOME   │ → vecHits_*_genome.sorted.bam + .bai
└───────────────────┘
```

## Requirements

- Nextflow >= 23.04.0
- Singularity or Docker
- One of the following execution environments:
  - Local machine with Docker
  - HPC cluster with SLURM and Singularity

### Software (containerized)

- **NanoPlot**: Quality control (`bumproo/nanoplotchopper`)
- **minimap2**: Read alignment
- **samtools**: BAM file manipulation
- **Python3**: Read extraction (`bumproo/general_genomics`)

## Installation

```bash
# Clone the repository
git clone https://github.com/KochInstitute-Bioinformatics/pacbio-integration-site.git
cd pacbio-integration-site

# No additional installation required - all software is containerized
```

## Quick Start

### 1. Prepare Your Samplesheet

Create a CSV file (`samplesheet.csv`) with your samples:

```csv
sample,fastq
sample1,/path/to/sample1.fq.gz
sample2,/path/to/sample2.fq.gz
sample3,/path/to/sample3.fq.gz
```

### 2. Run on SLURM Cluster (Recommended)

```bash
# Edit custom.config to set your paths
# Edit submit.sh to set your email and paths

# Submit to SLURM
sbatch submit.sh
```

### 3. Run Locally with Docker

```bash
nextflow run main.nf \
    --samplesheet samplesheet.csv \
    --vector_fasta /path/to/vector.fasta \
    --genome_fasta /path/to/genome.fasta \
    --outdir results \
    -profile docker \
    -resume
```

## Configuration

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `--samplesheet` | CSV file with sample names and FASTQ paths |
| `--vector_fasta` | FASTA file containing the vector sequence |
| `--genome_fasta` | Reference genome FASTA file |
| `--outdir` | Output directory (default: `results`) |

### Example Command

```bash
nextflow run main.nf \
    --samplesheet samplesheet.csv \
    --vector_fasta /data/vectors/inducible_cas9.fasta \
    --genome_fasta /data/genomes/Mus_musculus.GRCm39.dna.primary_assembly.fa \
    --outdir my_analysis \
    -profile singularity \
    -c custom.config \
    -resume
```

## SLURM Configuration

The pipeline includes optimized SLURM settings in `custom.config`:

- **Queue**: `bcc` (modify for your cluster)
- **QC**: 4 CPUs, 8 GB RAM, 2 hours
- **Vector Alignment**: 8 CPUs, 16 GB RAM, 4 hours
- **Extraction**: 2 CPUs, 8 GB RAM, 2 hours
- **Genome Alignment**: 8 CPUs, 32 GB RAM, 8 hours

Edit `custom.config` to customize for your cluster.

## Output Structure

```
results/
├── qc/
│   ├── sample1/
│   │   └── sample1_nanoplot/
│   ├── sample2/
│   └── sample3/
├── vector_alignment/
│   ├── sample1_vector.sorted.bam
│   ├── sample1_vector.sorted.bam.bai
│   └── ...
├── vector_hits/
│   ├── vecHits_sample1.fq.gz
│   └── ...
├── genome_alignment/
│   ├── vecHits_sample1_genome.sorted.bam
│   ├── vecHits_sample1_genome.sorted.bam.bai
│   └── ...
└── pipeline_info/
    ├── execution_report.html
    ├── execution_timeline.html
    ├── execution_trace.txt
    └── pipeline_dag.svg
```

## Output Files

### QC Reports (`qc/`)
- **NanoPlot HTML reports**: Interactive quality metrics
- **Statistics**: Read length distribution, quality scores, etc.

### Vector Alignment (`vector_alignment/`)
- **Sorted BAM files**: Reads aligned to vector
- **BAI index files**: For visualization in IGV

### Vector Hits (`vector_hits/`)
- **FASTQ files**: Reads that aligned to the vector sequence
- **Prefix**: `vecHits_[sample].fq.gz`

### Genome Alignment (`genome_alignment/`)
- **Sorted BAM files**: Vector-containing reads aligned to genome
- **BAI index files**: Ready for IGV visualization
- **Use these files to identify integration sites**

## Analyzing Results

### View in IGV

1. Load the reference genome in IGV
2. Load BAM files from `genome_alignment/`
3. Look for:
   - Reads spanning vector-genome junctions
   - Clusters of reads at integration sites
   - Split reads indicating breakpoints

### Integration Site Identification

Reads in the genome alignment BAM files represent potential integration sites:
- **Clustered reads**: Likely integration events
- **Split alignments**: Precise breakpoint locations
- **Coverage patterns**: Copy number at integration sites

## Troubleshooting

### Pipeline Fails to Start
- Check that all input files exist
- Verify Singularity cache directory permissions
- Ensure SLURM queue name is correct in `custom.config`

### Out of Memory Errors
- Increase memory in `custom.config` for specific processes
- Check `max_memory` parameter

### Container Pull Issues
- Set longer timeout: `pullTimeout = '120m'` in `custom.config`
- Check network connectivity
- Verify Singularity cache directory has space

### Resume from Failure
Always use `-resume` flag to restart from the last successful step:
```bash
nextflow run main.nf -c custom.config -resume
```

## Advanced Usage

### Custom Containers

To use different containers, edit `nextflow.config`:

```groovy
withName: 'NANOPLOT_QC' {
    container = 'your/custom-container:tag'
}
```

### Modify Resources

Edit `custom.config` to adjust CPU/memory/time per process:

```groovy
withName: 'ALIGN_TO_GENOME' {
    cpus = 16
    memory = '64.GB'
    time = '12.h'
}
```

## Citation

If you use this pipeline, please cite:

- **Nextflow**: Di Tommaso, P., et al. (2017). Nextflow enables reproducible computational workflows. Nature Biotechnology.
- **minimap2**: Li, H. (2018). Minimap2: pairwise alignment for nucleotide sequences. Bioinformatics.
- **NanoPlot**: De Coster, W., et al. (2018). NanoPack: visualizing and processing long-read sequencing data. Bioinformatics.

## License

MIT License - see LICENSE file for details

## Contact

For questions or issues, please open an issue on GitHub or contact the Koch Institute Bioinformatics team.

## Version

**v1.0.0** - Initial release
