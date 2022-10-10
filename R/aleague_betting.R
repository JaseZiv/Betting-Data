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
                         tag = release_tag)

  readRDS(f_name)
}

# NFL Futures -------------------------------------------------------------

Sys.setenv(TZ = "Australia/Melbourne")

scrape_date <- Sys.Date()

# aleague_betting <- readRDS(file.path("data", "aleague_betting.rds"))
aleague_betting <- file_reader("aleague_betting", "sports")

httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                 port = as.numeric(Sys.getenv("PROXY_PORT")),
                                 username =Sys.getenv("PROXY_USERNAME"),
                                 password= Sys.getenv("PROXY_PASSWORD")))




aleague_markets <- tryCatch(get_sports_market(competition_name = "A League Men"), error = function(e) data.frame())
futures_markets <- tryCatch(get_sports_market(competition_name = "A League Men Futures"), error = function(e) data.frame())

futures_markets <- dplyr::bind_rows(futures_markets, aleague_markets)

futures_markets$scrape_date <- scrape_date

futures_markets <- dplyr::bind_rows(futures_markets, aleague_betting)


# saveRDS(futures_markets, "data/aleague_betting.rds")
save_to_release(df= futures_markets, file_name= "aleague_betting", release_tag= "sports")


rm(list = ls())
