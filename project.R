# I referred to the TA's FAQ posted below, for guidance on 
# some of the ambiguous aspects of the project requirements:
# https://class.coursera.org/getdata-016/forum/thread?thread_id=50


library(data.table)
library(dplyr)
library(tidyr)

print(getwd())

# Initialize some variables
url = "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
destfile = "rawdata.zip"

# Download the file if necessary.
# For efficiency, only download the file if it doesn't exist already
# A better implementation would check that the existing file is the same as the one we want
# (by computing and comparing a hash value for example)
if (!file.exists(destfile))
  download.file(url, dest=destfile, mode="wb")

# Unzip it if necessary
# Assume that the file is already unzipped if the target folder already exists
# Not perfect, but better than getting an error while unzipping.
if (!file.exists("UCI HAR Dataset")) unzip(destfile) else 
print("The folder that the zip file extracts to already exists. I won't unzip.")


##########################
#
# 0- Extract the relevant datasets from the unzipped files.
#
##########################

# TEST dataset
  setwd("./UCI HAR Dataset/test")
  activity <- fread("y_test.txt") # the type of the activity
  subject <- fread("subject_test.txt") # the id numbers of the individuals (subjects) who participated
  if(!exists("measurements_test"))
    measurements_test <- read.table("X_test.txt", colClasses="numeric") # the measurements proper (the 500+ measurements)
  
  # merge the three data sets into one, column-wise
  # so that each row contains the id of the subject, the activity, and the recorded measurements.
  data_test <- cbind(subject, activity, measurements_test)

# Training dataset
# now repeat the same for the training data
  setwd("../train")

  activity <- fread("y_train.txt") # the type of the activity
  subject <- fread("subject_train.txt") # the id numbers of the individuals (subjects) who participated

# for efficiency, only read the file if the variable doesn't exist already
# if it exists, assume that this RStudio session has the right data, and 
# skip this step to save time.
  if(!exists("measurements_training"))
    measurements_training <- read.table("X_train.txt", colClasses="numeric") # the measurements proper (the 500+ measurements)
  
  # merge the three training datasets into one, column-wise
  data_train <- cbind(subject, activity, measurements_training)

##########################
#
# 1. Merge the training and the test sets to create one data set.
#
##########################

# combine both data tables, row-wise
# it is not a requirement to keep of track of the source of the data (train vs. test)
# so I am not capturing that info in the superset
# I tried using the more performant rbind_list but 
# it was dropping the first two columns, so
# I stuck to the less performing rbind().
data_all <- rbind(data_test, data_train)


##########################
#
# 4. Appropriately labels the data set with descriptive variable names. 
#
##########################

# I decided to do this out of order compared to the list of steps project Readme.md to
# make it easier to target the right columns for the subsequent operations.
# It's easier for me to refer to them by name rather than by index.


# Now set the names of the columns using the descriptions provided in the data set
# If you use colnames() for this operation, you get warning message about 
# the performance of this function.
# The warning message recommends using setnames() instead, and that's what I did here: 
features <- fread("../features.txt") # read the names of the measurements from the text files
setnames(data_all, c("subject", "activity", features$V2)) # set those names as column names


##########################
#
# 2. Extracts only the measurements on the mean and standard deviation for each measurement. 
#
##########################


# Get names of columns that have "-mean()" or "-std()" in them
# I am not including the 'meanFreq' as it doesn't seem to be a statistical value computed 
# out of the other measurements.
# It would be easy to include those if necessary by modifying the regex used as an argument 
# to the grep function below.
goodcolumns  <- c("subject", "activity", grep("(-mean\\()+|(std\\()+", names(data_all), value=TRUE))

data_small <- select(data_all, one_of(goodcolumns)) # one_of returns all items in the goodcolumns vector


##########################
#
# 3. Uses descriptive activity names to name the activities in the data set 
#
##########################


# Get activity names from the file
# the first column is the numerical code of the activity, the second column is its name
activitynames <- fread("../activity_labels.txt")

data_small$activity <- factor(as.character(data_small$activity), levels=activitynames$V1, labels=activitynames$V2)
data_small$subject <- factor(as.character(data_small$subject))

# Tidy data set requested

# Convert the many columns of measurements into one, called "measurements"
# where the values of those measurements are in a corresponding column "results"
res <- gather(data_small, measurement, results, -subject, -activity)

# Compute the averages of the measurements for 
meltedata <- res %>% 
  group_by(subject, activity, measurement) %>% 
  mutate(averages = mean(results)) %>% 
  select(-results) %>% 
  unique

# Clean up the measurement names.
# BodyBody should be Body
# I transformed the hyphens (-) to dots (.). Some functions don't like hyphens in the variable names.
meltedata$measurement <- gsub("BodyBody", "Body", gsub("-", ".", meltedata$measurement))

tidydata %>% spread(measurement, results)

setwd("../..")

write.table(tidydata, "outputdata.csv", quote=FALSE, row.names=FALSE)