select count(*) from Transactions

select count(*) from account_profiles


------ Data Cleaning from both tables ------
-- First cleaning data from account profiles table --
select * into account_profiles_clean from account_profiles

Select count(*) from account_profiles_clean

-- Checking for Duplicate accounts --
select account_id, count (*) from account_profiles_clean
Group by account_id
HAVING count(*)>1; 


-- Checking for missing Values --
Select count (*) "Missing is" from account_profiles_clean
where account_id is Null;

Select count (*) "Missing risk score" from account_profiles_clean
where risk_score is null;

Select count (*) as "missing account type" from account_profiles_clean
where acount_type is Null;

Select count (*) as "Missing credit limit" from account_profiles_clean
where credit_limit is Null;

Select count (*) as "Missing 2fa" from account_profiles_clean
where has_2fa is Null;

-- Validate Risk Scores --
Select * from account_profiles_clean
where risk_score <0 or risk_score >100;

-- Validate Credit Limit --
Select * from account_profiles_clean
where credit_limit <= 0;

-- Validate Account Age --
Select * from account_profiles_clean
where account_age_days < 0;

-- Checking 2fa values --
select distinct has_2fa from account_profiles_clean

-- Checking account type --
Select acount_type, count(*) from account_profiles_clean
group by acount_type
order by count (*) desc;


-- Cleaning data from Transactions table --
select * into transactions_clean from transactions

-- 1. Check total records --
Select count (*) as "total transactions" from transactions_clean 

-- 2. Check duplicate transaction ids --
select transaction_id,count (*) from transactions_clean 
group by transaction_id 
having count(*)>1;

-- 3. Check missing values --
select count(*) from transactions_clean 
where Transaction_id is Null;

select count(*) from transactions_clean 
where account_id is Null;

select count(*) from transactions_clean 
where amount is Null;

select count(*) from transactions_clean 
where merchant_category is Null;

select count(*) from transactions_clean 
where is_fraud is Null;

-- 4. Check negative transaction amount --
select * from transactions_clean
where amount< 0;

-- 5. Validate fraud Indicator --
Select distinct is_fraud from transactions_clean

-- 6. Validate Foreign transaction flag --
Select distinct is_foreign_txn from transactions_clean

-- 7. Validate Card present --
Select distinct card_present from transactions_clean

-- 8. Validate Risk Score -- 
Select distinct ip_risk_score from transactions_clean
where ip_risk_score <0 or ip_risk_score>100;




--- Exploatary analysis of account profiles ---
-- 1. How many accounts are there? --
select count(*)  as "Total accounts" from account_profiles_clean

-- 2. What is Distribution of account types? --
Select acount_type, count(*) as "Accounts" from account_profiles_clean
group by acount_type
order by count (*) desc;

-- 3. How much % accounts use 2fa? --
select round(100*sum(has_2fa)/count(*),2), 
count (*) from account_profiles_clean

-- 4. What is Average Risk Score? --
select avg(risk_score) as "avg risk score" from account_profiles_clean 

-- Range of risk is:
Select max(risk_score), min (risk_score ) from account_profiles_clean

-- 5. How many high risk account exist? --
select is_high_risk, count(*) as "accounts" from account_profiles_clean
group by is_high_risk

-- 6. What is average Credit Limit? --
select avg(credit_limit) as "Avg Credit Limit"
from account_profiles_clean

-- 7. How old are the accounts? --
select avg(account_age_days) as "Avg account age" from account_profiles_clean

select min(account_age_days), max (account_age_days) from account_profiles_clean

-- 8. Relationship Between account type and risk --
Select acount_type, Round(avg(risk_score),2) as "avg_risk_score"
from account_profiles_clean
group by acount_type
order by avg_risk_Score desc;



-- Exploratory Analysis for Transactions --
-- 1. How many transactions have been made? --
Select count(*) from transactions_clean

-- 2. How many Fraud Transactions?  --
Select count(*) from transactions_clean
where is_fraud =1;

-- 3. What is the fraud rate --
Select round(100* sum(is_fraud)/count(*), 2) 
from transactions_clean

-- 4. Total Transaction amount --
Select sum (amount) from transactions_clean

-- 5. What is total fraud amount --
Select sum (amount) from transactions_clean
where is_fraud = 1;

-- 6. Which countries have most fraud --
Select merchant_country, count(*) as"fraud_cases" FROM transactions_clean
where is_FRAUD =1
group by merchant_country
order by fraud_cases desc;

-- 7. Which merchants have most fraud --
select merchant_category, count(*) as "fraud" from transactions_clean
where is_fraud = 1
group by merchant_category
order by Fraud desc;

-- 8. Foreign vs Domestic --
Select is_foreign_txn, sum(is_fraud) as "fraud cases", count(*) from transactions_clean
group by is_foreign_txn

-- 9. Fraud by device type --
select device_type, sum(is_fraud), count(*) from transactions_clean
group by device_type




-- Verifying the Join --
Select count(*) from transactions_clean as "t"
join account_profiles_clean as "a" 
on t.account_id=a.account_id;

-- 1. Does 2FA reduce fraud?--
select a.has_2fa, count (*) as "transactions", 
sum(t.is_fraud) as "Fraud_cases", round(100*sum(t.is_fraud)/count(*),2) as "fraud rate"
from transactions_clean as "t"
join account_profiles_clean as "a" 
on t.account_id=a.account_id
group by a.has_2fa;

-- 2. Which account type has more frauds --
select a.acount_type, count (*) as "transactions", 
sum(t.is_fraud) as "Fraud_cases", round(100*sum(t.is_fraud)/count(*),2) as "fraud rate"
from transactions_clean as "t"
join account_profiles_clean as "a" 
on t.account_id=a.account_id
group by a.acount_type;

-- 3. Do high risk account actually experience more fraud? --
select a.is_high_risk, count (*) as "transactions", 
sum(t.is_fraud) as "Fraud_cases", round(100*sum(t.is_fraud)/count(*),2) as "fraud rate"
from transactions_clean as "t"
join account_profiles_clean as "a" 
on t.account_id=a.account_id
group by a.is_high_risk;

-- 4. Does Account age matter --
Select 
case
	WHEN a.account_age_days <= 365 then 'New'
	when a.account_age_days > 365 and a.account_age_days < 1825 then 'Medium'
	else 'old'
end as "Account",
count(*) as "transaction",
sum(t.is_fraud) as "Fraud_cases"
from transactions_clean as "t"
join account_profiles_clean as "a" 
on t.account_id=a.account_id
group by 
case
	WHEN a.account_age_days <= 365 then 'New'
	when a.account_age_days > 365 and a.account_age_days < 1825 then 'Medium'
	else 'old'
end ; 

-- 5. Does credit limit matter? --
Select 
case
	WHEN a.credit_limit <= 5000 then 'low'
	when a.credit_limit > 5000 and a.credit_limit < 15000 then 'Medium'
	else 'High'
end as "Credit_group",
count(*) as "transaction",
sum(t.is_fraud) as "fraud_cases"
from transactions_clean as "t"
join account_profiles_clean as "a" 
on t.account_id=a.account_id
group by a.Credit_limit,
case
	WHEN a.Credit_limit <= 5000 then 'low'
	when a.Credit_limit > 5000 and a.Credit_limit < 15000 then 'Medium'
	else 'high'
end 
order by fraud_cases desc;

-- 6. Risk Score --
select round(avg(a.risk_score),2) as "avg_account_risk",
round(avg(t.ip_risk_score),2) as "avg_transaction_risk"
from transactions_clean as "t"
join account_profiles_clean as "a"
on t.account_id=a.account_id
where t.is_fraud =1;
