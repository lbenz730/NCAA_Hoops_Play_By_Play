library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("College Basketball Assist Networks"),
  sidebarPanel(
    p(align = "center", "Created By: ", br(), 
      a("Luke Benz", href = "http://www.lukebenz.com"),
      br(), "President, ", a("Yale Undergraduate Sports Analytics Group", 
                             href = "http://sports.sites.yale.edu"), br(), "January 2018"),
    p(align = "left", "An", span("R Shiny", style = "color:blue") ,"application for creating college 
basketball assist networks."),
    p(align = "left", "To begin, select a team for which you desire to create an assist network. 
      Next, you will be prompted to select a game from this season for which to see the network.
      You may also have the option to choose the entire 2017-18 season's worth of data to compile a network
      for the entire season. Please note that if this option is selected, the network will need about 20-30 seconds
      to render, as the application needs to scrape data from ESPN. Networks takes about 3-5 seconds to load for a single game.", tags$br(),  "Finally, you'll be able to toggle with three network features."),
    
    p(align = "left", tags$li(tags$b("Weighted Network:"), tags$br(), "If", tags$code(TRUE), "asssisted three point shots will
be given 1.5 edge weight in the network, while assisted two point shows will be given 1.0 edge weight in the network. If", tags$code(FALSE), "all
                               assisted shots will be given 1.0 weight in the network."), 
    tags$li(tags$b("Network Structure")), "If", tags$code("Tree"), "the network will be drawn using a rooted tree structure. If", tags$code("Circle"), 
"a circular structure will be used to drawn the network. Ciclcular structures tend to work better for visualizing the entire season,
while tree structures tend to work better for single game networks."),
tags$li(tags$b("Remove Bench"), tags$br(), "If", tags$code(TRUE), "the network will be drawn using only players who have recorded an assist or assisted basket this season. If", tags$code(FALSE), 
"all players will be used in drawing the network."),

p(align = "left", tags$br(), "Simply click the network and drag to desktop to save the network as an image file (.png). The below network statistics will be displayed
  upon rendering of the graph."),

p(align = "left", tags$br(), "NOTE: In order to select a new team to examine, you'll need to click the \"Select New Team\" button. You may examine
numerous networks for the same team without using this reset button."),

p(align = "left", tags$b(tags$u("Glossary")), 
  tags$li(tags$b("Assisted Frequency Leader:"), tags$br(),  "Player with highest percentage of assists in network"),
  tags$li(tags$b("(Assisted) Shot Frequency Leader:"), tags$br(),  "Player with highest percentage of assited field goals in network"),
  tags$li(tags$b(a("Page Rank MVP:", href = "https://en.wikipedia.org/wiki/PageRank")), tags$br(),  "Most important all-around player in network, calculated using the Google Page Rank Algorithm."),
  tags$li(tags$b(a("Hub Score MVP:", href = "https://en.wikipedia.org/wiki/HITS_algorithm")), tags$br(),  "Most important assister in the the network. (Scale 0-1)"),
  tags$li(tags$b(a("Authroity Score MVP:", href = "https://en.wikipedia.org/wiki/HITS_algorithm")), tags$br(),  "Most important reciever of assists in the network (Scale 0-1)"),
  tags$li(tags$b(a("Team Clustering Coefficient:", href = "https://en.wikipedia.org/wiki/Clustering_coefficient")), tags$br(),  "Degreee of clustering within the network. (Scale 0-1).")),

fluidRow(column(12, offset = 0, p(align = "left", 
                                  htmlOutput("stats"), uiOutput("information"))))
),
  
  mainPanel(
    ### Sidebar with a slider input for number of bins 
    fluidRow(column(5, offset = 1, selectInput("team", label = "Select Team", choices = c(" ", dict$NCAA), selected = " ", multiple = FALSE,
                selectize = TRUE, width = NULL, size = NULL))),
    
    tags$head(tags$script(src = "message.js")),
    fluidRow(column(2, offset = 2, actionButton("select_team", "Select Team"))),
    uiOutput("selectOpp"),
    plotOutput("networkPlot")
   )


))