  ##### setting environment ######
  library(here) #reading wkd
  library(tidyverse) #data cleaning
  library(vroom) #for appending together data frames
  library(mgcv) #for running GAMs
  
  here() #sets wkd
  
  ##### read in the data files ##########################################
  #create list of files
  files <- list.files(path=here('joined_data'),pattern = "\\.txt$")
  
  # Read all the files 
  data <- vroom(here('joined_data', files))
  
  ####### delete and rename columns ##################################
  
  #delete uneeded columns
  data = subset(data, select = -c(row.names.x, move_list, Event))
  
  #rename columns - need to just shift rightward if possible (stackoverflow this)
  data <- data %>%
    rename(MoveId = GameId, 
           MoveList = classical_eval,
           Classical_eval = nnue_eval,
           Nnue_eval = final_eval,
           Final_eval = best_move,
           Best_move = row.names.y,
           event = Site,
           site = Date,
           date = Round,
           round = White,
           white = Black,
           black = Result,
           Result = WhiteElo,
           whiteElo = BlackElo,
           blackElo = WhiteTitle)
  
  # delete more uneeded variables
  data = subset(data, select = -c(WhiteFideId, BlackFideId, BlackTitle))
  
  ##### create the nnue_diff column ################################
  
  # create unique game id with a variable combination unique to that game
  data <- within(data,  
                 unique_id <- paste(
                   site, date, white, black, #combines site, date, and players
                   sep=""
                   )
                 )
  
  # creates a number for GameId based off unique_ids
  data <- data %>%
    mutate(GameId = match(unique_id, unique(unique_id)))
  
  data <- subset(data, select = -c(unique_id)) # deletes unique_id column 
  
  # check for NA values
  sum(is.na(data$Nnue_eval)) # there are no NA values currently so this only exists for 'in check' when typecasted
  
  data$Nnue_eval <- as.numeric(data$Nnue_eval) #typecasts Nue_eval
  
  # this calculates the differences between each subsequent row, this is reset for each new game 
  data <- data %>% 
    group_by(GameId) %>% 
    mutate(nnue_diff = c(NA, diff(Nnue_eval))) %>% 
    ungroup()
  
  # creates alternating colour allocation
  data <- data %>%
    group_by(GameId) %>%
    mutate(colour = rep(c("white", "black"), length.out = n())) %>%
    ungroup
  
  # swap sign for 'black' colour in nnue_diff
  data <- data %>%  
    mutate(
      nnue_diff_adjusted = case_when(
        colour == "black" ~ nnue_diff * -1, #multiplies all black values by -1
        TRUE ~ nnue_diff
        )
      )
  
  # remove first 10 rows of each group to account for 'book openings'
  data <- data %>% 
    group_by(GameId) %>%
    slice(11:n())
  
  
  ###### Grouping the data ######################################
  
  #remove inconsistent variables for grouping
  grouped_data <- subset(data, select = c(event, site, date, white, black, whiteElo, blackElo, GameId, colour, nnue_diff_adjusted))
  
  #sets nnue_diff_adjusted to numeric
  grouped_data$nnue_diff_adjusted <- as.numeric(grouped_data$nnue_diff_adjusted) 
  
  #remove NAs from nnue_diff_adjusted
  grouped_data <- grouped_data[!is.na(grouped_data$nnue_diff_adjusted),]
  
  
  #group together by game_colour_id and add column averaging the nnue_diff
  grouped_data2 <- grouped_data %>% 
    group_by(GameId, colour) %>% 
    summarise(mean_nnue_diff = mean(nnue_diff_adjusted)) 
  
  #create dataframe to join back to grouped_data2 that contains other variables
  grouped_data3 <- subset(grouped_data, select = -c(nnue_diff_adjusted)) #remove inconsistent variable 
  grouped_data3 <- grouped_data3[!duplicated(grouped_data3), ] #remove duplicates so just unique rows for each game and colour remain
  
  ######## joining the data ###########
  #join together grouped_data2 and grouped_data3
  
  #create unique id for joining
  grouped_data2 <- within(grouped_data2,  #for data2
                         game_colour_Id <- paste(
                           GameId, colour, 
                           sep="."
                         )
  ) 
  
  grouped_data3 <- within(grouped_data3,  #for data3
                          game_colour_Id <- paste(
                            GameId, colour, 
                            sep="."
                          )
  ) 
  
  #remove uneeded repeat variables before joining
  grouped_data2 <- subset(
    grouped_data2, 
    select = c(mean_nnue_diff, game_colour_Id)
    )
  
  gam_data <- full_join(grouped_data3, grouped_data2, by = "game_colour_Id") #joins dfs
  
  #makes date just year
  gam_data$year <- as.numeric(substr(gam_data$date, 0, 4))

  # adds corresponding elo rating to the player
  gam_data <- gam_data %>%
      mutate(EloRating = ifelse(colour == "white", whiteElo, blackElo))
  
  ######### running the gam ###########
  
  gam_mod <- gam(mean_nnue_diff ~ s(year) + s(EloRating), 
                 data = gam_data, 
                 method = 'REML')
  
  plot(gam_mod, residuals = T, pch = 1, cex = 0.5)
  
  
  uni_gam_mod <- gam(mean_nnue_diff ~ s(year), 
                     data = gam_data,
                     method = 'REML')
  
  plot(uni_gam_mod, residuals = T, pch = 1, cex = 0.5)
  
