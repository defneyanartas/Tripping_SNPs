


source("ped_script.R")

shinyApp(
  ui=fluidPage(
    titlePanel("Tripping SNPs"),
    sidebarLayout(
      sidebarPanel(
        textInput("snpoi",label="Type in SNP of interest",value="rs6696609",placeholder="rs#######"),
        sliderInput(inputId = "range", 
                    label = "Select the year Before present", 
                    value = c(3000,4000), max =  max(SNPOI_and_meta$Year),min =  min(SNPOI_and_meta$Year)),
        checkboxInput(inputId="timepath",label="Show time path",value=FALSE),
        pickerInput(inputId="population", label="Select the population(s) of interest",choices=unique(SNPOI_and_meta$Population),options = list('actions-box' = TRUE), multiple=TRUE)
      ),
      mainPanel(leafletOutput("map",height=600),textOutput("MAF"))),
    submitButton()
  ),
  server=function(input,output,session){
    SNPOI_and_meta<-reactive({maf_function(snpoi_ped_function(input$snpoi))})
    maf_pop<-reactive({MA_function(SNPOI_and_meta())})
    filtered_data<-reactive({SNPOI_and_meta()[SNPOI_and_meta()$Year>=input$range[1] & SNPOI_and_meta()$Year<=input$range[2] & SNPOI_and_meta()$Population %in% input$population,]})
    pops<-reactive({unique(SNPOI_and_meta()[SNPOI_and_meta()$Year>=input$range[1] & SNPOI_and_meta()$Year<=input$range[2],"Population"])})
    time_path<-reactive({input$timepath})
    output$map <- renderLeaflet({leaflet(data=filtered_data()) %>%
        setView(lng = mean(SNPOI_and_meta()$Long.), lat = mean(SNPOI_and_meta()$Lat.), zoom = 3) %>%
        addProviderTiles(providers$CartoDB.Voyager) })
    observe({leafletProxy("map", data=filtered_data())%>%
        clearShapes()%>%clearMarkers()%>%clearControls()%>%
        addCircleMarkers(data = filtered_data()[1,], ~Long., ~Lat., stroke = FALSE,
                         fillOpacity = 0.5, label = "Start", color = "gray") %>%
        addCircleMarkers(data = filtered_data()[nrow(filtered_data()),],  ~Long., ~Lat.,
                         stroke = FALSE, fillOpacity = 0.5, label = "End",
                         color = "gray")%>%
        addCircleMarkers(data = filtered_data(), lat = ~Lat., lng = ~Long., radius=2,
                         color = filtered_data()$color, 
                         label = paste0("Pop:",filtered_data()$Population,"\n","MAF by pop:",filtered_data()$MAF_bycountry,"(",maf_pop()[1],")","\n","Genotype:",filtered_data()$Genotype_group,"\n","Sample year bp:",filtered_data()$Year)) %>%
        #clusterOptions=markerClusterOptions()
        addLegend('bottomleft', colors = unique( filtered_data()$color), 
                  labels = unique(filtered_data()$Genotype_group), 
                  title = 'Alleles',
                  opacity = 1)})
    observe({if(time_path()==TRUE){leafletProxy("map", data=filtered_data()) %>% addPolylines(~Long., ~Lat., color = "black", weight=1) }})
    observe({if(time_path()==FALSE){leafletProxy("map", data=filtered_data()) %>% clearShapes }})
    output$MAF<-renderText({paste0("\n","MAF:" ,maf_pop()[1],"=>",maf_pop()[2])})
    observe({updateSliderInput(session,inputId ="range",value = c(quantile(SNPOI_and_meta()$Year,0.25),quantile(SNPOI_and_meta()$Year,0.75)), max =  max(SNPOI_and_meta()$Year) ,min =  min(SNPOI_and_meta()$Year))})
    observe({updatePickerInput(session,inputId ="population",choices=pops(),options = list('actions-box' = TRUE))})
  }
)


