library(bettRtab)
library(tidyverse)
library(lubridate)
library(scales)
library(gt)
library(here)


# # Update ------------------------------------------------------------------
#
melb_sat_races <-  readRDS("analysis/racing-statistics/melb_sat_races.rds")
#
#
# z <- melb_sat_races[length(melb_sat_races)]
#
# last_date <- z[[1]]$meeting$meetingDate %>% unlist() %>% ymd()
#
# meets <- load_race_meet_meta(2022)
#
#
# meet_dates_df <- meets %>%
#   mutate(meetingDate = ymd(meetingDate)) %>%
#   mutate(meet_day = as.character(wday(meetingDate, label = T))) %>%
#   filter(venueMnemonic == "M", raceType == "R", meet_day == "Sat") %>%
#   # filter(meetingName %in% c("SANDOWN", "CAULFIELD", "FLEMINGTON", "MOONEE VALLEY")) %>%
#   filter(meetingDate > last_date)
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
# melb_sat_races_updated <- get_past_race_content(urls = urls)
#
# melb_sat_races <- append(melb_sat_races, melb_sat_races_updated)
#
#
# updated_missing_meet <- bettRtab::get_race_meet_meta("2022-11-19") %>%
#   mutate(meetingDate = ymd(meetingDate)) %>%
#   mutate(meet_day = as.character(wday(meetingDate, label = T))) %>%
#   filter(venueMnemonic == "M", raceType == "R", meet_day == "Sat")
#
# meet_urls <- updated_missing_meet$races
#
# urls <- c()
#
# for(i in meet_urls) {
#   each <- i[["_links"]] %>% unlist()
#   urls <- c(urls, each) %>% unname()
# }
#
#
# melb_sat_races_missing <- get_past_race_content(urls = urls)
#
# melb_sat_races <- append(melb_sat_races, melb_sat_races_missing)
#
# saveRDS(melb_sat_races, "analysis/racing-statistics/melb_sat_races.rds")




melb_sat_races <- readRDS(here("analysis", "racing-statistics", "melb_sat_races.rds"))
runners_m_r <- parse_runners(melb_sat_races)

pools <- parse_pools(melb_sat_races)

pools <- pools %>%
  mutate(meetingDate = ymd(meetingDate)) %>%
  filter(wageringProduct == "Quaddie")


dividends <- parse_dividends(melb_sat_races)

dividends <- dividends %>%
  filter(wageringProduct == "Quaddie")

# races21 <- bettRtab::load_race_meet_meta(cal_year = 2021)
race_meta <- bettRtab::load_race_meet_meta(cal_year = 2022)


race_meta <- race_meta %>%
  mutate(meetingDate = ymd(meetingDate)) %>%
  mutate(meet_day = as.character(wday(meetingDate, label = T))) %>%
  filter(venueMnemonic == "M", raceType == "R", meet_day == "Sat") %>%
  select(meetingDate, meetingName, weatherCondition, trackCondition)


missing_first_leg <- "2022-10-08"

missing_race_meta <- runners_m_r %>%
  filter(meetingDate == missing_first_leg) %>%
  slice(1) %>%
  select(meetingDate, location, meetingName, raceType, venueMnemonic, raceNumber, raceName, raceClassConditions)

missing_race_meta <- missing_race_meta %>%
  mutate(raceNumber = "7",
         raceName = "Neds Might And Power",
         raceClassConditions = "WFA-G1")

missing_runners <- data.frame(runnerName = as.character(c("ZAAKI", "I'M THUNDERSTRUCK", "ALLIGATOR BLOOD", "MR BRIGHTSIDE", "MO'UNGA", "NONCONFORMIST", "ANAMOE", "BENAUD")),
                              runnerNumber = 1:8,
                              finishingPosition = c(3,2,0,4,0,0,1,0),
                              fixedOdds.returnWin = c(5,7,6.5,23,11,81,2.1,21),
                              fixedOdds.returnPlace = c(1.6,1.9,1.85,4.2,2.5,10,1.2,3.9),
                              fixedOdds.bettingStatus = c("Placing", "Placing", "Loser", "Loser", "Loser", "Loser", "Winner", "Loser"),
                              parimutuel.bettingStatus = rep("Normal", 8),
                              parimutuel.returnWin = c(5.1,6.1,6.1,17,11.1,63.6,2.2,20.2),
                              parimutuel.returnPlace = c(1.6,1.9,2,3.3,2.4,8.8,1.2,3.6))


missing_race_meta <- missing_race_meta %>% bind_cols(missing_runners)


runners_m_r <- runners_m_r %>%
  bind_rows(missing_race_meta) %>%
  arrange(meetingDate, as.numeric(raceNumber), as.numeric(runnerNumber))


# because the initial scrape included Cranbourne to test for errors
runners_m_r <- runners_m_r %>%
  mutate(meetingDate = ymd(meetingDate)) %>%
  # filter(meetingName != "CRANBOURNE") %>%
  left_join(race_meta, by = c("meetingDate", "meetingName")) %>%
  mutate(is_group_race = str_detect(raceClassConditions, "GP"))





