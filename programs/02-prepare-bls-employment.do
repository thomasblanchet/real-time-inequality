// -------------------------------------------------------------------------- //
// Prepare employment series to be integrated into DINA
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Get annual employment from DINA
// -------------------------------------------------------------------------- //

use "$work/01-import-dina/dina-full.dta", clear
generate dina_employed = (flemp > 0)
gcollapse (sum) dina_employed [pw=dweght], by(year)
save "$work/02-prepare-bls-employment/dina-employment.dta", replace

// -------------------------------------------------------------------------- //
// Get annual employment from SSA
// -------------------------------------------------------------------------- //

// Use historical tables before 1991 (after, we use the tabulations directly)
import excel "$rawdata/ssa-data/number-wage-earners.xlsx", sheet("1984+") cellrange(A7:G12) clear
keep A F
destring F, force replace ignore(",")
rename A year
rename F ssa_employed
replace ssa_employed = 1e6*ssa_employed
save "$work/02-prepare-bls-employment/ssa-employment.dta", replace

use "$work/01-import-ssa-wages/ssa-tables.dta", clear
gcollapse (sum) ssa_employed=pop, by(year)
append using "$work/02-prepare-bls-employment/ssa-employment.dta"
save "$work/02-prepare-bls-employment/ssa-employment.dta", replace

// -------------------------------------------------------------------------- //
// Get SSA/CES adjustment
// -------------------------------------------------------------------------- //

use "$work/01-import-ce/ce-employment.dta", clear

gcollapse (mean) ce_employed, by(year)
merge 1:1 year using "$work/02-prepare-bls-employment/ssa-employment.dta", keep(master match) nogenerate
merge 1:1 year using "$work/01-import-pop/pop-data-national.dta", keep(match) nogenerate

// Make SSA/BLS adjustment
generate ssa_employment_rate = ssa_employed/working_age
generate ce_employment_rate = ce_employed/working_age

reg ssa_employment_rate ce_employment_rate
estimates store ce_ssa_adj

save "$work/02-prepare-bls-employment/ssa-employment.dta", replace

// -------------------------------------------------------------------------- //
// Adjusted monthly series
// -------------------------------------------------------------------------- //

use "$work/01-import-ce/ce-employment.dta", clear
merge 1:1 year month using "$work/02-prepare-pop/pop-data-monthly.dta", nogenerate

generate ce_employment_rate = ce_employed/monthly_working_age
estimates restore ce_ssa_adj
predict ce_employment_rate_adj

generate time = ym(year, month)
format time %tm

merge n:1 year using "$work/02-prepare-bls-employment/ssa-employment.dta", nogenerate
merge n:1 year using "$work/02-prepare-bls-employment/dina-employment.dta", nogenerate
keep if year >= 1975

generate dina_employment = dina_employed/working_age

gr tw (line ce_employment_rate ce_employment_rate_adj time, col(ebblue ebblue) lp(dash solid)) ///
    (sc ssa_employment_rate /*dina_employment*/ time if month == 7, msym(Oh Sh) msize(small..) col(cranberry green)), ///
    ylabel(0.65 "65%" 0.70 "70%" 0.75 "75%" 0.80 "80%" 0.85 "85%" 0.90 "90%") ytitle("Employment rate" "Working-age population (20-64)") ///
    xtitle("") xlabel(, angle(45)) legend(pos(6) rows(1) label(1 "BLS") label(2 "BLS (adjusted)") label(3 "DINA") /*label(4 "DINA"")*/)
graph export "$graphs/02-prepare-bls-employment/employment-ssa-bls.pdf", replace

generate ssa_employed_monthly = ce_employment_rate_adj*monthly_working_age
gegen ssa_employed_yearly = mean(ssa_employed_monthly), by(year)
replace ssa_employed_yearly = ssa_employed if !missing(ssa_employed)

keep year month ce_employed ssa_employed_monthly ssa_employed_yearly
save "$work/02-prepare-bls-employment/ssa-bls-employment.dta", replace

// Yearly version
gcollapse (mean) ce_employed (first) ssa_employed=ssa_employed_yearly, by(year)
save "$work/02-prepare-bls-employment/ssa-bls-employment-yearly.dta", replace
