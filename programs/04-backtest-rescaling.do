// -------------------------------------------------------------------------- //
// Backtest the method
// -------------------------------------------------------------------------- //

clear
save "$work/04-backtest-rescaling/backtest-princ.dta", replace emptyok
save "$work/04-backtest-rescaling/backtest-peinc.dta", replace emptyok
save "$work/04-backtest-rescaling/backtest-dispo.dta", replace emptyok
save "$work/04-backtest-rescaling/backtest-poinc.dta", replace emptyok
save "$work/04-backtest-rescaling/backtest-hweal.dta", replace emptyok

// -------------------------------------------------------------------------- //
// Backtest, 1-year ahead
// -------------------------------------------------------------------------- //

global date_begin = ym(1977, 01)
global date_end   = ym(2019, 12)

quietly {
    foreach unit in "household" "individual" "equal-split" {
        foreach v in princ peinc dispo poinc hweal {
            foreach t of numlist $date_begin / $date_end {
                local year = year(dofm(`t'))
                local month = month(dofm(`t'))
                
                noisily di "-> `year'm`month', `v', `unit'"
            
                use id weight `v' using "$work/03-build-monthly-microfiles-backtest-rescaling-1y/microfiles/dina-monthly-`year'm`month'.dta", clear
                
                if ("`unit'" == "equal-split") {
                    gegen `v' = mean(`v'), by(id) replace
                }
                else if ("`unit'" == "household") {
                    gcollapse (sum) `v' (mean) weight, by(id)
                }
                
                // Calculate rank
                sort `v'
                generate rank = sum(weight)
                replace rank = (rank - weight/2)/rank[_N]
                
                // Calcualte groups
                generate bracket = ""
                replace bracket = "bot50" if inrange(rank, 0.00, 0.50)
                replace bracket = "mid40" if inrange(rank, 0.50, 0.90)
                replace bracket = "next9" if inrange(rank, 0.90, 0.99)
                replace bracket = "top1"  if inrange(rank, 0.99, 1.00)
                
                gcollapse (mean) `v' [pw=weight], by(bracket)
                
                generate year = `year'
                generate month = `month'
                generate lag = 1
                generate unit = "`unit'"

                append using "$work/04-backtest-rescaling/backtest-`v'.dta"
                save "$work/04-backtest-rescaling/backtest-`v'.dta", replace
            }
        }   
    }
}

// -------------------------------------------------------------------------- //
// Backtest, 2-year ahead
// -------------------------------------------------------------------------- //

global date_begin = ym(1977, 01)
global date_end   = ym(2019, 12)

quietly {
    foreach unit in "household" "individual" "equal-split" {
        foreach v in princ peinc dispo poinc hweal {
            foreach t of numlist $date_begin / $date_end {
                local year = year(dofm(`t'))
                local month = month(dofm(`t'))
                
                noisily di "-> `year'm`month', `v', `unit'"
            
                use id weight `v' using "$work/03-build-monthly-microfiles-backtest-rescaling-2y/microfiles/dina-monthly-`year'm`month'.dta", clear
                
                if ("`unit'" == "equal-split") {
                    gegen `v' = mean(`v'), by(id) replace
                }
                else if ("`unit'" == "household") {
                    gcollapse (sum) `v' (mean) weight, by(id)
                }
                
                // Calculate rank
                sort `v'
                generate rank = sum(weight)
                replace rank = (rank - weight/2)/rank[_N]
                
                // Calcualte groups
                generate bracket = ""
                replace bracket = "bot50" if inrange(rank, 0.00, 0.50)
                replace bracket = "mid40" if inrange(rank, 0.50, 0.90)
                replace bracket = "next9" if inrange(rank, 0.90, 0.99)
                replace bracket = "top1"  if inrange(rank, 0.99, 1.00)
                
                gcollapse (mean) `v' [pw=weight], by(bracket)
                
                generate year = `year'
                generate month = `month'
                generate lag = 2
                generate unit = "`unit'"

                append using "$work/04-backtest-rescaling/backtest-`v'.dta"
                save "$work/04-backtest-rescaling/backtest-`v'.dta", replace
            }
        }   
    }
}

// -------------------------------------------------------------------------- //
// Combine and plot
// -------------------------------------------------------------------------- //

// Reference
use "$work/04-backtest/dina-yearly-princ.dta", clear
merge 1:1 year bracket unit using "$work/04-backtest/dina-yearly-peinc.dta", nogenerate assert(match)
merge 1:1 year bracket unit using "$work/04-backtest/dina-yearly-dispo.dta", nogenerate assert(match)
merge 1:1 year bracket unit using "$work/04-backtest/dina-yearly-poinc.dta", nogenerate assert(match)
merge 1:1 year bracket unit using "$work/04-backtest/dina-yearly-hweal.dta", nogenerate assert(match)

renvars princ peinc dispo poinc hweal, prefix(average)
reshape long average, i(year unit bracket) j(income) string
generate lag = 99

expand 2, gen(new)
generate type = cond(new, "full", "rescaling")
drop new

tempfile ref
save "`ref'", replace

// Backtesting datasets (full)
use "$work/04-backtest/backtest-princ.dta", clear
merge 1:1 year month bracket unit lag using "$work/04-backtest/backtest-peinc.dta", nogenerate assert(match)
merge 1:1 year month bracket unit lag using "$work/04-backtest/backtest-dispo.dta", nogenerate assert(match)
merge 1:1 year month bracket unit lag using "$work/04-backtest/backtest-poinc.dta", nogenerate assert(match)
merge 1:1 year month bracket unit lag using "$work/04-backtest/backtest-hweal.dta", nogenerate assert(match)

renvars princ peinc dispo poinc hweal, prefix(average)
reshape long average, i(year month unit bracket lag) j(income) string
collapse (mean) average, by(year unit bracket income lag)

generate type = "full"

tempfile full
save "`full'", replace

// Backtesting datasets (rescaling)
use "$work/04-backtest-rescaling/backtest-princ.dta", clear
merge 1:1 year month bracket unit lag using "$work/04-backtest-rescaling/backtest-peinc.dta", nogenerate assert(match)
merge 1:1 year month bracket unit lag using "$work/04-backtest-rescaling/backtest-dispo.dta", nogenerate assert(match)
merge 1:1 year month bracket unit lag using "$work/04-backtest-rescaling/backtest-poinc.dta", nogenerate assert(match)
merge 1:1 year month bracket unit lag using "$work/04-backtest-rescaling/backtest-hweal.dta", nogenerate assert(match)

renvars princ peinc dispo poinc hweal, prefix(average)
reshape long average, i(year month unit bracket lag) j(income) string
collapse (mean) average, by(year unit bracket income lag)

generate type = "rescaling"

append using "`ref'"
append using "`full'"

// Convert to real
merge n:1 year using "$work/02-prepare-nipa/nipa-simplified-yearly.dta", nogenerate keep(match) keepusing(nipa_deflator)
replace average = average/nipa_deflator
drop nipa_deflator

// Calculate shares
generate n = .
replace n = 0.50 if bracket == "bot50"
replace n = 0.40 if bracket == "mid40"
replace n = 0.09 if bracket == "next9"
replace n = 0.01 if bracket == "top1"

gegen tot = total(n*average), by(year income unit lag type)
generate share = n*average/tot
drop tot

// Make as panel
gegen id = group(bracket income unit lag type)
tsset id year, yearly

// Calculate changes
generate chg1_share = 100*(share - L1.share)
generate chg2_share = 100*(share - L2.share)

generate chg1_average = 100*(average - L1.average)/L1.average
generate chg2_average = 100*(average - L2.average)/L2.average

// Calculate changes, using real value as reference
drop id
reshape wide chg* average share, i(year bracket income unit type) j(lag)
foreach v of varlist *99 {
    local u = subinstr("`v'", "99", "", 1)
    generate ref_`u' = `v'
}
reshape long chg1_share chg2_share chg1_average chg2_average average share, i(year bracket income unit type) j(lag)

gegen id = group(bracket income unit lag type)
tsset id year, yearly

generate chgref1_share = 100*(share - L1.ref_share)
generate chgref2_share = 100*(share - L2.ref_share)

generate chgref1_average = 100*(average - L1.ref_average)/L1.ref_average
generate chgref2_average = 100*(average - L2.ref_average)/L2.ref_average

// Calculate summary statistics
keep year bracket income unit chg* lag type
reshape wide chg*, i(year bracket income unit type) j(lag)

// Only show equal-split (results similar for all units)
keep if unit == "equal-split"

// Mark recession years
generate recession = 0
replace recession = 1 if inlist(year, 1980, 1981, 1982, 1990, 1991, 2001, 2008, 2009)
replace recession = 1 if inlist(year, 1983, 1992, 2002, 2010)

// Mark tax reform years
generate tax_reform = inlist(year, 1987, 1988, 1991, 1992, 1993, 2012, 2013)

// Plots

// Bottom 50%
gr tw (line chgref1_average99 chgref1_average99 if bracket == "bot50" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "bot50" & income == "princ" & unit == "equal-split" & type == "full", ///
        col(ebblue) msym(O)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "bot50" & income == "princ" & unit == "equal-split" & type == "rescaling", ///
        col(cranberry) msym(Oh)), ///
    aspectratio(1) xsize(6) ysize(4) legend(cols(1) pos(3) order(2 3) label(2 "Full Methodology") label(3 "Rescaling Only")) scale(1.2) ///
    xscale(range(-10 10)) yscale(range(-10 10)) ///
    ylabel(-10(5)10) xlabel(-10(5)10) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest-rescaling/pred-avg-bot50-1y.pdf", replace
    
gr tw (line chgref2_average99 chgref2_average99 if bracket == "bot50" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "bot50" & income == "princ" & unit == "equal-split" & type == "full", ///
        col(ebblue) msym(O)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "bot50" & income == "princ" & unit == "equal-split" & type == "rescaling", ///
        col(cranberry) msym(Oh)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-15 15)) yscale(range(-15 15)) ///
    ylabel(-15(5)15) xlabel(-15(5)15) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest-rescaling/pred-avg-bot50-2y.pdf", replace

// Middle 40%
gr tw (line chgref1_average99 chgref1_average99 if bracket == "mid40" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "mid40" & income == "princ" & unit == "equal-split" & type == "full", ///
        col(ebblue) msym(O)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "mid40" & income == "princ" & unit == "equal-split" & type == "rescaling", ///
        col(cranberry) msym(Oh)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-4 6)) yscale(range(-4 6)) ///
    ylabel(-4(2)6) xlabel(-4(2)6) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest-rescaling/pred-avg-mid40-1y.pdf", replace

gr tw (line chgref2_average99 chgref2_average99 if bracket == "mid40" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "mid40" & income == "princ" & unit == "equal-split" & type == "full", ///
        col(ebblue) msym(O)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "mid40" & income == "princ" & unit == "equal-split" & type == "rescaling", ///
        col(cranberry) msym(Oh)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-5 8)) yscale(range(-5 8)) ///
    ylabel(-4(2)8) xlabel(-4(2)8) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest-rescaling/pred-avg-mid40-2y.pdf", replace

// Next 9%
gr tw (line chgref1_average99 chgref1_average99 if bracket == "next9" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "next9" & income == "princ" & unit == "equal-split" & type == "full", ///
        col(ebblue) msym(O)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "next9" & income == "princ" & unit == "equal-split" & type == "rescaling", ///
        col(cranberry) msym(Oh)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-4 6)) yscale(range(-4 6)) ///
    ylabel(-4(2)6) xlabel(-4(2)6) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest-rescaling/pred-avg-next9-1y.pdf", replace

gr tw (line chgref2_average99 chgref2_average99 if bracket == "next9" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "next9" & income == "princ" & unit == "equal-split" & type == "full", ///
        col(ebblue) msym(O)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "next9" & income == "princ" & unit == "equal-split" & type == "rescaling", ///
        col(cranberry) msym(Oh)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-5 8)) yscale(range(-5 8)) ///
    ylabel(-4(2)8) xlabel(-4(2)8) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest-rescaling/pred-avg-next9-2y.pdf", replace

// Top 1%
gr tw (line chgref1_average99 chgref1_average99 if bracket == "top1" & income == "princ" & unit == "equal-split", col(black) lw(medthick)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "top1" & income == "princ" & unit == "equal-split" & type == "full", ///
        col(ebblue) msym(O)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "top1" & income == "princ" & unit == "equal-split" & type == "rescaling", ///
        col(cranberry) msym(Oh)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-10 20)) yscale(range(-10 20)) ///
    ylabel(-10(5)20) xlabel(-10(5)20) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest-rescaling/pred-avg-top1-1y.pdf", replace
    
gr tw (line chgref2_average99 chgref2_average99 if bracket == "top1" & income == "princ" & unit == "equal-split", col(black) lw(medthick)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "top1" & income == "princ" & unit == "equal-split" & type == "full", ///
        col(ebblue) msym(O)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "top1" & income == "princ" & unit == "equal-split" & type == "rescaling", ///
        col(cranberry) msym(Oh)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-15 37)) yscale(range(-15 37)) ///
    ylabel(-15(5)35) xlabel(-15(5)35) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest-rescaling/pred-avg-top1-2y.pdf", replace
