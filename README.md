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

4.  Then you could download the genome and the gff and the
    genotype.readme using just the local core on scompile, but we will
    just have Snakemake launch each job on SLURM using `sbatch`, by way
    of the slurm profile:

``` sh
```
