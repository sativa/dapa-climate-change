#Julian Ramirez-Villegas
#May 2012
#UoL / CCAFS / CIAT

#Get CMIP5 weather data

#src.dir <- "D:/_tools/dapa-climate-change/trunk/PhD/0006-weather-data/scripts"
src.dir <- "~/PhD-work/_tools/dapa-climate-change/trunk/PhD/0006-weather-data/scripts"
source(paste(src.dir,"/GHCND-GSOD-functions.R",sep=""))

#bDir <- "F:/PhD-work/data-quality-study"
bDir <- "~/PhD-work/data-quality-study"
compDir <- paste(bDir,"/climate-comparison",sep="")
oDir <- paste(compDir,"/experiments",sep="")
if (!file.exists(oDir)) {dir.create(oDir)}

#shuffled experiments
#read in the rainfall, calculate monthly total rainfall, number of rain days
#shDir <- paste(bDir,"/DSSAT-PNUT/GJ-weather/shuf-pert",sep="")
shDir <- "/dev/shm"


##################################################
### shuffled experiments#########################
##################################################
dataDir <- paste(bDir,"/data/shuffled",sep="")
trList <- list.files(dataDir,pattern="\\.7z")

#loop the different trials
for (trial in trList) {
  cat("\nprocessing",trial,"\n")
  trialm <- gsub("\\.7z","",trial)
  vn <- strsplit(trialm,"_",fixed=T)[[1]][2] #"prec"
  sc <- strsplit(trialm,"_",fixed=T)[[1]][3] #"all"
  
  outxDir <- paste(oDir,"/s_",vn,"_",sc,sep="")
  if (!file.exists(outxDir)) {dir.create(outxDir)}
  
  if (!file.exists(paste(outxDir,"/climate_s_",vn,"_",sc,".csv",sep=""))) {
    #copy and decompress
    x <- file.copy(paste(dataDir,"/",trial,sep=""),shDir)
    setwd(shDir)
    system(paste("7z x",trial))
    
    cdDir <- paste(shDir,"/s_",vn,"_",sc,sep="")
    expList <- list.files(cdDir,pattern="s-")
    
    #loop through experiments
    for (xp in expList) {
      cat("categorising experiment",xp,"which is",which(expList==xp),"\n")
      
      #xp <- expList[1]
      wthDir <- paste(cdDir,"/",xp,"/WTH",sep="")
      
      #loop through years now
      for (yr in 1966:1989) {
        yrs <- substr(yr,3,4)
        wFile <- paste(wthDir,"/INGJ",yrs,"01.WTH",sep="")
        wData <- read.fortran(wFile,format=c("A5","4F6"),skip=5)
        names(wData) <- c("DATE","SRAD","TMAX","TMIN","RAIN")
        
        if (vn == "prec") {
          fn <- "RAIN"
        } else if (vn == "tmin") {
          fn <- "TMIN"
        } else if (vn == "tmax") {
          fn <- "TMAX"
        }
        
        dg <- createDateGrid(yr)
        dg$MTH <- substr(dg$MTH.DAY,2,3)
        dg$DAY <- substr(dg$MTH.DAY,5,6)
        dg$VALUE <- wData[,fn]
        
        if (vn == "prec") {
          rtjun <- sum(dg$VALUE[which(dg$MTH=="06")]);
          rdjun <- length(which(dg$VALUE[which(dg$MTH=="06")] > 0))
          rtjul <- sum(dg$VALUE[which(dg$MTH=="07")])
          rdjul <- length(which(dg$VALUE[which(dg$MTH=="07")] > 0))
          rtaug <- sum(dg$VALUE[which(dg$MTH=="08")])
          rdaug <- length(which(dg$VALUE[which(dg$MTH=="08")] > 0))
          rtsep <- sum(dg$VALUE[which(dg$MTH=="09")])
          rdsep <- length(which(dg$VALUE[which(dg$MTH=="09")] > 0))
          
          out_row <- data.frame(YEAR=yr,EXP=xp,VN=vn,SC=sc,RT6=rtjun,RD6=rdjun,RT7=rtjul,RD7=rdjul,
                                RT8=rtaug,RD8=rdaug,RT9=rtsep,RD9=rdsep)
        } else {
          mtjun <- mean(dg$VALUE[which(dg$MTH=="06")]);
          mtjul <- mean(dg$VALUE[which(dg$MTH=="07")])
          mtaug <- mean(dg$VALUE[which(dg$MTH=="08")])
          mtsep <- mean(dg$VALUE[which(dg$MTH=="09")])
          
          out_row <- data.frame(YEAR=yr,EXP=xp,VN=vn,SC=sc,MT6=mtjun,MT7=mtjul,MT8=mtaug,MT9=mtsep)
        }
        
        if (yr == 1966) {
          out_all <- out_row
        } else {
          out_all <- rbind(out_all,out_row)
        }
      }
      
      if (xp == expList[1]) {
        xp_all <- out_all
      } else {
        xp_all <- rbind(out_all,xp_all)
      }
    }
    
    write.csv(xp_all,paste(outxDir,"/climate_s_",vn,"_",sc,".csv",sep=""),row.names=F,quote=F)
    
    system(paste("rm -rf",trialm))
    system(paste("rm -rf",trial))
    setwd(bDir)
  }
}


