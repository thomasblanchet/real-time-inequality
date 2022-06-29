// -------------------------------------------------------------------------- //
// Plot the evolution of race gaps
// -------------------------------------------------------------------------- //

global date_begin = ym(2006, 01)
global date_end   = ym(2022, 04)

// -------------------------------------------------------------------------- //
// Estimate income by bracket and race
// -------------------------------------------------------------------------- //

clear
save "$work/04-plot-gender-gaps/peinc-bracket-gender.dta", replace emptyok

foreach t of numlist $date_begin / $date_end {
    
    local year = year(dofm(`t'))
    local month = month(dofm(`t'))
    
    di "-> `year'm`month'"
    
    
    quietly {
        use "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
        
        // Calculate ranks
        sort sex peinc
        by sex: generate rank = sum(weight)
        by sex: replace rank = (rank - weight/2)/rank[_N]
        
        // Calculate groups
        generate bracket = ""
        
        replace bracket = "bot50" if inrange(rank, 0.00, 0.50)
        replace bracket = "mid40" if inrange(rank, 0.50, 0.90)
        replace bracket = "top10"  if inrange(rank, 0.90, 1.00)
        
        // Aggregate by race/bracket
        gcollapse (mean) peinc [pw=weight], by(year month sex bracket)
        
        // Save
        append using "$work/04-plot-gender-gaps/peinc-bracket-gender.dta"
        save "$work/04-plot-gender-gaps/peinc-bracket-gender.dta", replace
    }
}

// -------------------------------------------------------------------------- //
// Plot overall average
// -------------------------------------------------------------------------- //

use "$work/04-plot-gender-gaps/peinc-bracket-gender.dta", clear

// Aggregate to have overall average
generate pop = 0.5 if bracket == "bot50"
replace pop = 0.40 if bracket == "mid40"
replace pop = 0.10 if bracket == "top10"
gcollapse (mean) peinc [pw=pop], by(sex year month)

// Correct for inflation
merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate keep(match) keepusing(nipa_deflator)
replace peinc = peinc/nipa_deflator

generate quarter = quarter(dofm(ym(year, month)))
collapse (mean) peinc, by(year quarter sex)

generate time = yq(year, quarter)
format time %tq

// Overall average
gr tw (line peinc time if sex == 1, lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (line peinc time if sex == 2, lw(medthick) col(cranberry) msym(Sh) msize(small)), ///
    xtitle("") ytitle("Annualized pretax income" "(constant 2021 USD)") ylabel(0(1e4)1e5, format(%9.0gc)) ///
    legend(rows(1) label(1 "Males") label(2 "Females")) ///
    title("Average Pretax Income") subtitle("by gender")
graph export "$graphs/04-plot-gender-gaps/avg-peinc-gender.pdf", replace

// Make into and index (base 2006)
sort sex time
by sex: generate ref = peinc[1]
generate peinc_base2006 = 100*peinc/ref
drop ref

// Index since 2006
gr tw (line peinc_base2006 time if sex == 1, lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (line peinc_base2006 time if sex == 2, lw(medthick) col(cranberry) msym(Sh) msize(small)), ///
    xtitle("") ytitle("Pretax income" "(constant USD, 2006 = 100)") ylabel(90(5)120) ///
    legend(rows(1) label(1 "Males") label(2 "Females")) ///
    title("Average Pretax Income") subtitle("by gender")
graph export "$graphs/04-plot-gender-gaps/index-peinc-gender.pdf", replace

// During the last two recessions/recoveries
generate cycle = ""
replace cycle = "Great Recession (2007-2016)" if inrange(year(dofq(time)), 2007, 2016)
replace cycle = "Covid Recession (2020-2021)" if inrange(year(dofq(time)), 2020, 2021)
drop if cycle == ""

sort sex cycle time
by sex cycle: generate ref = cond(cycle == "Great Recession (2007-2016)", peinc[4], peinc[1])
generate peinc_cycles = 100*peinc/ref

// Over the two last recessions
gr tw (con peinc_cycles time if sex == 1, lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (con peinc_cycles time if sex == 2, lw(medthick) col(cranberry) msym(Sh) msize(small)), ///
    by(cycle, xrescale /*title("Average Pretax Income") subtitle("by gender")*/ note("") scale(1.3) imargin(0 10 0 0)) ///
    xtitle("") ytitle("Pretax income" "(constant USD, pre-recession peak = 100)") /*ylabel(85(5)105)*/ xlabel(, labsize(small)) ///
    legend(rows(1) label(1 "Men") label(2 "Women")) ysize(3) xsize(6) 
graph export "$graphs/04-plot-gender-gaps/index-peinc-gender-cycles.pdf", replace

// -------------------------------------------------------------------------- //
// Plot bottom 50% & top 10%
// -------------------------------------------------------------------------- //

use "$work/peinc-bracket-gender.dta", clear

// Correct for inflation
merge n:1 year month using "$work/nipa-simplified-monthly.dta", nogenerate keep(match) keepusing(nipa_deflator)
replace peinc = peinc/nipa_deflator

generate time = ym(year, month)
format time %tm

// Average by race and bracket
gr tw (line peinc time if sex == 1 & bracket == "bot50", lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (line peinc time if sex == 2 & bracket == "bot50", lw(medthick) col(cranberry) msym(Sh) msize(small)), ///
    xtitle("") ytitle("Annualized pretax income" "(constant 2021 USD)") ylabel(0(5e3)2.5e4, format(%9.0gc)) ///
    legend(rows(1) label(1 "Males") label(2 "Females")) ///
    title("Average Pretax Income") subtitle("by gender, bottom 50%")
graph export "$graphs/04-plot-gender-gaps/bot50-peinc-gender.pdf", replace

gr tw (line peinc time if sex == 1 & bracket == "top10", lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (line peinc time if sex == 2 & bracket == "top10", lw(medthick) col(cranberry) msym(Sh) msize(small)), ///
    xtitle("") ytitle("Annualized pretax income" "(constant 2021 USD)") ylabel(0(5e4)5e5, format(%9.0gc)) ///
    legend(rows(1) label(1 "Males") label(2 "Females")) ///
    title("Average Pretax Income") subtitle("by gender, top 10%")
graph export "$graphs/04-plot-gender-gaps/top10-peinc-gender.pdf", replace

// Make into and index (base 2006)
sort bracket sex time
by bracket sex: generate ref = (peinc[1] + peinc[2] + peinc[3] + peinc[4])/4
generate peinc_base2006 = 100*peinc/ref
drop ref

// Index since 2006
gr tw (line peinc_base2006 time if sex == 1 & bracket == "bot50", lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (line peinc_base2006 time if sex == 2 & bracket == "bot50", lw(medthick) col(cranberry) msym(Sh) msize(small)), ///
    xtitle("") ytitle("Pretax income" "(constant USD, 2006 = 100)") ylabel(85(5)140) ///
    legend(rows(1) label(1 "Males") label(2 "Females")) ///
    title("Average Pretax Income") subtitle("by gender, bottom 50%")
graph export "$graphs/04-plot-gender-gaps/index-bot50-peinc-gender.pdf", replace

gr tw (line peinc_base2006 time if sex == 1 & bracket == "top10", lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (line peinc_base2006 time if sex == 2 & bracket == "top10", lw(medthick) col(cranberry) msym(Sh) msize(small)), ///
    xtitle("") ytitle("Pretax income" "(constant USD, 2006 = 100)") ylabel(85(5)125) ///
    legend(rows(1) label(1 "Males") label(2 "Females")) ///
    title("Average Pretax Income") subtitle("by gender, top 10%")
graph export "$graphs/04-plot-gender-gaps/index-top10-peinc-gender.pdf", replace

// During the last two recessions/recoveries
generate cycle = ""
replace cycle = "Great Recession (2007-2016)" if inrange(year(dofm(time)), 2007, 2016)
replace cycle = "COVID Recession (2020-2021)" if inrange(year(dofm(time)), 2020, 2022)
drop if cycle == ""

sort bracket sex cycle time
by bracket sex cycle: generate ref = cond(cycle == "Great Recession (2007-2016)", ///
    (peinc[10] + peinc[11] + peinc[12])/3, (peinc[1] + peinc[2])/2)
generate peinc_cycles = 100*peinc/ref

// Over the two last recessions
gr tw (line peinc_cycles time if sex == 1 & bracket == "bot50", lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (line peinc_cycles time if sex == 2 & bracket == "bot50", lw(medthick) col(cranberry) msym(Sh) msize(small)), ///
    by(cycle, xrescale title("Average Pretax Income") subtitle("by gender, bottom 50%") note("")) ///
    xtitle("") ytitle("Pretax income" "(constant USD, pre-recession peak = 100)") ylabel(75(5)110) ///
    legend(rows(1) label(1 "Males") label(2 "Females"))
graph export "$graphs/04-plot-gender-gaps/index-bot50-peinc-gender-cycles.pdf", replace

// Over the two last recessions
gr tw (line peinc_cycles time if sex == 1 & bracket == "top10", lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (line peinc_cycles time if sex == 2 & bracket == "top10", lw(medthick) col(cranberry) msym(Sh) msize(small)), ///
    by(cycle, xrescale title("Average Pretax Income") subtitle("by gender, top 10%") note("")) ///
    xtitle("") ytitle("Pretax income" "(constant USD, pre-recession peak = 100)") ylabel(80(5)110) ///
    legend(rows(1) label(1 "Males") label(2 "Females"))
graph export "$graphs/04-plot-gender-gaps/index-top10-peinc-gender-cycles.pdf", replace

