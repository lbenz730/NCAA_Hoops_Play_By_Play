library(ncaahoopR)
library(gridExtra)

### Get Schedule
schedule <- get_master_schedule(year = 2019, month = 1, day = 26) %>%
  left_join(select(dict, ESPN_PBP, conference), by = c("home" = "ESPN_PBP")) %>%
  left_join(select(dict, ESPN_PBP, conference), by = c("away" = "ESPN_PBP"), 
            suffix = c("_home", "_away"))

### Get games for SEC/Big12 Challenge
sec_b12 <- 
  filter(schedule, conference_home == "SEC", conference_away == "Big 12") %>%
  rbind(filter(schedule, conference_away == "SEC", conference_home == "Big 12")) %>%
  mutate("gei" = sapply(game_id, game_excitement_index)) %>%
  arrange(desc(gei))

### Make Plots
plots <- list()
for(i in 1:nrow(sec_b12)) {
  plots[[i]] <- 
    gg_wp_chart(game_id = sec_b12$game_id[i], 
                home_col =  filter(ncaa_colors, espn_name == sec_b12$home[i]) %>% 
                  pull(primary_color),
                away_col = 
                  ifelse(!i %in% c(4,6,8),
                         filter(ncaa_colors, espn_name == sec_b12$away[i]) %>% 
                           pull(primary_color),
                         filter(ncaa_colors, espn_name == sec_b12$away[i]) %>% 
                           pull(secondary_color)),
                show_labels = F) + 
    theme_minimal() +
    labs(x = "",
         y = "",
         title = "",
         subtitle = "",
         caption = "") +
    theme(legend.position = "none",
          axis.text = element_blank(),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())
}

### Arrange them all
do.call("grid.arrange", c(plots, ncol = 5))
