--EDA and Visualization of Earthquake in Indonesia 

--Data Cleaning
--1. find duplicate
--2. check null in time, latitude, longitude, mag, place
--3. separate place into place and country
--4. Separate time column into date & time (extract only the hour)


--Visualization Material
--1. EQ count each region with percentage
--2. EQ count by year
--3. EQ by hour in Indonesia
--4. 
--5. Overall EQ Maps Indonesia
--6. Big EQ Maps Indonesia 

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

--List all the region and its count
SELECT region, count1, 
		ROUND(count1*100.0/counter,3) percentage
FROM (
	SELECT region, COUNT(*) count1, 
			(SELECT COUNT(*) FROM earthquake) counter
	FROM earthquake
	GROUP BY region
)as a
ORDER BY count1 DESC


--EQ by hour in Indonesia
SELECT timehour, COUNT(*)AS eqCount, AVG(mag) avMag,
		MIN(mag) minMage, MAX(mag) maxMag
FROM earthquake
WHERE region IN ('Indonesia', 'Banda Sea', 'off the west coast of northern Sumatra')
GROUP BY timehour
ORDER BY COUNT(*) DESC

--EQ by year in Indonesia
SELECT YEAR(datenew) year, COUNT(*) freq
FROM earthquake
GROUP BY YEAR(datenew)
ORDER BY year

--Preparing Data comparison with other dataset
SELECT datenew, mag, timeonly, place
FROM earthquake
WHERE YEAR(datenew) BETWEEN 2009 AND 2020
ORDER BY datenew desc