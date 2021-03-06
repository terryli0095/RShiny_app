## Packages

packages.used <- 
  c("geosphere", # For spatial methods  
    "threejs",   # threejs is used for 3-D interactive Earth Visualization
    "rworldmap", # For creating earth map
    "leaflet",   # Leaflet for R provides functions to control and integrate Leaflet, a JavaScript library for interactive maps, within R.
    "rgeos",      # Provides functions for handling operations on topologies.
    "raster",     # For raster image
    "DT",         # For creating interactive tables
    "ggplot2",
    "sp"   ,       # For Spatial processing of data
    "ggmap",       # To reverse geocode Long/Lat
    "knitr",        # TO enable 3-D visualization embedding in the HTML page
    "rglwidget",
    "rgl",
    "plyr",
    "reshape2",
    "maptools",
    "shiny",
    "googleVis"
  )

# check packages that need to be installed.
packages.needed=setdiff(packages.used, 
                        intersect(installed.packages()[,1], 
                                  packages.used))
# install additional packages
if(length(packages.needed)>0){
  install.packages(packages.needed, dependencies = TRUE)
}

#load the packages
library("plyr")
library("reshape2")
library("geosphere")
library("threejs")
library("rworldmap")
library("leaflet")
library("rgeos")
library("raster")
library("DT")
library("ggplot2")
library("sp")
library("ggmap")
library("knitr")
library("rglwidget")
library("rgl")
library("maptools")
library("shiny")
library("googleVis")

## UI Function

ui<- navbarPage(
  
  ##link to css.file
  theme = "bootstrap.css",
  
  ##Project Title
  "Flowing in and Flowing out",
  
  ## 3D Globe tab
  tabPanel("3D Globe",
           titlePanel("Coffee ,tea, and others traded between US and the world"),
           sidebarLayout(
             sidebarPanel(
               radioButtons(inputId = "type",
                            label  = "Choose import/export",
                            choices = c('Export','Import'),
                            selected ='Export'),
               sliderInput(inputId = "year_3D",
                           label = "Select a year",
                           value = 1996, min =1996, max =2016),
               sliderInput(inputId = "number_countries",
                           label = "Top Countries in Trade",
                           value = 10,min = 1,max = 50),
               selectInput(inputId = "commodity_3D",
                           label  = "Select the commodity",
                           choices = c('Annual Aggregate','Chocolate', 'Coffee','Cocoa','Spices','Tea'),
                           selected ='Coffee'),
               width = 3
             ),
             mainPanel(
               globeOutput("Globe",width="100%",height="600px"),
               plotOutput("ggplot",width="100%",height="200px")
             )
           )
  ),
  ## end 3D Globe tab
  
  ## 2D Map tab
  tabPanel("2D Map",
           titlePanel("Coffee ,tea, and others traded between US and the world"),
           sidebarLayout(
             sidebarPanel(
               radioButtons(inputId = "type_2D",
                            label  = "Choose import/export",
                            choices = c('Export','Import'),
                            selected ='Export'),
               sliderInput(inputId = "year_2D",
                           label = "Select a year",
                           value = 2016, min =1996, max =2016),
               sliderInput(inputId = "num_countries",
                           label = "Top Countries in Trade",
                           value = 30,min = 1,max = 50),
               selectInput(inputId = "commodity_2D",
                           label  = "Select the commodity",
                           choices = c('Annual Aggregate','Chocolate', 'Coffee','Cocoa','Spices','Tea'),
                           selected ='Coffee'),
               width = 3
             ),
             mainPanel(
               leafletOutput("mymap",width = "100%", height = 600)
             )
           )
  ),
  ## end 2D Map tab
  
  ## Summary Statistics tab
  navbarMenu("Summary Statistics",
             
             ### Motion Chart
             tabPanel("Motion Chart",
                      mainPanel(
                        htmlOutput("view")
                      )
             ),
             ### end Motion Chart
             
             tabPanel("Component B")
  ),
  ## end Summary Statistics tab
  
  tabPanel("More")
)

