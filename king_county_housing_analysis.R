# ==============================================================================
# King County Housing Price Analysis - R Script
# Author: Angelo Orciuoli
# Description: Housing price analysis and prediction models
# ==============================================================================

# Load Required Libraries
# ==============================================================================
library(tidyverse)
library(dplyr)
library(scales)
library(gridExtra)
library(ggplot2)
library(leaps)
library(faraway)
library(ROCR)

# Data Loading Function
# ==============================================================================
load_housing_data <- function(file_path = "kc_house_data.csv") {
  data <- read.csv(file_path, sep = ",", header = TRUE)
  cat("Data loaded successfully with", nrow(data), "rows and", ncol(data), "columns\n")
  cat("Missing values per column:\n")
  print(colSums(is.na(data)))
  return(data)
}

# Data Quality Check Function
# ==============================================================================
check_data_quality <- function(data) {
  problem_rows <- data[
    (data$bedrooms == 0 | data$bedrooms == 33 | data$bathrooms == 0) &
    !is.na(data$bedrooms) & !is.na(data$bathrooms),
    c("id", "bedrooms", "bathrooms", "sqft_living", "price", "zipcode")
  ]
  
  cat("Properties with suspicious bedroom/bathroom values:\n")
  print(problem_rows)
  cat("\nFound", nrow(problem_rows), "properties with extreme bedroom/bathroom values\n")
  return(problem_rows)
}

# Data Cleaning Function
# ==============================================================================
clean_housing_data <- function(data) {
  # Apply manual corrections based on external verification
  corrections <- list(
    list(id = 6306400140, bedrooms = 5, bathrooms = 4.50),
    list(id = 3421079032, bedrooms = 3, bathrooms = 3.75),
    list(id = 3918400017, bedrooms = 3, bathrooms = 2.25),
    list(id = 6896300380, bedrooms = 3, bathrooms = NA),
    list(id = 2954400190, bedrooms = 4, bathrooms = 4),
    list(id = 2569500210, bedrooms = 4, bathrooms = NA),
    list(id = 2310060040, bedrooms = 4, bathrooms = NA),
    list(id = 7849202190, bedrooms = 3, bathrooms = 1.50),
    list(id = 7849202299, bedrooms = 0, bathrooms = NA),
    list(id = 9543000205, bedrooms = 2, bathrooms = 1),
    list(id = 2402100895, bedrooms = 3, bathrooms = NA),
    list(id = 1222029077, bedrooms = 1, bathrooms = 1.50),
    list(id = 3374500520, bedrooms = 4, bathrooms = 3.5)
  )
  
  # Apply corrections
  for (correction in corrections) {
    if (!is.na(correction$bedrooms)) {
      data[data$id == correction$id, "bedrooms"] <- correction$bedrooms
    }
    if (!is.na(correction$bathrooms)) {
      data[data$id == correction$id, "bathrooms"] <- correction$bathrooms
    }
  }
  
  # Remove unverifiable records
  remove_ids <- c(5702500050, 203100435, 3980300371)
  data <- data[!data$id %in% remove_ids, ]
  
  cat("Applied corrections to", length(corrections), "properties\n")
  cat("Removed", length(remove_ids), "unverifiable records\n")
  cat("Remaining records:", nrow(data), "\n")
  
  return(data)
}

