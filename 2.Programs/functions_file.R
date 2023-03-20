#!/usr/bin/env Rscript

#Script name:functions_file.R
#Author: Defne YANARTAS 
#Created: 2023 March
#Usage: Source the whole script. 

#Description: The script has the functions necessary for the Tripping_SNPs 
              #application to work.

#Procedure:
# 0. The packages are installed and libraries are loaded. 
# 1. Data is read into dataframes. 
# 2. Functions are written for various parts of the ui of the shiny application.

###############################################################################
# 0. The packages are installed and libraries are loaded. 


#install.packages("tidyverse")
library(tidyverse)
#install.packages("shiny")
library(shiny)
#install.packages("leaflet")
library(leaflet)
library(dplyr)
#install.packages("shinyWidgets")
library(shinyWidgets)
#install.packages("leaflet.extras")
library("leaflet.extras")

###############################################################################
# 1. Data is read into dataframes. 
#Here we have told the user to run the scripts
#from programs directory and having a Data folder where the plink files are

anno_data<-read.delim("Data/Eurasian.anno",sep="\t")                                  #Annotation data containing coordinates and dating.
meta_data_less<-anno_data[,c(2,8,15,16,14)]                                      #Fetching only the columns of interest
colnames(meta_data_less)[2]<-"Year"                                              #Renaming the mean BP year column

map_file<-read.delim("Data/Eurasian.map",sep="\t", header=FALSE)                      #plink file containing SNP info in the same order that is presented in the ped file.
ped_file<-read.delim("Data/Eurasian.ped",sep=" ", header=FALSE)                       #plink file containing the sample id, population, paternal and maternal ids, sex, case respectively as well as genotypes of each SNP for every sample.

###############################################################################
# 2. Functions are written for various parts of the ui of the shiny application.


###################################


#Function to create the dataframe for the specific SNP chosen by the user


snpoi_ped_function<-function(snpoi){
  r<-which(map_file$V2==snpoi)
  SNPOI<-cbind(ped_file[,seq(1,6)],ped_file[,c(2*r+5,2*r+6)])
  colnames(SNPOI)<- c("Population","Master.ID","Paternal_ID","Maternal_ID","Sex",#Renaming the columns and making sure Sample Id column is the same name as the meta data sheet sample id column
                                           "Case","Allele_1","Allele_2")
  SNPOI_and_meta<-right_join(meta_data_less, SNPOI,by='Master.ID')               #Joining the SNP info with the metadata based on the individual ID.
  SNPOI_and_meta<-SNPOI_and_meta[complete.cases(SNPOI_and_meta$Lat.),]           #Getting rid of the samples where we dont have proper location information
  SNPOI_and_meta<-SNPOI_and_meta[order(-SNPOI_and_meta$Year),]                   #Ordering the tibble based on the Year in ascending order so we have a chronological order, that can be helpful when plottong path.
  SNPOI_and_meta<-SNPOI_and_meta[SNPOI_and_meta$Allele_1!=0,]                    #Get rid of non informatory sites
  SNPOI_and_meta<-SNPOI_and_meta[SNPOI_and_meta$Allele_2!=0,] 
  SNPOI_and_meta$Lat.<-as.numeric(SNPOI_and_meta$Lat.)                           #They need to be numeric
  SNPOI_and_meta$Long.<-as.numeric(SNPOI_and_meta$Long.)
  SNPOI_and_meta<-cbind(SNPOI_and_meta,"Genotype_group"=NA)                      #We will have columns for genotype and colors based on numbers. 
  SNPOI_and_meta<-cbind(SNPOI_and_meta,"color"=NA)
  genotypes<- data.frame("1"=c("AA","AC","AG","AT"),"2"=c("AC","CC","CG","CT"),  #These group names will be used in the map. Columns are for Allele_1 and rows are for Allele_2.
                          "3"=c("AG","CG","GG","GT"),"4"=c("AT","CT","GT","TT"),  
                          row.names = c("1","2","3","4"))
  geno_color<- data.frame("1"=c("red","orange","pink","purple"),
                          "2"=c("orange","yellow","yellowgreen","green"),                 
                         "3"=c("pink","yellowgreen","orchid","salmon"),
                         "4"=c("purple","green","salmon","blue"),                 
                         row.names = c("1","2","3","4"))
  for (i in 1:nrow(SNPOI_and_meta)){                                             #Converting the numbers to letters for genotypes.
    SNPOI_and_meta$Genotype_group[i]<-genotypes[                                   
      as.numeric(SNPOI_and_meta$Allele_1[i]),
      as.numeric(SNPOI_and_meta$Allele_2[i])]
    SNPOI_and_meta$color[i]<-geno_color[
      as.numeric(SNPOI_and_meta$Allele_1[i]),
      as.numeric(SNPOI_and_meta$Allele_2[i])]
  }
  return(SNPOI_and_meta)                                                         #Output of the function is the dataframe for the SNP that the user has chosen
}

SNPOI_and_meta<-snpoi_ped_function("rs6696609")                                 #As an initial output for the application                          


###################################

# Function to calculate MAF by country


maf_function<-function(df){                                                           
  df<-cbind(df,"MAF_bycountry"=NA)                                               #Make a new column for MAF
  var<-as.data.frame(table(c(df$Allele_1,df$Allele_2)))                          #Making a table of the counts of alleles
  MA<-var[var$Freq==min(var$Freq),"Var1"]                                        #The allele with the minimum frequency is fetched from the table and that is the minor allele now
  for (i in unique(df$Population)){                                              #Getting the names of the countries that exist in the current dataset and loop in them
    alleles<-as.data.frame(table(c(df[df$Population==i,"Allele_1"],              #For every country, get the frequency table for the samples alleles   
    df[df$Population==i,"Allele_2"])))
    if (MA %in% alleles$Var1){                                                   #If the global minor allele exists in the population,
      ma<-alleles[alleles$Var1==MA,"Freq"]                                       #From the table, get the count for the global MAF that was determined in the initial part of the function                                    
      maf<-round(ma/sum(alleles$Freq),digits=2)                                  #Calculate frequency in the population.
    }
    else {maf<-0}                                                                #If the global minor allele does not exist in the population, that value is assigned as zero.
    df[df$Population==i,"MAF_bycountry"]<-maf
  }
  return(df)                                                                     #The function returns an updated version of the dataframe that was given into it.
}


SNPOI_and_meta<-maf_function(SNPOI_and_meta)


###################################

# Function to determine MA 


MA_function<-function(df){                                                       #This function is really similar to the one above but instead of frequency it simply returns the name of the minor allele.
  var<-as.data.frame(table(c(df$Allele_1,df$Allele_2)))
  MA<-var[var$Freq==min(var$Freq),"Var1"]                                        #Minor allele for the population determined
  MAF_pop<-round(min(var$Freq)/sum(var$Freq),2)
  if (MA==1){MA="A"}                                                    
  else if (MA==2){MA="C"}
  else if (MA==3){MA="G"}
  else if (MA==4){MA="T"}
  return(c(MA,MAF_pop))
}



