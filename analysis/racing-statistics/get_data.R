library(bettRtab)
library(dplyr)

# m_r_race_lists_2021 <- readRDS("~/Documents/Jason/m_r_race_lists_2021.rds")
# m_r_race_lists <- readRDS("~/Documents/Jason/m_r_race_lists.rds")
#
#
# runners <- parse_runners(m_r_race_lists)
# runners_2021 <- parse_runners(m_r_race_lists_2021)


#
# meets <- load_race_meet_meta(c(2021:2022))
#
# meet_dates_df <- meets %>% filter(venueMnemonic == "M", raceType == "R") %>%
#   filter(meetingName %in% c("SANDOWN", "CAULFIELD", "FLEMINGTON", "MOONEE VALLEY"))
#
#
# meet_urls <- meet_dates_df$races
#
# urls <- c()
#
# for(i in meet_urls) {
#   each <- i[["_links"]] %>% unlist()
#   urls <- c(urls, each) %>% unname()
# }
#
#
# m_r_race_lists <- get_past_race_content(urls = urls)
# saveRDS(m_r_race_lists, "analysis/racing-statistics/m_r_race_lists.rds")



# Update ------------------------------------------------------------------

m_r_race_lists <-  readRDS("analysis/racing-statistics/m_r_race_lists.rds")


z <- m_r_race_lists[length(m_r_race_lists)]

last_date <- z[[1]]$meeting$meetingDate %>% unlist() %>% ymd()

meets <- load_race_meet_meta(2022)


meet_dates_df <- meets %>%
  mutate(meetingDate = ymd(meetingDate)) %>%
  filter(venueMnemonic == "M", raceType == "R") %>%
  filter(meetingName %in% c("SANDOWN", "CAULFIELD", "FLEMINGTON", "MOONEE VALLEY")) %>%
  filter(meetingDate > last_date)


meet_urls <- meet_dates_df$races

urls <- c()

for(i in meet_urls) {
  each <- i[["_links"]] %>% unlist()
  urls <- c(urls, each) %>% unname()
}


m_r_race_lists_updated <- get_past_race_content(urls = urls)

m_r_race_lists <- append(m_r_race_lists, m_r_race_lists_updated)

saveRDS(m_r_race_lists, "analysis/racing-statistics/m_r_race_lists_updated.rds")



