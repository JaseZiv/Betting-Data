library(dplyr)
library(httr)
library(bettRtab)

# NFL Futures -------------------------------------------------------------

Sys.setenv(TZ = "Australia/Melbourne")

scrape_date <- Sys.Date()

nfl_futures <- readRDS(file.path("data", "nfl_futures.rds"))

httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                 port = as.numeric(Sys.getenv("PROXY_PORT")),
                                 username =Sys.getenv("PROXY_USERNAME"),
                                 password= Sys.getenv("PROXY_PASSWORD")))


futures_markets <- tryCatch(get_sports_market(competition_name = "NFL Futures"), error = function(e) data.frame())

futures_markets$scrape_date <- scrape_date

futures_markets <- dplyr::bind_rows(futures_markets, nfl_futures)


saveRDS(futures_markets, "data/nfl_futures.rds")


rm(list = ls())
