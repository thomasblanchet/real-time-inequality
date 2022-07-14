// -------------------------------------------------------------------------- //
// Make graphs for presentation
// -------------------------------------------------------------------------- //

use "$work/03-decompose-components/decomposition-monthly-princ-working_age.dta", clear
merge 1:1 year month p using "$work/03-decompose-components/decomposition-monthly-peinc-working_age.dta", nogenerate assert(match)
merge 1:1 year month p using "$work/03-decompose-components/decomposition-monthly-dispo-working_age.dta", nogenerate assert(match)
merge 1:1 year month p using "$work/03-decompose-components/decomposition-monthly-poinc-working_age.dta", nogenerate assert(match)

keep if ym(year, month) >= ym(2019, 7)

merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate keepusing(nipa_deflator) keep(master match) assert(match using)

sort year month p
by year month: generate n = cond(_n == _N, 1e5 - p, p[_n + 1] - p)

generate bracket = ""
replace bracket = "Bottom 50%" if inrange(p, 00000, 49000)
replace bracket = "Middle 40%" if inrange(p, 50000, 89000)
replace bracket = "Next 9%" if inrange(p, 90000, 98000)
replace bracket = "Top 1%"  if inrange(p, 99000, 99999)

gcollapse (mean) princ-prisupgov (firstnm) nipa_deflator [pw=n], by(year month bracket)

generate time = ym(year, month)
format time %tm

foreach v of varlist princ-prisupgov {
    replace `v' = `v'/12/nipa_deflator
}

// -------------------------------------------------------------------------- //
// Bottom 50%
// -------------------------------------------------------------------------- //

keep if bracket == "Bottom 50%"

generate covidsub_min = princ
generate covidsub_max = princ + covidsub

generate uiben_min = covidsub_max
generate uiben_max = uiben_min + uiben

generate penben_min = uiben_max
generate penben_max = penben_min + penben - contrib

generate taxben_min = penben_max
generate taxben_max = taxben_min + vet + othcash - taxes - estatetax - corptax - othercontrib

generate covidrelief_min = taxben_max
generate covidrelief_max = covidrelief_min + covidrelief

generate medi_min = covidrelief_max
generate medi_max = medi_min + medicare + medicaid

generate oth_min = medi_max
generate oth_max = oth_min + otherkin + colexp

generate deficit_min = princ
generate deficit_max = princ + prisupgov - prodtax + govin
replace deficit_max = 0 if deficit_max < 0

