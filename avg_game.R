library(ncaahoopR)

### Hardcode Teams in Sweet 16
teams <- c("Duke", "Michigan State", "LSU", "Virginia Tech",
           "UNC", "Kentucky", "Houston", "Auburn",
           "UVA", "Oregon", "Purdue", "Tennessee",
           "Gonzaga", "Michigan", "Texas Tech", "Florida State")


for(i in 1:length(teams)) {
  ### Get PBP data for team
  x <- get_pbp(teams[i]) %>%
    mutate("secs_elapsed" = 2400 - secs_remaining)
  
  ### Compute Min by Min Avg Score Diff
  y <- group_by(x, floor(secs_elapsed/60)) %>%
    summarise("mean_sd" = mean(score_diff)) %>%
    ungroup %>%
    mutate("team" = teams[i])
  names(y)[1] <- "mins_elapsed"
  
  ### Save Results
  if(i == 1) {
    sweet_16 <- y
  } else {
    sweet_16 <- rbind(sweet_16, y) 
  }
}

### Get Colors
cols <- inner_join(data.frame("team" = teams), ncaa_colors, by = c("team" = "espn_name")) %>%
  arrange(team)

cols <- c(cols$secondary_color[1], cols$tertiary_color[2], cols$primary_color[3:7],
          cols$secondary_color[8], cols$primary_color[9],
          cols$secondary_color[10], cols$primary_color[11:14], cols$secondary_color[15],
          cols$primary_color[16])

### Make Plot
ggplot(sweet_16, aes(x = mins_elapsed, y = mean_sd, fill = team)) +
  facet_wrap(~team) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  theme(plot.title = element_text(size = 16, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5),
        axis.title = element_text(size = 14),
        plot.caption = element_text(size = 8, hjust = 0),
        strip.text = element_text(size = 10),
        strip.background = element_rect(fill = "lightblue"),
        legend.position = "none") +
  labs(x = "Minutes Elapsed",
       y = "Mean Score Differential",
       title = "Average NCAA Men's Basketball Game (2018-2019 Season)",
       subtitle = "Sweet 16 Teams",
       caption = "Luke Benz (@recspecs730) Data Accessed via ncaahoopR") +
  scale_fill_manual(values = cols)
