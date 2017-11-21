library(XML)
library(dplyr)
library(magrittr)

### Function to clean PBP data
clean <- function(data, half, OTs) {
  cleaned <- data %>% mutate(play_id = 1:nrow(data), 
                             half = half,
                             time_remaining_half = as.character(V1), 
                             description = V3, 
                             away_score = suppressWarnings(as.numeric(gsub("-.*", "", V4))),
                             home_score = suppressWarnings(as.numeric(gsub(".*-", "", V4))))
  cleaned$time_remaining_half[1] <- ifelse(half <= 2, "20:00", "5:00")
  mins <- suppressWarnings(as.numeric(gsub(":.*","", cleaned$time_remaining_half)))
  secs <- suppressWarnings(as.numeric(gsub(".*:","", cleaned$time_remaining_half)))
  cleaned$secs_remaining <- max(20 * (2 - half), 0) * 60 + 
    5 * 60 * max((OTs * as.numeric(half <=2)), ((OTs + 2 - half) * as.numeric(half > 2))) + 60 * mins + secs
  if(half == 1) {
    cleaned[1, c("home_score", "away_score")] <- c(0,0)
  }
  cleaned <- select(cleaned, play_id, half, time_remaining_half, secs_remaining, description,
                    home_score, away_score) 
  return(cleaned)
}

### Create Team URL Dictionairy for Acquiring Team PBP Data
teams_url <- "http://www.espn.com/mens-college-basketball/teams"
x <- scan(teams_url, what = "", sep = "\n")
x <- x[grep("http://www.espn.com/mens-college-basketball/team/_/id/", x)]
x <- strsplit(x, "/")

ids <- data.frame("team" = rep(NA, 351), 
                  "id" = rep(NA, 351),
                  "link" = rep(NA, 351))

for(i in 1:length(x)) {
  ids$id[i] <- x[[i]][8]
  y <- gsub("[<>\"]", "" , x[[i]][9])
  y <- gsub("class=bi", "",  y)
  y <- unlist(strsplit(y, " "))
  ids$link[i] <- y[1]
  ids$team[i] <- paste(y[-1], collapse = " ")
}

