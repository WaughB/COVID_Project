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
library(countrycode)
library(randomForest)
library(Metrics)

##### Import the datasets. #####

##### Import train dataset. #####
# Taken from: https://www.kaggle.com/c/covid19-global-forecasting-week-1/data
train <- read_csv(
  "~/Documents/covid_proj/data/train.csv", col_types = cols(
    Date = col_date(format = "%Y-%m-%d"), `Province/State` = col_character()
  )
)

# Add in country code.
train$code <-
  countrycode(train$`Country/Region`,
              origin = "country.name",
              destination = "iso3c")

# Remove unneeded information, and rename columns.
smaller_train <- train %>%
  select(Date, code, ConfirmedCases, Fatalities) %>%
  group_by(Date, code) %>%
  summarize(
    date = Date,
    code = code,
    cases = ConfirmedCases,
    deaths = Fatalities
  )

##### Import the test data. #####
# Taken from: https://www.kaggle.com/c/covid19-global-forecasting-week-1/data

test <- read_csv(
  "~/Documents/covid_proj/data/test.csv", col_types = cols(
    Date = col_date(format = "%Y-%m-%d"), `Province/State` = col_character()
  )
)

# Add in country code.
test$code <-
  countrycode(test$`Country/Region`,
              origin = "country.name",
              destination = "iso3c")

# Remove unneeded information, and rename columns.
smaller_test <- test %>%
  select(Date, code) %>%
  group_by(Date, code) %>%
  summarize(
    date = Date,
    code = code
  )

##### Gather additional data. #####

##### Add alcohol use.#####
# Taken from: https://ourworldindata.org/alcohol-consumption
alcohol_consumption <-
  read_csv(
    "~/Documents/covid_proj/data/total-alcohol-consumption-per-capita-litres-of-pure-alcohol.csv",
    col_types = cols(Code = col_character())
  )

# Format alcohol consumption dataset.
alcohol_report_2016 <- alcohol_consumption %>%
  summarise(country = Entity,
            code = Code,
            alcohol_consumption = `Alcohol consumption (litres per capita) (liters of pure alcohol, projected estimates, 15+ years of age)`) %>%
  filter(code != "NA" & country != "World") %>%
  select(code = code, alcohol_consumption = alcohol_consumption)

##### Add drug disorders. #####
# Taken from: https://ourworldindata.org/illicit-drug-use
drug_use_disorders <-
  read_csv("~/Documents/covid_proj/data/share-with-drug-use-disorders.csv")

# Format drug use disoder dataset.
drug_abuse_report_2017 <- drug_use_disorders %>%
  filter(Year == 2017) %>%
  summarise(country = Entity,
            code = Code,
            drug_use = `Prevalence - Drug use disorders - Sex: Both - Age: Age-standardized (Percent) (%)`) %>%
  filter(code != "NA" & country != "World") %>%
  select(code = code, drug_use = drug_use)

##### Add smoking use. #####
# Taken from: https://ourworldindata.org/smoking
cig_consumption <-
  read_csv("~/Documents/covid_proj/data/cig_consumption.csv",
           col_types = cols(income = col_skip()))

cig_consumption <- cig_consumption %>%
  select(code = code,
         cigarette_consumption = cigarette_consumption)

##### Add death rate from opioid use. .#####
# Taken from: https://ourworldindata.org/illicit-drug-use
death_rate_from_opioids <-
  read_csv("~/Documents/covid_proj/data/death-rate-from-opioid-use.csv")

# Format opiod use dataset.
opioid_report_2017 <- death_rate_from_opioids %>%
  filter(Year == 2017) %>%
  summarise(country = Entity,
            code = Code,
            opioid_death_rate = `Deaths - Opioid use disorders - Sex: Both - Age: Age-standardized (Rate) (deaths per 100,000)`) %>%
  filter(code != "NA" & country != "World") %>%
  select(code = code, opioid_death_rate = opioid_death_rate)

##### Add death rate from amphetamine. #####
# Taken from:https://ourworldindata.org/illicit-drug-us
death_rate_amphetamine <-
  read_csv("~/Documents/covid_proj/data/death-rate-amphetamine.csv")

# Format amphetamine dataset.
amphetamine_report_2017 <- death_rate_amphetamine %>%
  filter(Year == 2017) %>%
  summarise(country = Entity,
            code = Code,
            amphetamine_death_rate = `Deaths - Amphetamine use disorders - Sex: Both - Age: Age-standardized (Rate) (deaths per 100,000)`) %>%
  filter(code != "NA" & country != "World") %>%
  select(code = code, amphetamine_death_rate = amphetamine_death_rate)

