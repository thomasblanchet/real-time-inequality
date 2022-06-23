// -------------------------------------------------------------------------- //
// Import financial accounts from the FED
// -------------------------------------------------------------------------- //

copy "https://www.federalreserve.gov/releases/z1/20210923/z1_csv_files.zip" "$work/01-import-fa/z1_csv_files.zip", replace
cd "$work/01-import-fa"
unzipfile "$work/01-import-fa/z1_csv_files.zip", replace

// -------------------------------------------------------------------------- //
// Series availalble quarterly
// -------------------------------------------------------------------------- //

foreach file in b101 b104 l223 l227 l202 l122 l121 b101e l124 l224 l218 l219 l221 l117 l226 l108 {    
    import delimited "$work/01-import-fa/csv/`file'.csv", clear encoding(utf8) varnames(1) stringcols(_all)

    split date, parse(":Q") destring
    rename date1 year
    rename date2 quarter

    destring *, ignore("ND") force replace

    order year quarter
    
    tempfile `file'
    save "``file''", replace
}

use "`b101'", clear
merge 1:1 year quarter using "`b104'", nogenerate
merge 1:1 year quarter using "`l223'", nogenerate
merge 1:1 year quarter using "`l227'", nogenerate
merge 1:1 year quarter using "`l202'", nogenerate
merge 1:1 year quarter using "`l122'", nogenerate
merge 1:1 year quarter using "`l121'", nogenerate
merge 1:1 year quarter using "`b101e'", nogenerate
merge 1:1 year quarter using "`l124'", nogenerate
merge 1:1 year quarter using "`l224'", nogenerate
merge 1:1 year quarter using "`l218'", nogenerate
merge 1:1 year quarter using "`l219'", nogenerate
merge 1:1 year quarter using "`l221'", nogenerate
merge 1:1 year quarter using "`l117'", nogenerate
merge 1:1 year quarter using "`l226'", nogenerate
merge 1:1 year quarter using "`l108'", nogenerate

sort year quarter

generate time = yq(year, quarter), after(quarter)
tsset time, quarterly

keep if year >= 1952

save "$work/01-import-fa/fa-quarterly.dta", replace

// -------------------------------------------------------------------------- //
// Series availalble annually only
// -------------------------------------------------------------------------- //

foreach file in b101n {
    import delimited "$work/01-import-fa/csv/`file'.csv", clear encoding(utf8) varnames(1) stringcols(_all)

    destring *, ignore("ND") force replace
    
    rename date year
    
    tempfile `file'
    save "``file''", replace
}

use "`b101n'", clear

keep if year >= 1952

// -------------------------------------------------------------------------- //
// Disaggregate annual series using the proportional Denton method
// -------------------------------------------------------------------------- //

sort year
tsset year, yearly

// Variables to disaggregate
local to_disaggregate_yrly "lm163064005 fl163020005 fl163030205 lm163063005 fl164023005 fl163072003 lm163061005 fl163070005"

// Define the variable to use for the disaggregation in each case
local disag_lm163064005 "lm153064105" // Corporate equities and mutual funds shares of non-profits --> households + non-profit
local disag_fl163020005 "fl153020005" // Non-interest bearing deposits of non-profits --> households + non-profits
local disag_fl163030205 "fl153030005" // Interest-bearing deposits of non-profits --> households + non-profits
local disag_lm163063005 "lm153063005" // Foreign bonds --> domestic bonds
local disag_fl164023005 "fl154023005" // Loans of non-profits --> households + non-profits
local disag_fl163072003 "fl154023005" // PPP receivable of non-profits --> households + non-profits
local disag_lm163061005 "lm153062005" // Municipal bonds of non-profits --> households + non-profits
local disag_fl163070005 "fl154090005" // Grants and trade receivable --> Total financial assets

// Perform disaggregation
foreach v in `to_disaggregate_yrly' {
    tempfile `v'
    
    preserve
        drop if missing(`v'a)
        denton `v'a using "``v''", interp(`disag_`v''q) from("$work/01-import-fa/fa-quarterly.dta") generate(`v'q) stock
    restore
}

// Combine the data
use "$work/01-import-fa/fa-quarterly.dta", clear
foreach v in `to_disaggregate_yrly' {
    merge n:1 time using "``v''", nogenerate
    
    // Extrapolate in case the last quarter was not covered
    sort time
    generate ratio = `v'q/`disag_`v''q
    carryforward ratio, replace
    gsort -time
    carryforward ratio, replace
    gsort time
    replace `v'q = `disag_`v''*ratio if missing(`v'q)
    drop ratio 
}

tsset, clear
drop time

save "$work/01-import-fa/fa.dta", replace


