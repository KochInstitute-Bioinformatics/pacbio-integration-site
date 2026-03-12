#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
 * PacBio HiFi Vector Alignment Pipeline
 * 
 * This workflow processes PacBio HiFi reads to:
 * 1. Run quality control with NanoPlot
 * 2. Align reads to a vector sequence
 * 3. Extract reads with vector hits
 * 4. Align vector-containing reads to mouse genome
 */

// Parameters
params.samplesheet = null
params.vector_fasta = null
params.genome_fasta = null
params.outdir = 'results'

/*
 * Parse samplesheet CSV
 */
def parseSamplesheet(samplesheet) {
    def lines = file(samplesheet).readLines()
    
    // Skip header and parse remaining lines
    def samples = lines.drop(1).collect { line ->
        def fields = line.split(',')
        if (fields.size() >= 2) {
            def sample = fields[0].trim()
            def fastq = fields[1].trim()
            return [sample, file(fastq)]
        }
        return null
    }.findAll { it != null }
    
    return samples
}

/*
 * Process: Run NanoPlot for quality control
 */
process NANOPLOT_QC {
    tag "${sample}"
    publishDir "${params.outdir}/qc/${sample}", mode: 'copy'
    
    input:
    tuple val(sample), path(fastq)
    
    output:
    tuple val(sample), path("${sample}_nanoplot"), emit: qc_results
    
    script:
    """
    mkdir -p ${sample}_nanoplot
    NanoPlot --fastq ${fastq} \
        --outdir ${sample}_nanoplot \
        --prefix ${sample}_ \
        --threads ${task.cpus}
    """
}

/*
 * Process: Align reads to vector sequence with minimap2
 * Filters to keep only primary mapped alignments (flags 0 and 16)
 * Excludes: flag 4 (unmapped), flag 256 (secondary), flag 2048 (supplementary)
 */
process ALIGN_TO_VECTOR {
    tag "${sample}"
    publishDir "${params.outdir}/vector_alignment/${sample}", mode: 'copy'
    
    input:
    tuple val(sample), path(fastq)
    path vector_fasta
    
    output:
    tuple val(sample), path("${sample}_vector.sorted.bam"), path("${sample}_vector.sorted.bam.bai"), emit: bam
    tuple val(sample), path(fastq), path("${sample}_vector.sorted.bam"), emit: for_extraction
    
    script:
    """
    # Align with minimap2, filter to exclude flags 4, 256, 2048
    # -F 4: exclude unmapped reads
    # -F 256: exclude secondary alignments
    # -F 2048: exclude supplementary alignments
    # This keeps only primary mapped alignments (flags 0 and 16)
    minimap2 -ax map-hifi ${vector_fasta} ${fastq} | \
        samtools view -F 4 -F 256 -F 2048 -bS - | \
        samtools sort -o ${sample}_vector.sorted.bam -
    samtools index ${sample}_vector.sorted.bam
    """
}

/*
 * Process: Extract reads that aligned to vector
 */
process EXTRACT_VECTOR_HITS {
    tag "${sample}"
    publishDir "${params.outdir}/vector_hits/${sample}", mode: 'copy'
    
    input:
    tuple val(sample), path(fastq), path(bam)
    
    output:
    tuple val(sample), path("vecHits_${sample}.fq.gz"), emit: vector_reads
    
    script:
    """
    # Get read IDs that aligned to vector (excluding unmapped reads)
    samtools view -F 4 ${bam} | cut -f1 | sort -u > aligned_read_ids.txt
    
    # Extract these reads from the original FASTQ
    python3 <<'EOF'
import gzip

# Read the aligned read IDs
aligned_ids = set()
with open('aligned_read_ids.txt', 'r') as f:
    for line in f:
        aligned_ids.add(line.strip())

# Extract reads from FASTQ
with gzip.open('${fastq}', 'rt') as fin, gzip.open('vecHits_${sample}.fq.gz', 'wt') as fout:
    while True:
        # Read FASTQ record (4 lines)
        header = fin.readline()
        if not header:
            break
        seq = fin.readline()
        plus = fin.readline()
        qual = fin.readline()
        
        # Extract read ID (remove @ and everything after first space)
        read_id = header[1:].split()[0].strip()
        
        # Write if this read aligned to vector
        if read_id in aligned_ids:
            fout.write(header)
            fout.write(seq)
            fout.write(plus)
            fout.write(qual)

print(f"Extracted {len(aligned_ids)} reads with vector hits")
EOF
    """
}

/*
 * Process: Align original FASTQ reads to mouse genome
 */
process ALIGN_ORIGINAL_TO_GENOME {
    tag "${sample}"
    publishDir "${params.outdir}/original_genome_alignment/${sample}", mode: 'copy'
    
    input:
    tuple val(sample), path(fastq)
    path genome_fasta
    
    output:
    tuple val(sample), path("${sample}_genome.sorted.bam"), path("${sample}_genome.sorted.bam.bai"), emit: genome_bam
    
    script:
    """
    minimap2 -ax map-hifi ${genome_fasta} ${fastq} | \
        samtools view -bS - | \
        samtools sort -o ${sample}_genome.sorted.bam -
    samtools index ${sample}_genome.sorted.bam
    """
}

/*
 * Process: Align vector-containing reads to mouse genome
 */
process ALIGN_TO_GENOME {
    tag "${sample}"
    publishDir "${params.outdir}/genome_alignment/${sample}", mode: 'copy'
    
    input:
    tuple val(sample), path(vector_reads)
    path genome_fasta
    
    output:
    tuple val(sample), path("vecHits_${sample}_genome.sorted.bam"), path("vecHits_${sample}_genome.sorted.bam.bai"), emit: genome_bam
    
    script:
    """
    minimap2 -ax map-hifi ${genome_fasta} ${vector_reads} | \
        samtools view -bS - | \
        samtools sort -o vecHits_${sample}_genome.sorted.bam -
    samtools index vecHits_${sample}_genome.sorted.bam
    """
}

/*
 * Main workflow
 */
workflow {
    main:
    // Validate required parameters
    if (!params.samplesheet) {
        error "Please provide a samplesheet with --samplesheet"
    }
    if (!params.vector_fasta) {
        error "Please provide a vector FASTA file with --vector_fasta"
    }
    if (!params.genome_fasta) {
        error "Please provide a genome FASTA file with --genome_fasta"
    }
    
    // Parse samplesheet
    def samples = parseSamplesheet(params.samplesheet)
    samples_ch = channel.fromList(samples)
    
    // Create file channels for reference files
    vector_fasta_ch = channel.fromPath(params.vector_fasta, checkIfExists: true)
    genome_fasta_ch = channel.fromPath(params.genome_fasta, checkIfExists: true)
    
    // Run QC
    NANOPLOT_QC(samples_ch)
    
    // Align original FASTQ to mouse genome
    ALIGN_ORIGINAL_TO_GENOME(samples_ch, genome_fasta_ch.first())
    
    // Align to vector
    ALIGN_TO_VECTOR(samples_ch, vector_fasta_ch.first())
    
    // Extract vector hits
    EXTRACT_VECTOR_HITS(ALIGN_TO_VECTOR.out.for_extraction)
    
    // Align vector hits to genome
    ALIGN_TO_GENOME(EXTRACT_VECTOR_HITS.out.vector_reads, genome_fasta_ch.first())
}