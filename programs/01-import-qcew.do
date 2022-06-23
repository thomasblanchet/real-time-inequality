// -------------------------------------------------------------------------- //
// Import QCEW data
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Download the data
// -------------------------------------------------------------------------- //

forvalues year = 1975/2000 {
    copy "https://data.bls.gov/cew/data/files/`year'/sic/csv/sic_`year'_qtrly_singlefile.zip" "$rawdata/qcew-data/qcew-legacy-`year'.zip", replace
}
foreach year of numlist 1990/2021 {
    copy "https://data.bls.gov/cew/data/files/`year'/csv/`year'_qtrly_singlefile.zip" "$rawdata/qcew-data/qcew-`year'.zip", replace
}

// -------------------------------------------------------------------------- //
// Unzip and extract the data
// -------------------------------------------------------------------------- //

cd "$rawdata/qcew-data"

// SIC (legacy) files
forvalues year = 1975/2000 {
    unzipfile "$rawdata/qcew-data/qcew-legacy-`year'.zip", replace
    local csvfile: dir "$rawdata/qcew-data" files "sic.`year'.*.singlefile.csv"
    import delimited `csvfile', clear
    erase `csvfile'
    
    keep if agglvl_code == 29
    keep area_fips own_code industry_code year qtr month1_emplvl month2_emplvl month3_emplvl total_qtrly_wages
 
    tempfile qcew`year'
    save "`qcew`year''", replace
    local qcewfiles_legacy `qcewfiles_legacy' "`qcew`year''"
}
clear
append using `qcewfiles_legacy'
compress
save "$work/01-import-qcew/qcew-legacy-raw.dta", replace

// NAICS files
forvalues year = 1990/2021 {
    unzipfile "$rawdata/qcew-data/qcew-`year'.zip", replace
    local csvfile: dir "$rawdata/qcew-data" files "`year'.*.singlefile.csv"
    import delimited `csvfile', clear
    erase `csvfile'
    
    keep if agglvl_code == 78
    keep area_fips own_code industry_code year qtr month1_emplvl month2_emplvl month3_emplvl total_qtrly_wages
 
    tempfile qcew`year'
    save "`qcew`year''", replace
    local qcewfiles `qcewfiles' "`qcew`year''"
}
clear
append using `qcewfiles'
compress
save "$work/01-import-qcew/qcew-raw.dta", replace
