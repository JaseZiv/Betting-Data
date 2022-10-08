library(dplyr)
library(httr)
library(bettRtab)
library(piggyback)


Sys.setenv(TZ = "Australia/Melbourne")

scrape_date <- Sys.Date()

httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                 port = as.numeric(Sys.getenv("PROXY_PORT")),
                                 username =Sys.getenv("PROXY_USERNAME"),
                                 password= Sys.getenv("PROXY_PASSWORD")))

# # Save to and read from releases -------------------------------------------
#
# save_to_release <- function(df, file_name, release_tag) {
#
#   temp_dir <- tempdir(check = TRUE)
#   .f_name <- paste0(file_name,".rds")
#   saveRDS(df, file.path(temp_dir, .f_name))
#
#   piggyback::pb_upload(file.path(temp_dir, .f_name),
#                        repo = "JaseZiv/Betting-Data",
#                        tag = release_tag
#   )
#
# }
#
#
# file_reader <- function(file_name, release_tag) {
#   f_name <- paste0(file_name, ".rds")
#   piggyback::pb_download(f_name,
#                          tag = release_tag,
#                          dest = tempdir())
#
#   readRDS(f_name)
# }


# Function to get data ----------------------------------------------------

nbl_betting <- readRDS(file.path("data", "nbl_betting.rds"))
# nbl_betting <- file_reader("nbl_betting", "sports")

nbl_markets <- tryCatch(get_sports_market(competition_name = "NBL"), error = function(e) data.frame())
futures_markets <- tryCatch(get_sports_market(competition_name = "NBL Futures"), error = function(e) data.frame())

futures_markets <- dplyr::bind_rows(futures_markets, nbl_markets)

futures_markets$scrape_date <- scrape_date

futures_markets <- dplyr::bind_rows(futures_markets, nbl_betting)

saveRDS(futures_markets, "data/nbl_betting.rds")

# save_to_release(nbl_betting, "nbl_betting", "sports")



rm(list = ls())
