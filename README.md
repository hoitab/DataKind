Crop price analysis
===================

###The Question

The analysis was done to answer one of questions posed by [Oxfam](www.oxfam.org) at [DataDive](http://datadivelondon.eventbrite.co.uk/):

> Decompose local food price data into:
> + Long-term trends
> + Seasonal trends
> + Volatility around these two trends

###The Solution
![Sample](/sample-output/Maize%20%28white%29%2C%20Ethiopia-Addis%20Ababa.png)

Crop prices analysis using R.

Analysed food pricing data from UN Food and Agriculture Organization (FAO). This resulted in over 700+ crop-markets pairs. This R code separate it into three components - long term trend, seasonality and noise. 

Some pairs are ignored due to insufficient data (less than 2 years) or poor quality data (more than 25% missing).

Shared under [Creative Common 3.0 licence](http://creativecommons.org/licenses/by/3.0/)

The event was organised by [DataKind](http://datakind.org/)

###Instruction

* change the program parameters in the first section of the code
* run the program either in RStudio by pressing Shift-Ctrl-Enter or type in `source('<path>/crop_analysis.R', echo=FALSE)`. For example, `source('~/Google Drive/Hackathons/DataKind July 2013/crop_analysis.R', echo=FALSE)`

###Files

* crop_analysis.R - this is the code which perform the analysis
* country-food.csv - raw data from FAO regarding food prices for different markets
* sample-output - example images that the code generates for white maize

###For those that are curious - four key lines in the code

The majority of the code is actually around looping different crops and country market pair as well as guarding the code against non-Latin inputs which crashes R. That said, the most important lines are probably these four below:
```R
1. dataxts <- xts(temp$Value.USD, temp$Date)
```
`xts` is a custom package which can load time series as a collection of discreet time series points instead of the built in `ts` which required equally spaced points in a time series. In addition, it allows us to use th following command: 
```R
2. dataxts_withoutna<-na.approx(dataxts)
```
`na.approx` allows us to fill in some of the gaps in data which is inevitable in data related to the physical world. It would be a real shame to abandon a time series of couple of hundred data points just because three is missing. There are a number of option for approximation, we have leveraged the most simple one - linear approximation - other methods are available.

A word of caution though, in our code we have specified that the time series cannot have more than 25% of blank data. This safeguards our analysis from being turned into an analysis of linear approximation. This tolerance level should be fine-tuned in future versions.

```R
3. datats <- ts(dataxts_withoutna, start=c(year, month), frequency=12)
```
This turns the `xts` into a run of the mill `ts` in R. We set the frequency to 12 as our data is monthly data and there are of course 12 months to the year! By turning `xts` into `ts`, it means we can use the following:
```R
4. datats_dec <- decompose(datats)
```
This decompose the data into three components and we can access the raw analytical output by calling the components in (). The three components are:
+ The long term trend (`datats_dec$trend`)
+ The seasonal trend (`datats_dec$seasonal`)
+ The noise (`datats_dec$random`)

As it stands the code is performing an additive analysis by analysing moving averages. The analysis can easily be switched to multiplication by specifying the parameter `type =  "multiplicative"` in the `decompose` command.

###Acknowledgement

The author would like to thank Z Zhu for highlighting the decomposition capability of R and Derek for providing us with workable data from the FAO
