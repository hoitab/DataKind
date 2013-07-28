Crop price analysis
===================

Crop prices analysis using R.

Analysed food pricing data from UN Food and Agriculture Organization (FAO). This resulted in over 700+ crop-markets pairs. This R code separate it into three components - long term trend, seasonality and noise. 

Some pairs are ignored due to insufficient data (less than 2 years) or poor quality data (more than 25% missing).

Shared under Creative Common 3.0 licence
More details can be found here: http://creativecommons.org/licenses/by/3.0/

Instruction
-----------

* change the program parameters in the first section of the code
* run the program either in RStudio by pressing Shift-Ctrl-Enter or type in
```
source('<path>/crop_analysis.R', echo=FALSE)
```

for example
```
source('~/Google Drive/Hackathons/DataKind July 2013/crop_analysis.R', echo=FALSE)
```

Files
-----

* crop_analysis.R - this is the code which perform the analysis
* country-food.csv - raw data from FAO regarding food prices for different markets
* sample-output - example images that the code generates for white maize

Acknowledgement
---------------

The author would like to thank Z Zhu for highlighting the decomposition capability of R and Derek for providing us with workable data from the FAO
