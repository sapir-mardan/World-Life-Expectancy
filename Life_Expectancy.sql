# World Life Expectancy Project (Data Cleaning)

SELECT *
FROM world_life_expectancy
;

# How many rows: (just to explore the data a bit
SELECT COUNT(*)
FROM world_life_expectancy;

# 1. Duplicates
# each country should have 1 row per year. 
# First Ill check how many duplicates 

SELECT 
	Country,
    Year,
    COUNT(*) AS duplicates_count
FROM world_life_expectancy
GROUP BY Country, Year
HAVING duplicates_count > 1
;


SELECT Country, Year
FROM world_life_expectancy
GROUP BY Country, Year, CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country, Year)) > 1;

### I identified the countries and duplicate years, now lets see what are theyre Row_ID]

SELECT *
FROM(
	SELECT Row_ID,
	CONCAT(Country, Year),
	ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as row_num
	FROM world_life_expectancy) as row_id
WHERE row_num > 1;

## Now we will delete (making sure we have a backup table)
DELETE FROM world_life_expectancy
WHERE Row_ID IN(
SELECT Row_ID
FROM(
	SELECT Row_ID,
	CONCAT(Country, Year),
	ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as row_num
	FROM world_life_expectancy) as row_id
WHERE row_num > 1
);

## lets double check we have nothing in the output now when we look for duplicates:
SELECT *
FROM(
	SELECT Row_ID,
	CONCAT(Country, Year),
	ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as row_num
	FROM world_life_expectancy) as row_id
WHERE row_num > 1;

# Or by:
SELECT Country, Year, COUNT(*)
FROM world_life_expectancy
GROUP BY Country, Year
HAVING COUNT(*) > 1;

##########################################################################################
##### HANDLING MISSING VALUES ##############################
##########################################################################################

# 2. Handling missing values

# see all columns names:
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = N'world_life_expectancy';

#Check if there are nulls
SELECT *
FROM world_life_expectancy
WHERE Status = "" OR status is NULL;

# check what are the possible values
SELECT DISTINCT Status
FROM world_life_expectancy
;

#I want to make sure each country is ONLY Developing or Developed. If so, Ill fill it accordingly.

# count the distinct statuses for each (not including null obvi)
SELECT Country, COUNT(DISTINCT Status)
FROM world_life_expectancy
WHERE Status <> ""
GROUP BY Country;

# check if there are duplicates, so I subqueried the former query

SELECT *
FROM
(SELECT Country, COUNT(DISTINCT Status) as Status_count
FROM world_life_expectancy
WHERE Status <> ""
GROUP BY Country) as tbl1
WHERE Status_count > 1;

#awesome, each country has 1 status. I can fill now the missing values acconrdingly.


UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country # joining by countries will make sure each blank country will be joined with a country with the wanted status
SET t1.Status = 'Developing' #set the blank to developing
WHERE t1.Status = "" # where it is actually blank from table 1
AND t2.Status = "Developing"; #and it is developing in table 2;

# WHERE the country (1) is blank, and the country (2) is developing, and the country from both (1, 2) is the same (ON t1.Country = t2.Country)


UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country # joining by countries will make sure each blank country will be joined with a country with the wanted status
SET t1.Status = 'Developed'
WHERE t1.Status = ""
AND t2.Status = "Developed";

## Make sure status is filled:
SELECT COUNT(Status)
FROM world_life_expectancy
WHERE Status = "";
# got zero rows (:

SELECT *
FROM world_life_expectancy
WHERE `Life_expectancy` = "" OR `Life_expectancy` IS NULL
;

# I wanted to check how each coutnry is doing so when I did Min() Max() Some countries are missing their values:

# which ones dont have values
SELECT Country, Year, `life_expectancy`
FROM world_life_expectancy
WHERE `life_expectancy` is Null or `life_expectancy` = "";

#mean and median of all data
SELECT Year, AVG(`life_expectancy`)
FROM (SELECT *
	FROM world_life_expectancy
	WHERE `life_expectancy` != 0 and `life_expectancy` IS NOT NULL) AS no_nulls
GROUP BY Year;

SELECT t1.AVG(`life_expectancy`)
FROM world_life_expectancy t1;
#68.94309053778086

