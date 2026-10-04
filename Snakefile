configfile: "config.yaml"
rule all:
    input:
        expand(config["resultsdir"] + "/fastqc/{sample}_1_fastqc.html", sample=config["sample"]),
        expand(config["resultsdir"] + "/fastqc/{sample}_2_fastqc.html", sample=config["sample"]),
        expand(config["trimmeddir"] + "/{sample}_1.trim.fastq", sample=config["sample"]),
        expand(config["trimmeddir"] + "/{sample}_2.trim.fastq", sample=config["sample"]),
        expand(config["resultsdir"] + "/aligned/{sample}.aligned_reads.sam", sample=config["sample"]),
        expand(config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam", sample=config["sample"]),
        expand(config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam.bai", sample=config["sample"]),
        expand(config["vcfdir"] + "/{sample}.filtered.vcf", sample=config["sample"])

rule fastqc_raw:
    input:
        r1 = config["rawdir"] + "/{sample}_1.fastq",
        r2 = config["rawdir"] + "/{sample}_2.fastq"
    output:
        html1 = config["resultsdir"] + "/fastqc/{sample}_1_fastqc.html",
        html2 = config["resultsdir"] + "/fastqc/{sample}_2_fastqc.html"
    log:
        "logs/fastqc_raw/{sample}.log"
    threads: 2
    shell:
        "fastqc {input.r1} {input.r2} -t {threads} -o " + config["resultsdir"] + "/fastqc/ 2> {log}"

rule fastptrimming:
    input:
        r1 = config["rawdir"] + "/{sample}_1.fastq",
        r2 = config["rawdir"] + "/{sample}_2.fastq"
    output:
        r1_trimmed = config["trimmeddir"] + "/{sample}_1.trim.fastq",
        r2_trimmed = config["trimmeddir"] + "/{sample}_2.trim.fastq"
    log:
        "logs/fastp/{sample}.log"
    threads: 2
    shell:
        "fastp -i {input.r1} -I {input.r2} "
        "-o {output.r1_trimmed} -O {output.r2_trimmed} "
        "-w {threads} 2> {log}"

rule bwa_index:
    input:
        ref = config["refdir"] + "/ecoli_ref.fna"
    output:
        config["refdir"] + "/ecoli_ref.fna.bwt"
    log:
        "logs/bwa_index/index.log"
    shell:
        "bwa index {input.ref} 2> {log}"

rule bwa_mem:
    input: 
        reference = config["refdir"] + "/ecoli_ref.fna",
        index = config["refdir"] + "/ecoli_ref.fna.bwt",
        r1_trimmed = config["trimmeddir"] + "/{sample}_1.trim.fastq",
        r2_trimmed = config["trimmeddir"] + "/{sample}_2.trim.fastq"
    output:
        config["resultsdir"] + "/aligned/{sample}.aligned_reads.sam"
    log:
        "logs/bwa_mem/{sample}.log"
    threads: 4
    shell:
        "bwa mem -t {threads} {input.reference} {input.r1_trimmed} {input.r2_trimmed} "
        "> {output} 2> {log}"

rule sam_to_bam:
    input:
        sam = config["resultsdir"] + "/aligned/{sample}.aligned_reads.sam"
    output:
        bam = config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam"
    log:
        "logs/sam_to_bam/{sample}.log"
    threads: 2
    shell:
        "samtools sort -@ {threads} -o {output.bam} {input.sam} 2> {log}"
rule index_bam:
    input:
        bam = config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam"
    output:
        bai = config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam.bai"
    log:
        "logs/index_bam/{sample}.log"
    shell:
        "samtools index {input.bam} 2> {log}"

rule variant_calling:
    input:
        ref = config["refdir"] + "/ecoli_ref.fna",
        bam = config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam",
        bai = config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam.bai"
    output:
        vcf = config["vcfdir"] + "/{sample}.raw.vcf"
    log:
        "logs/variant_calling/{sample}.log"
    shell:
        "bcftools mpileup -f {input.ref} {input.bam} 2> {log} | "
        "bcftools call -mv -Ov -o {output.vcf} 2>> {log}"

rule filter_variants:
    input:
        vcf = config["vcfdir"] + "/{sample}.raw.vcf"
    output:
        vcf = config["vcfdir"] + "/{sample}.filtered.vcf"
    log:
        "logs/filter_variants/{sample}.log"
    shell:
        "bcftools filter -e 'QUAL<20 || DP<10' {input.vcf} -o {output.vcf} 2> {log}"