###### Add death rate from cocaine use. #####
# Taken from: https://ourworldindata.org/illicit-drug-use
death_rates_cocaine <-
  read_csv("~/Documents/covid_proj/data/death-rates-cocaine.csv")

# Format cocaine dataset.
cocaine_report_2017 <- death_rates_cocaine %>%
  filter(Year == 2017) %>%
  summarise(country = Entity,
            code = Code,
            cocaine_death_rate = `Deaths - Cocaine use disorders - Sex: Both - Age: Age-standardized (Rate) (deaths per 100,000)`) %>%
  filter(code != "NA" & country != "World") %>%
  select(code = code, cocaine_death_rate = cocaine_death_rate)

##### Add prison population. #####
# Taken from: https://dataunodc.un.org/crime/total-prison-population
prison_report <-
  read_excel("~/Documents/covid_proj/data/UN_prison_report.xlsx")

prison_report$code <-
  countrycode(prison_report$Countries,
              origin = "country.name",
              destination = "iso3c")

# Format the prison dataset.
prison_report_2017 <- prison_report %>%
  select(Countries, Year, Count, Rate, code) %>%
  filter(Year == 2017) %>%
  summarize(code = code,
            prisoner_count = Count,
            prisoner_rate = Rate)

##### Add port information #####
# Taken from: https://unctadstat.unctad.org/wds/TableViewer/tableView.aspx?ReportId=170027
port_calls <- read_csv(
  "~/Documents/covid_proj/data/Port_Calls.csv",
  col_types = cols(
    median_time_in_port_days = col_double(),
    number_of_arrivals = col_double()
  )
)

port_calls$code <-
  countrycode(port_calls$country,
              origin = "country.name",
              destination = "iso3c")

# Format the port information.
ports <- port_calls %>%
  filter(country != "World" & measure == "All ships") %>%
  select(code, number_of_arrivals, median_time_in_port_days)

##### Add airport information #####
# Taken from: https://www.cia.gov/library/publications/the-world-factbook/rankorder/2053rank.html
airports_by_country <-
  read_csv("~/Documents/covid_proj/data/airports_by_country.csv")

airports_by_country$code <-
  countrycode(airports_by_country$country,
              origin = "country.name",
              destination = "iso3c")

# Format the airport information.
airports <- airports_by_country %>%
  select(code, airports)

##### Add older population information #####
# Taken from: https://data.worldbank.org/indicator/SP.POP.65UP.TO.ZS
population_65_and_older <-
  read_csv("~/Documents/covid_proj/data/population_65_and_older.csv")

older_population <- population_65_and_older %>%
  select(code, percentage_65_and_older)

##### Combine train dataset with additional data. #####

# Combine the data using the country codes.

temp1 <-
  merge(alcohol_report_2016,
        drug_abuse_report_2017,
        by = "code")

temp2 <-
  merge(temp1, amphetamine_report_2017, by = "code")

temp3 <-
  merge(temp2, cocaine_report_2017, by = "code")

temp4 <-
  merge(temp3, cig_consumption, by = "code")

temp5 <- merge(temp4, opioid_report_2017, by = "code")

temp6 <- merge(temp5, older_population, by = "code")

temp7 <- merge(temp6, ports, by = "code")

temp8 <- merge(temp7, airports, by = "code")

temp9 <- merge(temp8, prison_report_2017, by = "code")

# The training data with all additional data. 
final_train <- merge(smaller_train, temp9, by = "code")

final_train$country <-
  countrycode(final_train$code,
              origin = "iso3c",
              destination = "country.name")

# Reorder the features.
final_train <- final_train %>%
  select(
    date,
    country,
    code,
    cases,
    deaths,
    alcohol_consumption,
    drug_use,
    amphetamine_death_rate,
    cocaine_death_rate,
    cigarette_consumption,
    opioid_death_rate,
    percentage_65_and_older,
    number_of_arrivals,
    median_time_in_port_days,
    airports,
    prisoner_count,
    prisoner_rate
  ) %>% arrange(code, date)

# The testing data with all additional data. 
final_test <- merge(smaller_test, temp9, by = "code")

final_test$country <-
  countrycode(final_test$code,
              origin = "iso3c",
              destination = "country.name")