# Feature Engineering Function
# ==============================================================================
engineer_features <- function(data) {
  # Extract year and month from date
  data$year_sold <- as.numeric(substr(data$date, 1, 4))
  data$month_sold <- as.numeric(substr(data$date, 5, 6))
  
  # Create geographic regions from zipcodes
  city_zips <- c(98101, 98102, 98104, 98105, 98109, 98112, 98115, 98116, 98118, 98119, 98121, 98122, 98125, 98126, 98133, 98134, 98136, 98144, 98154, 98164, 98174, 98195)
  suburb_zips <- c(98004, 98005, 98006, 98007, 98008, 98027, 98029, 98033, 98034, 98040, 98052, 98053, 98056, 98057, 98059, 98072, 98074, 98075, 98092, 98070, 98028, 98019)
  rural_zips <- setdiff(unique(data$zipcode), union(city_zips, suburb_zips))
  
  data$region <- case_when(
    data$zipcode %in% city_zips ~ "City",
    data$zipcode %in% suburb_zips ~ "Suburb",
    data$zipcode %in% rural_zips ~ "Rural"
  )
  data$region <- factor(data$region, levels = c("City", "Suburb", "Rural"))
  
  # Create renovation groups
  data$renovation_group <- case_when(
    data$yr_renovated == 0 ~ "Never Renovated",
    data$yr_renovated >= 2005 ~ "Recently Renovated",
    TRUE ~ "Renovated Long Ago"
  )
  data$renovation_group <- factor(data$renovation_group)
  
  # Convert waterfront to factor and calculate distance to downtown Seattle
  data$waterfront <- factor(data$waterfront)
  data$distance_to_downtown <- sqrt(
    (data$lat - 47.6062)^2 + (data$long + 122.3321)^2
  )
  
  # Remove redundant square footage variables (multicollinearity)
  data$sqft_above <- NULL
  data$sqft_basement <- NULL
  
  # Create good quality indicator for logistic regression
  data$good_quality <- ifelse(data$condition > 3 & data$grade > 7, "yes", "no")
  data$good_quality <- factor(data$good_quality)
  
  cat("Feature engineering completed\n")
  cat("Region distribution:\n")
  print(table(data$region))
  cat("\nRenovation group distribution:\n")
  print(table(data$renovation_group))
  
  return(data)
}

# Data Splitting Function
# ==============================================================================
split_data <- function(data, train_prop = 0.8, seed = 1) {
  set.seed(seed)
  sample_idx <- sample.int(nrow(data), floor(train_prop * nrow(data)), replace = FALSE)
  train <- data[sample_idx, ]
  test <- data[-sample_idx, ]
  
  cat("Data split completed:\n")
  cat("Training set:", nrow(train), "observations\n")
  cat("Test set:", nrow(test), "observations\n")
  
  return(list(train = train, test = test))
}

# Linear Regression Model Building Function
# ==============================================================================
build_linear_model <- function(train_data, remove_outliers = TRUE) {
  # Initial model with selected predictors
  model <- lm(price ~ bedrooms + sqft_living + waterfront + view + grade + yr_built + region + distance_to_downtown, data = train_data)
  
  if (remove_outliers) {
    # Remove outliers based on standardized residuals
    std_res <- rstandard(model)
    outlier_count <- sum(abs(std_res) > 2)
    outlier_residuals <- order(abs(std_res), decreasing = TRUE)[1:outlier_count]
    train_clean <- train_data[-outlier_residuals, ]
    
    # Rebuild model without outliers
    model <- lm(price ~ bedrooms + sqft_living + waterfront + view + grade + yr_built + region + distance_to_downtown, data = train_clean)
    
    cat("Removed", outlier_count, "outliers from training data\n")
  }
  
  cat("Linear model built successfully\n")
  print(summary(model))
  
  return(model)
}

# Logistic Regression Model Building Function
# ==============================================================================
build_logistic_model <- function(train_data, full_model = TRUE) {
  if (full_model) {
    model <- glm(good_quality ~ price + sqft_living + yr_built + distance_to_downtown + waterfront + region + renovation_group, 
                 data = train_data, family = binomial())
  } else {
    model <- glm(good_quality ~ price + sqft_living + yr_built + region, 
                 data = train_data, family = binomial())
  }
  
  cat("Logistic model built successfully\n")
  print(summary(model))
  
  return(model)
}

