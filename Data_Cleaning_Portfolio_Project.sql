use PortfolioProject


-- Select Data 
select *
from NashvilleHousing



-- Convert SaleDate to date datatype
select SaleDateConverted
from PortfolioProject.dbo.NashvilleHousing

alter table NashvilleHousing
add SaleDateConverted date

update NashvilleHousing
set SaleDateConverted = convert(date, SaleDate)



-- Populate Property Address data
select a.[UniqueID ], a.PropertyAddress, a.ParcelID, b.ParcelID, b.[UniqueID ], isnull(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
join NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

update a
set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
join NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]

select PropertyAddress
from NashvilleHousing




-- Separate PropertyAddress -> PropertySplitAddress + PropertySplitCity
alter table NashvilleHousing 
add PropertySplitAddress varchar(255), PropertySplitCity varchar(255)

update NashvilleHousing
set PropertySplitAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress) - 1),
PropertySplitCity = substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress))




-- Separate OwnerAddress -> OwnerSplitAddress + OwnerSplitCity + OwnerSplitState
select OwnerAddress
from NashvilleHousing

select
PARSENAME(replace(OwnerAddress, ',', '.'), 1),
PARSENAME(replace(OwnerAddress, ',', '.'), 2),
PARSENAME(replace(OwnerAddress, ',', '.'), 3)
from NashvilleHousing

alter table NashvilleHousing
add OwnerSplitAddress varchar(255), OwnerSplitCity varchar(255), OwnerSplitState varchar(255)

update NashvilleHousing
set OwnerSplitAddress = PARSENAME(replace(OwnerAddress, ',', '.'), 3),
OwnerSplitCity = PARSENAME(replace(OwnerAddress, ',', '.'), 2),
OwnerSplitState = PARSENAME(replace(OwnerAddress, ',', '.'), 1)




-- Change Y and N to Yes and No in "SoldAsVacant" field
update NashvilleHousing
set SoldAsVacant = 
case 
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
end

select distinct(SoldAsVacant), count(SoldAsVacant)
from NashvilleHousing
group by SoldAsVacant




-- Remove Duplicates
with RowNumCTE as (
	select *,
		ROW_NUMBER() over(
		partition by ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 order by 
					 UniqueID ) row_num
	from NashvilleHousing
)
delete
from RowNumCTE
where row_num > 1




-- Delete Unused Columns
alter table NashvilleHousing
drop column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
