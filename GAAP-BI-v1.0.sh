#!/bin/bash -login

cat << "EOF"
   _________    ___    ____        ____  ____
  / ____/   |  /   |  / __ \      / __ )/  _/
 / / __/ /| | / /| | / /_/ /_____/ __  |/ /  
/ /_/ / ___ |/ ___ |/ ____/_____/ /_/ // /   
\____/_/  |_/_/  |_/_/         /_____/___/   
                                                                                                                                                                                              
EOF

echo -e "
GAAP-BI v. 1.0 - Genome Assembly and Annotation Pipeline for Bacteria Illumina

MIT LICENSE - Copyright © 2022 Gian M.N. Benucci, Ph.D.
email: benucci[at]msu[dot]edu

`date`

This pipeline is based upon work supported by the Great Lakes Bioenergy Research Center, 
U.S. Department of Energy, Office of Science, Office of Biological and Environmental 
Research under award DE-SC0018409\n"

source ./config.yaml
cd $project_dir/rawdata/

echo -e "\n========== Comparing md5sum codes... ==========\n"
md5=$project_dir/rawdata/md5.txt

if [[ -f "$md5" ]]; then
		echo -e "\nAn md5 file exist. Now checking for matching codes.\n"
		md5sum md5* --check > tested_md5.results
		cat tested_md5.results
		resmd5=$(cat tested_md5.results | cut -f2 -d" " | uniq)

		if [[ "$resmd5" == "OK" ]]; then
				echo -e "\n Good news! Files are identical. \n"
		else
				echo -e "\n Oh oh! You're in trouble. Files are different! \n"
				echo -e "\nSomething went wrong during files'download. Try again, please.\n"
				exit
		fi
else
	echo "No md5 file found. You should look for it and start over!"
	exit
fi

cd $project_dir/code/

echo -e "\n Submitting jobs to cue, one after another...\n"

echo -e "\n========== Prefiltering ==========\n" 
jid1=`sbatch 00_decompressfiles.sb | cut -d" " -f4`
echo "$jid1: First of all, I will decompress your files."  

# Deinterlaced reads or not
if [[ "$INTERLACED" == "yes" ]]; then
		echo -e "\n Your Illumina reads are interlaced: I will deinterlace them for you :) \n"
		jid2=`sbatch --dependency=afterok:$jid1 01_deinterlace-bash.sb | cut -d" " -f4`
		echo "$jid2: Deinterlacing reads!"
else 
		echo -e "\n Your Illumina reads are NOT interlaced: Skipping! \n"
fi


# Checking reads quality
if [[ "$INTERLACED" == "yes" ]]; then
	jid3=`sbatch --dependency=afterok:$jid2 02_rawquality-nanostats.sb | cut -d" " -f4`
	echo "$jid3: I will generate basic raw-reads statistics with nanostat."
else 
	jid3=`sbatch --dependency=afterok:$jid1 02_rawquality-nanostats.sb | cut -d" " -f4`
	echo "$jid3: I will generate basic raw-reads statistics with nanostat."
fi

if [[ "$INTERLACED" == "yes" ]]; then
	jid4=`sbatch --dependency=afterok:$jid2 03_rawquality-fastqc.sb | cut -d" " -f4`
	echo "$jid4: I will check the quality of the raw reads with fastqc."
else 
	jid4=`sbatch --dependency=afterok:$jid1 03_rawquality-fastqc.sb | cut -d" " -f4`
	echo "$jid4: I will check the quality of the raw reads with fastqc."
fi

# Filetring Phix
if [[ "$INTERLACED" == "yes" ]]; then
		jid5=`sbatch --dependency=afterok:$jid2 04_removingPhix-bowtie2.sb | cut -d" " -f4`
		echo "$jid5: Removing reads that match to Phix genome with bowtie2."
else
		jid5=`sbatch --dependency=afterok:$jid1 04_removingPhix-bowtie2.sb | cut -d" " -f4`
		echo "$jid5: Removing reads that match to Phix genome with bowtie2."
fi

# Trimming
jid6=`sbatch --dependency=afterok:$jid5 05_trimmingadapters-fastp.sb | cut -d" " -f4`
echo "$jid6: Trimming adapters with fastp."

echo -e "\n========== Assembly, assembly evaluation, preliminary check for plasmid ==========\n" 
# Assembly
jid7=`sbatch --dependency=afterok:$jid6 06_assembly-spades.sb | cut -d" " -f4`
echo "$jid7: Assembly using spades."

# Checking for plasmids - probably I will implement a separate pipeline for plasmids later.
jid8=`sbatch --dependency=afterok:$jid7 07_plasmidcheck-platon.sb | cut -d" " -f4`
echo "$jid8: Checking for plasmids using Platon."

