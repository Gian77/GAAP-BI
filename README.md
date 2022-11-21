# **GAAP-BI**

*GAAP-BI v. 1.0* - **G**enome **A**ssembly and **A**nnotation **P**ipeline for **B**acteria **I**llumina<br>
<br>

MIT LICENSE - Copyright © 2022 Gian M.N. Benucci, Ph.D.<br>
email: *benucci[at]msu[dot]edu*<br>
GAAP-BI v.1, October 2022<br>

## *This pipeline is based upon work supported by the Great Lakes Bioenergy Research Center, U.S. Department of Energy, Office of Science, Office of Biological and Environmental Research under award DE-SC0018409*

> **_WARNING_**<br>
> ### **This pipeline was built for running on a cluster computer that runs SLURM (Slurm Workload Manager) job scheduler. Any other use will require substantial modification of the code.**

### **Installation**

To use GAAP-BP just clone the directory 
```
git clone git@github.com:Gian77/GAAP-BI.git
```
You will then need to 
* Copy your raw reads file in the rawdata directory together with a md5sum file.
* Install all the necessary tools through `conda` (please see the complete list of tools reported below).
* Download the databases (please see below and the `config.yaml` file), and include the full paths into the config file.
* Select all the **User options** (please see below).

Then you should be good to go and run GAAP-BP by just 
`sh GAAP-BI-v1.0.sh`

### **Let's explore the settings in the `config.yaml` file**

#### **Directories**
The main project's directory is: `project_dir="/mnt/home/benucci/GAAP-BP/`. Of course, you will need to adjust the path to your HPCC user name. 

> **_NOTE_**<br> 
> * This pipeline run using SLURM (please see bove). **Resourches of each individual scripts present in the `/mnt/home/benucci/GAAP-BP/code/` directory must be adjusted to the amount of data you want to run for each pipeline run.** In particular the parameters below.
```
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=256G
```
> * The individual scripts in the `code` direcotry include the buy-in node priority `#SBATCH -A shade-cole-bonito`. If you do not have access to those priority nodes please remove that line in the individual scripts.
> * You can change the name of the `project_dir`, but by default is going to be `GAAP-BP`. Subdirectories such as `outputs` and `slurms` are part of the workflow, and should be left as they are.
> * Please check the config file for options. A few script are additional and are can be avoided to save time.

#### **Default to the `rawdata` directory**
When the config is sourced it defaults to the `rawdata` project directory
```
cd $project_dir/rawdata/
```

# **Running options** 
If not numeric (i.e. float) then `yes` or `no`.
```
INTERLACED=yes
COVERAGE=2.0
LENGTH=500
MASH=yes
CHROMOSOMES=3
EGGNOG=yes
BAKTA=no
```

The `INTERLACED` variable is for when read are interlaced  (i.e. `R1` and `R2` are in the same file), if interlaced then specify `yes`.
The `COVERAGE` and `LENGTH` are selexplanaroty and refer to the assembled contigs.
The `STRING` variable differentiate `hifi` form `raw` pacbio reads. Usually `ccs` is present in the raw file name, when found it activates the hifi mode in the *Flye* assembler. If you want to differentiate using a different string you can change it accordingly.
The `MASH` variable is for running plasmid detection using *Mash*.
The `CHROMOSOMES` variable is for circularize the genome or the chromosomes. If the number of contigs is less than the number of specified chromosomes then *Circlator* is run on the contings to circularize them.
The `EGGNOG` variable is to run *eggnog-mapper* to re-classify the proteins detected by *Prokka*.
The `BAKTA` variable is for running the *bakta* annotation pipeline.

!For detailes on the tools mentioned above see below.

#### **Databases**
Find a place in your lab space (or in your home directory) where to put all the needed databases.
Correct the directory hierarchy according to your HPCC account name. For example, in my case all the
databases are in `/mnt/research/ShadeLab/Benucci/databases/`.

