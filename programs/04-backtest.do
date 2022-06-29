// -------------------------------------------------------------------------- //
// Backtest the method
// -------------------------------------------------------------------------- //

clear
save "$work/04-backtest/backtest-princ.dta", replace emptyok
save "$work/04-backtest/backtest-peinc.dta", replace emptyok
save "$work/04-backtest/backtest-dispo.dta", replace emptyok
save "$work/04-backtest/backtest-poinc.dta", replace emptyok
save "$work/04-backtest/backtest-hweal.dta", replace emptyok

// -------------------------------------------------------------------------- //
// Monthly distributions
// -------------------------------------------------------------------------- //

global date_begin = ym(1976, 01)
global date_end   = ym(2019, 12)

quietly {
    foreach unit in /*"household" "individual"*/ "equal-split" {
        foreach v in princ peinc dispo poinc hweal {
            foreach t of numlist $date_begin / $date_end {
                local year = year(dofm(`t'))
                local month = month(dofm(`t'))
                
                noisily di "-> `year'm`month', `v', `unit'"
            
                use id weight `v' using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
                
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
                generate lag = 0
                generate unit = "`unit'"

                append using "$work/04-backtest/backtest-`v'.dta"
                save "$work/04-backtest/backtest-`v'.dta", replace
            }
        }   
    }
}

// -------------------------------------------------------------------------- //
// Backtest, 1-year ahead
// -------------------------------------------------------------------------- //

global date_begin = ym(1976, 01)
global date_end   = ym(2019, 12)

quietly {
    foreach unit in /*"household" "individual"*/ "equal-split" {
        foreach v in princ peinc dispo poinc hweal {
            foreach t of numlist $date_begin / $date_end {
                local year = year(dofm(`t'))
                local month = month(dofm(`t'))
                
                noisily di "-> `year'm`month', `v', `unit'"
            
                use id weight `v' using "$work/03-build-monthly-microfiles-backtest-1y/microfiles/dina-monthly-`year'm`month'.dta", clear
                
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

                append using "$work/04-backtest/backtest-`v'.dta"
                save "$work/04-backtest/backtest-`v'.dta", replace
            }
        }   
    }
}

// -------------------------------------------------------------------------- //
// Backtest, 2-year ahead
// -------------------------------------------------------------------------- //

global date_begin = ym(1976, 01)
global date_end   = ym(2019, 12)

quietly {
    foreach unit in /*"household" "individual"*/ "equal-split" {
        foreach v in princ peinc dispo poinc hweal {
            foreach t of numlist $date_begin / $date_end {
                local year = year(dofm(`t'))
                local month = month(dofm(`t'))
                
                noisily di "-> `year'm`month', `v', `unit'"
            
                use id weight `v' using "$work/03-build-monthly-microfiles-backtest-2y/microfiles/dina-monthly-`year'm`month'.dta", clear
                
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

                append using "$work/04-backtest/backtest-`v'.dta"
                save "$work/04-backtest/backtest-`v'.dta", replace
            }
        }   
    }
}

// -------------------------------------------------------------------------- //
// Actual DINA
// -------------------------------------------------------------------------- //

clear
save "$work/04-backtest/dina-yearly-princ.dta", replace emptyok
save "$work/04-backtest/dina-yearly-peinc.dta", replace emptyok
save "$work/04-backtest/dina-yearly-dispo.dta", replace emptyok
save "$work/04-backtest/dina-yearly-poinc.dta", replace emptyok
save "$work/04-backtest/dina-yearly-hweal.dta", replace emptyok

quietly {
    foreach unit in /*"household" "individual"*/ "equal-split" {
        foreach v in princ peinc dispo poinc hweal {
            noisily di "-> `v', `unit'"
            
            use year id weight dina_`v' using "$work/02-prepare-dina/dina-rescaled.dta", clear
            rename dina_`v' `v'
            
            if ("`unit'" == "equal-split") {
                gegen `v' = mean(`v'), by(year id) replace
            }
            else if ("`unit'" == "household") {
                gcollapse (sum) `v' (mean) weight, by(year id)
            }
            
            // Calculate rank
            sort year `v'
            by year: generate rank = sum(weight)
            by year: replace rank = (rank - weight/2)/rank[_N]
            
            // Calcualte groups
            generate bracket = ""
            replace bracket = "bot50" if inrange(rank, 0.00, 0.50)
            replace bracket = "mid40" if inrange(rank, 0.50, 0.90)
            replace bracket = "next9" if inrange(rank, 0.90, 0.99)
            replace bracket = "top1"  if inrange(rank, 0.99, 1.00)
            
            gcollapse (mean) `v' [pw=weight], by(year bracket)
            
            generate unit = "`unit'"

            append using "$work/04-backtest/dina-yearly-`v'.dta"
            save "$work/04-backtest/dina-yearly-`v'.dta", replace
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

tempfile ref
save "`ref'", replace

// Backtesting datasets
use "$work/04-backtest/backtest-princ.dta", clear
merge 1:1 year month bracket unit lag using "$work/04-backtest/backtest-peinc.dta", nogenerate assert(match)
merge 1:1 year month bracket unit lag using "$work/04-backtest/backtest-dispo.dta", nogenerate assert(match)
merge 1:1 year month bracket unit lag using "$work/04-backtest/backtest-poinc.dta", nogenerate assert(match)
merge 1:1 year month bracket unit lag using "$work/04-backtest/backtest-hweal.dta", nogenerate assert(match)

renvars princ peinc dispo poinc hweal, prefix(average)
reshape long average, i(year month unit bracket lag) j(income) string
collapse (mean) average, by(year unit bracket income lag)

append using "`ref'"

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

gegen tot = total(n*average), by(year income unit lag)
generate share = n*average/tot
drop tot

// Make as panel
gegen id = group(bracket income unit lag)
tsset id year, yearly

// Calculate changes
generate chg1_share = 100*(share - L1.share)
generate chg2_share = 100*(share - L2.share)

generate chg1_average = 100*(average - L1.average)/L1.average
generate chg2_average = 100*(average - L2.average)/L2.average

// Calculate changes, using real value as reference
drop id
reshape wide chg* average share, i(year bracket income unit) j(lag)
foreach v of varlist *99 {
    local u = subinstr("`v'", "99", "", 1)
    generate ref_`u' = `v'
}
reshape long chg1_share chg2_share chg1_average chg2_average average share, i(year bracket income unit) j(lag)

gegen id = group(bracket income unit lag)
tsset id year, yearly

generate chgref1_share = 100*(share - L1.ref_share)
generate chgref2_share = 100*(share - L2.ref_share)

generate chgref1_average = 100*(average - L1.ref_average)/L1.ref_average
generate chgref2_average = 100*(average - L2.ref_average)/L2.ref_average

// Calculate summary statistics
keep year bracket income unit chg* lag
reshape wide chg*, i(year bracket income unit) j(lag)

// Only show equal-split (results similar for all units)
keep if unit == "equal-split"

// Mark recession years
generate recession = 0
replace recession = 1 if inlist(year, 1980, 1981, 1982, 1990, 1991, 2001, 2008, 2009)
replace recession = 1 if inlist(year, 1983, 1992, 2002, 2010)

// Mark tax reform years
generate tax_reform = inlist(year, 1987, 1988, 1991, 1992, 1993, 2012, 2013, 2001, 2002, 2003)

// Plots
generate year_label = ""
generate year_pos = 3

replace year_label = ""
replace year_label = "1984" if year == 1984
replace year_label = "2012" if year == 2012
replace year_label = "2017" if year == 2017

// Bottom 50%
gr tw (line chgref1_average99 chgref1_average99 if bracket == "bot50" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "bot50" & income == "princ" & unit == "equal-split" & !tax_reform, ///
        col(ebblue) msym(O) mlabel(year_label) mlabcol(black)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "bot50" & income == "princ" & unit == "equal-split" & tax_reform, ///
        col(cranberry) msym(T) mlabel(year_label) mlabcol(black)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-10 10)) yscale(range(-10 10)) ///
    ylabel(-10(5)10) xlabel(-10(5)10) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest/pred-avg-bot50-1y.pdf", replace
    
replace year_label = ""
replace year_label = "1985" if year == 1985
replace year_label = "2012" if year == 2012
replace year_label = "2018" if year == 2018
gr tw (line chgref2_average99 chgref2_average99 if bracket == "bot50" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "bot50" & income == "princ" & unit == "equal-split" & !tax_reform, ///
        col(ebblue) msym(O) mlabel(year_label) mlabcol(black)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "bot50" & income == "princ" & unit == "equal-split" & tax_reform, ///
        col(cranberry) msym(T) mlabel(year_label) mlabcol(black)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-15 15)) yscale(range(-15 15)) ///
    ylabel(-15(5)15) xlabel(-15(5)15) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest/pred-avg-bot50-2y.pdf", replace

// Middle 40%
replace year_label = ""
replace year_label = "1987" if year == 1987
replace year_label = "1988" if year == 1988
replace year_label = "2012" if year == 2012
replace year_label = "1991" if year == 1991
replace year_label = "2009" if year == 2009

gr tw (line chgref1_average99 chgref1_average99 if bracket == "mid40" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "mid40" & income == "princ" & unit == "equal-split" & !tax_reform, ///
        col(ebblue) msym(O) mlabel(year_label) mlabcol(black)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "mid40" & income == "princ" & unit == "equal-split" & tax_reform, ///
        col(cranberry) msym(T) mlabel(year_label) mlabcol(black)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-4 6)) yscale(range(-4 6)) ///
    ylabel(-4(2)6) xlabel(-4(2)6) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest/pred-avg-mid40-1y.pdf", replace
    
replace year_label = ""
replace year_label = "1988" if year == 1988
replace year_label = "1991" if year == 1991
replace year_label = "1992" if year == 1992
replace year_label = "1993" if year == 1993
replace year_label = "1994" if year == 1994
replace year_label = "2009" if year == 2009

replace year_pos = 3
replace year_pos = 12 if inlist(year, 1992, 1993)

gr tw (line chgref2_average99 chgref2_average99 if bracket == "mid40" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "mid40" & income == "princ" & unit == "equal-split" & !tax_reform, ///
        col(ebblue) msym(O) mlabel(year_label) mlabvpos(year_pos) mlabcol(black)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "mid40" & income == "princ" & unit == "equal-split" & tax_reform, ///
        col(cranberry) msym(T) mlabel(year_label) mlabvpos(year_pos) mlabcol(black)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-5 8)) yscale(range(-5 8)) ///
    ylabel(-4(2)8) xlabel(-4(2)8) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest/pred-avg-mid40-2y.pdf", replace

// Next 9%
replace year_label = ""
replace year_label = "2000" if year == 2000
replace year_label = "2009" if year == 2009
replace year_label = "2013" if year == 2013

replace year_pos = 3
replace year_pos = 1 if inlist(year, 2009)
replace year_pos = 10 if inlist(year, 2013)

gr tw (line chgref1_average99 chgref1_average99 if bracket == "next9" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "next9" & income == "princ" & unit == "equal-split" & !tax_reform, ///
        col(ebblue) msym(O) mlabel(year_label) mlabvpos(year_pos) mlabcol(black)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "next9" & income == "princ" & unit == "equal-split" & tax_reform, ///
        col(cranberry) msym(T) mlabel(year_label) mlabvpos(year_pos) mlabcol(black)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-4 6)) yscale(range(-4 6)) ///
    ylabel(-4(2)6) xlabel(-4(2)6) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest/pred-avg-next9-1y.pdf", replace
    
replace year_label = ""
replace year_label = "2000" if year == 2000
replace year_label = "2009" if year == 2009
replace year_label = "2013" if year == 2013

replace year_pos = 3
replace year_pos = 5 if inlist(year, 2009)
replace year_pos = 10 if inlist(year, 2013)

gr tw (line chgref2_average99 chgref2_average99 if bracket == "next9" & income == "princ" & unit == "equal-split" & !tax_reform, col(black) lw(medthick)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "next9" & income == "princ" & unit == "equal-split" & !tax_reform, ///
        col(ebblue) msym(O) mlabel(year_label) mlabvpos(year_pos) mlabcol(black)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "next9" & income == "princ" & unit == "equal-split" & tax_reform, ///
        col(cranberry) msym(T) mlabel(year_label) mlabvpos(year_pos) mlabcol(black)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-5 8)) yscale(range(-5 8)) ///
    ylabel(-4(2)8) xlabel(-4(2)8) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest/pred-avg-next9-2y.pdf", replace

// Top 1%
replace year_label = ""
replace year_label = "1979" if year == 1979
replace year_label = "1987" if year == 1987
replace year_label = "1988" if year == 1988
replace year_label = "1993" if year == 1993
replace year_label = "1994" if year == 1994
replace year_label = "2012" if year == 2012
replace year_label = "1991" if year == 1991

replace year_pos = 3
replace year_pos = 2 if inlist(year, 1987, 2012)

gr tw (line chgref1_average99 chgref1_average99 if bracket == "top1" & income == "princ" & unit == "equal-split", col(black) lw(medthick)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "top1" & income == "princ" & unit == "equal-split" & !tax_reform, ///
        col(ebblue) msym(O) mlabel(year_label) mlabvpos(year_pos) mlabcol(black)) ///
    (scatter chgref1_average99 chgref1_average1 if bracket == "top1" & income == "princ" & unit == "equal-split" & tax_reform, ///
        col(cranberry) msym(T) mlabel(year_label) mlabvpos(year_pos) mlabcol(black)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-10 20)) yscale(range(-10 20)) ///
    ylabel(-10(5)20) xlabel(-10(5)20) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest/pred-avg-top1.pdf", replace
    
replace year_label = ""
replace year_label = "1988" if year == 1988
replace year_label = "1993" if year == 1993
replace year_label = "1994" if year == 1994
replace year_label = "1991" if year == 1991
replace year_label = "1992" if year == 1992

replace year_pos = 3
replace year_pos = 2 if inlist(year, 1992)

gr tw (line chgref2_average99 chgref2_average99 if bracket == "top1" & income == "princ" & unit == "equal-split", col(black) lw(medthick)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "top1" & income == "princ" & unit == "equal-split" & !tax_reform, ///
        col(ebblue) msym(O) mlabel(year_label) mlabcol(black)) ///
    (scatter chgref2_average99 chgref2_average2 if bracket == "top1" & income == "princ" & unit == "equal-split" & tax_reform, ///
        col(cranberry) msym(T) mlabel(year_label) mlabvpos(year_pos) mlabcol(black)), ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-15 37)) yscale(range(-15 37)) ///
    ylabel(-15(5)35) xlabel(-15(5)35) ///
    xtitle("Predicted growth rate (%)") ///
    ytitle("Actual growth rate (%)")
graph export "$graphs/04-backtest/pred-avg-top1-2y.pdf", replace

save "$work/04-backtest/forecasts.dta", replace
forvalues lag = 1/2 {
    use "$work/04-backtest/forecasts.dta", clear
    
    // Forecast errors
    generate correct_sign = (sign(chgref`lag'_average`lag') == sign(chgref`lag'_average99)) if !missing(chgref`lag'_average`lag') & !missing(chgref`lag'_average99)
    generate fc_err = chgref`lag'_average`lag' - chgref`lag'_average99

    // All years
    preserve
        gegen sd = sd(chg`lag'_average99)
        gcollapse (sd) sd=chg`lag'_average99 (mean) correct_sign mean_fc_err=fc_err (sd) sd_fc_err=fc_err, by(bracket income)
        generate fc_rmse = sqrt(mean_fc_err^2 + sd_fc_err^2), before(mean_fc_err)
        renvars correct_sign mean_fc_err sd_fc_err sd fc_rmse, prefix(all_)
        tempfile fc_all
        save "`fc_all'"
    restore

    // Excluding tax reforms
    preserve
        gcollapse (mean) correct_sign mean_fc_err=fc_err (sd) sd_fc_err=fc_err if !tax_reform, by(bracket income)
        generate fc_rmse = sqrt(mean_fc_err^2 + sd_fc_err^2), before(mean_fc_err)
        renvars correct_sign mean_fc_err sd_fc_err fc_rmse, prefix(notax_)
        tempfile fc_notax
        save "`fc_notax'"
    restore

    // Recessions
    preserve
        gcollapse (mean) correct_sign mean_fc_err=fc_err (sd) sd_fc_err=fc_err if recession, by(bracket income)
        generate fc_rmse = sqrt(mean_fc_err^2 + sd_fc_err^2), before(mean_fc_err)
        renvars correct_sign mean_fc_err sd_fc_err fc_rmse, prefix(recession_)
        tempfile fc_recession
        save "`fc_recession'"
    restore

    use "`fc_all'", clear
    merge 1:1 bracket income using "`fc_notax'", nogenerate assert(match)
    merge 1:1 bracket income using "`fc_recession'", nogenerate assert(match)

    foreach v of varlist *_correct_sign {
        generate `v'_str = strofreal(100*`v', "%02.0f") + "\%", after(`v')
        drop `v'
        rename `v'_str `v'
    }

    foreach v of varlist all_sd *_fc_rmse *_mean_fc_err *_sd_fc_err {
        generate `v'_str = strofreal(`v', "%02.1f") + "~pp.", after(`v')
        drop `v'
        rename `v'_str `v'
    }

    generate income_order = .
    replace income_order = 1 if income == "princ"
    replace income_order = 2 if income == "peinc"
    replace income_order = 3 if income == "dispo"
    replace income_order = 4 if income == "poinc"
    replace income_order = 5 if income == "hweal"

    drop if income == "hweal" & bracket == "bot50"

    sort income_order bracket

    replace income = "\multirow{4}{*}{Factor Income}"     if income == "princ"
    replace income = "\multirow{4}{*}{Pretax Income}"     if income == "peinc"
    replace income = "\multirow{4}{*}{Disposable Income}" if income == "dispo"
    replace income = "\multirow{4}{*}{Post-tax Income}"   if income == "poinc"
    replace income = "\multirow{3}{*}{Wealth}"            if income == "hweal"

    by income_order: replace income = "" if _n > 1

    replace bracket = "Bottom 50\%" if bracket == "bot50"
    replace bracket = "Middle 40\%" if bracket == "mid40"
    replace bracket = "Next 9\%" if bracket == "next9"
    replace bracket = "Top 1\%" if bracket == "top1"

    generate vend = "\\"
    by income_order: replace vend = "\\ \midrule" if _n == _N
    replace vend = "\\" if _n == _N

    order income bracket
    listtab income bracket all_sd all_correct_sign all_fc_rmse all_mean_fc_err ///
            all_sd_fc_err notax_correct_sign notax_fc_rmse notax_mean_fc_err ///
            notax_sd_fc_err recession_correct_sign recession_fc_rmse ///
            recession_mean_fc_err recession_sd_fc_err ///
        using "$graphs/04-backtest/backtest-table-avg-`lag'y.tex", replace ///
        delimiter(" & ") ///
        vend(vend) ///
        headlines("\begin{tabular}{llccccccccccccc}" "\toprule" ///
            "\multirow{2}{*}{Concept} & \multirow{2}{*}{Bracket} & \multicolumn{5}{c}{All years} & \multicolumn{4}{c}{Excl. tax reforms}  & \multicolumn{4}{c}{Recessions} \\ \cmidrule(l){3-7} \cmidrule(l){8-11} \cmidrule(l){12-15}" ///
            " & & Std. Dev. & Correct sign & RMSE & Bias & Std. Err. & Correct sign & RMSE & Bias & Std. Err. & Correct sign & RMSE & Bias & Std. Err. \\ \midrule" ///
        ) ///
        footlines("\bottomrule \end{tabular}")
}
