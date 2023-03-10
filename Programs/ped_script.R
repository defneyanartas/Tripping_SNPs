#data prep script
library(tidyverse)


anno_data<-read.delim("Eurasian.anno",sep="\t")
meta_data_less<-anno_data[,c(2,8,15,16,14)]
colnames(meta_data_less)[2]<-"Year"                                              #Renaming the mean BP year column


snpoi_ped_function<-function(snpoi){
  SNPOI<-read.delim(paste0(snpoi,".ped"), sep=" ", header=FALSE)                                #Reading in the .ped file that is space separated into a dataframe.
  colnames(SNPOI)<- c("Population","Master.ID","Paternal_ID","Maternal_ID","Sex",  #Renaming the columns and making sure Sample Id column is the same name as the meta data sheet sample id column
                      "Case","Allele_1","Allele_2")
  
  SNPOI_and_meta<-right_join(meta_data_less, SNPOI,by='Master.ID')                 #Joining the SNP info with the metadata based on the individual ID.
  SNPOI_and_meta<-SNPOI_and_meta[complete.cases(SNPOI_and_meta$Lat.),]             #Getting rid of the samples where we dont have proper location information
  SNPOI_and_meta<-SNPOI_and_meta[order(-SNPOI_and_meta$Year),]                     #Ordering the tibble based on the Year in ascending order so we have a chronological order, that can be helpful when plottong path.
  SNPOI_and_meta<-SNPOI_and_meta[SNPOI_and_meta$Allele_1!=0,]              #Get rid of non informatory sites
  SNPOI_and_meta<-SNPOI_and_meta[SNPOI_and_meta$Allele_2!=0,] 
  SNPOI_and_meta$Lat.<-as.numeric(SNPOI_and_meta$Lat.)
  SNPOI_and_meta$Long.<-as.numeric(SNPOI_and_meta$Long.)
  SNPOI_and_meta<-cbind(SNPOI_and_meta,"Genotype_group"=NA)
  SNPOI_and_meta<-cbind(SNPOI_and_meta,"color"=NA)
  genotypes<- data.frame("1"=c("AA","AC","AG","AT"),"2"=c("AC","CC","CG","CT"),                 #These group names will be used for icons when visualizing. Columns are for Allele_1 and rows are for Allele_2.
                          "3"=c("AG","CG","GG","GT"),"4"=c("AT","CT","GT","TT"),                 #Zero is transfirned to 5!!! 
                          row.names = c("1","2","3","4"))
  geno_color<- data.frame("1"=c("red","orange","pink","purple"),"2"=c("orange","yellow","yellowgreen","green"),                 #These group names will be used for icons when visualizing. Columns are for Allele_1 and rows are for Allele_2.
                         "3"=c("pink","yellowgreen","orchid","salmon"),"4"=c("purple","green","salmon","blue"),                 #Zero is transfirned to 5!!! 
                         row.names = c("1","2","3","4"))
  #SNPOI_and_meta$Allele_1<-sub(0,5,SNPOI_and_meta$Allele_1)                        #I wanted to replace 0 with 5. From now on missing info has a code of 5.
  #SNPOI_and_meta$Allele_2<-sub(0,5,SNPOI_and_meta$Allele_2)
  
  for (i in 1:nrow(SNPOI_and_meta)){                                               #Assigning the icon group names to the genotypes.
    SNPOI_and_meta$Genotype_group[i]<-genotypes[
      as.numeric(SNPOI_and_meta$Allele_1[i]),as.numeric(SNPOI_and_meta$Allele_2[i])]
    SNPOI_and_meta$color[i]<-geno_color[
      as.numeric(SNPOI_and_meta$Allele_1[i]),as.numeric(SNPOI_and_meta$Allele_2[i])]
  }
  return(SNPOI_and_meta)
}

SNPOI_and_meta<-snpoi_ped_function("rs6696609")                                                  #Example SNP so that there is an initial map for the user to see

maf_function<-function(df){                                                       #function to calculate MAF by country
  df<-cbind(df,"MAF_bycountry"=NA)
  var<-as.data.frame(table(c(df$Allele_1,df$Allele_2)))
  MA<-var[var$Freq==min(var$Freq),"Var1"]                                          #Minor allele for the population determined
  #MAF_pop<-min(var$Freq)/sum(var$Freq)
  for (i in unique(df$Population)){
    alleles<-as.data.frame(table(c(df[df$Population==i,"Allele_1"],
    df[df$Population==i,"Allele_2"])))
    if (MA %in% alleles$Var1){
      ma<-alleles[alleles$Var1==MA,"Freq"]
      maf<-round(ma/sum(alleles$Freq),digits=2)
    }
    else {maf<-0} 
    df[df$Population==i,"MAF_bycountry"]<-maf
  }
  return(df)
}


SNPOI_and_meta<-maf_function(SNPOI_and_meta)

MA_function<-function(df){
  var<-as.data.frame(table(c(df$Allele_1,df$Allele_2)))
  MA<-var[var$Freq==min(var$Freq),"Var1"]                                          #Minor allele for the population determined
  MAF_pop<-min(var$Freq)/sum(var$Freq)
  if (MA==1){MA="A"}
  else if (MA==2){MA="C"}
  else if (MA==3){MA="G"}
  else if (MA==4){MA="T"}
  return(c(MA,MAF_pop))
}
MA_function(SNPOI_and_meta)

