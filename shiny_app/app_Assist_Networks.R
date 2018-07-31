### NCAA Assist Networks
### Luke Benz
### Version 3.0 (Updated 7.30.18)

library(igraph)
library(dplyr)

assist_net <- function(team, node_col, season, rmv_bench, tree, three_weights) {
  dict <- read.csv("ESPN_NCAA_Dict.csv", as.is = T)
  text_team <- dict$ESPN_PBP[dict$ESPN == team]
  
  ### Read Play-by-Play File
  if(season[1] == "2016-17") {
    x <- read.csv(paste("pbp_2016_17/", gsub(" ", "_", team), ".csv", sep = ""), as.is = T)
    text <- " Assist Network for 2017-18 Returning Players"
    factor <- 0.75
  }else if(season[1] == "2017-18") {
    x <- read.csv(paste("pbp_2017_18/", gsub(" ", "_", team), ".csv", sep = ""),  as.is = T)
    factor <- 0.75
    text <- " Assist Network for 2017-18 Season"
    x$description <- as.character(x$description)
  }else {
    x <- read.csv(paste("pbp_2017_18/", gsub(" ", "_", team), ".csv", sep = ""),  as.is = T)
    factor <- 0.75
    x <- filter(x, game_id == season)
    # x <- suppressWarnings(try(get_pbp_game(season), silent = T))
    # if(class(x) == "try-error") {
    #   return("Play-by-Play Data Not Available")
    # }
    opp <- setdiff(c(x$away, x$home), text_team)
    text <- paste(" Assist Network vs. ", opp, sep = "")
    x$description <- as.character(x$description)
    factor <- 1.25
  }
  
  ### Get Roster
  team <- gsub(" ", "_", team)
  roster <- read.csv(paste("rosters_2017_18/", team, ".csv", sep = ""), as.is = T)
  roster$Name <- gsub("Jr.", "Jr", roster$Name)
  games <- unique(x$game_id)
  ast <- grep("Assisted", x$description)
  x <- x[ast, ]
  if(team == "VMI") {
    roster <- roster[-8,]
  }
  
  ### Get Ast/Shot from ESPN Play Description
  splitplay <- function(description) {
    tmp <- strsplit(strsplit(description, "Assisted")[[1]], " ")
    n1 <- grep("made", tmp[[1]])
    n2 <- length(tmp[[2]])
    tmp[[2]][n2] <- substring(tmp[[2]][n2], 1, nchar(tmp[[2]][n2]) - 1)
    shot_maker <- paste(tmp[[1]][1:(n1-1)], collapse = " ")
    assister <- paste(tmp[[2]][3:n2], collapse = " ")
    return(list("shot_maker" = shot_maker, "assister" = assister))
  }
  
  x <- mutate(x, "ast" = NA, "shot" = NA)
  for(i in 1:nrow(x)) {
    play <- splitplay(x$description[i])
    x$ast[i] <- play$assister
    x$shot[i] <- play$shot_maker
  }
  
  ### Get only shots made by the team in question
  x$ast <- gsub("Jr.", "Jr", x$ast)
  x$shot <- gsub("Jr.", "Jr", x$shot)
  x <- x[is.element(x$ast, roster$Name), ]
  
  sets <- 2 * choose(nrow(roster), 2)
  network <- data.frame("ast" = rep(NA, sets), 
                        "shot" = rep(NA, sets),
                        "num" = rep(NA, sets))
  
  ### Adjust Three Point Weights in Network
  x$weights <- 1
  if(three_weights){
    threes <- grep("Three Point", x$description)
    x$weights[threes] <- 1.5
  }
  
  ### Aggregate Assists
  for(i in 1:nrow(roster)) {
    ast <- roster$Name[i]
    tmp <- roster[roster$Name != ast,]
    for(j in 1:nrow(tmp)) {
      index <- j + (i - 1) * nrow(tmp)
      network$ast[index] <- ast
      network$shot[index] <- tmp$Name[j]
      network$num[index] <- sum(x$weights[x$ast == ast & x$shot == tmp$Name[j]])
    }
  }
  
  network$a_freq <- network$num/sum(network$num)
  
  ### Remove Bench
  if(rmv_bench) {
    network <- network[network$a_freq > 0,]
  }
  
  ### Team Ast/Shot Distributions
  ast_data <- aggregate(a_freq ~ ast, data = network, sum)
  shot_data <- aggregate(a_freq ~ shot, data = network, sum)
  
  ### Create Temporary Directed Network 
  net <- graph.data.frame(network, directed = T)
  deg <- degree(net, mode="all")
  E(net)$weight <- network$num
  
  ### Compute Clustering Coefficient
  clust_coeff <- round(transitivity(net, type = "global"), 3)
  
  ### Compute Page Rank
  pagerank <- sort(page_rank(net)$vector, decreasing = T)
  
  ### Compute Hub Score
  hubscores <- sort(hub_score(net, scale = F)$vector, decreasing = T)
  
  ### Compute Authority Scores
  auth_scores <- sort(authority_score(net, scale = F)$vector, decreasing = T)
  
  ### Compute Assist Frequency Data
  ast_freq <- ast_data$a_freq
  names(ast_freq) <- ast_data$ast
  
  ### Compute Shot Frequency Data
  shot_freq <- shot_data$a_freq
  names(shot_freq) <- shot_data$shot
  
  
  ### Create/Plot Undirected Network
  deg <- degree(net, mode="all")
  E(net)$weight <- network$num
  E(net)$arrow.size <- 1.2
  E(net)$edge.color <- "white"
  E(net)$width <- E(net)$weight * factor
  V(net)$color <- node_col
  if(season %in% c("2016-17", "2017-18")) {
    labs <- NA
  }
  else{
    labs <- as.character(network$num)
  }
  
  
  plot(net, vertex.label.color= "black", vertex.label.cex = 1, 
       edge.curved = 0.3, edge.label = labs, edge.label.cex = 1.2,
       edge.label.color = "black",
       layout= ifelse(tree, layout_as_tree,layout_in_circle),
       vertex.label.family = "Arial Black", 
       main = paste(text_team, ifelse(three_weights, " Weighted", ""), text, sep = ""))  
  
  
  ### Return Results
  return(list("clust_coeff" = clust_coeff, "page_ranks" = pagerank, 
              "hub_scores" = hubscores, "auth_scores" = auth_scores,
              "ast_freq" = ast_freq, "shot_freq" = shot_freq))
}


