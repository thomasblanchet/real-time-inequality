// -------------------------------------------------------------------------- //
// Import SCF data to be matched with DINA
// -------------------------------------------------------------------------- //

cap mkdir "$transport"
cap mkdir "$transport/scf"

// Import the CPS to convert series to nominal
import fred CPIAUCSL, clear
generate month = month(daten)
generate year = year(daten)
keep if month == 9
keep if inrange(year, 1989, 2019)
drop month
sort year
rename CPIAUCSL cpi
replace cpi = cpi/cpi[_N]
keep year cpi
save "$work/01-import-transport-scf/cpi-scf.dta", replace

// Import the SCF
clear
save "$work/01-import-transport-scf/scf-transport-summary.dta", replace emptyok

clear
save "$work/01-import-transport-scf/scf-full.dta", emptyok replace

// Merge full and summary files in each year to get spouse's age
foreach year of numlist 1989(3)2019 {
    use "$rawdata/scf-data/rscfp`year'.dta", clear
    
    local yy = substr("`year'", 3, 2)
    local i = cond(`year' == 1992, 4, 6)
    
    if (`year' == 1989) {
        rename x1 X1
        merge 1:1 X1 using "$rawdata/scf-data/p`yy'i`i'.dta", nogenerate
        rename xx1 yy1
        rename X1 y1
    }
    else if (`year' < 2013) {
        rename y1 Y1
        rename yy1 YY1
        merge 1:1 Y1 using "$rawdata/scf-data/p`yy'i`i'.dta", nogenerate
    }
    else {
        merge 1:1 y1 using "$rawdata/scf-data/p`yy'i`i'.dta", nogenerate
    }
    
    renvars, lower
    
    // Keep first implicate only
    keep if mod(y1, 10) == 1
    drop y1
    
    rename x104 age_spouse
    
    // Recode education of spouse (transcription of the FED's SAS programs
    // for reference person)
    if (`year' < 2016) {
        generate educ_spouse = .
        replace educ_spouse = -1 if (married == 1) & ((x6101 == -1))
        replace educ_spouse = 01 if (married == 1) & (inrange(x6101, 1, 4))
        replace educ_spouse = 02 if (married == 1) & (inrange(x6101, 5, 6))
        replace educ_spouse = 03 if (married == 1) & (inrange(x6101, 7, 8))
        replace educ_spouse = 04 if (married == 1) & ((x6101 == 9))
        replace educ_spouse = 05 if (married == 1) & ((x6101 == 10))
        replace educ_spouse = 06 if (married == 1) & ((x6101 == 11))
        replace educ_spouse = 07 if (married == 1) & ((x6101 == 12) & inlist(x6102, 0, 5))
        replace educ_spouse = 08 if (married == 1) & ((x6101 == 12) & inlist(x6102, 1, 2))
        replace educ_spouse = 09 if (married == 1) & ((x6101 >= 13) & x6104 == 5)
        replace educ_spouse = 10 if (married == 1) & (inrange(x6101, 13, 15) & inlist(x6105, 7, 11))
        replace educ_spouse = 11 if (married == 1) & ((x6101 >= 13) & inlist(x6105, 1, 10))
        replace educ_spouse = 12 if (married == 1) & ((x6101 >= 13) & (x6105 == 2))
        replace educ_spouse = 12 if (married == 1) & ((x6101 == 16) & inlist(x6105, 11, -7))
        replace educ_spouse = 13 if (married == 1) & ((x6101 == 17) & inlist(x6105, 11, 7, -7))
        replace educ_spouse = 14 if (married == 1) & ((x6101 >= 13) & inlist(x6105, 5, 6, 4, 12))
    }
    else {
        generate educ_spouse = x6111 if (married == 1)
    }
    
    // Employment status of spouse
    generate employed = !(inrange(x4100, 50, 80) | (x4100 == 97))
    assert employed == lf
    generate employed_spouse = !(inrange(x4700, 50, 80) | (x4700 == 97)) if married == 1
    
    keep yy1 wgt-nincqrtcat age_spouse educ_spouse employed employed_spouse
    
    save "$work/01-import-transport-scf/scf-combined-`year'.dta", replace
}

forvalues year = 1989/2020 {
    // Construct a yearly sample by mixing two adjacent samples
    local y1 = 1989 + floor((`year' - 1989)/3)*3
    
    if (`year' == `y1') {
        // We are on an SCF survey year, use he file directly
        use "$work/01-import-transport-scf/scf-combined-`y1'.dta", clear
    }
    else {
        if (`year' >= 2019) {
            // We are past the last SCF survey year, we use the last year
            // available
            use "$work/01-import-transport-scf/scf-combined-2019.dta", clear
        }
        else {
            // We are between two years, mix the samples
            local y2 = `y1' + 3
            
            use "$work/01-import-transport-scf/scf-combined-`y1'.dta", clear
            append using "$work/01-import-transport-scf/scf-combined-`y2'.dta", generate(right)
            
            // Make Unique IDs
            gegen yy1 = group(right yy1), replace
            
            local mix_prop = (`year' - `y1')/3
            
            replace wgt = (1 - `mix_prop')*wgt if right == 0
            replace wgt = (`mix_prop')*wgt if right == 1
            
            drop right
        }
    }
    
    // Year
    generate year = `year'
    
    // Merge with CPI to convert back to nominal
    merge n:1 year using "$work/01-import-transport-scf/cpi-scf.dta", keep(match) nogenerate
    
    // SCF income variables
    capture generate rentinc = 0 // Set rentinc to 0 in not existing (grouped with interest/dividends)
    generate scf_wage     = wageinc*cpi
    generate scf_pens_ss  = ssretinc*cpi
    generate scf_bus      = bussefarminc*cpi
    generate scf_intdivrt = (intdivinc + rentinc)*cpi
    // We ignore transfothinc because it has problems in 1992
    //generate scf_trans    = max(transfothinc, 0)*cpi
    generate scf_kg       = max(kginc, 0)*cpi
    
    // SCF wealth variables
    generate scf_wfinbus = (fin + bus)*cpi
    generate scf_whou    = (houses + oresre)*cpi
    generate scf_wdeb    = debt*cpi
    
    generate old = (age >= 65) | (age_spouse >= 65)
    replace married = (married == 1)
    rename wgt weight
    rename yy1 id
    
    keep year id weight married old employed employed_spouse hhsex age age_spouse race educ educ_spouse scf_*
    order year id weight married old employed employed_spouse hhsex age age_spouse race educ educ_spouse scf_*
    
    rename hhsex sex_scf
    rename age age_scf
    rename age_spouse age_spouse_scf
    rename race race_scf

    replace employed = employed + employed_spouse if !missing(employed_spouse)
    
    recode educ ///
        (-1/1  = 01)  /// No schooling to 4th grade
        (2/3   = 02)  /// 5th to 8th grade
        (4     = 03)  /// 9th grade
        (5     = 04)  /// 10th grade
        (6     = 05)  /// 11th grade
        (7/8   = 06)  /// 12th grade (High School)
        (9     = 07)  /// 1 year of college/some college but no degree
        (10/11 = 08)  /// 2 years of college/associate degree
        (12    = 09)  /// 3-4 years of college/bachelor degree
        (13/15 = 10), /// 5+ years of college
        generate(educ_scf)
        
    recode educ_spouse ///
        (-1/1  = 01)  /// No schooling to 4th grade
        (2/3   = 02)  /// 5th to 8th grade
        (4     = 03)  /// 9th grade
        (5     = 04)  /// 10th grade
        (6     = 05)  /// 11th grade
        (7/8   = 06)  /// 12th grade (High School)
        (9     = 07)  /// 1 year of college/some college but no degree
        (10/11 = 08)  /// 2 years of college/associate degree
        (12    = 09)  /// 3-4 years of college/bachelor degree
        (13/15 = 10), /// 5+ years of college
        generate(educ_spouse_scf)
    drop educ educ_spouse
    
    // Sometimes (very rare) education is missing: impute median value
    summarize educ_scf [aw=weight]
    replace educ_scf = r(median) if missing(educ_scf)
    
    // If educ missing assume same as spouse
    replace educ_spouse_scf = educ_scf if married & missing(educ_spouse_scf)
    replace educ_scf = educ_spouse_scf if missing(educ_scf)
    
    // Combine Asian and Others (not in public files anyway)
    replace race_scf = 4 if race_scf == 5
    
    // Few people below 20: make them 20-year-old
    replace age_scf = 20 if age_scf < 20
    replace age_spouse_scf = 20 if age_spouse_scf < 20
    
    // If age missing assume same as spouse
    replace age_spouse_scf = age_scf if missing(age_spouse_scf)
    
    // Sanity checks
    assert !missing(educ_scf) & inrange(educ_scf, 1, 10)
    assert !missing(educ_spouse_scf) & inrange(educ_spouse_scf, 1, 10) if married
    assert age_scf >= 20 & !missing(age_scf)
    assert age_spouse_scf >= 20 & !missing(age_spouse_scf) if married
    assert inrange(race_scf, 1, 4) & !missing(race_scf)
    
    append using "$work/01-import-transport-scf/scf-full.dta"
    save "$work/01-import-transport-scf/scf-full.dta", replace
}

// Check that all cells are represented
preserve
    gcollapse (count) weight, by(year married old employed)
    fillin year married old employed
    assert _fillin == 0 | (married == 0 & employed == 2)
restore

// Export CSVs
levelsof year, local(years)
foreach yr of local years {
    export delimited id weight old married employed scf_* using "$transport/scf/scf`yr'.csv" if year == `yr', replace
}

// Export univariate distributions
local firstiter = 1
foreach v of varlist scf_* {
    preserve
        // Equal-split the wealth
        replace `v' = `v'/2 if married
        
        // Key statistics
        local stub = substr("`v'", 5, .)
        generate scf_has_`stub' = (`v' > 0)
        sort year `v'
        by year: generate rank = sum(weight) if scf_has_`stub'
        by year: replace rank = (rank - weight/2)/rank[_N] if scf_has_`stub'
        
        generate scf_bot50_`stub' = `v'*inrange(rank, 0, 0.5)
        generate scf_top10_`stub' = `v'*inrange(rank, 0.9, 1)
        
        gcollapse (sum) `v' scf_bot50_`stub' scf_top10_`stub' scf_has_`stub' (rawsum) pop=weight [pw=weight], by(year)
        
        replace scf_bot50_`stub' = 100*scf_bot50_`stub'/`v'
        replace scf_top10_`stub' = 100*scf_top10_`stub'/`v'
        replace scf_has_`stub' = 100*scf_has_`stub'/pop
        replace `v' = `v'/(pop*scf_has_`stub'/100)
        keep year `v' scf_bot50_`stub' scf_top10_`stub' scf_has_`stub'
        
        // Combine & save
        if (`firstiter' == 0) {
            merge 1:1 year using "$work/01-import-transport-scf/scf-transport-summary.dta", nogenerate
        }
        save "$work/01-import-transport-scf/scf-transport-summary.dta", replace
    restore
    local firstiter = 0
}


