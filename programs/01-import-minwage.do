// -------------------------------------------------------------------------- //
// Import state and federal minimum wage series
// -------------------------------------------------------------------------- //

// ---------------------------------------------------------------------- //
// Import all state-level minimum wage
// ---------------------------------------------------------------------- //

tempfile stat_minw_series
fredsearch "STTMINWG", idonly saving("`stat_minw_series'", replace)
import fred, serieslist("`stat_minw_series'") clear

generate year = year(daten)
generate month = month(daten)
drop datestr daten

reshape long STTMINWG, i(year month) j(state) string

generate frequency = substr(state, 3, 1)
replace frequency = "A" if missing(frequency)
replace state = substr(state, 1, 2)
reshape wide STTMINWG, i(year month state) j(frequency) string

generate state_minw = cond(missing(STTMINWGM), STTMINWGA, STTMINWGM)
drop STTMINWGM STTMINWGA

drop if state == "FG"
generate state_code = ""
replace state_code = "01" if state == "AL"
replace state_code = "02" if state == "AK"
replace state_code = "04" if state == "AZ"
replace state_code = "05" if state == "AR"
replace state_code = "06" if state == "CA"
replace state_code = "08" if state == "CO"
replace state_code = "09" if state == "CT"
replace state_code = "10" if state == "DE"
replace state_code = "11" if state == "DC"
replace state_code = "12" if state == "FL"
replace state_code = "13" if state == "GA"
replace state_code = "15" if state == "HI"
replace state_code = "16" if state == "ID"
replace state_code = "17" if state == "IL"
replace state_code = "18" if state == "IN"
replace state_code = "19" if state == "IA"
replace state_code = "20" if state == "KS"
replace state_code = "21" if state == "KY"
replace state_code = "22" if state == "LA"
replace state_code = "23" if state == "ME"
replace state_code = "24" if state == "MD"
replace state_code = "25" if state == "MA"
replace state_code = "26" if state == "MI"
replace state_code = "27" if state == "MN"
replace state_code = "28" if state == "MS"
replace state_code = "29" if state == "MO"
replace state_code = "30" if state == "MT"
replace state_code = "31" if state == "NE"
replace state_code = "32" if state == "NV"
replace state_code = "33" if state == "NH"
replace state_code = "34" if state == "NJ"
replace state_code = "35" if state == "NM"
replace state_code = "36" if state == "NY"
replace state_code = "37" if state == "NC"
replace state_code = "38" if state == "ND"
replace state_code = "39" if state == "OH"
replace state_code = "40" if state == "OK"
replace state_code = "41" if state == "OR"
replace state_code = "42" if state == "PA"
replace state_code = "44" if state == "RI"
replace state_code = "45" if state == "SC"
replace state_code = "46" if state == "SD"
replace state_code = "47" if state == "TN"
replace state_code = "48" if state == "TX"
replace state_code = "49" if state == "UT"
replace state_code = "50" if state == "VT"
replace state_code = "51" if state == "VA"
replace state_code = "53" if state == "WA"
replace state_code = "54" if state == "WV"
replace state_code = "55" if state == "WI"
replace state_code = "56" if state == "WY"
replace state_code = "60" if state == "AS"
replace state_code = "66" if state == "GU"
replace state_code = "69" if state == "MP"
replace state_code = "72" if state == "PR"
replace state_code = "78" if state == "VI"
assert !missing(state_code)
drop state

fillin state_code year month
drop _fillin

sort state_code year month
by state_code year: carryforward state_minw, replace
drop if missing(state_minw)

save "$work/01-import-minwage/state-minimum-wage.dta", replace

// ---------------------------------------------------------------------- //
// Combine with federal minimum wage
// ---------------------------------------------------------------------- //

import fred "FEDMINNFRWG", clear

generate year = year(daten)
generate month = month(daten)
drop datestr daten

rename FEDMINNFRWG fed_minw

sort year month

save "$work/01-import-minwage/fed-minimum-wage.dta", replace

