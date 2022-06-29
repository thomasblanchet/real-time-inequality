// -------------------------------------------------------------------------- //
// Broadly check for consistency between DINA and CPS variables
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Check CPS & DINA variables over time
// -------------------------------------------------------------------------- //

use "$work/01-import-transport-cps/cps-transport-summary.dta", clear
merge 1:1 year using "$work/02-export-transport-dina/dina-transport-summary.dta", nogenerate

foreach v of varlist cps_has_* {
    local stub = substr("`v'", 9, .)
    
    gr tw con cps_has_`stub' dina_has_`stub' year, col(ebblue cranberry) lw(medthick..) msym(O S) msize(small..) ///
        title("Fraction > 0") subtitle("`stub'") xtitle("") ytitle("%") legend(rows(1) label(1 "CPS") label(2 "DINA")) ///
        xlabel(1975(5)2020) yscale(range(0 100)) ylabel(0(10)100)
    graph export "$graphs/02-transport-check-consistency/transport-cps-dina-has-`stub'.pdf", replace
    
    gr tw con cps_top10_`stub' dina_top10_`stub' year, col(ebblue cranberry) lw(medthick..) msym(O S) msize(small..) ///
        title("Top 10% share") subtitle("`stub'") xtitle("") ytitle("%") legend(rows(1) label(1 "CPS") label(2 "DINA")) ///
        xlabel(1975(5)2020) yscale(range(0 100)) ylabel(0(10)100)
    graph export "$graphs/02-transport-check-consistency/transport-cps-dina-top10-`stub'.pdf", replace
    
    gr tw con cps_bot50_`stub' dina_bot50_`stub' year, col(ebblue cranberry) lw(medthick..) msym(O S) msize(small..) ///
        title("Bottom 50% share") subtitle("`stub'") xtitle("") ytitle("%") legend(rows(1) label(1 "CPS") label(2 "DINA")) ///
        xlabel(1975(5)2020) yscale(range(0 100)) ylabel(0(10)100)
    graph export "$graphs/02-transport-check-consistency/transport-cps-dina-bot50-`stub'.pdf", replace
    
    gr tw con cps_`stub' dina_`stub' year, col(ebblue cranberry) lw(medthick..) msym(O S) msize(small..) ///
        title("Average") subtitle("`stub'") xtitle("") ytitle("USD (nominal)") legend(rows(1) label(1 "CPS") label(2 "DINA")) ///
        xlabel(1975(5)2020)
    graph export "$graphs/02-transport-check-consistency/transport-cps-dina-avg-`stub'.pdf", replace
}

// -------------------------------------------------------------------------- //
// Check SCF & DINA variables over time
// -------------------------------------------------------------------------- //

use "$work/02-export-transport-dina/dina-transport-summary.dta", clear
merge 1:1 year using "$work/01-import-transport-scf/scf-transport-summary.dta", nogenerate
sort year

foreach v of varlist scf_has_* {
    local stub = substr("`v'", 9, .)
    
    gr tw con scf_has_`stub' dina_has_`stub' year, col(ebblue cranberry) lw(medthick..) msym(O S) msize(small..) ///
        title("Fraction > 0") subtitle("`stub'") xtitle("") ytitle("%") legend(rows(1) label(1 "SCF") label(2 "DINA")) ///
        xlabel(1975(5)2020) yscale(range(0 100)) ylabel(0(10)100)
    graph export "$graphs/02-transport-check-consistency/transport-scf-dina-has-`stub'.pdf", replace
    
    gr tw con scf_top10_`stub' dina_top10_`stub' year, col(ebblue cranberry) lw(medthick..) msym(O S) msize(small..) ///
        title("Top 10% share") subtitle("`stub'") xtitle("") ytitle("%") legend(rows(1) label(1 "SCF") label(2 "DINA")) ///
        xlabel(1975(5)2020) yscale(range(0 100)) ylabel(0(10)100)
    graph export "$graphs/02-transport-check-consistency/transport-scf-dina-top10-`stub'.pdf", replace
    
    gr tw con scf_bot50_`stub' dina_bot50_`stub' year, col(ebblue cranberry) lw(medthick..) msym(O S) msize(small..) ///
        title("Bottom 50% share") subtitle("`stub'") xtitle("") ytitle("%") legend(rows(1) label(1 "SCF") label(2 "DINA")) ///
        xlabel(1975(5)2020) yscale(range(0 100)) ylabel(0(10)100)
    graph export "$graphs/02-transport-check-consistency/transport-scf-dina-bot50-`stub'.pdf", replace
    
    gr tw con scf_`stub' dina_`stub' year, col(ebblue cranberry) lw(medthick..) msym(O S) msize(small..) ///
        title("Average") subtitle("`stub'") xtitle("") ytitle("USD (nominal)") legend(rows(1) label(1 "SCF") label(2 "DINA")) ///
        xlabel(1975(5)2020)
    graph export "$graphs/02-transport-check-consistency/transport-scf-dina-avg-`stub'.pdf", replace
}
