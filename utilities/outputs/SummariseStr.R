SummariseStr <- function(sampleshare=0.5, pnrparkingcost=2.0, logrun=FALSE, catvarslist=c("orig_taz", "dest_taz", "home_taz", "trip_mode", "incQ", "timeCodeNum", "ptype"), sumvarslist=c("num_participants", "walktime", "wait", "IVT", "transfers", "bau_fare", "fare", "othercost", "distance", "dFree", "dInterCity", "dLocal", "dRegional", "ddist", "dFareMat")) {

  
  library(tidyverse)
  library(openxlsx)
  library(crayon)
  
  # Example of use
  # SummariseStr(sampleshare=0.5, pnrparkingcost=2.0, logrun=TRUE, catvarslist = c("trip_mode"), sumvarslist=c("num_participants", "walktime", "wait", "IVT", "transfers", "fare", "othercost", "distance"))
  
  
  # The default value of pnrparking cost is USD 2.0 (2000 prices).  BART parking costs approximately USD 3 is 2021.  
  # $3 adjusted for inflation 2020 - 2000 gives approximately $2 in 2000 prices.  
  # Source for inflation data: https://www.bls.gov/data/inflation_calculator.htm
  

  dropr <- function(mydf,...) {
    
    my_return_name <- deparse(substitute(mydf))
    
    myinitialsize <- round(object.size(mydf)/1000000, digits = 3)
    cat(paste0("Size of ", my_return_name, " before removing variables: ", myinitialsize, " MB. \n"))
    
    names_to_drop <- c(...)
    mytext <- paste("The following variables will be dropped from ", my_return_name, ": ", sep = "")
    print(mytext)
    print(names_to_drop)
    mydf <- mydf[,!names(mydf) %in% names_to_drop]
    
    myfinalsize <- round(object.size(mydf)/1000000, digits = 3)
    cat(paste0("Size of ", my_return_name, " after removing variables: ", myfinalsize, " MB. \n"))
    ramsaved <- round(myinitialsize - myfinalsize, digits = 3)
    cat(paste0("RAM saved: ", ramsaved, " MB. \n"))
    
    return(mydf)
    
  }	
  
  keepr <- function(mydf,...) {
    
    my_return_name <- deparse(substitute(mydf))
    
    myinitialsize <- round(object.size(mydf)/1000000, digits = 3)
    cat(paste0("Size of ", my_return_name, " before removing variables: ", myinitialsize, " MB. \n"))
    
    names_to_keep <- c(...)
    mytext <- paste("The following variables will be kept from ", my_return_name, ": ", sep = "")
    print(mytext)
    print(names_to_keep)
    mydf <- mydf[,names(mydf) %in% names_to_keep]
    
    myfinalsize <- round(object.size(mydf)/1000000, digits = 3)
    cat(paste0("Size of ", my_return_name, " after removing variables: ", myfinalsize, " MB. \n"))
    ramsaved <- round(myinitialsize - myfinalsize, digits = 3)
    cat(paste0("RAM saved: ", ramsaved, " MB. \n"))
    
    return(mydf)
    
  }
  
  StrLabeller <- function(mydf, ...) {
    
    # examples
    # mydf <- StrLabeller(mydf = mydf, myvar = "trip_mode")    
    
    vars_to_label <- c(...)
    
    for (myvar in vars_to_label) {
      
      myvarname <- substitute(myvar)
      
      if (myvarname=="trip_mode") {
        
        mydf$trip_mode <- factor(mydf$trip_mode, levels = c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21), labels = c("Drive alone (single-occupant vehicles), not eligible to use value toll facilities","Drive alone (single-occupant), eligible to use value toll facilities","Shared ride 2 (two-occupant vehicles), not eligible to use value toll facilities","Shared ride 2 (two-occupant vehicles), eligible to use value toll facilities","Shared ride 3+ (three-or-more-occupant vehicles), not eligible to use value toll facilities","Shared ride 3+ (three-of-more occupant vehicles), eligible to use value toll facilities","Walk the entire way (no transit, no bicycle)","Bicycle the entire way (no transit)","Walk to local bus","Walk to light rail or ferry","Walk to express bus","Walk to heavy rail","Walk to commuter rail","Drive to local bus","Drive to light rail or ferry","Drive to express bus","Drive to heavy rail","Drive to commuter rail","Taxi (added in Travel Model 1.5)","TNC (Transportation Network Company, or ride-hailing services) - Single party (added in Travel Model 1.5)","TNC - Shared e.g. sharing with strangers (added in Travel Model 1.5)"))
        
      }
      
      if (myvarname=="incQ") {
        
        mydf$incQ <- factor(mydf$incQ, levels = c(1,2,3,4), labels = c("Less than $30k", "$30k to $60k", "$60k to $100k", "More than $100k"))
        
      }
      
      if (myvarname=="timeCodeNum") {
        
        mydf$timeCodeNum <- factor(mydf$timeCodeNum, levels = c(1,2,3,4,5), labels = c("Early AM", "AM Peak", "Midday", "PM Peak", "Evening"))
        
      }

      if (myvarname=="ptype") {
        
        mydf$ptype <- factor(mydf$ptype, levels = c(1,2,3,4,5,6,7,8), labels = c("Full-time worker", "Part-time worker", "College student", "Non-working adult", "Retired", "Driving-age student", "Non-driving-age student", "Child too young for school"))
        
      }
      
      if (myvarname=="orig_county") {
        
        mydf$orig_county <- factor(mydf$orig_county, levels = c(1,2,3,4,5,6,7,8,9), labels = c("San Francisco", "San Mateo", "Santa Clara", "Alameda", "Contra Costa", "Solano", "Napa", "Sonoma", "Marin"))
        
      }
      
      if (myvarname=="dest_county") {
        
        mydf$dest_county <- factor(mydf$dest_county, levels = c(1,2,3,4,5,6,7,8,9), labels = c("San Francisco", "San Mateo", "Santa Clara", "Alameda", "Contra Costa", "Solano", "Napa", "Sonoma", "Marin"))
        
      }      
      
      
      
    }
    
    return(mydf)
    
  }
  
  # Work --------------------------------------------------------------------
  
  mywd <- getwd()
  
  # For RStudio, these can be set in the .Rprofile
  TARGET_DIR   <- mywd  		# The location of the input files
  SAMPLESHARE  <- sampleshare # Sampling
  
  TARGET_DIR   <- gsub("\\\\","/",TARGET_DIR) # switch slashes around
  
  stopifnot(nchar(TARGET_DIR  )>0)
  stopifnot(nchar(SAMPLESHARE )>0)
  
  MAIN_DIR    <- file.path(TARGET_DIR,"main"          )
  RESULTS_DIR <- file.path(TARGET_DIR,"core_summaries")
  UPDATED_DIR <- file.path(TARGET_DIR,"updated_output")
  
  
  # trips, revenue, and average fare by mode
  
  trips <- readRDS(file=file.path(UPDATED_DIR, "trips.rds"))
  
  # Join on geographical categories
  tazData <- read.table(file=file.path(TARGET_DIR,"landuse","tazData.csv"), header=TRUE, sep=",")
  tazData <- tazData %>% select(ZONE, DISTRICT, SD, COUNTY)
  orig_taz_data <- tazData %>% rename(orig_taz = ZONE, orig_district = DISTRICT, orig_sd = SD, orig_county = COUNTY)
  dest_taz_data <- tazData %>% rename(dest_taz = ZONE, dest_district = DISTRICT, dest_sd = SD, dest_county = COUNTY)
  trips <- trips %>% left_join(orig_taz_data)
  trips <- trips %>% left_join(dest_taz_data)
  rm(orig_taz_data, dest_taz_data, tazData)
  
  # report the available variables
  cat(yellow(paste0("The following variables are available: \n \n")))  
  print(names(trips))
  cat((paste0("\n \n")))  
  
  # define list of variables
  # trip_mode must be kept
  essentialvarslist <- c("trip_mode")
  myvarlist <- c(catvarslist, sumvarslist, essentialvarslist)
  
  # reduce the data in memory to the required variables
  # mydf <- keepr(mydf = trips, "num_participants", "walktime", "wait", "IVT", "transfers", "fare", "othercost", "distance")
  mydf <- keepr(mydf = trips, myvarlist)
  
  remove(trips)
  
  print(gc())
  
  # Set to zero distance variables that should be zero for modes with no transit stages
  
  for (myvarname in c("dLocal", "dRegional", "dFree", "dInterCity", "ddist", "dFareMat")) {
  
    if (myvarname %in% names(mydf)) {
      
      myvar <- rlang::sym(paste0(myvarname))
      
      # Assign value
      mydf <- mydf %>%
        mutate(!!myvar := ifelse(trip_mode<=8, 0.0,!!myvar))
      
    }
    
  }
  
  
  # convert monetary variables from cents to dollars
  
  mydf <- mydf %>%
    mutate(fare=fare/100) %>% 
	mutate(bau_fare=bau_fare/100) %>%
    mutate(othercost=othercost/100)
  
  # calculate the numbers of trips taking into account the sample share
  
  mydf <- mydf %>% 
    mutate(trips=num_participants/sampleshare)
  
  # should also add assumed cost per unit distance of auto access for PNR options, but the data to do it is not available at present.  
  # Auto operating cost per mile, from ModeChoice.xls
  costPerMile <- 18.29
  mydf <- mydf %>% 
	mutate(pnr_operatingcost = ifelse(trip_mode>=14 & trip_mode<=18,costPerMile*ddist/100,0))

  
  # divide pnr parking cot by 2 to get it per direction for comparability with transit fares
  pnrparkingcostperdirection <- pnrparkingcost/2
  
  # add assumed PNR parking cost to other costs
  mydf <- mydf %>% 
    mutate(othercost=ifelse(trip_mode>=14 & trip_mode<=18, othercost + pnrparkingcostperdirection + pnr_operatingcost, othercost))
  
  # adjust other costs to be per person for consistency with transit costs
  mydf <- mydf %>% 
    mutate(othercost=othercost/num_participants)
  
  # weight the variables to be summarised by trips so that they can be aggregated
  
  mydf <- mydf %>% 
    mutate(across(all_of(sumvarslist), ~ .x*trips))

  # aggregate  
  
  mysumvarslist <- c(c("trips"), sumvarslist)
  
  mydf <- mydf %>% 
    group_by(across(all_of(catvarslist))) %>%
    summarise(across(all_of(mysumvarslist), sum)) %>%
    ungroup()
  
  # average
  
  mydf <- mydf %>%
    mutate(across(all_of(sumvarslist),  ~ .x/trips))
  
  # calculate revenue
  
  mydf <- mydf %>%
    mutate(revenue = trips*fare)
  
  # tidy up - put the columns in the desired order
  
  mysumvarslist <- c(c("trips", "revenue"), sumvarslist)
  
  myvarslist <- c(catvarslist, mysumvarslist)
  
  mydf <- mydf %>%
    select(all_of(myvarslist))
  
  # apply labels to the category variables
  
  for(myvar in catvarslist) {
  
    mydf <- StrLabeller(mydf, myvar)
  
  }

  return(mydf)

}






