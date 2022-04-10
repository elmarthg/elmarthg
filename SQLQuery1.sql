select Location, date, total_cases, new_cases, total_deaths, population
from master..CovidDeaths
order by 1,2



-- Death Percentage

select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
from master..CovidDeaths
order by 1,2

select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Rate
from master..CovidDeaths
where location like '%states%'
order by 1,2

select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Rate
from master..CovidDeaths
where location like '%Philippines%'
order by 1,2

-- Total Cases vs Population

select Location, date, population, total_cases, (total_cases/population)*100 as Infection_Rate
from master..CovidDeaths
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From master..CovidDeaths
Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From master..CovidDeaths
Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From master..CovidDeaths
Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as bigint)) as TotalDeathCount
From master..CovidDeaths
Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From master..CovidDeaths
Where location like '%states%'
where continent is not null 
Group By date
order by 1,2

-------------------


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

                                                                                                                                                                                                                                                                                       

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population)*100
From master..CovidDeaths dea
Join master..CovidVax vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #ercentPopulationVaccinated
Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
RollingPeopleVaccinated numeric
)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population)*100
From master..CovidDeaths dea
Join master..CovidVax vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null /                 

Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     




-- Creating View to store data for later visualizations



Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population)*100
From master..CovidDeaths dea
Join master..CovidVax vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 



SELECT LOCATION, SUM(cast(new_deaths as bigint)) as TotalDeathCount
FROM master..CovidDeaths
Where continent is null
and location  not in ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'low income')
Group by location
order by TotalDeathCount desc

select location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
from master..CovidDeaths
Group by location, population
order by PercentPopulationInfected desc

SELECT location, population, date, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from master..CovidDeaths
group by location, population, date
order by PercentPopulationInfected desc






                                                                                                                                                                                              
