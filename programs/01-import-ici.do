// -------------------------------------------------------------------------- //
// Import ICI data on the composition of pension funds
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Stock data
// -------------------------------------------------------------------------- //

import excel "https://www.ici.org/system/files/2022-03/ret_21_q4_data.xls", sheet("Table 19") clear

keep if ustrregexm(A, "^[0-9][0-9][0-9][0-9](:Q[1-4])?$")

split A, parse(":Q") destring

rename A1 year
rename A2 quarter

rename B ici_domestic_equity
rename D ici_world_equity
rename F ici_hybrid_equity
rename H ici_bonds
rename J ici_money_market
rename L ici_total

keep year quarter ici_*
order year quarter

replace quarter = 4 if missing(quarter)
destring ici_*, force replace

foreach v of varlist ici_* {
    replace `v' = 1e3*`v'
}

save "$work/01-import-ici/ici-data-stocks.dta", replace

// -------------------------------------------------------------------------- //
// Flow data (IRAs)
// -------------------------------------------------------------------------- //

import excel "https://www.ici.org/system/files/2022-03/ret_21_q4_data.xls", sheet("Table 11") clear

keep if ustrregexm(A, "^[0-9][0-9][0-9][0-9]$")

destring A B, force replace

keep A B
rename A year
rename B contrib_ira_tradi

tempfile tradi
save "`tradi'", replace

import excel "https://www.ici.org/system/files/2022-03/ret_21_q4_data.xls", sheet("Table 13") clear

generate type = ""
replace type = "_sep" if strpos(A, "SEP")
replace type = "_simple" if strpos(A, "SIMPLE")
carryforward type, replace
keep if ustrregexm(A, "^[0-9][0-9][0-9][0-9]$")

destring A B, force replace

keep type A B

rename A year
rename B contrib

reshape wide contrib, i(year) j(type) string

merge 1:1 year using "`tradi'", nogenerate

sort year

generate contrib_ira_pretax = contrib_sep + contrib_simple + contrib_ira_tradi

foreach v of varlist contrib_* {
    replace `v' = `v'*1e9
}

save "$work/01-import-ici/ici-data-flows.dta", replace
