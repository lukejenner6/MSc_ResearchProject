##### set environment ######################
library(here)
here()

library(bigchess)
library(processx)
library(tidyverse)
library(utils)

######## function that initiates the stockfish moves #############################

#this function just activates each step of the stockfish commands and then uses regex to extract the evaluations
stockfish_function <- function(move){
  
  ### stockfish commands ##
  stockfish  <- process$new('stockfish_15_x64_avx2', stdin = '|', stdout = '|', stderr = '|')
  
  repeat{ #the repeat forces R to keep prompting stockfish until it produces a response
    
    ##initiate
    stockfish$write_input('uci\n')
    
    ##input individual moves
    stockfish$write_input(paste0('position startpos moves ',move,'\n'))
    
    ##make that move
    evaluations <- stockfish$write_input('go movetime 100 \n') 
    evaluations
    
    #this adds a delay to stop the loop timing out if no evaluations have been retrieved 
    if(length(evaluations) == 0) {
      #adds delay
      Sys.sleep(0.1)
    } else {
      Sys.sleep(0)
    }
    
    ##evaluate it
    stockfish$write_input('eval\n') 
    
    ##read output
    stockfish_response <- stockfish$read_output_lines() 
    
    ### this checks if a final response was omitted due to check ###
    grepl_output <- grepl('Final evaluation: none \\(in check\\)', stockfish_response) #this reg ex is present when in check
    
    ## if the move was in check NA values are inserted instead
    
    if (any(grepl_output == TRUE)){
      
      #this assigns lines which contain NA strings to variables
      classical_evaluation <- paste('in check')
      nnue_evaluation <- paste('in check')
      final_evaluation <- paste('in check')
      best_move <- str_match(stockfish_response, 'bestmove.+')
      
      #this ensures only the final notation is returned
      best_move <- head(best_move[complete.cases(best_move), ], 1)
      
      #appends each variable to a list
      all_evaluations <- append(classical_evaluation, nnue_evaluation)
      all_evaluations <- append(all_evaluations, final_evaluation)
      all_evaluations <- append(all_evaluations, best_move)
      
      ## if the output does contain evaluations (not in check) then regex are extracted for these
    } else {
      
      ### extract output with regex ###              
      #this assigns lines which contain evaluation to variables
      classical_evaluation <- str_match(stockfish_response, 'Classical evaluation.+?\\(white side\\)')
      nnue_evaluation <- str_match(stockfish_response, 'NNUE evaluation.+?\\(white side\\)')
      final_evaluation <- str_match(stockfish_response, 'Final evaluation.+?\\(white side\\)')
      best_move <- str_match(stockfish_response, 'bestmove.+')
      
      #this ensures only the final notation of each is returned
      classical_evaluation <- tail(classical_evaluation[complete.cases(classical_evaluation), ], 1)
      nnue_evaluation <- tail(nnue_evaluation[complete.cases(nnue_evaluation), ], 1)
      final_evaluation <- tail(final_evaluation[complete.cases(final_evaluation), ], 1)
      best_move <- head(best_move[complete.cases(best_move), ], 1)
      
      #appends each variable to a list
      all_evaluations <- append(classical_evaluation, nnue_evaluation)
      all_evaluations <- append(all_evaluations, final_evaluation)
      all_evaluations <- append(all_evaluations, best_move)
      
    }
    
    
    if (length(all_evaluations) == 4){
      break
      #returns evaluations when all evaluations or 'in checks' extracted
    }
  }
  return(all_evaluations) 
}


############## function to add each evaluated move to evaluations_df ###########
#this function adds each move filtered by the loop into the stockfish_function defined prior. It then takes the list in raw evaluation output and splits it back into individual variables to be appended to evaluations_df as created previously

append_function <- function(move){
  
  raw_evaluation <- stockfish_function(move) #assigns output of stockfish_function for each move
  
  if(raw_evaluation[1] == 'in check'){
    
    ## just splits the 'in check' strings from the list into each column
    classical_input <- raw_evaluation[1] 
    nnue_input <- raw_evaluation[2]
    final_eval <- raw_evaluation[3]
    best_move <- raw_evaluation[4]
    
  } else {
    
    ## takes numeric values from string and assigns to variables
    classical_input <- str_sub(raw_evaluation[1], 24, -14) 
    nnue_input <- str_sub(raw_evaluation[2], 24, -14)
    final_eval <- str_sub(raw_evaluation[3], 24, -14)
    best_move <- raw_evaluation[4]
    
    }
  
  ## adds each variable to new row of evaluations_df
  evaluations_df <- evaluations_df %>% add_row(
    move_list = move, #assigns the move string to move_list column
    classical_eval = classical_input,
    nnue_eval = nnue_input,
    final_eval = final_eval,
    best_move = best_move
  )
  
  return(evaluations_df)
}



