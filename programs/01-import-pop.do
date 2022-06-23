// -------------------------------------------------------------------------- //
// Import population data from the Census Bureau
// -------------------------------------------------------------------------- //

copy "https://seer.cancer.gov/popdata/yr1969_2020.19ages/us.1969_2020.19ages.adjusted.txt.gz" ///
    "$work/01-import-pop/pop-data.txt.gz"
cd "$work/01-import-pop"
cap erase "$work/01-import-pop/pop-data.txt"
shell gunzip "pop-data.txt.gz"

// -------------------------------------------------------------------------- //
// Import the data
// -------------------------------------------------------------------------- //

infix ///
    int  year        1-4 ///
    str  state_iso   5-6 ///
    str  state_fips  7-8 ///
    str  county_fips 9-11 ///
    str  registry    12-13 ///
    byte race        14 ///
    byte origin      15 ///
    byte sex         16 ///
    byte age         17-18 ///
    long pop         19-27 ///
    using "$work/01-import-pop/pop-data.txt", clear

// -------------------------------------------------------------------------- //
// Version collapsed at the national level, adults vs. rest
// -------------------------------------------------------------------------- //
    
generate long adult = pop*(age >= 5)
generate long working_age = pop*inrange(age, 5, 13)

gcollapse (sum) pop adult working_age, by(year)

save "$work/01-import-pop/pop-data-national.dta", replace
