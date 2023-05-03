# Model: Gradient Boosting with gbm

# load library
library(tidyverse)
library(gbm)

# MAE
MAE <- function(obs, pred) {
  e <- obs - pred
  mae <- mean(abs(e))
  return(mae)
}

# Import the data and combine together, in order each variable have the same level
train <- read_csv("data/train_85.csv") %>%
  mutate(dataset = "train")
local_test <- read_csv("data/train_15.csv") %>%
  mutate(dataset = "local_test")
test <- read_csv("data/test_noprice.csv") %>%
  mutate(dataset = "test",
         price = 0)
full_data <- rbind(train, local_test, test)
remove(train, local_test, test)

# Convert character to factor 
full_data$result <- factor(full_data$result)
full_data$property_type <- factor(full_data$property_type)
full_data$suburb <- as.factor(full_data$suburb)
full_data$month <- as.factor(full_data$month)

# split data to orgionnal
train_85 <- full_data %>%
  filter(dataset == "train") %>%
  mutate(log_price = log(price)) %>%
  select(-dataset)

train_15 <- full_data %>%
  filter(dataset == "local_test") %>%
  select(-dataset)

test_np <- full_data %>%
  filter(dataset == "test") %>%
  select(-c("dataset","price"))

remove(full_data)

# gbm model with gaussian distribution
set.seed(001)
gbm_gaussian <- gbm(log_price~.-price, 
                 data = train_85,
                 distribution = "gaussian",
                 n.trees = 1000,
                 shrinkage=0.01,
                 interaction.depth = 20,
                 n.minobsinnode = 30,
                 bag.fraction = 0.8,
                 train.fraction = 0.8,
                 cv.folds = 4,
                 n.cores = 4)

saveRDS(gbm_gaussian, "model/saved_model/gbm_gaussian.RDS")

# underestimates the optimal number of iterations
best_iter_gaussian_oob <- gbm.perf(gbm_gaussian, method = "OOB")
print(best_iter_gaussian_oob) #gbm_gaussian_oob_tree, 389
summary(gbm_gaussian, n.trees = best_iter_gaussian_oob) #gbm_gaussian_oob_important
train_15_pred_oob <- predict(object = gbm_gaussian, newdata = train_15, n.trees = best_iter_gaussian_oob)
MAE(exp(train_15_pred_oob), train_15$price) #1.414814

# Check performance using the 20% heldout test set
best_iter_gaussian_test <- gbm.perf(gbm_gaussian, method = "test")
print(best_iter_gaussian_test) #gbm_gaussian_test_tree, 26
summary(gbm_gaussian, n.trees = best_iter_gaussian_test) #gbm_gaussian_test_important
train_15_pred_test <- predict(object = gbm_gaussian, newdata = train_15, n.trees = best_iter_gaussian_test)
MAE(exp(train_15_pred_test), train_15$price) #2.755079

# Check performance using 4-fold cross-validation
best_iter_gaussian_cv <- gbm.perf(gbm_gaussian, method = "cv")
print(best_iter_gaussian_cv) #gbm_gaussian_cv_tree, 752
summary(gbm_gaussian, n.trees = best_iter_gaussian_cv) #gbm_gaussian_cv_important
train_15_pred_cv <- predict(object = gbm_gaussian, newdata = train_15, n.trees = best_iter_gaussian_cv)
MAE(exp(train_15_pred_cv), train_15$price) #1.413301

# gbm model with laplace distribution
gbm_laplace <- gbm(price~.-log_price, 
                    data = train_85,
                    distribution = "laplace",
                    n.trees = 1000,
                    shrinkage = 0.028,
                    interaction.depth = 21,
                    n.minobsinnode = 30,
                    bag.fraction = 0.8,
                    train.fraction = 0.8,
                    cv.folds = 4,
                    n.cores = 4)

saveRDS(gbm_laplace, "model/saved_model/gbm_laplace.RDS")

# underestimates the optimal number of iterations
best_iter_laplace_oob <- gbm.perf(gbm_laplace, method = "OOB")
print(best_iter_laplace_oob) #gbm_laplace_oob_tree, 166
summary(gbm_laplace, n.trees = best_iter_laplace_oob) #gbm_laplace_oob_important
train_15_pred_oob <- predict(object = gbm_laplace, newdata = train_15, n.trees = best_iter_laplace_oob)
MAE(train_15_pred_oob, train_15$price) #1.247876

# Check performance using the 20% heldout test set
best_iter_laplace_test <- gbm.perf(gbm_laplace, method = "test")
print(best_iter_laplace_test) #gbm_laplace_test_tree, 987
summary(gbm_laplace, n.trees = best_iter_laplace_test) #gbm_laplace_test_important
train_15_pred_test <- predict(object = gbm_laplace, newdata = train_15, n.trees = best_iter_laplace_test)
MAE(train_15_pred_test, train_15$price) #1.222826

# Check performance using 4-fold cross-validation
best_iter_laplace_cv <- gbm.perf(gbm_laplace, method = "cv")
print(best_iter_laplace_cv) #gbm_laplace_cv_tree, 990
summary(gbm_laplace, n.trees = best_iter_laplace_cv) #gbm_laplace_cv_important
train_15_pred_cv <- predict(object = gbm_laplace, newdata = train_15, n.trees = best_iter_laplace_cv)
MAE(train_15_pred_cv, train_15$price) #1.22285


