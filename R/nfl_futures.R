library(dplyr)
library(httr)
library(jsonlite)
library(tidyr)

# NFL Futures -------------------------------------------------------------

# res <- GET("https://api.beta.tab.com.au/v1/tab-info-service/sports/American%20Football/competitions/NFL%20Futures?jurisdiction=VIC") %>% content()

nfl_futures <- readRDS("data/nfl_futures.rds")

scrape_date <- Sys.Date()

sports <- readRDS("data/sports_markets.rds")

link_url <- sports %>%
  dplyr::filter(competitions.name == "NFL Futures") %>%
  dplyr::pull(self) %>% unlist()

httr::set_config(httr::user_agent("RStudio Desktop (2022.7.1.554); R (4.1.1 x86_64-w64-mingw32 x86_64 mingw32)"))


res <-  httr::GET(link_url) %>% httr::content()

aa <- aa <- res$matches

futures_markets <- data.frame()

for(j in 1:length(aa)) {

  markets <- aa[[j]]$markets %>% jsonlite::toJSON() %>% jsonlite::fromJSON() %>% data.frame()
  markets <- markets %>%
    dplyr::rename(marketId=id, marketName=name, marketBettingStatus=bettingStatus, marketAllowPlace=allowPlace)

  df <- tidyr::unnest(markets, cols = propositions) %>% data.frame()

  futures_markets <- dplyr::bind_rows(futures_markets, df)

}


futures_markets$scrape_date <- scrape_date

futures_markets <- dplyr::bind_rows(futures_markets, nfl_futures)


saveRDS(futures_markets, "data/nfl_futures.rds")
