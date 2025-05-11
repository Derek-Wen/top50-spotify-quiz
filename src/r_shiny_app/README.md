# Shiny App - Spotify Cover Art Quiz

### Live Application: [Spotify Cover Art Quiz](https://dwen.shinyapps.io/spotify-cover-art-quiz/)

## App Overview

This Shiny application provides a fun and interactive way to test your knowledge of popular Spotify tracks based solely on their cover art. It integrates a Flask-based recommendation system deployed on Amazon EC2 to suggest similar songs.

## Application Features

### Quiz Interface

This interface allows you to engage with the quiz:

- Guess the song title and artist from the displayed Spotify cover art.
- Receive feedback on your guesses.
- Get personalized track recommendations after each guess based on your selection.
- Track your score throughout the session.

### Recommendations

After each guess, this section displays similar songs to the one you're quizzed on, retrieved from the Flask recommendation API.

### Data

The app relies on data gathered from Spotify’s "Top 50 Most Streamed Songs" playlist. Key features include:

- Song and artist details.
- Track popularity metrics.
- Artist-related statistics, such as followers and genres.

### About

Provides background information about the quiz mechanics, data collection process, the recommendation model, and deployment details.

---
