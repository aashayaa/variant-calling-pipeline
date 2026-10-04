# Variant Calling Pipeline

This is a Snakemake pipeline I built to practice reproducible bioinformatics
workflows — the kind of thing that comes up in genomics labs but isn't
usually covered in intro coursework. It takes raw paired-end sequencing
reads and turns them into a list of genetic variants, going through quality
control, trimming, alignment, and variant calling along the way.

I used *E. coli* as the test organism since its genome is small (~4.6 Mb),
so the whole pipeline runs in a few minutes instead of hours. It's useful for
testing and debugging without burning a ton of time on every run.

## What it does, step by step
(dag.png)
1. **FastQC** on the raw reads, just checking what the data actually
   looks like before doing anything to it
2. **fastp** trims low-quality bases and adapter sequences
3. **BWA** Burrow-Wheeler Algorithm indexes reference genome, then aligns
   the trimmed reads to it
4. **samtools** sorts and indexes the resulting alignment file; Sequence Alignment Map format
5. **bcftools** calls variants (positions where the sample differs from
   the reference) and then filters out low-confidence calls - Binary Call Format tools
6. A small summary step reports the alignment rate and how many variants
   passed filtering
