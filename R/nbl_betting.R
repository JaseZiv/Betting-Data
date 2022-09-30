library(dplyr)
library(httr)
library(bettRtab)

# NFL Futures -------------------------------------------------------------

Sys.setenv(TZ = "Australia/Melbourne")

scrape_date <- Sys.Date()

nbl_betting <- readRDS(file.path("data", "nbl_betting.rds"))

httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                 port = as.numeric(Sys.getenv("PROXY_PORT")),
                                 username =Sys.getenv("PROXY_USERNAME"),
                                 password= Sys.getenv("PROXY_PASSWORD")))


nbl_markets <- get_sports_market(competition_name = "NBL")
futures_markets <- get_sports_market(competition_name = "NBL Futures")

futures_markets <- dplyr::bind_rows(nbl_markets, futures_markets)

futures_markets$scrape_date <- scrape_date

futures_markets <- dplyr::bind_rows(futures_markets, nbl_betting)


saveRDS(futures_markets, "data/nbl_betting.rds")


rm(list = ls())
