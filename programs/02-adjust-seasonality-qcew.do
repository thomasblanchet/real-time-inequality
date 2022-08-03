// -------------------------------------------------------------------------- //
// Adjust QCEW series for seasonality
// -------------------------------------------------------------------------- //

use "$work/02-tabulate-qcew/qcew-tabulations.dta", clear

// -------------------------------------------------------------------------- //
// Create panel
// -------------------------------------------------------------------------- //

// Drop the first year of data for each version, foreach the 12-month moving
// average of wages gives leads to missing values
drop if year == 1975 & version == "SIC"
drop if year == 1990 & version == "NAICS"

generate time = monthly(strofreal(year) + "m" + strofreal(month), "YM")
gegen id = group(version p)
xtset id time, monthly

// -------------------------------------------------------------------------- //
// Make seasonal adjustment
// -------------------------------------------------------------------------- //

// Log-transform
generate x = log(avg_mthly_wages)

// Initial estimate of trend
egen trend = filter(x), lags(-6/6) coef(0.5 1 1 1 1 1 1 1 1 1 1 1 0.5) normalize
generate seas_irreg = x - trend
// Filter out outliers from seasonal adjustment estimation
gegen med_seas = median(seas_irreg), by(version p month)
gegen med_seas_irreg = median(seas_irreg - med_seas - med_seas), by(version p)
gegen mad_seas_irreg = median(abs(seas_irreg - med_seas - med_seas_irreg)), by(version p)
generate cval = abs(seas_irreg - med_seas - med_seas_irreg)/(mad_seas_irreg/invnormal(3/4))
generate outliers = cval > invnormal(0.995) & !missing(cval)
generate seas_irreg_noout = seas_irreg if !outlier
drop cval med_seas_irreg mad_seas_irreg med_seas
// Initial estimate of seasonality
egen seas = filter(seas_irreg_noout), lags(-12 0 12) normalize
while (1) {
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
    gegen med_seas = median(seas_irreg), by(version p month)
    gegen med_seas_irreg = median(seas_irreg - med_seas), by(version p)
    gegen mad_seas_irreg = median(abs(seas_irreg - med_seas - med_seas_irreg)), by(version p)
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
generate avg_mthly_wages_sa = exp(seasadj)
gr tw line avg_mthly_wages avg_mthly_wages_sa time if p == 30000 & version == "NAICS", ///
    lw(medthick..) lcol(ebblue cranberry) xtitle("") ytitle("Current USD") ///
    legend(label(1 "p = 30%, raw") label(2 "p = 30%, seasonally adjusted"))
graph export "$graphs/02-adjust-seasonality-qcew/seasadj-qcew.pdf", replace

xtset, clear
keep version year month p avg_mthly_wages_sa

// -------------------------------------------------------------------------- //
// Save
// -------------------------------------------------------------------------- //

save "$work/02-adjust-seasonality-qcew/qcew-tabulations-sa.dta", replace
