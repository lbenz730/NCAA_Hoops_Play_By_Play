library(dplyr)

dict <- read.csv("ESPN_NCAA_Dict.csv", as.is = T)
games <- read.csv("pbp_2016_17/all_games.csv", as.is = T)
x <- read.csv("pbp_2016_17/NCAA_Hoops_Results_6_29_2017.csv", as.is = T)

### Predict Missing ESPN Line 
get_line <- function(gameID) {
  ### Get Teams
  teams <- games %>%
    filter(game_id ==  gameID) %>% 
    select(away, home)
  away <- teams$away[1]
  home <- teams$home[1]
  
  ### Convert to NCAA Names
  away <- dict$NCAA[dict$ESPN == away]
  home <- dict$NCAA[dict$ESPN == home]
  
  ### Get Predicted Line
  if(length(home) == 0 | length(away) == 0) {
    return(NA)
  }
  game <- x %>% filter(team == home, opponent == away, location == "H")
  if(nrow(game) == 0) {
    game <- x %>% filter(team == home, opponent == away, location == "N")
    if(nrow(game) == 0) {
      return(NA)
    }
  }
  return(game$predscorediff[1])
}


### Determine if home team won
is.win <- function(gameID) {
  game_data <- games[games$game_id == gameID & games$secs_remaining == 0,]
  game_data <- game_data[1,]
  return(as.numeric(game_data$home_score > game_data$away_score))
}

### Fill in Missing Lines and Wins
gameIDs <- unique(games$game_id)
games$win <- NA
wins <- apply(as.data.frame(gameIDs), 1, is.win)
lines <- apply(as.data.frame(gameIDs), 1, get_line)

for(i in 1:length(gameIDs)) {
  print(i)
  if(is.na(games$home_favored_by[games$game_id == gameIDs[i]][1])) {
    games$home_favored_by[games$game_id == gameIDs[i]] <- lines[i]
  }
  games$win[games$game_id == gameIDs[i]] <- wins[i]
}

games$scorediff <- games$home_score - games$away_score

### Remove Problematic Games
these <- (games$scorediff == 0 & games$secs_remaining == 0) | (games$scorediff > 0 & games$win == 0 & games$secs_remaining == 0)| (games$scorediff < 0 & games$win == 1 & games$secs_remaining == 0)
bad_ids <- games$game_id[these]
games <- games[!(games$game_id %in% bad_ids),]
these <- games$secs_remaining > 2700
bad_ids <- games$game_id[these]
games <- games[!(games$game_id %in% bad_ids),]

### Get Pre Game Prior
prior <- glm(wins ~ predscorediff, data = x, family = binomial)
tmp <- data.frame(wins = games$win, predscorediff = games$home_favored_by)
games$pre_game_prob <- predict(prior, newdata = tmp, type = "response")


### Fit Series of Logistic Model
secs <- c(0:29, seq(30, 60, 2), seq(70, 2700, 10))
wp_hoops <- list()

for(i in 1:(length(secs) - 1)){
  print(i)
  wp_hoops[[i]] <- suppressWarnings(glm(win ~  scorediff + pre_game_prob, 
                                        data = games[games$secs_remaining >= secs[i] & games$secs_remaining < secs[i+1], ], 
                                        family = binomial))
}

### Save Model
saveRDS("wp_hoops.rds")
