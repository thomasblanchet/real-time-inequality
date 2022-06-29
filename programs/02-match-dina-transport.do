// -------------------------------------------------------------------------- //
// Match DINA with ASEC CPS files using the transport maps calculated
// on the server
// -------------------------------------------------------------------------- //

tempfile dina cps scf

foreach year of numlist 1975/2019 {
    di "--> `year'"
    quietly {
        // Prepare files to match
        use if year == `year' using "$work/02-add-ssa-wages/dina-ssa-full.dta", clear
        drop age
        rename id dina_id
        save "`dina'", replace
        
        use if year == `year' using "$work/01-import-transport-cps/cps-full.dta", clear
        rename id cps_id
        save "`cps'", replace
        
        if (`year' >= 1989) {
            use if year == `year' using "$work/01-import-transport-scf/scf-full.dta", clear
            rename id scf_id
            save "`scf'", replace
        }
        
        // Import transport map
        import delimited "$transport/match/match-`year'.csv", clear
        
        generate transport_id = _n
        generate year = `year'
                
        // Match with DINA
        joinby year dina_id using "`dina'", unmatched(both)
        assert _merge == 3
        drop _merge
        
        // Match with CPS
        joinby year cps_id using "`cps'"
        
        // Match with SCF, if possible
        capture confirm variable scf_id
        if (_rc == 0) {
            joinby year scf_id using "`scf'"
        }
        
        egen num_id = nvals(transport_id)
        
        // Identify if couple are mixed-sex or same-sex in CPS
        egen num_male = total(sex_cps == 2) if married == 1, by(transport_id)
        egen num_female = total(sex_cps == 1) if married == 1, by(transport_id)
        generate same_sex = (num_male == 0) | (num_female == 0) if (married == 1)
        
        // If this is a mixed-sex couple, match CPS on gender
        drop if (married == 1) & (same_sex == 0) & (female == 1 & sex_cps == 1)
        drop if (married == 1) & (same_sex == 0) & (female == 0 & sex_cps == 2)
        
        // And then match the SCF to the CPS individual gender (in the SCF
        // only records gender of reference person)
        capture confirm variable scf_id
        if (_rc == 0) {
            replace age_scf = age_spouse_scf if (sex_cps != sex_scf) & (married == 1) & (same_sex == 0)
            replace educ_scf = educ_spouse_scf if (sex_cps != sex_scf) & (married == 1) & (same_sex == 0)
            replace sex_scf = cond(sex_scf == 1, 2, 1) if (sex_cps != sex_scf) & (married == 1) & (same_sex == 0)
        }
        
        // If this is a same-sex couple, match on whoever is closest in terms of labor income
        set seed 19920902
        generate tiebreaker = uniform() if (same_sex == 1)
        generate distance = abs(flwag - cps_wage) if (same_sex == 1)
        sort transport_id distance tiebreaker
        // First observation is the first match
        by transport_id: generate transport_num = _n if (same_sex == 1)
        by transport_id: generate dina_num = female[1] if (same_sex == 1)
        by transport_id: generate cps_num = pernum[1] if (same_sex == 1)
        // The other observation has to be different from the first for both DINA and CPS
        drop if (transport_num > 1) & (same_sex == 1) & (married == 1) & ((female == dina_num) | (pernum == cps_num))
        drop transport_num dina_num cps_num num_male num_female tiebreaker distance
        
        egen num_id2 = nvals(transport_id)
        noisily assert num_id == num_id2
        
        // For SCF age, reference person is the one with the highest wage income
        capture confirm variable scf_id
        if (_rc == 0) {
            generate tiebreaker = uniform() if (same_sex == 1)
            sort transport_id flwag tiebreaker
            by transport_id: replace age_scf = age_spouse_scf if (same_sex == 1) & (_n == 2)
            by transport_id: replace educ_scf = educ_spouse_scf if (same_sex == 1) & (_n == 2)
            drop tiebreaker 
        }
        drop same_sex
        
        // Check there's two people per couple
        by transport_id: generate num_people = _N
        assert num_people == 2 if (married == 1)
        assert num_people == 1 if (married == 0)
        drop num_people
        
        // Check weights
        assert !missing(weight)
        
        gegen weight_chk = total(weight), by(dina_id)
        replace weight_chk = weight_chk/2 if married == 1
        assert reldif(weight_chk, dweght) < 1e-4
        
        // CPS-base wage split within couples
        egen totincwage = total(cps_wage) if married, by(transport_id)
        generate share_cps_wage = cps_wage/totincwage if married
        drop totincwage
        
        // Clean up
        drop cps_id //dina_id
        capture confirm variable scf_id
        if (_rc == 0) {
            drop scf_id
        }
        rename transport_id id
        drop dweght serial pernum sploc cps_*
            
        capture confirm variable age_spouse_scf
        if (_rc == 0) {
            drop age_spouse_scf scf_*
        }
        compress
        
        label drop _all
        
        tempfile match`year'
        save "`match`year''", replace
        local matchfiles `matchfiles' "`match`year''"
    }
}
clear
append using `matchfiles'
compress

// Determine if an observation is in the top
generate is_top = 0
foreach v of varlist princ peinc poinc hweal {
    hashsort year `v'
    by year: generate rank = sum(weight)
    by year: replace rank = (rank - weight/2)/rank[_N]
    replace is_top = 1 if rank >= 0.95
    drop rank
}
// For observations in the top, use SCF after 1989, otherwise use CPS
foreach v in race age educ sex {
    generate `v' = `v'_cps
    replace `v' = `v'_scf if is_top & year >= 1989
}
drop is_top

// Simplify education
replace educ = 1 if inlist(educ, 1, 2) // Less than high school
replace educ = 3 if inlist(educ, 3, 4, 5) // Some high school

// Age groups
egen age_group = cut(age), at(20(5)75 999)

compress
save "$work/02-match-dina-transport/dina-transport-full.dta", replace
