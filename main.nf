
def usage() {
    log.info"""

    Documentation

    // local: nextflow run main.nf -profile apple_silicon --reference NC_000913.3 --data ERR14841871
    // run from github: nextflow run theneti3/nf-pipeline  --reference NC_000913.3 --data "data/samples/*_R{1,2}.fq"

    OPTIONS
    --help
    --reference 
    --data 
    --out set to default folder "data-out"
    -profile [apple_silicon]
"""
}

// _______________________________
//         Parameters
// _______________________________

params.help = null
params.reference = null
params.data = null
// sets a default out directory
params.out = "data_out"

// _______________________________
//         Processes
// _______________________________

// Fetch genome reference
process fetch_reference {
    conda "bioconda::entrez-direct=24.0"

    input:
      val accession

    output:
      path "${accession}.fasta"

    script:
        """
        esearch -db nucleotide -query "$accession" \\
        | efetch -format fasta > "${accession}.fasta"
        """
    
}

// Fetch fastq files from SRA
process fetch_data {
    conda "bioconda::sra-tools=3.2.1"
    label "mem_&_threads"

    input:
        val accession

    output:
        tuple val(accession), path("raw_fastq_files/${accession}/*.fastq"), emit: fastq_files

    script:

        """
        mkdir -p raw_fastq_files
        fasterq-dump ${accession} \\
        --outdir ./raw_fastq_files/${accession} \\
        --split-files
        """
}

// Execute fastqc analysis on raw files
process fastqc{
    conda "bioconda::fastqc=0.12.1"
    label "mem_&_threads"
    
    input: 
        //val fastq_data
        tuple val(sample_id), path(reads)

    output:
        path "fastqc_reports", emit: reports

    script:
        //sample_id = sample_id[0]
        //read1 = sample_id[1][0]
        //read2 = sample_id[1][1]
    
        """
        mkdir -p fastqc_reports
        fastqc ${reads[0]} ${reads[1]} --outdir fastqc_reports
        """
}

// Execute fastp trimming on raw data
process fastp {
    conda "bioconda::fastp=1.1.0"
    
    input:
        val sample_data

    output:
        path "*.trimmed.fq.gz" , emit: sample_ID //tuple (val(sample_ID), path("*.trimmed.fq.gz)) suggested output name
        path "*.html" , emit: html_reports
        path "*.json" , emit: json_reports

    script:
        //unpack gz with groovey script
        // [sample_ID,[R1.R2]]
        
        sample_ID = sample_data[0]
        read1 = sample_data[1][0]
        read2 = sample_data[1][1]

        """
        fastp --in1 ${read1} --in2 ${read2} --out1 ${sample_ID}_R1.trimmed.fq.gz --out2 ${sample_ID}_R2.trimmed.fq.gz
        """
}

// Reporting
// Execute multiqc on raw data and trimmed data 

// _______________________________
//         Workflow
// _______________________________

workflow {
    if (params.help) {
        usage()
        exit 0
    }

    if (params.reference == null) {
        println ("Missing reference")
        exit 1
    }

    if (params.data == null) {
        println ("Missing data input")
        exit 1
    }

    // println("$params.reference, $params.data, $params.out")

    // def ch_input = channel.fromSRA(params.data, apiKey: "d5822ef54698cb072e0cf866736fd5f6ab08")
        
    def ch_input = fetch_data(params.data)

    def ch_reference = fetch_reference(params.reference)
        
    fastqc(ch_input)
        // | view

    fastp(ch_input)
        // | view  
}










 