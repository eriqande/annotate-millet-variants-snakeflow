# we begin by creating arrays that tell us the first and second allele
# of each IUPAC-coded genotype
BEGIN {
  iupac["A",1] = "A";
  iupac["A",2] = "A";

  iupac["C",1] = "C";
  iupac["C",2] = "C";

  iupac["G",1] = "G";
  iupac["G",2] = "G";

  iupac["T",1] = "T";
  iupac["T",2] = "T";

  iupac["R",1] = "A";
  iupac["R",2] = "G";

  iupac["Y",1] = "C";
  iupac["Y",2] = "T";

  iupac["S",1] = "G";
  iupac["S",2] = "C";

  iupac["W",1] = "A";
  iupac["W",2] = "T";

  iupac["K",1] = "G";
  iupac["K",2] = "T";

  iupac["M",1] = "A";
  iupac["M",2] = "C";

  # Now, print the minimal header lines
  printf("##fileformat=VCFv4.2\n")
  printf("##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n")
  printf("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT")

}


# we catenate the sample names, each on a line starting with SAMPLE
# to the input, and then print them all here
$1=="SAMPLE" {
  printf("\t%s", $NF);
  next
}

/xxxxxxxxxxxxxx/ {printf("\n"); next}



# then, for each row, we make a first pass and define integers for the
# different alternate alleles. Then we make a second pass and print
# the VCF line
{
  CHROM=$1;
  POS=$2
  delete a_ints; # clear these arrays
  delete alleles;
  a_idx = 0;  # start the allele index at 0 (the REF)
  alleles[$3] = a_idx; # reference allele gets a 0
  a_ints[a_idx] = $3;  # keep this array to have alleles in sorted order,
                       # indexed from 0 to the number of alleles - 1

  # cycle over all the columns, and the two alleles within each genotype
  # in that column, and add any new alleles found to the alleles hash array
  for(i=4;i<=NF;i++) {
    for(a=1;a<=2;a++) if($i != "-") {
      alle = iupac[$i, a];
      if(!(alle in alleles)) {  # if we have not seen this allele before
        alleles[alle] = ++a_idx;
        a_ints[a_idx] = alle
      }
    }
  }

  # Now we can print the VCF line
  # print CHROM, POS, ID, and REF columns
  printf("%s\t%s\t.\t%s", $1, $2, $3) 

  # print the ALT field, including comma-separated alleles if multiallelic
  if(a_idx == 0) { # if there are no alternate alleles ALT gets a .
    printf("\t.")
  } else {
    printf("\t%s", a_ints[1])
    for(a=2;a<=a_idx;a++)
      printf(",%s", a_ints[a])
  }

  # Set all the QUALs to 100, the FILTERs to PASS and the INFO to .
  printf("\t100\tPASS\t.")

  # make the FORMAT column.  It just has GT
  printf("\tGT")

  # now, cycle over the individuals and print their genotypes
  for(i=4;i<=NF;i++) {
    if($i=="-") {
      printf("\t./.");
    } else {
      a = iupac[$i, 1];
      b = iupac[$i, 2];
      printf("\t%s/%s", alleles[a], alleles[b])
    }
  }
  
  printf("\n")
}

