SELECT *
FROM PortfolioProject.dbo.CovidDeaths$
order by 3,4

--SELECT *
--FROM PortfolioProject.dbo.CovidVaccinations$
--order by 3,4

--SELECT THE DATA THAT I AM GOING TO BE USING--
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY location, date

--LOOKING AT TOTAL CASES VS TOTAL DEATHS--
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location = 'Canada' AND continent IS NOT NULL
ORDER BY location, date

--LOOKING AT THE TOTAL CASES VS THE POPULATION--
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location = 'Canada' AND continent IS NOT NULL
ORDER BY location, date

--LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION--
SELECT location, MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population)*100) AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY PercentPopulationInfected DESC

--LOOKING AT COUNTRIES WITH HIGHEST DEATHS COMPARED TO POPULATION--
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--LOOKING AT CONTINENTS WITH HIGHEST DEATHS COMPARED TO POPULATION--
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--LOOKING AT GLOBAL NUMBERS--
SELECT date, SUM(new_cases) AS GlobalCases, SUM(CAST(new_deaths AS INT)) AS GlobalDeaths, SUM(CAST(new_deaths AS INT))/ SUM(new_cases) *100 AS GlobalPercDeaths
FROM PortfolioProject.dbo.CovidDeaths$
WHERE  continent IS NOT NULL
GROUP BY date

--JOINING TABLES--
SELECT *
FROM PortfolioProject.dbo.CovidDeaths$ AS d
INNER JOIN PortfolioProject.dbo.CovidVaccinations$ AS v
ON d.location = v.location
AND d.date = v.date

--LOOKING AT TOTAL POPULATION VS VACCINATIONS  (USING WINDOW FUNCTION)

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CAST(v.new_vaccinations AS BIGINT)) OVER (PARTITION BY d.location ORDER BY d.location, d.date)
AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ AS d
INNER JOIN PortfolioProject.dbo.CovidVaccinations$ AS v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.location, d.date

--USING A CTE

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date)
AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ AS d
INNER JOIN PortfolioProject.dbo.CovidVaccinations$ AS v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPercPopVaccinated
FROM PopVsVac
ORDER BY Location, Date

--TEMP TABLE
DROP TABLE IF exists #PercentPopulationVaccinated --Added this line to be able to edit the query on the go, eg: Comented out the Where clause
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date)
AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ AS d
INNER JOIN PortfolioProject.dbo.CovidVaccinations$ AS v
	ON d.location = v.location AND d.date = v.date
--WHERE d.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPercPopVaccinated
From #PercentPopulationVaccinated
ORDER BY Location, Date


--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date)
AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ AS d
INNER JOIN PortfolioProject.dbo.CovidVaccinations$ AS v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY d.location, d.date

SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPercPopVaccinated
From dbo.PercentPopulationVaccinated
ORDER BY Location, Date
