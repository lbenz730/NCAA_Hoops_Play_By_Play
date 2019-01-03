library(XML)
library(RCurl)
library(dplyr)

years <- 2002:2019

for(year in years) {
  cat("Getting", year,"\n")
  ### Pull Data
  url <- paste0("https://kenpom.com/index.php?y=", year)
  x <- as.data.frame(readHTMLTable(getURL(url))[[1]])
  
  ### Clean Data
  names(x) <- c("rank", "team", "conference", "record", "adj_em", "adj_o", 
                "adj_o_rank", "adj_d", "adj_d_rank", "adj_tempo", "adj_tempo_rank", 
                "luck", "luck_rank", "sos_adj_em", "sos_adj_em_rank", "sos_adj_o",
                "sos_adj_o_rank","sos_adj_d", "sos_adj_d_rank", "nc_sos_adj_em", 
                "nc_sos_adj_em_rank")
  x <- filter(x, !team %in% c("", "Team"))
  for(i in 5:ncol(x)) {
    x[,i] <- as.numeric(as.character(x[,i]))
  }
  
  x <- mutate(x, 
              "ncaa_seed" = sapply(team, function(arg) { as.numeric(gsub("[^0-9]", "", arg)) }),
              "team" = sapply(team, function(arg) { gsub("\\s[0-9]+", "", arg) }),
              "year" = year)
  
  ### Store Data
  if(year == 2002) {
    kenpom <- x
  }else {
    kenpom <- rbind(kenpom, x)
  }
}

write.csv(kenpom, "kenpom.csv", row.names = F)