# Reorder the features.
final_test <- final_test %>%
  select(
    date,
    country,
    code,
    alcohol_consumption,
    drug_use,
    amphetamine_death_rate,
    cocaine_death_rate,
    cigarette_consumption,
    opioid_death_rate,
    percentage_65_and_older,
    number_of_arrivals,
    median_time_in_port_days,
    airports,
    prisoner_count,
    prisoner_rate
  ) %>% arrange(code, date)

##### Determine important features #####

# Standard formula relating all features from final training set. 
deaths_form <- deaths ~ date+cases+alcohol_consumption+drug_use+amphetamine_death_rate+cocaine_death_rate+cigarette_consumption+opioid_death_rate+percentage_65_and_older+number_of_arrivals+median_time_in_port_days+airports+prisoner_count+prisoner_rate

# Linear model test. 
deaths_linTest <- lm(deaths_form, final_train)
summary(deaths_linTest)

# Standard formula relating all features from final training set. 
cases_form <- cases ~ date+deaths+alcohol_consumption+drug_use+amphetamine_death_rate+cocaine_death_rate+cigarette_consumption+opioid_death_rate+percentage_65_and_older+number_of_arrivals+median_time_in_port_days+airports+prisoner_count+prisoner_rate

# Linear model test. 
cases_linTest <- lm(cases_form, final_train)
summary(cases_linTest)

##### SVM Modeling #####

# Recreate formulas with relevant features only.
deaths_form_final <-
  deaths ~ date + alcohol_consumption + amphetamine_death_rate +
  cigarette_consumption + percentage_65_and_older + median_time_in_port_days +
  prisoner_count + prisoner_rate

cases_form_final <-
  cases ~ date + alcohol_consumption + drug_use + amphetamine_death_rate +
  cigarette_consumption + number_of_arrivals + median_time_in_port_days +
  airports + prisoner_count + prisoner_rate


# Set seed value to ensure reproducible results.
set.seed(1337)

# Parameters for the SVM predicting fatalities.
deaths_tune <- tune(
  svm,
  deaths_form_final,
  data = final_train,
  kernal = c("linear", "radial", "polynomial", "sigmoid"),
  ranges = list(
    gamma = seq(0, 1, 0.2),
    epsilon = seq(0, 1, 0.2),
    cost = seq(0.1, 3, 1)
  ),
  
  tunecontrol = e1071::tune.control(
    random = FALSE,
    nrepeat = 1,
    repeat.aggregate = mean,
    sampling = c("cross", "fix", "bootstrap"),
    sampling.aggregate = mean,
    sampling.dispersion = sd,
    cross = 10,
    fix = 4 / 5,
    nboot = 10,
    boot.size = 9 / 10,
    best.model = TRUE,
    performances = TRUE,
    error.fun = NULL
  )
)

# Parameters for the SVM predicting cases.
cases_tune <- tune(
  svm,
  cases_form_final,
  data = final_train,
  kernal = c("linear", "radial", "polynomial", "sigmoid"),
  ranges = list(
    gamma = seq(0, 1, 0.2),
    epsilon = seq(0, 1, 0.2),
    cost = seq(0.1, 3, 1)
  ),
  
  tunecontrol = tune.control(
    random = FALSE,
    nrepeat = 1,
    repeat.aggregate = mean,
    sampling = c("cross", "fix", "bootstrap"),
    sampling.aggregate = mean,
    sampling.dispersion = sd,
    cross = 10,
    fix = 4 / 5,
    nboot = 10,
    boot.size = 9 / 10,
    best.model = TRUE,
    performances = TRUE,
    error.fun = NULL
  )
)

##### Predictions #####

# Place to store the results. 
results <- list()

# Place ForcastId in results.
results$ForcastId <- test$ForecastId

# Deaths
results$Fatalities <- predict(deaths_tune, newdata = test)

# Confirmed cases
results$ConfirmedCases <- predict(cases_tune, newdata = test)

##### RMSEL #####

# RMSLE for SVM predicting fatalities. 
deaths_rmsle <- rmsle(testing$Fatalities, results$Fatalities)
deaths_rmsle

# RMSLE for SVM predicting confirmed cases. 
cases_rmsle <- rmsle(testing$ConfirmedCases, results$ConfirmedCases)
cases_rmsle

##### Output #####

write.csv(results, file = "results.csv", row.names = FALSE)