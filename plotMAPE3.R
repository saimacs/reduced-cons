# box n whisker plots - semester & dow

library(ggplot2)
library(reshape2)
library(plyr)
library(lubridate)

newBD = c("B1","B2","B3","B4","B5","B6","B7","B8","B9","B10",
          "B11","B12","B13","B14","B15","B16","B17","B18","B19","B20",
          "B21","B22","B23","B24","B25","B26","B27","B28","B29","B30",
          "B31","B32","B33")

# define season limits
summerStart12 = as.POSIXct("2012-05-16"); # May 16
summerEnd12 = as.POSIXct("2012-09-1"); # Sep 1

summerStart13 = as.POSIXct("2013-05-16"); # May 16
summerEnd13 = as.POSIXct("2013-09-1"); # Sep 1

summerStart14 = as.POSIXct("2014-05-16"); # May 16
summerEnd14 = as.POSIXct("2014-09-1"); # Sep 1

# read obs and pred values
setwd("~/Desktop/curtailment/Obs/test/")
fList = list.files(pattern = paste("*.csv"))
fList = fList [-c(16,24,25,26)]
numFiles = length(fList)

seasonList = NULL
dateList = NULL
dowList = NULL
bdList = NULL
mapeHM = NULL
mapeEns = NULL
for (j in 1:numFiles){
  bd = substr(fList[j],1,3)
    
  # read observed values
  setwd("~/Desktop/curtailment/Obs/test/")
  obs = read.csv(fList[j])  
  DRdates = obs$date
  DRdow = weekdays(as.Date(DRdates))
  DRyear = year(DRdates)
  DRdates = as.POSIXct(DRdates)
  for(k in 1:length(DRyear)){
    if(DRyear[k] == 2012){
      if(DRdates[k] < summerStart12){
        season = "Spring"
      }else if(DRdates[k] < summerEnd12){
        season = "Summer"
      }else{
        season = "Fall"
      }
    }
    if(DRyear[k] == 2013){
      if(DRdates[k] < summerStart13){
        season = "Spring"
      }else if(DRdates[k] < summerEnd13){
        season = "Summer"
      }else{
        season = "Fall"
      }
    }
    if(DRyear[k] == 2014){
      if(DRdates[k] < summerStart14){
        season = "Spring"
      }else if(DRdates[k] < summerEnd14){
        season = "Summer"
      }else{
        season = "Fall"
      }
    }
    seasonList = c(seasonList,season)
  }
  obs = obs[,2:17]
  
  # read predicted values HM
  setwd("~/Desktop/curtailment/Predictions/histmean-test/")
  predHM = read.csv(paste(bd,"-preds.csv",sep=""))
  predHM = predHM[,2:17]
  errorsHM = abs(obs-predHM)/obs
  errorsHM = apply(errorsHM, 1, mean)
  mapeHM = c(mapeHM,errorsHM)
  
  # read predicted values Ens
  setwd("~/Desktop/curtailment/Predictions/ensrf-test/")
  predEns = read.csv(paste(bd,"-preds.csv",sep=""))
  predEns = predEns[,2:17]
  errorsEns = abs(obs-predEns)/obs
  errorsEns = apply(errorsEns, 1, mean)
  mapeEns = c(mapeEns,errorsEns)
  
  bdList = c(bdList, rep(newBD[j],length(errorsHM)))
  dateList = c(dateList,DRdates)
  dowList = c(dowList,DRdow)
  cat(bd, ":", length(errorsHM), ",", length(errorsEns), "\n")
}

#------------------------------
# frame the data
df = data.frame(building = bdList,
                dowList = dowList,
                dateList = dateList,
                seasonList = seasonList,
                IDS = mapeHM,
                Ensemble = mapeEns)
df$building = factor(df$building, levels = df$building)
df1 = melt(df, id=c("building","dowList","dateList", "seasonList"))

#------------------------------
# 1. paired boxplots

g1 = ggplot(df1) + theme_bw() +
  geom_boxplot(aes(x=building, y=value,fill=variable)) + 
  theme(axis.text.x = element_text(angle=90, vjust=1)) + 
  theme(legend.position = "top")

g2 = g1 + xlab("Building") + ylab("MAPE") +
      theme(legend.title = element_blank()) + 
      theme(legend.text = element_text(size = 16)) +
      theme(axis.title = element_text(size=14)) +
      theme(axis.text = element_text(size=14))
g2

#------------------------------
#2. DoW boxplots

df1$dowList_f= factor(df1$dowList, levels = 
                c('Monday','Tuesday','Wednesday','Thursday','Friday'))
  
g1 = ggplot(df1) +
  geom_boxplot(aes(x=variable, y=value,color=variable)) +
  facet_grid(. ~ dowList_f) + 
  theme(legend.position = "top")

g2 = g1 + xlab("Model") + ylab("MAPE") +
  theme(legend.title = element_blank()) + 
  theme(legend.text = element_text(size = 16)) +
  theme(axis.title = element_text(size=14)) +
  theme(axis.text.x = element_blank())
g2

#------------------------------
#3. Semester boxplots

df1$seasonList_f= factor(df1$seasonList, levels = 
                        c('Spring','Summer','Fall'))

g1 = ggplot(df1) +
  geom_boxplot(aes(x=variable, y=value,color=variable)) +
  facet_grid(. ~ seasonList_f) + 
  theme(legend.position = "top")

g2 = g1 + xlab("Model") + ylab("MAPE") +
  theme(legend.title = element_blank()) + 
  theme(legend.text = element_text(size = 16)) +
  theme(axis.title = element_text(size=14)) +
  theme(axis.text.x = element_blank())
g2

