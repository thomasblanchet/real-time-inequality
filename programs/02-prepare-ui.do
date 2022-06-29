// -------------------------------------------------------------------------- //
// Prepare data on UI claims
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Seasonally adjust UI claims data
// -------------------------------------------------------------------------- //

use "$work/01-import-ui/ui-data.dta", clear

generate time = ym(year, month)
tsset time, monthly

// Log-transform
generate x = log(ui_claims)

// Initial estimate of trend
egen trend = filter(x), lags(-6/6) coef(0.5 1 1 1 1 1 1 1 1 1 1 1 0.5) normalize
generate seas_irreg = x - trend
// Filter out outliers from seasonal adjustment estimation
gegen med_seas = median(seas_irreg), by(month)
gegen med_seas_irreg = median(seas_irreg - med_seas)
gegen mad_seas_irreg = median(abs(seas_irreg - med_seas - med_seas_irreg))
generate cval = abs(seas_irreg - med_seas - med_seas_irreg)/(mad_seas_irreg/invnormal(3/4))
generate outliers = cval > invnormal(0.995) & !missing(cval)
generate seas_irreg_noout = seas_irreg if !outlier
drop cval med_seas_irreg mad_seas_irreg med_seas
// Initial estimate of seasonality
egen seas = filter(seas_irreg_noout), lags(-12 0 12) normalize
while (1) {
    replace seas = (L12.seas + F12.seas)/2 if missing(seas)
    replace seas = L12.seas if missing(seas)
    replace seas = F12.seas if missing(seas)
    count if missing(seas)
    if r(N) == 0 {
        continue, break
    }
}
// Initial estimate of seasonally adjusted series
generate seasadj = x - seas
generate irreg = seas_irreg - seas

// Refinements
forvalue i = 1/5 {
    drop trend seas_irreg seas_irreg_noout seas irreg outliers
    
    // New estimate of the trend
    tssmooth ma trend = seasadj, weights(0.5 1 1 1 1 1 <1> 1 1 1 1 1 0.5)
    generate seas_irreg = x - trend
    // New estimate of seasonality
    gegen med_seas = median(seas_irreg), by(month)
    gegen med_seas_irreg = median(seas_irreg - med_seas)
    gegen mad_seas_irreg = median(abs(seas_irreg - med_seas - med_seas_irreg))
    generate cval = abs(seas_irreg - med_seas - med_seas_irreg)/(mad_seas_irreg/invnormal(3/4))
    generate outliers = cval > invnormal(0.995)
    generate seas_irreg_noout = seas_irreg if !outlier
    drop cval med_seas_irreg mad_seas_irreg med_seas
    egen seas = filter(seas_irreg_noout), lags(-12 0 12) normalize
    while (1) {
        replace seas = (L12.seas + F12.seas)/2 if missing(seas)
        replace seas = L12.seas if missing(seas)
        replace seas = F12.seas if missing(seas)
        count if missing(seas)
        if r(N) == 0 {
            continue, break
        }
    }
    // New estimate of seasonally adjusted series
    replace seasadj = x - seas
    generate irreg = seas_irreg - seas
}

// Transform back
generate ui_claims_sa = exp(seasadj)

// Plot seasonal adjustment
preserve
    replace ui_claims = ui_claims/1e6
    replace ui_claims_sa = ui_claims_sa/1e6
    gr tw line ui_claims ui_claims_sa time, xtitle("") ytitle("Claims (million)") ///
        lcol(cranberry ebblue) legend( ///
            label(1 "raw") label(2 "seasonally" "adjusted"))
    graph export "$graphs/02-prepare-ui/ui-claims-seasonal-adjustment.pdf", replace
restore
keep year month time ui_claims ui_claims_sa

save "$work/02-prepare-ui/ui-data-sa.dta", replace

// -------------------------------------------------------------------------- //
// UI data in DINA microfiles to adjust level of monthly series
// -------------------------------------------------------------------------- //

// Save the dates with available UI data
use "$work/02-prepare-ui/ui-data-sa.dta", clear
keep time
duplicates drop
tempfile ui_dates
save "`ui_dates'", replace

// Calculate number of people receiving UI benefits by year
use "$work/01-import-dina/dina-full.dta", clear

summarize year, meanonly
global dina_last_year = r(max)

keep if year >= 1976
gegen uiinc = mean(uiinc), by(year id) replace

generate dina_ui_claims = (uiinc > 0)
gcollapse (sum) dina_ui_claims [pw=dweght], by(year)

tempfile dina_ui
save "`dina_ui'", replace

// Adjust weekly UI data using DINA data
use "$work/02-prepare-ui/ui-data-sa.dta", clear

gcollapse (mean) ui_claims, by(year)
merge 1:1 year using "`dina_ui'", nogenerate

tsset year, yearly

generate chg_dina_ui_claims = log(dina_ui_claims) - log(L.dina_ui_claims)
generate chg_ui_claims      = log(ui_claims) - log(L.ui_claims)

// Remove post-2014 data from the regression because of microfile deficiency
reg chg_dina_ui_claims chg_ui_claims if year <= 2014, nocons
local coef_chg = _b[chg_ui_claims]

use "$work/02-prepare-ui/ui-data-sa.dta", clear

// Adjust change to yearly series
tsset time, monthly
generate chg_ui_claims_sa_adj = `coef_chg'*(log(ui_claims_sa) - log(L.ui_claims_sa))
generate ui_claims_sa_adj = exp(sum(chg_ui_claims_sa_adj))

// Adjust level
merge n:1 year using "`dina_ui'", nogenerate
reg dina_ui_claims ui_claims_sa_adj if year <= 2014, nocons coeflegend
replace ui_claims_sa_adj = _b[ui_claims_sa_adj]*ui_claims_sa_adj

// Plot
preserve
    replace ui_claims_sa_adj = ui_claims_sa_adj/1e6
    replace dina_ui_claims = dina_ui_claims/1e6
    gr tw (line ui_claims_sa_adj time, col(ebblue)) ///
        (sc dina_ui_claims time if month == 7 & year <= 2012, msym(Oh) col(cranberry) msize(small)), ///
        xtitle("") ytitle("Number of claimants (million)") ///
        legend(label(1 "monthly") label(2 "yearly"))
    graph export "$graphs/02-prepare-ui/ui-claims-dina-monthly.pdf", replace
restore

// Clean up
keep year month time ui_claims_sa_adj
rename ui_claims_sa_adj ui_claims

save "$work/02-prepare-ui/ui-data-sa.dta", replace
    
// -------------------------------------------------------------------------- //
// Calculate UI distributions from DINA files
// -------------------------------------------------------------------------- //

use "$work/01-import-dina/dina-full.dta", clear

keep if year >= 1976
keep if uiinc > 0

sort year uiinc

by year: generate rank = sum(dweght)
by year: replace rank = 1e5*(rank - dweght/2)/rank[_N]

// Note: we only go up to the top 1%
egen p = cut(rank), at(0(1000)99000 100001)

gcollapse (mean) avg_uiinc=uiinc [aw=dweght], by(year p)

fillin year p
assert !missing(avg_uiinc)
drop _fillin

save "$work/02-prepare-ui/dina-ui-dist.dta", replace
