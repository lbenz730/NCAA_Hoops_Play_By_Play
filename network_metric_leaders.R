source("NCAA_Hoops_PBP_Scraper.R")
source("Assist_Networks.R")

dict <- read.csv("ESPN_NCAA_Dict.csv", as.is = T)

### Create Data Frame to Collect Results
metrics <- data.frame("team" = dict$ESPN_PBP,
                      "clust_coeff" = rep(NA, 351),
                      "max_page_rank" = rep(NA, 351),
                      "page_rank_mvp" = rep(NA, 351),
                      "max_hub_score" = rep(NA, 351),
                      "hub_score_mvp" = rep(NA, 351),
                      "max_auth_score" = rep(NA, 351),
                      "auth_score_mvp" = rep(NA, 351),
                      "max_ast_freq" = rep(NA, 351),
                      "ast_freq_leader" = rep(NA, 351),
                      "max_shot_freq" = rep(NA, 351),
                      "shot_freq_leader" = rep(NA, 351),
                      "weighted_max_page_rank" = rep(NA, 351),
                      "weighted_page_rank_mvp" = rep(NA, 351),
                      "weighted_max_hub_score" = rep(NA, 351),
                      "weighted_hub_score_mvp" = rep(NA, 351),
                      "weighted_max_auth_score" = rep(NA, 351),
                      "weighted_auth_score_mvp" = rep(NA, 351),
                      "weighted_max_ast_freq" = rep(NA, 351),
                      "weighted_ast_freq_leader" = rep(NA, 351),
                      "weighted_max_shot_freq" = rep(NA, 351),
                      "weighted_shot_freq_leader" = rep(NA, 351))


for(i in 1:351) {
  print(paste("Team # ", i, "/351", sep = ""))
  
  ### Get PBP Data
  z <- get_pbp(dict$ESPN[i])
  
  ### Un-Weighted Assist Network
  unweighted <- assist_net(dict$ESPN[i], "white", "2017-18", T, F, F)
  
  ### Weighted Assist Network
  weighted <- assist_net(dict$ESPN[i], "white", "2017-18", T, F, T)
 
  ### Fill in Data Frame
  metrics$clust_coeff[i] <- unweighted$clust_coeff
  metrics$max_page_rank[i] <- max(unweighted$page_ranks)
  metrics$page_rank_mvp[i] <- names(unweighted$page_ranks)[which.max(unweighted$page_ranks)]
  metrics$max_hub_score[i] <- max(unweighted$hub_scores)
  metrics$hub_score_mvp[i] <- names(unweighted$hub_scores)[which.max(unweighted$hub_scores)]
  metrics$max_auth_score[i] <- max(unweighted$auth_scores)
  metrics$auth_score_mvp[i] <- names(unweighted$auth_scores)[which.max(unweighted$auth_scores)]
  metrics$max_ast_freq[i] <- max(unweighted$ast_freq)
  metrics$ast_freq_leader[i] <- names(unweighted$ast_freq)[which.max(unweighted$ast_freq)]
  metrics$max_shot_freq[i] <- max(unweighted$shot_freq)
  metrics$shot_freq_leader[i] <- names(unweighted$shot_freq)[which.max(unweighted$shot_freq)]
  
  metrics$weighted_max_page_rank[i] <- max(weighted$page_ranks)
  metrics$weighted_page_rank_mvp[i] <- names(weighted$page_ranks)[which.max(weighted$page_ranks)]
  metrics$weighted_max_hub_score[i] <- max(weighted$hub_scores)
  metrics$weighted_hub_score_mvp[i] <- names(weighted$hub_scores)[which.max(weighted$hub_scores)]
  metrics$weighted_max_auth_score[i] <- max(weighted$auth_scores)
  metrics$weighted_auth_score_mvp[i] <- names(weighted$auth_scores)[which.max(weighted$auth_scores)]
  metrics$weighted_max_ast_freq[i] <- max(weighted$ast_freq)
  metrics$weighted_ast_freq_leader[i] <- names(weighted$ast_freq)[which.max(weighted$ast_freq)]
  metrics$weighted_max_shot_freq[i] <- max(weighted$shot_freq)
  metrics$weighted_shot_freq_leader[i] <- names(weighted$shot_freq)[which.max(weighted$shot_freq)]
  
}

write.csv(metrics, "1_2_2018_assit_leaderboad.csv", row.names = F)
