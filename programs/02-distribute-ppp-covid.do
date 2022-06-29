// -------------------------------------------------------------------------- //
// Distribute the Paycheck Protection Program
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Calculate aggregates from full data (to account for observations not
// matched later on)
// -------------------------------------------------------------------------- //

use "$work/01-import-ppp-covid/ppp-covid-data.dta", clear
gcollapse (sum) ttloan=loan ttjobs=jobs [aw=bus_ratio], by(year_approved month_approved)
rename year_approved year
rename month_approved month
save "$work/02-distribute-ppp-covid/ppp-covid-data-aggregated.dta", replace

// -------------------------------------------------------------------------- //
// Match PPP to QCEW data
// -------------------------------------------------------------------------- //

use "$work/02-update-qcew/qcew-monthly-updated.dta", clear

// Only keep years covered by the program
keep if inrange(year, 2020, 2022)

// Aggregate over ownerships types
gcollapse (rawsum) mthly_emplvl (mean) avg_mthly_wages [pw=mthly_emplvl], ///
    by(year month area_fips industry_code)
    
// Rescale to BLS employment
merge n:1 year month using "$work/01-import-ce/ce-employment.dta", nogenerate keep(match)
gegen ttmthly_emplvl = total(mthly_emplvl), by(year month)
replace mthly_emplvl = mthly_emplvl*(ce_employed/ttmthly_emplvl)
drop ce_employed ttmthly_emplvl

// Calculate percentiles of wage distribution
hashsort year month avg_mthly_wages

by year month: generate rank = sum(mthly_emplvl)
by year month: replace rank = 1e5*(rank - mthly_emplvl/2)/rank[_N]

egen p = cut(rank), at(0(1000)99000 100001)

rename area_fips county
rename industry_code naics
rename year year_approved
rename month month_approved

merge 1:n county naics year_approved month_approved using "$work/01-import-ppp-covid/ppp-covid-data.dta"
   
// Recall that PPP loans were duplicated when their ZIP code spans several
// counties. When only certain observations for a given ZIP code could be
// matched, we rescale the bus_ratio variable that is used to split amounts
// between duplicates
gegen tot_bus_ratio = total(bus_ratio) if _merge == 3, by(id)

// Count the PPP loans matched at least once out of all PPP loans
// (about 75%)
preserve
    keep if inlist(_merge, 2, 3)
    gegen num_match = total(_merge == 3), by(id)
    generate has_match = (num_match > 0)

    gcollapse (first) has_match, by(id)
    summarize has_match
    count if has_match
restore

// Split amounts between matched duplicates
keep if inlist(_merge, 1, 3)
drop _merge
replace bus_ratio = bus_ratio/tot_bus_ratio
drop tot_bus_ratio

foreach v of varlist loan jobs forgiveness *_proceed {
    replace `v' = `v'*bus_ratio
}

rename year_approved year
rename month_approved month

// Aggregate by time/county/naics for when multiple loans are matched to a cell
gcollapse (sum) loan jobs forgiveness *_proceed (first) avg_mthly_wages mthly_emplvl p, ///
    by(county naics year month)
    
// Share of wage bill covered by the payroll + health care proceeds
generate share_wage_bill = 100*payroll_proceed/(jobs*avg_mthly_wages*6)

// Rescale to aggregate number of jobs covered to account for units not matched
merge n:1 year month using "$work/02-distribute-ppp-covid/ppp-covid-data-aggregated.dta", nogenerate

gegen ttjobs2 = total(jobs), by(year month)
replace jobs = jobs/ttjobs2*ttjobs

// -------------------------------------------------------------------------- //
// Fraction of the six-month wage bill covered by proceeds
// -------------------------------------------------------------------------- //

preserve
    gcollapse (mean) share_wage_bill [pw=jobs], by(year month p)
    gcollapse (mean) share_wage_bill, by(p)
    
    tempfile ppp_share_wages
    save "`ppp_share_wages'", replace
    
    gr tw line share_wage_bill p, col(black) lw(thick) ///
        yscale(range(0 100)) ylabel(0(10)100) ytitle("Share of 6-month wage bill (%)") ///
        xlabel(0 "0%" 10000 "10%" 20000 "20%" 30000 "30%" 40000 "40%" 50000 "50%" ///
            60000 "60%" 70000 "70%" 80000 "80%" 90000 "90%" 99000 "99%") ///
        xtitle("Percentile of wage distribution") ///
        legend(off) xsize(6) ysize(3) scale(1.2) /*title("Share of wage bill covered by PPP") ///
        subtitle("by percentile of the wage distribution")*/
    graph export "$graphs/02-distribute-ppp-covid/ppp-covid-share-wages.pdf", replace
restore

// -------------------------------------------------------------------------- //
// Fraction of labor force covered, by percentile
// -------------------------------------------------------------------------- //
    
preserve
    gcollapse (sum) jobs mthly_emplvl, by(year month p)
    generate frac_jobs = 100*jobs/mthly_emplvl
    gcollapse (sum) frac_jobs, by(p)
    
    tempfile ppp_frac_jobs
    save "`ppp_frac_jobs'", replace

    gr tw line frac_jobs p, col(black) lw(thick) ///
        yscale(range(0 100)) ylabel(0(10)100) ytitle("Share of workforce (%)") ///
        xlabel(0 "0%" 10000 "10%" 20000 "20%" 30000 "30%" 40000 "40%" 50000 "50%" ///
            60000 "60%" 70000 "70%" 80000 "80%" 90000 "90%" 99000 "99%") ///
        xtitle("Percentile of wage distribution") ///
        legend(off) xsize(6) ysize(3) scale(1.2) /*title("Share of workforce covered by PPP") ///
        subtitle("by percentile of the wage distribution")*/
    graph export "$graphs/02-distribute-ppp-covid/ppp-covid-share-workforce.pdf", replace
restore
    
// -------------------------------------------------------------------------- //
// Proceeds and fraction of loans forgiven, by percentile
// -------------------------------------------------------------------------- //

preserve
    /// Aggregate by percentile
    gcollapse (rawsum) loan utilities_proceed payroll_proceed ///
        mortgage_interest_proceed rent_proceed refinance_eidl_proceed ///
        health_care_proceed debt_interest_proceed forgiveness jobs mthly_emplvl ///
        (mean) avg_mthly_wages [pw=mthly_emplvl], by(p)

    // Fraction of loan forgiven and workforce covered
    generate frac_forgiven = 100*forgiveness/loan
    
    tempfile ppp_proceeds
    save "`ppp_proceeds'", replace
    
    gr tw (line frac_forgiven p, col(black) lw(thick)), ///
        yscale(range(0 100)) ylabel(0(10)100) ytitle("Share forgiven (%)") ///
        xlabel(0 "0%" 10000 "10%" 20000 "20%" 30000 "30%" 40000 "40%" 50000 "50%" ///
            60000 "60%" 70000 "70%" 80000 "80%" 90000 "90%" 99000 "99%") ///
        xtitle("Percentile of wage distribution") xsize(6) ysize(3) scale(1.2) ///
        /*title("Share of PPP loan amount forgiven") subtitle("as of 07/2021")*/ ///
        legend(off)
    graph export "$graphs/02-distribute-ppp-covid/ppp-covid-forgiveness.pdf", replace

    // Spending of proceeds
    cap drop decomp_* 
    local vlist ""
    summarize loan, meanonly
    foreach v in payroll health_care rent utilities mortgage_interest ///
        debt_interest refinance_eidl {
            
        if ("`decomp_vprev'" == "") {
            generate decomp_`v' = 100*`v'/r(sum)
        }
        else {
            generate decomp_`v' = `decomp_vprev' + 100*`v'/r(sum)
        }
        local decomp_vprev decomp_`v'
        local vlist decomp_`v' `vlist'
    }
        
    gr tw (bar `vlist' p, yaxis(1) barwidth(1000 ..) lw(none ..) ///
            col(green cranberry*1.2 cranberry cranberry*0.8 cranberry*0.6 ebblue*0.8 ebblue*1.2)), ///
        xsize(6) ysize(3) ///
        yscale(range(0 1.5) axis(1)) ytitle("Share of PPP loan amounts (%)", axis(1)) ylabel(0(0.25)1.5, format(%3.2f) axis(1)) ///
        xlabel(0 "0%" 10000 "10%" 20000 "20%" 30000 "30%" 40000 "40%" 50000 "50%" ///
            60000 "60%" 70000 "70%" 80000 "80%" 90000 "90%" 99000 "99%") ///
        xtitle("Percentile of wage distribution") ///
        /*title("Proceeds of PPP loans") subtitle("by type of spending and percentile of the wage distribution")*/ ///
        legend(pos(3) cols(1) label(1 "EIDL" "refinancing") label(2 "Debt" "interest") ///
            label(3 "Mortage" "interest") label(4 "Utilities") label(5 "Rent") ///
            label(6 "Health care") label(7 "Payroll") label(8 "Share of" "total amount") ///
            order(- "{bf:Proceeds}" "{bf:spent on:}" - 1 2 3 4 5 6 7))
    graph export "$graphs/02-distribute-ppp-covid/ppp-covid-proceeds.pdf", replace
restore

// -------------------------------------------------------------------------- //
// Export distribution
// -------------------------------------------------------------------------- //

use "`ppp_frac_jobs'", clear
merge 1:1 p using "`ppp_proceeds'", nogenerate assert(match)
merge 1:1 p using "`ppp_share_wages'", nogenerate assert(match)

generate rank_flemp_ppp = p/1e5
replace rank_flemp_ppp = -99 if p == 0

replace frac_jobs = frac_jobs/100
replace share_wage_bill = share_wage_bill/100

egen total_proceeds = rowtotal(*_proceed)
gegen share_flemp          = mean((payroll_proceed + health_care_proceed)/total_proceeds)
gegen share_housing_tenant = mean(rent_proceed/total_proceeds)
gegen share_fkfix          = mean((mortgage_interest_proceed + debt_interest_proceed)/total_proceeds)
gegen share_princ          = mean((utilities_proceed + refinance_eidl_proceed)/total_proceeds)

gegen check = total(share_flemp + share_housing_tenant + share_fkfix + share_princ)
asser reldif(check, 100) < 1e-7

keep p rank_flemp_ppp frac_jobs share_wage_bill share_flemp share_housing_tenant share_fkfix share_princ

save "$work/02-distribute-ppp-covid/ppp-distribution.dta", replace
