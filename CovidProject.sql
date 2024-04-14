select * from PortfolioProject..[CovidDeaths (1)]
order by 3,4
select location, date, total_cases, new_cases, total_deaths,population
from PortfolioProject..[CovidDeaths (1)]
where continent is not null
order by 1,2

-- Thay đổi data type của một cột trong data table
Alter table PortfolioProject..[CovidDeaths (1)]
Alter Column total_cases float NULL
Alter table PortfolioProject..[CovidDeaths (1)]
Alter Column total_deaths float NULL
Alter table PortfolioProject..[CovidDeaths (1)]
Alter Column new_cases float NULL

-- thay các giá trị 0 bằng null để không bị lỗi divided by 0
UPDATE PortfolioProject..[CovidDeaths (1)] SET total_cases=NULL WHERE total_cases=0
UPDATE PortfolioProject..[CovidDeaths (1)] SET new_cases=NULL WHERE new_cases=0
-- trước câu lệnh này thì vài giá trị ở column continent trống nên không exclude ra được, set nó về null:
UPDATE PortfolioProject..[CovidDeaths (1)] SET continent=NULL WHERE continent=' '

-- Total Cases vs Total Deaths
select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..[CovidDeaths (1)]
where location like '%state%'
where continent is not null
order by 1,2

-- Total cases vs Population
select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..[CovidDeaths (1)]
where location like '%state%'
order by 1,2

-- looking at countries with high infection rate
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentagePopulationInfected
from PortfolioProject..[CovidDeaths (1)]
where population <> 0
group by location, population
order by PercentagePopulationInfected desc

-- Countries with the Highest Death Count per Population
select location, population, total_deaths, MAX((total_deaths/population))*100 as HighestDeathCount
from PortfolioProject..[CovidDeaths (1)]
where population <> 0
group by location, population, total_deaths
order by HighestDeathCount desc

-- BREAK DOWN BY CONTINENTS
-- The CAST() function converts a value (of any type) into a specified datatype: https://www.w3schools.com/sql/func_sqlserver_cast.asp 
select location, max(cast(total_deaths as int)) as TotalDeaths
from PortfolioProject..[CovidDeaths (1)]
where continent is null
group by location
order by TotalDeaths desc
-- The difference btw the above and below is in the third line, if continent is null, data will be shown in continents:
select continent, max(cast(total_deaths as int)) as TotalDeaths
from PortfolioProject..[CovidDeaths (1)]
where continent is NOT null
group by continent
order by TotalDeaths desc

-- GLOBAL NUMBERS:
Alter table PortfolioProject..[CovidDeaths (1)]
Alter Column date datetime NULL
-----cần lệnh trên vì datatype cũ của date là varchar nên lệnh order by phía dưới sẽ order không đúng
select date, sum(new_cases) as Total_Cases, sum(cast (new_deaths as int)) as New_Deaths, sum(cast (new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..[CovidDeaths (1)]
-------where location like '%state%'
where continent is not null
group by date
order by 1,2


-- Looking at Total Population vs Vaccinations 
Alter table PortfolioProject..CovidVaccinations
Alter Column new_vaccinations float NULL
Alter table PortfolioProject..[CovidDeaths (1)]
Alter Column location varchar(50) NULL
UPDATE PortfolioProject..CovidVaccinations SET new_vaccinations=NULL WHERE new_vaccinations=' '
Select dea.continent, dea.location, dea.date, vac.new_vaccinations, dea.population, sum(vac.new_vaccinations) over (Partition by dea.location order by dea.location, dea.date) as AcculVaccinated
from PortfolioProject..[CovidDeaths (1)]  as dea
join PortfolioProject..CovidVaccinations as vac
   On dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null
   order by 2,3

   ----USE CTE: 
With PopvsVac (continent, location, date, population, new_vaccinations, AcculVaccinated) -- chỗ này, nhớ là thứ tự tên của các cột trong cái bảng ảo chỗ này phải khớp với thứ tự tên của bảng thật ở lệnh select ở dưới.
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,sum(vac.new_vaccinations) over (Partition by dea.location order by dea.location, dea.date) as AcculVaccinated --Lưu ý tỉ lần: đặt alias thì không được chèn dấu chấm phẩy gì đó vô.
from PortfolioProject..[CovidDeaths (1)]  as dea
join PortfolioProject..CovidVaccinations as vac
   On dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null
  )
  select *, (AcculVaccinated/population)*100 from PopvsVac;

  -- TEMP TABLE: WHAT IS IT FOR? =)))
 drop table if exists #PercentPopulationVaccinated
 create table #PercentPopulationVaccinated
  (
  Continent nvarchar(255),
  Location nvarchar (255),
  date datetime,
  population float,
  new_vaccincations float,
  AcculVaccinated float
  )
  Insert into #PercentPopulationVaccinated
	  Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,sum(vac.new_vaccinations) over (Partition by dea.location order by dea.location, dea.date) as AcculVaccinated --Lưu ý tỉ lần: đặt alias thì không được chèn dấu chấm phẩy gì đó vô.
	from PortfolioProject..[CovidDeaths (1)]  as dea
	join PortfolioProject..CovidVaccinations as vac
	   On dea.location = vac.location
	   and dea.date = vac.date
	   where dea.continent is not null
select *, (AcculVaccinated/population)*100 from #PercentPopulationVaccinated;

-- Create view to store data for later visualizations:
drop view if exists PercentPopulationVaccinated
--- Nhớ dùng lệnh USE GO sau đây để view được lưu vào PortfolioProject, không là không biết nó ở đâu:
USE PortfolioProject
GO
create view PercentPopulationVaccinated as
	  Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,sum(vac.new_vaccinations) over (Partition by dea.location order by dea.location, dea.date) as AcculVaccinated --Lưu ý tỉ lần: đặt alias thì không được chèn dấu chấm phẩy gì đó vô.
	from PortfolioProject..[CovidDeaths (1)]  as dea
	join PortfolioProject..CovidVaccinations as vac
	   On dea.location = vac.location
	   and dea.date = vac.date
	   where dea.continent is not null
	