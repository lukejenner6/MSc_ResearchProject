# Has Decision Making in Chess Improved Over the Past Century?
This repository contains all files used in my MSc research project. This project aimed to measure if move selection accuracy had imporved within chess players from 1850 to 2020. The chess engine *'Stockfish 15'* was used to evaluate the degree to which each individual move selected by players matched the *'optimal'* move suggested by Stockfish. This 'move accuracy' was then averaged across each player within a game. 

12,000 games were randomly sampled from ChessBase's Mega Database 2022 [link here](https://shop.chessbase.com/en/products/mega_database_2022). 

This data was then analysed using a GAM (generalised additive model) to investigate the presumed non-linear relationship between **year** the game was played and **'move accuracy'**, whilst controlling for **Elo-rating** (a player's current proffessional standing).

As this is still an ongoing project the analysis, visualisations and rMarkdown is yet to be completed. 
