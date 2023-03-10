#!/usr/bin/env Rscript

#Script name:SNP_to_map
#Author: Defne YANARTAS 
#Created: 2023 March
#Usage: 

#Description:The script takes an input .ped file that contains the information of an SNP of interest (SNPOI)
 
#Input: .ped file specific for the SNP of interest(SNPOI) and .xlsx file that contains the metadata for the file. 
#Output: The animation video containing the tracing of the SNP alleles over time on the world map.
#Procedure:
  # 0. The packages are installed and libraries are loaded. 
  # 1. Data is fetched and organized and cleaned.
  # 2. Main script - plotting and animation.


###############################################################################
# 0. The packages are installed and libraries are loaded.


#install packages
if (!requireNamespace("maps", quietly = TRUE)){
  install.packages("maps", dependencies = TRUE)
}
if (!requireNamespace("mapdata", quietly = TRUE)){
  install.packages("mapdata", dependencies = TRUE)
}
install.packages("gganimate")
install.packages("transformr")
install.packages("av")
install.packages("patchwork")
install.packages("cowplot")
#load the libraries
library(cowplot)
library(maps)
library(mapdata)
library(ggplot2)
library(dplyr)
library(reshape2)
library(tidyverse)
library(gganimate)
library(transformr)
library(av)
library(patchwork)

print(sessionInfo())                                                             #To print the versions used during the script

###############################################################################
# 1. Data is fetched and organized and cleaned.

colnames(anno_data)
anno_data<-read.delim("Eurasian.anno",sep="\t")
meta_data_less<-anno_data[,c(2,8,15,16,14)]
colnames(meta_data_less)[2]<-"Year"                                              #Renaming the mean BP year column
colnames(meta_data_less)[5]<-"Country"
# meta_data<-readxl::read_excel("Eurasian - Dataset_tims.xlsx")                    #This is definitely not a well organized input file, so in this case, it is manually written in the file and the cleaning is done manually in the script. This is my so-called database now.
# meta_data_less<-meta_data[,c(2,19,25,26,27)]                                     #Getting only the columns related to id, time and location.

SNPOI<-read.delim("rs6696609.ped", sep=" ", header=FALSE)                        #Reading in the .ped file that is space separated into a dataframe.
colnames(SNPOI)<- c("Population","Master.ID","Paternal_ID","Maternal_ID","Sex",  #Renaming the columns and making sure Master Id column is the same name as the meta data sheet sample id column
                    "Case","Allele_1","Allele_2")

# colnames(SNPOI_combined_data_clean)[7]<-"Lat"
# colnames(SNPOI_combined_data_clean)[8]<-"Long""

SNPOI_and_meta<-right_join(meta_data_less, SNPOI,by='Master.ID')                 #Joining the SNP info with the metadata based on the individual ID.
SNPOI_and_meta<-SNPOI_and_meta[complete.cases(SNPOI_and_meta$Lat.),]             #Getting rid of the samples where we dont have proper location information
SNPOI_and_meta<-SNPOI_and_meta[order(-SNPOI_and_meta$Year),]                     #Ordering the tibble based on the Year in ascending order so we have a chronological order, that can be helpful when plottong path.
SNPOI_and_meta<-cbind(SNPOI_and_meta,"Genotype_group"=NA)

icon_codes<- data.frame("1"=c(1,6,11,16,21),"2"=c(2,7,12,17,22),                 #These group names will be used for icons when visualizing. Columns are for Allele_1 and rows are for Allele_2.
                        "3"=c(3,8,13,18,23),"4"=c(4,9,14,19,24),                 #Zero is transfirned to 5!!!
                        "5"=c(5,10,15,20,25), 
                        row.names = c("1","2","3","4","5"))
SNPOI_and_meta[SNPOI_and_meta$Allele_1==0,]

SNPOI_and_meta$Allele_1<-sub(0,5,SNPOI_and_meta$Allele_1)                        #I wanted to replace 0 with 5. From now on missing info has a code of 5.
SNPOI_and_meta$Allele_2<-sub(0,5,SNPOI_and_meta$Allele_2)

