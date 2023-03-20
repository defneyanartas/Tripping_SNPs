#!/usr/bin/env Rscript

#Script name:Trippind_SNP_shiny.R
#Author: Defne YANARTAS 
#Created: 2023 March
#Usage: Run it from the terminal, the app comes up. You can select an SNP you 
        #are interested in. What is typed as SNP needs to exist in the database. 
        #You can sleect the time range you want to see and you can select to see 
        #a time path, as well as what populations you are interested in.

#Description: This is the shiny application file which tracks an SNP of 
              #interest in the map over time and space.
#Known bugs: If the user selects a number of populations and shows them, 
            #later changes the time period to a range that the selected 
            #population does not exist, the list becomes the full population 
            #list but they dont get displayed on the map.

rm(list=ls())                                                                    #Cleaning the environment
source("2.Programs/functions_file.R")                                                       #Sourcing the functions file to have the data read into dataframes and functions imported



shinyApp(
  ui=fluidPage(                                                                  #This is the user interface part of the application
    titlePanel("Tripping SNPs"),                                                 #Title of the page
    sidebarLayout(                                                               #The placing in the page
      sidebarPanel(
        textInput("snpoi",                                                       #First user input is a text of SNP of interets that needs to exist in the dataset, otherwise the application stops working. snpoi is the inputid, so any value put into will be referred with that object name
                  label="Type in SNP of interest",
                  value="rs6696609",                                             #I assign an example value for the app to start with                                           
                  placeholder="rs#######"),
        sliderInput(inputId = "range",                                           #This is a user input where the user can select the time range they want to visualize
                    label = "Select the year before present(BP:1950)",           
                    value = c(3000,4000),                                        #Some default values to start with
                    max =  max(SNPOI_and_meta$Year),                             #The range should have a min and max in the ui according to the current dataset                         
                    min =  min(SNPOI_and_meta$Year)),
        checkboxInput(inputId="timepath",                                        #This is a check box for if the user wants to visualize a timepath between the samples.
                      label="Show time path",
                      value=FALSE),                                              #Default is not showing
        pickerInput(inputId="population",                                        #The user can also select the populations they would like to visualize
                    label="Select the population(s) of interest",
                    choices=unique(SNPOI_and_meta$Population),                   #the choices are the countries in the current dataset
                    options = list('actions-box' = TRUE),                        #This adss a select all option to the drop down list so the suer does not need to select many populations one by one.
                    multiple=TRUE,                                               #Multiple populations can be selected and default is none.
                    selected=unique(SNPOI_and_meta$Population))
        ),
      mainPanel(leafletOutput("map",height=600),textOutput("MAF"))),             #Main panel will show the map
    submitButton()                                                               #There is a submit button to trigger the action from the server for when the user selects new options
  ),
  
  server=function(input,output,session){                                         #This is the server part of the application
    
    SNPOI_and_meta<-reactive({                                                   #The reactive function is very important for the application to react to the changes that the user inputs
      maf_function(snpoi_ped_function(input$snpoi))})                            #Here the dataset is updated based on the SNP input
    
    maf_pop<-reactive({                                                          #Here we run the maf determining funtion on the new dataset
      MA_function(SNPOI_and_meta())})                                           
    
    filtered_data<-reactive({                                                    #We take a certain part of the dataset based on the time range that use has selected    
      SNPOI_and_meta()[SNPOI_and_meta()$Year>=input$range[1] &
                         SNPOI_and_meta()$Year<=input$range[2] & 
                         SNPOI_and_meta()$Population %in% input$population,]})
    
    pops<-reactive({                                                             #We take only the rows with countries that the user has selected a population from.
      unique(SNPOI_and_meta()[SNPOI_and_meta()$Year>=input$range[1] & 
                                SNPOI_and_meta()$Year<=input$range[2],
                              "Population"])})
    
    time_path<-reactive({                                                        #To save what the user has decided regarding whether to draw a time path or not.
      input$timepath})
    
    output$map <- renderLeaflet({leaflet(data=filtered_data()) %>%               #We have set the output id as map up in the ui section, so now the output object map will appear there.
        setView(lng = mean(SNPOI_and_meta()$Long.),                              #We use the leaflet package to draw a base map. Here the map for initial default SNP gets drawn
                lat = mean(SNPOI_and_meta()$Lat.), zoom = 3) %>%
        addProviderTiles(providers$CartoDB.Voyager) })                           #The tiles are chosen as from one of the common versions.
    
    observe({leafletProxy("map", data=filtered_data())%>%                        #observe function executes when there is a change by the user. Here we will update the already created map according to the new user inputs  
        clearShapes()%>%clearMarkers()%>%clearControls()%>%                      #Before further mapping we make sure to clean markers or lines or legends
        addCircleMarkers(data = filtered_data()[1,], ~Long., ~Lat.,              #Coordinates of the oldest sample
                         stroke = FALSE,                                         #addCircleMarkers adds markers on the map for the given coordinates
                         fillOpacity = 0.5, label = "Start", color = "gray") %>% #Labelled as start
        addCircleMarkers(data = filtered_data()[nrow(filtered_data()),],         #Coordinates of the newest sample
                         ~Long., ~Lat.,
                         stroke = FALSE, fillOpacity = 0.5, label = "End",       #Labelled as end
                         color = "gray")%>%
        addCircleMarkers(data = filtered_data(),                                 
                         lat = ~Lat., lng = ~Long., radius=2,                    #Coordinates of samples
                         color = filtered_data()$color,                          #Markers are colored as the color column
                         label = paste0("Pop:",filtered_data()$Population,       #Markers will have labels with the information of the sample
                                        "\n","MAF by pop:",
                                        filtered_data()$MAF_bycountry,
                                        "(",maf_pop()[1],")","\n","Genotype:",
                                        filtered_data()$Genotype_group,"\n",
                                        "Sample year bp:",
                                        filtered_data()$Year)) %>%
        addLegend('bottomleft', colors = unique( filtered_data()$color),         #The legend is created according to the colors(alleles)
                  labels = unique(filtered_data()$Genotype_group), 
                  title = 'Alleles',
                  opacity = 1)})
   
    observe({if(time_path()==TRUE){leafletProxy("map", data=filtered_data()) %>% #If the user selected the time path option, the lines get drawn between samples starting from oldest to newest
        addPolylines(~Long., ~Lat., color = "black", weight=1) }})
    
    observe({if(time_path()==FALSE){leafletProxy("map", data=filtered_data()) %>% #If the tick is removed the lines are cleaned.
        clearShapes }})
    
    output$MAF<-renderText({paste0("\n","MAF:" ,maf_pop()[1],"=>",maf_pop()[2])})
    
    observe({updateSliderInput(session,                                          #The time range gets updated with this observe function because different datasets might have different oldest and newest samples
                               inputId ="range",
                               value = c(quantile(SNPOI_and_meta()$Year,0.25),
                                         quantile(SNPOI_and_meta()$Year,0.75)),
                               max =  max(SNPOI_and_meta()$Year) ,
                               min =  min(SNPOI_and_meta()$Year))})
    
    observe({updatePickerInput(session,                                          #The population options get updated with this observe function because different datasets might have different populations in them.
                               inputId ="population",
                               choices=pops(),
                               options = list('actions-box' = TRUE),
                               selected=pops())})
  }
)


