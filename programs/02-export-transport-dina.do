// -------------------------------------------------------------------------- //
// Import DINA to be matched with CPS
// -------------------------------------------------------------------------- //

cap mkdir "$transport"
cap mkdir "$transport/dina"

clear
save "$work/02-export-transport-dina/dina-transport-summary.dta", replace emptyok

foreach year of numlist 1975/2019 {
    di "* `year'"
    quietly {
        use "$rawdata/dina-data/microfiles/usdina`year'.dta", clear
        
        generate dina_wage  = fiwag - peninc
        generate dina_pens  = peninc
        generate dina_bus   = max(fibus, 0)
        generate dina_int   = fiint
        generate dina_drt   = fidiv + max(firen, 0)
        generate dina_gov   = ssinc_di + divet + diwco + uiinc
        generate dina_ss    = ssinc_oa
        generate dina_welfr = difoo + dicao
        
        generate dina_pens_ss  = dina_pens + dina_ss
        generate dina_intdivrt = fiint + fidiv + max(firen, 0)
        generate dina_kg       = fikgi
        
        generate dina_wfinbus = hwfix + hwpen + hwequ + hwbus
        generate dina_whou    = hwhou
        generate dina_wdeb    = -hwdeb
        
        generate weight = dweght/1e5
        generate year = `year'
        
        // Use DINA files adjusted with SSA data for the "employed" dummy
        merge 1:1 year id female using "$work/02-add-ssa-wages/dina-ssa-full.dta", nogenerate ///
            keep(master match) assert(match using) keepusing(flemp_ssa flsup_ssa flwag_ssa)
        generate employed = (flemp_ssa > 0)
        
        // Export univariate distributions
        tempfile summary
        local firstiter = 1
        foreach v of varlist dina_* {
            preserve
                // Equal-split the income
                gegen `v' = mean(`v'), by(year id) replace
                
                // Key statistics
                local stub = substr("`v'", 6, .)
                generate dina_has_`stub' = (`v' > 0)
                sort year `v'
                by year: generate rank = sum(weight) if dina_has_`stub'
                by year: replace rank = (rank - weight/2)/rank[_N] if dina_has_`stub'
                
                generate dina_bot50_`stub' = `v'*inrange(rank, 0, 0.5)
                generate dina_top10_`stub' = `v'*inrange(rank, 0.9, 1)
                
                gcollapse (sum) `v' dina_bot50_`stub' dina_top10_`stub' dina_has_`stub' (rawsum) pop=weight [pw=weight], by(year)
                
                replace dina_bot50_`stub' = 100*dina_bot50_`stub'/`v'
                replace dina_top10_`stub' = 100*dina_top10_`stub'/`v'
                replace dina_has_`stub' = 100*dina_has_`stub'/pop
                replace `v' = `v'/(pop*dina_has_`stub'/100)
                keep year `v' dina_bot50_`stub' dina_top10_`stub' dina_has_`stub'
                
                // Combine & save
                if (`firstiter' == 0) {
                    merge 1:1 year using "`summary'", nogenerate
                }
                save "`summary'", replace
            restore
            local firstiter = 0
        }
        
        preserve
            use "`summary'", clear
            append using "$work/02-export-transport-dina/dina-transport-summary.dta"
            save "$work/02-export-transport-dina/dina-transport-summary.dta", replace
        restore
        
        // Collapse by households for matching
        gcollapse (first) married (max) old (sum) employed (sum) dina_* (mean) weight, by(id)
        
        // Export as CSV for use in Python
        export delimited "$transport/dina/usdina`year'.csv", replace nolabel
        
        // Check that all cells are represented
        preserve
            gcollapse (count) weight, by(married old employed)
            fillin married old employed
            assert _fillin == 0 | (married == 0 & employed == 2)
        restore
    }
}

