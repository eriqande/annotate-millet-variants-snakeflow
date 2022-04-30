

GENOME_VERSION_NAME=$1
SPECIES_NAME_STRING=$2
OUTPUT=$3

if [ $# -ne 3 ]; then
	echo "expected 3 arguments" > /dev/stderr
	exit 1;
fi


# get the directory that the alias lives in
FIRSTDIR=$(dirname $(dirname $(which snpEff))) &&
# get the directory of the value of the alias
TMP=$(dirname $(readlink -s `which snpEff`)) &&
# combine those to get the directory where the config file is
SNPEFFDIR=${FIRSTDIR}${TMP/../} &&



mkdir -p resources/SnpEff  &&

# copy the config file
cp $SNPEFFDIR/snpEff.config  $OUTPUT  &&

# add an entry for pearl millet
echo "

# added by snakemake rule add_to_snpeff_config
$GENOME_VERSION_NAME.genome : $SPECIES_NAME_STRING

" >> $OUTPUT

