# Model: Random Forest

# load library
library(tidyverse)
library(randomForest)
library(caret)

# MAE
MAE <- function(obs, pred) {
  e <- obs - pred
  mae <- mean(abs(e))
  return(mae)
}

# Import the spilt training data set
train_85 <- read_csv("data/train_85.csv")
train_15 <- read_csv("data/train_15.csv")

# Convert character to factor, 
train_85$result <- factor(train_85$result)
train_85$property_type <- factor(train_85$property_type)
train_85$suburb <- as.numeric(factor(train_85$suburb))
train_85$month <- as.numeric(factor(train_85$month))
train_85

train_15$result<-factor(train_15$result)
train_15$property_type<-factor(train_15$property_type)
train_15$suburb<-as.numeric(factor(train_15$suburb))
train_15$month<-as.numeric(factor(train_15$month))
train_15

# Grid search, use 5-fold, 2 repeat dure the size of data, found optimise mtry
set.seed(001)
control <- trainControl(method = "repeatedcv", number = 5, repeats = 2, search = "grid")
# tune mtry base on 500 trees
tunegrid_mtry <- expand.grid(.mtry = c(1:13))
rf_grid_mtry <- train(price~., 
                      data = train_85, 
                      method = "rf", 
                      metric = "MAE",
                      maximize = FALSE,
                      ntree = 500,
                      tuneGrid = tunegrid_mtry, 
                      trControl = control)
print(rf_grid_mtry)

plot_rf_grid_mtry <- rf_grid_mtry$results %>%
  ggplot(aes(x = mtry, y = MAE)) +
  geom_point() +
  geom_line(color = "blue") +
  geom_hline(yintercept = min(rf_grid_mtry$results$MAE), color = "red", linetype="dotted")+
  ggtitle("Grid Search of mtry parameter for Random Forest")

ggsave(filename = "plot/plot_rf_grid_mtry.png", plot = plot_rf_grid_mtry, width = 6, height = 3, units = "in")

#save the model
saveRDS(rf_grid_mtry, "model/saved_model/rf_grid_mtry.RDS")

#optimise mtry is 13
optimise_mtry <- 13

# Grid search, found optimise ntree base on optimise mtry
# tune mtry base on optimise mtry
model_list <- list()
tunegrid_ntree <- expand.grid(.mtry = optimise_mtry)
for (ntree in c(500, 1000, 1500, 2000, 3000)) {
  set.seed(001)
  fit <- train(price~., 
               data = train_85, 
               method = "rf", 
               metric = "MAE",
               maximize = FALSE,
               tuneGrid = tunegrid_ntree, 
               trControl = control,
               ntree = ntree)
  key <- toString(ntree)
  model_list[[key]] <- fit
}

#save the model
#saveRDS(model_list, "model/saved_model/rf_grid_ntree.RDS")

# compare results
results <- resamples(model_list)
summary(results)
dotplot(results)

optimise_ntree <- 2000

# Final random forest model base on optimise mtry and ntree
optimise_rf <- model_list[[4]]

saveRDS(optimise_rf, "model/saved_model/optimise_rf.RDS")

# Evaluate the MAE with train_15 set
MAE(predict(optimise_rf, train_15), train_15$price)
# MAE is 1.334874

# test set
test_np <- read_csv("data/test_noprice.csv")
test_np$result <- factor(test_np$result)
test_np$property_type <- factor(test_np$property_type)
test_np$suburb <- as.numeric(factor(test_np$suburb))
test_np$month <- as.numeric(factor(test_np$month))

pred <- predict(optimise_rf, test_np)
# Sumbmission
test_sub <- test_np %>%
  select(id) %>%
  mutate(price = pred)
# write_csv(test_sub, "sub_rf.csv")

