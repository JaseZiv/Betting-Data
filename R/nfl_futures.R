library(dplyr)
library(httr)
library(jsonlite)
library(tidyr)

# NFL Futures -------------------------------------------------------------

# res <- GET("https://api.beta.tab.com.au/v1/tab-info-service/sports/American%20Football/competitions/NFL%20Futures?jurisdiction=VIC") %>% content()

nfl_futures <- readRDS(url("https://github.com/JaseZiv/Betting-Data/blob/main/data/nfl_futures.rds?raw=true"))

scrape_date <- Sys.Date()

sports <- readRDS(url("https://github.com/JaseZiv/Betting-Data/blob/main/data/sports_markets.rds?raw=true"))

link_url <- sports %>%
  dplyr::filter(competitions.name == "NFL Futures") %>%
  dplyr::pull(self) %>% unlist()


httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                 port = as.numeric(Sys.getenv("PROXY_PORT")),
                                 username =Sys.getenv("PROXY_USERNAME"),
                                 password= Sys.getenv("PROXY_PASSWORD")))


res <-  httr::GET(link_url) %>% httr::content()

aa <- res$matches

futures_markets <- data.frame()

for(j in 1:length(aa)) {

  markets <- aa[[j]]$markets %>% jsonlite::toJSON() %>% jsonlite::fromJSON() %>% data.frame()
  markets <- markets %>%
    dplyr::rename(marketId=id, marketName=name, marketBettingStatus=bettingStatus, marketAllowPlace=allowPlace) %>%
    dplyr::select(-message, -informationMessage)

  df <- tidyr::unnest(markets, cols = propositions) %>% data.frame()

  futures_markets <- dplyr::bind_rows(futures_markets, df)

}

futures_markets <- futures_markets %>%
  dplyr::select(-differential)

futures_markets$scrape_date <- scrape_date

futures_markets <- dplyr::bind_rows(futures_markets, nfl_futures)


saveRDS(futures_markets, "data/nfl_futures.rds")
