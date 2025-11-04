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






