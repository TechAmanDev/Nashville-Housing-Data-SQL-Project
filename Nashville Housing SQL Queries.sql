USE housing;

-- Updating Date into standard format --

SELECT * FROM housing_table;
SELECT STR_TO_DATE(SaleDate, '%M %d, %Y') from housing_table;

SET SQL_SAFE_UPDATES =0;
UPDATE housing_table
SET SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');

-- Finding and filling empty PrpertyAddress --

SELECT * FROM housing_table
WHERE PropertyAddress IS NULL;

UPDATE housing_table
SET PropertyAddress = NULL
WHERE PropertyAddress = "";

SELECT a.ParcelID, 
		a.PropertyAddress, 
        b.ParcelID, 
        b.PropertyAddress, 
        IFNULL(a.PropertyAddress,b.PropertyAddress) 
FROM housing_table AS a
JOIN housing_table AS b
ON a.ParcelID = b.ParcelID
AND  a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE housing_table AS a 
JOIN housing_table AS b
	ON a.ParcelID = b.ParcelID
	AND  a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress,b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- Breaking PropertyAddress and owner Address --

SELECT SUBSTRING_INDEX(PropertyAddress,',',1) AS splitAddress,
		SUBSTRING_INDEX(PropertyAddress,',',-1) AS splitCity 
FROM housing_table;

ALTER TABLE housing_table
ADD splitAddress NVARCHAR(255);

ALTER TABLE housing_table
ADD splitCity NVARCHAR(255);

UPDATE housing_table
SET splitAddress = SUBSTRING_INDEX(PropertyAddress,',',1), 
	splitCity = SUBSTRING_INDEX(PropertyAddress,',',-1);

UPDATE housing_table
SET OwnerAddress = NULL
WHERE OwnerAddress = "";

SELECT OwnerAddress, 
		SUBSTRING_INDEX(OwnerAddress,',',-1),
		SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',-2),',',1), 
        SUBSTRING_INDEX(OwnerAddress,',',1) FROM housing_table;

ALTER TABLE housing_table
ADD splitOwnerAddress VARCHAR(255);

UPDATE housing_table
SET splitOwnerAddress = SUBSTRING_INDEX(OwnerAddress,',',1);

ALTER TABLE housing_table
ADD splitOwnerCity VARCHAR(255);

UPDATE housing_table
SET splitOwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',-2),',',1);

ALTER TABLE housing_table
ADD splitOwnerState NVARCHAR(255);

UPDATE housing_table
SET splitOwnerState = SUBSTRING_INDEX(OwnerAddress,',',-1);

-- Replace Y with Yes and N with No --

SELECT SoldAsVacant,
CASE WHEN  SoldAsVacant = "Y" THEN "Yes"
	WHEN SoldAsVacant = "N" THEN "No"
     ELSE SoldAsVacant
     END
     FROM housing_table;

UPDATE housing_table
SET SoldAsVacant = CASE WHEN  SoldAsVacant = "Y" THEN "Yes"
	WHEN SoldAsVacant = "N" THEN "No"
     ELSE SoldAsVacant
     END;

SELECT DISTINCT(SoldAsVacant), 
				COUNT(SoldAsVacant) 
FROM housing_table
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT * FROM housing_table;

CREATE TEMPORARY TABLE temp_housing
SELECT * FROM (
	SELECT *,ROW_NUMBER() OVER (PARTITION BY ParcelID,LandUse,PropertyAddress,SaleDate,SalePrice,OwnerName) AS rn 
    FROM housing_table AS hs) AS hs
WHERE rn =1;

-- DELETE UNUSED COLUMN--

ALTER TABLE temp_housing
 DROP COLUMN rn;

ALTER TABLE temp_housing
DROP COLUMN PropertyAddress;

ALTER TABLE temp_housing
DROP COLUMN OwnerAddress;

ALTER TABLE temp_housing
DROP COLUMN TaxDistrict;

ALTER TABLE temp_housing
DROP COLUMN SaleDate;

SELECT * FROM temp_housing;

DROP TABLE temp_housing;

-- End of Task --
