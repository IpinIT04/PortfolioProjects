use PortfolioProject

-- Edit CovidDeathsFixed table: only include countries in location field, not continents
create view [CovidDeathsFixed] as
select * 
from CovidDeaths
where continent is not null

select * from [CovidDeathsFixed]
order by 3,4

-- Select Data that we are going to be using
create view [MainData] as
select 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths,
	new_deaths,
	population
from [CovidDeathsFixed]

select * from MainData
order by 1,2

-- Shows death percentage as covid infection in any country
select 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	cast(total_deaths as float) / nullif(cast(total_cases as float), 0)*100 as death_percentage
from MainData
order by 1,2


-- Looking at Total_Cases vs Population
-- Shows what percentage of population got Covid
select 
	location, 
	date, 
	total_cases, 
	new_cases,
	population,
	cast(total_cases as float) / nullif(cast(population as float), 0)*100 as Incidence
from MainData
where location like '%viet%' and total_cases is not null
order by 1,2


-- Percent Population Infected (Tableau Table 4)
select 
	location,
	population,
	date,
	max(cast(total_cases as int)) as HighestInfectionCount,
	replace(max(cast(total_cases as float)) / nullif(population, 0)*100, ',','.') as HighestInfectionRate
from MainData
group by location, population, date


-- Looking at Countries with highest infection rate compared to population (Tableau Table 3)
select 
	location,
	population,
	max(cast(total_cases as int)) as HighestInfectionCount,
	max(cast(total_cases as float)) / nullif(population, 0)*100 as HighestInfectionRate
from MainData
group by location, population
order by HighestInfectionRate desc

-- Showing Countries with Highest Death Count per Population
select 
	continent,
	location,
	population,
	max(cast(total_deaths as int)) as HighestDeathTotal,
	max(cast(total_deaths as float)) / nullif(population, 0) as HighestDeathsPercentage
from CovidDeathsFixed
group by continent, location, population
order by HighestDeathsPercentage desc


-- Shows highest death count in continents
select 
	continent as Continents,
	max(cast(total_deaths as int)) as HighestDeathTotal,
	max(cast(total_deaths as float) / nullif(cast(population as float), 0)) as HighestDeathsPercentage
from CovidDeathsFixed
group by continent
order by HighestDeathsPercentage desc


-- Shows total_cases with total_deaths in each continent (Tableau Table 2)
select 
	continent, 
	sum(cast(new_cases as int)) as TotalCases, 
	sum(cast(new_deaths as int)) as TotalDeaths
from CovidDeathsFixed
group by continent
order by 1


-- GLOBAL NUMBERS ( USE CTE )
with GLOBAL_NUMBERS as
(
	select
		date,
		sum(cast(new_cases as int)) as TotalNewCases,
		sum(cast(new_deaths as int)) as TotalNewDeaths
	from MainData
	group by date
)
select 
	sum(TotalNewCases) as GlobalCasesTotal,
	sum(TotalNewDeaths) as GlobalDeathsTotal,
	cast(sum(TotalNewDeaths) as float) / nullif(cast(sum(TotalNewCases) as float), 0) as DeathPercentage
from GLOBAL_NUMBERS


-- Fast way (Global numbers) - Tableau Table 1
select 
	sum(cast(new_cases as int)) as GlobalCasesTotal,
	sum(cast(new_deaths as int)) as GlobalDeathsTotal,
	convert(float, sum(cast(new_deaths as int))) / nullif(sum(cast(new_cases as int)), 0) as DeathPercentage
from MainData


-------------------------------------------
create view [CovidVaccinationsFixed] as
select * 
from CovidVaccinations
where continent is not null

select * from CovidVaccinationsFixed
order by 3, 4

-- USE CTE
with Pop_Vaccinated (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) as 
(
	select 
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.date) as RollingPeopleVaccinated
	from CovidDeathsFixed dea
	join CovidVaccinationsFixed vac
	on dea.location = vac.location
		and dea.date = vac.date
)
select *, (RollingPeopleVaccinated / population)*100 as PercentagePeopleVaccinated
from Pop_Vaccinated




