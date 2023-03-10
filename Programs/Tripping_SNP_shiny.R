install.packages("shiny")
library(shiny)
install.packages("leaflet")
library(leaflet)
library(dplyr)
###########################################



shinyApp(
  ui=fluidPage(
    titlePanel("Tripping SNPs"),
    sidebarLayout(
      sidebarPanel(
        textInput("snpoi",label="Type in SNP of interest",value="rs6696609",placeholder="rs#######"),
        sliderInput(inputId = "range", 
                    label = "Select the year Before present", 
                    value = c(3000,4000), max =  max(SNPOI_and_meta$Year),min =  min(SNPOI_and_meta$Year)),
        checkboxInput(inputId="timepath",label="Show time path",value=FALSE)
      ),
      mainPanel(leafletOutput("map",height=600),textOutput("MAF"))),
    #textOutput("text"),
    submitButton()
  ),
  server=function(input,output,session){
    SNPOI_and_meta<-reactive({snpoi_ped_function(input$snpoi)})
    filtered_data<-reactive({maf_function(SNPOI_and_meta()[SNPOI_and_meta()$Year>=input$range[1] & SNPOI_and_meta()$Year<=input$range[2],])})
    maf_pop<-reactive({MA_function(filtered_data())})
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
                         label = filtered_data()$MAF_bycountry) %>%
                         #clusterOptions=markerClusterOptions()
        addLegend('bottomleft', colors = unique( filtered_data()$color), 
                  labels = unique(filtered_data()$Genotype_group), 
                  title = 'Alleles',
                  opacity = 1)})
      observe({if(time_path()==TRUE){leafletProxy("map", data=filtered_data()) %>% addPolylines(~Long., ~Lat., color = "black", weight=1) }})
      observe({if(time_path()==FALSE){leafletProxy("map", data=filtered_data()) %>% clearShapes }})
      output$MAF<-renderText({paste0("\n","MAF for selected time period:" ,maf_pop()[1],maf_pop()[2])})
  
    }
)

??checkboxGroupInput
