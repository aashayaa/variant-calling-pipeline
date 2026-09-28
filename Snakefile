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
        r1 = config["rawdir"] + "/{sample}_1.fastq", #path avoid hardcoding
        r2 = config["rawdir"] + "/{sample}_2.fastq"
    output:
        html1 = config["resultsdir"] + "/fastqc/{sample}_1_fastqc.html", #output path
        html2 = config["resultsdir"] + "/fastqc/{sample}_2_fastqc.html"
    shell:
        "fastqc {input.r1} {input.r2} -o " + config["resultsdir"] + "/fastqc/"

rule fastptrimming:
    input:
        r1 = config["rawdir"] + "/{sample}_1.fastq",
        r2 = config["rawdir"] + "/{sample}_2.fastq"
    output:
        r1_trimmed = config["trimmeddir"] + "/{sample}_1.trim.fastq",
        r2_trimmed = config["trimmeddir"] + "/{sample}_2.trim.fastq"
    shell:
        "fastp -i {input.r1} -I {input.r2} -o {output.r1_trimmed} -O {output.r2_trimmed}"

rule bwa_index:
    input:
        ref = config["refdir"] + "/ecoli_ref.fna"
    output:
        config["refdir"] + "/ecoli_ref.fna.bwt"
    shell:
        "bwa index {input.ref}"

rule bwa_mem:
    input: 
        reference = config["refdir"] + "/ecoli_ref.fna",
        index = config["refdir"] + "/ecoli_ref.fna.bwt",
        r1_trimmed = config["trimmeddir"] + "/{sample}_1.trim.fastq",
        r2_trimmed = config["trimmeddir"] + "/{sample}_2.trim.fastq"
    output:
        config["resultsdir"] + "/aligned/{sample}.aligned_reads.sam"
    shell:
        "bwa mem -t 4 {input.reference} {input.r1_trimmed} {input.r2_trimmed} > {output}"

rule sam_to_bam:
    input:
        sam = config["resultsdir"] + "/aligned/{sample}.aligned_reads.sam"
    output:
        bam = config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam"
    shell:
        "samtools sort -o {output.bam} {input.sam}"
rule index_bam:
    input:
        bam = config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam"
    output:
        bai = config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam.bai"
    shell:
        "samtools index {input.bam}"

rule variant_calling:
    input:
        ref = config["refdir"] + "/ecoli_ref.fna",
        bam = config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam",
        bai = config["resultsdir"] + "/aligned/bam/{sample}.sorted.bam.bai"
    output:
        vcf = config["vcfdir"] + "/{sample}.raw.vcf"
    shell:
        "bcftools mpileup -f {input.ref} {input.bam} | "
        "bcftools call -mv -Ov -o {output.vcf}"

rule filter_variants:
    input:
        vcf = config["vcfdir"] + "/{sample}.raw.vcf"
    output:
        vcf = config["vcfdir"] + "/{sample}.filtered.vcf"
    shell:
        "bcftools filter -e 'QUAL<20 || DP<10' {input.vcf} -o {output.vcf}"
