Coursera Data Science Specialization track
Getting and Cleaning Data - https://class.coursera.org/getdata-016/
Course project
===========================================

This project required acquiring, tidying, and subsetting the data set available at https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip


Step 1 - Extract the relevant datasets from the unzipped files.

I start by downloading and unzipping the data set in a local working directory.

For efficiency, and since I ran the script multiple times, I added simple logic to only download and unzip if the files are not present locally already. The file unzips into a directory called "UCI HAR Dataset"


I then read into local data frames, the contents of files under the "train" and the "test" folders. The project instructions ask us to only consider the columns for means and standard deviations. Since, the files under Inertial Signals do not include any data about means or standard deviations, I didn't have to read those files in.

subject_train.txt and subject_test.txt are single column files where each row corresponds to an observation. The data in that row is the id of the person carrying the device where the observation was recorded.

y_train.txt and y_test.txt are also single column files, each row corresponding to an observation. The data in that row is the id of the activity that was occurring when the observation was recorded. (the names of those activities are found in activity_labels.txt under the root folder of the data set ("UCI HAR Dataset")

X_train.txt and y_test.txt are the files that contain the data for the observations.
Both have 561 columns, one corresponding to each measurement (the names of those measurements are found in the "features.txt" file).
X_train.txt has 7352 observations (rows), and X_test.txt has 2947 observations.
Seeing that they have the same number of columns is an indication that they will be easy to collate together.
The number of rows aren't really important for the analysis, but they helped give me an idea about the size of the data set.

The first step was to create a "super data set" of all the data. I used cbind and rbind to create a data frame (called data_all) with the following pattern:

subject (int)  activity (int)  measurement 1 (num) ... measurement 561 (num)
Test observation 1
..
Test observation 2947
Train observation 1
..
Train observation 7352


Step 2 - Label the variable names

The variables were described, in the right order, in header-less file "features.txt" under "UCI HAR Dataset"
I read the file content in a data frame (called "features"). The names that I needed were in the second column (features$V2).
I then used setnames() (from the data.table library) to set the names of all 563 columns (subject, activity, and the 561 measurement columns)

Step 3. Extract only the measurements on the mean and standard deviation for each measurement. 

The project requirement is slightly ambiguous. Should all measurements that include the word "mean" be included? Some are measurements where the mean was an input (for example: angle(X,gravityMean)).

I made an assumption, and documented how the code can be changed if someone disagrees with my assumption. The assumption is the following: the measurements that include the word "mean" and that have to be included, are those that have a corresponding measurement where "mean" is replaced by "std" (for example: fBodyBodyGyroJerkMag-mean() and fBodyBodyGyroJerkMag-std())

I used the grep() function and a simple regular expression to select the columns of interest (the "good columns"). I looked for columns that include "-mean()" and "-std()" in their name.
	goodcols  <- c("subject", "activity", grep("(-mean\\()+|(std\\()+", names(data_all), value=TRUE))

I then used select() (from the dplyr library) to build a smaller data set that only includes the resulting 68 columns.
	data_small <- select(data_all, one_of(goodcols))

	
Step 4. Use activity names instead of numbers in the data set 
The names of the activities are found in the file "activity_labels.txt".
I read the content of that file into a data frame (called activitynames), and converted the 'activity' column to factors with the labels being the 'activitynames'

Step 5. Used gather() to create a transition data frame where I will do the computation.
Using gather() (from the tidyr library), I converted the measurement columns into a single column with multiple values, into a temporary data frame called res.
This is what res looks like:
			subject         activity                measurement    results
		 1:       2         STANDING          tBodyAcc-mean()-X  0.2571778
		 2:       2         STANDING          tBodyAcc-mean()-X  0.2860267
		 3:       2         STANDING          tBodyAcc-mean()-X  0.2754848
		 4:       2         STANDING          tBodyAcc-mean()-X  0.2702982
		 5:       2         STANDING          tBodyAcc-mean()-X  0.2748330
		---                                                               
	679730:      30 WALKING_UPSTAIRS fBodyBodyGyroJerkMag-std() -0.7239514
	679731:      30 WALKING_UPSTAIRS fBodyBodyGyroJerkMag-std() -0.7711831
	679732:      30 WALKING_UPSTAIRS fBodyBodyGyroJerkMag-std() -0.7263718
	679733:      30 WALKING_UPSTAIRS fBodyBodyGyroJerkMag-std() -0.6894209
	679734:      30 WALKING_UPSTAIRS fBodyBodyGyroJerkMag-std() -0.7451204

	
Step 6- Compute the averages of the chosen measurements
I then used a chain of dplyr commands to compute the average of each measurement (for each subject and activity combination). 

	res %>% 
	  group_by(subject, activity, measurement) %>% 
	  mutate(averages = mean(results))

This results in the following data frame:

	Source: local data table [679,734 x 5]
	Groups: subject, activity, measurement

	   subject activity       measurement   results  averages
	1        1  WALKING tBodyAcc-mean()-X 0.2820216 0.2773308
	2        1  WALKING tBodyAcc-mean()-X 0.2558408 0.2773308
	3        1  WALKING tBodyAcc-mean()-X 0.2548672 0.2773308
	4        1  WALKING tBodyAcc-mean()-X 0.3433705 0.2773308
	5        1  WALKING tBodyAcc-mean()-X 0.2762397 0.2773308
	6        1  WALKING tBodyAcc-mean()-X 0.2554682 0.2773308
	7        1  WALKING tBodyAcc-mean()-X 0.3211398 0.2773308
	8        1  WALKING tBodyAcc-mean()-X 0.2346659 0.2773308
	9        1  WALKING tBodyAcc-mean()-X 0.3126340 0.2773308
	10       1  WALKING tBodyAcc-mean()-X 0.2769154 0.2773308
	..     ...      ...               ...       ...       ...

Since we're not interested in keeping the individual measurements in the output data set, we can remove the "results" column, and keep only the unique rows. I stored the cleaner (and much smaller) result in a data frame called "meltedata".
	
	Source: local data table [11,880 x 4]
	Groups: subject, activity, measurement

	   subject activity          measurement    averages
	1        1  WALKING    tBodyAcc-mean()-X  0.27733076
	2        1  WALKING    tBodyAcc-mean()-Y -0.01738382
	3        1  WALKING    tBodyAcc-mean()-Z -0.11114810
	4        1  WALKING     tBodyAcc-std()-X -0.28374026
	5        1  WALKING     tBodyAcc-std()-Y  0.11446134
	6        1  WALKING     tBodyAcc-std()-Z -0.26002790
	7        1  WALKING tGravityAcc-mean()-X  0.93522320
	8        1  WALKING tGravityAcc-mean()-Y -0.28216502
	9        1  WALKING tGravityAcc-mean()-Z -0.06810286
	10       1  WALKING  tGravityAcc-std()-X -0.97660964
	..     ...      ...                  ...         ...


Step 7 - Create a tidy data set and write it to a file	
Wickham's "Tidy data" paper (2007) lists three principles for tidy data.
	1. Each variable forms a column.
	2. Each observation forms a row.
	3. Each type of observational unit forms a table.
	
Principle 1 is of particular interest for this project. I considered the various measurements (average of tBodyAcc-mean()-X, and average of tBodyAcc-std()-X) are different variables, which means that the "meltedata" data frame is not tidy yet. This lead me to spread() (from the tidyr library) those variables into their own columns, and store the result in a data frame called "tidydata".

But before calling spread(), I cleaned up the variable names a bit. I noticed for example that some variables had the word "Body" twice (as such: BodyBody), I considered that to be a typo in the original data set and fixed it using the gsub() function. Also, in the course of implementing the code of the project I also noticed that some functions throw an error if a variable name has a hyphen "-" in it, so I removed all the hyphens and replaced them with dots "." to maintain readability.
	fBodyAcc-mean()-X became fBodyAcc.mean().X, for example.

After cleaning the variable names, I spread the measurements into their own variables:
	tidydata <- meltedata %>% spread(measurement, averages)

tidydata has 180 rows and 68 columns. The code book for tidydata is in "Codebook.txt". Note that the original data set did not specify the units of the measurements as far as I could tell, so I indicated in the code book that the units are also missing from the tidy data set that I generated.
	
	
The last step in the script is to write tidydata to a file. I did that with the following command:
	write.table(tidydata, "outputdata.txt", quote=FALSE, row.names=FALSE)
	
To read the file simply use:
	read.table("outputdata.txt", header=TRUE)
	
I thank the community TA David Hood for suggesting to include the read.table command in this Readme. He posted an extensive FAQ at this address:  https://class.coursera.org/getdata-016/forum/thread?thread_id=50