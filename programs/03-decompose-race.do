// -------------------------------------------------------------------------- //
// Decompose income by race
// -------------------------------------------------------------------------- //

clear
save "$work/03-decompose-race/decomposition-monthly-race.dta", replace emptyok

global date_begin = ym(1989, 01)
global date_end   = ym(2022, 04)

quietly {
    foreach income in peinc wage pkinc hweal {
        foreach t of numlist $date_begin / $date_end {
            noisily di "* " %tm = `t' ", `income'"
            
            local year = year(dofm(`t'))
            local month = month(dofm(`t'))
            
            // Calculate additional incomes if necessary
            if ("`income'" == "peinc") {
                use id weight race peinc using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
            }
            else if ("`income'" == "wage") {
                use id weight age race flemp proprietors if age < 65 using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
            
                generate wage = flemp + 0.7*proprietors
            }
            else if ("`income'" == "pkinc") {
                use id weight race proprietors rental corptax profits fkfix fknmo prodtax prodsub govin covidsub ///
                    surplus using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
                
                generate pkinc = 0.3*proprietors + rental + corptax + profits + fkfix - fknmo
            }
            else if ("`income'" == "hweal") {
                use id weight race hweal using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
            }
            
            // Equal-split
            gegen `income' = mean(`income'), by(id) replace
            
            // Generate groups by race
            hashsort race `income'
            by race: generate rank = sum(weight)
            by race: replace rank = 1e5*(rank - weight/2)/rank[_N]
            
            egen p = cut(rank), at(0(1000)99000 999999)
            
            gcollapse (mean) average=`income' [pw=weight], by(race p)
            generate year = `year'
            generate month = `month'
            generate type = "`income'"
            
            append using "$work/03-decompose-race/decomposition-monthly-race.dta"
            save "$work/03-decompose-race/decomposition-monthly-race.dta", replace
        }
    }
}

// -------------------------------------------------------------------------- //
// Plot Black/White gap
// -------------------------------------------------------------------------- //

use "$work/03-decompose-race/decomposition-monthly-race.dta", clear

generate time = ym(year, month)
format time %tm

sort time type race p
by time type race: generate n = cond(_n == _N, 1e5 - p, p[_n + 1] - p)

gcollapse (mean) average [pw=n], by(year month time race type)

generate quarter = quarter(dofm(time))

gcollapse (mean) average, by(year quarter race type)
generate time = yq(year, quarter)
format time %tq

greshape wide average, i(year quarter time type) j(race)

generate gap = 100*average2/average1

gr tw (line gap time if type == "wage", lw(medthick) col(ebblue)), ///
    yscale(range(0 100)) ylabel(0(10)100) xtitle("") ytitle("Black average / White average (%)") ///
    legend(off) xlabel(`=yq(1990, 1)'(20)`=yq(2020, 1)') scale(1.1) ///
    text(68 `=yq(2003, 1)' "Labor income (working-age population)", col(ebblue) size(small))
graph export "$graphs/03-decompose-race/black-white-gaps-1.pdf", replace

gr tw (line gap time if type == "wage", lw(medthick) col(ebblue)) ///
    (line gap time if type == "hweal", lw(medthick) col(purple)), ///
    yscale(range(0 100)) ylabel(0(10)100) xtitle("") ytitle("Black average / White average (%)") ///
    legend(off) xlabel(`=yq(1990, 1)'(20)`=yq(2020, 1)') scale(1.1) ///
    text(68 `=yq(2003, 1)' "Labor income (working-age population)", col(ebblue) size(small)) ///
    text(30 `=yq(2000, 1)' "Wealth", col(purple) size(small))
graph export "$graphs/03-decompose-race/black-white-gaps-2.pdf", replace

gr tw (line gap time if type == "wage", lw(medthick) col(ebblue)) ///
    (line gap time if type == "hweal", lw(medthick) col(purple)) ///
    (line gap time if type == "pkinc", lw(medthick) col(orange)), ///
    yscale(range(0 100)) ylabel(0(10)100) xtitle("") ytitle("Black average / White average (%)") ///
    legend(off) xlabel(`=yq(1990, 1)'(20)`=yq(2020, 1)') scale(1.1) ///
    text(68 `=yq(2003, 1)' "Labor income (working-age population)", col(ebblue) size(small)) ///
    text(19 `=yq(1996, 1)' "Pretax capital income", col(orange) size(small)) ///
    text(30 `=yq(2000, 1)' "Wealth", col(purple) size(small))
graph export "$graphs/03-decompose-race/black-white-gaps-3.pdf", replace

gr tw (line gap time if type == "wage", lw(medthick) col(ebblue)) ///
    (line gap time if type == "peinc", lw(medthick) col(cranberry)) ///
    (line gap time if type == "hweal", lw(medthick) col(purple)) ///
    (line gap time if type == "pkinc", lw(medthick) col(orange)), ///
    yscale(range(0 100)) ylabel(0(10)100) xtitle("") ytitle("Black average / White average (%)") ///
    legend(off) xlabel(`=yq(1990, 1)'(20)`=yq(2020, 1)') scale(1.1) ///
    text(68 `=yq(2003, 1)' "Labor income (working-age population)", col(ebblue) size(small)) ///
    text(47 `=yq(2006, 1)' "Pretax income", col(cranberry) size(small)) ///
    text(19 `=yq(1996, 1)' "Pretax capital income", col(orange) size(small)) ///
    text(30 `=yq(2000, 1)' "Wealth", col(purple) size(small))
graph export "$graphs/03-decompose-race/black-white-gaps-4.pdf", replace

// -------------------------------------------------------------------------- //
// Plot overall average dureing recessions
// -------------------------------------------------------------------------- //

use "$work/03-decompose-race/decomposition-monthly-race.dta", clear

keep if type == "peinc"

sort race type year month p
by race type year month: generate n = cond(_n == _N, 1e5 - p, p[_n + 1] - p)

// Aggregate to have overall average
gcollapse (mean) peinc=average [pw=n], by(race year month)

// Correct for inflation
merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate keep(match) keepusing(nipa_deflator)
replace peinc = peinc/nipa_deflator

// Aggregate by quarters
generate time = yq(year, quarter(dofm(ym(year, month))))
format time %tq
gcollapse (mean) peinc, by(race time)

generate quarter = quarter(dofq(time))
generate year = year(dofq(time))

// Overall average
/*
gr tw (con peinc time if race == 1, lw(medthick) col(ebblue) msym(i) msize(small)) ///
    (con peinc time if race == 2, lw(medthick) col(cranberry) msym(i) msize(small)) ///
    (con peinc time if race == 3, lw(medthick) col(green) msym(i) msize(small)), ///
    xtitle("") ytitle("Pretax income, working-age population" "(constant USD)") ylabel(0(1e4)1e5, format(%9.0gc)) ///
    legend(rows(1) label(1 "Non-hispanic whites") label(2 "Blacks") label(3 "Hispanics")) ///
    title("Average Pretax Income") subtitle("by race and ethnicity")
graph export "$graphs/03-decompose-race/avg-peinc-race.pdf", replace
*/

// Make into and index (base 2006)
sort race time
gegen ref = mean(peinc) if year == 2007, by(race)
gegen ref = max(ref), by(race) replace
generate peinc_base2006 = 100*peinc/ref
drop ref

// Index since 2006
/*
gr tw (con peinc_base2006 time if race == 1, lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (con peinc_base2006 time if race == 2, lw(medthick) col(cranberry) msym(Sh) msize(small)) ///
    (con peinc_base2006 time if race == 3, lw(medthick) col(green) msym(Dh) msize(small)), ///
    xtitle("") xlabel(184(8)247) ytitle("Pretax income, working-age population" "constant USD, 2007 = 100") ylabel(85(5)125) ///
    legend(rows(1) label(1 "Non-hispanic whites") label(2 "Blacks") label(3 "Hispanics"))
graph export "$graphs/03-decompose-race/index-peinc-race.pdf", replace
*/

// During the last two recessions/recoveries
generate cycle = ""
replace cycle = "Great Recession (2007-2016)" if inrange(year(dofq(time)), 2007, 2016)
replace cycle = "COVID Recession (2020-2022)" if inrange(year(dofq(time)), 2020, 2022)
drop if cycle == ""

sort race cycle time
by race cycle: generate ref = cond(cycle == "Great Recession (2007-2016)", peinc[1], peinc[1])
generate peinc_cycles = 100*peinc/ref

// Over the two last recessions
gr tw (con peinc_cycles time if race == 1, lw(medthick) col(ebblue) msym(Oh) msize(small)) ///
    (con peinc_cycles time if race == 2, lw(medthick) col(cranberry) msym(Sh) msize(small)) ///
    (con peinc_cycles time if race == 3, lw(medthick) col(green) msym(Dh) msize(small)), ///
    by(cycle, xrescale /*title("Average Pretax Income") subtitle("By Race and Ethnicity")*/ note("") scale(1.3) imargin(0 10 0 0)) ///
    xtitle("") ytitle("Pretax income" "(constant USD, pre-recession peak = 100)") ylabel(90(5)110) xlabel(, labsize(small)) ysize(3) xsize(6) ///
    legend(rows(1) label(1 "Non-hispanic whites") label(2 "Blacks") label(3 "Hispanics"))
graph export "$graphs/03-decompose-race/index-peinc-race-cycles.pdf", replace


// -------------------------------------------------------------------------- //
// Black/white representation
// -------------------------------------------------------------------------- //

clear
save "$work/03-decompose-race/black-white-representation.dta", emptyok replace

global date_begin = ym(1989, 01)
global date_end   = ym(2022, 04)

foreach v in flemp peinc hweal {
    foreach t of numlist $date_begin / $date_end {
        quietly {
            noisily di "* " %tm = `t' ", `v'"
            
            local year = year(dofm(`t'))
            local month = month(dofm(`t'))
            
            use id weight race `v' using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
            
            if ("`v'" == "flemp") {
                drop if `v' < 0
            }
        
            sort `v'
            generate rank = sum(weight)
            replace rank = (rank - weight/2)/rank[_N]
            
            generate bracket = ""
            replace bracket = "_bot90" if inrange(rank, 0, 0.90)
            replace bracket = "_top10" if inrange(rank, 0.90, 1)
            
            generate black = cond(race == 2, 1, 0)
            generate white = cond(race == 1, 1, 0)
            generate other = !black & !white
            
            gcollapse (mean) black white other [pw=weight], by(bracket)
            generate concept = "`v'"
            generate year = `year'
            generate month = `month'
            
            append using "$work/03-decompose-race/black-white-representation.dta"
            save "$work/03-decompose-race/black-white-representation.dta", replace
        }
    }
}

use "$work/03-decompose-race/black-white-representation.dta", clear

reshape wide black white other, i(year month concept) j(bracket) string

foreach v in black white other {
    generate `v'_total = 0.9*`v'_bot90 + 0.1*`v'_top10
    
    foreach grp in bot90 top10 total {
        replace `v'_`grp' = 100*`v'_`grp'
    }
}

generate quarter = quarter(dofm(ym(year, month)))

collapse (mean) black_top10 black_total, by(year quarter concept)

generate time = yq(year, quarter)
format time %tq

gr tw (line black_top10 time if concept == "flemp" & year >= 1989, col(ebblue) lw(medthick) msize(small) msym(Sh)) ///
    (line black_top10 time if concept == "peinc" & year >= 1989, col(cranberry) lw(medthick) msize(small) msym(Oh)) ///
    (line black_top10 black_total time if concept == "hweal" & year >= 1989, col(dkgreen black) lw(medthick..) msize(small..) msym(Dh O)), ///
    yscale(range(0 12)) ylabel(0(2)12) ytitle("Share of black population (%)") ///
    xlabel(`=yq(1989, 01)'(24)`=yq(2022, 01)') xtitle("") legend(off) ///
    text(11 `=yq(2000, 02)' "Full population", col(black) size(small)) ///
    text(7.0 `=yq(2000, 02)' "Top 10% wage earners", col(ebblue) size(small)) ///
    text(4.5 `=yq(1994, 02)' "Top 10% pretax income", col(cranberry) size(small)) ///
    text(3.6 `=yq(2007, 02)' "Top 10% wealth", col(dkgreen) size(small))
graph export "$graphs/03-decompose-race/black-white-gap-top10.pdf", replace


