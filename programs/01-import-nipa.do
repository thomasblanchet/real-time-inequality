// -------------------------------------------------------------------------- //
// Import NIPA series from BEA
// -------------------------------------------------------------------------- //

// URLs to retrieve the raw BEA data
global url_table_register  "https://apps.bea.gov/national/Release/TXT/TablesRegister.txt"
global url_series_register "https://apps.bea.gov/national/Release/TXT/SeriesRegister.txt"
global url_annual_data     "https://apps.bea.gov/national/Release/TXT/NipaDataA.txt"
global url_quarterly_data  "https://apps.bea.gov/national/Release/TXT/NipaDataQ.txt"
global url_monthly_data    "https://apps.bea.gov/national/Release/TXT/NipaDataM.txt"

// ---------------------------------------------------------------------- //
// Tables register
// ---------------------------------------------------------------------- //

import delimited "$url_table_register", clear varnames(1) encoding(utf8)

rename tableid table_id
rename tabletitle table_title

save "$work/01-import-nipa/nipa-tables-register.dta", replace

// ---------------------------------------------------------------------- //
// Series register
// ---------------------------------------------------------------------- //

import delimited "$url_series_register", clear varnames(1) encoding(utf8)

rename seriescode series_code
rename serieslabel series_label
rename metricname metric_name
rename calculationtype calculation_type
rename defaultscale default_scale
rename tableidlineno table_id_line_no
rename seriescodeparents series_code_parents

save "$work/01-import-nipa/nipa-series-register.dta", replace

// ---------------------------------------------------------------------- //
// Annual NIPA data
// ---------------------------------------------------------------------- //

import delimited "$url_annual_data", clear varnames(1) encoding(utf8) ///
    groupseparator(",") decimalseparator(".")
    
rename seriescode series_code
rename period year

save "$work/01-import-nipa/nipa-annual-series.dta", replace

// ---------------------------------------------------------------------- //
// Quarterly NIPA data
// ---------------------------------------------------------------------- //

import delimited "$url_quarterly_data", clear varnames(1) encoding(utf8) ///
    groupseparator(",") decimalseparator(".")
    
rename seriescode series_code

split period, parse("Q")
rename period1 year
rename period2 quarter
destring year quarter, replace
drop period

save "$work/01-import-nipa/nipa-quarterly-series.dta", replace

// ---------------------------------------------------------------------- //
// Monthly NIPA data
// ---------------------------------------------------------------------- //

import delimited "$url_monthly_data", clear varnames(1) encoding(utf8) ///
    groupseparator(",") decimalseparator(".")
    
rename seriescode series_code

split period, parse("M")
rename period1 year
rename period2 month
destring year month, replace
drop period

save "$work/01-import-nipa/nipa-monthly-series.dta", replace
// Save PCE price index separately (useful to import other data)
keep if series == "DPCERG"
keep value year month
sort year month
replace value = value/value[_N]
rename value index
save "$work/01-import-nipa/nipa-pce-price-index.dta", replace
