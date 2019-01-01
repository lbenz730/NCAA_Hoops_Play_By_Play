library(tools)
library(ncaahoopR)

### Set NCAA Conferences link add-ons from teamcolorcodes.com
conferences <- c("aac", "america-east", "acc", "atlantic-sun",
                 "atlantic-10", "big-east", "big-sky", "big-west",
                 "big-ten", "big-12", "horizon-league", "conference-usa", 
                 "ivy-league", "maac", "mac", "missouri-valley", "mountain-west",
                 "pac-12", "sec", "summit-league", "sun-belt", 
                 "western-athletic-conference", "west-coast-conference")

### Loop over Conferences
for(i in 1:length(conferences)) {
  ### Get Individual URLs for Teams in Conference
  url <- paste0("https://teamcolorcodes.com/ncaa-color-codes/", conferences[i])
  html <- scan(url, sep = "\n", what = "")
  html <- html[grep("https://teamcolorcodes.com/.*-color-codes/", html)]
  html <- html[length(html)]
  html <- strsplit(html, "team-button")[[1]][-1]
  
  links <- gsub("\">.*", "", gsub("=\"background-color: .*; border-bottom: 4px solid .*;\" href=\"", "", html))
  links <- gsub("\" style", "", links)
  links <- gsub("&quot;", "", gsub("=\".*", "", gsub(".*href=\"", "", links)))
  links <- links[links != "\" https:"]
  
  ### Special Case (Big 10
  if(i == 9) {
    links[6] <- "https://teamcolorcodes.com/michigan-state-spartans-colors" 
    links[12] <- "https://teamcolorcodes.com/purdue-boilermakers-colors/"
    links[14] <- "https://teamcolorcodes.com/wisconsin-badgers-colors/"
  }else if(i == 14) {
    links[1:8] <- paste0("https://teamcolorcodes.com", links[1:8])
  }else if(i == 16) {
    links[c(1:5, 9)] <- paste0("https://teamcolorcodes.com", links[c(1:5, 9)])
  }else if(i == 22) {
    vec <- c("gcu-antelopes", "umkc-kangaroos", "new-mexico-state-aggies", 
             "seattle-university-redhawks", "utrgv-vaqueros", "utah-valley-wolverines")
   links[3:8] <- paste0("https://teamcolorcodes.com/", vec, c("-color-codes", rep("-colors", 2),
                                                              "-color-codes", rep("-colors", 2)))
  }
  
  
  ### Loop over teams in conference
  for(j in 1:length(links)) {
    cat("Conference #", i, "-- Team #", j, "\n")
    ### Get Team Name
    team <- gsub("https://teamcolorcodes.com/", "", links[j])
    team <- unlist(strsplit(team, "-")[[1]])
    team <- team[1:(length(team) - 2)]
    team <- paste(toTitleCase(team), collapse = " ")
    
    ### Get Team Colors
    html <- scan(links[j], sep = "\n", what = "")
    html <- html[grep("Hex Color", html)]
    if(length(html) > 0) {
      html <- strsplit(html, "Hex Color")[[1]][-1]
    }
    else {
      html <- scan(links[j], sep = "\n", what = "")
      html <- html[grep("Hex: ", html)]
      if(length(html) > 0) {
        html <- strsplit(html, "Hex: ")[[1]][-1]
      }
      else{
        html <- scan(links[j], sep = "\n", what = "")
        html <- html[grep("HEX COLOR: ", html)]
        html <- strsplit(html, "HEX COLOR: ")[[1]][-1]
      }
    }
    colors <- gsub(".*\\s", "", gsub(";.*", "", html))
    colors <- substring(colors, 1, 7)
    
    ### Add Black Hex Code if Team Color
    if(any(sapply(html, grepl, pattern = "style=\"background-color: #000000; color: #FFF;\"> BLACK"))) {
      colors <- c(colors, "#000000")
    }
    
    ### Store Results
    df <- data.frame("team" = team,
                     "conference" = conferences[i],
                     "primary_color" = NA,
                     "secondary_color" = NA,
                     "tertiary_color" = NA,
                     "color_4" = NA,
                     "color_5" = NA, 
                     "color_6" = NA, 
                     stringsAsFactors = F)
    df[, 3:(2 + length(colors))] <- colors
    
    if(i == 1 & j == 1) {
      ncaa_colors <- df
    }else{
      ncaa_colors <- rbind(ncaa_colors, df)
    }
  }
}

### Clean Results
ncaa_colors <- mutate(ncaa_colors, conference =
         case_when(conference == "aac" ~ "AAC",
                   conference == "america-east" ~ "Am. East",
                   conference == "acc" ~ "ACC", 
                   conference == "atlantic-sun" ~ "ASun",
                   conference == "atlantic-10" ~ "A-10",
                   conference == "big-east" ~ "Big East",
                   conference == "big-west" ~ "Big West",
                   conference == "big-sky" ~ "Big Sky",
                   conference == "big-ten" ~ "Big 10",
                   conference == "big-12" ~ "Big 12", 
                   conference == "horizon-league" ~ "Horizon",
                   conference == "conference-usa" ~ "C-USA",
                   conference == "ivy-league" ~ "Ivy",
                   conference == "maac" ~ "MAAC", 
                   conference == "mac" ~ "MAC",
                   conference == "missouri-valley" ~ "MVC",
                   conference == "mountain-west" ~ "MWC", 
                   conference == "pac-12" ~ "Pac 12",
                   conference == "sec" ~ "SEC", 
                   conference == "sun-belt" ~ "Sunbelt",
                   conference == "summit-league" ~ "Summit",
                   conference == "western-athletic-conference" ~ "WAC",
                   conference == "west-coast-conference" ~ "WCC"))

### We'll have to manually edit a few of the team names but this should give us most of them
ncaa_colors <- 
  mutate(ncaa_colors, 
         "ncaa_name" = sapply(team, function(x) { dict$NCAA[which.min(stringdist(x, dict$NCAA))] }))

### Save Results
write.csv(ncaa_colors, "ncaa_colors.csv", row.names = F)
