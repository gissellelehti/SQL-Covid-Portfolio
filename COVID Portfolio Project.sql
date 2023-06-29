-- Retrieve and see data from COVID Deaths table

select * 
From [Portfolio Project]..CovidDeaths
where continent is not null
order by 3,4


-- Retrieve and see data from COVID Vaccinations table

select * 
From [Portfolio Project]..CovidVaccinations
where continent is not null
order by 3,4


-- Select Data that will be used 

select location, date, total_cases, new_cases, total_deaths, population
From [Portfolio Project]..CovidDeaths
where continent is not null
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying of COVID in Finland

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
From [Portfolio Project]..CovidDeaths
where location like 'Finland'
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population got COVID in Finland

select location, date, population, total_cases, (total_cases/population)*100 as infected_pop_percentage 
From [Portfolio Project]..CovidDeaths
where location like 'Finland'
order by 1,2


-- Countries with Highest Infection rate vs Population

select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as infected_pop_percentage 
From [Portfolio Project]..CovidDeaths
where continent is not null
group by location, population
order by infected_pop_percentage desc


-- Countries with Highest death count per Population

select location, MAX(cast(total_deaths as int)) as total_death_count 
-- because the column values of total deaths are nvarchar, it needs to be converted to an int to properly calculate the max
From [Portfolio Project]..CovidDeaths
where continent is not null
group by location
order by total_death_count desc


-- Continents and Regional Associations with Highest death count per Population

select location, MAX(cast(total_deaths as int)) as total_death_count
From [Portfolio Project]..CovidDeaths
where continent is null
group by location
order by total_death_count desc


-- GLOBAL NUMBERS
-- World cases, deaths, death percentage by day
select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100  as death_percentage 
From [Portfolio Project]..CovidDeaths
where continent is not null
group by date
order by 1,2

-- Overall cases, deaths, death percentage
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100  as death_percentage 
From [Portfolio Project]..CovidDeaths
where continent is not null
order by 1,2



-- Join COVID deaths and vaccination tables

select * 
from [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date


-- Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Total Population vs Vaccinations with Rolling Sum of Vaccinations per Country

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as rolling_vaccinations
from [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- USE CTE

with PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinations)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as rolling_vaccinations
from [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
)
select *, (rolling_vaccinations/population)*100 as vaccinated_percentage
from PopvsVac


-- Creating a temp table
-- if the table needs to be remade run the following
-- DROP Table if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric, 
rolling_vaccinations numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as rolling_vaccinations
from [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null


-- Country Population, Vaccinations and Vaccinated Percentage

select location, max(population) as population, max(new_vaccinations) as new_vaccinations, max(rolling_vaccinations) as rolling_vaccinations, 
Max(rolling_vaccinations/population*100) as vaccinated_percentage
from #PercentPopulationVaccinated
group by location
order by 1



-- Creating views to store data for future visualizations

-- Percent Population Vaccinated VIEW

Create View Percent_Population_Vaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as rolling_vaccinations
from [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null

-- Testing Percent_Popoulation_Vaccinted view

select * from Percent_Population_Vaccinated


-- Continents and Regional Associations with Highest death count per Population VIEW

Create view Continent_Regions_Death_Count as
select location, MAX(cast(total_deaths as int)) as total_death_count
From [Portfolio Project]..CovidDeaths
where continent is null
group by location


-- Testing Continent_Regions_Death_Count view

select * from Continent_Regions_Death_Count