jid9=`sbatch --dependency=afterok:$jid7 08_plasmidcheck-mash.sb | cut -d" " -f4`
echo "$jid9: Checking for plasmids using Mash."

# Evaluating assembly
jid10=`sbatch --dependency=afterok:$jid7 09_assemblyeval-bowtie2-qualimap.sb | cut -d" " -f4`
echo "$jid10: Assembly evaluation using Qualimap."

jid11=`sbatch --dependency=afterok:$jid7:$jid10 10_assemblyvisual-blast-blobtl.sb | cut -d" " -f4`
echo "$jid11: Assembly visualization and quality check using BLAST and blobtools."

echo -e "\n========== Filtering contaminants ==========\n" 
# Classifying contigs 
jid12=`sbatch --dependency=afterok:$jid7 11_completeness-checkm-gtdbtk.sb | cut -d" " -f4`
echo "$jid12: Assembly completeness and contamination using checkM and GTDB-tk."

jid13=`sbatch --dependency=afterok:$jid7 12_taxclassabund-kraken2-braken.sb | cut -d" " -f4`
echo "$jid13: Assembly taxonomic classification and abundance with Kraken2 and Bracken."

jid14=`sbatch --dependency=afterok:$jid7:$jid12 13_chimeraDetect-gunc-checkm.sb | cut -d" " -f4`
echo "$jid14: Assembly classification and chimerism using GUNC."

# Extracting rRNAs 
jid15=`sbatch --dependency=afterok:$jid7 14_extractRNAgenes-barrnap-metaxa.sb | cut -d" " -f4`
echo "$jid15: Extract rRNA marker genes using barrnap and metaxa."

# Filetring contaminants
jid16=`sbatch --dependency=afterok:$jid7:$jid11:$jid13:$jid14 15_filterContaminants-bash.sb | cut -d" " -f4`
echo "$jid16: Filtering out contigs based on taxonomy, length, coverage."

jid17=`sbatch --dependency=afterok:$jid16 16_cleanGenome-bash.sb | cut -d" " -f4`
echo "$jid17: Extract rRNA marker genes using barrnap and metaxa."

# Reorienting the genome and fistart
jid18=`sbatch --dependency=afterok:$jid17 17_fixstart-circlator.sb | cut -d" " -f4`
echo "$jid18: Running circlator to reorient the genome."

# Comparing different versions of the assembly
jid19=`sbatch --dependency=afterok:$jid18 18_assemblyquality-quast.sb | cut -d" " -f4`
echo "$jid19: Compare and evaluate quality of assemblies and filtering approaches."

echo -e "\n========== Gene annotation ==========\n" 
# Gene predicions, completeness, and orthologs searches
jid20=`sbatch --dependency=afterok:$jid18 19_geneprediction-busco.sb | cut -d" " -f4`
echo "$jid20: Gene prediciton and completeness with BUSCO single-copy orthologs."

jid21=`sbatch --dependency=afterok:$jid18:$jid12 20_geneannotation-prokka.sb | cut -d" " -f4`
echo "$jid21: Gene functional annotation with Prokka."

jid22=`sbatch --dependency=afterok:$jid18:$jid21 21_proteinAnnotation-eggnog.sb | cut -d" " -f4`
echo "$jid22: Protein Annootation using the EggNog mapper."

jid23=`sbatch --dependency=afterok:$jid18 22_ARgenes-abricate.sb | cut -d" " -f4`
echo "$jid23: Identifying Antimicrobial resistence genes with abricate."

echo -e "\n========== Exporting and zipping reports and results ==========\n" 
jid24=`sbatch --dependency=afterok:$jid2:$jid3:$jid10$jid13:$jid19:$jid20:$jid21 23_combinereports-multiqc.sb | cut -d" " -f4`
echo "$jid24: Generating multi-report with multiQC."

jid25=`sbatch --dependency=afterok:$jid7:$jid18:$jid21 24_assemblygraph-bandage.sb | cut -d" " -f4`
echo "$jid25: plotting genome network - differnet versions."

jid26=`sbatch --dependency=afterok:$jid2:$jid3:$jid4:$jid5:$jid6:$jid7:$jid8:$jid9:$jid10:$jid11:$jid12:$jid13:$jid14:$jid15:$jid16:$jid17:$jid18:$jid19:$jid20:$jid21:$jid22:$jid23:$jid24:$jid25 25_exportreports-bash.sb | cut -d" " -f4`
echo "$jid26: Copy and zip all reports for further use."


echo -e "\n========== Listing submitted jobs ==========\n" 
echo -e "\n `sq` \n"

echo -e "\n========== This is the end... My friend... You should be all done! ==========\n" 