for (i in 1:nrow(SNPOI_and_meta)){                                               #Assigning the icon group names to the genotypes.
  SNPOI_and_meta$Genotype_group[i]<-icon_codes[
    as.numeric(SNPOI_and_meta$Allele_1[i]),as.numeric(SNPOI_and_meta$Allele_2[i])]
}


#SNPOI_and_meta<-SNPOI_and_meta[c(1:10),]                                         #Here we can restrict part of the timeline we are looking at.


###############################################################################
# 2. Main script - plotting and animation.

install.packages("leaflet")
library(leaflet)

library(leafletMarkerCluster)

countryBorders <- st_read("country_border.geojson")

allele_color<- colorFactor(palette = "Set1", SNPOI_and_meta$Genotype_group)

m <- leaflet(data=SNPOI_and_meta) %>% setView(lng = mean(SNPOI_and_meta$Long.), 
                                              lat = mean(SNPOI_and_meta$Lat.), 
                                              zoom = 3)
  
m %>% addProviderTiles(providers$CartoDB.Voyager) %>%
  #addPolylines(~Long., ~Lat., color = "blue", weight=1) %>%
  addCircleMarkers(data = SNPOI_and_meta[1,], ~Long., ~Lat., stroke = FALSE, 
                   fillOpacity = 0.5, label = "Start", color = "green") %>%
  addCircleMarkers(data = SNPOI_and_meta[nrow(SNPOI_and_meta),],  ~Long., ~Lat., 
                   stroke = FALSE, fillOpacity = 0.5, label = "End", 
                   color = "red") %>%
  addCircleMarkers(data = SNPOI_and_meta, lat = ~Lat., lng = ~Long., radius=2,
                 color = SNPOI_and_meta$color, 
                 popup = as.character(SNPOI_and_meta$Genotype_group)
                 )%>%
  addpiechartclustermarkers()
  addLegend('bottomleft', colors = unique(SNPOI_and_meta$color), 
            labels = unique(SNPOI_and_meta$Genotype_group), 
            title = 'Alleles',
            opacity = 1)
                 
m%>%
addLabelOnlyMarkers(data = SNPOI_and_meta,
                    lng = ~Long., lat = ~Lat.,
                    label = ~as.character(~Genotype_group),
                    clusterOptions = markerClusterOptions(),
                    labelOptions = labelOptions(noHide = T,
                                                direction = "auto"))

################################################################################



circle_gray <- makeIcon(iconUrl = "https://www.flaticon.com/free-icons/brochure",
                        iconWidth = 18, iconHeight = 18)


################################################################################



gg2 <- ggplot(data = world, aes(x=long, y = lat)) +                              #Plotting the world map coordinates.
  geom_polygon(aes(group = group),col="gray",fill="wheat4") +                    #Binding the coordinates to draw the borders and filling with color.
  theme(legend.position = "none") +
  geom_point(data=SNPOI_and_meta, aes (x=Long., y= Lat.), colour="red",            #Plotting the coordinates of individuals
             size = 1) +
  geom_path(data=SNPOI_and_meta,aes (x=Long., y= Lat.))+                         #Drawing a path between the individuals in the order of the years.
  coord_cartesian(xlim = c(min(SNPOI_and_meta$Long.)-10,                         #Limiting the plot window to show a zoomed in view of our data points. coord_cartesian helps to limit the view without ruining the outer ggplot datapoints.
                           max(SNPOI_and_meta$Long.)+10), 
                  ylim = c(min(SNPOI_and_meta$Lat.)-10, 
                           max(SNPOI_and_meta$Lat.)+10))



timebar<-ggplot(data = SNPOI_and_meta, aes(x = Year, y = 1)) +                   #Making a timeline
  geom_bar()+                                                                    #Time points
  geom_path()+                                                                   #Drawing a path for the timeline
  scale_x_reverse()                                                              #I want the timeline plotted from the highest to the lowest so we move chronologically 

anim_gg2<-gg2+transition_reveal(c(1:10)) + enter_fade() + exit_fly(y_loc = 1)

animate(anim_gg2,renderer = av_renderer())







