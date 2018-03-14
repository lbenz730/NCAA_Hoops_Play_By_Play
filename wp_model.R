library(dplyr)

dict <- read.csv("ESPN_NCAA_Dict.csv", as.is = T)
games_2016 <- read.csv("pbp_2016_17/all_games.csv", as.is = T)
games_2017 <- read.csv("pbp_2017_18/2017_18_mid_season.csv", as.is = T)
x <- read.csv("pbp_2016_17/NCAA_Hoops_Results_6_29_2017.csv", as.is = T)
y <- read.csv("pbp_2017_18/2017_midseason_predictions.csv", as.is = T)

games_2016$year <- 2016
games_2017$year <- 2017
games <- rbind(games_2016, games_2017)


### Predict Missing ESPN Line 
get_line <- function(gameID, year) {
  ### Get Teams
  teams <- games[games$game_id == gameID,]
  away <- teams$away[1]
  home <- teams$home[1]
  
  ### Convert to NCAA Names
  away <- dict$NCAA[dict$ESPN == away]
  home <- dict$NCAA[dict$ESPN == home]
  
  ### Get Predicted Line
  if(length(home) == 0 | length(away) == 0) {
    return(NA)
  }
  
  if(year == 2016) {
    game <- x %>% filter(team == home, opponent == away, location == "H")
    if(nrow(game) == 0) {
      game <- x %>% filter(team == home, opponent == away, location == "N")
      if(nrow(game) == 0) {
        return(NA)
      }
    }
    return(game$predscorediff[1])
  }
  else{
    game <- y %>% filter(team == home, opponent == away, location == "H")
    if(nrow(game) == 0) {
      game <- y %>% filter(team == home, opponent == away, location == "N")
      if(nrow(game) == 0) {
        return(NA)
      }
    }
    return(game$predscorediff[1])
  }
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

for(i in 1:length(gameIDs)) {
  print(i)
  if(is.na(games$home_favored_by[games$game_id == gameIDs[i]][1])) {
    games$home_favored_by[games$game_id == gameIDs[i]] <- 
      get_line(gameIDs[i], year = games$year[games$game_id == gameIDs[i]][1])
  }
  games$win[games$game_id == gameIDs[i]] <- is.win(gameIDs[i])
}

games$scorediff <- games$home_score - games$away_score

### Remove Problematic Games
these <- (games$scorediff == 0 & games$secs_remaining == 0) | (games$scorediff > 0 & games$win == 0 & games$secs_remaining == 0)| (games$scorediff < 0 & games$win == 1 & games$secs_remaining == 0)
bad_ids <- games$game_id[these]
games <- games[!(games$game_id %in% bad_ids),]

### Fix Secs Remaining for OT 
games$secs <- NA
for(i in 1:length(gameIDs)) {
  print(i)
  msec <- max(games$secs_remaining[games$game_id == gameIDs[i]])
  
  if(msec == 2400) {
    games$secs[games$game_id == gameIDs[i]] <- 
      games$secs_remaining[games$game_id == gameIDs[i]]
  }
  else if(msec > 2400 & msec <= 2700) {
    games$secs[games$game_id == gameIDs[i] & games$secs_remaining >= 300] <-
      games$secs_remaining[games$game_id == gameIDs[i] & games$secs_remaining >= 300] - 300
  }
  else if(msec > 2700 & msec <= 3000) {
    games$secs[games$game_id == gameIDs[i] & games$secs_remaining >= 600] <-
      games$secs_remaining[games$game_id == gameIDs[i] & games$secs_remaining >= 600] - 600
    games$secs[games$game_id == gameIDs[i] & games$secs_remaining >= 300 & games$secs_remaining < 600] <-
      games$secs_remaining[games$game_id == gameIDs[i] & games$secs_remaining >= 300 & games$secs_remaining < 600] - 300
  }
  else if(msec > 3000 & msec <= 3300){
    games$secs[games$game_id == gameIDs[i] & games$secs_remaining >= 900] <-
      games$secs_remaining[games$game_id == gameIDs[i] & games$secs_remaining >= 900] - 900
    games$secs[games$game_id == gameIDs[i] & games$secs_remaining >= 600 & games$secs_remaining < 900] <-
      games$secs_remaining[games$game_id == gameIDs[i] & games$secs_remaining >= 600 & games$secs_remaining < 900] - 600
    games$secs[games$game_id == gameIDs[i] & games$secs_remaining >= 300 & games$secs_remaining < 600] <-
      games$secs_remaining[games$game_id == gameIDs[i] & games$secs_remaining >= 300 & games$secs_remaining < 600] - 300
  }
  else if(msec > 3300 & msec <= 3600){
    games$secs[games$game_id == gameIDs[i] & games$secs_remaining >= 1200] <-
      games$secs_remaining[games$game_id == gameIDs[i] & games$secs_remaining >= 1200] - 1200
    games$secs[games$game_id == gameIDs[i] & games$secs_remaining >= 900 & games$secs_remaining < 1200] <-
      games$secs_remaining[games$game_id == gameIDs[i] & games$secs_remaining >= 900 & games$secs_remaining < 1200] - 900
    games$secs[games$game_id == gameIDs[i] & games$secs_remaining >= 600 & games$secs_remaining < 900] <-
      games$secs_remaining[games$game_id == gameIDs[i] & games$secs_remaining >= 600 & games$secs_remaining < 900] - 600
    games$secs[games$game_id == gameIDs[i] & games$secs_remaining >= 300 & games$secs_remaining < 600] <-
      games$secs_remaining[games$game_id == gameIDs[i] & games$secs_remaining >= 300 & games$secs_remaining < 600] - 300
  }
}

### Get Pre Game Prior
cols <- c("wins", "predscorediff")
prior <- glm(wins ~ predscorediff, data = rbind(x[,cols], y[!is.na(y$scorediff),cols]), family = binomial)
tmp <- data.frame(wins = games$win, predscorediff = games$home_favored_by)
games$pre_game_prob <- predict(prior, newdata = tmp, type = "response")


### Fit Series of Logistic Model
secs <- c(0:29, seq(30, 60, 2), seq(70, 2400, 10))
wp_hoops <- data.frame("intercept" = rep(NA, (length(secs) - 1)),
                     "scorediff" = rep(NA, (length(secs) - 1)),
                     "pre_game_prob" = rep(NA, (length(secs) - 1)))

for(i in 1:(length(secs) - 1)){
  print(i)
  tmp <- suppressWarnings(glm(win ~  scorediff + pre_game_prob, 
                                        data = games[games$secs >= secs[i] & games$secs_remaining < secs[i+1], ], 
                                        family = binomial))
  wp_hoops[i,] <- tmp$coefficients
  
}

### Save Model
write.csv(wp_hoops, "wp_hoops.csv", row.names = F)