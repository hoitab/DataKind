########################################################################################################################
#
# ** Title: Crop price analysis
#
# Author: Hoi Lam
# Date:   July 2013 (DataDive event by DataKind UK)
# 
# ** Abstract:
# Analysed food pricing data from UN Food and Agriculture Organization (FAO). This resulted in over 700+ crop-markets
# pairs. This R code separate it into three components - long term trend, seasonality and noise. 
# Some pairs are ignored due to insufficient data (less than 2 years) or poor quality data (more than 25% missing).
#
# ** Shared under Creative Common 3.0 licence
# More details can be found here: http://creativecommons.org/licenses/by/3.0/
#
# ** Acknowledgement
# The author would like to thank Z Zhu for highlighting the decomposition capability of R and Derek for providing us 
# with workable data from the FAO
#
########################################################################################################################

# Sample output can be found here: https://drive.google.com/folderview?id=0B4Ya6p-H04dqU2YySmZSMl9jWGs&usp=sharing#grid

# Instruction: 
#    - change the program parameters in the first section of the code
#    - run the program either in RStudio by pressing Shift-Ctrl-Enter or type in
#             source('<path>/crop_analysis.R', echo=FALSE)
#             e.g. source('~/Google Drive/Hackathons/DataKind July 2013/crop_analysis.R', echo=FALSE)
#

### Program parameters - please change before use

# Where is country-food located?
SOURCE_FILE = "~/Google Drive/Hackathons/DataKind July 2013/country-food.csv"

# Output target - these are set to png images at the moment due to image quality considerations.
# The name need to contain two "%s":
#    First %s will be replaced by the crop name
#    Second %s will be replaced by the country-market name e.g. "Peru-Lima"
# The directory needs to exist before the code is run
TARGET_FILENAMES = "~/Google Drive/Hackathons/DataKind July 2013/Crop analysis output/%s, %s.png"

### 

# Load data
country.food <- read.csv(SOURCE_FILE)

# Detect the number of unique commodity names
unique_crops <- unique(country.food$Commodity.full)

# Trackers - these keep track of progress
total = nrow(country.food)
n = 0                 # n: number of observation analysed
n_insufficient = 0    # n_insufficient: number of observations abandoned due to insufficient data (need more than two years worth)
n_poor_quality = 0    # n_poor_quality: number of observations abandoned due to poor quality of data (NA makes up more than 25% of data points)
n_analysed = 0        # n_analysed: number of observations we used in our analysis including the ones we approximated
n_analysed_approx = 0 # n_analysed_approx: number of observations we approximated in the n_analysed data set

# Load the xts library
library(xts)

# Loop through each crop
for (j in 1:length(unique_crops)) {
  
  crop_name <- unique_crops[j]
  
  # Filter selection to current crop
  crop_selection <- subset(country.food, Commodity.full==crop_name)
  
  # Have a look at the unique values of country and market
  crop_selection$location <- paste0(crop_selection$Country, "-", crop_selection$Market)
  # Some place names include non-ASCII characters - need to remove these before saving the file
  crop_selection$location <- iconv(crop_selection$location, "latin1", "ASCII", sub="")
  
  # Converting text dates into R dates...
  crop_selection$Date <- as.Date(as.character(crop_selection$Date),format="%d-%b-%y")
  
  # Display an overview of data from the different markets and how many data point there is in each market
  table(crop_selection$location)
  
  # Retrieve the number of unique market - i.e. country, market name combinations
  unique_location <- unique(crop_selection$location)

  # Print out size of task for the current crop
  cat(sprintf("*** Processing %s (%d out of %d), %d observations in %d markets\n", crop_name, j, length(unique_crops),
              nrow(crop_selection), length(unique_location)))
  
  # Loop through all the markets for the current crop
  for (i in 1:length(unique_location)) {
    
    # Retrieve the subset of data which contain a unique combination of crop (counter = j) and
    # country-market (country = i)
    temp <- subset(crop_selection, crop_selection$location==unique_location[i])
    
    # Create extensible time-series object, we are using this in place of the run-of-the-mill ts because
    # it allows for:
    #    1) date to be specify per data point and 
    #    2) use na.approx to approximate missing values using linear interpolation
    dataxts <- xts(temp$Value.USD, temp$Date)
    
    # update tracker
    n = n + length(dataxts)
    
    # Check for data quality to see if NA makes up more than 25% of the data - if so reject
    # This is a simple check so that linear approximation does not make up too much of the data
    if(sum(is.na(dataxts))/length(dataxts)<0.25){
      
      # Need at least two years (or 24 months) of data to decompose trend from seasonal factors
      # Otherwise flag insufficient data
      if(length(dataxts)>24){
        
        # Print progress on the current crop / market
        cat(sprintf("[%05d/%d] %s from %s, %d obs including %d N/A\n", n, total, crop_name, unique_location[i],
                    length(dataxts), sum(is.na(dataxts))))
        startdate = min(temp$Date, na.rm=TRUE)
        enddate = max(temp$Date, na.rm=TRUE)
        
        # fill in NA with linear approximation of their nearest neighbours
        dataxts_withoutna<-na.approx(dataxts)
        
        # export to a standard R time series (ts) with the frequency set to 12 - i.e. 12 months so 
        # that R can separate out the annual seasonal effects
        datats <- ts(dataxts_withoutna, start=c(as.numeric(format(startdate, "%Y")), as.numeric(format(startdate, "%m"))),
                     frequency=12)
        
        # decompose the data into three components - long term trend, seasonal effects and noise
        datats_dec <- decompose(datats)
        
        # cleaning the file name of "illegal" characters - in this case just % sign for now...
        file_crop_name <- gsub("%", " percent", crop_name)
        
        # set output file location and format - png is chosen due to quality
        png(sprintf(TARGET_FILENAMES, file_crop_name, unique_location[i]))
        
        # scale the chart heading to 75% of the original size - Otherwise it tends to get cut off
        par(cex.main=0.75)
        
        # This is used instead of plot(datats_dec) because we want to fully customised the heading
        plot(cbind(observed = datats_dec$random + datats_dec$trend + datats_dec$seasonal,
                   trend = datats_dec$trend,
                   seasonal = datats_dec$seasonal, 
                   random = datats_dec$random), main =sprintf("%s from %s \nPricing decomposed", crop_name, unique_location[i])) 
        
        # Output file
        dev.off()
        
        # update tracker - analyse
        n_analysed = n_analysed + length(dataxts)
        n_analysed_approx = n_analysed_approx + sum(is.na(dataxts))
        
      } else {
        # update tracker - insufficient data
        n_insufficient = n_insufficient + length(dataxts)
        cat(sprintf("[%05d/%d] Insufficient Data for decomposition - %s from %s, %d obs including %d N/A\n", n, total, crop_name, unique_location[i], length(dataxts), sum(is.na(dataxts))))
        
      }
    } else {
      # update tracker - poor quality
      n_poor_quality = n_poor_quality + length(dataxts)
      cat(sprintf("[%05d/%d] Poor quality data, no decomposition performed - %s from %s, %d obs including %d N/A\n", n, total, crop_name, unique_location[i], length(dataxts), sum(is.na(dataxts))))
      
    }
  }
}
cat(sprintf("\n"))
cat(sprintf("*** Summary ***\n"))
cat(sprintf("Total %s observations analysed. %s were used with %s approximated. There was:\n",
            n, n_analysed, n_analysed_approx))
cat(sprintf("   - insufficient data related to %s obs\n",
            n_insufficient))
cat(sprintf("   - poor quality data related to %s obs\n",
            n_poor_quality))