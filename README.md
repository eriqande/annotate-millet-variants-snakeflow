annotate-millet-variants-snakeflow
================

This is a little Snakemake workflow to annotate some variants from pearl
millet. This task came up during a bioinformatics course, BZ582A, at CSU
in the spring of 2022. SnpEff is pretty easy to use when there is a
precompiled data base for your organism. It is a little clunkier when
you need to build a data base from a GFF. This shows one approach to
that. (Note that it would probably be good to check the results by
comparing them to some coding sequences, which we have not done here,
yet).

The purpose of this little workflow is to demonstrate how a Snakefile
can be put together for this task, and also to show how to use a SLURM
profile derived from jdblischak’s
[smk-simple-slurm](https://github.com/jdblischak/smk-simple-slurm)
profile. The profile included in the repository at
`/hpcc-profiles/slurm-summit` is tailored to the SUMMIT supercomputer.

Here is a DAG of this workflow, condensed using
[SnakemakeDagR](https://github.com/eriqande/SnakemakeDagR):
![](README_figures/amvs.svg)<!-- -->

To try this out on SUMMIT:

1.  From `scompile` clone this repository from GitHub into your scratch
    directory.

``` sh
git clone https://github.com/eriqande/annotate-millet-variants-snakeflow.git
```

2.  Then, on the `scompile` node, first do a dry run:

``` sh
cd annotate-millet-variants-snakeflow
conda activate snakemake
snakemake -np 
```

The output of that should include a jobs table that looks like this:

    Job stats:
    job                         count    min threads    max threads
    ------------------------  -------  -------------  -------------
    add_to_snpeff_config            1              1              1
    all                             1              1              1
    annotate_each_chromosome        7              1              1
    build_snpeff_database           1              1              1
    catenate_anno_chroms            1              1              1
    convert_to_vcf                  7              1              1
    download_genome                 1              1              1
    download_genotype_readme        1              1              1
    download_genotypes              7              1              1
    download_gff                    1              1              1
    headerize_vcfs                  7              1              1
    make_fai                        1              1              1
    total                          36              1              1

3.  Use this line to install the conda environments:

``` sh
snakemake --use-conda --conda-create-envs-only --cores 1
```

4.  Now, we will just have Snakemake launch each job on SLURM using
    `sbatch`, by way of the slurm profile (except for the rules marked
    as `localrules` at the top of the snakefile—those rules, which are
    simple text manipulations or downloads, will be run locally on
    `scompile`.) Make sure you do this next step in a tmux session on
    `scompile`, because this has to keep running, even after you log
    off.

``` sh
snakemake  --profile hpcc-profiles/slurm-summit
```

While these things are running or are in the SLURM queue you can see
them, by opening up another shell (with tmux, for example) and doing
this::

``` sh
squeue -u $(whoami) -o "%.12i %.9P %.50j %.10u %.2t %.15M %.6D %.18R %.5C %.12m"
```

If you need more space for the job names, change the `50` above to a
larger number.

In the end, the annotated VCF file is in the directory `results/vcf`,
and all the other intermediate (VCF) files have been deleted.

Additionally, the snpEff reports (html files and TSV files of genes) are
all in the directory `snpeff_reports`.

A few things could be done better here. We don’t need to compress after
reheadering, because it just gets decompressed to concat it. Also, it
might be better to create the whole VCF before running it through
snpEff, because then you get just single summary report. But, that would
take a little longer, since you lose the parallelizability over
chromosomes.

At any rate. This shows a simple Snakefile that has made this analysis
easily reproducible.
