# COVID-19 Project

Kaggle competition to see what factors are leading to the spread of COVID-19. Secondary objective is to predict fatalities and confirmed cases. 

## Datasets

I found that just the original dataset left much to be desired. I included additional datasets to improve the accuracy of my models. 


### Original 
[Data](https://www.kaggle.com/c/covid19-global-forecasting-week-1/data)

### Additional

[Alcohol use](https://ourworldindata.org/alcohol-consumption)
[Drug use](https://ourworldindata.org/illicit-drug-use)
[Opioid death rate](https://ourworldindata.org/illicit-drug-use)
[Amphetamine death rate](https://ourworldindata.org/illicit-drug-us)
[Cigerette consumption](https://ourworldindata.org/smoking)
[Cocaine death rate](https://ourworldindata.org/illicit-drug-use)

[Number of persons 65+](https://data.worldbank.org/indicator/SP.POP.65UP.TO.ZS)
[Prisoner information](https://dataunodc.un.org/crime/total-prison-population)

[Port information](https://unctadstat.unctad.org/wds/TableViewer/tableView.aspx?ReportId=170027)
[Airport information](https://www.cia.gov/library/publications/the-world-factbook/rankorder/2053rank.html) 

## Methodology

It became apparent that the country names were too diverse to combine data on. I ended up converting the country names into ISO3C to make merging data easier. 

Not all of the additional datasets proved to be useful. Some of the datasets only proved useful predicting fatalities, while other for confirmed cases and some not at all. I used linear modeling to determine which features were going to produce better results. While I would have liked to do more digging into feature selection, I did not have the time to run more sophisticated models with so many features. 

I decided to use support vector machine (SVM) models for this. Often regarded as a black box, SVMs can produce robust results. One of the features I like the most about SVMs is its ability to handle data with several dimensions. The grid search for an SVM can consume a significant amount of resources but the end models are often worth the wait. 

## Results

still to come! 
