#!/usr/bin/env Rscript
# src/eda/eda.R  – exploratory analysis (outputs PNGs in imgs/)

pkgs <- c("tidyverse", "GGally", "here", "scales")
new  <- pkgs[!(pkgs %in% installed.packages()[,"Package"])]
if(length(new)) install.packages(new, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

df <- read_csv(here("data", "playlist_enriched.csv"), show_col_types = FALSE) %>% 
  mutate(explicit = factor(explicit, levels = c(0,1), labels = c("No","Yes")))

fig_dir <- here("imgs"); dir.create(fig_dir, showWarnings = FALSE)

# Genre distribution
df %>% separate_rows(genres, sep="\\|") %>% filter(genres!="") %>% 
  count(genres, sort=TRUE) %>% slice_head(n=15) %>% 
  ggplot(aes(reorder(genres,n), n)) +
  geom_col(fill="#1DB954") + coord_flip() +
  labs(title="Top 15 Genres", x=NULL, y="Count") +
  theme_minimal() ->
  p_genre
ggsave(file.path(fig_dir,"genres_top15.png"), p_genre, width=6, height=4, dpi=300)

# Numeric distributions
num_cols <- c("popularity", "duration_ms", "artist_followers",
              "artist_popularity", "age_days")

walk(num_cols, function(col){
  p <- ggplot(df, aes(.data[[col]]))
  
  if(col == "artist_followers"){
    p <- p + geom_histogram(fill="#1DB954", colour="black", bins=20) +
      scale_x_log10(labels = comma) +
      labs(title="artist_followers (log10 scale)", x="Followers (log10)")
  } else {
    p <- p + geom_histogram(fill="#1DB954", colour="black", bins=30) +
      labs(title = col)
  }
  
  p <- p + theme_minimal()
  ggsave(file.path(fig_dir, paste0(col,"_hist.png")),
         p, width=5, height=4, dpi=300)
})

# Top ISRC countries
df %>% filter(isrc_country!="") %>% count(isrc_country, sort=TRUE) %>% 
  slice_head(n=15) %>% 
  ggplot(aes(reorder(isrc_country,n), n)) +
  geom_col(fill="#1DB954") + coord_flip() +
  labs(title="Top 15 ISRC Countries", x="Country", y="Count") +
  theme_minimal() ->
  p_cty
ggsave(file.path(fig_dir,"country_top15.png"), p_cty, width=6, height=4, dpi=300)

# Correlation heat-map with labels
corr_df <- df %>% select(all_of(num_cols)) %>% cor(use="pairwise")
corr_long <- as_tibble(reshape2::melt(corr_df), .name_repair="unique")

p_corr <- ggplot(corr_long, aes(Var2, Var1, fill = value)) +
  geom_tile(color="white") +
  geom_text(aes(label = sprintf("%.2f", value)), colour="white", size=3) +
  scale_fill_gradient2(low="#191414", mid="#0E7A37", high="#1DB954",
                       midpoint=0, limits=c(-1,1)) +
  scale_x_discrete(position="top") +
  labs(x=NULL, y=NULL, title="Numeric Feature Correlations") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle=45, hjust=0),
        axis.text = element_text(color="white"),
        plot.background = element_rect(fill="black", colour=NA),
        panel.background = element_rect(fill="black"))

ggsave(file.path(fig_dir,"corr_heatmap.png"),
       p_corr, width=8, height=7, dpi=300)