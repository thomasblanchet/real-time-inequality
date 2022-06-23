// -------------------------------------------------------------------------- //
// Import some DINA macroeconomic parameters to adjust microfiles
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Macro parameters
// -------------------------------------------------------------------------- //

import excel "$rawdata/dina-data/parameters.xlsx", clear firstrow
rename yr year
drop if missing(year)

save "$work/01-import-dina-macro/dina-macro-parameters.dta", replace

// -------------------------------------------------------------------------- //
// Detailed wealth data
// -------------------------------------------------------------------------- //

import excel "$rawdata/dina-data/DINA(Aggreg).xlsx", sheet("DataWealth") cellrange("A12") clear

drop if missing(A)
rename A year
rename EM lm883164133q

expand 4
sort year
by year: generate quarter = _n

generate time = yq(year, quarter)
foreach v of varlist lm883164133q {
    replace `v' = . if quarter != 2
    ipolate `v' time, gen(i)
    replace lm883164133q = 1000*i
    drop i
}

keep year quarter lm883164133q

save "$work/01-import-dina-macro/dina-wealth-detailed.dta", replace

// -------------------------------------------------------------------------- //
// Separate income paid vs. received of the government
// -------------------------------------------------------------------------- //

import excel "$rawdata/dina-data/DINA(Aggreg).xlsx", sheet("TA3") cellrange("A8:V115") clear

rename A year
rename U ttgovin_rec
rename V ttgovin_pay

keep year ttgovin_rec ttgovin_pay

replace ttgovin_pay = -ttgovin_pay
generate ttgovin = ttgovin_rec + ttgovin_pay

save "$work/01-import-dina-macro/dina-govin.dta", replace

// -------------------------------------------------------------------------- //
// Store aside NPISH account (yearly) to make adjustment to DINA variables
// -------------------------------------------------------------------------- //

import excel "$rawdata/dina-data/DINA(Aggreg).xlsx", sheet("TSA4") cellrange("A9:G116") clear

rename A year
rename B ttnpinc
rename C ttnpinc_nos
rename D ttnpinc_div
generate ttnpinc_int = E - F

keep year ttnpinc*

// Sanity check
assert reldif(ttnpinc_nos + ttnpinc_div + ttnpinc_int, ttnpinc) < 1e-5

save "$work/01-import-dina-macro/dina-npinc.dta", replace

// -------------------------------------------------------------------------- //
// Also retrieve decomposition of difference between proprietor's income
// and mixed income
// -------------------------------------------------------------------------- //

import excel "$rawdata/dina-data/DINA(Aggreg).xlsx", sheet("TSA3") cellrange("A10:AK116") clear

rename A year
rename AG ttnmix
rename AH ttproprietors
rename AI ttbustrans
rename AJ ttroyalties
rename AK ttrental_ncor
rename AB ttfin_ncor
rename AF ttmiscpay

keep year ttnmix ttproprietors ttbustrans ttroyalties ttrental_ncor ttfin_ncor ttmiscpay

// Sanity check
assert reldif(ttproprietors + ttbustrans + ttroyalties - ttrental_ncor, ttnmix) < 1e-5

save "$work/01-import-dina-macro/dina-nmix-proprietors.dta", replace
