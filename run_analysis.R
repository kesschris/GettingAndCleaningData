## Load R packages used in creating the tidy dataset.
packages <- c("data.table", "reshape2")
sapply(packages, require, character.only = TRUE, quietly = TRUE)

## Set working directory to the R working directory and store the path with /Dataset appended. 
## Used to conditionally create the Dataset dir. Also, helps increase 
##code readability.
path <- paste(getwd(),"/Dataset", sep="")
path

## Set the URL and File name. The 'If' statement only creates the directory if one
## does not already exist with that name, then downloads the dataset to the directory.
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
f <- "Dataset.zip"
if (!file.exists(path)) {
      dir.create(path)
}
download.file(url, file.path(path, f))

## Unzip the file.
setwd(path)
unzip(f)
dataPath <- file.path(path,"UCI HAR Dataset")
dataPath

## Read the specified files into R. First up are the Subject files.
dtTrain <- fread(file.path(dataPath, "train", "subject_train.txt"))
dtTest <- fread(file.path(dataPath, "test", "subject_test.txt")) 
dtSubComp <- rbind(dtTrain, dtTest) 

##Next up are the Y files (activities).
dtYTrain <- fread(file.path(dataPath, "train", "y_train.txt"))
dtYTest <- fread(file.path(dataPath, "test", "y_test.txt"))
dtActComp <- rbind(dtYTrain, dtYTest)

## Finally, the X files - pun not intended. Due to a column name having a
## space, I'm using read.file here instead. Chose this route over ignoring
## the column in the spirit of true reproduceability in case this column
## is needed. 
dtXTrain <- read.table(file.path(dataPath, "train", "X_train.txt"))
dtXTest <- read.table(file.path(dataPath, "test", "X_test.txt"))
dtXComp <- rbind(dtXTrain, dtXTest) 

## Set column names for Suject and Activity files
setnames(dtSubComp, "V1", "subject")
setnames(dtActComp, "V1", "activityNum")


## Get the mean and standard deviation
dtFeatures <- fread(file.path(dataPath, "features.txt")) 
setnames(dtFeatures, names(dtFeatures), c("featureNum", "featureName"))
dtFeatures <- dtFeatures[grepl("mean\\(\\)|std\\(\\)", featureName)]
dtFeatures$featureCode <- dtFeatures[, paste0("V", featureNum)]
## head(dtFeatures) ## Test only

## Combine the Subject and Activity datda, then join in the all the measurments.
dtSubComp <- cbind(dtSubComp, dtActComp)
CompDat <- cbind(dtSubComp, dtXComp)

## Read in the Activity names.
dtActNames <- fread(file.path(dataPath, "activity_labels.txt"))
setnames(dtActNames, names(dtActNames), c("activityNum", "activityName"))
CompDat <-  merge(CompDat, dtActNames, by = "activityNum", all.x = TRUE)
head(CompDat) ## Test only

## Replace the "v code" column name with the actual feature name
setkey(CompDat, subject, activityNum, activityName)
select <- c(key(CompDat), dtFeatures$featureCode)
CompDat <- CompDat[, select, with = FALSE]
ColNames <- c("subject","activityNum","activityName",dtFeatures$featureName)
setnames(CompDat, CompDat[,dtFeatures$featureCode], dtFeatures$featureName)
write.table(CompDat, "Clean_Data.txt")


## Make a tidy data set
TidyData <- CompDat[, list(count = .N, average = mean(value)), by = key(CompDat)]
 
