--Select Data to be used
SELECT location, date, total_cases, new_cases,total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Total cases vs. Total deaths
--Shows likelyhood of dying of Covid
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%india%'
ORDER BY 1,2

--Total cases vs. Population
--Shows what percentage of population got Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%india%'
ORDER BY 1,2

--Countries with highest infection rate vs. Population
SELECT location, MAX(total_cases) AS HighestInfected, population, MAX((total_cases/population))*100 AS PercentAffected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%india%'
GROUP BY location, population
ORDER BY PercentAffected DESC


-- Countries with highest death count per capita
SELECT location, MAX(cast (total_deaths AS int)) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%india%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeaths DESC

--Continents with highest death count
SELECT continent, MAX(cast (total_deaths AS int)) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%india%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeaths DESC


--Global Scale
SELECT  SUM(new_cases) AS total_cases, SUM(cast(total_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%india%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2


--Total Population vs. Vaccinations

--Using CTE
WITH PopvsVac(continent, location, date, population, new_vaccinations, RollingVaccineCount) AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccineCount
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccs AS cv ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingVaccineCount/population)*100 as PercentVaccinated
FROM PopvsVac

--Using Temp Table

DROP Table if exists #PopulationVaccinated

CREATE TABLE #PopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255), 
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccineCount numeric
)
INSERT INTO PopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccineCount
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccs AS cv ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingVaccineCount/population)*100 as PercentVaccinated
FROM #PopulationVaccinated

CREATE VIEW PeopleVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccineCount
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccs AS cv ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY 2,3