// Start from factor national income
gr tw (con princ time, lw(medthick) col(black) msym(Oh)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "{bf:Factor national income}" "{it:(matching national income)}") ///
        order(1 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step1.pdf", replace
    
// + PPP
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "{bf:Factor national income}" "{it:(matching national income)}") ///
        order(1 2 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step2.pdf", replace

// = subsidized factor income
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(3 "{bf:Subsidized factor national income}") ///
        order(3 1 2 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step3.pdf", replace

// + UI
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (rarea uiben_min uiben_max time, col(cranberry*1.2) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    xtitle("") xsize(6) ysize(3) ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "Unemployment insurance benefits") ///
        label(3 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(4 "{bf:Subsidized factor national income}") ///
        order(2 4 1 3 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step4.pdf", replace

// + other social insurance
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (rarea uiben_min uiben_max time, col(cranberry*1.2) lw(none)) ///
    (rarea penben_min penben_max time, col(cranberry*0.8) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "Unemployment insurance benefits") ///
        label(3 "Other benefits (net)" "{it:(pensions & DI, minus contributions)}") ///
        label(4 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(5 "{bf:Subsidized factor national income}") ///
        order(3 2 5 1 4 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step5.pdf", replace

// = pretax income
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (rarea uiben_min uiben_max time, col(cranberry*1.2) lw(none)) ///
    (rarea penben_min penben_max time, col(cranberry*0.8) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)) ///
    (con penben_max time, lw(medthick) col(black) msym(Th)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "Unemployment insurance benefits") ///
        label(3 "Other benefits (net)" "{it:(pensions & DI, minus contributions)}") ///
        label(4 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(5 "{bf:Subsidized factor national income}") ///
        label(6 "{bf:Subsidized pretax national income}") ///
        order(6 3 2 5 1 4 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step6.pdf", replace

// + regular cash transfers
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (rarea uiben_min uiben_max time, col(cranberry*1.2) lw(none)) ///
    (rarea penben_min penben_max time, col(cranberry*0.8) lw(none)) ///
    (rarea taxben_min taxben_max time, col(green*0.8) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)) ///
    (con penben_max time, lw(medthick) col(black) msym(Th)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "Unemployment insurance benefits") ///
        label(3 "Other benefits (net)" "{it:(pensions & DI, minus contributions)}") ///
        label(4 "Regular cash transfers" "{it:(net of taxes)}") ///
        label(5 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(6 "{bf:Subsidized factor national income}") ///
        label(7 "{bf:Subsidized pretax national income}") ///
        order(4 7 3 2 6 1 5 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step7.pdf", replace

// + COVID relief
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (rarea uiben_min uiben_max time, col(cranberry*1.2) lw(none)) ///
    (rarea penben_min penben_max time, col(cranberry*0.8) lw(none)) ///
    (rarea taxben_min taxben_max time, col(green*0.8) lw(none)) ///
    (rarea covidrelief_min covidrelief_max time, col(green*1.2) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)) ///
    (con penben_max time, lw(medthick) col(black) msym(Th)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "Unemployment insurance benefits") ///
        label(3 "Other benefits (net)" "{it:(pensions & DI, minus contributions)}") ///
        label(4 "Regular cash transfers" "{it:(net of taxes)}") ///
        label(5 "COVID stimulus checks") ///
        label(6 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(7 "{bf:Subsidized factor national income}") ///
        label(8 "{bf:Subsidized pretax national income}") ///
        order(5 4 8 3 2 7 1 6 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step8.pdf", replace

// = post-tax disposable
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (rarea uiben_min uiben_max time, col(cranberry*1.2) lw(none)) ///
    (rarea penben_min penben_max time, col(cranberry*0.8) lw(none)) ///
    (rarea taxben_min taxben_max time, col(green*0.8) lw(none)) ///
    (rarea covidrelief_min covidrelief_max time, col(green*1.2) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)) ///
    (con penben_max time, lw(medthick) col(black) msym(Th)) ///
    (con covidrelief_max time, lw(medthick) col(black) msym(Dh)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "Unemployment insurance benefits") ///
        label(3 "Other benefits (net)" "{it:(pensions & DI, minus contributions)}") ///
        label(4 "Regular cash transfers" "{it:(net of taxes)}") ///
        label(5 "COVID stimulus checks") ///
        label(6 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(7 "{bf:Subsidized factor national income}") ///
        label(8 "{bf:Subsidized pretax national income}") ///
        label(9 "{bf:Post-tax disposable income}") ///
        order(9 5 4 8 3 2 7 1 6 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step9.pdf", replace

/*
// + medicare/medicaid
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (rarea uiben_min uiben_max time, col(cranberry*1.2) lw(none)) ///
    (rarea penben_min penben_max time, col(cranberry*0.8) lw(none)) ///
    (rarea taxben_min taxben_max time, col(green*0.8) lw(none)) ///
    (rarea covidrelief_min covidrelief_max time, col(green*1.2) lw(none)) ///
    (rarea medi_min medi_max time, col(dkorange*1.2) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)) ///
    (con penben_max time, lw(medthick) col(black) msym(Th)) ///
    (con covidrelief_max time, lw(medthick) col(black) msym(Dh)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "Unemployment insurance benefits") ///
        label(3 "Other benefits (net)" "{it:(pensions & DI, minus contributions)}") ///
        label(4 "Regular cash transfers" "{it:(net of taxes)}") ///
        label(5 "COVID stimulus checks") ///
        label(6 "Medicaid and Medicare") ///
        label(7 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(8 "{bf:Subsidized factor national income}") ///
        label(9 "{bf:Subsidized pretax national income}") ///
        label(10 "{bf:Post-tax disposable income}") ///
        order(6 10 5 4 9 3 2 8 1 7 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step10.pdf", replace


// + other spending
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (rarea uiben_min uiben_max time, col(cranberry*1.2) lw(none)) ///
    (rarea penben_min penben_max time, col(cranberry*0.8) lw(none)) ///
    (rarea taxben_min taxben_max time, col(green*0.8) lw(none)) ///
    (rarea covidrelief_min covidrelief_max time, col(green*1.2) lw(none)) ///
    (rarea medi_min medi_max time, col(dkorange*1.2) lw(none)) ///
    (rarea oth_min oth_max time, col(dkorange*0.8) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)) ///
    (con penben_max time, lw(medthick) col(black) msym(Th)) ///
    (con covidrelief_max time, lw(medthick) col(black) msym(Dh)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "Unemployment insurance benefits") ///
        label(3 "Other benefits (net)" "{it:(pensions & DI, minus contributions)}") ///
        label(4 "Regular cash transfers" "{it:(net of taxes)}") ///
        label(5 "COVID stimulus checks") ///
        label(6 "Medicaid and Medicare") ///
        label(7 "Other government spending") ///
        label(8 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(9 "{bf:Subsidized factor national income}") ///
        label(10 "{bf:Subsidized pretax national income}") ///
        label(11 "{bf:Post-tax disposable income}") ///
        order(7 6 11 5 4 10 3 2 9 1 8 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step11.pdf", replace

// - deficit
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (rarea uiben_min uiben_max time, col(cranberry*1.2) lw(none)) ///
    (rarea penben_min penben_max time, col(cranberry*0.8) lw(none)) ///
    (rarea taxben_min taxben_max time, col(green*0.8) lw(none)) ///
    (rarea covidrelief_min covidrelief_max time, col(green*1.2) lw(none)) ///
    (rarea medi_min medi_max time, col(dkorange*1.2) lw(none)) ///
    (rarea oth_min oth_max time, col(dkorange*0.8) lw(none)) ///
    (rarea deficit_min deficit_max time, col(gs12) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)) ///
    (con penben_max time, lw(medthick) col(black) msym(Th)) ///
    (con covidrelief_max time, lw(medthick) col(black) msym(Dh)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "Unemployment insurance benefits") ///
        label(3 "Other benefits (net)" "{it:(pensions & DI, minus contributions)}") ///
        label(4 "Regular cash transfers" "{it:(net of taxes)}") ///
        label(5 "COVID stimulus checks") ///
        label(6 "Medicaid and Medicare") ///
        label(7 "Other government spending") ///
        label(8 "Government deficit") ///
        label(9 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(10 "{bf:Subsidized factor national income}") ///
        label(11 "{bf:Subsidized pretax national income}") ///
        label(12 "{bf:Post-tax disposable income}") ///
        order(8 7 6 12 5 4 11 3 2 10 1 9 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step12.pdf", replace

// = post-tax national
gr tw (rarea covidsub_min covidsub_max time, col(ebblue) lw(none)) ///
    (rarea uiben_min uiben_max time, col(cranberry*1.2) lw(none)) ///
    (rarea penben_min penben_max time, col(cranberry*0.8) lw(none)) ///
    (rarea taxben_min taxben_max time, col(green*0.8) lw(none)) ///
    (rarea covidrelief_min covidrelief_max time, col(green*1.2) lw(none)) ///
    (rarea medi_min medi_max time, col(dkorange*1.2) lw(none)) ///
    (rarea oth_min oth_max time, col(dkorange*0.8) lw(none)) ///
    (rarea deficit_min deficit_max time, col(gs12) lw(none)) ///
    (con princ time, lw(medthick) col(black) msym(Oh)) ///
    (con covidsub_max time, lw(medthick) col(black) msym(Sh)) ///
    (con penben_max time, lw(medthick) col(black) msym(Th)) ///
    (con covidrelief_max time, lw(medthick) col(black) msym(Dh)) ///
    (con poinc time, lw(medthick) col(black) msym(O)), ///
    ylabel(, format(%9.0gc)) ytitle("Monthly income per adult (constant USD)") ///
    yscale(range(0 4200)) ylabel(0(500)4000) ///
    xtitle("") xsize(6) ysize(3) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(pos(4) cols(1) region(margin(0 0 10 0)) ///
        label(1 "Paycheck Protection Program") ///
        label(2 "Unemployment insurance benefits") ///
        label(3 "Other benefits (net)" "{it:(pensions & DI, minus contributions)}") ///
        label(4 "Regular cash transfers" "{it:(net of taxes)}") ///
        label(5 "COVID stimulus checks") ///
        label(6 "Medicaid and Medicare") ///
        label(7 "Other government spending") ///
        label(8 "Government deficit") ///
        label(9 "{bf:Factor national income}" "{it:(matching national income)}") ///
        label(10 "{bf:Subsidized factor national income}") ///
        label(11 "{bf:Subsidized pretax national income}") ///
        label(12 "{bf:Post-tax disposable income}") ///
        label(13 "{bf:Post-tax national income}" "{it:(matching national income)}") ///
        order(13 8 7 6 12 5 4 11 3 2 10 1 9 - "{dup 60: }") ///
    )
graph export "$graphs/04-plot-covid/presentation-bot50-step13.pdf", replace
*/

// -------------------------------------------------------------------------- //
// Compare evolution of averages
// -------------------------------------------------------------------------- //

use "$work/03-decompose-components/decomposition-monthly-princ-adult.dta", clear
merge 1:1 year month p using "$work/03-decompose-components/decomposition-monthly-peinc-adult.dta", nogenerate //assert(match)
merge 1:1 year month p using "$work/03-decompose-components/decomposition-monthly-dispo-adult.dta", nogenerate //assert(match)
merge 1:1 year month p using "$work/03-decompose-components/decomposition-monthly-poinc-adult.dta", nogenerate //assert(match)
merge 1:1 year month p using "$work/03-decompose-components/decomposition-monthly-hweal-adult.dta", nogenerate //assert(match)

keep if inrange(ym(year, month), ym(2019, 7), ym(2022, 03))

merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate keepusing(nipa_deflator) keep(master match) assert(match using)

sort year month p
by year month: generate n = cond(_n == _N, 1e5 - p, p[_n + 1] - p)

generate bracket = ""
replace bracket = "Bottom 50%" if inrange(p, 00000, 49000)
replace bracket = "Middle 40%" if inrange(p, 50000, 89000)
replace bracket = "Next 9%" if inrange(p, 90000, 98000)
replace bracket = "Top 1%"  if inrange(p, 99000, 99999)

gcollapse (mean) princ dispo hweal (firstnm) nipa_deflator [pw=n], by(year month bracket)

generate time = ym(year, month)
format time %tm

foreach v of varlist princ dispo hweal {
    replace `v' = `v'/12/nipa_deflator
}

sort bracket time

foreach v of varlist princ dispo hweal {
    by bracket: generate `v'0 = `v'[1]
    by bracket: replace `v' = 100*`v'/`v'0
}

keep if time <= ym(2022, 03)

gr tw (con princ time if bracket == "Bottom 50%", lw(medthick) msym(Oh) col(ebblue)) ///
    (con princ time if bracket == "Middle 40%", lw(medthick) msym(Sh) col(cranberry)) ///
    (con princ time if bracket == "Next 9%", lw(medthick) msym(Th) col(green)) ///
    (con princ time if bracket == "Top 1%", lw(medthick) msym(Dh) col(dkorange)), ///
    ytitle("Average income per adult (constant)" "07/2019 = 100") ///
    xtitle("") xsize(6) ysize(4) scale(1.2) ///
    legend(ring(0) bplacement(5) cols(1) ///
        label(1 "Bottom 50%") ///
        label(2 "Middle 40%") ///
        label(3 "Next 9%") ///
        label(4 "Top 1%") ///
        order(4 3 2 1) ///
    )
graph export "$graphs/04-plot-covid/presentation-evolution-princ.pdf", replace

gr tw (con dispo time if bracket == "Bottom 50%", lw(medthick) msym(Oh) col(ebblue)) ///
    (con dispo time if bracket == "Middle 40%", lw(medthick) msym(Sh) col(cranberry)) ///
    (con dispo time if bracket == "Next 9%", lw(medthick) msym(Th) col(green)) ///
    (con dispo time if bracket == "Top 1%", lw(medthick) msym(Dh) col(dkorange)), ///
    ytitle("Average income per adult (constant)" "07/2019 = 100") ///
    xtitle("") xsize(6) ysize(4) scale(1.2) ///
    legend(pos(6) rows(1) ///
        label(1 "Bottom 50%") ///
        label(2 "Middle 40%") ///
        label(3 "Next 9%") ///
        label(4 "Top 1%") ///
        order(4 3 2 1) ///
    )
graph export "$graphs/04-plot-covid/presentation-evolution-dispo.pdf", replace

gr tw (con hweal time if bracket == "Bottom 50%", lw(medthick) msym(Oh) col(ebblue)) ///
    (con hweal time if bracket == "Middle 40%", lw(medthick) msym(Sh) col(cranberry)) ///
    (con hweal time if bracket == "Next 9%", lw(medthick) msym(Th) col(green)) ///
    (con hweal time if bracket == "Top 1%", lw(medthick) msym(Dh) col(dkorange)), ///
    ytitle("Average wealth per adult (constant)" "07/2019 = 100") ///
    xtitle("") xsize(6) ysize(4) scale(1.2) ///
    legend(ring(0) bplacement(5) cols(1) ///
        label(1 "Bottom 50%") ///
        label(2 "Middle 40%") ///
        label(3 "Next 9%") ///
        label(4 "Top 1%") ///
        order(4 3 2 1) ///
    )
graph export "$graphs/04-plot-covid/presentation-evolution-hweal.pdf", replace

// -------------------------------------------------------------------------- //
// Compare evolution of averages
// -------------------------------------------------------------------------- //

use "$work/03-decompose-components/decomposition-monthly-hweal-adult.dta", clear

keep if ym(year, month) >= ym(2019, 7)

merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate keepusing(nipa_deflator) keep(master match) assert(match using)

sort year month p
by year month: generate n = cond(_n == _N, 1e5 - p, p[_n + 1] - p)

generate bracket = ""
replace bracket = "bot50" if inrange(p, 00000, 49000)
replace bracket = "mid40" if inrange(p, 50000, 89000)
replace bracket = "top10" if inrange(p, 90000, 98000)
replace bracket = "top1"  if inrange(p, 99000, 99800)
replace bracket = "top01" if inrange(p, 99900, 99999)

gcollapse (sum) hweal (mean) nipa_deflator [pw=n], by(year month bracket)

generate time = ym(year, month)
format time %tm

foreach v of varlist hweal {
    replace `v' = `v'/nipa_deflator
}

reshape wide hweal, i(time year month) j(bracket) string

replace hwealtop1 = hwealtop1 + hwealtop01
replace hwealtop10 = hwealtop10 + hwealtop1

sort time

// Add real-time estimate, taken directly from website
count
set obs `=r(N) + 1'
replace year = 2022 if _n == _N
replace month = 6 if _n == _N
replace time = ym(year, month) if _n == _N
replace hwealmid40 = hwealmid40[_n - 1]*(124.5/125.3) if _n == _N
replace hwealtop10 = hwealtop10[_n - 1]*(120.7/126.2) if _n == _N
replace hwealtop1 = hwealtop1[_n - 1]*(121.1/128.9) if _n == _N
replace hwealtop01 = hwealtop01[_n - 1]*(119.7/130.0) if _n == _N

foreach v of varlist hweal* {
    generate `v'ini = `v'[1]
    replace `v' = 100*`v'/`v'ini
}

gr tw (con hwealmid40 time if ym(year, month) <= ym(2022, 05), lw(medthick) msym(Oh) col(ebblue)) ///
    (con hwealtop10 time if ym(year, month) <= ym(2022, 05), lw(medthick) msym(Sh) col(cranberry)) ///
    (con hwealtop1 time if ym(year, month) <= ym(2022, 05), lw(medthick) msym(Th) col(green)) ///
    (con hwealtop01 time if ym(year, month) <= ym(2022, 05), lw(medthick) msym(Dh) col(dkorange)) ///
    ///
    (con hwealmid40 time if ym(year, month) >= ym(2022, 05), lw(medthick) lp(shortdash) msym(Oh) col(ebblue)) ///
    (con hwealtop10 time if ym(year, month) >= ym(2022, 05), lw(medthick) lp(shortdash) msym(Sh) col(cranberry)) ///
    (con hwealtop1 time if ym(year, month) >= ym(2022, 05), lw(medthick) lp(shortdash) msym(Th) col(green)) ///
    (con hwealtop01 time if ym(year, month) >= ym(2022, 05), lw(medthick) lp(shortdash) msym(Dh) col(dkorange)), ///
    ///
    ytitle("Average wealth per adult (constant USD)" "07/2019 = 100") ///
    xtitle("") xsize(6) ysize(4) scale(1.2) xscale(range(`=ym(2019, 7)' `=ym(2022, 8)')) xlabel(`=ym(2019, 7)'(6)`=ym(2022, 8)') ///
    legend(ring(0) bplacement(5) cols(1) ///
        label(1 "Middle 40%") ///
        label(2 "Top 10%") ///
        label(3 "Top 1%") ///
        label(4 "Top 0.1%") ///
        order(4 3 2 1) ///
    )
graph export "$graphs/04-plot-covid/presentation-evolution-hweal.pdf", replace
