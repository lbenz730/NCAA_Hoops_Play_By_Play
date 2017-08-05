# NCAA_Hoops_Play_By_Play
Men's College Basketball Play by Play Data

__NCAA_Hoops_PBP_Scraper.R:__ An R file used to scrape data from ESPN. To get a particular team's play by play data, call ```get_pbp(team)```. Note that team names must adhere to ESPN naming conventions. A full dictionary of team names used by ESPN is created in the __ids__ data frame in the script.

__2016_17_pbp/:__ A folder containing play by play csv files for each team for the 2016-17 season. Additionally, the file __all_games.csv__ contains all games scraped for the 2016-17 season. Each .csv file contains the following variables:
   * __play_id__: The index of a play in a given game
   * __half:__ Overtimes denoted by 3, 4, etc.
   * __time_remaining_half:__ Time left in a given period of play, as it would appear on a scoreboard.
   * __secs_remaining:__ The number of seconds left in a given game.
   * __description:__ A description of what happened on the given play.
   * __home_score/away_score:__ Scores for the home and away teams, as denoted by ESPN. Even for neutral site games, a "home team" is denoted by choosing the team listed second in ESPN box scores.
   * __away/home:__ Home and Away teams. See above for treatment of neutral site games.
   * __home_favored_by:__ Number of points the home team is favored by, if available. (i.e. 6 corresponds with traditional Vegas line of -6.0)