```
NCBI_nt="/mnt/research/ShadeLab/Benucci/databases/ncbi_nt1121"
kraken2_db="/mnt/research/ShadeLab/Benucci/databases/kraken2_db/"
minikraken2_db="/mnt/research/ShadeLab/Benucci/databases/minikraken2_db/"
platon_db="/mnt/research/ShadeLab/Benucci/databases/platon_db/db/"
mash_plsdb="/mnt/research/ShadeLab/Benucci/databases/plasmid_db/plsdb.msh"
mash_plsdb_meta="/mnt/research/ShadeLab/Benucci/databases/plasmid_db/plsdb.tsv"
busco_db="/mnt/research/ShadeLab/Benucci/databases/busco_db1121/bacteria_odb10"
phix_db="/mnt/research/ShadeLab/Benucci/databases/phix_index/my_phix"
gunc_db="/mnt/research/ShadeLab/Benucci/databases/gunc_db"
bakta_db="/mnt/research/ShadeLab/Benucci/databases/bakta_db/db"

```
#### **PATHs**
```
export GTDBTK_DATA_PATH=/mnt/research/ShadeLab/Benucci/databases/gtdb_tk/release207_v2
export EGGNOG_DATA_DIR=/mnt/research/ShadeLab/Benucci/databases/emapperdb/
export GUNC_DB=/mnt/research/ShadeLab/Benucci/databases/gunc_db/gunc_db_progenomes2.1.dmnd
```

### **Software needed to fully run Gisa-PB on HPCC**

Please install via conda (or use the binaries in the HPPC) of all these software below. 
#### *[FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), [NanoStat](https://github.com/wdecoster/nanostat), [Flye](https://github.com/fenderglass/Flye), [Minimap2](https://github.com/lh3/minimap2), [Racon](https://github.com/isovic/racon), [Pilon](https://github.com/broadinstitute/pilon/wiki), [Circlator](https://sanger-pathogens.github.io/circlator/), [quast](http://bioinf.spbau.ru/quast), [qualimap](https://github.com/EagleGenomics-cookbooks/QualiMap), [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs), [BlobTools](https://github.com/DRL/blobtools), [Platon](https://github.com/oschwengers/platon), [Mash](https://github.com/marbl/Mash), [Kraken 2](https://ccb.jhu.edu/software/kraken2/), [Bracken](https://github.com/jenniferlu717/Bracken), [CheckM](https://ecogenomics.github.io/CheckM/), [Gunc](https://github.com/grp-bork/gunc), [GTDB-Tk](https://github.com/Ecogenomics/GTDBTk), [Barrnap](https://github.com/tseemann/barrnap), [Metaxa2](https://microbiology.se/software/metaxa2/), [eggNOG](https://github.com/eggnogdb), [Prokka](https://github.com/tseemann/prokka), [BUSCO](https://busco.ezlab.org/), [ABRicate](https://github.com/tseemann/abricate), [MultiQC](https://github.com/ewels/MultiQC), [Bandage](https://github.com/rrwick/Bandage), [R](https://anaconda.org/r/r-essentials).*

> **_NOTE_**<br> 
>Make sure you install `tydiverse` and `ggplot2` along with R.

#### **config options**

Please check the config file for options. A few script are additional and can be avoided if needed.

### **Acknowledgements**
Many thanks to the [Institute for Cyber-Enabled Research (ICER)](https://icer.msu.edu/) for helping troubshoting SLURM, the [DOE Joint Genome Institute](https://jgi.doe.gov/) for providing the sequence data, methods, and metadata support, the whole crew at the [Shade lab](https://ashley17061.wixsite.com/shadelab) for brainstorming over methods and tools, and my good friend and colleague, Dr. Livio Antonielli at the [AIT Austrian Institute of Technology GmbH](https://www.ait.ac.at/en/) for giving me a baseline and for the insiteful discussions and bioiformatic suggestions.