quad_legs <- pools %>%
  distinct(meetingDate, meetingName, raceNumber) %>%
  arrange(meetingDate, as.numeric(raceNumber)) %>%
  group_by(meetingDate) %>%
  mutate(legNumber = row_number()) %>%
  ungroup()

runners_m_r <- runners_m_r %>%
  left_join(quad_legs, by = c("meetingDate", "meetingName", "raceNumber"))



# load in the quaddie numbers picked by punters club
punters_nums <- read.csv(file.path("analysis", "racing-statistics", "punters-club", "punters_quaddie_numbers.csv"))


quaddie_winners <- runners_m_r %>%
  filter(meetingDate >= ymd("2022-08-27")) %>%
  filter(!is.na(legNumber)) %>%
  filter(finishingPosition == 1)


quaddie_winners <- quaddie_winners %>%
  left_join(punters_nums %>% mutate(Date = ymd(Date)), by = c("meetingDate" = "Date"))

in_list <- function(x) {
  as.character(runnerNumber) %in% unlist(strsplit(Leg2, ","))
}


for(i in 1:nrow(quaddie_winners)) {
  if(quaddie_winners$legNumber[i] == 1) {
    quaddie_winners$gotLeg[i] <- "Yes"
  } else if (quaddie_winners$legNumber[i] == 2 && as.character(quaddie_winners$runnerNumber[i]) %in% unlist(strsplit(quaddie_winners$Leg2[i], ","))) {
    quaddie_winners$gotLeg[i] <- "Yes"
  } else if (quaddie_winners$legNumber[i] == 3 && as.character(quaddie_winners$runnerNumber[i]) %in% unlist(strsplit(quaddie_winners$Leg3[i], ","))) {
    quaddie_winners$gotLeg[i] <- "Yes"
  } else if (quaddie_winners$legNumber[i] == 4 && as.character(quaddie_winners$runnerNumber[i]) %in% unlist(strsplit(quaddie_winners$Leg4[i], ","))) {
    quaddie_winners$gotLeg[i] <- "Yes"
  } else {
    quaddie_winners$gotLeg[i] <- "No"
  }
}


# quaddie_winners %>% select(meetingDate, raceNumber, runnerNumber, Placed, tidyselect::contains("leg")) %>% view()


quaddie_winners %>%
  group_by(legNumber) %>%
  mutate(number_races = n()) %>%
  group_by(legNumber, gotLeg, number_races) %>%
  summarise(number_winners = n()) %>% ungroup() %>%
  mutate(win_percentage = number_winners / number_races) %>%
  filter(gotLeg == "Yes") %>%
  select(legNumber, number_winners, number_races, win_percentage) %>%
  mutate(win_percentage = scales::percent(win_percentage, accuracy = 0.1))


runners_m_r %>%
  filter(meetingDate >= ymd("2022-08-27")) %>%
  filter(!is.na(legNumber)) %>%
  filter(parimutuel.bettingStatus != "Scratched",
         fixedOdds.bettingStatus != "LateScratched") %>%
  group_by(meetingDate, meetingName, raceNumber, legNumber) %>%
  summarise(n_runners = n(),
            sd_race_odds = sd(parimutuel.returnWin),
            race_range = range(parimutuel.returnWin)[2] - range(parimutuel.returnWin)[1]) %>%
  ungroup() %>%
  group_by(legNumber) %>%
  summarise(n_meets = n_distinct(meetingDate),
            avg_runners = mean(n_runners),
            median_runners = median(n_runners),
            avg_sd_runners = mean(sd_race_odds),
            avg_range = mean(race_range)) %>%
  mutate(range_per_runner = avg_range / avg_runners)



# runners_m_r %>%
#   filter(meetingDate >= ymd("2022-08-27")) %>%
#   filter(!is.na(legNumber)) %>%
#   filter(parimutuel.bettingStatus != "Scratched") %>%
#   # group_by(meetingDate, meetingName, raceNumber, legNumber) %>%
#   # summarise(n_runners = n()) %>%
#   # ungroup() %>%
#   group_by(legNumber) %>%
#   summarise(avg_price = mean(parimutuel.returnWin))


runners_m_r %>%
  filter(meetingDate >= ymd("2022-08-27")) %>%
  filter(!is.na(legNumber)) %>%
  filter(parimutuel.bettingStatus != "Scratched",
         finishingPosition == 1) %>%
  # group_by(meetingDate, meetingName, raceNumber, legNumber) %>%
  # summarise(n_runners = n()) %>%
  # ungroup() %>%
  group_by(legNumber) %>%
  summarise(avg_win_price = mean(parimutuel.returnWin),
            median_win_price = median(parimutuel.returnWin))



runners_m_r %>%
  filter(meetingDate >= ymd("2022-08-27")) %>%
  group_by(meetingDate, meetingName, raceNumber) %>%
  mutate(n_runners = n()) %>%
  filter(parimutuel.bettingStatus != "Scratched",
         finishingPosition == 1) %>%
  select(meetingDate, meetingName, raceNumber, parimutuel.returnWin, n_runners) %>%
  lm(parimutuel.returnWin ~ n_runners, data=.) %>% summary()

