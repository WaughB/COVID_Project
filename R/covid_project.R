# Brett W.
# 22 March 2020.
# Kaggle Competition - COVID19 Global Forecasting (Week 1)
# Objective: To illuminate factors that contribute to the spread of COVID-19.
# Secondary Objective: To predict fatalities of COVID-19. 

##### Necessary libraries. #####
library(readr)
library(readxl)
library(tidyr)
library(dplyr)
library(stats)
library(e1071)

##### Import the datasets. #####

##### Import train dataset. ##### 
# Taken from: https://www.kaggle.com/c/covid19-global-forecasting-week-1/data 
train <- read_csv("Documents/covid_proj/train.csv", 
                    +     col_types = cols(Date = col_date(format = "%Y-%m-%d"), 
                                           +         `Province/State` = col_character()))

# Removed state and province information. 
c1 <- subset(train, select = -c(Lat, Long, Id))

c2 <- c1 %>%
  + subset(select = -c(`Province/State`, `Country/Region`)) %>%
  + unite("Location", State,Country, sep = " - ", remove = FALSE)

# Shows the location with some other important fields. 
test2 <- c2 %>% group_by(Date, Location) %>% summarize(date = Date, location = Location, country = Country, state = State, cases = ConfirmedCases, deaths = Fatalities)

##### Import the test data. #####
# Taken from: https://www.kaggle.com/c/covid19-global-forecasting-week-1/data 

test <- read_csv("Documents/covid_proj/test.csv", 
                 +     col_types = cols(Date = col_date(format = "%Y-%m-%d"), 
                                        +         `Province/State` = col_character()))

##### Gather additional data. #####

##### Add age and sex data. #####
# Taken from: http://data.un.org/Data.aspx?d=POP&f=tableCode%3A22
age_data <- read_csv("Documents/covid_proj/UN_age_data.csv")


##### Add alcohol use.##### 
# Taken from: https://ourworldindata.org/alcohol-consumption
alcohol_consumption <- read_csv("Documents/covid_proj/total-alcohol-consumption-per-capita-litres-of-pure-alcohol.csv", 
                                col_types = cols(Code = col_character()))

# Format alcohol consumption dataset. 
alcohol_report_2016 <- alcohol_consumption %>%
  summarise(country = Entity, code = Code, alcohol_consumption = `Alcohol consumption (litres per capita) (liters of pure alcohol, projected estimates, 15+ years of age)`) %>%
  filter(code != "NA" & country != "World")

##### Add drug disorders. #####
# Taken from: https://ourworldindata.org/illicit-drug-use
drug_use_disorders <- read_csv("Documents/covid_proj/share-with-drug-use-disorders.csv")

# Format drug use disoder dataset.
drug_abuse_report_2016 <- drug_use_disorders %>%
  filter(Year == 2017) %>%
  summarise(country = Entity, code = Code, drug_use = `Prevalence - Drug use disorders - Sex: Both - Age: Age-standardized (Percent) (%)`) %>%
  filter(code != "NA" & country != "World")

##### Add smoking use. #####
# Taken from: https://ourworldindata.org/smoking  
smoking_use <- read_csv("Documents/covid_proj/share-of-adults-who-smoke.csv")

# Format smoking dataset. 
smoking_report_2016 <- smoking_use %>%
  filter(Year == 2016) %>%
  summarise(country = Entity, code = Code, smoking_use = `Smoking prevalence, total (ages 15+) (% of adults)`) %>%
  filter(code != "NA" & country != "World")

##### Add death rate from opioid use. .##### 
# Taken from: https://ourworldindata.org/illicit-drug-use
death_rate_from_opioids <- read_csv("Documents/covid_proj/death-rate-from-opioid-use.csv")

# Format opiod use dataset. 
opioid_report_2017 <- death_rate_from_opioids %>%
  filter(Year == 2017) %>%
  summarise(country = Entity, code = Code, opioid_death_rate = `Deaths - Opioid use disorders - Sex: Both - Age: Age-standardized (Rate) (deaths per 100,000)`) %>%
  filter(code != "NA" & country != "World")

##### Add death rate from amphetamine. #####
# Taken from:https://ourworldindata.org/illicit-drug-us
death_rate_amphetamine <- read_csv("Documents/covid_proj/death-rate-amphetamine.csv")

# Format amphetamine dataset. 
amphetamine_report_2017 <- death_rate_amphetamine %>%
  filter(Year == 2017) %>%
  summarise(country = Entity, code = Code, amphetamine_death_rate = `Deaths - Amphetamine use disorders - Sex: Both - Age: Age-standardized (Rate) (deaths per 100,000)`) %>%
  filter(code != "NA" & country != "World")

###### Add death rate from cocaine use. #####
# Taken from: https://ourworldindata.org/illicit-drug-use 
death_rates_cocaine <- read_csv("Documents/covid_proj/death-rates-cocaine.csv")

# Format cocaine dataset. 
cocaine_report_2017 <- death_rates_cocaine %>%
  filter(Year == 2017) %>% 
  summarise(country = Entity, code = Code, cocaine_death_rate = `Deaths - Cocaine use disorders - Sex: Both - Age: Age-standardized (Rate) (deaths per 100,000)`) %>%
  filter(code != "NA" & country != "World")

##### Add prison population. #####
# Taken from: https://dataunodc.un.org/crime/total-prison-population 
prison_report <- read_excel("Documents/covid_proj/UN_prison_report.xlsx")

# Format the prison dataset. 
prison_report_2017 <- prison_report %>%
  select(Countries, Year, Count, Rate) %>%
  filter(Year == 2017) %>%
  summarize(country = Countries, count = Count, rate = Rate)

##### Combine train dataset with additional data. #####

# Combine the reports for: alcohol, drug abuse, amphetamine, opioids, smoking, and cocaine. 

temp1 <- merge(alcohol_report_2016, drug_abuse_report_2016, by = c("code", "country"))

temp2 <- merge(temp1, amphetamine_report_2017, by = c("code", "country"))

temp3 <- merge(temp2, cocaine_report_2017, by = c("code", "country"))

temp4 <- merge(temp3, smoking_report_2016, by = c("code", "country"))

temp5 <- merge(temp4, opioid_report_2017, by = c("code", "country"))

# TODO: Fix the prison report.
# TODO: Add in age dataset. 
temp6 <- merge(temp5,prison_report_2017_2, by = "country")

final_train <- merge(test2, temp5, by = "country")
