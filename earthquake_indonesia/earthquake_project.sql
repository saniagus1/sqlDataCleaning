--Earthquake in Indonesia


--DATA PRE PROCESSING PART
--USGS DATA

--Data Cleaning
--1. find duplicate
--2. check null in time, latitude, longitude, mag, place
--3. separate place into place and country
--4. Separate time column into date & time (extract only the hour)

--find duplicate from id
SELECT id, COUNT(*)
FROM earthquake
GROUP BY id
HAVING COUNT(*)>1


--find duplicate from other column
SELECT time, latitude, longitude, mag, place, COUNT(*)
FROM earthquake
GROUP BY time, latitude, longitude, mag, place
HAVING COUNT(*)>1

--2. check null
SELECT COUNT(*)
FROM earthquake
WHERE dmin is null

--Separate date+time into separated column
--extract hour from date
SELECT time, 
		CONVERT(Date, time) AS Date,
		PARSENAME(REPLACE(time, 'T', '.'),2) AS Time,
		DATEPART(hour FROM timeonly)
FROM earthquake

ALTER TABLE earthquake
Add datenew Date;

UPDATE earthquake
SET datenew = CONVERT(Date, time)

ALTER TABLE earthquake
Add timeonly time;

UPDATE earthquake
SET timeonly = PARSENAME(REPLACE(time, 'T', '.'),2)

ALTER TABLE earthquake
Add timehour int;

UPDATE earthquake
SET timehour = DATEPART(hour FROM timeonly)


--separate the country from place
SELECT place, 
		PARSENAME(REPLACE(place, ',', '.'),1),
		TRIM(' ' FROM PARSENAME(REPLACE(place, ',', '.'),1))
FROM earthquake


ALTER TABLE earthquake
Add region NvarChar(255);

UPDATE earthquake
SET region = TRIM(' ' FROM PARSENAME(REPLACE(place, ',', '.'),1))


--Preparing Data comparison with BMKG dataset
SELECT datenew, mag, timeonly, place
FROM earthquake
WHERE YEAR(datenew) BETWEEN 2009 AND 2020
ORDER BY datenew desc


---------------------
--BMKG DATA CLEANING

--Data Cleaning
--1. find duplicate
--2. check null 
--3. convert tgl into date only
--4.convert ot into time only and extract only the hour


SELECT *
FROM bmkg_earthquake
--89218 rows found
--86616 rows after duplicate deletion

--Finding duplicate
SELECT tgl, ot, lat, lon, mag, COUNT(*)
FROM bmkg_earthquake
GROUP BY tgl, ot, lat, lon, mag
HAVING COUNT(*)>1
ORDER BY tgl
--detected 2602 duplicate

--Delete duplicate using CTE
WITH duplicate_detector AS(
	SELECT tgl, ot, lat, lon, mag,
			ROW_NUMBER() OVER (PARTITION BY tgl, ot, lat, lon, mag
			ORDER BY tgl, ot, lat, lon, mag) ranking
	FROM bmkg_earthquake

)
--SELECT *
--FROM duplicate_detector
--WHERE ranking>1
--ORDER BY tgl

DELETE FROM duplicate_detector
WHERE ranking>1

--Check null value
--Change column name in the second bracket
SELECT COUNT(*)-COUNT(mag)
FROM bmkg_earthquake
--No null value found

--Another way of checking null
--change column name in WHERE statement
SELECT *
FROM bmkg_earthquake
WHERE mag is NULL

--Remove time from tgl
SELECT tgl, CONVERT(Date, tgl) tglnew
FROM bmkg_earthquake

ALTER TABLE bmkg_earthquake
ADD tglonly Date;

UPDATE bmkg_earthquake
SET tglonly = CONVERT(Date, tgl)

--Remove date from ot
SELECT ot, CONVERT(time, ot) timenew
FROM bmkg_earthquake

ALTER TABLE bmkg_earthquake
ADD timeonly time;

UPDATE bmkg_earthquake
SET timeonly = CONVERT(time, ot)

--Extract hour only 
SELECT timeonly, DATEPART(hour FROM timeonly)
FROM bmkg_earthquake