## preprocess work, Load dataframe already prepared for plotting
input_data =  read.csv("../data/mydata.csv",header = T,as.is = T)
input_data = input_data[!is.na(input_data$longitude),]
input_data = input_data[input_data$value != 0,]
#create 6 level for value data whose magnitude ranges from 1e3 tp 1e8
input_data$log = ceiling(log(input_data$value)/3)-2
## end preprocess data

## map creation preprocess
data(wrld_simpl) # Basic country shapes
bgcolor = "#000000"
arc_colors = c("#998080","#809980","#808099","#999980","#809999","#998099")
map_pal = data.frame(AnnualAggregate = c("red"),Chocolate = c("blue"),Coffee = c("green"),COCOA = c("#ffe9bf"),Spices = c("pink"),Tea = c("orange"))
names(map_pal)[1] = "Annual Aggregate"
## end preprocess map


## Server function

server<- function(input, output){
  
  ## 3D Globe
  output$Globe <- renderGlobe({
    ##### subset dataframe
    temp = input_data
    temp = subset(temp,Commodity_Name == as.character(input$commodity_3D))
    temp = subset(temp,Year == as.integer(input$year_3D))
    temp = subset(temp,type == as.character(input$type))
    temp = arrange(temp,desc(value))[1:input$number_countries,]
    index = match(input$commodity_3D,c('Annual Aggregate','Chocolate', 'Coffee','Cocoa','Spices','Tea'))
    maxValue = log(max(temp$value))
    ##### end subset
    
    ##### map colors creation
    earth <- tempfile(fileext=".jpg")
    jpeg(earth, width=2048, height=1024, quality=100, bg=bgcolor, antialias="default")
    par(mar = c(0,0,0,0),    pin = c(4,2),    pty = "m",    xaxs = "i",
        xaxt = "n",          xpd = FALSE,    yaxs = "i",    yaxt = "n")
    
    map_palette = map_pal[,index]
    clrs = rep('#050505', length(wrld_simpl$NAME))
    names(clrs) = wrld_simpl$NAME
    clrs[temp$Country] = alpha(map_palette[1], log(temp$value)/maxValue*0.1)
    
    plot(wrld_simpl,  col=clrs,   bg=bgcolor,  border="#757575", cex = 0.1,  ann=FALSE,
         axes=FALSE,  xpd=FALSE,  xlim=c(-180,180), ylim=c(-90,90),  setParUsrBB=TRUE)
    
    graphics.off()
    ##### end map creation
    
    ##### globe plotting
    globejs(earth, bg="black", emissive="#aaaacc",
            fov = 38,
            arcs=temp[,c(4,3,9,8)],
            arcsHeight=0.35, 
            arcsLwd=2, 
            arcsColor = arc_colors[index], 
            arcsOpacity=1,
            atmosphere=TRUE, height=600, width = 600
    )
  })
  ## end 3D Globe
  
  
  
  ## ggplot
  output$ggplot <- renderPlot({
    
    ##### subset dataframe
    temp = input_data
    temp = subset(temp,Commodity_Name == as.character(input$commodity_3D))
    temp = subset(temp,Year == as.integer(input$year_3D))
    temp = subset(temp,type == as.character(input$type))
    temp = arrange(temp,desc(value))[1:input$number_countries,]
    index = match(input$commodity_3D,c('Annual Aggregate','Chocolate', 'Coffee','Cocoa','Spices','Tea'))
    maxValue = log(max(temp$value))
    map_palette = map_pal[,index]
    clrs = rep('#050505', length(wrld_simpl$NAME))
    names(clrs) = wrld_simpl$NAME
    clrs[temp$Country] = alpha(map_palette[1], log(temp$value)/maxValue*0.1)
    ##### end subset
    
    g = ggplot(data = temp, aes(x = Country, y = value)) + theme(axis.text.x = element_text(angle = 45, hjust = 1)) +theme(legend.position="none") + theme(legend.background = element_rect(),panel.grid.major.y = element_blank(), panel.grid.minor.y = element_blank()) + geom_bar(stat = "identity", aes(fill=temp$value)) + scale_fill_gradient(low = "#a7a7a7", high = "#dbdbdb") + scale_x_discrete(limits = temp$Country) + theme(panel.background = element_rect(fill = "#000000")) + theme(plot.background = element_rect(fill = "#000000")) + theme(panel.background = element_rect(colour = "#050505"))
    g
    
  })
  ## end ggplot
  
  
  
  ## 2D map
  output$mymap <- renderLeaflet({
    ## Control Icon size and looks
    levelIcon <- iconList(
      level1 = makeIcon("css-ShinyApp_split/www/trade-icon_1.png", iconAnchorX = 19, iconAnchorY = 19),
      level2 = makeIcon("css-ShinyApp_split/www/trade-icon_2.png", iconAnchorX = 19, iconAnchorY = 19),
      level3 = makeIcon("css-ShinyApp_split/www/trade-icon_3.png", iconAnchorX = 19, iconAnchorY = 19),
      level4 = makeIcon("css-ShinyApp_split/www/trade-icon_4.png", iconAnchorX = 19, iconAnchorY = 19),
      level5 = makeIcon("css-ShinyApp_split/www/trade-icon_5.png", iconAnchorX = 19, iconAnchorY = 19),
      level6 = makeIcon("css-ShinyApp_split/www/trade-icon_6.png", iconAnchorX = 19, iconAnchorY = 19),
      level7 = makeIcon("css-ShinyApp_split/www/trade-icon_7.png", iconAnchorX = 19, iconAnchorY = 19),
      level8 = makeIcon("css-ShinyApp_split/www/trade-icon_8.png", iconAnchorX = 19, iconAnchorY = 19)
    )
    Icon = makeIcon(iconAnchorX = 19, iconAnchorY = 19,
                    iconWidth = 38, iconHeight = 38)
    ## subset the data
    US = data.frame(Country = "US",longitude = -95.71289,latitude = 37.09024)
    ##### subset dataframe
    tmp = input_data
    tmp = subset(tmp,Commodity_Name == as.character(input$commodity_2D))
    tmp = subset(tmp,Year == as.integer(input$year_2D))
    tmp = subset(tmp,type == as.character(input$type_2D))
    tmp = arrange(tmp,desc(value))[1:input$num_countries,]
    rank = 1:nrow(tmp)
    Log = paste("level",ceiling(log(tmp$value)/2)-3,sep = "")
    tmp$rank = paste(tmp$Country,"<br/>",
                     "ranks No.",rank,"<br/>",
                     "Annual Trade Value: $",tmp$value,"<br/>",sep = "",
                     "<a href='https://en.wikipedia.org/wiki/",tmp$Country,"'>Wikipedia Page</a>","<br/>",
                     "<a href='https://www.youtube.com/results?search_query=Discover",tmp$Country,"'>Youtube Page</a>"
    )
    index = match(input$commodity_2D,c('Annual Aggregate','Chocolate', 'Coffee','Cocoa','Spices','Tea'))
    Colors = c("#231d65","#276d98","#2586a4","#3c6049","#216957","#4abf8c","#9eae1e","#eff09e")
    Labels = paste("Level:",1:8)
    ##### end subset      
    leaflet(tmp)%>%addProviderTiles("Esri.WorldStreetMap")%>%
      addMarkers(popup=~rank,icon = ~levelIcon[Log])%>%
      addMarkers(data = US, 
                 popup=~Country,icon = ~Icon)%>%  
      setView(lng=-30,lat=28,zoom=3)%>%#put US in the centre
      addLegend("bottomright", colors = Colors, labels = Labels,
                title = "Value From Large to Small",
                labFormat = labelFormat(prefix = "$"),
                opacity = 1)
  })
  ## end 2D map
  
  
  
  ## MotionChart
  output$view <- renderGvis({
    
    gvisMotionChart(country, idvar='Country',timevar = 'Year', sizevar='Coffee', options=list(width="800", height="800"))
  })
  ## end MotionChart
  
  
}


## Calling shiny App
shinyApp(ui = ui, server= server)