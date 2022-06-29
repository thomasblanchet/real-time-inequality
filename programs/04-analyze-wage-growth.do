// -------------------------------------------------------------------------- //
// Analyse the evolution of wage growth during the last two recessions
// -------------------------------------------------------------------------- //

// Total nonfarm employment directly from FRED
import fred PAYEMS, clear

generate year = year(daten)
generate month = month(daten)
generate nonfarm_emp = 1000*PAYEMS
keep year month nonfarm_emp
keep if year >= 2006
merge 1:1 year month using "$work/02-prepare-pop/pop-data-monthly.dta", ///
    keep(match) keepusing(monthly_working_age) nogenerate
generate emprate = 100*nonfarm_emp/monthly_working_age

gen time = ym(year, month)
format time %tm

// Local critical dates
global pre2008_peak = ym(2007, 12)
global post2008_recov = ym(2017, 05)

global preCOVID_peak = ym(2018, 07)
global postCOVID_recov = ym(2022, 02)

gr tw (line emprate time, lw(medthick) col(ebblue)) if time >= ym(2019, 1), scale(1.2) ///
    legend(off) ytitle("Employment to working-age population ratio (%)") ///
    xtitle("") xlabel(`=ym(2019, 1)'(12)`=ym(2022, 1)')
graph export "$graphs/04-analyze-wage-growth/employment-1.pdf", replace

gr tw (line emprate time, lw(medthick) col(ebblue)) (sc emprate time if inlist(time, $pre2008_peak), col(cranberry)), ///
    legend(off) ytitle("Employment to working-age population ratio (%)") ///
    xtitle("") xlabel(`=ym(2006, 1)'(48)`=ym(2022, 1)') ///
    text(77 `=$pre2008_peak + 4' "Great recession" "begins" "in 12/2007", placement(right) justification(left))
graph export "$graphs/04-analyze-wage-growth/employment-2.pdf", replace

gr tw (line emprate time, lw(medthick) col(ebblue)) (sc emprate time if inlist(time, $pre2008_peak), col(cranberry)) ///
    (pcarrowi 76.1 `=$pre2008_peak + 4' 76.1 `=$post2008_recov - 4', lw(medthick) col(black)), ///
    legend(off) ytitle("Employment to working-age population ratio (%)") ///
    xtitle("") xlabel(`=ym(2006, 1)'(48)`=ym(2022, 1)') ///
    text(77 `=$pre2008_peak + 4' "Great recession" "begins" "in 12/2007", placement(right) justification(left)) ///
    text(76 `=($post2008_recov + $pre2008_peak)/2' "9 years and 5 months", placement(bottom) justification(right))
graph export "$graphs/04-analyze-wage-growth/employment-3.pdf", replace
    
gr tw (line emprate time, lw(medthick) col(ebblue)) (sc emprate time if inlist(time, $pre2008_peak, $post2008_recov), col(cranberry)) ///
    (pcarrowi 76.1 `=$pre2008_peak + 4' 76.1 `=$post2008_recov - 4', lw(medthick) col(black)), ///
    legend(off) ytitle("Employment to working-age population ratio (%)") ///
    xtitle("") xlabel(`=ym(2006, 1)'(48)`=ym(2022, 1)') ///
    text(77 `=$pre2008_peak + 4' "Great recession" "begins" "in 12/2007", placement(right) justification(left)) ///
    text(77 `=$post2008_recov - 4' "Pre-recession level" "reached again" "in 07/2017", placement(left) justification(right)) ///
    text(76 `=($post2008_recov + $pre2008_peak)/2' "9 years and 5 months", placement(bottom) justification(right))
graph export "$graphs/04-analyze-wage-growth/employment-4.pdf", replace
    
gr tw (line emprate time, lw(medthick) col(ebblue)) (sc emprate time if inlist(time, $pre2008_peak, $post2008_recov, $preCOVID_peak, $postCOVID_recov), col(cranberry)) ///
    (pcarrowi 76.1 `=$pre2008_peak + 4' 76.1 `=$post2008_recov - 4', lw(medthick) col(black)) ///
    (pcarrowi 77.4 `=$preCOVID_peak + 3' 77.4 `=$postCOVID_recov - 3', lw(medthick) col(black)), ///
    legend(off) ytitle("Employment to working-age population ratio (%)") ///
    xtitle("") xlabel(`=ym(2006, 1)'(48)`=ym(2022, 1)') ///
    text(77.0 `=$pre2008_peak + 4' "Great recession" "begins" "in 12/2007", placement(right) justification(left)) ///
    text(77.0 `=$post2008_recov - 4' "Pre-recession level" "reached again" "in 07/2017", placement(left) justification(right)) ///
    text(76.0 `=($post2008_recov + $pre2008_peak)/2' "9 years and 5 months", placement(bottom) justification(right)) ///
    text(77.3 `=$preCOVID_peak + 2' "07/18", placement(se)) ///
    text(77.6 `=$postCOVID_recov - 2' "02/22", placement(nw))
graph export "$graphs/04-analyze-wage-growth/employment-5.pdf", replace

// -------------------------------------------------------------------------- //
// Get wage quartiles based on microdata
// -------------------------------------------------------------------------- //

clear
save "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta", replace emptyok

global date_begin = ym(1998, 01)
global date_end   = ym(2022, 04)

quietly {
    foreach t of numlist $date_begin / $date_end {
        noisily di "* " %tm = `t'
        
        local year = year(dofm(`t'))
        local month = month(dofm(`t'))
        
        // ------------------------------------------------------------------ //
        // All working-age adults
        // ------------------------------------------------------------------ //

        use id weight age flemp proprietors if age < 65 using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
        // Calculate wage income
        generate wage = flemp + 0.7*proprietors
        // Employment dummy
        generate employed = (wage > 0)
        // Get ranks
        sort wage
        generate rank = sum(weight)
        replace rank = (rank - weight/2)/rank[_N]
        // Get quartiles
        generate quartile = .
        replace quartile = 1 if inrange(rank, 0.00, 0.25)
        replace quartile = 2 if inrange(rank, 0.25, 0.50)
        replace quartile = 3 if inrange(rank, 0.50, 0.75)
        replace quartile = 4 if inrange(rank, 0.75, 1.00)
        // Aggregate
        gcollapse (mean) wage employed (rawsum) pop=weight [pw=weight], by(quartile)
        generate year = `year'
        generate month = `month'
        append using "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta"
        save "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta", replace
        
        // ------------------------------------------------------------------ //
        // By race
        // ------------------------------------------------------------------ //
        
        use id weight age race flemp proprietors if age < 65 using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
        // Calculate wage income
        generate wage = flemp + 0.7*proprietors
        // Employment dummy
        generate employed = (wage > 0)
        // Get ranks
        sort race wage
        by race: generate rank = sum(weight)
        by race: replace rank = (rank - weight/2)/rank[_N]
        // Get quartiles
        generate quartile = .
        replace quartile = 1 if inrange(rank, 0.00, 0.25)
        replace quartile = 2 if inrange(rank, 0.25, 0.50)
        replace quartile = 3 if inrange(rank, 0.50, 0.75)
        replace quartile = 4 if inrange(rank, 0.75, 1.00)
        // Aggregate
        gcollapse (mean) wage employed (rawsum) pop=weight [pw=weight], by(quartile race)
        generate year = `year'
        generate month = `month'
        append using "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta"
        save "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta", replace
        
        // ------------------------------------------------------------------ //
        // By gender
        // ------------------------------------------------------------------ //
        
        use id weight age sex flemp proprietors if age < 65 using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
        // Calculate wage income
        generate wage = flemp + 0.7*proprietors
        // Employment dummy
        generate employed = (wage > 0)
        // Get ranks
        sort sex wage
        by sex: generate rank = sum(weight)
        by sex: replace rank = (rank - weight/2)/rank[_N]
        // Get quartiles
        generate quartile = .
        replace quartile = 1 if inrange(rank, 0.00, 0.25)
        replace quartile = 2 if inrange(rank, 0.25, 0.50)
        replace quartile = 3 if inrange(rank, 0.50, 0.75)
        replace quartile = 4 if inrange(rank, 0.75, 1.00)
        // Aggregate
        gcollapse (mean) wage employed (rawsum) pop=weight [pw=weight], by(quartile sex)
        generate year = `year'
        generate month = `month'
        append using "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta"
        save "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta", replace
        
        // ------------------------------------------------------------------ //
        // By education
        // ------------------------------------------------------------------ //
        
        use id weight age sex educ flemp proprietors if age < 65 using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
        // Calculate wage income
        generate wage = flemp + 0.7*proprietors
        // Employment dummy
        generate employed = (wage > 0)
        // Get ranks
        sort educ wage
        by educ: generate rank = sum(weight)
        by educ: replace rank = (rank - weight/2)/rank[_N]
        // Get quartiles
        generate quartile = .
        replace quartile = 1 if inrange(rank, 0.00, 0.25)
        replace quartile = 2 if inrange(rank, 0.25, 0.50)
        replace quartile = 3 if inrange(rank, 0.50, 0.75)
        replace quartile = 4 if inrange(rank, 0.75, 1.00)
        // Aggregate
        gcollapse (mean) wage employed (rawsum) pop=weight [pw=weight], by(quartile educ)
        generate year = `year'
        generate month = `month'
        append using "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta"
        save "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta", replace
    }
}

clear
save "$work/04-analyze-wage-growth/decomposition-monthly-wages-top1.dta", replace emptyok

global date_begin = ym(1998, 01)
global date_end   = ym(2022, 04)

quietly {
    foreach t of numlist $date_begin / $date_end {
        noisily di "* " %tm = `t'
        
        local year = year(dofm(`t'))
        local month = month(dofm(`t'))
        
        // ------------------------------------------------------------------ //
        // All working-age adults
        // ------------------------------------------------------------------ //

        use id weight age flemp proprietors if age < 65 using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
        // Calculate wage income
        generate wage = flemp + 0.7*proprietors
        // Employment dummy
        generate employed = (wage > 0)
        // Get ranks
        sort wage
        generate rank = sum(weight)
        replace rank = (rank - weight/2)/rank[_N]
        // Get quartiles
        generate top = inrange(rank, 0.99, 1)
        // Aggregate
        gcollapse (mean) wage employed (rawsum) pop=weight [pw=weight], by(top)
        generate year = `year'
        generate month = `month'
        append using "$work/04-analyze-wage-growth/decomposition-monthly-wages-top1.dta"
        save "$work/04-analyze-wage-growth/decomposition-monthly-wages-top1.dta", replace
    }
}


// -------------------------------------------------------------------------- //
// Plot total wage growth between different points
// -------------------------------------------------------------------------- //

use "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta", clear
merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", keepusing(nipa_deflator) nogenerate keep(match)

keep if missing(race) & missing(sex) & quartile == 2

replace wage = wage/nipa_deflator

generate time = ym(year, month)
format time %tm

summarize wage if time == $pre2008_peak
global wage_pre2008_peak = r(mean)

summarize wage if time == $post2008_recov
global wage_post2008_recov = r(mean)

global wage_growth_post2008 = strofreal(100*((${wage_post2008_recov}/${wage_pre2008_peak})^(1/((${post2008_recov} - ${pre2008_peak})/12)) - 1), "%03.2f")

summarize wage if time == $preCOVID_peak
global wage_preCOVID_peak = r(mean)

summarize wage if time == $postCOVID_recov
global wage_postCOVID_recov = r(mean)

global wage_growth_postCOVID = strofreal(100*((${wage_postCOVID_recov}/${wage_preCOVID_peak})^(1/((${postCOVID_recov} - ${preCOVID_peak})/12)) - 1), "%03.2f")

gr tw (line wage time, lw(medthick) col(ebblue)), ///
    legend(off) ytitle("Average real labor income (constant USD)") yscale(range(24000 35000)) ylabel(, format(%9.0gc)) ///
    xtitle("") xlabel(`=ym(2006, 1)'(48)`=ym(2022, 1)')
graph export "$graphs/04-analyze-wage-growth/wages-1.pdf", replace

gr tw (line wage time, lw(medthick) col(ebblue)) (sc wage time if inlist(time, $pre2008_peak, $post2008_recov, $preCOVID_peak, $postCOVID_recov), col(cranberry)) ///
    (pcarrowi 33300 `=ym(2011, 1)' 29100 `=${pre2008_peak} + 1', lw(medthick) col(cranberry)) ///
    (pcarrowi 33300 `=ym(2014, 4)' 29700 `=${post2008_recov} - 1', lw(medthick) col(cranberry)), ///
    legend(off) ytitle("Average real labor income (constant USD)") yscale(range(24000 35000)) ylabel(, format(%9.0gc)) ///
    xtitle("") xlabel(`=ym(2006, 1)'(48)`=ym(2022, 1)') ///
    text(34000  `=($pre2008_peak + $post2008_recov)/2' ///
        "Identical working-age" "employment rates", col(cranberry) justification(center))
graph export "$graphs/04-analyze-wage-growth/wages-2.pdf", replace

gr tw (line wage time, lw(medthick) col(ebblue)) (sc wage time if inlist(time, $pre2008_peak, $post2008_recov, $preCOVID_peak, $postCOVID_recov), col(cranberry)) ///
    (pcarrowi 33300 `=ym(2011, 1)' 29100 `=${pre2008_peak} + 1', lw(medthick) col(cranberry)) ///
    (pcarrowi 33300 `=ym(2014, 4)' 29700 `=${post2008_recov} - 1', lw(medthick) col(cranberry)) ///
    (pcarrowi ${wage_pre2008_peak} `=$pre2008_peak + 4' ${wage_post2008_recov} `=$post2008_recov - 4', lw(medthick) col(black)), ///
    legend(off) ytitle("Average real labor income (constant USD)") yscale(range(24000 35000)) ylabel(, format(%9.0gc)) ///
    xtitle("") xlabel(`=ym(2006, 1)'(48)`=ym(2022, 1)') ///
    text(`=(${wage_post2008_recov} + ${wage_pre2008_peak})/2 + 400' `=($pre2008_peak + $post2008_recov)/2 + 3' ///
        "Annualized growth {bf:+${wage_growth_post2008}%}", placement(n) justification(center)) ///
    text(34000  `=($pre2008_peak + $post2008_recov)/2' ///
        "Identical working-age" "employment rates", col(cranberry) justification(center))
graph export "$graphs/04-analyze-wage-growth/wages-3.pdf", replace
        
gr tw (line wage time, lw(medthick) col(ebblue)) (sc wage time if inlist(time, $pre2008_peak, $post2008_recov, $preCOVID_peak, $postCOVID_recov), col(cranberry)) ///
    (pcarrowi 33300 `=ym(2011, 1)' 29100 `=${pre2008_peak} + 1', lw(medthick) col(cranberry)) ///
    (pcarrowi 33300 `=ym(2014, 4)' 29700 `=${post2008_recov} - 1', lw(medthick) col(cranberry)) ///
    (pcarrowi ${wage_pre2008_peak} `=$pre2008_peak + 4' ${wage_post2008_recov} `=$post2008_recov - 4', lw(medthick) col(black)) ///
    (pcarrowi `=${wage_preCOVID_peak} + 200' `=$preCOVID_peak + 3' `=${wage_postCOVID_recov} - 200' `=$postCOVID_recov - 4', lw(medthick) col(black)), ///
    legend(off) ytitle("Average real labor income (constant USD)") yscale(range(24000 35000)) ylabel(, format(%9.0gc)) ///
    xtitle("") xlabel(`=ym(2006, 1)'(48)`=ym(2022, 1)') ///
    text(`=(${wage_post2008_recov} + ${wage_pre2008_peak})/2 + 400' `=($pre2008_peak + $post2008_recov)/2 + 3' ///
        "Annualized growth {bf:+${wage_growth_post2008}%}", placement(n) justification(center)) ///
    text(`=(${wage_postCOVID_recov} + ${wage_preCOVID_peak})/2 + 1000' `=($preCOVID_peak + $postCOVID_recov)/2' ///
        "Annualized" "growth" "{bf:+${wage_growth_postCOVID}%}", placement(n) justification(center)) ///
    text(34000  `=($pre2008_peak + $post2008_recov)/2' ///
        "Identical working-age" "employment rates", col(cranberry) justification(center))
graph export "$graphs/04-analyze-wage-growth/wages-4.pdf", replace

// -------------------------------------------------------------------------- //
// Bar chart for other quartiles
// -------------------------------------------------------------------------- //

use "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta", clear
merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", keepusing(nipa_deflator) nogenerate keep(match)

replace wage = wage/nipa_deflator

preserve
    keep if missing(race) & missing(sex)
    gcollapse (mean) wage [pw=pop], by(year month)
    generate quartile = 99
    tempfile tot
    save "`tot'", replace
restore

keep if missing(race) & missing(sex) & quartile >= 2
append using "`tot'"

generate time = ym(year, month)
format time %tm

// Mark points of comparison
generate marker = .
replace marker = 1 if time == $pre2008_peak
replace marker = 2 if time == $post2008_recov
replace marker = 3 if time == $preCOVID_peak
replace marker = 4 if time == $postCOVID_recov
drop if missing(marker)

keep quartile marker time wage
reshape wide time wage, i(quartile) j(marker)

// Calculate growth
generate growth2008 = 100*((wage2/wage1)^(1/((time2 - time1)/12)) - 1)
generate growthCOVID = 100*((wage4/wage3)^(1/((time4 - time3)/12)) - 1)

generate group = ""
replace group = "2nd quartile" if quartile == 2
replace group = "3rd quartile" if quartile == 3
replace group = "4th quartile" if quartile == 4
replace group = "Total" if quartile == 99

preserve
    replace growth2008 = . if quartile > 2
    replace growthCOVID = . if quartile > 2
    gr bar growth2008 growthCOVID, bar(1, col(cranberry)) bar(2, col(ebblue)) ///
        ytitle("Annualized real labor income growth (%)") bargap(20) /// 
        over(group) ylabel(, format(%02.1f)) ///
        legend(label(1 "Great recession & recovery") label(2 "COVID recession & recovery"))
    graph export "$graphs/04-analyze-wage-growth/wages-quartiles-1.pdf", replace
restore

preserve
    replace growth2008 = . if quartile > 3
    replace growthCOVID = . if quartile > 3
    gr bar growth2008 growthCOVID, bar(1, col(cranberry)) bar(2, col(ebblue)) ///
        ytitle("Annualized real labor income growth (%)") bargap(20) /// 
        over(group) ylabel(, format(%02.1f)) ///
        legend(label(1 "Great recession & recovery") label(2 "COVID recession & recovery"))
    graph export "$graphs/04-analyze-wage-growth/wages-quartiles-2.pdf", replace
restore

preserve
    replace growth2008 = . if quartile > 4
    replace growthCOVID = . if quartile > 4
    gr bar growth2008 growthCOVID, bar(1, col(cranberry)) bar(2, col(ebblue)) ///
        ytitle("Annualized real labor income growth (%)") bargap(20) /// 
        over(group) ylabel(, format(%02.1f)) ///
        legend(label(1 "Great recession & recovery") label(2 "COVID recession & recovery"))
    graph export "$graphs/04-analyze-wage-growth/wages-quartiles-3.pdf", replace
restore

preserve
    gr bar growth2008 growthCOVID, bar(1, col(cranberry)) bar(2, col(ebblue)) ///
        ytitle("Annualized real labor income growth (%)") bargap(20) /// 
        over(group) ylabel(, format(%02.1f)) ///
        legend(label(1 "Great recession & recovery") label(2 "COVID recession & recovery"))
    graph export "$graphs/04-analyze-wage-growth/wages-quartiles-4.pdf", replace
restore

// -------------------------------------------------------------------------- //
// Evolution of wage income by race
// -------------------------------------------------------------------------- //

use "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta", clear
merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", keepusing(nipa_deflator) nogenerate keep(match)

replace wage = wage/nipa_deflator
gegen emprate = mean(employed) [pw=pop], by(race year month)

drop if missing(race)

generate time = ym(year, month)
format time %tm

gcollapse (mean) emprate wage [pw=pop], by(race year month time)

generate quarter = quarter(dofm(time))
gcollapse (mean) emprate wage, by(race year quarter)

generate time = yq(year, quarter)
format time %tq

// Make into and index (base 2006)
sort race time
gegen ref = mean(wage) if year == 2007, by(race)
gegen ref = max(ref), by(race) replace
generate wage_base2007 = 100*wage/ref
drop ref

// Index since 2006
gr tw (line wage_base2007 time if race == 1, lw(medthick) col(ebblue)) ///
    (line wage_base2007 time if race == 2, lw(medthick) col(cranberry)) ///
    (line wage_base2007 time if race == 3, lw(medthick) col(green)), ///
    xtitle("") xlabel(184(8)247) ytitle("Labor income (working-age population)" "Constant USD (2007 = 100)") ylabel(85(5)130) ///
    legend(off) ///
    text(92 `=yq(2015, 1)' "Blacks", col(cranberry)) ///
    text(100 `=yq(2011, 1)' "Whites", col(ebblue)) ///
    text(113 `=yq(2016, 1)' "Hispanics", col(green))
graph export "$graphs/04-analyze-wage-growth/growth-rates-race.pdf", replace

// -------------------------------------------------------------------------- //
// Evolution of wage income by gender
// -------------------------------------------------------------------------- //

use "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta", clear
merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", keepusing(nipa_deflator) nogenerate keep(match)

replace wage = wage/nipa_deflator
gegen emprate = mean(employed) [pw=pop], by(race year month)

drop if missing(sex)

generate time = ym(year, month)
format time %tm

gcollapse (mean) emprate wage [pw=pop], by(sex year month time)

generate quarter = quarter(dofm(time))
gcollapse (mean) emprate wage, by(sex year quarter)

generate time = yq(year, quarter)
format time %tq

// Make into and index (base 2006)
sort sex time
gegen ref = mean(wage) if year == 2007, by(sex)
gegen ref = max(ref), by(sex) replace
generate wage_base2007 = 100*wage/ref
drop ref

// Index since 2006
gr tw (line wage_base2007 time if sex == 1, lw(medthick) col(ebblue)) ///
    (line wage_base2007 time if sex == 2, lw(medthick) col(cranberry)), ///
    xtitle("") xlabel(184(8)247) ytitle("Labor income (working-age population)" "Constant USD (2007 = 100)") ylabel(85(5)130) ///
    legend(off) ///
    text(90 `=yq(2010, 2)' "Men", col(ebblue)) ///
    text(113 `=yq(2017, 1)' "Women", col(cranberry))
graph export "$graphs/04-analyze-wage-growth/growth-rates-sex.pdf", replace

// -------------------------------------------------------------------------- //
// Table for the different subgroups
// -------------------------------------------------------------------------- //

use "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta", clear
merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", keepusing(nipa_deflator) nogenerate keep(match)

replace wage = wage/nipa_deflator

gegen group = group(race sex), missing
gegen emprate = mean(employed) [pw=pop], by(group year month)

gcollapse (mean) emprate wage [pw=pop], by(group race sex year month)

generate time = ym(year, month)
format time %tm

// Slightly smooth wage series for more robust growth rates
tsset group time, monthly
tssmooth ma wage = wage, replace window(1 1 1)

*gr tw (line wage time if race == 1) (line wage time if race == 3), xline(`=ym(2007, 12)' `=ym(2019, 2)') yscale(log)

generate peak2008 = ym(2007, 12)

// Locate great recession recovery point
generate emprate_peak2008 = emprate if time == peak2008
gegen emprate_peak2008 = max(emprate_peak2008), by(group) replace

generate above_peak2008 = (emprate >= emprate_peak2008) & (time > (peak2008 + 12))
gsort group -above_peak2008 time

by group: generate is_2008recov = (above_peak2008) & (_n == 1)

gegen num_recov = total(is_2008recov), by(group)
assert num_recov == 1
drop num_recov

// Pre-COVID comparison point
generate emprate_peakCOVID = emprate if time == ym(2022, 02)
gegen emprate_peakCOVID = max(emprate_peakCOVID), by(group) replace

generate above_peakCOVID = (emprate >= emprate_peakCOVID) & (time < ym(2020, 03)) & (time > (peak2008 + 12))
gsort group -above_peakCOVID time

by group: generate is_COVIDpeak = (above_peakCOVID) & (_n == 1)

gegen num_recov = total(is_COVIDpeak), by(group)
assert num_recov == 1
drop num_recov

// Keep only points of comparison
generate marker = .
replace marker = 1 if time == peak2008
replace marker = 2 if is_2008recov
replace marker = 3 if is_COVIDpeak
replace marker = 4 if time == ym(2022, 02)

keep if !missing(marker)

keep group race sex marker time wage
reshape wide time wage, i(group race sex) j(marker)

generate growth2008 = 100*((wage2/wage1)^(1/((time2 - time1)/12)) - 1)
generate duration2008_year = floor((time2 - time1)/12)
generate duration2008_month = mod(time2 - time1, 12)

generate growthCOVID = 100*((wage4/wage3)^(1/((time4 - time3)/12)) - 1)
generate durationCOVID_year = floor((time4 - time3)/12)
generate durationCOVID_month = mod(time4 - time3, 12)

// Plot
generate group_str = ""
replace group_str = "Whites" if (race == 1)
replace group_str = "Blacks" if (race == 2)
replace group_str = "Hispanics" if (race == 3)
replace group_str = "Men" if (sex == 1)
replace group_str = "Women" if (sex == 2)
drop if group_str == ""

generate group_order = 1 if group_str == "Whites"
replace group_order = 2 if group_str == "Blacks"
replace group_order = 3 if group_str == "Hispanics"
replace group_order = 4 if group_str == "Men"
replace group_order = 5 if group_str == "Women"

generate categ = "Race/Ethnicity" if !missing(race)
replace categ = "Gender" if !missing(sex)

gr bar growth2008 growthCOVID, bar(1, col(cranberry)) bar(2, col(ebblue)) ///
    ytitle("Annualized real labor income growth (%)") bargap(20) /// 
    over(group_str, sort(group_order)) over(categ) nofill ///
    legend(label(1 "Great recession & recovery") label(2 "COVID recession & recovery")) ///
    ///
    text(0.8 3 "9 years" "11 months", size(small) col(cranberry)) ///
    text(2.1 12 "2 years" "3 months", size(small) col(ebblue)) ///
    ///
    text(1.3 22 "10 years" "4 months", size(small) col(cranberry)) ///
    text(3.05 30.5 "2 years" "10 months", size(small) col(ebblue)) ///
    ///
    text(1.15 49 "11 years" "11 months", size(small) col(cranberry)) ///
    text(1.7 58 "3 years" "7 month", size(small) col(ebblue)) ///
    ///
    text(0.45 67.5 "8 years" "10 months", size(small) col(cranberry)) ///
    text(2 76 "2 years" "4 months", size(small) col(ebblue)) ///
    ///
    text(1.45 87 "10 years" "1 month", size(small) col(cranberry)) ///
    text(2.95 95 "2 years" "2 months", size(small) col(ebblue))
graph export "$graphs/04-analyze-wage-growth/growth-rates-race-gender.pdf", replace

// -------------------------------------------------------------------------- //
// Wage levels by quartile + top 1%
// -------------------------------------------------------------------------- //

use "$work/04-analyze-wage-growth/decomposition-monthly-wages-top1.dta", clear
keep if top == 1
drop top
generate quartile = 99
append using "$work/04-analyze-wage-growth/decomposition-monthly-wages.dta"

keep if year >= 2019 & missing(educ) & missing(sex) & missing(race) & quartile > 1

merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", keepusing(nipa_deflator) nogenerate keep(match)

replace wage = wage/nipa_deflator

generate time = ym(year, month)
tsset quartile time, monthly

by quartile: generate wage0 = wage[1]
replace wage = 100*wage/wage0

keep year month time quartile wage
reshape wide wage, i(year month time) j(quartile)

gr tw line wage* time, lw(medthick..) legend(off) lcol(ebblue cranberry orange purple) scale(1.2) ///
    ytitle("Average real labor income" "Index (2019m1 = 100)") xtitle("") ///
    text(90 `=ym(2020, 11)' "2nd quartile", size(small) col(ebblue)) ///
    text(102 `=ym(2021, 7)' "3rd quartile", size(small) col(cranberry)) ///
    text(108 `=ym(2022, 1)' "4th quartile", size(small) col(orange)) ///
    text(110 `=ym(2021, 1)' "Top 1%", size(small) col(purple))
gr export "$graphs/04-analyze-wage-growth/wage-growth-covid.pdf", replace
