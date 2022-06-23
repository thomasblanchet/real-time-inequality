# Replication package for "Real-Time Inequality" (Blanchet, Saez and Zucman, 2022)

## Overview

The code in this replication package constructs the synthetic microfiles that can be used to replicate the inequality data available online at [realtimeinequality.org](https://realtimeinequality.org/). It combines data for a large number of sources (detailed below). The master file and most of the code runs in Stata with some parts of the code written in R and in Python. The replicator should expect the entire code to run in 1--2 days.

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

#### Real-Time Billionaires List from Forbes

#### Wilshire 5000 Total Market Index (Wilshire Associates, via FRED)

#### Case-Shiller National Home Price Index (via FRED)

#### Zillow Home Value Index (via FRED)


> INSTRUCTIONS: For each data source, list the file that contains data from that source here; if providing combined/derived datafiles, list them separately after the DAS. For each data source or file, as appropriate, 
> 
> - Describe the format (open formats preferred, but some software-specific formats OK if open-source readers available): `.dta`, `.xlsx`, `.csv`, `netCDF`, etc.
> - Provide a data dictionairy, either as part of the archive (list the file name), or at a URL (list the URL). Some formats are self-describing *if* they have the requisite information (e.g., `.dta` should have both variable and value labels).


### Example for public use data collected by the authors

> The [DATA TYPE] data used to support the findings of this study have been deposited in the [NAME] repository ([DOI or OTHER PERSISTENT IDENTIFIER]). [[1](https://www.hindawi.com/research.data/#statement.templates)]. The data were collected by the authors, and are available under a Creative Commons Non-commercial license.

### Example for public use data sourced from elsewhere and provided

> Data on National Income and Product Accounts (NIPA) were downloaded from the U.S. Bureau of Economic Analysis (BEA, 2016). We use Table 30. Data can be downloaded from https://apps.bea.gov/regional/downloadzip.cfm, under "Personal Income (State and Local)", select CAINC30: Economic Profile by County, then download. Data can also be directly downloaded using  https://apps.bea.gov/regional/zip/CAINC30.zip. A copy of the data is provided as part of this archive. The data are in the public domain.

Datafile:  `CAINC30__ALL_AREAS_1969_2018.csv`

### Example for public use data with required registration and provided extract

> The paper uses IPUMS Terra data (Ruggles et al, 2018). IPUMS-Terra does not allow for redistribution, except for the purpose of replication archives. Permissions as per https://terra.ipums.org/citation have been obtained, and are documented within the "data/IPUMS-terra" folder.
>> Note: the reference to "Ruggles et al, 2018" would be resolved in the Reference section of this README, **and** in the main manuscript.

Datafile: `data/raw/ipums_terra_2018.dta`

### Example for free use data with required registration, extract not provided

> The paper uses data from the World Values Survey Wave 6 (Inglehart et al, 2019). Data is subject to a redistribution restriction, but can be freely downloaded from http://www.worldvaluessurvey.org/WVSDocumentationWV6.jsp. Choose `WV6_Data_Stata_v20180912`, fill out the registration form, including a brief description of the project, and agree to the conditions of use. Note: "the data files themselves are not redistributed" and other conditions. Save the file in the directory `data/raw`. 

>> Note: the reference to "Inglehart et al, 2018" would be resolved in the Reference section of this README, **and** in the main manuscript.

Datafile: `data/raw/WV6_Data_Stata_v20180912.dta` (not provided)

### Example for confidential data

> INSTRUCTIONS: Citing and describing confidential data, in particular when it does not have a regular distribution channel or online landing page, can be tricky. A citation can be crafted ([see guidance](https://social-science-data-editors.github.io/guidance/FAQ.html#data-citation-without-online-link)), and the DAS should describe how to access, whom to contact (including the role of the particular person, should that person retire), and other relevant information, such as required citizenship status or cost.

> The data for this project (DESE, 2019) are confidential, but may be obtained with Data Use Agreements with the Massachusetts Department of Elementary and Secondary Education (DESE). Researchers interested in access to the data may contact [NAME] at [EMAIL], also see www.doe.mass.edu/research/contact.html. It can take some months to negotiate data use agreements and gain access to the data. The author will assist with any reasonable replication attempts for two years following publication.

### Example for confidential Census Bureau data

> All the results in the paper use confidential microdata from the U.S. Census Bureau. To gain access to the Census microdata, follow the directions here on how to write a proposal for access to the data via a Federal Statistical Research Data Center: https://www.census.gov/ces/rdcresearch/howtoapply.html. 
You must request the following datasets in your proposal:
>1. Longitudinal Business Database (LBD), 2002 and 2007
>2. Foreign Trade Database – Import (IMP), 2002 and 2007
[...]

(adapted from [Fort (2016)](https://doi.org/10.1093/restud/rdw057))

### Example for preliminary code during the editorial process

> Code for data cleaning and analysis is provided as part of the replication package. It is available at https://dropbox.com/link/to/code/XYZ123ABC for review. It will be uploaded to the [JOURNAL REPOSITORY] once the paper has been conditionally accepted.

## Dataset list

> INSTRUCTIONS: In some cases, authors will provide one dataset (file) per data source, and the code to combine them. In others, in particular when data access might be restrictive, the replication package may only include derived/analysis data. Every file should be described. This can be provided as a Excel/CSV table, or in the table below.

> INSTRUCTIONS: While it is often most convenient to provide data in the native format of the software used to analyze and process the data, not all formats are "open" and can be read by other (free) software. Data should at a minimum be provided in formats that can be read by open-source software (R, Python, others), and ideally be provided in non-proprietary, archival-friendly formats. 

> INSTRUCTIONS: All data files should be fully documented: variables/columns should have labels (long-form meaningful names), and values should be explained. This might mean generating a codebook, pointing at a public codebook, or providing data in (non-proprietary) formats that allow for a rich description. This is in particular important for data that is not distributable.

> INSTRUCTIONS: Some journals require, and it is considered good practice, to provide synthetic or simulated data that has some of the key characteristics of the restricted-access data which are not provided. The level of fidelity may vary - it may be useful for debugging only, or it should allow to assess the key characteristics of the statistical/econometric procedure or the main conclusions of the paper.

| Data file | Source | Notes    |Provided |
|-----------|--------|----------|---------|
| `data/raw/lbd.dta` | LBD | Confidential | No |
| `data/raw/terra.dta` | IPUMS Terra | As per terms of use | Yes |
| `data/derived/regression_input.dta`| All listed | Combines multiple data sources, serves as input for Table 2, 3 and Figure 5. | Yes |


## Computational requirements

> INSTRUCTIONS: In general, the specific computer code used to generate the results in the article will be within the repository that also contains this README. However, other computational requirements - shared libraries or code packages, required software, specific computing hardware - may be important, and is always useful, for the goal of replication. Some example text follows. 

> INSTRUCTIONS: We strongly suggest providing setup scripts that install/set up the environment. Sample scripts for [Stata](https://github.com/gslab-econ/template/blob/master/config/config_stata.do),  [R](https://github.com/labordynamicsinstitute/paper-template/blob/master/programs/global-libraries.R), [Julia](https://github.com/labordynamicsinstitute/paper-template/blob/master/programs/packages.jl) are easy to set up and implement. Specific software may have more sophisticated tools: [Python](https://pip.pypa.io/en/stable/user_guide/#ensuring-repeatability), [Julia](https://julia.quantecon.org/more_julia/tools_editors.html#Package-Environments).

### Software Requirements

> INSTRUCTIONS: List all of the software requirements, up to and including any operating system requirements, for the entire set of code. It is suggested to distribute most dependencies together with the replication package if allowed, in particular if sourced from unversioned code repositories, Github repos, and personal webpages. In all cases, list the version *you* used. 

- Stata (code was last run with version 15)
  - `estout` (as of 2018-05-12)
  - `rdrobust` (as of 2019-01-05)
  - the program "`0_setup.do`" will install all dependencies locally, and should be run once.
- Python 3.6.4
  - `pandas` 0.24.2
  - `numpy` 1.16.4
  - the file "`requirements.txt`" lists these dependencies, please run "`pip install -r requirements.txt`" as the first step. See [https://pip.pypa.io/en/stable/user_guide/#ensuring-repeatability](https://pip.pypa.io/en/stable/user_guide/#ensuring-repeatability) for further instructions on creating and using the "`requirements.txt`" file.
- Intel Fortran Compiler version 20200104
- Matlab (code was run with Matlab Release 2018a)
- R 3.4.3
  - `tidyr` (0.8.3)
  - `rdrobust` (0.99.4)
  - the file "`0_setup.R`" will install all dependencies (latest version), and should be run once prior to running other programs.

Portions of the code use bash scripting, which may require Linux.

Portions of the code use Powershell scripting, which may require Windows 10 or higher.

### Controlled Randomness

> INSTRUCTIONS: Some estimation code uses random numbers, almost always provided by pseudorandom number generators (PRNGs). For reproducibility purposes, these should be provided with a deterministic seed, so that the sequence of numbers provided is the same for the original author and any replicators. While this is not always possible, it is a requirement by many journals' policies. The seed should be set once, and not use a time-stamp. If using parallel processing, special care needs to be taken. If using multiple programs in sequence, care must be taken on how to call these programs, ideally from a main program, so that the sequence is not altered.

- [ ] Random seed is set at line _____ of program ______

### Memory and Runtime Requirements

> INSTRUCTIONS: Memory and compute-time requirements may also be relevant or even critical. Some example text follows. It may be useful to break this out by Table/Figure/section of processing. For instance, some estimation routines might run for weeks, but data prep and creating figures might only take a few minutes.

#### Summary

Approximate time needed to reproduce the analyses on a standard (CURRENT YEAR) desktop machine:

- [ ] <10 minutes
- [ ] 10-60 minutes
- [ ] 1-8 hours
- [ ] 8-24 hours
- [ ] 1-3 days
- [ ] 3-14 days
- [ ] > 14 days
- [ ] Not feasible to run on a desktop machine, as described below.

#### Details

The code was last run on a **4-core Intel-based laptop with MacOS version 10.14.4**. 

Portions of the code were last run on a **32-core Intel server with 1024 GB of RAM, 12 TB of fast local storage**. Computation took 734 hours. 

Portions of the code were last run on a **12-node AWS R3 cluster, consuming 20,000 core-hours**.  

> INSTRUCTIONS: Identifiying hardware and OS can be obtained through a variety of ways:
> Some of these details can be found as follows:
>
> - (Windows) by right-clicking on "This PC" in File Explorer and choosing "Properties"
> - (Mac) Apple-menu > "About this Mac"
> - (Linux) see code in [tools/linux-system-info.sh](https://github.com/AEADataEditor/replication-template/blob/master/tools/linux-system-info.sh)`


## Description of programs/code

> INSTRUCTIONS: Give a high-level overview of the program files and their purpose. Remove redundant/ obsolete files from the Replication archive.

- Programs in `programs/01_dataprep` will extract and reformat all datasets referenced above. The file `programs/01_dataprep/main.do` will run them all.
- Programs in `programs/02_analysis` generate all tables and figures in the main body of the article. The program `programs/02_analysis/main.do` will run them all. Each program called from `main.do` identifies the table or figure it creates (e.g., `05_table5.do`).  Output files are called appropriate names (`table5.tex`, `figure12.png`) and should be easy to correlate with the manuscript.
- Programs in `programs/03_appendix` will generate all tables and figures  in the online appendix. The program `programs/03_appendix/main-appendix.do` will run them all. 
- Ado files have been stored in `programs/ado` and the `main.do` files set the ADO directories appropriately. 
- The program `programs/00_setup.do` will populate the `programs/ado` directory with updated ado packages, but for purposes of exact reproduction, this is not needed. The file `programs/00_setup.log` identifies the versions as they were last updated.
- The program `programs/config.do` contains parameters used by all programs, including a random seed. Note that the random seed is set once for each of the two sequences (in `02_analysis` and `03_appendix`). If running in any order other than the one outlined below, your results may differ.

### (Optional, but recommended) License for Code

![Modified BSD License](https://img.shields.io/badge/License-BSD-lightgrey.svg)

The code is licensed under the [Modified BSD License](https://opensource.org/licenses/BSD-3-Clause). See LICENSE.txt for details.

> INSTRUCTIONS: Most journal repositories provide for a default license, but do not impose a specific license. Authors should actively select a license. This should be provided in a LICENSE.txt file, separately from the README, possibly combined with the license for any data provided. Some code may be subject to inherited license requirements, i.e., the original code author may allow for redistribution only if the code is licensed under specific rules - authors should check with their sources. For instance, some code authors require that their article describing the econometrics of the package be cited. Licensing can be complex. Some non-legal guidance may be found [here](https://social-science-data-editors.github.io/guidance/Licensing_guidance.html).

The code is licensed under a MIT/BSD/GPL [choose one!] license. See [LICENSE.txt](LICENSE.txt) for details.

## Instructions to Replicators

> INSTRUCTIONS: The first two sections ensure that the data and software necessary to conduct the replication have been collected. This section then describes a human-readable instruction to conduct the replication. This may be simple, or may involve many complicated steps. It should be a simple list, no excess prose. Strict linear sequence. If more than 4-5 manual steps, please wrap a main program/Makefile around them, in logical sequences. Examples follow.

- Edit `programs/config.do` to adjust the default path
- Run `programs/00_setup.do` once on a new system to set up the working environment. 
- Download the data files referenced above. Each should be stored in the prepared subdirectories of `data/`, in the format that you download them in. Do not unzip. Scripts are provided in each directory to download the public-use files. Confidential data files requested as part of your FSRDC project will appear in the `/data` folder. No further action is needed on the replicator's part.
- Run `programs/01_main.do` to run all steps in sequence.

### Details

- `programs/00_setup.do`: will create all output directories, install needed ado packages. 
   - If wishing to update the ado packages used by this archive, change the parameter `update_ado` to `yes`. However, this is not needed to successfully reproduce the manuscript tables. 
- `programs/01_dataprep`:  
   - These programs were last run at various times in 2018. 
   - Order does not matter, all programs can be run in parallel, if needed. 
   - A `programs/01_dataprep/main.do` will run them all in sequence, which should take about 2 hours.
- `programs/02_analysis/main.do`.
   - If running programs individually, note that ORDER IS IMPORTANT. 
   - The programs were last run top to bottom on July 4, 2019.
- `programs/03_appendix/main-appendix.do`. The programs were last run top to bottom on July 4, 2019.
- Figure 1: The figure can be reproduced using the data provided in the folder “2_data/data_map”, and ArcGIS Desktop (Version 10.7.1) by following these (manual) instructions:
  - Create a new map document in ArcGIS ArcMap, browse to the folder
“2_data/data_map” in the “Catalog”, with files  "provinceborders.shp", "lakes.shp", and "cities.shp". 
  - Drop the files listed above onto the new map, creating three separate layers. Order them with "lakes" in the top layer and "cities" in the bottom layer.
  - Right-click on the cities file, in properties choose the variable "health"... (more details)

## List of tables and programs


> INSTRUCTIONS: Your programs should clearly identify the tables and figures as they appear in the manuscript, by number. Sometimes, this may be obvious, e.g. a program called "`table1.do`" generates a file called `table1.png`. Sometimes, mnemonics are used, and a mapping is necessary. In all circumstances, provide a list of tables and figures, identifying the program (and possibly the line number) where a figure is created.
>
> NOTE: If the public repository is incomplete, because not all data can be provided, as described in the data section, then the list of tables should clearly indicate which tables, figures, and in-text numbers can be reproduced with the public material provided.

The provided code reproduces:

- [ ] All numbers provided in text in the paper
- [ ] All tables and figures in the paper
- [ ] Selected tables and figures in the paper, as explained and justified below.


| Figure/Table #    | Program                  | Line Number | Output file                      | Note                            |
|-------------------|--------------------------|-------------|----------------------------------|---------------------------------|
| Table 1           | 02_analysis/table1.do    |             | summarystats.csv                 ||
| Table 2           | 02_analysis/table2and3.do| 15          | table2.csv                       ||
| Table 3           | 02_analysis/table2and3.do| 145         | table3.csv                       ||
| Figure 1          | n.a. (no data)           |             |                                  | Source: Herodus (2011)          |
| Figure 2          | 02_analysis/fig2.do      |             | figure2.png                      ||
| Figure 3          | 02_analysis/fig3.do      |             | figure-robustness.png            | Requires confidential data      |

## References

> INSTRUCTIONS: As in any scientific manuscript, you should have proper references. For instance, in this sample README, we cited "Ruggles et al, 2019" and "DESE, 2019" in a Data Availability Statement. The reference should thus be listed here, in the style of your journal:

Steven Ruggles, Steven M. Manson, Tracy A. Kugler, David A. Haynes II, David C. Van Riper, and Maryia Bakhtsiyarava. 2018. "IPUMS Terra: Integrated Data on Population and Environment: Version 2 [dataset]." Minneapolis, MN: *Minnesota Population Center, IPUMS*. https://doi.org/10.18128/D090.V2

Department of Elementary and Secondary Education (DESE), 2019. "Student outcomes database [dataset]" *Massachusetts Department of Elementary and Secondary Education (DESE)*. Accessed January 15, 2019.

U.S. Bureau of Economic Analysis (BEA). 2016. “Table 30: "Economic Profile by County, 1969-2016.” (accessed Sept 1, 2017).

Inglehart, R., C. Haerpfer, A. Moreno, C. Welzel, K. Kizilova, J. Diez-Medrano, M. Lagos, P. Norris, E. Ponarin & B. Puranen et al. (eds.). 2014. World Values Survey: Round Six - Country-Pooled Datafile Version: http://www.worldvaluessurvey.org/WVSDocumentationWV6.jsp. Madrid: JD Systems Institute.

---

## Acknowledgements

Some content on this page was copied from [Hindawi](https://www.hindawi.com/research.data/#statement.templates). Other content was adapted  from [Fort (2016)](https://doi.org/10.1093/restud/rdw057), Supplementary data, with the author's permission.