### NCAA Assist Networks
### Luke Benz
### Version 1.4 (Updated 12.16.17)

library(igraph)

assist_net <- function(team, node_col, season, rmv_bench, tree) {
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
    factor <- 1.75
  }else {
    x <- get_pbp_game(season)
    opp <- setdiff(c(x$away, x$home), team)
    text <- paste(" Assist Network vs. ", opp, sep = "")
    x$description <- as.character(x$description)
    factor <- 5
  }
  
  ### Get Roster
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
  
  ### Remove Bench
  if(rmv_bench) {
    network <- network[network$a_freq > 0,]
  }
  
  ### Team Ast/Shot Distributions
  ast_data <- aggregate(a_freq ~ ast, data = network, sum)
  shot_data <- aggregate(a_freq ~ shot, data = network, sum)
  
  ### Create Network
  net <- graph.data.frame(network, directed = F)
  deg <- degree(net, mode="all")
  E(net)$weight <- network$num
  E(net)$arrow.size <- 0.3
  E(net)$edge.color <- "white"
  E(net)$width <- E(net)$weight * factor
  V(net)$color <- node_col
  
  ### Plot Network
  plot(net, vertex.label.color= "black", vertex.label.cex = 0.5,
       layout= ifelse(tree, layout_as_tree,layout_in_circle),
       vertex.label.family = "Arial Black", main = paste(team, text, sep = ""))  
  
  ### Compute and Return Clustering Coefficient
  clust_coeff <- round(transitivity(net, type = "global"), 3)
  print(paste("Clustering Coefficient: ", clust_coeff))
  return(clust_coeff)
}

