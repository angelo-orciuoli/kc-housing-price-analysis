# King County Housing Price Analysis

A comprehensive data analysis and machine learning project predicting home prices in King County, Washington using statistical modeling and regression techniques.

## 🏠 Project Overview

This project analyzes housing sales data from King County, Washington to build predictive models for residential property values. The analysis combines data cleaning, exploratory data analysis, linear regression, and logistic regression to understand the factors that drive housing prices and identify high-quality properties.

### Key Features

- **Comprehensive Data Cleaning**: Manual verification and correction of data entry errors using external sources
- **Feature Engineering**: Creation of meaningful variables from raw data (geographic regions, renovation categories)
- **Statistical Modeling**: Linear regression for price prediction with model selection techniques
- **Classification Analysis**: Logistic regression for identifying high-quality homes
- **Visualization**: Extensive exploratory data analysis with professional charts and graphs

## 📊 Dataset

The dataset contains over 21,000 home sales records from King County, including:

- **Property Details**: Bedrooms, bathrooms, square footage, lot size, floors
- **Quality Metrics**: Property condition, grade, view quality
- **Location Data**: Latitude, longitude, zip codes
- **Historical Information**: Year built, renovation history
- **Sale Information**: Price, date of sale

## 🔧 Methodology

### Data Preprocessing
1. **Quality Validation**: Identification and correction of data entry errors
2. **Manual Verification**: Cross-referencing suspicious records with King County Parcel Viewer
3. **Feature Transformation**: 
   - Date parsing (sale year/month)
   - Geographic clustering (city/suburb/rural classification)
   - Renovation categorization (recent/old/never)

### Analytical Approaches

#### Linear Regression Analysis
- **Model Selection**: Used adjusted R², Mallows' Cp, and BIC for optimal feature selection
- **Assumption Validation**: Checked linearity, independence, homoscedasticity, and normality
- **Outlier Treatment**: Systematic removal of influential observations
- **Final Model Performance**: R² = 0.683, RMSE ≈ $205K

#### Logistic Regression Classification
- **Target Variable**: "Good Quality" homes (condition > 3 AND grade > 7)
- **Feature Selection**: Price, square footage, year built, and geographic region
- **Model Evaluation**: ROC analysis, AUC = 0.77

## 📈 Key Findings

### Price Prediction Model
The final linear regression model identified these key price drivers:
- **Square footage**: +$154.65 per sq ft
- **Waterfront property**: +$584,913 premium
- **Property grade**: +$96,291 per grade level
- **View quality**: +$45,372 per view level
- **Location**: Suburban homes +$41,909 vs rural (-$59,865)

### Home Quality Classification
High-quality homes are characterized by:
- Significantly higher prices and larger living areas
- More common in suburban areas
- Generally newer construction
- Better proximity to downtown Seattle

## 🛠️ Technologies Used

- **R** - Primary analysis language
- **tidyverse** - Data manipulation and visualization
- **ggplot2** - Statistical graphics
- **leaps** - Model selection procedures
- **ROCR** - ROC analysis for classification
- **R Markdown** - Reproducible research documentation

## 📁 Project Structure

```
├── king_county_housing_analysis.Rmd    # Main analysis notebook
├── kc_house_data.csv                   # Housing dataset
├── grade_condition_distribution.png    # Generated visualization
├── LICENSE                             # MIT License
└── README.md                           # This file
```

## 🚀 Getting Started

### Prerequisites
```r
# Required R packages
install.packages(c("tidyverse", "ggplot2", "leaps", "faraway", "ROCR", "scales", "gridExtra"))
```

### Running the Analysis
1. Clone this repository
2. Open `king_county_housing_analysis.Rmd` in RStudio
3. Ensure `kc_house_data.csv` is in the working directory
4. Run all code chunks to reproduce the analysis

## 📋 Analysis Highlights

### Data Quality Improvements
- Corrected 13 properties with verified data entry errors
- Removed 3 unverifiable records
- Maintained data integrity through external verification

### Model Performance
- **Linear Regression**: Explains 68.3% of price variation
- **Logistic Regression**: 77% accuracy in identifying quality homes
- **Cross-validation**: Models tested on held-out test data

### Business Insights
- Waterfront properties command the highest premiums
- Property grade is a stronger predictor than condition
- Geographic location significantly impacts valuations
- Recent renovations don't always correlate with higher quality ratings

## 🔮 Future Enhancements

- **Time Series Analysis**: Incorporate seasonal trends and market cycles
- **Advanced ML Models**: Random Forest, XGBoost for improved predictions
- **Geographic Analysis**: Detailed neighborhood-level clustering
- **Economic Indicators**: Integration with local economic data
- **Interactive Dashboard**: Shiny app for real-time predictions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


---

*This analysis demonstrates practical applications of statistical modeling in real estate valuation and showcases best practices in data science workflows.*
