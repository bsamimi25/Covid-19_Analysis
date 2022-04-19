CREATE TABLE public."CovidDeaths"
(
    iso_code text COLLATE pg_catalog."default",
    continent text COLLATE pg_catalog."default",
    location text COLLATE pg_catalog."default",
    date date,
    population numeric,
    total_cases numeric,
    new_cases numeric,
    new_cases_smoothed numeric,
    total_deaths numeric,
    new_deaths numeric,
    new_deaths_smoothed numeric,
    total_cases_per_million numeric,
    new_cases_per_million numeric,
    new_cases_smoothed_per_million numeric,
    total_deaths_per_million numeric,
    new_deaths_per_million numeric,
    new_deaths_smoothed_per_million numeric,
    reproduction_rate numeric,
    icu_patients numeric,
    icu_patients_per_million numeric,
    hosp_patients numeric,
    hosp_patients_per_million numeric,
    weekly_icu_admissions numeric,
    weekly_icu_admissions_per_million numeric,
    weekly_hosp_admissions numeric,
    weekly_hosp_admissions_per_million numeric
)

CREATE TABLE public."CovidVaccinations"
(
    iso_code text COLLATE pg_catalog."default",
    continent text COLLATE pg_catalog."default",
    location text COLLATE pg_catalog."default",
    date date,
    new_tests numeric,
    total_tests_per_thousand numeric,
    new_tests_per_thousand numeric,
    new_tests_smoothed numeric,
    new_tests_smoothed_per_thousand numeric,
    positive_rate numeric,
    tests_per_case numeric,
    tests_units text COLLATE pg_catalog."default",
    total_vaccinations numeric,
    people_vaccinated text COLLATE pg_catalog."default",
    people_fully_vaccinated numeric,
    total_boosters numeric,
    new_vaccinations numeric,
    new_vaccinations_smoothed numeric,
    total_vaccinations_per_hundred numeric,
    people_vaccinated_per_hundred numeric,
    people_fully_vaccinated_per_hundred numeric,
    total_boosters_per_hundred numeric,
    new_vaccinations_smoothed_per_million numeric,
    new_people_vaccinated_smoothed numeric,
    new_people_vaccinated_smoothed_per_hundred numeric,
    stringency_index numeric,
    population numeric,
    population_density numeric,
    median_age numeric,
    aged_65_older numeric,
    aged_70_older numeric,
    gdp_per_capita numeric,
    extreme_poverty numeric,
    cardiovasc_death_rate numeric,
    diabetes_prevalence numeric,
    female_smokers numeric,
    male_smokers numeric,
    handwashing_facilities numeric,
    hospital_beds_per_thousand numeric,
    life_expectancy numeric,
    human_development_index numeric,
    excess_mortality_cumulative_absolute numeric,
    excess_mortality_cumulative numeric,
    excess_mortality numeric,
    excess_mortality_cumulative_per_million numeric
)

-- Looking at Total Cases v Total Deaths 
-- Shows Likelihood of dying if you contracted COVID, statistically
Select location, date, total_cases,total_deaths,(total_deaths/total_cases)*100 as Death_Percentage
from 
	public."CovidDeaths"
where 
	location like '%United States%'
order by 1,2;

-- Looking at Total Cases v Population
-- Shows what Percentage of population got Covid
Select location, 
		date, 
		population,
		total_cases,
		(total_cases/population)*100 as Case_Percentage
from 
	public."CovidDeaths"
where 
	location like '%United States%'

-- What countries have the highest infection rates compared to population? 
Select location,
		population,
		MAX(total_cases) as Highest_Infection_Count,
		MAX((total_cases/population))*100 as Case_Percentage
from 
	public."CovidDeaths"
where 
	continent is not null
group by 
	location, Population
order by 
	Case_Percentage desc;

-- Countries with the Highest Death Percentage per Population
Select location,
		MAX(total_deaths) as Highest_Death_Count,
		MAX((total_deaths/population))*100 as Death_Percentage
from 
	public."CovidDeaths"
where 
	continent is not null
group by 
	location
order by 
	Death_Percentage desc;

-- Countries with the Highest Death Count per Population
Select location,
		MAX(total_deaths) as Highest_Death_Count
from 
	public."CovidDeaths"
where 
	continent is not null
group by 
	location
order by 
	Highest_Death_Count desc;

-------------------------CONTINENT ANALYSIS-----------------------------
-- Showing continents with Highest Death Counts per Population
Select location,
		MAX(total_deaths) as Highest_Death_Count
from 
	public."CovidDeaths"
where 
	continent is null
group by 
	location
order by 
	Highest_Death_Count desc;

-- Continents with the Highest Death Percentage per Population
Select continent,
		MAX(total_deaths) as Highest_Death_Count,
		MAX((total_deaths/population))*100 as Death_Percentage
from 
	public."CovidDeaths"
where 
	continent is not null
group by continent
order by Death_Percentage desc;

-------------------------GLOBAL ANALYSIS-----------------------------

-- Show Death Percentage by date Globally
select date,
		SUM(total_cases) as Total_Global_Cases,
		SUM(total_deaths) as Total_Death_Cases,
		SUM(total_deaths)/SUM(total_cases)*100 as Global_Death_Percentage
from 
	public."CovidDeaths"
where 
	continent is not null
group by date 

-- Show Global Death Percentage for all of Pandemic
select
		SUM(total_cases) as Total_Global_Cases,
		SUM(total_deaths) as Total_Death_Cases,
		SUM(total_deaths)/SUM(total_cases)*100 as Global_Death_Percentage
from 
	public."CovidDeaths"
where 
	continent is not null

--------------------------- DEEP DIVE INTO NORTH AMERICA----------------------
-- Percentage of Infection rate per Country for North America
Select continent, 
		date, 
		population,
		total_cases,
		(total_cases/population)*100 as Case_Percentage
		from 
	public."CovidDeaths"
where 
	continent like '%North America%'

-- Percentage of Death per Country in North America
Select location,
		MAX(total_deaths) as Highest_Death_Count,
		MAX((total_deaths/population))*100 as Death_Percentage
from 
	public."CovidDeaths"
where 
	continent is not null and continent like '%North America%'
group by 
	location
order by 
	Death_Percentage desc;


---------------------------VACCINATIONS ANALYSIS----------------------

select *
from public."CovidDeaths" as dea 
	left join public."CovidVaccinations" as vac on dea.location = vac.location and dea.date= vac.date

-- Total Population vs Vaccinations 
select dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations
from public."CovidDeaths" as dea 
	left join public."CovidVaccinations" as vac on dea.location = vac.location and dea.date= vac.date
where 
	dea.continent is not null
order by 2,3

-- USE CTE
with PopvVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
as 
(
select dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (Partition by dea.location
									   		Order by dea.location,dea.date) as RollingPeopleVaccinated
from public."CovidDeaths" as dea 
	left join public."CovidVaccinations" as vac on dea.location = vac.location and dea.date= vac.date
where 
	dea.continent is not null
)

select *, (RollingPeopleVaccinated/population)*100
from PopvVac



-- MAX VACCINE COUNT
--USe temp table

--drop table if exists PercentPopulationVaccinated
create table PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into PercentPopulationVaccinated
select dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (Partition by dea.location
									   		Order by dea.location,dea.date) as RollingPeopleVaccinated
from public."CovidDeaths" as dea 
	left join public."CovidVaccinations" as vac on dea.location = vac.location and dea.date= vac.date
where 
	dea.continent is not null

select *, (RollingPeopleVaccinated/population)*100
from PercentPopulationVaccinated