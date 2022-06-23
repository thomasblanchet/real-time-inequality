// -------------------------------------------------------------------------- //
// Import the BLS's price index (CPI for all urban consumers)
// -------------------------------------------------------------------------- //

import delimited "https://download.bls.gov/pub/time.series/cu/cu.data.1.AllItems", ///
    varnames(1) delimiter("\t") clear encoding(utf8)

destring value, ignore("- ") replace
destring period, ignore("MS") replace
drop footnote_codes

// Parse series ID
generate seasonal_code    = substr(series_id, 3, 1)
generate periodicity_code = substr(series_id, 4, 1)
generate area_code        = substr(series_id, 5, 4)
generate item_code        = substr(series_id, 9, .)
drop series_id

keep if strtrim(item_code) == "SA0"
keep if area_code == "0000"
keep if periodicity_code == "R"
keep if seasonal_code == "S"
drop if period == 13

rename period month

keep year month value
rename value cpi
sort year month
replace cpi = cpi/cpi[_N]

save "$work/01-import-cu/bls-cpi.dta", replace

