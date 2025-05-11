# src/r_shiny_app/app.R
library(shiny)
library(bslib)
library(shinyjs)
library(httr)
library(jsonlite)
library(here)
library(dplyr)
library(stringdist)

API_URL  <- "http://ec2-54-183-183-87.us-west-1.compute.amazonaws.com:8000"
DATA_CSV <- here("data", "playlist_enriched.csv")
all_df   <- read.csv(DATA_CSV, stringsAsFactors = FALSE)

# theme
spotify_green <- "#1DB954"; spotify_black <- "#191414"
quiz_theme <- bs_theme(
  version = 5, bg = spotify_black, fg = "white", primary = spotify_green,
  base_font = "'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
  heading_font = "'Segoe UI Semibold', Roboto, Helvetica, Arial, sans-serif"
)
custom_css <- tags$style(HTML(sprintf("
  .cover-card{max-width:340px;margin:auto;background:#222;border:0;padding:25px 25px 15px;
              border-radius:16px;box-shadow:0 0 12px #000;}
  .cover-card img{width:290px;border-radius:12px;box-shadow:0 0 8px #000;}
  .btn-primary{background:%s;border-color:%s;} .btn-primary:hover{background:#17a443;}
  .btn-next{background:#fff;color:#000;border-color:#fff;} .btn-next:hover{background:#e6e6e6;}
  .score-badge{background:%s;color:#000;border-radius:20px;padding:6px 14px;font-weight:600;}
  .result-text span{font-weight:600;} .recommend ul{list-style:none;padding:0;text-align:center;}
  .recommend li{padding:2px 0;} .footer-text{margin-top:40px;font-size:0.9rem;color:#bbb;text-align:center;}
", spotify_green, spotify_green, spotify_green)))

# helpers
close_match <- function(a, b) stringdist(tolower(trimws(a)), tolower(trimws(b)), "lv") <= 2
new_session <- function() {
  idx <- sample(nrow(all_df), 5)
  list(order = idx, round = 1, track = all_df[idx[1], ], score = 0,
       attempts = 0, resultShown = FALSE)
}

# UI
ui <- fluidPage(
  theme = quiz_theme, custom_css, useShinyjs(),
  br(), h2("Spotify Cover Art Quiz", class = "text-center mb-4"),
  div(class="text-center",
      span(class="score-badge", textOutput("score", inline = TRUE))
  ),
  
  div(id = "quiz-card", class = "cover-card",
      uiOutput("cover"),
      h5(textOutput("round_text", inline = TRUE), class = "text-center"),
      br(),
      textInput("song_guess",   label = NULL, placeholder = "Enter song title"),
      textInput("artist_guess", label = NULL, placeholder = "Enter artist name (any one)"),
      fluidRow(
        column(6, actionButton("submit",   "Submit", class = "btn-primary w-100")),
        column(6, actionButton("next_btn", "Next",   class = "btn-next w-100", disabled = TRUE))
      ),
      div(class="result-text", htmlOutput("result"))
  ),
  
  conditionalPanel("output.resultShown",
                   br(), h4("Recommended songs:", class = "text-center"),
                   div(class="recommend", uiOutput("recs"))
  ),
  
  div(id = "final-card", style = "display:none",
      h3(textOutput("final_score"), class = "text-center"),
      br(),
      div(class="text-center",
          actionButton("play_again", "Play again", class = "btn-primary"))
  ),
  
  div(class="footer-text",
      "Source: Top 50 Most Streamed Songs", br(), "Derek Wen · STATS 418")
)

# server
server <- function(input, output, session) {
  rv <- reactiveValues()
  
  reset_session <- function() {
    vals <- new_session(); for (n in names(vals)) rv[[n]] <- vals[[n]]
    updateTextInput(session,"song_guess", value="");  updateTextInput(session,"artist_guess", value="")
    output$result <- renderUI(""); output$recs <- renderUI("")
    show("quiz-card"); hide("final-card")
    updateActionButton(session,"submit", disabled=FALSE); updateActionButton(session,"next_btn",disabled=TRUE,label="Next")
  }
  reset_session()
  
  output$cover      <- renderUI(tags$img(src = rv$track$cover_url))
  output$round_text <- renderText(sprintf("Round %d / 5", rv$round))
  output$score      <- renderText(sprintf("%.1f / %d", rv$score, rv$attempts))
  output$resultShown <- reactive(rv$resultShown); outputOptions(output,"resultShown",suspendWhenHidden = FALSE)
  
  # submit
  observeEvent(input$submit, {
    updateActionButton(session,"submit",disabled=TRUE)
    
    song_ok   <- close_match(input$song_guess, rv$track$name)
    artist_ok <- { arts <- strsplit(rv$track$artists,",\\s*")[[1]]
    any(vapply(arts, close_match, logical(1), b=input$artist_guess)) }
    rv$attempts <- rv$attempts + 1; rv$score <- rv$score + 0.5*song_ok + 0.5*artist_ok
    
    make_line <- function(ok, txt, lbl){
      if(ok) span(style="color:#1DB954", HTML("Correct! &#10004;"))
      else   span(style="color:#FF4B4B",
                  HTML(sprintf("The correct %s was %s &#10060;", lbl, txt)))
    }
    output$result <- renderUI(tags$div(
      make_line(song_ok,   sprintf("“%s”", rv$track$name), "song"),
      tags$br(),
      make_line(artist_ok, rv$track$artists, "artist")
    ))
    
    updateActionButton(session,"next_btn",
                       disabled=FALSE,
                       label = if(rv$round==5) "Finish" else "Next")
    
    recs <- fromJSON(content(GET(
      sprintf("%s/recommend/%s?k=5", API_URL, rv$track$id)),
      "text", encoding = "UTF-8"))
    output$recs <- renderUI(tags$ul(
      lapply(seq_len(nrow(recs)), function(i)
        tags$li(sprintf("%s — %s", recs$name[i], recs$artists[i])))))
    
    rv$resultShown <- TRUE
  })
  
  # next / finished
  observeEvent(input$next_btn, {
    if(rv$round < 5) {
      rv$round <- rv$round + 1; rv$track <- all_df[ rv$order[rv$round], ]
      rv$resultShown <- FALSE
      updateTextInput(session,"song_guess", value=""); updateTextInput(session,"artist_guess",value="")
      updateActionButton(session,"submit",disabled=FALSE)
      updateActionButton(session,"next_btn",disabled=TRUE, label=if(rv$round==5) "Finish" else "Next")
      output$cover <- renderUI(tags$img(src = rv$track$cover_url))
      output$round_text <- renderText(sprintf("Round %d / 5", rv$round))
      output$result <- renderUI(""); output$recs <- renderUI("")
    } else {
      # finished
      rv$resultShown <- FALSE
      hide("quiz-card"); show("final-card")
      updateActionButton(session,"submit",disabled=TRUE)
      updateActionButton(session,"next_btn",disabled=TRUE)
      output$final_score <- renderText(sprintf("Final Score: %.1f / 5", rv$score))
      output$recs <- renderUI("")      # clear recommendations
    }
  })
  
  # play again
  observeEvent(input$play_again, { reset_session() }, ignoreInit = TRUE)
}

shinyApp(ui, server)
