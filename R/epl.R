library(dplyr)
library(stringr)
library(httr)
library(bettRtab)
library(piggyback)


# Save to and read from releases -------------------------------------------

save_to_release <- function(df, file_name, release_tag) {

  temp_dir <- tempdir(check = TRUE)
  .f_name <- paste0(file_name,".rds")
  saveRDS(df, file.path(temp_dir, .f_name))

  piggyback::pb_upload(file.path(temp_dir, .f_name),
                       repo = "JaseZiv/Betting-Data",
                       tag = release_tag
  )

}


file_reader <- function(file_name, release_tag) {
  f_name <- paste0(file_name, ".rds")
  piggyback::pb_download(f_name,
                         repo = "JaseZiv/Betting-Data",
                         tag = release_tag,
                         dest = tempdir())
  temp_dir <- tempdir(check = TRUE)

  readRDS(file.path(temp_dir, f_name))
}


# 2022 World Cup -------------------------------------------------------------

get_epl_data <- function(file_name) {

  Sys.setenv(TZ = "Australia/Melbourne")

  scrape_date <- Sys.Date()

  existing <- file_reader(file_name = file_name, "sports")

  scrape_date <- Sys.Date()

  sports <- read.csv("https://github.com/JaseZiv/bettRtab_data/raw/main/data/sports_markets.csv")

  sports <- sports %>%
    dplyr::filter(str_detect(competitions.name, "English Premier League")) %>%
    dplyr::pull(competitions.name)


  httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                   port = as.numeric(Sys.getenv("PROXY_PORT")),
                                   username =Sys.getenv("PROXY_USERNAME"),
                                   password= Sys.getenv("PROXY_PASSWORD")))

  epl <- sports %>%
    purrr::map_df(get_sports_market)

  epl$scrape_date <- scrape_date

  epl <- dplyr::bind_rows(epl, existing)

  # return(futures)
  save_to_release(df= epl, file_name= file_name, release_tag= "sports")

}

# extract and save
get_epl_data(file_name= "epl_2023_24_markets")

