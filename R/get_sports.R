library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)


params = list(
  `jurisdiction` = 'VIC'
)

httr::set_config(httr::user_agent("RStudio Desktop (2022.7.1.554); R (4.1.1 x86_64-w64-mingw32 x86_64 mingw32)"))

res <- httr::GET(url = 'https://api.beta.tab.com.au/v1/tab-info-service/sports', query = params)

a <- httr::content(res)
b <- a$sports

all_data <- data.frame()

for(i in b) {
  each_sport <- jsonlite::toJSON(i) %>% jsonlite::fromJSON() %>% data.frame()

  all_data <- dplyr::bind_rows(all_data, each_sport)
}

all_data <- all_data %>%
  dplyr::select(-competitions.tournaments)

all_data <- tidyr::unnest(all_data,
                     cols = c(competitions.id, competitions.name, competitions.spectrumId,
                              competitions._links, competitions.hasMarkets,
                              competitions.sameGame))

saveRDS(all_data, "data/sports_markets.rds")



