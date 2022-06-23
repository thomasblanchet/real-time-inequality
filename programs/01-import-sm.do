// -------------------------------------------------------------------------- //
// Import BLS employment and earning series
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Import industry codes
// -------------------------------------------------------------------------- //

import delimited "https://download.bls.gov/pub/time.series/sm/sm.industry", ///
    varnames(1) delimiter("\t") clear encoding(utf8) stringcols(_all)

generate supersector_code = substr(industry_code, 1, 2)
generate naics_code       = substr(industry_code, 3, 6)

save "$work/01-import-sm/bls-sm-industry.dta", replace

// -------------------------------------------------------------------------- //
// Import area codes
// -------------------------------------------------------------------------- //

import delimited "https://download.bls.gov/pub/time.series/sm/sm.area", ///
    varnames(1) delimiter("\t") clear encoding(utf8) stringcols(_all)
save "$work/01-import-sm/bls-sm-area.dta", replace

// -------------------------------------------------------------------------- //
// Import data series
// -------------------------------------------------------------------------- //

import delimited "https://download.bls.gov/pub/time.series/sm/sm.data.1.AllData", ///
    varnames(1) delimiter("\t") clear encoding(utf8)

destring value, ignore("- ") replace
destring period, ignore("M") replace
drop footnote_codes

generate seasonal_code    = substr(series_id, 3, 1)
generate state_code       = substr(series_id, 4, 2)
generate area_code        = substr(series_id, 6, 5)
generate supersector_code = substr(series_id, 11, 2)
generate industry_code    = substr(series_id, 13, 6)
generate data_type_code   = substr(series_id, 19, 2)

// Remove annual averages
drop if period == 13
rename period month

// Remove seasonally adjusted series
drop if seasonal_code == "S"
drop seasonal_code

drop series_id

greshape wide value, i(state_code area_code supersector_code industry_code year month) j(data_type_code) string

rename value01 sm_allemp
rename value11 sm_wkly_earn_allemp

rename value06 sm_prodemp
rename value30 sm_wkly_earn_prodemp

drop value*

// Convert to constant USD
merge n:1 year month using "$work/01-import-cu/bls-cpi.dta", ///
    nogenerate keep(match) keepusing(cpi)
replace sm_wkly_earn_allemp = sm_wkly_earn_allemp/cpi
replace sm_wkly_earn_prodemp = sm_wkly_earn_prodemp/cpi
drop cpi

// Take moving averages for earnings series
generate time = ym(year, month)
gegen id = group(state_code area_code supersector_code industry_code)
tsset id time, monthly

ereplace sm_wkly_earn_allemp = filter(sm_wkly_earn_allemp), lags(0/11) normalize
ereplace sm_wkly_earn_prodemp = filter(sm_wkly_earn_prodemp), lags(0/11) normalize

tsset, clear
drop id time

// Discard old data
keep if year >= 1990

preserve
    drop if industry_code == "000000"
    drop supersector_code
    gisid state_code area_code industry_code year month
    save "$work/01-import-sm/sm-industry.dta", replace
    keep if area_code == "00000"
    drop area_code
    gisid state_code industry_code year month
    save "$work/01-import-sm/sm-state-industry.dta", replace
restore

preserve
    keep if industry_code == "000000"
    drop industry_code
    gisid state_code area_code supersector_code year month
    save "$work/01-import-sm/sm-supersector.dta", replace
    keep if area_code == "00000"
    drop area_code
    gisid state_code supersector_code year month
    save "$work/01-import-sm/sm-state-supersector.dta", replace
restore
