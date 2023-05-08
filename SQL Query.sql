  

Select *
FROM CovidDeaths
WHERE continent is not NULL 
ORDER BY 3,4;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY 1,2;
 
-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract COVID in your country 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM coviddeaths
ORDER BY 1,2;

-- Looking at total cases v population 
-- Shows what percentage of population got COVID

SELECT location, date, population, total_cases, (total_cases::float / population)*100 as ContractionRate
FROM coviddeaths
ORDER BY 1,2;

-- Looking at countries with highest infection rate companred to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases::float / population)*100 as ContractionRate
FROM coviddeaths
GROUP BY location, population
ORDER BY ContractionRate desc;

-- Showing countries with highest death counts per populaiton

SELECT location, MAX(total_deaths) as totaldeathcount
FROM coviddeaths
WHERE continent is not NULL
GROUP BY location
HAVING MAX(total_deaths) is not NULL 
ORDER BY totaldeathcount DESC; 

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing the continients with the highest death count per population 

SELECT continent, MAX(total_deaths) as totaldeathcount
FROM coviddeaths
WHERE continent is not NULL
GROUP BY continent
HAVING MAX(total_deaths) is not NULL 
ORDER BY totaldeathcount DESC; 

-- Global numbers 

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths::float)/SUM(new_cases)*100 as DeathPercentage
FROM coviddeaths
WHERE continent is not NULL
--GROUP BY date 
-- HAVING SUM(new_cases) is not NULL
ORDER BY 1,2;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingpeoplevaccinated
-- (rollingpeoplevaccinated/popultion) *100
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL 
ORDER BY 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, new_vaccination, rollingpeoplevaccinated)

as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingpeoplevaccinated
-- (rollingpeoplevaccinated/popultion) *100
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL 
-- ORDER BY 2,3
)

SELECT *, (rollingpeoplevaccinated::float/population)*100
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMP TABLE PercentPopulationVaccinated (
  Continent varchar(255),
  Location varchar(255),
  Date date,
  Population numeric,
  New_vaccinations numeric,
  RollingPeopleVaccinated numeric
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS integer)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PercentPopulationVaccinated;

-- Creating View to store data for later visualizations

CREATE OR REPLACE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS integer)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

