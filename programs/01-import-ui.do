// -------------------------------------------------------------------------- //
// Import data on UI claims
// -------------------------------------------------------------------------- //

import excel "$rawdata/ui-data/weekly-unemployment-report.xlsx", clear cellrange(A3) allstring

generate time = date(O, "MDY")
format time %td

destring H, generate(ui_claims)

keep time ui_claims
drop if missing(time)
drop if missing(ui_claims)

generate year = year(time)
generate month = month(time)

// Aggregate by month
gcollapse (mean) ui_claims, by(year month)

// Save
save "$work/01-import-ui/ui-data.dta", replace