##################################################
### perturbed experiments#########################
##################################################
dataDir <- paste(bDir,"/data/perturbed",sep="")
trList <- list.files(dataDir,pattern="\\.7z")

oDir <- paste(compDir,"/experiments",sep="")
if (!file.exists(oDir)) {dir.create(oDir)}

#loop the different p values
#for (trial in trList) {
doTrial <- function(trial) {
  cat("\nprocessing",trial,"\n")
  trialm <- gsub("\\.7z","",trial)
  vn <- strsplit(trialm,"_",fixed=T)[[1]][2] #"prec"
  sc <- strsplit(trialm,"_",fixed=T)[[1]][3] #"all"
  
  outxDir <- paste(oDir,"/p_",vn,"_",sc,sep="")
  if (!file.exists(outxDir)) {dir.create(outxDir)}
  
  if (!file.exists(paste(outxDir,"/climate_p_",vn,"_",sc,"_all.csv",sep=""))) {
    #copy 7z file
    x <- file.copy(paste(dataDir,"/",trial,sep=""),shDir)
    
    #loop through values of p
    for (p in 0:299) {
      cat("categorising for value of p =",p,"\n")
      
      if (!file.exists(paste(outxDir,"/climate_p_",vn,"_",sc,"_",p,".csv",sep=""))) {
        #decompress  7z x p_prec_climate.7z -ir!"p-299*"
        setwd(shDir)
        system(paste('7z x ',trial,' -ir!"p-',p,'*"',sep=''))
        cdDir <- paste(shDir,"/p_",vn,"_",sc,sep="")
        
        #listing experiments
        expList <- list.files(cdDir,pattern=paste("p-",p,"_",sep=""))
        
        #loop through experiments
        for (xp in expList) {
          cat("categorising experiment",xp,"which is",which(expList==xp),"\n")
          
          #xp <- expList[1]
          wthDir <- paste(cdDir,"/",xp,"/WTH",sep="")
          
          #loop through years now
          for (yr in 1966:1989) {
            yrs <- substr(yr,3,4)
            wFile <- paste(wthDir,"/INGJ",yrs,"01.WTH",sep="")
            wData <- read.fortran(wFile,format=c("A5","4F6"),skip=5)
            names(wData) <- c("DATE","SRAD","TMAX","TMIN","RAIN")
            
            if (vn == "prec") {
              fn <- "RAIN"
            } else if (vn == "tmin") {
              fn <- "TMIN"
            } else if (vn == "tmax") {
              fn <- "TMAX"
            }
            
            dg <- createDateGrid(yr)
            dg$MTH <- substr(dg$MTH.DAY,2,3)
            dg$DAY <- substr(dg$MTH.DAY,5,6)
            dg$VALUE <- wData[,fn]
            
            if (vn == "prec") {
              rtjun <- sum(dg$VALUE[which(dg$MTH=="06")]);
              rdjun <- length(which(dg$VALUE[which(dg$MTH=="06")] > 0))
              rtjul <- sum(dg$VALUE[which(dg$MTH=="07")])
              rdjul <- length(which(dg$VALUE[which(dg$MTH=="07")] > 0))
              rtaug <- sum(dg$VALUE[which(dg$MTH=="08")])
              rdaug <- length(which(dg$VALUE[which(dg$MTH=="08")] > 0))
              rtsep <- sum(dg$VALUE[which(dg$MTH=="09")])
              rdsep <- length(which(dg$VALUE[which(dg$MTH=="09")] > 0))
              
              out_row <- data.frame(YEAR=yr,EXP=xp,VN=vn,SC=sc,RT6=rtjun,RD6=rdjun,RT7=rtjul,RD7=rdjul,
                                    RT8=rtaug,RD8=rdaug,RT9=rtsep,RD9=rdsep)
            } else {
              mtjun <- mean(dg$VALUE[which(dg$MTH=="06")]);
              mtjul <- mean(dg$VALUE[which(dg$MTH=="07")])
              mtaug <- mean(dg$VALUE[which(dg$MTH=="08")])
              mtsep <- mean(dg$VALUE[which(dg$MTH=="09")])
              
              out_row <- data.frame(YEAR=yr,EXP=xp,VN=vn,SC=sc,MT6=mtjun,MT7=mtjul,MT8=mtaug,MT9=mtsep)
            }
            
            if (yr == 1966) {
              out_all <- out_row
            } else {
              out_all <- rbind(out_all,out_row)
            }
          }
          
          if (xp == expList[1]) {
            xp_all <- out_all
          } else {
            xp_all <- rbind(out_all,xp_all)
          }
        }
        write.csv(xp_all,paste(outxDir,"/climate_p_",vn,"_",sc,"_",p,".csv",sep=""),row.names=F,quote=F)
        system(paste("rm -rf",trialm))
      } else {
        xp_all <- read.csv(paste(outxDir,"/climate_p_",vn,"_",sc,"_",p,".csv",sep=""))
      }
      
      if (p == 0) {
        out_ps <- xp_all
      } else {
        out_ps <- rbind(xp_all,out_ps)
      }
      
    }
    
    write.csv(out_ps,paste(outxDir,"/climate_p_",vn,"_",sc,"_all.csv",sep=""),row.names=F,quote=F)
    
    system(paste("rm -rf",trial))
    setwd(bDir)
  }
}


