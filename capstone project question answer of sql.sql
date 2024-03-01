create database capstone_project;

-- Q.1) Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)

   SELECT
        CustomerID,
		 EstimatedSalary,Bank_DOJ,
        ROW_NUMBER() OVER (ORDER BY EstimatedSalary DESC) AS SalaryRank
    FROM
        CustomerInfo ;


        
-- Q.2)Calculate the average number of products used by customers who have a credit card. (SQL)

SELECT AVG(NumOfProducts) AS AvgProducts
FROM bank_churn 
WHERE HasCrCard = 1;


-- Q.3)Compare the average credit score of customers who have exited and those who remain. (SQL)

SELECT Exited, AVG(CreditScore) AS AvgCreditScore
FROM Bank_Churn
GROUP BY Exited;


-- Q.4)Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)

SELECT GenderCategory, Round(AVG(EstimatedSalary),2) AS AvgSalary, ActiveCategory
FROM CustomerInfo
JOIN Gender ON CustomerInfo.GenderID = Gender.GenderID
JOIN bank_churn ON CustomerInfo.CustomerId = bank_churn.CustomerId
join activecustomer on activecustomer.ActiveID= bank_churn.HasCrCard
GROUP BY GenderCategory, ActiveCategory;


-- Q.5)Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)
WITH CreditScoreSegments AS (
    SELECT
        CustomerId,exited,
        CASE
            WHEN CreditScore >= 800 AND CreditScore <= 850 THEN 'Excellent'
            WHEN CreditScore >= 740 AND CreditScore <= 799 THEN 'Very Good'
            WHEN CreditScore >= 670 AND CreditScore <= 739 THEN 'Good'
            WHEN CreditScore >= 580 AND CreditScore <= 669 THEN 'Fair'
            WHEN CreditScore >= 300 AND CreditScore <= 579 THEN 'Poor'
            ELSE 'Unknown'
        END AS CreditScoreSegment
    FROM
        Bank_Churn
)
, ExitRates AS (
    SELECT
        CreditScoreSegment,
        round(AVG(CAST(Exited AS FLOAT)),4) AS ExitRate
    FROM
        CreditScoreSegments
    GROUP BY
        CreditScoreSegment
)
SELECT  
     CreditScoreSegment,
    ExitRate
FROM
    ExitRates
ORDER BY
    ExitRate DESC
    limit 1;


-- Q.6)Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)

WITH ActiveCustomersWithTenure AS (
    SELECT
        CI.GeographyID,
        COUNT(*) AS ActiveCustomerCount
    FROM
        CustomerInfo CI
    JOIN
       bank_churn BC
       ON CI.CustomerId = BC.CustomerId
    join  ActiveCustomer AC 
       ON BC.IsActiveMember = AC.ActiveID

    WHERE
        AC.ActiveCategory = 'Active Member'
        AND BC.Tenure > 5
    GROUP BY
        CI.GeographyID
)
SELECT 
    GeographyID,
    ActiveCustomerCount
FROM
    ActiveCustomersWithTenure
ORDER BY
    ActiveCustomerCount DESC
    LIMIT 1;



-- Q.7)Examine the trend of customer joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.

        

   
WITH YearlyJoiningTrend AS (
    SELECT
        YEAR(Bank_DOJ) AS JoiningYear,
        COUNT(*) AS JoiningCount
    FROM
        CustomerInfo
    GROUP BY
        YEAR(Bank_DOJ)
)

SELECT
    'Yearly' AS TrendType,
    CAST(JoiningYear AS DATE) AS TrendDate,
    JoiningCount
FROM
    YearlyJoiningTrend;




-- Q.8) Using SQL, write a query to find out the gender wise average income of male and female in each geography id. Also rank the gender according to the average value. (SQL)
with cte as (SELECT GenderCategory, GeographyID, ROUND(AVG(EstimatedSalary),2) AS AvgIncome

FROM CustomerInfo
JOIN Gender ON CustomerInfo.GenderID = Gender.GenderID
GROUP BY GenderCategory, GeographyID
ORDER BY AvgIncome DESC)
select GenderCategory, GeographyID, AvgIncome,
dense_rank()over(partition by GenderCategory order by  AvgIncome desc) as rnk
from cte ;



-- Q.9)Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).
SELECT 
  CASE 
    WHEN Age BETWEEN 18 AND 30 THEN '18-30'
    WHEN Age BETWEEN 31 AND 50 THEN '30-50'
    WHEN Age > 50 THEN '50+'
  END AS AgeBracket,
  AVG(Tenure) AS AvgTenure
FROM CustomerInfo
JOIN Bank_Churn ON CustomerInfo.CustomerId = Bank_Churn.CustomerId
WHERE Exited = 1
GROUP BY AgeBracket;



-- Q.10)Rank each bucket of credit score as per the number of customers who have churned the bank.
WITH CreditScoreBuckets AS (
    SELECT
        CASE
            WHEN CreditScore >= 800 AND CreditScore <= 850 THEN 'Excellent'
            WHEN CreditScore >= 740 AND CreditScore <= 799 THEN 'Very Good'
            WHEN CreditScore >= 670 AND CreditScore <= 739 THEN 'Good'
            WHEN CreditScore >= 580 AND CreditScore <= 669 THEN 'Fair'
            WHEN CreditScore >= 300 AND CreditScore <= 579 THEN 'Poor'
            ELSE 'Unknown'
        END AS CreditScoreBucket,
        COUNT(*) AS ChurnedCustomers
    FROM
        Bank_Churn
    WHERE
        Exited = 1
    GROUP BY
        CreditScoreBucket
)
SELECT
    CreditScoreBucket,
    ChurnedCustomers,
    RANK() OVER (ORDER BY ChurnedCustomers DESC) AS Rnk
FROM
    CreditScoreBuckets
ORDER BY
    Rnk;


-- Q.11) According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets who have lesser than average number of credit cards per bucket.
 SELECT 
  CASE 
    WHEN Age BETWEEN 18 AND 30 THEN '18-30'
    WHEN Age BETWEEN 31 AND 50 THEN '30-50'
    WHEN Age > 50 THEN '50+'
  END AS AgeBucket,
  COUNT(*) AS CreditCardCount
FROM CustomerInfo
join bank_churn
on customerinfo.CustomerId= bank_churn.CustomerId
WHERE HasCrCard = 1
GROUP BY AgeBucket;


-- Q.12) Rank the Locations as per the number of people who have churned the bank and average balance of the learners.

SELECT GeographyLocation, COUNT(*) AS ChurnCount,round(AVG(Balance),2) AS AvgBalance
FROM CustomerInfo
JOIN Geography ON CustomerInfo.GeographyID = Geography.GeographyID
JOIN Bank_Churn ON CustomerInfo.CustomerId = Bank_Churn.CustomerId
WHERE Exited = 1
GROUP BY GeographyLocation
ORDER BY ChurnCount DESC, AvgBalance DESC;

-- Q.13) Utilize SQL queries to segment customers based on demographics, account details, and transaction behaviors. 
SELECT
    CustomerId,
    NumOfProducts,
    CASE
        WHEN NumOfProducts = 1 THEN 'Single Product User'
        WHEN NumOfProducts = 2 THEN 'Two Products User'
        WHEN NumOfProducts > 2 THEN 'Multi-Products User'
        ELSE 'Unknown'
    END AS ProductSegment
FROM
    bank_churn;


