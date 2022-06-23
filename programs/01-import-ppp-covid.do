// -------------------------------------------------------------------------- //
// Import data on the Paycheck Protection Program (PPP) during COVID
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// HUD database to match ZIP codes and county names to their FIPS codes
// -------------------------------------------------------------------------- //

cap mkdir "$work/01-import-ppp-covid/zip-county-crosswalk"
forvalues y = 2020/2022 {
    foreach q in "03" "06" "09" "12" {
        capture copy "https://www.huduser.gov/portal/datasets/usps/ZIP_COUNTY_`q'`y'.xlsx" ///
            "$work/01-import-ppp-covid/zip-county-crosswalk/ZIP_COUNTY_`q'`y'.xlsx", replace
    }
}

local files: dir "$work/01-import-ppp-covid/zip-county-crosswalk" files "*.xlsx"
clear
save "$work/01-import-ppp-covid/zip-county-crosswalk.dta", replace emptyok 
foreach f of local files {    
    import excel "$work/01-import-ppp-covid/zip-county-crosswalk/ZIP_COUNTY_092021.xlsx", ///
        clear firstrow case(lower)
        
    keep zip county usps_zip_pref_city usps_zip_pref_state bus_ratio
    rename zip zipcode
    rename usps_zip_pref_city city
    rename usps_zip_pref_state state
    
    local month = substr("`f'", 12, 2)
    local year = substr("`f'", 14, 4)
    generate year = `year'
    generate quarter = 1 + floor(`month'/3)
    
    append using "$work/01-import-ppp-covid/zip-county-crosswalk.dta"
    save "$work/01-import-ppp-covid/zip-county-crosswalk.dta", replace
}

// -------------------------------------------------------------------------- //
// Import the PPP loan data
// -------------------------------------------------------------------------- //

import delimited "$rawdata/ppp-covid-data/public_150k_plus_220403.csv", clear bindquotes(strict) stringcols(_all)
keep dateapproved initialapprovalamount forgivenessdate projectzip jobsreported naicscode forgivenessamount *_proceed
save "$work/01-import-ppp-covid/ppp-covid-data.dta", replace

forvalues i = 1/12 {
    import delimited "$rawdata/ppp-covid-data/public_up_to_150k_`i'_220403.csv", clear bindquotes(strict) stringcols(_all)
    keep dateapproved initialapprovalamount forgivenessdate projectzip jobsreported naicscode forgivenessamount *_proceed
    append using "$work/01-import-ppp-covid/ppp-covid-data.dta"
    save "$work/01-import-ppp-covid/ppp-covid-data.dta", replace
}

generate time_approved = date(dateapproved, "MDY")
format time_approved %td

generate year = year(time_approved)
generate quarter = quarter(time_approved)

generate time_forgiveness = date(forgivenessdate, "MDY")
format time_forgiveness %td

rename projectzip zipcode
rename jobsreported jobs
rename naicscode naics
rename forgivenessamount forgiveness
rename initialapprovalamount loan

destring loan forgiveness jobs *_proceed, replace

drop if naics == ""
drop if zipcode == "N/A"
drop if missing(jobs)
replace zipcode = substr(zipcode, 1, 5)

generate id = _n

joinby year quarter zipcode using "$work/01-import-ppp-covid/zip-county-crosswalk.dta"

rename year year_approved
drop quarter
generate month_approved = month(time_approved)

foreach v of varlist *_proceed {
    replace `v' = 0 if missing(`v')
}

generate year_forgiveness = year(time_forgiveness)
generate month_forgiveness = month(time_forgiveness)

keep id bus_ratio year_forgiveness month_forgiveness year_approved month_approved county naics jobs loan forgiveness *_proceed

compress

save "$work/01-import-ppp-covid/ppp-covid-data.dta", replace


