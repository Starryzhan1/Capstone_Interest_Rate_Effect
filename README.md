# Capstone_Interest_Rate_Effect

## **💡Project Description**
This project analyzes how the European Central Bank’s (ECB) interest rate policy has influenced bank strategies and household financial behavior (saving, borrowing, and investing) in Germany from 2020 to 2025. 

**The analysis involves:**
- Data collection
- Exploratory Data Analysis (EDA)
- Advanced analysis using Python and SQL
- Visualization using Tableau

**The ultimate goal** is to understand:
- How different types of banks (traditional vs. digital vs. neobank) respond to ECB rate changes
- How household customers adjust their financial behavior accordingly

## **❓Analysis Questions**
- What is the correlation between the unemployment rate, inflation rate, and the ECB's interest rate policy?
- How quickly do different types of banks react to ECB policy changes?
- How do banks perform when interest rates change?
- Do banks with higher interest rates attract more capital and perform better?
- How do customers adjust their saving, borrowing, and investment behavior in response to interest rate changes?

## **📊Analysis Procedure**
<img src="Dashboard/Data pipeline.png" alt="Dashboard" width="700"/>

-------------------------------------------------------------------------------------------

## **✅ MVP Breakdown-Dashboards**

**1️⃣ Macro layer – ECB & Bundesbank Data**
Understand the broader picture of what happened behind the ECB policy;  Show overall market signals that affect all banks.


**2️⃣ Customer layer – Behavioral trends**
Show how customers shift between saving, borrowing, and investing depending on the rate environment with aggregated bank data


**3️⃣ Bank layer – Traditional vs Digital**
Understand differences in how they react to ECB changes and perform

## **📌Key Takeaways**
### 🧍 Household Financial Behaviors:
- Households primarily adjusted their savings composition, rather than total savings
- Borrowing and investing behaviors were more responsive to rate changes
- Economic context (e.g., inflation, policy, human behavior) often matters more than rates alone

### 🏦Bank Strategy:

- Rate hierarchy (observed): Neobank rate > Digital bank rate > Traditional rate
- High interest rates ≠ guaranteed cash inflow
- Banks differ significantly in their interest rate strategy and reaction speed

## **Limitation & Next Steps**
**Limitation:**
- Some data were not publicly available:
  1. Historical rates by bank
  2. Bank-level saving, borrowing, and investing volume
- Investment data covers bonds and debt securities only
- Focus limited to household customers (not SMEs or corporates)
- Time range limited to 5 years
  
**Next steps:**
  1. Analyze the delta between ECB rates and bank rates
  2. Deep-dive into installment credit and housing loan trends
  3. Expand to include corporate customer behavior
  4. Refine Scope – Focus on Neobanks in Germany


## **📂Data Source**
- Europe Central Bank(ECB) Data Portal
- Deutsche Bundesbank
- Global Rates
- Official site of:
  1. Commerzbank
  2. TradeRepublic
  3. DKB


## **🧰Tech Stack**
- SQL
- Python(Pandas)
- Jupyter Notebook
- Tableau

