# load library
library(caret)
library(readr)

# Import training data set
train <- read_csv("data/train.csv")

# Spilt train set as 85/15 ratio by the vraiable suburb
set.seed(123)
index <- createDataPartition(train$suburb, list = FALSE, p = 0.85)
train_85 <- train[index,]
train_15 <- train[-index,]

# split training set
train_85
train_15

# outport the split training set
#write_csv(train_85, "data/train_85.csv")
#write_csv(train_15, "data/train_15.csv")
