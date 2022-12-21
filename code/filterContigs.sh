#!/bin/bash

# MIT LICENSE - Copyright © 2022 Gian M.N. Benucci <benucci@msu.edu>
# This script extract high quality contigs from genome/metagenomes assembled with spades,
# based on the length and coverage calculated in spades.
# Usage: sh filterContigs.sh <full-path-to-contigs.fasta> <full-path-to-output_dir> 

cd $(echo "$( echo $(cd ../../ && pwd) )"/code/)
echo `pwd`

source ./../config.yaml

cd $project_dir/outputs/06_assembly_spades

in_file=$1
echo "infile:$infile"
out_dir=$2
echo "out-dir:$out_dir"

cat $in_file | grep "NODE_" > $out_dir/name.dat
cat $in_file| grep "NODE_" | tr "_" "\t" | cut -f4,6 > $out_dir/CL.dat

# Extract contigs list (with length and coverage) from contigs.fasta
#paste <(cat $1 | grep "NODE_") <(cat $1 | grep "NODE_" | tr "_" "\t" | cut -f4,6) > contigs.list
paste $out_dir/name.dat $out_dir/CL.dat > $out_dir/contigs.list
rm $out_dir/name.dat $out_dir/CL.dat 

# Filter the lines using given values of COVERAGE and LENGTH
# Use -v to pass variables inside awk command
cat $out_dir/contigs.list | awk -v len="$LENGTH" -v cov="$COVERAGE" '$2>=len && $3>=cov' > $out_dir/contigs_filtered.results

# Extract contigs ids
cat $out_dir/contigs_filtered.results | cut -f1 | sed 's/>//' > $out_dir/ids.txt

# Extracting the filtered and discarded contigs with awk
awk 'NR==FNR{a[">"$0];next}/^>/{f=0;}($0 in a)||f{print;f=1}' $out_dir/ids.txt $in_file > $out_dir/contigs_hq.fasta
awk '(NR==FNR){s[">"$0]++} (/^>/){ s[$0] ? a=0 : a=1}a' $out_dir/ids.txt $in_file > $out_dir/contigs_bad.fasta
