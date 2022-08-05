# Project Overview: Has Decision Making in Chess Improved Over the Past Century?
This repository contains all files used in my MSc research project. This project aimed to measure if move selection accuracy had improved within chess players from 1850 to 2020. The chess engine *'Stockfish 15'* was used to evaluate the degree to which each individual move selected by players matched the *'optimal'* move suggested by Stockfish. This 'move accuracy' was then averaged across each player within a game. 

12,000 games were randomly sampled from ChessBase's Mega Database 2022 [link here](https://shop.chessbase.com/en/products/mega_database_2022). 

This data was then analysed using a GAM (generalised additive model) to investigate the presumed non-linear relationship between **year** the game was played and **'move accuracy'**, whilst controlling for **Elo-rating** (a player's current proffessional standing).

As this is still an ongoing project the analysis, visualisations and rMarkdown is yet to be completed. 

## Important Information before Running the Code
The working directory should include all the files and folders in the current repository format. The data pipeline requires heavy computational processing and time to complete, so is not recommended to perform. This repository's main purpose is to act as an exemplar for the steps taken in the project. 

The working directory should also contain an empty folder titled **'output_data'**. This will be where the output files of the data pipeline are stored.

Ensure the **here()** function is set correctly to your working directory, by first restarting R and then setting the working directory to the source file location. 

## Repository Overview
**input_data:** The data that is fed into the data pipeline. These are text files containing information on a given chess game.

**loop.R:** This is the R code for the data pipeline. It reads in the text files and retrieves the move evaluations from *Stockfish*. It then appends these to the end of a text file in the folder titled **'output_data'**. The file then joins these files back to the input files.

**analysis.R:** This R script cleans the data in preparation for analysis and then formulates the GAM. 

**stockfish_15_x64_avx2.exe:** This is the Stockfish 15 software. A terminal is created between this and R.
