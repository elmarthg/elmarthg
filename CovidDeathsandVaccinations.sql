select *
From PortfolioProject..CovidDeaths
order by 3,4

--select *
--From PortfolioProject..CovidVaccination
--order by 3,4


SELECT Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2



--Total Cases vs Total Deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%States%'
order by 1,2

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where Location = 'Philippines' 
order by 1,2

--Countries with Highest Infection Rate

SELECT Location, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
group by Location, Population
order by PercentPopulationInfected desc

--Countries with Highest DeathCount and DeathRate

SELECT Location, MAX(cast(total_deaths as bigint)) as TotalDeathCount, Max((total_deaths/population))*100000 as DeathRate
From PortfolioProject..CovidDeaths
where continent is not null
group by Location
order by TotalDeathCount desc

SELECT location, MAX(cast(total_deaths as bigint)) as TotalDeathCount, Max((total_deaths/population))*100000 as DeathRate
From PortfolioProject..CovidDeaths
where continent is null
group by Location
order by TotalDeathCount desc

--Group by Continent

SELECT continent, MAX(cast(total_deaths as bigint)) as TotalDeathCount, Max((total_deaths/population))*100000 as DeathRate
From PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

--Group by Income

SELECT location, MAX(cast(total_deaths as bigint)) as TotalDeathCount, Max((total_deaths/population))*100000 as DeathRate
From PortfolioProject..CovidDeaths
where continent is null
group by location
order by TotalDeathCount desc

--Global Summary

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, SUM(cast(new_deaths as bigint))/SUM(new_cases) * 100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
Group by date
order by 1,2

--Total Population vs Vaccination

--USING CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.Location, 
dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/Population)*100

From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

)

select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinationa numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.Location, 
dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/Population)*100
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating View


CREATE VIEW PercentPopulationVaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

