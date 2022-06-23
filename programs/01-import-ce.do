// -------------------------------------------------------------------------- //
// Import BLS Employment, Hours, and Earnings (National, NAICS)
// -------------------------------------------------------------------------- //

import delimited "https://download.bls.gov/pub/time.series/ce/ce.data.0.AllCESSeries", ///
    varnames(1) delimiter("\t") clear encoding(utf8)

destring value, ignore("- ") replace
destring period, ignore("M") replace
drop footnote_codes

// Parse series ID
generate seasonal_code    = substr(series_id, 3, 1)
generate supersector_code = substr(series_id, 4, 2)
generate industry_code    = substr(series_id, 6, 6)
generate data_type_code   = substr(series_id, 12, 2)
drop series_id

// Remove annual averages
drop if period == 13
rename period month

// Export total nonfarm employment
preserve
    keep if seasonal_code == "S" & supersector_code == "00" & industry_code == "000000" & data_type_code == "01"
    keep year month value
    replace value = 1000*value
    rename value ce_employed
    save "$work/01-import-ce/ce-employment.dta", replace
restore

// Remove seasonally adjusted series
drop if seasonal_code == "S"
drop seasonal_code

// Make one column per data type
greshape wide value, i(year month supersector_code industry_code) j(data_type_code) string

rename value01 ce_allemp
rename value15 ce_wkly_earn_allemp

rename value06 ce_prodemp
rename value33 ce_wkly_earn_prodemp

drop value*

// Convert to constant USD
merge n:1 year month using "$work/01-import-cu/bls-cpi.dta", nogenerate keep(match) keepusing(cpi)
replace ce_wkly_earn_allemp = ce_wkly_earn_allemp/cpi
replace ce_wkly_earn_prodemp = ce_wkly_earn_prodemp/cpi
drop cpi

// Take moving averages for earnings series
generate time = ym(year, month)
gegen id = group(supersector_code industry_code)
tsset id time, monthly

ereplace ce_wkly_earn_allemp = filter(ce_wkly_earn_allemp), lags(0/11) normalize
ereplace ce_wkly_earn_prodemp = filter(ce_wkly_earn_prodemp), lags(0/11) normalize

tsset, clear
drop id time

// Discard old data
keep if year >= 1990

// Save
sort supersector_code industry_code year month
compress

preserve
    drop if industry_code == "000000"
    drop supersector_code
    gisid industry_code year month
    save "$work/01-import-ce/ce-industry.dta", replace
restore

preserve
    keep if industry_code == "000000"
    drop industry_code
    gisid supersector_code year month
    save "$work/01-import-ce/ce-supersector.dta", replace
restore
