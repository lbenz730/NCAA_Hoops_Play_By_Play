library(shiny)
source("global.R")

shinyServer(function(input, output, session) {
  observeEvent(input$select_team, {
    if(input$team != " ") {
      schedule <- read.csv(paste("schedules_2017_18/", 
                                 gsub(" ", "_", dict$ESPN[dict$NCAA == input$team]),
                                 ".csv", sep = ""))
      choose_opp <- paste(schedule$opponent, " (", schedule$date, ") ", sep = "")
      output$selectOpp <- renderUI({
        ui = mainPanel(
          p(br()),
          fluidRow(column(10, offset = 0, selectInput("opponent", label = "Select Opponent (Or Entire Season)", choices = c("Entire 2017-18 Season", choose_opp), selected = " ", multiple = FALSE,
                                                      selectize = TRUE, width = NULL, size = NULL))),
          fluidRow(h3("Network Features"),
                   column(4, radioButtons("three_weights", label = h5("Weighted Network"),
                                          choices = list("True" = TRUE, "False" = FALSE))),
                   column(4, radioButtons("tree", label = h5("Network Structure"),
                                          choices = list("Circle" = FALSE, "Tree" = TRUE))),
                   column(4, radioButtons("rmv_bench", label = h5("Bench Players"),
                                          choices = list("Remove" = TRUE, "Keep" = FALSE)))),
          fluidRow(column(2, offset = 2, actionButton("render_net", "Render Network")),
                   column(2, offset = 2, actionButton("refresh", "Select New Team")))
        )
      })
    }
    else{
      session$sendCustomMessage(type = "message",
                                message = "Error: Please select a team.")
    }
    
  })
  
  np <- eventReactive(input$render_net, {
    #schedule <- get_schedule(dict$ESPN[dict$NCAA == input$team])
    schedule <- read.csv(paste("schedules_2017_18/", 
                               gsub(" ", "_", dict$ESPN[dict$NCAA == input$team]),
                               ".csv", sep = ""))
    
    ### Plot Netwok
    team <- dict$ESPN[dict$NCAA == input$team]
    if(input$opponent == "Entire 2017-18 Season") {
      selected_season <- "2017-18"
    }
    else{
      schedule$day_opp <- paste(schedule$opponent, " (", schedule$date, ") ", sep = "")
      selected_season <- schedule$game_id[schedule$day_opp == input$opponent]
      # x <- suppressWarnings(try(get_pbp_game(selected_season), silent = T))
      # if(is.null(x)) {
      #   session$sendCustomMessage(type = "message",
      #                             message = "Error: Play-By-Play Data Not Available for this Game. Please Select Another Game.")
      #   plot_flag <- F
      # }
    }
    
    info <- try(assist_net(team, node_col = dict$network_col[dict$NCAA == input$team], season = selected_season,
                           rmv_bench = input$rmv_bench, tree = input$tree, three_weights = input$three_weights))
    if(class(info) == "try-error") {
      showNotification("Play-By-Play Not Available for this game", type = "error", duration = 10)
    }
    else{
      html <- paste("<ul><li>", "Assist Frequency Leader: ", names(info$ast_freq)[which.max(info$ast_freq)], " (", 
                    round(max(info$ast_freq) * 100, 1), "%)</li>", sep = "")
      html <- paste(html, "<li>", "(Assisted) Shot Frequency Leader: ", names(info$shot_freq)[which.max(info$shot_freq)],
                    " (", round(max(info$shot_freq) * 100, 1), "%)</li>", sep = "")
      html <- paste(html, "<li>", "Page Rank MVP: ", names(info$page_ranks)[which.max(info$page_ranks)],
                    " (", round(max(info$page_ranks), 3), ")</li>", sep = "")
      html <- paste(html, "<li>", "Hub Score MVP: ", names(info$hub_scores)[which.max(info$hub_scores)],
                    " (", round(max(info$hub_score), 3), ")</li>", sep = "")
      html <- paste(html, "<li>", "Authority Score MVP: ", names(info$auth_scores)[which.max(info$auth_scores)],
                    " (", round(max(info$auth_scores), 3), ")</li>", sep = "")
      html <- paste(html, "<li>", "Team Clustering Coefficient: (", round(info$clust_coeff, 3), ")</li></ul>", sep = "")
      
      output$information <- renderUI(HTML(html))
      output$stats <- renderText(HTML("<b>Network Statistics</b>"))
    }
  })
  
  output$networkPlot <- renderPlot(np(), height = 800, width = 800)
  
  observeEvent(input$refresh, {
    session$reload()
  })
  
})

