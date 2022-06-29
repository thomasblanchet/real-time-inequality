// -------------------------------------------------------------------------- //
// Create monthly version of QCEW data
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Combine NAICS and SIC files
// -------------------------------------------------------------------------- //

use "$work/01-import-qcew/qcew-raw.dta", clear
generate version = "NAICS"
append using "$work/01-import-qcew/qcew-legacy-raw.dta"
replace version = "SIC" if missing(version)

// Fix typo in the input file
replace month2_emplvl = 153 if month2_emplvl == 30000153 & ///
    area_fips == "12103" & ///
    industry_code == "SIC_0J92" & ///
    own_code == 3
    
// -------------------------------------------------------------------------- //
// Simple disaggregation: get monthly employment levels, keep average
// quarterly wage
// -------------------------------------------------------------------------- //

generate qtrly_emplvl = month1_emplvl + month2_emplvl + month3_emplvl
drop if qtrly_emplvl == 0

expand 3
hashsort version area_fips own_code industry_code year qtr
by version area_fips own_code industry_code year qtr: generate month = _n

generate mthly_emplvl = .
replace mthly_emplvl = month1_emplvl if month == 1
replace mthly_emplvl = month2_emplvl if month == 2
replace mthly_emplvl = month3_emplvl if month == 3
drop month1_emplvl month2_emplvl month3_emplvl
drop if mthly_emplvl == 0
replace month = (qtr - 1)*3 + month

// Calculate average monthly wages in constant USD
merge n:1 year month using "$work/01-import-cu/bls-cpi.dta", ///
    keep(master match) assert(match using) keepusing(cpi) nogenerate

hashsort version area_fips own_code industry_code year qtr
gegen qtrly_cpi = mean(cpi), by(version area_fips own_code industry_code year qtr)
by version area_fips own_code industry_code year qtr: generate avg_mthly_wages = total_qtrly_wages/qtrly_emplvl/qtrly_cpi

drop qtr qtrly_emplvl total_qtrly_wages qtrly_cpi cpi

// -------------------------------------------------------------------------- //
// Take a 12-month moving average of wages, to get rid of seasonality,
// and assuming that they are sticky anyway
// -------------------------------------------------------------------------- //

gegen id = group(version area_fips own_code industry_code)
generate time = ym(year, month)

tsset id time, monthly

egen avg_mthly_wages_ma = filter(avg_mthly_wages), lags(0/11) normalize
// Drop first year of data because of moving average
drop if version == "SIC" & year == 1975
drop if version == "NAICS" & year == 1990

// -------------------------------------------------------------------------- //
// Impute missing values, included created by the moving average
// -------------------------------------------------------------------------- //

generate log_avg_mthly_wages = log(avg_mthly_wages_ma)
generate is_imputed = missing(log_avg_mthly_wages)

foreach v in NAICS SIC {
    reghdfe log_avg_mthly_wages if version == "`v'" [aw=mthly_emplvl], verbose(4) coeflegend absorb(area_fips own_code industry_code time, savefe)
    // Create the constant
    generate __hdfe0__ = _b[_cons] if version == "`v'"
    // Extend fxed effects to observations with missing values
    gegen __hdfe1__ = firstnm(__hdfe1__) if version == "`v'", by(area_fips) replace
    gegen __hdfe2__ = firstnm(__hdfe2__) if version == "`v'", by(own_code) replace
    gegen __hdfe3__ = firstnm(__hdfe3__) if version == "`v'", by(industry_code) replace
    gegen __hdfe4__ = firstnm(__hdfe4__) if version == "`v'", by(time) replace
    // If fixed effect missing, assume zero
    forvalues i = 1/4 {
        replace __hdfe`i'__ = 0 if missing(__hdfe`i'__) & version == "`v'"
    }
    // Make prediction
    replace avg_mthly_wages_ma = exp(__hdfe0__ + __hdfe1__ + __hdfe2__ + __hdfe3__ + __hdfe4__) if missing(avg_mthly_wages_ma) & version == "`v'"
    drop __hdfe*
}

drop log_avg_mthly_wages
assert !missing(avg_mthly_wages_ma)

replace avg_mthly_wages = avg_mthly_wages_ma
drop avg_mthly_wages_ma

tsset, clear
drop time id

// -------------------------------------------------------------------------- //
// Save
// -------------------------------------------------------------------------- //

compress
save "$work/02-disaggregate-qcew/qcew-monthly.dta", replace