###### loop for game Ids and then loop for moves ##########################################
#the two final loops are nested within the loop for each game id


# Comment from Nemanja: Searching for all input files and puts them in a list

files <- list.files(path  =here('input_data'),pattern = "\\.txt$")

## Iterates over the lenght of list: sorts out data and evaluates moves

for (m in 1:length(files)){
  data_old <- read.table(here('input_data',paste('Chunk_',m,'.txt',sep='')), sep='\t', header=T) 
  
  ## add game code of integers from 1 to infinity ##
  data_old$GameId <- 1:nrow(data_old) #adds game ID column so that it can be looped by game ID
  
  ## Split the strings and add to individual rows ##
  data_full <- separate_rows(data_old, Movetext) #separates each move into its own row
  
  ## keep only relevant columns ##
  data_full <- data_full[c("Event", "Site", "Date", "Round", "White", "Black", "Result", "Movetext", "GameId",'WhiteElo','BlackElo','WhiteFideId','BlackFideId')] #cleans df to just necessary variables
  
  ## add ID for each row ##
  data_full$MoveId <- 1:nrow(data_full)
  
  
  ########## list for all game Ids ###########
  unique_ids <- unique(data_full$GameId) #used for looping through game IDs
  
  ##### create DF to be appended #####################
  #this is an empty df where each new evaluation and move sequence will be appended to
  
  evaluations_df <- data.frame(
    GameId=character(0),
    move_list=character(0), #will contain string of move sequences
    classical_eval=character(0), #string for evaluation
    nnue_eval=character(0), #string for evaluation
    final_eval=character(0), #string for evaluation
    best_move=character(0)
  )

  
  # creates empty df to append the output to a text file fit m with the file number you want to append to
  write.table(evaluations_df, here('output_data', paste('Processed_Chunk_',m,'.txt')), sep='', sep='\t')

    ### game id loop ###
    for (id in unique_ids){
      
      test <- filter(data_full, GameId == id) #filters by game ID
      
      move_list <- list() #defines move_list as a list
      
    
      
      ### loop to create a string with each iteration adding another move ### 
      for(i in 1:nrow(test)){
        
        inter <- test %>% #takes data filtered to each game_ID
          slice(1:i) %>% #selects each row
          pull(Movetext) %>% #extracts single value
          str_c(collapse = " ") #keeps adding each movetext selected to a list with spaces in between
        
        move_list <- append(move_list, inter) #this appends each new string to the list
        
      }
      
      evaluations_df <- data.frame(
        GameId=character(0),
        move_list=character(0), #will contain string of move sequences
        classical_eval=character(0), #string for evaluation
        nnue_eval=character(0), #string for evaluation
        final_eval=character(0), #string for evaluation
        best_move=character(0)
      )
      
      
      ### loop to feed each move to stock fish list ####    
      for (number  in seq_along(move_list)){
        
        move <- move_list[[number]] #inserts next line of the move_list list
        
        evaluations_df <- append_function(move) #this applies the append function for the currently filtered move to the evaluations_df
        
        evaluations_df$GameId=id  # adds the number of a game in a file
      }
      
      print(id)
      
      write.table(evaluations_df,paste('C:\\Chess\\output_data_new\\Processed_Chunk_',m,'.txt',sep=''), sep='\t', append = TRUE, col.names = FALSE) #continously write the evaluations to the empty dataframe
      
    } #nesting 
}


# Data combining

dat<-read.table(here('output_data_new, Processed_Chunk_1.txt'), sep='\t', header=T, row.names = NULL)
datA<-read.table(here('input_data', 'Chunk_1.txt'), sep='\t', header=T, row.names = NULL)
datA$GameId=1:1000
datComb<-merge(dat, datA, by='GameId')


