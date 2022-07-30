// -------------------------------------------------------------------------- //
// Build the online database
// -------------------------------------------------------------------------- //

clear

global date_begin = ym(2022, 01)
global date_end   = ym(2022, 06)

cap use "$work/03-build-online-database-labor/online-database-labor.dta", clear
if (_rc == 0) {
    drop if ym(year, month) >= $date_begin
}
save "$work/03-build-online-database-labor/online-database-labor.dta", emptyok replace 

tempfile micro data groups total

quietly {
    foreach t of numlist $date_begin / $date_end {
        foreach unit in individual equal_split {
            local year = year(dofm(`t'))
            local month = month(dofm(`t'))
            
            use id flemp proprietors age weight if age < 65 using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
            
            generate wage_income = flemp + 0.7*proprietors
            
            if ("`unit'" == "equal_split") {
                gegen wage_income = mean(wage_income), by(id) replace
            }
            
            generate employed = (wage_income > 0)
            
            save "`data'", replace
            
            timer clear 1
            timer on 1
            
            use "`data'", clear
            
            sort wage_income
            
            generate rank = sum(weight)
            replace rank = (rank - weight/2)/rank[_N]
            
            generate group = ""
            replace group = "1st_quartile" if inrange(rank, 0.00, 0.25)
            replace group = "2nd_quartile" if inrange(rank, 0.25, 0.50)
            replace group = "3rd_quartile" if inrange(rank, 0.50, 0.75)
            replace group = "top25_10"     if inrange(rank, 0.75, 0.90)
            replace group = "top10_1"      if inrange(rank, 0.90, 0.99)
            replace group = "top1"         if inrange(rank, 0.99, 1.00)
            
            save "`micro'", replace
            
            gcollapse (sum) value=wage_income [pw=weight], by(group)
            
            generate type = 1
            greshape wide value, i(type) j(group) string
            
            generate value4th_quartile = valuetop25_10 + valuetop10_1 + valuetop1
            generate valuetop10 = valuetop10_1 + valuetop1
            greshape long value, i(type) j(group) string
            drop type
            
            replace group = "1st Quartile" if group == "1st_quartile"
            replace group = "2nd Quartile" if group == "2nd_quartile"
            replace group = "3rd Quartile" if group == "3rd_quartile"
            replace group = "4th Quartile" if group == "4th_quartile"
            replace group = "Top 10%"      if group == "top10"
            replace group = "Top 1%"       if group == "top1"
            replace group = "Top 10%-1%"   if group == "top10_1"
            replace group = "Top 25%-10%"  if group == "top25_10"
            
            generate year = `year'
            generate month = `month'
            generate unit = "working_age_`unit'"
            generate income = "labor_income"
            save "`groups'", replace
            
            use "`micro'", clear
            
            gcollapse (sum) value=wage_income (mean) employed=employed (rawsum) pop=weight [pw=weight]
            generate group = "Total"
            generate unit = "working_age_`unit'"
            generate income = "labor_income"
            
            generate year = `year'
            generate month = `month'
            save "`total'", replace
            
            use "$work/03-build-online-database-labor/online-database-labor.dta", clear
            append using "`groups'" "`total'" 
            save "$work/03-build-online-database-labor/online-database-labor.dta", replace
            
            timer off 1
            timer list 1
            
            noisily display "* labor income, `unit', `year'm`month' [`=r(t1)' seconds]"
        }
    }
}

// -------------------------------------------------------------------------- //
// Export in the right format
// -------------------------------------------------------------------------- //

use "$work/03-build-online-database-labor/online-database-labor.dta", clear

gen time = ym(year, month)
format time %tm

replace employed = 100*(employed - 0.75)/(1 - 0.75)

gr tw (line employed time if unit == "working_age_equal_split", col(ebblue) lw(medthick)) ///
    (line employed time if unit == "working_age_individual", col(cranberry) lw(medthick)), ///
    xtitle("") ytitle("Employed (%)") yscale(range(0 100)) ylabel(0(10)100) ///
    xlabel(`=ym(1976, 01)'(48)`=ym(2020, 01)', alternate) legend(off) ///
    text(90 `=ym(1990, 01)' "Working-age adults" "(equal split among married)", col(ebblue)) ///
    text(40 `=ym(2002, 01)' "Working-age adults" "(individualized)", col(cranberry)) ///
    subtitle("Employment Rate of Bottom 25% Working-Age Adults") ///
    note("Our labor income statistics include all working-age adults including non-workers. All non-workers have zero labor income and" ///
        "hence are in the bottom 25%. This figure displays the employment rate of bottom 25% working-age adults (defined as having" ///
        "positive labor income). In the series “working-age adults (individualized)”, direct individual earnings are used. The secular" ///
        "upper trend reflects the growing female labor force participation. In the series “working-age adults (equal split among" ///
        "married)”, earnings are split equally within married couples. This eliminates the secular trend and makes such series more" ///
        "meaningful for long-term inequality comparisons.", size(vsmall))
graph export "$graphs/03-build-online-database-labor/employment-first-quartile.pdf", replace

gegen pop = mean(pop), by(year month unit income) replace

replace pop = 0.25*pop if group == "1st Quartile"
replace pop = 0.25*pop if group == "2nd Quartile"
replace pop = 0.25*pop if group == "3rd Quartile"
replace pop = 0.25*pop if group == "4th Quartile"
replace pop = (0.25 - 0.1)*pop if group == "Top 25%-10%"
replace pop = 0.1*pop if group == "Top 10%"
replace pop = 0.01*pop if group == "Top 1%"
replace pop = (0.1 - 0.01)*pop if group == "Top 10%-1%"

gegen pop = mean(pop), by(group year month unit) replace

greshape wide value, i(group year month unit) j(income) string
renvars value*, predrop(5)

drop pop employed

/*
merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", ///
    keepusing(nipa_deflator) keep(master match) assert(match using) nogenerate
rename nipa_deflator deflator
*/

sort year month unit group

export delimited "$website/online-database-labor.csv", replace
