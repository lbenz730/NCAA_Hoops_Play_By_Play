library(dplyr)
library(magrittr)
library(ggraph)
library(igraph)

assist_net <- function(team, node_col, season, games) {
  
  ### Read File
  if(season[1] == "2016-17") {
    x <- read.csv(paste("pbp_2016_17/", team, ".csv", sep = ""), as.is = T)
    text <- " Assist Flow Chart for 2017-18 Returning Players"
    factor <- 1.25
  }
  else if(season[1] == "2017-18") {
    x <- read.csv(paste("pbp_2017_18/", team, ".csv", sep = ""), as.is = T)
    text <- " Assist Flow Chart for 2017-18 Season"
    factor <- 3
  }
  else {
    x <- get_pbp_game(season)
    opp <- setdiff(c(x$away, x$home), team)
    text <- paste(" Assist Flow Chart vs. ", opp, sep = "")
    x$description <- as.character(x$description)
    factor <- 5
  }
  roster <- read.csv(paste("rosters_2017_18/", team, ".csv", sep = ""), as.is = T)
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
  for(i in 1:nrow(roster)) {
    ast <- roster$Name[i]
    tmp <- roster[roster$Name != ast,]
    for(j in 1:nrow(tmp)) {
      index <- j + (i - 1) * nrow(tmp)
      network$ast[index] <- ast
      network$shot[index] <- tmp$Name[j]
      network$num[index] <- sum(x$ast == ast & x$shot == tmp$Name[j])
    }
  }
  
  network$a_freq <- network$num/sum(network$num)
  
  net <- graph.data.frame(network, directed = F)
  deg <- degree(net, mode="all")
  E(net)$weight <- network$num
  E(net)$arrow.size <- 0.3
  E(net)$edge.color <- "white"
  E(net)$width <- E(net)$weight * factor
  V(net)$color <- node_col
  plot(net, vertex.label.color= "black", vertex.label.cex = 0.5, 
       vertex.label.family = "Arial Black", main = paste(team, text, sep = ""))                      
  
}

