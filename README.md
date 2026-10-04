# Variant Calling Pipeline

This is a Snakemake pipeline I built to practice reproducible bioinformatics
workflows — the kind of thing that comes up in genomics labs but isn't
usually covered in intro coursework. It takes raw paired-end sequencing
reads and turns them into a list of genetic variants, going through quality
control, trimming, alignment, and variant calling along the way.

I used *E. coli* as the test organism since its genome is small (~4.6 Mb),
so the whole pipeline runs in a few minutes instead of hours. It's useful for
testing and debugging without burning a ton of time on every run.
