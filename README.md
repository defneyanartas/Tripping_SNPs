# Tripping_SNPs

Author: Defne Yanartas

Date: March 2023

Sections:
0. Installing and set-up
1. Data
2. Programs (usage)
3. Results

## 0. Installing and set-up

### PLINK (version v1.07)

Install plink 

```bash
wget https://zzz.bwh.harvard.edu/plink/dist/plink-1.07-x86_64.zip   #download to the bin
unzip plink-1.07-x86_64.zip                                         #after that, add the directory to the path
```
### Git and project directory

Set up the project directory and git repository. For the rest of the file I will not wrote each time that I commit changes but the user can decide when to commit and push their changes to the repository and remote.
```bash
mkdir Data
mkdir Programs
mkdir Results

gitinit
git remote add origin git@github.com:defneyanartas/Tripping_SNPs.git
git branch -M main
git push --set-upstream origin main 

```

### Conda (version 22.11.1)
```bash
conda create --name tripping-r-env r-base 
```
## 1. Data

It is important to have the directory and file names exactly as stated here in this document. 

Fetch the plink files (fam, bim and bed) from:https://github.com/sarabehnamian/Origins-of-Ancient-Eurasian-Genomes/tree/main/steps/Step%20. Rename the base as Eurasian. Then proceed to use plink to recode the binary files to readable files. Output will be a map and ped file. 
```bash
plink --bfile Eurasian --recode --out Eurasian --noweb
cat Eurasian.map | cut -f 2 | whiel read line; do echo $line > extract.txt; plink --bfile Eurasian --extract extract.txt --recode --out $line --noweb; done
nohup cat to_be_extracted.txt | while read line; do echo $line > extract.txt; plink --bfile Eurasian --extract extract.txt --recode --out $line --noweb ; done &
```
Get the annotation file from course page and name it "Eurasian.anno"

The files created in PLINK are too large and will not be tracked or pushed to github but the binary files and annotation file is provided in the "1.Data" directory so the files necessary for the program to run can be created by following the PLINK command I have written.

## 2. Programs

### Scripts
Scripts were written in R in RStudio. Below is a session information.

htmlwidgets_1.6.1 compiler_4.2.1    magrittr_2.0.3    fastmap_1.1.0     R6_2.5.1          cli_3.6.0        
leaflet_2.1.1     htmltools_0.5.4   tools_4.2.1       rstudioapi_0.14   crosstalk_1.2.0   digest_0.6.31    
rlang_1.0.6      

### Usage 

We need to run the application in the conda environment that we have created. We also need to install the required packages.
```bash
conda activate tripping-r-env r-base
conda install -c conda-forge r-shiny
conda install -c conda-forge r-tidyverse
conda install -c conda-forge r-leaflet
conda install -c conda-forge r-dplyr
conda install -c conda-forge r-shinywidgets
conda install -c conda-forge r-leaflet.extras
```

You can run the application by running the code below from your project directory. Notice that scripts must be placed under "Programs" directory and the data under "Data" directory.
```
Rscript Programs/Tripping_SNP_shiny.R && R -e "shiny::runApp('Programs/Tripping_SNP_shiny.R', launch.browser = TRUE)"
```
It might take some time to read data depending on the size. When a line like "http://127.0.0.1:4164/" appears, either there will be a popup window on your browser or if not, copy the address to your browser and this should bring up the GUI, then you can select your options and start visualizing.

## 3. Results

The default SNP is depicted together with no populations picked when the application is started. Minor allele and the minor allele frequency (MAF) are also displayed underneath the map for the whole dataset of the chosen SNP.

<img src="3.Results/Picture1.png" alt= “” width="80%" height="value">

The user can select a different SNP, certain populations or a time period.

<img src="3.Results/Picture2.png" alt= “” width="80%" height="value">

When the user ticks the time path check box, a time tracking line is drawn showing the samples from the oldest to the newest. Also when the cursor is on a marker, information regarding the sample is depicted.

<img src="3.Results/Picture3.png" alt= “” width="80%" height="value">