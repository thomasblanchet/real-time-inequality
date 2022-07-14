// -------------------------------------------------------------------------- //
// Growth incidence curve over COVID and great recession
// -------------------------------------------------------------------------- //

clear
save "$work/04-gic-wages/gic.dta", replace emptyok

// Local critical dates
global pre2008_peak = ym(2007, 12)
global post2008_recov = ym(2017, 05)

global preCOVID_peak = ym(2020, 02)
global postCOVID_recov = ym(2022, 05)

local j = 1
foreach t in $pre2008_peak $post2008_recov $preCOVID_peak $postCOVID_recov {
    local year = year(dofm(`t'))
    local month = month(dofm(`t'))
    
    use id weight age flemp proprietors if age < 65 using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
    
    // Calculate wage income
    generate wage = flemp + 0.7*proprietors
    
    //gegen wage = mean(wage), by(id) replace
    
    // Get rank
    sort wage
    generate rank = sum(weight)
    replace rank = 1e5*(rank - weight/2)/rank[_N]

    egen p = cut(rank), at(0(5000)95000 99000 999999)
    
    gcollapse (mean) wage [pw=weight], by(p)
    
    generate year = `year'
    generate month = `month'
    generate j = `j'
    
    append using "$work/04-gic-wages/gic.dta"
    save "$work/04-gic-wages/gic.dta", replace
    
    local j = `j' + 1
}

merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", keepusing(nipa_deflator) nogenerate keep(match)

replace wage = wage/nipa_deflator

keep p wage j
reshape wide wage, i(p) j(j)

generate growth_2008 = 100*((wage2/wage1)^(12/(${post2008_recov} - ${pre2008_peak})) - 1)
generate growth_covid = 100*((wage4/wage3)^(12/(${postCOVID_recov} - ${preCOVID_peak})) - 1)

gr tw (con growth_2008 p if p >= 25000, col(ebblue) lw(medthick) msym(Sh)) ///
    (con growth_covid p if p >= 25000, col(cranberry) lw(medthick) msym(Oh)), ///
    xtitle("Percentiles (working-age population)") ytitle("Annualized real labor income growth (%)") ///
    ylabel(0(1)4, format(%01.0f)) xlabel(25000 "25-30%" 30000 "30-35%" 35000 "35-40%" ///
        40000 "40-45%" 45000 "45-50%" 50000 "50-55%" 55000 "55-60%" 60000 "60-65%" ///
        65000 "65-70%" 70000 "70-75%" 75000 "75-80%" 80000 "80-85%" 85000 "85-90%" ///
        90000 "90-95%" 95000 "95-99%" 99000 "Top 1%", alternate labsize(small)) ///
    legend(off) ///
    text(2.7 45000 "COVID recession" "and recovery" "(02/2020 to 05/2022)", col(cranberry) size(small)) ///
    text(0.9 35000 "Great recession" "and recovery" "(12/2007 to 05/2017)", col(ebblue) size(small))
graph export "$graphs/04-gic-wages/gic-wages.pdf", replace
