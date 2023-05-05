Select *
from [Portfolio Project]..CovidDeaths
where continent is not null
order by 3,4

--Select *
--from [Portfolio Project]..CovidVaccinations
--order by 3,4

--Select Data that we are going to be using
Select Location, Date,total_cases,new_cases,total_deaths,population
from [Portfolio Project]..CovidDeaths
where continent is not null
order by 1,2

--Looking at Total Cases vs Total Deaths
--Note: Changing Data Type before Dividing ('nvarchar' --> 'float', not 'int' because Percentage will return 0) 
--Use 'Convert', 'Cast' or 'Alter Table'
alter table covidvaccinations
alter column new_vaccinations bigint

--Shows likelihood of dying if you contract covid in your country
Select Location, Date,total_cases,total_deaths,(total_deaths/total_cases)*100 DeathPercentage
from [Portfolio Project]..CovidDeaths
where Location = 'vietnam' and continent is not null
order by 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
Select Location, Date,population,total_cases,(total_cases/population)*100 CasePercentage
from [Portfolio Project]..CovidDeaths
where Location = 'vietnam' and continent is not null
order by 1,2

--Looking at country with highest Infection Rate compared to Population
Select Location, population,max(total_cases) HighestInfectionCount, Max((total_cases/population))*100 PercentPopulationInfected
from [Portfolio Project]..CovidDeaths
where continent is not null
group by location, population
--where Location = 'vietnam'
order by 4 desc

--Showing the countries with the Highest Death Count per Population
Select Location, max(cast(total_deaths as int)) TotalDeathCount
from [Portfolio Project]..CovidDeaths
where continent is not null
group by location
--where Location = 'vietnam'
order by TotalDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINENT
--WRONG
Select continent, max(cast(total_deaths as int)) TotalDeathCount
from [Portfolio Project]..CovidDeaths
where continent is not null
group by continent
--where Location = 'vietnam'
order by TotalDeathCount desc
--RIGHT
Select location, max(cast(total_deaths as int)) TotalDeathCount
from [Portfolio Project]..CovidDeaths
where continent is null
group by location
--where Location = 'vietnam'
order by TotalDeathCount desc

--GLOBAL NUMBERS
Select Date,sum(new_cases) NewCases,sum(new_deaths) NewDeaths,(sum(new_deaths)/sum(new_cases))*100 as NewDeathPercentage
from [Portfolio Project]..CovidDeaths
--where Location = 'vietnam' and 
where continent is not null and new_cases <> 0
group by date
order by 1,2

Select sum(new_cases) NewCases,sum(new_deaths) NewDeaths,(sum(new_deaths)/sum(new_cases))*100 as NewDeathPercentage
from [Portfolio Project]..CovidDeaths
--where Location = 'vietnam' and 
where continent is not null and new_cases <> 0
--group by date
order by 1,2

-- Looking at Total Population vs Vaccinations
select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
on dea.date=vac.date
and dea.location=vac.location
where dea.continent is not null
order by 2,3

--The earliest country with vaccination
select dea.continent,dea.location,dea.date,dea.date,dea.population,vac.new_vaccinations
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
on dea.date=vac.date
and dea.location=vac.location
where dea.continent is not null and vac.new_vaccinations is not null and new_vaccinations <> 0
order by 6,3

select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.date)
as RollingPeopleVaccinated
--Error: Arithmetic overflow error converting expression to data type int --> use 'bigint' instead of 'int'
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
on dea.date=vac.date
and dea.location=vac.location
where dea.continent is not null
order by 2,3

--USE CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated --Các cột được chọn phải tương ứng các cột được tạo
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
on dea.date=vac.date
and dea.location=vac.location
where dea.continent is not null
)
select*,(RollingPeopleVaccinated/Population)*100
from PopvsVac

--TEMP TABLE
Drop Table if exists #PercentPopulationVaccinated --Tránh lặp bảng
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated --Các cột được chọn phải tương ứng các cột được tạo
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
on dea.date=vac.date
and dea.location=vac.location
where dea.continent is not null

select*,(RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated

--Creating View to store dât for later visualiztion
Create View PercentPopulationVaccinated as
select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated --Các cột được chọn phải tương ứng các cột được tạo
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
on dea.date=vac.date
and dea.location=vac.location
where dea.continent is not null

select *
from PercentPopulationVaccinated
