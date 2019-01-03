# NCAA_Hoops_Play_By_Play
Men's College Basketball Play by Play Data

__NOTE:__ As of 8/8/2018, the majority of functionality, including development of Play-by-Play scrapers, assist networks, and 
win probability charts has moved to my new R package, [ncaahoopR](https://github.com/lbenz730/ncaahoopR). Data and other miscellaneous
files will still be stored here, but core scripts whose functionally has been incorporated into the  ```ncaahoopR``` package will be updated with the package, not in this repository.



__NCAA_Hoops_PBP_Scraper.R:__ An R file used to scrape data from ESPN. The following functions are available.

* ```get_pbp(team)```: Game entire 2017-18 Season's worth of play-by-play data for a given team.
* ```get_pbp_game(gameIDS)```:  Get play-by-play data for a specific vector of ESPN game ids. 
* ```get_roster(team)```: Get a particular team's roster. 
* ```get_schedule(team)```: Get a team's schedule.
* ```get_game_ids(team)```: Get a vector of ESPN Game IDs for all games in which ```team``` plays in.
* ```get_date(gameID)```: Gets the date of a game given an ESPN Game ID.
* ```is.nit(gameID)```: Returns logical ```T/F``` whether or not the game was part of the NIT

Note that team names must adhere to ESPN naming conventions. A full dictionary of team names used by ESPN is provided in __ids.csv__  Note that play by play data is not available for all games.

__pbp_2016_17/:__ A folder containing play by play csv files for each team for the 2016-17 season. Additionally, the file [all_games.csv](https://drive.google.com/open?id=0BzSws2ZDOraxbXF0aWNJNmxCdnM) (too large for GitHub) contains all games scraped for the 2016-17 season. Each team's .csv file contains the following variables:
   * __play_id__: The index of a play in a given game
   * __half:__ Overtimes denoted by 3, 4, etc.
   * __time_remaining_half:__ Time left in a given period of play, as it would appear on a scoreboard.
   * __secs_remaining:__ The number of seconds left in a given game.
   * __description:__ A description of what happened on the given play.
   * __home_score/away_score:__ Scores for the home and away teams, as denoted by ESPN. Even for neutral site games, a "home team" is denoted by choosing the team listed second in ESPN box scores.
   * __away/home:__ Home and Away teams. See above for treatment of neutral site games.
   * __home_favored_by:__ Number of points the home team is favored by, if available. (i.e. 6 corresponds with traditional Vegas line of -6.0)
   
__pbp_2017_18/:__ Same as above for 2017-18 season.

__Assist_Network.R:__ The function ```assist_net(team, node_col, season, rmv_bench)```, used to create college basketball assist networks. 
  * ```team``` is the ESPN team name
  * ```node_col``` is the node color for the graph
  * ```season```: Options include "2016-17", "2017-18", or a vector of ESPN game IDs. 
  * ```rmv_bench```: Logical. If TRUE, removes all players who aren't in the network. 
  * ```tree```: Logical. If TRUE, draws graph in tree structure. If FALSE, draws graph in circle
  * ```three_weights```: Logical. If TRUE, assisted three point shots are given 1.5 weight. If FALSE, assisted three point shots are given weight 1. In both cases, assisted 2 point shots are given weight 1. 
  * ```Message``` (default = ```NA```) Option for custom message to replace graph title when using a subset of the season (e.g. conference play).
  
__rosters_2016_17/:__ 2016-17 rosters for each team.

__rosters_2017_18/:__ 2017-18 rosters for each team.

__schedules_2017_18/:__ 2017-18 schedules for each team.

__wp_model.R:/__ Prepares data and builds win probability model (coefficients saved as object __wp_hoops.csv__). Requires [all_games.csv](https://drive.google.com/open?id=0BzSws2ZDOraxbXF0aWNJNmxCdnM) and [2017_18_mid_season.csv](https://drive.google.com/file/d/1b7P-p1loGIghL0zDpzaox255X93Mqgkg/view?usp=sharing).

__wp_charts.R:/__ Plots win probability chart for given game. Usage:```wp_chart(ESPN_Game_ID, home_color, away_color, show_legend = T)```. The ```show_legend``` parameter is defaulted to ```TRUE```. I recommend turning this parameter off when plotting more than one win probability charts on a single graph.

__shiny_app:/__ Code for the [R Shiny App version of Assist Networks](https://lbenz730.shinyapps.io/assist_networks).

__network_metric_leaders.R:__ A script for computing weighted/unweighted assist network metrics for all 351 Division 1 teams. The mid-season leaderboad for the 2017-18 season is stored in __1_2_2018_assist_leaderboard.csv__. 

__kenpom_scraper.R:__ Scrapes data from [kenpom.com](https://kenpom.com) main page and store results in __kenpom.csv__.

__ncaa_color_scraper.R:__ Scrapes color hexcodes from http://teamcolorcodes.com for use in the [ncaahoopR](https://github.com/lbenz730/ncaahoopR) package.

# Examples
### Assist Networks
* Weighted Assist Network
![Yale Weighted Assist Network](pics/Yale_Weighted_Network.png)
```assist_net("Yale", "royalblue1", "2017-18", rmv_bench = T, tree = F, three_weights = T, message = NA)```

* Tree Assist Network
![Yale Tree Assist Network](pics/Yale_Tree.png)
```assist_net("Yale", "royalblue1", "2017-18", rmv_bench = T, tree = T, three_weights = F, message = NA)```

### Win Probability Charts
* Texas A&M vs. Northern Iowa, March 20, 2016
![Texas A&M vs. Northern Iowa, March 20, 2016](pics/WinProb.png)
```wp_chart(400872229, "maroon", "purple")```
* Cincinnati vs. Houston, March 11, 2018 (2018 AAC Championship Game)
![Cincinnati vs. Houston, March 11, 2018 (2018 AAC Championship Game)](pics/GEI_example.png)
Update 3/13/2018: Added Game Excitement Index (GEI) to charts. 
