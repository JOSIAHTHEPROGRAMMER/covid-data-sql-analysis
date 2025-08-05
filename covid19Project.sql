-- View all data from CovidDeaths table
SELECT *
FROM CovidProject..[CovidDeaths - CovidDeaths]
ORDER BY 3, 4;


-- View all data from CovidVaccinations table
-- SELECT *
-- FROM CovidProject..[CovidVaccinations - CovidVaccinations]
-- ORDER BY 3, 4;


-- Select data we are going to be using
SELECT 
    location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM CovidProject..[CovidDeaths - CovidDeaths]
ORDER BY location, date;


-- Total Deaths vs Total Cases in a country
--  Highlights percentage of cases that results in deaths
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths * 100.0 / NULLIF(total_cases, 0)) AS percentage_of_death
FROM 
    CovidProject..[CovidDeaths - CovidDeaths]
--WHERE 
  --  location LIKE '%Trinidad%' 
 -- OR location LIKE '%Jamaica%'
ORDER BY 
    location, date;


-- Population vs Total Cases for a country
-- Highlights the percentage of the population that contracted COVID-19
SELECT 
    location,
    date,
    total_cases,
    population,
    (total_cases * 100.0 / NULLIF(population, 0)) AS percentage_of_population_infected
FROM 
    CovidProject..[CovidDeaths - CovidDeaths]
--WHERE 
 --      location LIKE '%Trinidad%' 
 --    location LIKE '%Jamaica%'
ORDER BY 
    location, date;


-- Countries with the highest rate of infection compared to population

SELECT 
    location,
    MAX(total_cases) as highest_total_cases,
    population,MAX(
    (total_cases * 100.0 / NULLIF(population, 0))) AS percentage_of_population_infected
FROM 
    CovidProject..[CovidDeaths - CovidDeaths]
--WHERE 
 --      location LIKE '%Trinidad%' 
 --    location LIKE '%Jamaica%'
GROUP BY location, population
ORDER BY 
    percentage_of_population_infected DESC


-- Countries with the highest death count

SELECT 
    location,
    MAX(total_deaths) as highest_total_deaths
 -- population,MAX(
 --  (total_deaths * 100.0 / NULLIF(population, 0))) AS percentage_of_population_deaths
FROM 
    CovidProject..[CovidDeaths - CovidDeaths]
WHERE 
       continent IS NOT NULL
 --      location LIKE '%Trinidad%' 
 --    location LIKE '%Jamaica%'
GROUP BY location, population
ORDER BY 
     highest_total_deaths DESC

-- Continents with the highest death count

SELECT 
    continent,
    MAX(total_deaths) as highest_total_deaths
 -- population,MAX(
 --  (total_deaths * 100.0 / NULLIF(population, 0))) AS percentage_of_population_deaths
FROM 
    CovidProject..[CovidDeaths - CovidDeaths]
    WHERE continent IS NOT NULL 
 
 --      location LIKE '%Trinidad%' 
 --    location LIKE '%Jamaica%'
GROUP BY continent
ORDER BY 
     highest_total_deaths DESC

-- Continents with the highest cases

SELECT 
    continent,
    MAX(total_cases) as highest_total_cases
 -- population,MAX(
 --  (total_deaths * 100.0 / NULLIF(population, 0))) AS percentage_of_population_deaths
FROM 
    CovidProject..[CovidDeaths - CovidDeaths]
    WHERE continent IS NOT NULL 
 
 --      location LIKE '%Trinidad%' 
 --    location LIKE '%Jamaica%'
GROUP BY continent
ORDER BY 
     highest_total_cases DESC

-- Global death percentage over time

SELECT 
    date, 
    SUM(new_cases) AS total_new_cases, 
    SUM(new_deaths) AS total_new_deaths,
    (SUM(new_deaths) * 100.0 / NULLIF(SUM(new_cases), 0)) AS global_death_percentage
