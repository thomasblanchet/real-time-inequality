# Replication package for "Real-Time Inequality" (Blanchet, Saez and Zucman, 2022)

## Overview

The code in this replication package constructs the synthetic microfiles that can be used to replicate the inequality data available online at [realtimeinequality.org](https://realtimeinequality.org/) as well as the accompanying paper "Real-Time Inequality" (Blanchet, Saez and Zucman, 2022). It combines data from a large number of sources (detailed below). The master file and most of the code runs in Stata with some parts of the code written in R and in Python.

## Data Availability and Provenance Statements

### Statement about Rights

- [x] I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript. 
- [x] I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package. Appropriate permission are documented in the [LICENSE.txt](LICENSE.txt) file.


### License

![Creative Commons Attribution 4.0 International Public License](https://img.shields.io/badge/License%20-CC%20BY%204.0-lightgrey.svg)

The data, tables and figures are licensed under the [Creative Commons Attribution 4.0 International (CC BY 4.0) license](https://creativecommons.org/licenses/by/4.0/). See [LICENSE.txt](LICENSE.txt) for details.

### Summary of Availability

- [ ] All data **are** publicly available.
- [x] Some data **cannot be made** publicly available.
- [ ] **No data can be made** publicly available.

### Details on each Data Source

#### National Income and Product Accounts (NIPA) from the Bureau of Economic Analysis (BEA)

Data on National Income and Product Accounts (NIPA) is downloaded directly from the Bureau of Economic Analysis (BEA) using the "flat files" available at <https://apps.bea.gov/iTable/iTable.cfm?reqid=19&step=4&isuri=1&nipa_table_list=1&categories=flatfiles>. This data is in the public domain. It is automatically downloaded by the file `01-import-nipa.do` and stored in the repository under `work-data/01-import-nipa`.

#### Consumer Price Index for All Urban Consumers from the Bureau of Labor Statistics (BLS)

The CPI for All Urban Consumers is the most frequently update price index, and we use it to adjust BLS data for inflation in intermediary treatments. This data is in the public domain. It is downloaded directly from the BLS at <https://download.bls.gov/pub/time.series/cu/> by the file `01-import-cu.do` and stored in the repository under `work-data/01-import-cu`.

#### Employment, Hours and Earnings from the Bureau of Labor Statistics (BLS)

The data on Employment, Hours, and Earnings at the national (<https://download.bls.gov/pub/time.series/ce/>) and at the state and area levels (<https://download.bls.gov/pub/time.series/sm>) comes from the BLS. The data is in the public domain. It is automatically downloaded by `01-import-ce.do` (national) and `01-import-sm.do` (state and area) and is stored in the repository under `work-data/01-import-ce` and `work-data/01-import-sm`.

#### Weekly Unemployment Insurance Claims from the Department of Labor (DOL)

The data on weekly unemployment insurance claims comes from the Department of Labor. The data is in the public domain and available at <https://oui.doleta.gov/unemploy/claims.asp>. A copy of the data is provided in the repository at `raw-data/ui-data/weekly-unemployment-report.xlsx`. Otherwise it needs to be manually downloaded:

- go to <https://oui.doleta.gov/unemploy/claims.asp>
- select "national", "XML" (not "spreadsheet") and the latest year
- save the result as XLSX in ``raw-data/ui-data/weekly-unemployment-report.xlsx``

#### Financial Accounts from the Federal Reserve

The Financial Accounts data comes from the Federal Reserve (<https://www.federalreserve.gov/releases/z1/release-dates.htm>). The data is in the public domain. It is automatically downloaded by `01-import-fa.do` and is stored in the repository under `work-data/01-import-fa`.

#### State and Federal Minimum Wage from FRED

We use data on the state and federal minimum wages to identify outliers in the Quarterly Census of Employment and Wages. This data is in the public domain, is automatically downloaded from FRED (series `STTMINWG*` and `FEDMINNFRWG`) by `01-import-minwage.do`, and is stored in the repository under `work-data/01-import-minwage`.

#### Distributional National Accounts Data from Piketty, Saez and Zucman (2018)

The distributional national accounts data comes from [Piketty, Saez and Zucman (2018)](https://gabriel-zucman.eu/files/PSZ2018QJE.pdf) (and updated by the same authors). The aggregate data is publicly available online at <https://gabriel-zucman.eu/usdina/> and a copy is provided in this archive under `raw-data/dina-data`. The microdata is built on top the [public-use IRS microdata](https://www.nber.org/research/data/tax-model-file-documentation) which can be obtained from the NBER but cannot be redistributed directly. A stripped-down version of these microfiles, however, with fewer observations but a similar structure, can be obtained at <https://gabriel-zucman.eu/usdina/>. The DINA microdata needs to be included in the repository under `raw-data/dina-data/microfiles`.

#### Wage Statistics from the Social Security Administration

We use the yearly wage statistics from the Social Security Administration (SSA), available at <https://www.ssa.gov/cgi-bin/netcomp.cgi>. The data is in the public domain. It is automatically downloaded by `01-import-ssa-wages.R` and is stored in the repository under `work-data/01-import-ssa-wages`.

Additional historical data (on the number of wage earners only) was retrieved by hand from <https://www.ssa.gov/oact/cola/oldawidata.html> and <https://www.ssa.gov/oact/cola/awidevelop.html>. This data is only for the historical period and does not need to be updated. The data is in the Excel file `raw-data/ssa-data/number-wage-earners.xlsx` with is provided in the repository.

#### Population Data from the National Cancer Institute's Surveillance, Epidemiology an End Results Program (SEER)

We use population data by age from the National Cancer Institute's Surveillance, Epidemiology an End Results Program (SEER) (<https://seer.cancer.gov/popdata/download.html>). The data is in the public domain. It is automatically downloaded by `01-import-pop.do`, and is stored in the repository under `work-data/01-import-pop`.

#### Quarterly Retirement Market Data from the Investment Company Institute (ICI)

We use the ICI data to obtain the composition of pension funds. This data is publicly available. It is automatically downloaded from <https://www.ici.org/research/stats/retirement> and stored in the repository under `work-data/01-import-ici`.

#### Effects of Selected Federal Pandemic Response Programs on Personal Income from the Bureau of Economic Analysis (BEA)

The data on the total amounts for various COVID relief programs is obtained from the BEA at <https://www.bea.gov/federal-recovery-programs-and-bea-statistics/archive>. The data is in the public domain. It needs to be fetched by hand from the BEA's website. A copy of the data is provided in the repository under `raw-data/covid-aid-data`.

#### Paycheck Protection Program Microdata from the Small Business Administration

To obtain the microdata on PPP loans during COVID, we use the microdata from the Small Business Administration. The data is publicly available. It must be downloaded by hand from <https://data.sba.gov/dataset/ppp-foia> and included in the repository under `raw-data/ppp-covid-data`.

To match PPP loans to counties, with use the crosswalk between ZIP codes and counties provided by HUD (<https://www.huduser.gov/portal/datasets/usps_crosswalk.html>). This data is public and automatically downloaded by `01-import-ppp-covid.do`.

#### Quarterly Census of Employment and Wages (QCEW) from the Bureau of Labor Statistics (BLS)

The Quarterly Census of Employment and Wages comes from the BLS. The data is in the public domain. It is automatically downloaded from <https://www.bls.gov/cew/downloadable-data-files.htm> and stored in zipped form in the repository under `raw-data/qcew-data`.

#### Real-Time Billionaires List from Forbes

The Real-Time data on billionaires comes from Forbes. The data is publicly available. It is automatically scrapped from the [the Internet Archive](https://archive.org/) by the Python script `01-scrape-forbes.py` and stored in the repository under `raw-data/forbes-data`.

#### Wilshire 5000 Total Market Index (Wilshire Associates, via FRED)

The Wilshire 5000 Total Market Index is obtained via FRED (series `WILL5000IND`). The data is automatically downloaded by `01-import-wealth-indexes.do` and is stored in the repository under `work-data/01-import-wealth-indexes`.

#### Case-Shiller National Home Price Index (via FRED)

The Case-Shiller National Home Price Index is obtained via FRED (series `CSUSHPISA`). The data is automatically downloaded by `01-import-wealth-indexes.do` and is stored in the repository under `work-data/01-import-wealth-indexes`.

#### Zillow Home Value Index (via FRED)

The Zillow Home Value Index is obtained via FRED (series `USAUCSFRCONDOSMSAMID`). The data is automatically downloaded by `01-import-wealth-indexes.do` and is stored in the repository under `work-data/01-import-wealth-indexes`.

#### Monthly Current Population Survey (Census Bureau, via IPUMS)

We obtain the Current Population Survey microdata from IPUMS. IPUMS does not allow for redistribution, except for the purpose of replication archives. The monthly CPS extract can be obtained from [IPUMS CPS](https://cps.ipums.org/cps/). It must be stored in the repository under `raw-data/cps-monthly/cps-monthly.dat`. The extract is made up of all the monthly samples, restricted to people 20 and older, and with the following variables:

| Variable | Label                                      |
|----------|--------------------------------------------|
| YEAR     | Survey year                                |
| SERIAL   | Household serial number                    |
| MONTH    | Month                                      |
| HWTFINL  | Household weight, Basic Monthly            |
| CPSID    | CPSID, household record                    |
| ASECFLAG | Flag for ASEC                              |
| PERNUM   | Person number in sample unit               |
| WTFINL   | Final Basic Weight                         |
| CPSIDP   | CPSID, person record                       |
| AGE      | Age                                        |
| SEX      | Sex                                        |
| RACE     | Race                                       |
| SPLOC    | Person number of spouse (from programming) |
| HISPAN   | Hispanic origin                            |
| EMPSTAT  | Employment status                          |
| EDUC     | Educational attainment recode              |
| EARNWT   | Earnings weight                            |
| EARNWEEK | Weekly earnings                            |
| ELIGORG  | (Earnings) eligibility flag                |

The `cps-monthly.dat` file is imported into Stata using `01-import-cps-monthly.do`.

#### American Community Survey/Census (Census Bureau, via IPUMS USA)

We obtain the ACS/Census microdata from IPUMS. IPUMS does not allow for redistribution, except for the purpose of replication archives. The monthly CPS extract can be obtained from [IPUMS USA](https://usa.ipums.org/usa/). It must be stored in the repository under `raw-data/acs-data/usa.dta`. The extract is made up of all the default samples for each year after 1970 with the following variables:

| Variable            | Label                                          |
|---------------------|------------------------------------------------|
| YEAR                | Census year                                    |
| SAMPLE              | IPUMS sample identifier                        |
| SERIAL              | Household serial number                        |
| CBSERIAL            | Original Census Bureau household serial number |
| HHWT                | Household weight                               |
| CLUSTER             | Household cluster for variance estimation      |
| STRATA              | Household strata for variance estimation       |
| GQ                  | Group quarters status                          |
| GQTYPE (general)    | Group quarters type [general version]          |
| GQTYPED (detailed)  | Group quarters type [detailed version]         |
| PERNUM              | Person number in sample unit                   |
| PERWT               | Person weight                                  |
| SPLOC               | Spouse's location in household                 |
| SEX                 | Sex                                            |
| AGE                 | Age                                            |
| RACE (general)      | Race [general version]                         |
| RACED (detailed)    | Race [detailed version]                        |
| HISPAN (general)    | Hispanic origin [general version]              |
| HISPAND (detailed)  | Hispanic origin [detailed version]             |
| EDUC (general)      | Educational attainment [general version]       |
| EDUCD (detailed)    | Educational attainment [detailed version]      |
| EMPSTAT (general)   | Employment status [general version]            |
| EMPSTATD (detailed) | Employment status [detailed version]           |
| INCWAGE             | Wage and salary income                         |
| INCBUS              | Non-farm business income                       |
| INCBUS00            | Business and farm income, 2000                 |
| INCFARM             | Farm income                                    |
| INCSS               | Social Security income                         |
| INCWELFR            | Welfare (public assistance) income             |
| INCINVST            | Interest, dividend, and rental income          |
| INCRETIR            | Retirement income                              |

The `usa.dat` file is imported into Stata using `01-import-transport-acs.do`.

#### Current Population Survey, Annual Social and Economic Supplement (Census Bureau, via IPUMS CPS)

We obtain the Current Population Survey microdata from IPUMS. IPUMS does not allow for redistribution, except for the purpose of replication archives. The monthly CPS extract can be obtained from [IPUMS CPS](https://cps.ipums.org/cps/). It must be stored in the repository under `raw-data/cps-data/cps.dta`. The extract is made up of all the ASEC samples with the following variables:

| Variable | Label                                                  |
|----------|--------------------------------------------------------|
| YEAR     | Survey year                                            |
| SERIAL   | Household serial number                                |
| MONTH    | Month                                                  |
| CPSID    | CPSID, household record                                |
| ASECFLAG | Flag for ASEC                                          |
| HFLAG    | Flag for the 3/8 file 2014                             |
| ASECWTH  | Annual Social and Economic Supplement Household weight |
| PERNUM   | Person number in sample unit                           |
| CPSIDP   | CPSID, person record                                   |
| ASECWT   | Annual Social and Economic Supplement Weight           |
| AGE      | Age                                                    |
| SEX      | Sex                                                    |
| RACE     | Race                                                   |
| SPLOC    | Person number of spouse (from programming)             |
| HISPAN   | Hispanic origin                                        |
| EMPSTAT  | Employment status                                      |
| EDUC     | Educational attainment recode                          |
| INCWAGE  | Wage and salary income                                 |
| INCBUS   | Non-farm business income                               |
| INCFARM  | Farm income                                            |
| INCSS    | Social Security income                                 |
| INCWELFR | Welfare (public assistance) income                     |
| INCGOV   | Income from other govt programs                        |
| INCRETIR | Retirement income                                      |
| INCDRT   | Income from dividends, rent, trusts                    |
| INCINT   | Income from interest                                   |
| INCUNEMP | Income from unemployment benefits                      |
| INCWKCOM | Income from worker's compensation                      |
| INCVET   | Income from veteran's benefits                         |
| INCDIVID | Income from dividends                                  |
| INCRENT  | Income from rent                                       |
| INCRANN  | Retirement income from annuities                       |
| INCPENS  | Pension income                                         |

#### Survey of Consumer Finances

The Survey of Consumer Finances microdata comes from the Federal Reserve. The data is public and can be downloaded from <https://www.federalreserve.gov/econres/scfindex.htm>. It is stored under `raw-data/scf-data`. We use both the "full" public dataset and the "extract" public data. The data is imported into Stata using `01-import-transport-scf.do`.

## Computational requirements

### Software Requirements

- Stata 16
  - `gtools` (version 1.5.1)
  - `ftools` (version 2.37.0)
  - `grstyle` (version 1.1.0)
  - `renvars` (version 2.4.0)
  - `ereplace` (version 1.0.3)
  - `enforce` (version 1.0)
  - `reghdfe` (version 5.7.3)
  - `_gwtmean` (version 1.0.0)
  - `denton` (version 1.2.1)
  - The program `00-setup.do` will install all dependencies, alonside setting appropriate paths, etc. It should be run first every time.
- Python 3.8.3
  - `ot` (version 0.8.1.0)
  - `numpy` (version 1.22.2)
  - `scipy` (version 1.4.1)
  - `pandas` (version 1.2.4)
- R 4.0.1
  - `pacman` (version 0.5.1)
  - `gpinter` (version 0.0.0.9000)
  - `dplyr` (version 1.0.7)
  - `magrittr` (version 1.5)
  - `rvest` (version 0.3.6)
  - `glue` (version 1.4.1)
  - `stringr` (version 1.4.0)
  - `readr` (version 2.1.2)
  - `purrr` (version 0.3.4)
  - `haven` (version 2.3.1)
  - Each R file uses `pacman` to load packages, which automatically install packages if necessary. The exception is for `gpinter`, which needs to be installed from its Github repository. See <https://github.com/thomasblanchet/gpinter>.

The portion of the code in Python is meant to run on [Slurm](https://slurm.schedmd.com/documentation.html), which requires light bash scripting. This may requires a Unix-type system.

### Controlled Randomness

Random seeds are set at the beginning of the following programs:

- `03-build-monthly-microfiles.do`
- `03-build-monthly-microfiles-backtest-1y.do`
- `03-build-monthly-microfiles-backtest-2y.do`

### Memory and Runtime Requirements

> INSTRUCTIONS: Memory and compute-time requirements may also be relevant or even critical. Some example text follows. It may be useful to break this out by Table/Figure/section of processing. For instance, some estimation routines might run for weeks, but data prep and creating figures might only take a few minutes.

#### Summary

Approximate time needed to reproduce the analyses on a standard 2022 desktop machine:

- [ ] <10 minutes
- [ ] 10-60 minutes
- [ ] 1-8 hours
- [ ] 8-24 hours
- [ ] 1-3 days
- [x] 3-14 days
- [ ] > 14 days
- [ ] Not feasible to run on a desktop machine, as described below.

#### Details

The code was last run on a **2,4 GHz 8-Core Intel Core i9 laptop with 64GB of RAM running MacOS version 11.6**.

Portions of the code (the optimal transport algorithms) were last run on a **8-core Intel i9-9900X CPU @ 3.50GHz computing server with 768GB of RAM running Ubuntu 20.04.1 LTS**. Computation took 2-3 days.

## Description of programs/code

- The folder `raw-data` contains the raw input data, primarily in cases where direct download/scraping is not possible or not justified, or in cases where data files are heavy (like the QCEW) and therefore downloading them over the internet every time is not desirable.
- The folder `work-data` contains intermediary data files that are produced by the code. It is divided into subfolders corresponding to each code file, and no intermediary data file is may be changed by two distinct code files.
- The folder `graphs` contains the all the figures (and a few tables) generated by the code. It is divided into subfolders corresponding to each code file.
- The folder `programs` contains the codes (except those performing the optimal transport).
  - The codes named `programs/01-*` handle the retrieval of the raw data, either directly from the internet or from the folder `raw-data`.
  - The codes named `programs/02-*` handle preliminary treatments of the data.
  - The codes named `programs/03-*` produce the synthetic microfiles and related outputs.
  - The codes named `programs/04-*` produce the figures and tables used for the analysis.
- The folder `transport` contains the code and data specifically related to the optimal transport: it is meant to run separately from the main code on a computing cluster.

### License for Code

![Modified BSD License](https://img.shields.io/badge/License-BSD-lightgrey.svg)

The code is licensed under the [Modified BSD License](https://opensource.org/licenses/BSD-3-Clause). See [LICENSE.txt](LICENSE.txt) for details.

## Instructions to Replicators

- Edit the `$root` global in `programs/00-setup.do` to correspond to the project's directory.
- Run the file `programs/00-run.do`.
- To also run the transport, run programs until `programs/02-export-transport-dina.do` and then execute the Python code under `transport/transport.py` preferably using [Slurm](https://slurm.schedmd.com/documentation.html) and the Shell script `transport/transport.sh`. Then resume the execution of `programs/00-run.do`.

### Details

- `programs/01-*`
  - The codes retrieve the data from the internet directly to the extent that it is possible.
  - Unless there has been changes in the structure of the data, they should run without any change for each update.
  - In some cases, the data needs to be manually updated in the `raw-data` folder at each update.
  - Instruction for each file in included in `00-run.do`.
- `programs/02-*`
  - The codes primarily generate data in the `work-data` folder that is used to generate the synthetic microfiles.
- `transport`
  - This folder includes the data and code necessary for the optimal transport.
  - These codes are meant to run on the computing cluster.
  - They do not need to be updated every time (only when new tax microdata is available).
  - The CSV data files included in this folder are produced by the codes before.
- `programs/03-*`
  - The codes in that folder produce the synthetic microfiles, including backtesting versions of the microfiles that use older tax data, and rescaling versions that only use information on macro aggregates.
  - The globals `$date_begin` and `$date_end` at the beginning of these files can be used to generate only the files for specific months. This can be useful since not all the files need to be constructed for every update.
  - Codes in that section also produce the aggregated version of the database by group that is used for the website <http://realtimeinequality.org/>. These files are stored in the folder `website`.
- `programs/04-*`
  - Use the microfiles and related outputs to create the tables and figures included in the paper (see below).

## List of tables and programs

The provided code reproduces:

- [x] All numbers provided in text in the paper
- [x] All tables and figures in the paper
- [ ] Selected tables and figures in the paper, as explained and justified below.

Note that program files are under `programs` and graphs/tables are under `graphs` in the folder with the same name as the program file.

| Figure/Table # | Program                     | Output file                      |
|----------------|-----------------------------|----------------------------------|
| Figure 1       | 02-create-monthly-wages.do  | flemp-dina-qcew.pdf              |
| Figure 2a      | 02-prepare-dina.do          | volatility-profits-paper.pdf     |
| Figure 2b      | 02-prepare-dina.do          | volatility-interest-paper.pdf    |
| Figure 2c      | 02-prepare-dina.do          | volatility-rental-paper.pdf      |
| Figure 2d      | 02-prepare-dina.do          | volatility-proprietors-paper.pdf |
| Figure 3a      | 04-backtest.do              | pred-avg-bot50-1y.pdf            |
| Figure 3b      | 04-backtest.do              | pred-avg-bot50-2y.pdf            |
| Figure 3c      | 04-backtest.do              | pred-avg-mid40-1y.pdf            |
| Figure 3d      | 04-backtest.do              | pred-avg-mid40-2y.pdf            |
| Figure 4a      | 04-backtest.do              | pred-avg-top1-1y.pdf             |
| Figure 4b      | 04-backtest.do              | pred-avg-top1-2y.pdf             |
| Figure 4c      | 04-backtest.do              | pred-avg-next9-1y.pdf            |
| Figure 4d      | 04-backtest.do              | pred-avg-next9-2y.pdf            |
| Figure 5a      | 04-plot-covid.do            | presentation-evolution-princ.pdf |
| Figure 5b      | 04-plot-bot50-recessions.do | bot50-recessions.pdf             |
| Figure 6a      | 04-analyze-wage-growth.do   | employment-1.pdf                 |
| Figure 6b      | 04-analyze-wage-growth.do   | wage-growth-covid.pdf            |
| Figure 7       | 04-gic-wages.do             | gic-wages.pdf                    |
| Figure 8       | 04-plot-covid.do            | presentation-bot50-step9.pdf     |
| Figure 9       | 04-plot-covid.do            | presentation-evolution-hweal.pdf |
| Figure 10      | 03-decompose-race.do        | black-white-gaps-4.pdf           |
| Figure 11      | 03-decompose-race.do        | index-peinc-race-cycles.pdf      |
| Table 1        | n.a. (no data)              |                                  |
| Table 2        | 04-backtest.do              | backtest-table-avg-1y.tex        |
| Figure A1      | 02-prepare-nipa.do          | gdp-gdi-growth.pdf               |
| Figure A2a     | 04-backtest-rescaling.do    | pred-avg-bot50-1y.pdf            |
| Figure A2b     | 04-backtest-rescaling.do    | pred-avg-top1-1y.pdf             |
| Figure A3      | 04-plot-covid.do            | presentation-evolution-dispo.pdf |
| Figure A4      | 04-plot-covid.do            | presentation-bot50-step13.pdf    |
| Figure A5      | 03-decompose-race.do        | black-white-gap-top10.pdf        |
| Figure A6      | 03-decompose-education.do   | college-premium-4.pdf            |
| Figure A7      | 04-plot-gender-gaps         | index-peinc-gender-cycles.pdf    |
| Table A1       | 04-backtest.do              | backtest-table-avg-2y.tex        |

## References

Steven Ruggles, Sarah Flood, Ronald Goeken, Megan Schouweiler and Matthew Sobek. IPUMS USA: Version 12.0 [dataset]. Minneapolis, MN: IPUMS, 2022. https://doi.org/10.18128/D010.V12.0

Sarah Flood, Miriam King, Renae Rodgers, Steven Ruggles, J. Robert Warren and Michael Westberry. Integrated Public Use Microdata Series, Current Population Survey: Version 9.0 [dataset]. Minneapolis, MN: IPUMS, 2021. https://doi.org/10.18128/D030.V9.0

