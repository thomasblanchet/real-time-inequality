// -------------------------------------------------------------------------- //
// Create monthly estimates of the adult population
// -------------------------------------------------------------------------- //

// Import monthly (total) population from NIPA
use "$work/02-prepare-nipa/nipa-simplified-monthly.dta", clear
keep year month nipa_pop
generate time = ym(year, month)

replace time = time + 5

tsset time, monthly
tempfile pop_nipa
save "`pop_nipa'", replace

// Import annual total and adult population from SEER
use "$work/01-import-pop/pop-data-national.dta", clear
merge 1:1 year using "$work/01-import-dina/dina-full-aggregates.dta", ///
    nogenerate keepusing(dina_adults dina_taxunits) keep(match)
keep if year >= 1974

// Check consistency
preserve
    merge 1:n year using "`pop_nipa'", nogenerate
    
    replace pop = . if month != 7
    replace adult = . if month != 7
    replace dina_adults = . if month != 7
    replace dina_taxunits = . if month != 7
    
    gr tw con pop nipa_pop adult dina_adults dina_taxunits time, sort(time) lw(medthick..) msym(Th i i Oh Oh) ///
        connect(none direct direct none none) col(cranberry cranberry ebblue ebblue green) msize(small..) ///
        legend(pos(3) cols(1) label(1 "Population" "(SEER, yearly)") label(2 "Population" "(NIPA, monthly)") ///
            label(3 "Adult" "(SEER, yearly)") label(4 "Adults" "(DINA, yearly)") label(5 "Tax units" "(DINA, yearly)")) ///
            xtitle("") xlabel(, angle(45))
    graph export "$graphs/02-prepare-pop/populations.pdf", replace
restore

// -------------------------------------------------------------------------- //
// Disaggregate adult & tax units population using Denton's method
// -------------------------------------------------------------------------- //

tsset year, yearly

tempfile adult_monthly
denton adult using "`adult_monthly'", interp(nipa_pop) from("`pop_nipa'") generate(monthly_adult) stock

tempfile working_age_monthly
denton working_age using "`working_age_monthly'", interp(nipa_pop) from("`pop_nipa'") generate(monthly_working_age) stock

tempfile pop_monthly
denton pop using "`pop_monthly'", interp(nipa_pop) from("`pop_nipa'") generate(monthly_pop) stock

tempfile taxunits_monthly
denton dina_taxunits using "`taxunits_monthly'", interp(nipa_pop) from("`pop_nipa'") generate(monthly_taxunits) stock

use "`pop_monthly'", clear
merge 1:1 time using "`adult_monthly'", nogenerate
merge 1:1 time using "`working_age_monthly'", nogenerate
merge 1:1 time using "`taxunits_monthly'", nogenerate

replace time = time - 5

// -------------------------------------------------------------------------- //
// Extrapolate in recent years
// -------------------------------------------------------------------------- //

merge 1:1 time using "`pop_nipa'", nogenerate

foreach stub in pop adult working_age taxunits {
    generate ratio_`stub' = monthly_`stub'/nipa_pop
    sort time
    carryforward ratio_`stub', replace
    replace monthly_`stub' = nipa_pop*ratio_`stub' if missing(monthly_`stub')
}

keep if year >= 1975
keep year month monthly_pop monthly_adult monthly_working_age monthly_taxunits

// -------------------------------------------------------------------------- //
// Save
// -------------------------------------------------------------------------- //

save "$work/02-prepare-pop/pop-data-monthly.dta", replace

// -------------------------------------------------------------------------- //
// Save quarterly version
// -------------------------------------------------------------------------- //

generate quarter = quarter(dofm(ym(year, month)))
collapse (mean) quarterly_pop=monthly_pop quarterly_adult=monthly_adult ///
    quarterly_working_age=monthly_working_age quarterly_taxunits=monthly_taxunits, by(year quarter)
save "$work/02-prepare-pop/pop-data-quarterly.dta", replace

