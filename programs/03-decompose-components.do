 // -------------------------------------------------------------------------- //
// Database that decomposes the different income components on each month
// -------------------------------------------------------------------------- //

global date_begin = ym(2007, 12)
global date_end   = ym(2022, 04)

// Labels for graphs
local label_princ "Factor national income"
local label_peinc "Pretax national income"
local label_poinc "Post-tax national income"
local label_dispo "Post-tax disposable income"
local label_flemp "Compensation of employees"
local label_contrib "Social contributions"
local label_uiben "Unemployment insurance benefits"
local label_penben "Pension + disability insurance benefits"
local label_surplus "Surplus/deficit of social insurance"
local label_proprietors "Proprietor's income"
local label_rental "Rental income"
local label_profits "Undistributed profits"
local label_fkfix "Interest income"
local label_govin "Government interest income"
local label_fknmo "Nonmortage interest payments"
local label_corptax "Corporate tax"
local label_prodtax "Production taxes"
local label_taxes "Current taxes on income and wealth"
local label_estatetax "Estate tax"
local label_othercontrib "Non social security contributions"
local label_vet "Veteran benefits"
local label_othcash "Other cash benefits"
local label_medicare "Medicare"
local label_medicaid "Medicaid"
local label_otherkin "Other in-kind transfers"
local label_colexp "Collective expenditures"
local label_prisupenprivate "Surplus/deficit of private insurance system"
local label_prisupgov "Surplus/deficit"
local label_covidrelief "COVID relief"
local label_covidsub "Paycheck Protection Program"
local label_prodsub "Production subsidies"

local label_hweal "Wealth"
local label_housing_tenant "Housing (tenant-ocupied)"
local label_housing_owner "Housing (owner-occupied)"
local label_equ_scorp "S-corporation equity"
local label_equ_nscorp "Non-S-corporation equity"
local label_business "Noncorporate equity"
local label_pensions "Pension"
local label_fixed "Fixed-income assets"
local label_mortgage_tenant "Mortgages (tenant-occupied)"
local label_mortgage_owner "Mortgages (owner-occupied)"
local label_nonmortage "Non-mortage debt"