get_pbp <- function(team) {
  print(paste("Getting Game IDs: ", team, sep = ""))
  ### Get Game IDs
  base_url <- "http://www.espn.com/mens-college-basketball/team/_/id/"
  url <- paste(base_url, ids$id[ids$team == team], "/", ids$link[ids$team == team], sep = "")
  
  x <- scan(url, what = "", sep = "\n")
  x <- x[grep("club-schedule", x)]
  x <- unlist(strsplit(x, "gameId="))
  x <- x[-1]
  x <- x[1:(floor(length(x)/2))]
  
  gameIDs <- substring(x, 1, 9)
  gameIDs <- unique(gameIDs)
  
  ### Get Play by Play Data 
  base_url <- "http://www.espn.com/mens-college-basketball/playbyplay?gameId="
  summary_url <- "http://www.espn.com/mens-college-basketball/game?gameId="
  j <- 0
  
  for(i in 1:length(gameIDs)) {
    print(paste("Getting ", team, " Game: ", i, "/", length(gameIDs), sep = ""))
    url <- paste(base_url, gameIDs[i], sep = "")
    tmp <- try(readHTMLTable(url), silent = T)
    
    ### Check if PBP Data is Available
    if(length(tmp) < ncol(tmp[[1]]) | length(tmp) == 0) {
      print("Play by Play Data Not Available")
      next
    }
    else{
      j <- j + 1
    }
    
    
    ### 0 OT
    if(ncol(tmp[[1]]) == 4) {
      half_1 <- clean(as.data.frame(tmp[[2]]), 1, 0)
      half_2 <- clean(as.data.frame(tmp[[3]]), 2, 0)
      pbp <- rbind(half_1, half_2)
    }
    
    ### 1 OT
    if(ncol(tmp[[1]]) == 5) {
      half_1 <- clean(as.data.frame(tmp[[2]]), 1, 1)
      half_2 <- clean(as.data.frame(tmp[[3]]), 2, 1)
      half_3 <- clean(as.data.frame(tmp[[4]]), 3, 1)
      pbp <- rbind(half_1, half_2, half_3)
    }
    
    ### 2 OT
    if(ncol(tmp[[1]]) == 6) {
      half_1 <- clean(as.data.frame(tmp[[2]]), 1, 2)
      half_2 <- clean(as.data.frame(tmp[[3]]), 2, 2)
      half_3 <- clean(as.data.frame(tmp[[4]]), 3, 2)
      half_4 <- clean(as.data.frame(tmp[[5]]), 4, 2)
      pbp <- rbind(half_1, half_2, half_3, half_4)
    }
    
    ### 3 OT
    if(ncol(tmp[[1]]) == 7) {
      half_1 <- clean(as.data.frame(tmp[[2]]), 1, 3)
      half_2 <- clean(as.data.frame(tmp[[3]]), 2, 3)
      half_3 <- clean(as.data.frame(tmp[[4]]), 3, 3)
      half_4 <- clean(as.data.frame(tmp[[5]]), 4, 3)
      half_5 <- clean(as.data.frame(tmp[[6]]), 5, 3)
      pbp <- rbind(half_1, half_2, half_3, half_4, half_5)
    }
    
    ### 4 OT
    if(ncol(tmp[[1]]) == 8) {
      half_1 <- clean(as.data.frame(tmp[[2]]), 1, 4)
      half_2 <- clean(as.data.frame(tmp[[3]]), 2, 4)
      half_3 <- clean(as.data.frame(tmp[[4]]), 3, 4)
      half_4 <- clean(as.data.frame(tmp[[5]]), 4, 4)
      half_5 <- clean(as.data.frame(tmp[[6]]), 5, 4)
      half_6 <- clean(as.data.frame(tmp[[7]]), 5, 4)
      pbp <- rbind(half_1, half_2, half_3, half_4, half_6)
    }
    
    these <- grep(T, is.na(pbp$home_score))
    pbp[these, c("home_score", "away_score")] <- pbp[these - 1 , c("home_score", "away_score")]
    
    ### Get full team names 
    url2 <- paste(summary_url, gameIDs[i], sep = "")
    tmp <- readHTMLTable(url2)
    pbp$away <- as.character(as.data.frame(tmp[[2]])[1,1])
    pbp$home <- as.character(as.data.frame(tmp[[2]])[2,1])
    away_abv <- as.character(as.data.frame(tmp[[1]])[1,1])
    home_abv <- as.character(as.data.frame(tmp[[1]])[2,1])
    
    ### Get Game Line
    y <- scan(url2, what = "", sep = "\n")
    y <- y[grep("Line:", y)]
    if(length(y) > 0) {
      y <- gsub("<[^<>]*>", "", y)
      y <- gsub("\t", "", y)
      y <- strsplit(y, ": ")[[1]][2]
      line <- as.numeric(strsplit(y, " ")[[1]][2])
      abv <- strsplit(y, " ")[[1]][1]
      if(abv == home_abv) {
        line <- line * -1
      }
    }
    else {
      line <- NA
    }
    
    pbp$home_favored_by <- line
    pbp$play_id <- 1:nrow(pbp)
    pbp$game_id <- gameIDs[i]
    
    if(j == 1) {
      pbp_season <- pbp
    }else{
      pbp_season <- rbind(pbp_season, pbp)
    }
  }
  write.table(pbp_season, paste("pbp_2017_18/", gsub(" ", "_", team), ".csv", sep = ""), row.names = F, col.names = T, sep = ",")
  return(pbp_season)
}

get_roster <- function(team) {
  print(paste("Getting Roster: ", team, sep = ""))
  base_url <- "http://www.espn.com/mens-college-basketball/team/roster/_/id/"
  url <-  paste(base_url, ids$id[ids$team == team], "/", ids$link[ids$team == team], sep = "")
  tmp <- readHTMLTable(url)
  tmp <- as.data.frame(tmp[[1]][-1,])
  names(tmp) <- c("Number", "Name", "Position", "Height", "Weight", "Class", "Hometown")
  return(tmp)
}

