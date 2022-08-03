// -------------------------------------------------------------------------- //
// Age the QCEW file based on more recent statistics
// -------------------------------------------------------------------------- //

// Retrieve most recent dates from BLS data
use "$work/01-import-sm/sm-state-supersector.dta", clear
summarize year, meanonly
global sm_last_year = r(max)
summarize month if year == $sm_last_year, meanonly
global sm_last_month = r(max)

use "$work/01-import-ce/ce-supersector.dta", clear
summarize year, meanonly
global ce_last_year = r(max)
summarize month if year == $ce_last_year, meanonly
global ce_last_month = r(max)

// -------------------------------------------------------------------------- //
// Import crosswalk between NAICS codes (used by QCEW) and BLS/CES industry codes
// -------------------------------------------------------------------------- //

import delimited "$rawdata/crosswalks/bls-naics-crosswalk.csv", delimit(",") clear encoding(utf8)

generate ownership_code = .
replace ownership_code = 8 if ownership == "All government"
replace ownership_code = 1 if ownership == "Federal Government"
replace ownership_code = 3 if ownership == "Local Government"
replace ownership_code = 5 if ownership == "Private"
replace ownership_code = 0 if ownership == "Private and all government"
replace ownership_code = 2 if ownership == "State Government"
replace ownership_code = . if ownership == "State and Local Government"

replace naicscode = substr(cesindustrycode, 4, 6) if substr(cesindustrycode, 1, 2) == "90"
replace naicscode = ustrregexs(1) if substr(cesindustrycode, 1, 2) == "90" & ustrregexm(naicscode, "^([0-9]*?)0*$")

save "$work/01-import-sm/bls-naics-crosswalk.dta", replace

// -------------------------------------------------------------------------- //
// Make extrapolations in QCEW data
// -------------------------------------------------------------------------- //

use "$work/02-disaggregate-qcew/qcew-monthly.dta", clear
// We only update the latest version of the data
keep if version == "NAICS"

gegen id = group(area_fips own_code industry_code)

// -------------------------------------------------------------------------- //
// Add missing recent dates by duplicating the most recent observations
// -------------------------------------------------------------------------- //

summarize year, meanonly
global qcew_last_year = r(max)
summarize month if year == $qcew_last_year, meanonly
global qcew_last_month = r(max)

local last_date_bls = max( ///
    12*$ce_last_year + $ce_last_month - 1, ///
    12*$sm_last_year + $sm_last_month - 1 ///
)
local last_data_qcew = 12*$qcew_last_year + $qcew_last_month - 1
local missing_dates = `last_date_bls' - `last_data_qcew' + 1

