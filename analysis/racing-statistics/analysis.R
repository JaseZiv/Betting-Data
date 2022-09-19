library(bettRtab)
library(dplyr)

# m_r_race_lists_2021 <- readRDS("~/Documents/Jason/m_r_race_lists_2021.rds")
# m_r_race_lists <- readRDS("~/Documents/Jason/m_r_race_lists.rds")
#
#
# runners <- parse_runners(m_r_race_lists)
# runners_2021 <- parse_runners(m_r_race_lists_2021)
#
#
#
# meets <- load_race_meet_meta(2021)
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
# urls_test <- urls[1:110]
#
# m_r_race_lists_2021 <- get_past_race_content(urls = urls_test)
# saveRDS(m_r_race_lists, "~/Documents/Jason/m_r_race_lists_2021_pt1.rds")
#
# urls_rest <- urls[111:length(urls)]
#
# m_r_race_lists_2021_rest <- get_past_race_content(urls = urls_rest)
# saveRDS(m_r_race_lists_2021_rest, "~/Documents/Jason/m_r_race_lists_2021_pt2.rds")
#
#
# well <- parse_runners(m_r_race_lists_2021)

# m_r_race_lists_2021 <- readRDS("~/Documents/Jason/m_r_race_lists_2021_pt1.rds")
m_r_race_lists_2021_rest <- readRDS("~/Documents/Jason/m_r_race_lists_2021_pt2.rds")
m_r_race_lists <- readRDS("~/Documents/Jason/m_r_race_lists.rds")

# worked <- append(m_r_race_lists_2021, m_r_race_lists_2021_rest)

worked <- append(m_r_race_lists_2021_rest, m_r_race_lists)


did_this_work <- parse_runners(worked)


library(tidyverse)


did_this_work %>%
  count(meetingDate, meetingName, raceType, raceNumber, raceDistance, runnerNumber, sort = T)


did_this_work %>%
  filter(meetingName != "CRANBOURNE") %>%
  filter(finishingPosition == 1) %>%
  ggplot(aes(x=parimutuel.returnWin, y=meetingName)) +
  geom_boxplot() +
  xlim(0,50)


did_this_work %>%
  filter(meetingName != "CRANBOURNE") %>%
  filter(finishingPosition == 1) %>%
  mutate(is_group_race = str_detect(raceClassConditions, "GP")) %>%
  ggplot(aes(x=parimutuel.returnWin, y=raceClassConditions)) +
  geom_boxplot() +
  xlim(0,50)


did_this_work %>%
  filter(meetingName != "CRANBOURNE") %>%
  filter(finishingPosition == 1) %>%
  mutate(is_group_race = str_detect(raceClassConditions, "GP")) %>%
  ggplot(aes(x=parimutuel.returnWin, y=is_group_race)) +
  geom_boxplot() +
  xlim(0,50)



did_this_work %>%
  filter(meetingName != "CRANBOURNE") %>%
  filter(parimutuel.bettingStatus == "Normal") %>%
  group_by(meetingDate, meetingName, raceNumber, raceName, raceDistance, raceClassConditions) %>%
  summarise(sd_win = sd(parimutuel.returnWin, na.rm = T)) %>%
  ggplot(aes(x=sd_win, meetingName)) +
  geom_boxplot()


did_this_work %>%
  filter(meetingName != "CRANBOURNE") %>%
  filter(parimutuel.bettingStatus == "Normal") %>%
  group_by(meetingDate, meetingName, raceNumber, raceName, raceDistance, raceClassConditions) %>%
  summarise(sd_win = sd(parimutuel.returnWin, na.rm = T)) %>%
  arrange(sd_win) %>% view()


did_this_work %>%
  # select(meetingDate, meetingName, raceNumber, raceName, raceDistance, raceClassConditions, parimutuel.returnWin, parimutuel.bettingStatus) %>%
  filter(meetingDate == "2021-03-31",
         meetingName == "SANDOWN",
         raceNumber == "1") %>% view()



did_this_work %>%
  filter(meetingName != "CRANBOURNE") %>%
  filter(parimutuel.bettingStatus == "Normal") %>%
  group_by(meetingDate, meetingName, raceNumber, raceName, raceDistance, raceClassConditions) %>%
  summarise(sd_win = sd(parimutuel.returnWin, na.rm = T)) %>%
  ggplot(aes(x=sd_win, y= factor(raceNumber, levels = 1:10))) +
  geom_boxplot() +
  facet_wrap(~ meetingName)