get_pbp_game <- function(gameIDs) {
  
  ### Get Play by Play Data 
  base_url <- "http://www.espn.com/mens-college-basketball/playbyplay?gameId="
  summary_url <- "http://www.espn.com/mens-college-basketball/game?gameId="
  j <- 0
  
  for(i in 1:length(gameIDs)) {
    print(paste(" Game: ", i, "/", length(gameIDs), sep = ""))
    url <- paste(base_url, gameIDs[i], sep = "")
    tmp <- try(readHTMLTable(url), silent = T)
    
    ### Check if PBP Data is Available
    if(length(tmp) < ncol(tmp[[1]]) | length(tmp) == 0) {
      print("Play by Play Data Not Available")
      next
    }
    else{
      j <- j + 1
    }
    
    
    ### 0 OT
    if(ncol(tmp[[1]]) == 4) {
      half_1 <- clean(as.data.frame(tmp[[2]]), 1, 0)
      half_2 <- clean(as.data.frame(tmp[[3]]), 2, 0)
      pbp <- rbind(half_1, half_2)
    }
    
    ### 1 OT
    if(ncol(tmp[[1]]) == 5) {
      half_1 <- clean(as.data.frame(tmp[[2]]), 1, 1)
      half_2 <- clean(as.data.frame(tmp[[3]]), 2, 1)
      half_3 <- clean(as.data.frame(tmp[[4]]), 3, 1)
      pbp <- rbind(half_1, half_2, half_3)
    }
    
    ### 2 OT
    if(ncol(tmp[[1]]) == 6) {
      half_1 <- clean(as.data.frame(tmp[[2]]), 1, 2)
      half_2 <- clean(as.data.frame(tmp[[3]]), 2, 2)
      half_3 <- clean(as.data.frame(tmp[[4]]), 3, 2)
      half_4 <- clean(as.data.frame(tmp[[5]]), 4, 2)
      pbp <- rbind(half_1, half_2, half_3, half_4)
    }
    
    ### 3 OT
    if(ncol(tmp[[1]]) == 7) {
      half_1 <- clean(as.data.frame(tmp[[2]]), 1, 3)
      half_2 <- clean(as.data.frame(tmp[[3]]), 2, 3)
      half_3 <- clean(as.data.frame(tmp[[4]]), 3, 3)
      half_4 <- clean(as.data.frame(tmp[[5]]), 4, 3)
      half_5 <- clean(as.data.frame(tmp[[6]]), 5, 3)
      pbp <- rbind(half_1, half_2, half_3, half_4, half_5)
    }
    
    ### 4 OT
    if(ncol(tmp[[1]]) == 8) {
      half_1 <- clean(as.data.frame(tmp[[2]]), 1, 4)
      half_2 <- clean(as.data.frame(tmp[[3]]), 2, 4)
      half_3 <- clean(as.data.frame(tmp[[4]]), 3, 4)
      half_4 <- clean(as.data.frame(tmp[[5]]), 4, 4)
      half_5 <- clean(as.data.frame(tmp[[6]]), 5, 4)
      half_6 <- clean(as.data.frame(tmp[[7]]), 5, 4)
      pbp <- rbind(half_1, half_2, half_3, half_4, half_6)
    }
    
    these <- grep(T, is.na(pbp$home_score))
    pbp[these, c("home_score", "away_score")] <- pbp[these - 1 , c("home_score", "away_score")]
    
    ### Get full team names 
    url2 <- paste(summary_url, gameIDs[i], sep = "")
    tmp <- readHTMLTable(url2)
    pbp$away <- as.character(as.data.frame(tmp[[2]])[1,1])
    pbp$home <- as.character(as.data.frame(tmp[[2]])[2,1])
    away_abv <- as.character(as.data.frame(tmp[[1]])[1,1])
    home_abv <- as.character(as.data.frame(tmp[[1]])[2,1])
    
    ### Get Game Line
    y <- scan(url2, what = "", sep = "\n")
    y <- y[grep("Line:", y)]
    if(length(y) > 0) {
      y <- gsub("<[^<>]*>", "", y)
      y <- gsub("\t", "", y)
      y <- strsplit(y, ": ")[[1]][2]
      line <- as.numeric(strsplit(y, " ")[[1]][2])
      abv <- strsplit(y, " ")[[1]][1]
      if(abv == home_abv) {
        line <- line * -1
      }
    }
    else {
      line <- NA
    }
    
    pbp$home_favored_by <- line
    pbp$play_id <- 1:nrow(pbp)
    pbp$game_id <- gameIDs[i]
    
    return(pbp)
  }
}

### Get all of 2017/18 Data
for(k in 1:351) {
  data <- get_pbp(ids$team[k])
  write.table(data, paste("pbp_2017_18/", gsub(" ", "_", ids$team[k]), ".csv", sep = ""), row.names = F, col.names = T, sep = ",")
  roster <- get_roster(ids$team[k])
  write.table(roster, paste("rosters_2017_18/", gsub(" ", "_", ids$team[k]), ".csv", sep = ""), row.names = F, col.names = T, sep = ",")
  
  
  if(k == 1){
    season <- data
  }else{
    season <- rbind(season, data)
  }
}

write.table(season, "pbp_2017_18/all_games.csv", row.names = F, col.names = T, sep = ",")