#make sure these countries has other values for different years
SELECT Country, Year, `life_expectancy`
FROM world_life_expectancy
WHERE Country IN ('Afghanistan', 'Albania');
#

#NOW LETS FILL IN
SELECT t1.Country, t1.YEAR, t1.`life_expectancy`,
t2.Year as "Year - 1", t2.`life_expectancy`,
t3.Year as "Year + 1", t3.`life_expectancy`
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
WHERE t1.`life_expectancy` is Null or t1.`life_expectancy` = ""
;

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
SET t1.`life_expectancy` = ROUND(((t2.`life_expectancy` + t3.`life_expectancy`) / 2), 2)
WHERE t1.`life_expectancy` is Null or t1.`life_expectancy` = ""
;

SELECT AVG(t1.`life_expectancy`), AVG(t2.`life_expectancy`)
FROM world_life_expectancy t1
JOIN world_life_expectancy_backup t2
ON t1.Country = t2.Country;




##############################
# 2. Exploratory Data Analysis
##############################

# 1. Which country is doing best? lets check min and max

Select *
FROM world_life_expectancy; 

# which country increaed their avg life expectency during the 15 years
Select Country, 
MIN(`Life_expectancy`), 
MAX(`Life_expectancy`), 
ROUND(MAX(`Life_expectancy`) - MIN(`Life_expectancy`),1) AS 'life_increase_15_years'
FROM world_life_expectancy
GROUP BY Country
HAVING MAX(`Life_expectancy`) != 0 
AND MIN(`Life_expectancy`) != 0
ORDER BY life_increase_15_years
;

# Now lets look at the year
SELECT Year, ROUND(AVG(`Life_expectancy`), 2)
FROM world_life_expectancy
WHERE `Life_expectancy` != 0 #JUST INCASE cause zero value will really lower the AVG
GROUP BY Year
ORDER BY Year
;

### Corelations between life expectancy and other fields
Select *
FROM world_life_expectancy; 

SELECT Country,
ROUND(AVG(`Life_expectancy`), 1) AS Life_EXP,
ROUND(AVG(GDP), 1) AS GDP
FROM world_life_expectancy
GROUP BY Country
HAVING Life_EXP > 0
AND GDP > 0
ORDER BY GDP
; 
# we can see that lower GDP on average, leads to lower Life expectancy when 
#comparing to the total avg;

SELECT AVG(GDP), AVG(`Life_expectancy`)
FROM world_life_expectancy
;
# so below 68.9 is considered low

### 1. check the coralation between life exoectancy and GDP

SELECT 
(SELECT ROUND(AVG(`Life_expectancy`),2)
FROM world_life_expectancy) AS AVG_LIFE_EXP,
(SELECT ROUND(AVG(`GDP`),2)
FROM world_life_expectancy) AS AVG_GDP,
ROUND(AVG(CASE 
		WHEN `GDP` >= (SELECT AVG(`GDP`) 
									FROM world_life_expectancy)
		THEN `Life_expectancy`
		ELSE NULL 
	END), 2) AS HIGHER_GDP_LifeEXP,
ROUND(AVG(CASE
		WHEN `GDP` < (SELECT AVG(`GDP`)
								  FROM world_life_expectancy)
		THEN `Life_expectancy` 
        ELSE NULL
	END), 2) AS LOWER_GDP_LifeEXP
FROM world_life_expectancy
; 


#### 2. check the coralation between life exoectancy and Status

SELECT 
ROUND(AVG(CASE WHEN `Status` = 'Developing' THEN Life_expectancy ELSE NULL END), 2)AS Developing_LifeEXP,
ROUND(AVG(CASE WHEN Status = 'Developed' THEN Life_expectancy ELSE NULL END), 2) AS Developed_LifeEXP
FROM world_life_expectancy
;

## OR (Easier.....):

SELECT Status, ROUND(AVG(Life_expectancy), 2), COUNT(DISTINCT Country)
FROM world_life_expectancy
GROUP BY Status
;


## what about BMI
SELECT 
    Country,
    ROUND(AVG(`Life_expectancy`), 1) AS Life_Exp,
    ROUND(AVG(BMI), 1) AS BMI
FROM world_life_expectancy
GROUP BY Country
HAVING Life_Exp > 0
   AND BMI > 0
ORDER BY BMI ASC;