expand `missing_dates' if year == $qcew_last_year & month == $qcew_last_month, generate(new)
replace mthly_emplvl = . if new
replace avg_mthly_wages = . if new
hashsort version area_fips own_code industry_code year month new
by version area_fips own_code industry_code: replace month = month + sum(new)
replace year = year + floor((month - 1)/12)
replace month = 1 + mod(month - 1, 12)

// -------------------------------------------------------------------------- //
// Match BLS/SM statistics
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Match the QCEW observations with their finest geographic location
// available in the BLS series
// -------------------------------------------------------------------------- //

// Match QCEW locations (counties with FIPS codes) to the CBSAs in
// the BLS "State and Area Employment, Hours and Earnings" series
generate fipsstatecode  = substr(area_fips, 1, 2)
generate fipscountycode = substr(area_fips, 3, 3)
fmerge m:1 fipsstatecode fipscountycode using "$rawdata/crosswalks/cbsa2fipsxw.dta", ///
    keep(master match) keepusing(cbsacode)
// If a county in not included in the major labor areas, we give it its
// state-wide series (code 00000 in BLS data)
replace cbsacode = "00000" if _merge == 1
drop _merge
// BLS series actually only include a subset of CBSA codes, so we replace
// unavailable CBSA codes by their statewide value
rename cbsacode area_code
fmerge m:1 area_code using "$work/01-import-sm/bls-sm-area.dta", ///
    keep(master match) keepusing(area_code)
replace area_code = "00000" if _merge == 1
drop _merge
rename fipsstatecode state_code
drop fipscountycode

// -------------------------------------------------------------------------- //
// Create industry/sector codes that can be used to match QCEW data
// with "State and Area Employment, Hours and Earnings" series
// -------------------------------------------------------------------------- //

// Code the various NAICS levels
generate naics6_code = substr(industry_code, 1, 6)
generate naics5_code = substr(industry_code, 1, 5)
generate naics4_code = substr(industry_code, 1, 4)
generate naics3_code = substr(industry_code, 1, 3)
generate naics2_code = substr(industry_code, 1, 2)

// Code BLS supersectors 
// (see https://www.bls.gov/sae/additional-resources/naics-supersectors-for-ces-program.htm)

// Zero-level BLS supersector (All Nonfarm)
generate bls_sector_code0 = ""

replace bls_sector_code0 = "00" if inlist(naics4_code, "1133") | inlist(naics2_code, "21")
replace bls_sector_code0 = "00" if inlist(naics2_code, "23")
replace bls_sector_code0 = "00" if inlist(naics2_code, "31", "32", "33")
replace bls_sector_code0 = "00" if inlist(naics2_code, "42", "44", "45", "48", "49", "22")
replace bls_sector_code0 = "00" if inlist(naics2_code, "51")
replace bls_sector_code0 = "00" if inlist(naics2_code, "52", "53")
replace bls_sector_code0 = "00" if inlist(naics2_code, "54", "55", "56")
replace bls_sector_code0 = "00" if inlist(naics2_code, "61", "62")
replace bls_sector_code0 = "00" if inlist(naics2_code, "71", "72")
replace bls_sector_code0 = "00" if inlist(naics2_code, "81")

replace bls_sector_code0 = "00" if inlist(naics2_code, "91", "92", "93")

// First level BLS Supersectors
generate bls_sector_code1 = ""

replace bls_sector_code1 = "05" if inlist(naics4_code, "1133") | inlist(naics2_code, "21")
replace bls_sector_code1 = "05" if inlist(naics2_code, "23")
replace bls_sector_code1 = "05" if inlist(naics2_code, "31", "32", "33")
replace bls_sector_code1 = "05" if inlist(naics2_code, "42", "44", "45", "48", "49", "22")
replace bls_sector_code1 = "05" if inlist(naics2_code, "51")
replace bls_sector_code1 = "05" if inlist(naics2_code, "52", "53")
replace bls_sector_code1 = "05" if inlist(naics2_code, "54", "55", "56")
replace bls_sector_code1 = "05" if inlist(naics2_code, "61", "62")
replace bls_sector_code1 = "05" if inlist(naics2_code, "71", "72")
replace bls_sector_code1 = "05" if inlist(naics2_code, "81")

replace bls_sector_code1 = "90" if inlist(naics2_code, "91", "92", "93")

// Second level BLS Supersectors
generate bls_sector_code2 = ""

replace bls_sector_code2 = "06" if inlist(naics4_code, "1133") | inlist(naics2_code, "21")
replace bls_sector_code2 = "06" if inlist(naics2_code, "23")
replace bls_sector_code2 = "06" if inlist(naics2_code, "31", "32", "33")

replace bls_sector_code2 = "08" if inlist(naics2_code, "42", "44", "45", "48", "49", "22")
replace bls_sector_code2 = "08" if inlist(naics2_code, "51")
replace bls_sector_code2 = "08" if inlist(naics2_code, "52", "53")
replace bls_sector_code2 = "08" if inlist(naics2_code, "54", "55", "56")
replace bls_sector_code2 = "08" if inlist(naics2_code, "61", "62")
replace bls_sector_code2 = "08" if inlist(naics2_code, "71", "72")
replace bls_sector_code2 = "08" if inlist(naics2_code, "81")

replace bls_sector_code2 = "90" if inlist(naics2_code, "91", "92", "93")

// Third level BLS Supersectors
generate bls_sector_code3 = ""

replace bls_sector_code3 = "15" if inlist(naics4_code, "1133") | inlist(naics2_code, "21")
replace bls_sector_code3 = "15" if inlist(naics2_code, "23")
replace bls_sector_code3 = "30" if inlist(naics2_code, "31", "32", "33")

replace bls_sector_code3 = "40" if inlist(naics2_code, "42", "44", "45", "48", "49", "22")
replace bls_sector_code3 = "50" if inlist(naics2_code, "51")
replace bls_sector_code3 = "55" if inlist(naics2_code, "52", "53")
replace bls_sector_code3 = "60" if inlist(naics2_code, "54", "55", "56")
replace bls_sector_code3 = "65" if inlist(naics2_code, "61", "62")
replace bls_sector_code3 = "70" if inlist(naics2_code, "71", "72")
replace bls_sector_code3 = "80" if inlist(naics2_code, "81")

replace bls_sector_code3 = "90" if inlist(naics2_code, "91", "92", "93")

// Fourth level BLS Supersectors
generate bls_sector_code4 = ""

replace bls_sector_code4 = "10" if inlist(naics4_code, "1133") | inlist(naics2_code, "21")
replace bls_sector_code4 = "20" if inlist(naics2_code, "23")

replace bls_sector_code4 = "31" if inlist(naics2_code, "31")
replace bls_sector_code4 = "32" if inlist(naics2_code, "32", "33")

replace bls_sector_code4 = "41" if inlist(naics2_code, "42")
replace bls_sector_code4 = "42" if inlist(naics2_code, "44", "45", "48")
replace bls_sector_code4 = "43" if inlist(naics2_code, "49", "22")

replace bls_sector_code4 = "50" if inlist(naics2_code, "51")
replace bls_sector_code4 = "55" if inlist(naics2_code, "52", "53")
replace bls_sector_code4 = "60" if inlist(naics2_code, "54", "55", "56")
replace bls_sector_code4 = "65" if inlist(naics2_code, "61", "62")
replace bls_sector_code4 = "70" if inlist(naics2_code, "71", "72")
replace bls_sector_code4 = "80" if inlist(naics2_code, "81")

replace bls_sector_code4 = "90" if inlist(naics2_code, "91", "92", "93")

// -------------------------------------------------------------------------- //
// Match employment and earnings from SM in two versions: one that matches
// on the detailed CBSA, anoher that matches at the state level only, with
// potentially more detailed industry match
// -------------------------------------------------------------------------- //

rename industry_code industry_code_qcew

// -------------------------------------------------------------------------- //
// First: priority to location in the matching
// -------------------------------------------------------------------------- //

generate sm_cbsa_allemp = .
generate sm_cbsa_wkly_earn_allemp = .
generate sm_cbsa_prodemp = .
generate sm_cbsa_wkly_earn_prodemp = .

foreach i of numlist 6(-1)2 {
    generate industry_code = naics`i'_code + "0"*(6 - `i')
    
    merge n:1 state_code area_code industry_code year month using "$work/01-import-sm/sm-industry.dta", nogenerate ///
        keep(master match) keepusing(sm_allemp sm_wkly_earn_allemp sm_prodemp sm_wkly_earn_prodemp)

    foreach stub in allemp wkly_earn_allemp prodemp wkly_earn_prodemp {
        gegen all_missing = min(missing(sm_cbsa_`stub')), by(id)
        replace sm_cbsa_`stub' = sm_`stub' if all_missing
        drop sm_`stub' all_missing
    }
    drop industry_code
}

// If we couldn't match based on industry, match based on supersector
foreach i of numlist 4(-1)0 {
    generate supersector_code = bls_sector_code`i'
    
    merge m:1 state_code area_code supersector_code year month using "$work/01-import-sm/sm-supersector.dta", nogenerate ///
        keep(master match) keepusing(sm_allemp sm_wkly_earn_allemp sm_prodemp sm_wkly_earn_prodemp)
        
    foreach stub in allemp wkly_earn_allemp prodemp wkly_earn_prodemp {
        gegen all_missing = min(missing(sm_cbsa_`stub')), by(id)
        replace sm_cbsa_`stub' = sm_`stub' if all_missing
        drop sm_`stub' all_missing
    }
    drop supersector_code
}

// -------------------------------------------------------------------------- //
// Second: state-level matching, more detailed industry
// -------------------------------------------------------------------------- //

generate sm_state_allemp = .
generate sm_state_wkly_earn_allemp = .
generate sm_state_prodemp = .
generate sm_state_wkly_earn_prodemp = .

foreach i of numlist 6(-1)2 {
    generate industry_code = naics`i'_code + "0"*(6 - `i')
    
    merge n:1 state_code industry_code year month using "$work/01-import-sm/sm-state-industry.dta", nogenerate ///
        keep(master match) keepusing(sm_allemp sm_wkly_earn_allemp sm_prodemp sm_wkly_earn_prodemp)
        
    foreach stub in allemp wkly_earn_allemp prodemp wkly_earn_prodemp {
        gegen all_missing = min(missing(sm_state_`stub')), by(id)
        replace sm_state_`stub' = sm_`stub' if all_missing
        drop sm_`stub' all_missing
    }
    drop industry_code
}

// If we couldn't match based on industry, match based on supersector
foreach i of numlist 4(-1)0 {
    generate supersector_code = bls_sector_code`i'
    
    merge n:1 state_code supersector_code year month using "$work/01-import-sm/sm-state-supersector.dta", nogenerate ///
        keep(master match) keepusing(sm_allemp sm_wkly_earn_allemp sm_prodemp sm_wkly_earn_prodemp)
        
    foreach stub in allemp wkly_earn_allemp prodemp wkly_earn_prodemp {
        gegen all_missing = min(missing(sm_state_`stub')), by(id)
        replace sm_state_`stub' = sm_`stub' if all_missing
        drop sm_`stub' all_missing
    }
    drop supersector_code
}

// -------------------------------------------------------------------------- //
// Now match with the CE data (national level, more detailed industry)
// -------------------------------------------------------------------------- //

generate ce_nat_allemp = .
generate ce_nat_wkly_earn_allemp = .
generate ce_nat_prodemp = .
generate ce_nat_wkly_earn_prodemp = .

foreach i of numlist 6(-1)2 {
    generate industry_code = naics`i'_code + "0"*(6 - `i')
    
    merge n:1 industry_code year month using "$work/01-import-ce/ce-industry.dta", nogenerate ///
        keep(master match) keepusing(ce_allemp ce_wkly_earn_allemp ce_prodemp ce_wkly_earn_prodemp)
        
    foreach stub in allemp wkly_earn_allemp prodemp wkly_earn_prodemp {
        gegen all_missing = min(missing(ce_nat_`stub')), by(id)
        replace ce_nat_`stub' = ce_`stub' if all_missing
        drop ce_`stub' all_missing
    }
    drop industry_code
}

// If we couldn't match based on industry, match based on supersector
foreach i of numlist 4(-1)0 {
    generate supersector_code = bls_sector_code`i'
    
    merge n:1 supersector_code year month using "$work/01-import-ce/ce-supersector.dta", nogenerate ///
        keep(master match) keepusing(ce_allemp ce_wkly_earn_allemp ce_prodemp ce_wkly_earn_prodemp)
        
    foreach stub in allemp wkly_earn_allemp prodemp wkly_earn_prodemp {
        gegen all_missing = min(missing(ce_nat_`stub')), by(id)
        replace ce_nat_`stub' = ce_`stub' if all_missing
        drop ce_`stub' all_missing
    }
    drop supersector_code
}

drop naics* bls*

// -------------------------------------------------------------------------- //
// Perform extrapolations
// -------------------------------------------------------------------------- //

rename industry_code_qcew industry_code

// Convert predictors to real
merge n:1 year month using "$work/01-import-cu/bls-cpi.dta", ///
    keep(master match) assert(match using) nogenerate keepusing(cpi)
    
foreach v of varlist sm_state_wkly_earn_allemp sm_state_wkly_earn_prodemp ///
                     sm_cbsa_wkly_earn_allemp sm_cbsa_wkly_earn_prodemp ///
                     ce_nat_wkly_earn_allemp ce_nat_wkly_earn_prodemp {
                         
    replace `v' = `v'/cpi
}
drop cpi

// Set up panel
generate time = ym(year, month)
tsset id time, monthly

// Numeric version of group variables (for reghdfe)
gegen area_fips_fe = group(area_fips)
gegen industry_code_fe = group(own_code industry_code)
gegen industry_code_month_fe = group(own_code industry_code month)

// We seek to predict changes in employment and wages
generate chg_mthly_emplvl    = log(mthly_emplvl) - log(L.mthly_emplvl)
generate chg_avg_mthly_wages = log(avg_mthly_wages) - log(L.avg_mthly_wages)

// Put predictors in the right format
generate chg_sm_state_allemp           = log(sm_state_allemp) - log(L.sm_state_allemp)
generate chg_sm_state_wkly_earn_allemp = log(sm_state_wkly_earn_allemp) - log(L.sm_state_wkly_earn_allemp)

generate chg_sm_cbsa_allemp           = log(sm_cbsa_allemp) - log(L.sm_cbsa_allemp)
generate chg_sm_cbsa_wkly_earn_allemp = log(sm_cbsa_wkly_earn_allemp) - log(L.sm_cbsa_wkly_earn_allemp)

generate chg_ce_nat_allemp           = log(ce_nat_allemp) - log(L.ce_nat_allemp)
generate chg_ce_nat_wkly_earn_allemp = log(ce_nat_wkly_earn_allemp) - log(L.ce_nat_wkly_earn_allemp)

// For wages, average the predictions
egen chg_avg_mthly_wages_pred = rowmean(chg_sm_state_wkly_earn_allemp chg_sm_cbsa_wkly_earn_allemp chg_ce_nat_wkly_earn_allemp)

// For employment, use the average of the different prediction
egen chg_mthly_emplvl_pred = rowmean(chg_sm_state_allemp chg_sm_cbsa_allemp chg_ce_nat_allemp)

// For missing values, take average by bracket
by id: carryforward avg_mthly_wages mthly_emplvl, gen(last_avg_mthly_wages last_mthly_emplvl)
gquantiles bracket = last_avg_mthly_wages [aw=last_mthly_emplvl], xtile nquantiles(20)

gegen avg_chg_mthly_emplvl_pred = mean(chg_mthly_emplvl_pred), by(bracket year month)
gegen avg_chg_avg_mthly_wages_pred = mean(chg_avg_mthly_wages_pred), by(bracket year month)
assert !missing(avg_chg_mthly_emplvl_pred) if new // If this fails, try reducing number of brackets
assert !missing(avg_chg_avg_mthly_wages_pred) if new // If this fails, try reducing number of brackets

replace chg_mthly_emplvl_pred = avg_chg_mthly_emplvl_pred if missing(chg_mthly_emplvl_pred)
replace chg_avg_mthly_wages_pred = avg_chg_avg_mthly_wages_pred if missing(chg_avg_mthly_wages_pred)

// Predict residual via FE only regression
gegen industry_fe = group(own_code industry_code month)
foreach y of varlist chg_mthly_emplvl chg_avg_mthly_wages {
    generate resid = `y' - `y'_pred
    reghdfe resid [aw=mthly_emplvl], verbose(1) coeflegend absorb(area_fips industry_fe, savefe)
    generate __hdfe0__ = _b[_cons]
    gegen __hdfe1__ = firstnm(__hdfe1__), by(area_fips) replace
    gegen __hdfe2__ = firstnm(__hdfe2__), by(industry_fe) replace
    // If fixed effect missing, assume zero
    forvalues i = 1/2 {
        replace __hdfe`i'__ = 0 if missing(__hdfe`i'__)
    }
    // Make prediction
    replace `y'_pred = `y'_pred + __hdfe0__ + __hdfe1__ + __hdfe2__
    drop __hdfe* resid
}
drop industry_fe

// Save that version of the dataset for backtesting purposes
save "$work/02-update-qcew/qcew-monthly-updated-backtesting.dta", replace

replace chg_avg_mthly_wages = chg_avg_mthly_wages_pred if new
replace chg_mthly_emplvl = chg_mthly_emplvl_pred if new

// Cumulate to get prediction
by id: replace mthly_emplvl = last_mthly_emplvl*exp(sum(chg_mthly_emplvl)) if new
by id: replace avg_mthly_wages = last_avg_mthly_wages*exp(sum(chg_avg_mthly_wages)) if new

tsset, clear
keep area_fips own_code industry_code year version month mthly_emplvl avg_mthly_wages

save "$work/02-update-qcew/qcew-monthly-updated.dta", replace

// Add SIC version of the data as well (not extrapolated)
use "$work/02-disaggregate-qcew/qcew-monthly.dta", clear
keep if version == "SIC"
drop is_imputed
append using "$work/02-update-qcew/qcew-monthly-updated.dta"
save "$work/02-update-qcew/qcew-monthly-updated.dta", replace

// -------------------------------------------------------------------------- //
// Do backtesting of the extrapolation
// -------------------------------------------------------------------------- //

use if year >= 2019 using "$work/02-update-qcew/qcew-monthly-updated-backtesting.dta", clear

// Indicator for the backtesting period
generate bt = (year >= 2020)

// Last value before backtesting
generate last_mthly_emplvl_bt = mthly_emplvl if year == 2019 & month == 12
generate last_avg_mthly_wages_bt = avg_mthly_wages if year == 2019 & month == 12
sort id year month
by id: carryforward last_mthly_emplvl_bt last_avg_mthly_wages_bt, replace

// Cumulate to get prediction
by id: generate mthly_emplvl_bt = last_mthly_emplvl_bt*exp(sum(chg_mthly_emplvl_pred)) if bt
by id: generate avg_mthly_wages_bt = last_avg_mthly_wages_bt*exp(sum(chg_avg_mthly_wages_pred)) if bt

// Aggregate by quintile
drop bracket
replace avg_mthly_wages_bt = avg_mthly_wages if time < ym(2020, 01)
gquantiles bracket = avg_mthly_wages_bt [aw=mthly_emplvl], xtile nquantiles(4) by(year month)
replace avg_mthly_wages_bt = . if time < ym(2020, 01)
gcollapse (mean) mthly_emplvl mthly_emplvl_bt avg_mthly_wages avg_mthly_wages_bt [aw=mthly_emplvl], by(bracket year month)

// Make into an index and plot
generate time = ym(year, month)
format time %tm
sort bracket time
foreach v of varlist mthly_emplvl_bt avg_mthly_wages_bt mthly_emplvl avg_mthly_wages {
    generate ref = `v' if year == 2020 & month == 1
    gegen ref = min(ref), by(bracket) replace
    replace `v' = 100*`v'/ref
    drop ref
}

// Rescale wage growth (since wage income will be normalized)
gegen avg_wages_bt = mean(avg_mthly_wages_bt) [pw=mthly_emplvl_bt], by(time)
gegen avg_wages = mean(avg_mthly_wages) [pw=mthly_emplvl], by(time)
replace avg_mthly_wages_bt = avg_mthly_wages_bt/avg_wages_bt*avg_wages

generate quartile = ""
replace quartile = "1st quartile" if bracket == 1
replace quartile = "2nd quartile" if bracket == 2
replace quartile = "3rd quartile" if bracket == 3
replace quartile = "4th quartile" if bracket == 4

keep if inrange(time, ym(2019, 10), ym(2020, 06))

gr tw con mthly_emplvl mthly_emplvl_bt time, by(quartile, note("")) ///
    ytitle("Employment level (01/2020 = 100)") xtitle("") xlabel(`=ym(2019, 11)'(2)`=ym(2020, 6)', labsize(small)) ///
    lw(medthick..) col(ebblue cranberry) msize(small) msym(Oh Sh) ///
    legend(label(1 "True") label(2 "Extrapolated after 01/2020"))
graph export "$graphs/02-update-qcew/extrapolation-backtest-employment.pdf", replace
    
gr tw con avg_mthly_wages avg_mthly_wages_bt time, by(quartile, note("")) ///
    ytitle("Average wage (01/2020 = 100)") xtitle("") xlabel(`=ym(2019, 11)'(2)`=ym(2020, 6)', labsize(small)) ///
    lw(medthick..) col(ebblue cranberry) msize(small) msym(Oh Sh) ///
    legend(label(1 "True") label(2 "Extrapolated after 01/2020"))
graph export "$graphs/02-update-qcew/extrapolation-backtest-wage.pdf", replace

// -------------------------------------------------------------------------- //
// Perform systematic backtesting of CES extrapolation
// -------------------------------------------------------------------------- //

global date_begin = ym(2007, 12)
global date_end = ym(2021, 12)

quietly {
    foreach t of numlist $date_begin (3) $date_end {
        use id year month time mthly_emplvl avg_mthly_wages chg_mthly_emplvl_pred chg_avg_mthly_wages_pred ///
            if inrange(time, `t', `t' + 6) using "$work/02-update-qcew/qcew-monthly-updated-backtesting.dta", clear
        
        local year = year(dofm(`t'))
        local month = month(dofm(`t'))
        
        // Last value before backtesting
        generate last_mthly_emplvl_bt = mthly_emplvl if time == `t'
        generate last_avg_mthly_wages_bt = avg_mthly_wages if time == `t'
        //sort id year month
        by id: carryforward last_mthly_emplvl_bt last_avg_mthly_wages_bt, replace

        // Cumulate to get prediction
        replace chg_mthly_emplvl_pred = 0 if time == `t'
        replace chg_avg_mthly_wages_pred = 0 if time == `t'
        by id: generate mthly_emplvl_bt`t' = last_mthly_emplvl_bt*exp(sum(chg_mthly_emplvl_pred))
        by id: generate avg_mthly_wages_bt`t' = last_avg_mthly_wages_bt*exp(sum(chg_avg_mthly_wages_pred))

        drop last_mthly_emplvl_bt last_avg_mthly_wages_bt chg_mthly_emplvl_pred chg_avg_mthly_wages_pred
        
        compress
        save "$work/02-update-qcew/backtesting-ces/qcew-ces-backtesting`t'.dta", replace
        
        noisily di "* `year'm`month'"
    }
}

clear

use if version == "NAICS" & inrange(ym(year, month), $date_begin, $date_end + 6) ///
    using "$work/02-update-qcew/qcew-monthly-updated.dta", clear

// Tabulate
hashsort year month avg_mthly_wages

by year month: generate rank = sum(mthly_emplvl)
by year month: replace rank = 1e5*(rank - mthly_emplvl/2)/rank[_N]

egen p = cut(rank), at(0(1000)99000 100001)

gcollapse (mean) avg_mthly_wages [aw=mthly_emplvl], by(year month p)

save "$work/02-update-qcew/backtesting-ces/qcew-ces-backtesting-tabulations.dta", replace

foreach t of numlist $date_begin (3) $date_end {
    use "$work/02-update-qcew/backtesting-ces/qcew-ces-backtesting`t'.dta", clear
    
    // Tabulate
    hashsort year month avg_mthly_wages_bt`t'

    by year month: generate rank = sum(mthly_emplvl_bt`t')
    by year month: replace rank = 1e5*(rank - mthly_emplvl_bt`t'/2)/rank[_N]

    egen p = cut(rank), at(0(1000)99000 100001)

    gcollapse (mean) avg_mthly_wages=avg_mthly_wages_bt`t' [aw=mthly_emplvl_bt`t'], by(year month p)
    
    generate bt = `t'
    format bt %tm
    
    append using "$work/02-update-qcew/backtesting-ces/qcew-ces-backtesting-tabulations.dta"
    save "$work/02-update-qcew/backtesting-ces/qcew-ces-backtesting-tabulations.dta", replace
}

use "$work/02-update-qcew/backtesting-ces/qcew-ces-backtesting-tabulations.dta", clear

generate time = ym(year, month)
format time %tm

hashsort bt year month

gegen total = total(avg_mthly_wages), by(bt year month)
generate share = 100*avg_mthly_wages/total

generate bracket = ""
replace bracket = "bot50" if inrange(p, 0, 49000)
replace bracket = "top10" if inrange(p, 90000, 100000)

gcollapse (sum) share if year >= 2019, by(year month time bt bracket)

gr tw (line share time if missing(bt) & bracket == "bot50", col(ebblue) lw(medthick)) ///
    (line share time if bt == 713 & bracket == "bot50", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 716 & bracket == "bot50", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 719 & bracket == "bot50", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 722 & bracket == "bot50", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 725 & bracket == "bot50", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 728 & bracket == "bot50", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 731 & bracket == "bot50", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 734 & bracket == "bot50", col(cranberry) lw(medthick) lp(dash)), ///
    xtitle("") ytitle("Bottom 50% wage income share in QCEW (%)") ///
    legend(label(1 "QCEW") label(2 "Extrapolation from CES") order(1 2)) 
graph export "$graphs/02-update-qcew/extrapolation-bot50.pdf", replace

gr tw (line share time if missing(bt) & bracket == "top10", col(ebblue) lw(medthick)) ///
    (line share time if bt == 713 & bracket == "top10", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 716 & bracket == "top10", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 719 & bracket == "top10", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 722 & bracket == "top10", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 725 & bracket == "top10", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 728 & bracket == "top10", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 731 & bracket == "top10", col(cranberry) lw(medthick) lp(dash)) ///
    (line share time if bt == 734 & bracket == "top10", col(cranberry) lw(medthick) lp(dash)), ///
    xtitle("") ytitle("Top 10% wage income share in QCEW (%)") ///
    legend(label(1 "QCEW") label(2 "Extrapolation from CES") order(1 2)) 
graph export "$graphs/02-update-qcew/extrapolation-top10.pdf", replace

