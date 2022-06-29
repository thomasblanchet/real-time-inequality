// -------------------------------------------------------------------------- //
// Create income distribution series from QCEW data
// -------------------------------------------------------------------------- //

use "$work/02-update-qcew/qcew-monthly-updated.dta", clear
*use "$work/02-disaggregate-qcew/qcew-monthly.dta", clear

// Convert back to nominal
merge n:1 year month using "$work/01-import-cu/bls-cpi.dta", ///
    keep(master match) assert(match using) nogenerate keepusing(cpi)
replace avg_mthly_wages = avg_mthly_wages*cpi
drop cpi

// Remove excessively low values (less than 50% full-time minimum wage)
generate state_code = substr(area_fips, 1, 2)
merge n:1 state_code year month using "$work/01-import-minwage/state-minimum-wage.dta", nogenerate keep(master match)
merge n:1 year month using "$work/01-import-minwage/fed-minimum-wage.dta", nogenerate keep(master match) assert(match using)

generate minw = fed_minw
replace minw = state_minw if !missing(state_minw) & state_minw > fed_minw
drop if avg_mthly_wages < 40*4*minw/2
drop state_code minw fed_minw state_minw

// Tabulate
hashsort version year month avg_mthly_wages

by version year month: generate rank = sum(mthly_emplvl)
by version year month: replace rank = 1e5*(rank - mthly_emplvl/2)/rank[_N]

// Note: we only go up to the top 1%
egen p = cut(rank), at(0(1000)99000 100001)

gcollapse (mean) avg_mthly_wages [aw=mthly_emplvl], by(version year month p)

save "$work/02-tabulate-qcew/qcew-tabulations.dta", replace
