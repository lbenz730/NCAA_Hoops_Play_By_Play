### NCAA Assist Networks
### Luke Benz
### Version 2.0 (Updated 12.19.17)

library(igraph)
library(dplyr)

assist_net <- function(team, node_col, season, rmv_bench, tree, three_weights) {
  ### Read Play-by-Play File
  if(season[1] == "2016-17") {
    x <- read.csv(paste("pbp_2016_17/", team, ".csv", sep = ""), as.is = T)
    text <- " Assist Network for 2017-18 Returning Players"
    factor <- 1.25
  }else if(season[1] == "2017-18") {
    x <- suppressWarnings(try(read.csv(paste("pbp_2017_18/", team, ".csv", sep = ""), 
                                       as.is = T), silent = T))
    if(class(x) == "try-error") {
      x <- get_pbp(team)
    }
    text <- " Assist Network for 2017-18 Season"
    factor <- 1.25
    x$description <- as.character(x$description)
  }else {
    x <- get_pbp_game(season)
    opp <- setdiff(c(x$away, x$home), team)
    text <- paste(" Assist Network vs. ", opp, sep = "")
    x$description <- as.character(x$description)
    factor <- 2.5
  }
  
  ### Get Roster
  team <- gsub(" ", "_", team)
  roster <- read.csv(paste("rosters_2017_18/", team, ".csv", sep = ""), as.is = T)
  roster$Name <- gsub(" Jr.", "", roster$Name)
  games <- unique(x$game_id)
  ast <- grep("Assisted", x$description)
  x <- x[ast, ]
  
  ### Get Ast/Shot from ESPN Play Description
  splitplay <- function(description) {
    tmp <- strsplit(strsplit(description, "[.]")[[1]], " ")
    shot_maker <- paste(tmp[[1]][1:2], collapse = " ")
    assister <- paste(tmp[[2]][4:5], collapse = " ")
    return(list("shot_maker" = shot_maker, "assister" = assister))
  }
  
  x <- mutate(x, "ast" = NA, "shot" = NA)
  for(i in 1:nrow(x)) {
    play <- splitplay(x$description[i])
    x$ast[i] <- play$assister
    x$shot[i] <- play$shot_maker
  }
  
  ### Get only shots made by the team in question
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
  
  
  ### Create/Plot Undirected Network
  net <- graph.data.frame(network, directed = F)
  deg <- degree(net, mode="all")
  E(net)$weight <- network$num
  E(net)$arrow.size <- 0.3
  E(net)$edge.color <- "white"
  E(net)$width <- E(net)$weight * factor
  V(net)$color <- node_col
  
  plot(net, vertex.label.color= "black", vertex.label.cex = 0.5,
       layout= ifelse(tree, layout_as_tree,layout_in_circle),
       vertex.label.family = "Arial Black", 
       main = paste(gsub("_", " ", team), ifelse(three_weights, " Weighted", ""), text, sep = ""))  
  
  ### Add Text to Network
  text(-1.5, 1.0, paste(ifelse(three_weights, "Weighted ", ""), "Assist Frequency Leader: ", 
                        ast_data$ast[which.max(ast_data$a_freq)], " (", 
                        round(100 * max(ast_data$a_freq), 1), "%)", sep = ""), 
       cex = ifelse(three_weights, 0.8, 0.6))
  text(-1.5, 0.9, paste(ifelse(three_weights, "Weighted ", ""), "(Assisted) Shot Frequency Leader: ", 
                        shot_data$shot[which.max(shot_data$a_freq)], " (", 
                        round(100 * max(shot_data$a_freq), 1), "%)", sep = ""), 
       cex = ifelse(three_weights, 0.8, 0.6))
  text(-1.5, 0.8, paste("PageRank MVP: ", names(which.max(pagerank)), " (", 
                        round(max(pagerank), 3), ")", sep = ""))
  text(-1.5, 0.7, paste("Hub Score MVP: ", names(which.max(hubscores)), " (", 
                        round(max(hubscores), 3), ")", sep = ""))
  text(-1.5, 0.6, paste("Authority Score MVP: ", names(which.max(auth_scores)), " (", 
                        round(max(auth_scores), 3), ")", sep = ""))
  text(-1.5, 0.5, paste("Team Clustering Coefficient: ", clust_coeff, sep = ""))
  
  if(three_weights){
    text(0, -1.4, cex = 0.7,
         paste("Weighted Assist Network: Assisted 2 point shots are given weight 1, ", 
               "Assisted 3 point shots are given weight 1.5", sep = ""))
  }
  
  
  ### Return Results
  return(list("clust_coeff" = clust_coeff, "page_ranks" = pagerank, 
              "hub_scores" = hubscores, "auth_scores" = auth_scores))
}