ALTER TABLE bmkg_earthquake
ADD timehour int;

UPDATE bmkg_earthquake
SET timehour = DATEPART(hour FROM timeonly)

SELECT *
FROM earthquake

SELECT *
FROM bmkg_earthquake

--CREATE merged table to store the data
--filtered for Indonesian region only
CREATE TABLE indonesia_earthquake_full(
	date date,
	time time,
	timehour int,
	latitude float,
	longitude float,
	mag float,
	place nvarchar(255)
)

--USGS Data for new table
SELECT datenew, timeonly, timehour, latitude, longitude, mag, place
FROM earthquake
WHERE region IN ('Indonesia','Banda Sea', 'off the west coast of northern Sumatra',
				'Molucca Sea', 'Flores Sea', 'Arafura Sea', 'Bali Sea') AND
	datenew BETWEEN '2000/01/01' AND '2008/10/31' AND
	mag>2.9
ORDER BY datenew

--BMKG Data for new Table
SELECT tglonly, timeonly, timehour, lat, lon, mag, remark
FROM bmkg_earthquake
WHERE mag>2.9

--INSERT USGS into new table 
INSERT INTO indonesia_earthquake_full
SELECT datenew, timeonly, timehour, latitude, longitude, mag, place
FROM earthquake
WHERE region IN ('Indonesia','Banda Sea', 'off the west coast of northern Sumatra',
				'Molucca Sea', 'Flores Sea', 'Arafura Sea', 'Bali Sea') AND
	datenew BETWEEN '2000/01/01' AND '2008/10/31' AND
	mag>2.9
ORDER BY datenew


----INSERT BMKG into new table
INSERT INTO indonesia_earthquake_full
SELECT tglonly, timeonly, timehour, lat, lon, mag, remark
FROM bmkg_earthquake
WHERE mag>2.9


---EDA PART

SELECT COUNT(*)
FROM indonesia_earthquake_full
WHERE date BETWEEN '2008/11/01' AND '2022/10/31'
--ORDER BY date DESC

SELECT COUNT(mag)
FROM indonesia_earthquake_full
WHERE date BETWEEN '2008/11/01' AND '2022/10/31'
		AND mag<2.8
--WHERE date BETWEEN '2000/01/01' AND '2008/10/31'

--List all the region and its count (USGS)
SELECT region, count1, 
		ROUND(count1*100.0/counter,3) percentage
FROM (
	SELECT region, COUNT(*) count1, 
			(SELECT COUNT(*) FROM earthquake) counter
	FROM earthquake
	GROUP BY region
)as a
ORDER BY count1 DESC


--EQ by year in Indonesia
SELECT YEAR(date) year, COUNT(*) freq
FROM indonesia_earthquake_full
GROUP BY YEAR(date)
ORDER BY year


--EQ by hour in Indonesia
SELECT timehour, COUNT(*)AS freq, ROUND(AVG(mag),2) avMag,
		MAX(mag) maxMag
FROM indonesia_earthquake_full
GROUP BY timehour
ORDER BY freq DESC

--EQ by days of the week
SELECT DATENAME(WEEKDAY, date) AS hari, COUNT(*) freq
FROM indonesia_earthquake_full
GROUP BY DATENAME(WEEKDAY, date)
ORDER BY freq DESC


--Earthquake by Magnitude
WITH eqcategory AS(
SELECT CASE
			WHEN mag BETWEEN 3.0 AND 3.9 THEN 'micro'
			WHEN mag BETWEEN 4.0 AND 4.9 THEN 'light'
			WHEN mag BETWEEN 5.0 AND 5.9 THEN 'moderate'
			WHEN mag BETWEEN 6.0 AND 6.9 THEN 'strong'
			WHEN mag BETWEEN 7.0 AND 7.9 THEN 'major'
			ELSE 'great'
	   END AS category
FROM indonesia_earthquake_full)
SELECT category, COUNT(*) freq
FROM eqcategory
GROUP BY category
ORDER BY freq DESC


--Earthquake Maps
SELECT *
FROM indonesia_earthquake_full
ORDER BY date 