# Model Evaluation Functions
# ==============================================================================
evaluate_linear_model <- function(model, test_data) {
  predictions <- predict(model, newdata = test_data)
  actual_prices <- test_data$price
  
  # Calculate RMSE
  mse <- mean((predictions - actual_prices)^2)
  rmse <- sqrt(mse)
  
  # Calculate R-squared
  rss <- sum((predictions - actual_prices)^2)
  tss <- sum((actual_prices - mean(actual_prices))^2)
  rsq <- 1 - rss / tss
  
  cat("Linear Model Performance:\n")
  cat("RMSE:", round(rmse, 2), "\n")
  cat("R-squared:", round(rsq, 3), "\n")
  
  return(list(rmse = rmse, r_squared = rsq, predictions = predictions))
}

evaluate_logistic_model <- function(model, test_data) {
  # Predicted probabilities
  preds <- predict(model, newdata = test_data, type = "response")
  
  # Confusion matrix
  confusion_matrix <- table(test_data$good_quality, preds > 0.5)
  print("Confusion Matrix:")
  print(confusion_matrix)
  
  # Calculate accuracy and error rate
  accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
  error_rate <- 1 - accuracy
  
  # ROC and AUC
  rates <- ROCR::prediction(preds, test_data$good_quality)
  roc_result <- ROCR::performance(rates, measure = "tpr", x.measure = "fpr")
  auc <- ROCR::performance(rates, measure = "auc")
  
  cat("Logistic Model Performance:\n")
  cat("Accuracy:", round(accuracy * 100, 2), "%\n")
  cat("Error Rate:", round(error_rate * 100, 2), "%\n")
  cat("AUC:", round(auc@y.values[[1]], 3), "\n")
  
  return(list(
    accuracy = accuracy,
    error_rate = error_rate,
    auc = auc@y.values[[1]],
    predictions = preds,
    roc = roc_result
  ))
}

# Visualization Functions
# ==============================================================================
plot_price_distribution <- function(data) {
  ggplot(data, aes(x = price)) +
    scale_x_continuous(breaks = breaks_extended(6), labels = label_dollar()) +
    theme(plot.title = element_text(hjust = 0.5)) +
    labs(x = "Price", y = "Density", title = "Distribution of Price") +
    geom_density()
}

plot_price_by_region <- function(data) {
  ggplot(data, aes(x = region, y = log(price))) +
    scale_y_continuous(breaks = breaks_extended(6)) +
    theme(plot.title = element_text(hjust = 0.5)) +
    labs(x = "Region", y = "log(Price)", title = "log(Price) by Region") +
    geom_boxplot(fill = "lavender")
}

plot_roc_curve <- function(roc_result, title = "ROC Curve") {
  plot(roc_result, main = title)
  lines(x = c(0, 1), y = c(0, 1), col = "red")
}

# Main Analysis Function
# ==============================================================================
run_housing_analysis <- function(file_path = "kc_house_data.csv") {
  # Load and prepare data
  cat("=== Loading and Cleaning Data ===\n")
  data <- load_housing_data(file_path)
  check_data_quality(data)
  data <- clean_housing_data(data)
  data <- engineer_features(data)
  
  # Split data
  cat("\n=== Splitting Data ===\n")
  split_result <- split_data(data)
  train <- split_result$train
  test <- split_result$test
  
  # Build and evaluate linear regression model
  cat("\n=== Linear Regression Analysis ===\n")
  linear_model <- build_linear_model(train, remove_outliers = TRUE)
  linear_results <- evaluate_linear_model(linear_model, test)
  
  # Build and evaluate logistic regression model
  cat("\n=== Logistic Regression Analysis ===\n")
  logistic_model <- build_logistic_model(train, full_model = TRUE)
  logistic_results <- evaluate_logistic_model(logistic_model, test)
  
  return(list(
    data = data,
    train = train,
    test = test,
    linear_model = linear_model,
    logistic_model = logistic_model,
    linear_results = linear_results,
    logistic_results = logistic_results
  ))
}

# Example Usage
# ==============================================================================
# Uncomment the following lines to run the complete analysis:
# results <- run_housing_analysis("kc_house_data.csv")
# 
# # Generate some plots
# plot_price_distribution(results$train)
# plot_price_by_region(results$train)
# plot_roc_curve(results$logistic_results$roc, "ROC Curve for Home Quality Classification")