# This file does the following:
# reads DR event dates
# reads kwh data for all DR events
# calculates total curtailment for each DR event
# (uses SCE baseline)

library(zoo)

# DR event parameters
beginDR = 54 # 1:15 PM
endDR = 69 # 5:00 PM
  
# set FTP data
username = ""
pswd = ""
url = paste("ftp://",username,":",pswd,
            "@fmsdevwin.usc.edu/Files/Electrical_Dashboard/",
            sep="")

# read building codes
setwd("/Users/saima/Desktop/Energy Experiments/gcode/reducedKWH/")
bcodes = read.csv("buildingCodes.csv",header=TRUE)

# read event data 
data12 = read.csv("DRevents2012.csv")
data13 = read.csv("DRevents2013.csv")
data14 = read.csv("DRevents2014.csv")
DRdata = rbind(data12,data13,data14)
eventDays = unique(DRdata$Date)
numDays = length(eventDays)

#-------------------------
# do for each DR event day
missing = NULL # DR days skipped
curtAll = NULL
eventsAll = NULL

dateArray = NULL
buildingArray = NULL
curtArray = NULL
BLconsumptionArray = NULL

# do for each event day
for(i in 1:numDays){    
#for(i in 1:4){     
  cat("*****day", i,"of", numDays,"-", as.character(eventDays[i]),"\n")
  dataSlice = subset(DRdata, Date==eventDays[i])
  eventDate = as.Date(dataSlice$Date[1],"%m/%d/%Y")
  
  # 1. read observed data from FTP for the event day
  ipFile = paste(url,"export-",eventDate,".csv",sep="")
  myDataObs = read.csv(ipFile,header=TRUE,sep=",",as.is=TRUE)
  
  # 2. read baseline data from files for the event day
  ipFile = paste("edison/",eventDate,".csv",sep="")
  if(file.exists(ipFile)){
    #readData = try(read.csv(ipFile))
    myDataBL = read.csv(ipFile,header=TRUE,sep=",",as.is=TRUE)
  }else{
    next
  }
  
  # do for individual buildings on the DR day
  totalCurtailment = 0
  numMissed = 0
  cat("buildings ")
  numBuildingsSelected = dim(dataSlice)[1]
  for (j in 1:dim(dataSlice)[1]){
    bldng = as.character(dataSlice$Building[j])
    strategy = as.character(dataSlice$Strategy[j])
    key = bcodes$Building.Key[which(bcodes$Building.Code == bldng)]
    kwhIndices = which(myDataObs$szCity == key)
    
    cat(",", bldng)
    
    # check data for missing values
    if (length(kwhIndices) < 90){     # when kwh data is missing
      missed = c(bldng,as.character(eventDate),strategy)
      missing = rbind(missing,missed) # save missed data info
      numMissed = numMissed + 1
      numBuildingsSelected = numBuildingsSelected - 1
      cat("-skipped,")
      next   # skip for this building; move to next             
    } 
    kwh = myDataObs$Total[kwhIndices]
    # interpolate for missing data
    kwh = na.fill(kwh, "extend")  
    # extract kwh during DR
    kwhDR = kwh[beginDR:endDR]
    # find BL
    kwhBL = subset(myDataBL,buildings == bldng)
    kwhBL = kwhBL[2:17]
    
    # calculate curtailment
    curtArray = rbind(curtArray,c(kwhBL - kwhDR))
    BLconsumptionArray = rbind(BLconsumptionArray,rep(kwhBL,16))
    curtailment = sum(kwhBL - kwhDR)
    totalCurtailment = totalCurtailment + curtailment
    
    # also save building name and date
    buildingArray = c(buildingArray, bldng)
    dateArray = c(dateArray, eventDate)
  } # done for each building
  
  cat("\n Total curtailment = ", totalCurtailment, "\n")
  if(numMissed == dim(dataSlice)[1]){
    next    
  }
  # save this events data
  curtAll = rbind(curtAll,totalCurtailment)
  eventsAll = rbind(eventsAll,as.character(eventDate))
  
} # done for each DR event day
#---------------

# frame 
myDFi = data.frame(buildingArray,as.Date(dateArray))
write.csv(myDFi,"file1-SCE.csv",row.names=FALSE)

# save individual buildings' curtailment
write.csv(curtArray,"file2-SCE.csv",row.names=FALSE)
# save individual buildings' baseline consumption
write.csv(BLconsumptionArray,"file3-SCE.csv",row.names=FALSE)

f1 = read.csv("file1-SCE.csv")
f2 = read.csv("file2-SCE.csv")
f3 = read.csv("file3-SCE.csv")

myDFx = data.frame(f1,f2)
write.csv(myDFx,"curtailment-SCE-intervalwise.csv",row.names=FALSE)

myDFx = data.frame(f1,f3)
write.csv(myDFx,"BLconsumption-SCE-intervalwise.csv",row.names=FALSE)

# frame and save curtailment summary
myDF = data.frame(date = eventsAll,
                  curtailment = curtAll)
write.csv(myDF,"curtailment-SCE.csv")

#missing files
write.csv(missing,"missingDRdata-SCE.csv",row.names=FALSE)