FROM CovidProject..[CovidDeaths - CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Global death percentage
SELECT  
    SUM(new_cases) AS total_new_cases, 
    SUM(new_deaths) AS total_new_deaths,
    (SUM(new_deaths) * 100.0 / NULLIF(SUM(new_cases), 0)) AS global_death_percentage
FROM CovidProject..[CovidDeaths - CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1 , 2;


-- Total population vs vaccinations over time

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as rolling_people_total_vacs
FROM CovidProject..[CovidDeaths - CovidDeaths] d
JOIN CovidProject..[CovidVaccinations - CovidVaccinations] v
on d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.location


-- Rolling Vaccination Rate per Country Over Time

WITH PopVsVac (continent, location, date, population, new_vaccinations, rolling_people_total_vacs)
as (

    SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
    SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as rolling_people_total_vacs
    FROM CovidProject..[CovidDeaths - CovidDeaths] d
    JOIN CovidProject..[CovidVaccinations - CovidVaccinations] v
    on d.location = v.location
    AND d.date = v.date
    WHERE d.continent IS NOT NULL
  --  ORDER BY d.location

)

SELECT * , (rolling_people_total_vacs * 100.0 / NULLIF(population, 0)) as percent_vaccinated
FROM PopVsVac


-- TEMP TABLE 
DROP TABLE IF EXISTS #VaccinatedPopulationPercentage
CREATE TABLE #VaccinatedPopulationPercentage(
 continent nvarchar(255),
 location nvarchar(255),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 rolling_people_total_vacs numeric
)

INSERT INTO  #VaccinatedPopulationPercentage
    SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
    SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as rolling_people_total_vacs
    FROM CovidProject..[CovidDeaths - CovidDeaths] d
    JOIN CovidProject..[CovidVaccinations - CovidVaccinations] v
    on d.location = v.location
    AND d.date = v.date
    WHERE d.continent IS NOT NULL
  --  ORDER BY d.location

SELECT *, (rolling_people_total_vacs * 100.0 / NULLIF(population, 0)) AS percent_vaccinated
FROM #VaccinatedPopulationPercentage


-- CREATING VIEWS FOR VISUALS

DROP VIEW IF EXISTS vw_DeathRateByCountry;

CREATE VIEW vw_DeathRateByCountry AS
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths * 100.0 / NULLIF(total_cases, 0)) AS percentage_of_death
FROM CovidProject..[CovidDeaths - CovidDeaths];

DROP VIEW IF EXISTS vw_InfectionRateByCountry;

CREATE VIEW vw_InfectionRateByCountry AS
SELECT 
    location,
    date,
    total_cases,
    population,
    (total_cases * 100.0 / NULLIF(population, 0)) AS percentage_of_population_infected
FROM CovidProject..[CovidDeaths - CovidDeaths];


DROP VIEW IF EXISTS vw_HighestInfectionRateByCountry;

CREATE VIEW vw_HighestInfectionRateByCountry AS
SELECT 
    location,
    MAX(total_cases) AS highest_total_cases,
    population,
    MAX(total_cases * 100.0 / NULLIF(population, 0)) AS percentage_of_population_infected
FROM CovidProject..[CovidDeaths - CovidDeaths]
GROUP BY location, population;

DROP VIEW IF EXISTS vw_HighestDeathCountByCountry;

CREATE VIEW vw_HighestDeathCountByCountry AS
SELECT 
    location,
    MAX(total_deaths) AS highest_total_deaths
FROM CovidProject..[CovidDeaths - CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY location;

DROP VIEW IF EXISTS vw_GlobalDeathPercentageByDate;


CREATE VIEW vw_GlobalDeathPercentageByDate AS
SELECT 
    date, 
    SUM(new_cases) AS total_new_cases, 
    SUM(new_deaths) AS total_new_deaths,
    (SUM(new_deaths) * 100.0 / NULLIF(SUM(new_cases), 0)) AS global_death_percentage
FROM CovidProject..[CovidDeaths - CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date;

DROP VIEW IF EXISTS vw_RollingVaccinationRate;

CREATE VIEW vw_RollingVaccinationRate AS
SELECT 
    d.continent, 
    d.location, 
    d.date, 
    d.population, 
    v.new_vaccinations, 
    SUM(v.new_vaccinations) OVER (
        PARTITION BY d.location ORDER BY d.location, d.date
    ) AS rolling_people_total_vacs,
    (SUM(v.new_vaccinations) OVER (
        PARTITION BY d.location ORDER BY d.location, d.date
    ) * 100.0 / NULLIF(d.population, 0)) AS percent_vaccinated
FROM CovidProject..[CovidDeaths - CovidDeaths] d
JOIN CovidProject..[CovidVaccinations - CovidVaccinations] v
    ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;


