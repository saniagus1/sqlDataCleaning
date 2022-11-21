/*
Data Cleaning in SQL

Name : Gede Agus Andika Sani
Date : 18/11/2022
*/

SELECT *
FROM housedata

--1. Standardize datetime format


--Remove time in the current SaleDate column
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM housedata

ALTER TABLE housedata
Add SaleDateNew Date;

UPDATE housedata
SET SaleDateNew = CONVERT(Date, SaleDate)


--2. Fill an empty Property Address


--Self Join the Table to find address of a similar ParcelID
--(Same ParcelID has a same Address)
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM housedata a
JOIN housedata b
 ON a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

--Update the data after confirming the result above
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM housedata a
JOIN housedata b
 ON a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ]



--3. Splitting the Property Address into individual column (Address & City)

--Using SUBSTRING
SELECT PropertyAddress
FROM housedata

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
		SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City
FROM housedata

ALTER TABLE housedata
Add PropertySplitAddress NvarChar(255);

UPDATE housedata
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)


ALTER TABLE housedata
Add PropertySplitCity NvarChar(255);

UPDATE housedata
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))



--4. Splitting the Owner Address into Address, City, State
SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)
FROM housedata


ALTER TABLE housedata
Add OwnerSplitAddress NvarChar(255);

UPDATE housedata
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)


ALTER TABLE housedata
Add OwnerSplitCity NvarChar(255);

UPDATE housedata
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)


ALTER TABLE housedata
Add OwnerSplitState NvarChar(255);

UPDATE housedata
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)




--5. Change Y into Yes and N into No in Sold as Vacant Column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM housedata
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM housedata


Update housedata
SET SoldAsVacant = 
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END


--6. Removing Duplicates

--Altough having different UniqueID, these item considered duplicate
--because having the same value for other column

WITH duplicate_checker AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SaleDate,
				SalePrice,
				LegalReference
				ORDER BY 
					UniqueID) AS row_num	
FROM housedata)

SELECT *
FROM duplicate_checker
WHERE row_num>1




--7. Delete Unused Column

--Delete PropertyAddress and OwnerAddress from the Table
ALTER TABLE housedata
DROP COLUMN OwnerAddress, PropertyAddress
