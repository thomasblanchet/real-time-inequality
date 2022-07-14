// -------------------------------------------------------------------------- //
// Build the online database
// -------------------------------------------------------------------------- //

global date_begin = ym(2021, 01)
global date_end   = ym(2022, 05)

cap use "$work/03-build-online-database/online-database.dta", clear
if (_rc == 0) {
    drop if ym(year, month) >= $date_begin
}
save "$work/03-build-online-database/online-database.dta", emptyok replace 

local income_variables factor_income pretax_income disposable_income posttax_income wage_income wealth
tempfile micro data groups total

quietly {
    foreach t of numlist $date_begin / $date_end {
        foreach unit in "Households" "Adults" "Working-age" {
            
            local year = year(dofm(`t'))
            local month = month(dofm(`t'))
            
            use "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
                
            generate factor_income     = princ
            generate pretax_income     = peinc
            generate disposable_income = dispo
            generate posttax_income    = poinc
            generate wage_income       = flemp + 0.7*proprietors
            generate wealth            = hweal
            
            // Equal-split
            foreach v of varlist factor_income pretax_income disposable_income ///
                posttax_income wage_income wealth {
                
                gegen `v' = mean(`v'), by(id) replace
            }
            
            if ("`unit'" == "Households") {
                gcollapse (mean) weight (nansum) `income_variables', by(id)
            }
            else if ("`unit'" == "Working-age") {
                drop if age >= 65
            }
            
            save "`data'", replace
            
            foreach v of varlist `income_variables' {
                timer clear 1
                timer on 1
            
                use "`data'", clear
                
                sort `v'
                
                generate rank = sum(weight)
                replace rank = (rank - weight/2)/rank[_N]
                
                generate group = ""
                replace group = "bot50"     if inrange(rank, 0, 0.5)
                replace group = "mid40"     if inrange(rank, 0.5, 0.9)
                replace group = "top10_1"   if inrange(rank, 0.9, 0.99)
                replace group = "top1_01"   if inrange(rank, 0.99, 0.999)
                replace group = "top01_001" if inrange(rank, 0.999, 0.9999)
                replace group = "top001"    if inrange(rank, 0.9999, 1)
                
                save "`micro'", replace
                
                gcollapse (sum) value=`v' [pw=weight], by(group)
                
                generate type = 1
                greshape wide value, i(type) j(group) string
                
                generate valuetop10 = valuetop001 + valuetop01_001 + valuetop1_01 + valuetop10_1
                generate valuetop1  = valuetop001 + valuetop01_001 + valuetop1_01
                generate valuetop01 = valuetop001 + valuetop01_001
                
                greshape long value, i(type) j(group) string
                drop type
                
                replace group = "Bottom 50%"     if group == "bot50"
                replace group = "Middle 40%"     if group == "mid40"
                replace group = "Top 10%"        if group == "top10"
                replace group = "Top 1%"         if group == "top1"
                replace group = "Top 0.1%"       if group == "top01"
                replace group = "Top 0.01%"      if group == "top001"
                replace group = "Top 10%-1%"     if group == "top10_1"
                replace group = "Top 1%-0.1%"    if group == "top1_01"
                replace group = "Top 0.1%-0.01%" if group == "top01_001"
                
                generate year = `year'
                generate month = `month'
                generate unit = "`unit'"
                generate income = "`v'"
                save "`groups'", replace
                
                use "`micro'", clear
                
                gcollapse (sum) value=`v' (rawsum) pop=weight [pw=weight]
                generate group = "Total"
                generate unit = "`unit'"
                generate income = "`v'"
                
                generate year = `year'
                generate month = `month'
                save "`total'", replace
                
                use "$work/03-build-online-database/online-database.dta", clear
                append using "`groups'" "`total'" 
                save "$work/03-build-online-database/online-database.dta", replace
                
                timer off 1
                timer list 1
            
                noisily display "* `v', `unit', `year'm`month' [`=r(t1)' seconds]"
            }   
        }
    }
}

// -------------------------------------------------------------------------- //
// Export in the right format
// -------------------------------------------------------------------------- //

use "$work/03-build-online-database/online-database.dta", clear

gegen pop = mean(pop), by(year month unit income) replace

replace pop = 0.5*pop if group == "Bottom 50%"
replace pop = 0.4*pop if group == "Middle 40%"
replace pop = 0.1*pop if group == "Top 10%"
replace pop = 0.01*pop if group == "Top 1%"
replace pop = 0.001*pop if group == "Top 0.1%"
replace pop = 0.0001*pop if group == "Top 0.01%"
replace pop = (0.1 - 0.01)*pop if group == "Top 10%-1%"
replace pop = (0.01 - 0.001)*pop if group == "Top 1%-0.1%"
replace pop = (0.001 - 0.0001)*pop if group == "Top 0.1%-0.01%"

gegen pop = mean(pop), by(group year month unit) replace

greshape wide value, i(group year month unit) j(income) string
renvars value*, predrop(5)
rename pop population

merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", ///
    keepusing(nipa_deflator) keep(master match) assert(match using) nogenerate
rename nipa_deflator deflator

sort year month unit group

export delimited "$website/online-database.csv", replace

keep if group == "Total"

keep year month unit population deflator

replace unit = "_" + strlower(subinstr(unit, "-", "_", .))
greshape wide population, i(year month) j(unit) string

export delimited "$website/online-database-popul-deflator.csv", replace
