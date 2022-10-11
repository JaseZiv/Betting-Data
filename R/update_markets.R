library(dplyr)
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


get_data <- function(current_market, futures_market, file_name) {

  Sys.setenv(TZ = "Australia/Melbourne")

  scrape_date <- Sys.Date()

  betting <- file_reader(file_name = file_name, "sports")

  httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                   port = as.numeric(Sys.getenv("PROXY_PORT")),
                                   username =Sys.getenv("PROXY_USERNAME"),
                                   password= Sys.getenv("PROXY_PASSWORD")))




  markets <- tryCatch(get_sports_market(competition_name = current_market), error = function(e) data.frame())
  futures <- tryCatch(get_sports_market(competition_name = futures_market), error = function(e) data.frame())

  futures <- dplyr::bind_rows(futures, markets)

  futures$scrape_date <- scrape_date

  futures <- dplyr::bind_rows(futures, betting)

  # return(futures)
  save_to_release(df= futures, file_name= file_name, release_tag= "sports")

}




#===============================================================================================
# Update Markets ----------------------------------------------------------
#===============================================================================================

get_data(current_market = "NBL", futures_market = "NBL Futures", file_name = "nbl_betting")


get_data(current_market = "A League Men", futures_market = "A League Men Futures", file_name = "aleague_betting")


get_data(current_market = "...", futures_market = "NFL Futures", file_name = "nfl_futures")


get_data(current_market = "...", futures_market = "Victorian Politics", file_name = "vic_pol_futures")

rm(list = ls())