foreach income in princ /*peinc dispo poinc hweal*/ {
    foreach pop in /*adult*/ working_age {
        quietly {
            clear
            save "$work/03-decompose-components/decomposition-monthly-`income'-`pop'.dta", replace emptyok
            foreach t of numlist $date_begin / $date_end {
                noisily di "* " %tm = `t' ": `income', `pop'"
                
                local year = year(dofm(`t'))
                local month = month(dofm(`t'))
                
                use "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear

                // Define decomposition for each type of income
                if ("`income'" == "princ") {
                    replace govin = -govin
                    local decomposition_pos flemp proprietors rental profits corptax fkfix prodtax
                    local decomposition_neg fknmo govin prodsub covidsub
                }
                else if ("`income'" == "peinc") {
                    local decomposition_pos princ uiben penben
                    local decomposition_mid surplus
                    local decomposition_neg contrib
                }
                else if ("`income'" == "dispo") {
                    replace peinc = peinc - surplus - govin
                    local decomposition_pos peinc vet othcash covidrelief prodsub covidsub
                    local decomposition_mid ""
                    local decomposition_neg othercontrib taxes estatetax corptax prodtax
                }
                else if ("`income'" == "poinc") {
                    replace prisupgov = prisupgov + govin + prisupenprivate
                    local decomposition_pos dispo medicare medicaid otherkin colexp
                    local decomposition_mid prisupgov
                    local decomposition_neg ""
                }
                else if ("`income'" == "hweal") {
                    local decomposition_pos housing_tenant housing_owner equ_scorp equ_nscorp business pensions fixed
                    local decomposition_neg mortgage_tenant mortgage_owner nonmortage
                }
                
                // Make equal-split
                foreach v of varlist `income' `decomposition_pos' `decomposition_mid' `decomposition_neg' {
                    gegen `v' = mean(`v'), by(id) replace
                }
                
                // Limit to working age if requested
                if ("`pop'" == "working_age") {
                    keep if age < 65
                }
                
                // Get rank
                sort princ
                generate rank = sum(weight)
                replace rank = 1e5*(rank - weight/2)/rank[_N]

                egen p = cut(rank), at(0(1000)99000 99100(100)99900 99910(10)99990 99991(1)99999 100001)
                
                gcollapse (mean) `income' `decomposition_pos' `decomposition_mid' `decomposition_neg' [pw=weight], by(year month p)
                append using "$work/03-decompose-components/decomposition-monthly-`income'-`pop'.dta"
                save "$work/03-decompose-components/decomposition-monthly-`income'-`pop'.dta", replace
            }
            
            use "$work/03-decompose-components/decomposition-monthly-`income'-`pop'.dta", clear
            
            merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate keepusing(nipa_deflator)

            sort year month p
            by year month: generate n = cond(_n == _N, 1e5 - p, p[_n + 1] - p)

            generate bracket = ""
            replace bracket = "Bottom 50%" if inrange(p, 00000, 49000)
            replace bracket = "Middle 40%" if inrange(p, 50000, 89000)
            replace bracket = "Next 9%" if inrange(p, 90000, 98000)
            replace bracket = "Top 1%"  if inrange(p, 99000, 99999)

            gcollapse (mean) `income' `decomposition_pos' `decomposition_mid' `decomposition_neg' (firstnm) nipa_deflator [pw=n], by(year month bracket)
            
            local vlist ""
            local v_prev ""
            if ("`decomposition_neg'" != "") {
                foreach v of varlist `decomposition_neg' {
                    if ("`v_prev'" == "") {
                        if ("`decomposition_mid'" != "") {
                            generate decomp_`v' = min(0, `decomposition_mid'/nipa_deflator/12) - `v'/nipa_deflator/12
                        }
                        else {
                            generate decomp_`v' = -`v'/nipa_deflator/12
                        }
                        label variable decomp_`v' "`label_`v''"
                    }
                    else {
                        generate decomp_`v' = decomp_`v_prev' - `v'/nipa_deflator/12
                        label variable decomp_`v' "`label_`v''"
                    }
                    local v_prev `v'
                    local vlist decomp_`v' `vlist'
                }
            }

            if ("`decomposition_mid'" != "") {
                generate decomp_`decomposition_mid' = `decomposition_mid'/nipa_deflator/12
                label variable decomp_`decomposition_mid' "`label_`decomposition_mid''"
                local vlist `vlist' decomp_`decomposition_mid'
            }

            local v_prev ""
            foreach v of varlist `decomposition_pos' {
                if ("`v_prev'" == "") {
                    if ("`decomposition_mid'" != "") {
                        generate decomp_`v' = max(0, `decomposition_mid'/nipa_deflator/12) + `v'/nipa_deflator/12
                    }
                    else {
                        generate decomp_`v' = `v'/nipa_deflator/12
                    }
                    label variable decomp_`v' "`label_`v''"
                }
                else {
                    generate decomp_`v' = decomp_`v_prev' + `v'/nipa_deflator/12
                    label variable decomp_`v' "`label_`v''"
                }
                local v_prev `v'
                local vlist decomp_`v' `vlist' 
            }

            generate time = ym(year, month)
            format time %tm
            
            replace `income' = `income'/nipa_deflator/12
            label variable `income' "`label_`income''"

            gr tw (area `vlist' time if bracket == "Bottom 50%", lw(none..)) ///
                (con `income' time if bracket == "Bottom 50%", col(black) lw(medthick) msize(small) msym(Oh)), ///
                legend(pos(3) cols(1) size(tiny)) xtitle("") ytitle("USD (constant)") ///
                title("Bottom 50%") subtitle("`label_`income''") aspectratio(1) ///
                xlabel(, labsize(small) angle(45)) ylabel(, labsize(small))
            graph export "$graphs/03-decompose-components/decomposition-monthly-`income'-`pop'-bot50.pdf", replace
                
            gr tw (area `vlist' time if bracket == "Middle 40%", lw(none..)) ///
                (con `income' time if bracket == "Middle 40%", col(black) lw(medthick) msize(small) msym(Oh)), ///
                legend(pos(3) cols(1) size(tiny)) xtitle("") ytitle("USD (constant)") ///
                title("Middle 40%") subtitle("`label_`income''") aspectratio(1) ///
                xlabel(, labsize(small) angle(45)) ylabel(, labsize(small))
            graph export "$graphs/03-decompose-components/decomposition-monthly-`income'-`pop'-mid40.pdf", replace
                
            gr tw (area `vlist' time if bracket == "Next 9%", lw(none..)) ///
                (con `income' time if bracket == "Next 9%", col(black) lw(medthick) msize(small) msym(Oh)), ///
                legend(pos(3) cols(1) size(tiny)) xtitle("") ytitle("USD (constant)") ///
                title("Next 9%") subtitle("`label_`income''") aspectratio(1) ///
                xlabel(, labsize(small) angle(45)) ylabel(, labsize(small))
            graph export "$graphs/03-decompose-components/decomposition-monthly-`income'-`pop'-next9.pdf", replace

            gr tw (area `vlist' time if bracket == "Top 1%", lw(none..)) ///
                (con `income' time if bracket == "Top 1%", col(black) lw(medthick) msize(small) msym(Oh)), ///
                legend(pos(3) cols(1) size(tiny)) xtitle("") ytitle("USD (constant)") ///
                title("Top 1%") subtitle("`label_`income''") aspectratio(1) ///
                xlabel(, labsize(small) angle(45)) ylabel(, labsize(small))
            graph export "$graphs/03-decompose-components/decomposition-monthly-`income'-`pop'-top1.pdf", replace
        }
    }
}
