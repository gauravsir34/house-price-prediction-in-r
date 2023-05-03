# Model: Decision Tree

# load library
library(tidyverse)
library(rpart)

# MAE
MAE <- function(obs, pred) {
  e <- obs - pred
  mae <- mean(abs(e))
  return(mae)
}

# Import the spilt training data set
train_85 <- read_csv("data/train_85.csv")
train_15 <- read_csv("data/train_15.csv")

# Decision tree, set the minimum overvation in the end leaf must larger than 70
model_dt <- rpart(price~., data = train_85, control = rpart.control(cp = 0.0000001, minsplit = 70))
tail(model_dt$cptable)
model_dt$variable.importance

saveRDS(model_dt, "model/saved_model/dt_base.RDS")

# Evaluate the MAE with train_15 set
MAE(predict(model_dt, train_15), train_15$price)
#MAE is 1.216002

# Predict test set
test_np <- read_csv("data/test_noprice.csv")
pred <- predict(model_dt, test_np)

# Sumbmission
test_sub <- test_np %>%
  select(id) %>%
  mutate(price = pred)
# write_csv(test_sub, "sub_dt.csv")

