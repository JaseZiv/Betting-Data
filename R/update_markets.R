library(dplyr)
library(httr)
library(bettRtab)
library(piggyback)


# this comes directly from the bettRtab_data repository.
# Have just included it here to ensure we're getting all the currently available markets on demand when this script runs
get_available_markets <- function() {

  httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                   port = as.numeric(Sys.getenv("PROXY_PORT")),
                                   username =Sys.getenv("PROXY_USERNAME"),
                                   password= Sys.getenv("PROXY_PASSWORD")))


  headers = c(
    `sec-ch-ua` = '"Chromium";v="128", "Not;A=Brand";v="24", "Google Chrome";v="128"',
    Accept = "application/json, text/plain, */*",
    Referer = "https://www.tab.com.au/",
    `sec-ch-ua-mobile` = "?0",
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
    `sec-ch-ua-platform` = '"macOS"'
  )

  params = list(
    `jurisdiction` = "VIC"
  )

  res <- httr::GET(url = "https://api.beta.tab.com.au/v1/tab-info-service/sports", httr::add_headers(.headers=headers), query = params)


  a <- httr::content(res)
  b <- a$sports

  all_data <- data.frame()

  for(i in b) {
    each_sport <- jsonlite::toJSON(i) %>% jsonlite::fromJSON() %>% data.frame()

    all_data <- dplyr::bind_rows(all_data, each_sport)
  }

  all_data <- all_data %>%
    select(-tidyr::any_of(c("X_links.self", "X_links.selfTemplate", "X_links.competitions", "X_links.footytab")))
  ## here, we want to do soemthing with the FALSE results - expand those out:
  which_to_change <- all_data$competitions.hasMarkets == TRUE

  # idx <- grep(!which_to_change, which_to_change)
  to_change <- all_data[!which_to_change, ]
  # to_change <- .unlist_df_cols(to_change)


  to_change <- to_change %>%
    select(id, name, displayName, spectrumId, competitions.tournaments, sameGame)

  to_change <- tidyr::unnest(to_change,
                             cols = competitions.tournaments, names_sep = ".")

  names(to_change) <- gsub(".tournaments", "", names(to_change))


  to_change <- tidyr::unnest(to_change,
                             cols = c(competitions.id, competitions.name, competitions.spectrumId,
                                      competitions._links))



  no_change <- all_data[which_to_change, ]

  no_change <- no_change %>%
    dplyr::select(-competitions.tournaments, -competitions.hasMarkets, -competitions.sameGame)

  no_change <- tidyr::unnest(no_change,
                             cols = c(competitions.id, competitions.name, competitions.spectrumId,
                                      competitions._links))

  all_data <- bind_rows(no_change, to_change)

  return(all_data)
}


# now execute the function to retur the CURRENTLY available sports markets
sports_df <- get_available_markets()



# copy a betteRtab helper function
.unlist_df_cols <- function(data) {
  df_name <- names(data)

  ListCols <- sapply(data, is.list)
  data <- cbind(data[!ListCols], t(apply(data[ListCols], 1, as.character)))
  colnames(data) <- df_name
  return(data)
}

# here we're recreating bettRtab::get_sports_market() locally to take in the sports_df we're also doing locally
get_sports_market_local <- function (sport_df, competition_name)
{
  # sports <- .file_reader("https://github.com/JaseZiv/bettRtab_data/blob/main/data/sports_markets.rds?raw=true")
  link_url <- sport_df %>% dplyr::filter(.data[["competitions.name"]] ==
                                         competition_name) %>% dplyr::pull(.data[["self"]]) %>%
    unlist()

  headers = c(
    `sec-ch-ua` = '"Chromium";v="128", "Not;A=Brand";v="24", "Google Chrome";v="128"',
    Accept = "application/json, text/plain, */*",
    Referer = "https://www.tab.com.au/",
    `sec-ch-ua-mobile` = "?0",
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
    `sec-ch-ua-platform` = '"macOS"'
  )

  res <- httr::GET(link_url, httr::add_headers(.headers=headers)) %>% httr::content()
  aa <- res$matches
  markets_df <- data.frame()
  for (j in 1:length(aa)) {
    markets <- aa[[j]]$markets %>% jsonlite::toJSON() %>%
      jsonlite::fromJSON() %>% data.frame()
    markets <- markets %>% dplyr::rename(marketId = .data[["id"]],
                                         marketName = .data[["name"]], marketBettingStatus = .data[["bettingStatus"]],
                                         marketAllowPlace = .data[["allowPlace"]])
    if (any(grep("sameGame", names(markets)))) {
      markets <- markets %>% dplyr::rename(marketSameGame = .data[["sameGame"]])
    }
    df <- tidyr::unnest(markets, cols = .data[["propositions"]]) %>%
      data.frame()
    df <- df %>% dplyr::select(-.data[["differential"]],
                               -.data[["message"]], -.data[["informationMessage"]])
    df <- .unlist_df_cols(df)
    markets_df <- dplyr::bind_rows(markets_df, df)
  }
  return(markets_df)
}



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


get_data <- function(sport_df, current_market, futures_market, file_name) {

  Sys.setenv(TZ = "Australia/Melbourne")

  scrape_date <- Sys.Date()

  betting <- tryCatch(file_reader(file_name = file_name, "sports"), error = function(e) data.frame())

  httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                   port = as.numeric(Sys.getenv("PROXY_PORT")),
                                   username =Sys.getenv("PROXY_USERNAME"),
                                   password= Sys.getenv("PROXY_PASSWORD")))




  markets <- tryCatch(get_sports_market_local(sport_df = sport_df, competition_name = current_market), error = function(e) data.frame())
  futures <- tryCatch(get_sports_market_local(sport_df = sport_df, competition_name = futures_market), error = function(e) data.frame())

  futures <- dplyr::bind_rows(futures, markets)

  if(nrow(futures) > 0) {
    futures$scrape_date <- scrape_date
  }

  futures <- dplyr::bind_rows(futures, betting)

  # return(futures)
  save_to_release(df= futures, file_name= file_name, release_tag= "sports")

}




#===============================================================================================
# Update Markets ----------------------------------------------------------
#===============================================================================================

# get_data(sport_df = sports_df, current_market = "NBL", futures_market = "NBL Futures", file_name = "nbl_betting")


# get_data(current_market = "A League Men", futures_market = "A League Men Futures", file_name = "aleague_betting")

get_data(sport_df = sports_df, current_market = "AFL", futures_market = "AFL Futures", file_name = "afl_betting")
get_data(sport_df = sports_df, current_market = "Brownlow Medal", futures_market = "", file_name = "brownlow_betting")

# get_data(sport_df = sports_df, current_market = "NFL", futures_market = "NFL Futures", file_name = "nfl_futures")
#
# get_data(sport_df = sports_df, current_market = "English Premier League", futures_market = "English Premier League Futures", file_name = "epl_2023_24_markets")
#
#
# get_data(sport_df = sports_df, current_market = "A League Men", futures_market = "A League Men Futures", file_name = "a_league_men")
# get_data(sport_df = sports_df, current_market = "A League Women", futures_market = "A League Women Futures", file_name = "a_league_women")
#
# get_data(sport_df = sports_df, current_market = "EuroLeague", futures_market = "", file_name = "euroleague_men")

# get_data(current_market = "...", futures_market = "Victorian Politics", file_name = "vic_pol_futures")

rm(list = ls())
