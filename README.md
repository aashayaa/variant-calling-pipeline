# Variant Calling Pipeline

This is a Snakemake pipeline I built to practice reproducible bioinformatics
workflows, the kind of thing that comes up in genomics labs but isn't
usually covered in intro coursework. It takes raw paired-end sequencing
reads and turns them into a list of genetic variants, going through quality
control, trimming, alignment, and variant calling along the way.

I used *E. coli* as the test organism since its genome is small ( around 4.6 Mb),
so the whole pipeline runs in a few minutes instead of hours. It's useful for
testing and debugging without burning a ton of time on every run.

## What it does
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
   
## Environment & Pipeline 

The pipeline runs in a conda environment I've named "varcallingpipeline," the components
of which I defined in `environment.yml`. Conda resolves and installs everything at once from 
that single file.

I'm using Snakemake to manage the workflow. The snakefile has each step defined clearly.
Although I used some help from AI to figure out how a Snakefile is actually meant to
be formatted, I wanted to write the script myself to develop a sense of this industry-
standard skill. Snakemake figures out the correct execution order itself through a
tool called a "dependency graph." `config.yaml` has the sample names and file paths. I
have done this to prevent hardcoding and possible reuse this code in a lab setting.

