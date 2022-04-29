
CHRS = [1, 2, 3, 4, 5, 6, 7]

GENOME_VERSION="Pearl_Millet_v1.1"
SPECIES_NAME_STRING="Pennisetum_glaucum_PM_v1.1"


rule all:
	input:
		"results/vcf/annotated.vcf.gz"


rule download_genotypes:
	params:
		url="https://cegresources.icrisat.org/data_public/PM_SNPs/SNP_calls/WP.pgchr{chrom}.genotype.gz"
	log:
		"results/logs/download_genotypes/{chrom}.log"
	output:
		"data/genotypes/WP.pgchr{chrom}.genotype.gz"
	shell:
		"wget --no-check-certificate -O {output} {params.url} > {log} 2>&1"



rule download_genotype_readme:
	params:
		url="https://cegresources.icrisat.org/data_public/PM_SNPs/SNP_calls/genotype.readme"
	log:
		"results/logs/download_genotype_readme/log.log"
	output:
		"data/genotypes/genotype.readme"
	shell:
		"wget --no-check-certificate -O {output} {params.url} > {log} 2>&1"



rule download_genome:
	params:
		url="https://cegresources.icrisat.org/data_public/PM_SNPs/pearl_millet_v1.1.fa.gz"
	log:
		"results/logs/download_genome/log.log"
	output:
		"resources/genome.fasta"
	shell:
		" (wget --no-check-certificate -O {output}.gz {params.url}; "
		" gunzip {output}.gz) > {log} 2>&1;"



rule download_gff:
	params:
		url="https://cegresources.icrisat.org/data_public/PM_SNPs/PM.genechr.trans.gff.gz"
	log:
		"results/logs/download_gff/log.log"
	output:
		"resources/genome.gff"
	shell:
		"(wget --no-check-certificate -O {output}.gz {params.url}; "
		" gunzip {output}.gz) > {log} 2>&1; "



rule convert_to_vcf:
	input:
		geno="data/genotypes/WP.pgchr{chrom}.genotype.gz",
		readme="data/genotypes/genotype.readme"
	log:
		"results/logs/convert_to_genotypes/{chrom}.log"
	output:
		"results/vcf_parts/{chrom}.vcf"
	resources:
		time = "03:00:00"
	shell:
		"""
		(
  			awk 'NR>=5 {{printf("SAMPLE %s\\n", $2);}}' {input.readme}; 
  			echo xxxxxxxxxxxxxxxxx; 
  			zcat {input.geno}
		) | awk -f script/genotypes2vcf.awk > {output} 2>{log}
		"""


# make an fai file for putting a header on the VCFs
rule make_fai:
	input:
		fasta="resources/genome.fasta"
	output:
		"resources/genome.fasta.fai"
	log:
		"results/logs/make_fai/make_fai.log"
	conda:
		"envs/samtools.yaml"
	shell:
		" samtools faidx {input.fasta} 2> {log} "


# put headers on each of the VCF files and then compress them
rule headerize_vcfs:
	input:
		vcf="results/vcf_parts/{chrom}.vcf",
		fai="resources/genome.fasta.fai"
	output:
		"results/vcfs_headered/{chrom}.vcf.gz"
	log:
		"results/logs/headerize_vcfs/{chrom}.log"
	conda:
		"envs/bcftools.yaml"
	shell:
		" bcftools reheader -f {input.fai} {input.vcf} | "
		" bcftools view -Oz -  > {output} 2> {log};"



# make a new config file and add to it
rule add_to_snpeff_config:
	params:
		genome_version=GENOME_VERSION,
		species_name_string=SPECIES_NAME_STRING
	output:
		"resources/SnpEff/snpEff.config"
	log:
		"results/add_to_snpeff_config/log.log"
	conda:
		"envs/bcftools.yaml"
	shell:
		"./script/add_to_config.sh {params.genome_version} {params.species_name_string} {output} 2> {log}"


# build a database from genome.fasta and genome.gff
rule build_snpeff_database:
	input:
		fasta="resources/genome.fasta",
		gff="resources/genome.gff",
		config="resources/SnpEff/snpEff.config",
	output:
		directory("resources/SnpEff/data/{gv}".format(gv=GENOME_VERSION) )
	params:
		genome_version=GENOME_VERSION
	log:
		"results/logs/build_snpeff_database/log.log"
	conda:
		"envs/snpeff.yaml"
	shell:
		"( cp resources/genome.fasta {output}/sequences.fa && "
		" cp resources/genome.gff {output}/genes.gff && "
		" snpEff build -Xmx4g  -noCheckCds -noCheckProtein -gff3 "
		"    -c resources/SnpEff/snpEff.config  -v {params.genome_version} ) > {log} 2>&1"

		

rule annotate_each_chromosome:
	input:
		vcf="results/vcf_parts/{chrom}.vcf",
		db="resources/SnpEff/data/{gv}".format(gv=GENOME_VERSION),
		config="resources/SnpEff/snpEff.config",
	output:
		"results/anno_vcf_parts/{chrom}.vcf"
	params:
		genome_version=GENOME_VERSION
	log:
		"results/logs/annotate_each_chromosome/{chrom}.log"
	conda:
		"envs/snpeff.yaml"
	shell:
		"snpEff ann -c {input.config}  {params.genome_version} {input.vcf} > {output} 2> {log} "


rule catenate_anno_chroms:
	input:
		expand("results/anno_vcf_parts/{chrom}.vcf", chrom=CHRS)
	output:
		"results/vcf/annotated.vcf.gz"
	log:
		"results/logs/catenate_anno_chroms/log.log"
	conda:
		"envs/bcftools.yaml"
	shell:
		"bcftools concat {input} | bcftools view -Oz > {output} 2> {log}"


