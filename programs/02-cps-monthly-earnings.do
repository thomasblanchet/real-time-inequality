// -------------------------------------------------------------------------- //
// Estimate distribution of monthly earnings from CPS
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Clean up CPS
// -------------------------------------------------------------------------- //

use "$work/01-import-cps-monthly/cps-monthly.dta", clear

keep if (year >= 1982) & (eligorg == 1) & (earnweek < 9999.99) & (earnwt > 0)

sort year month earnweek
by year month: generate rank = sum(earnwt)
by year month: replace rank = 1e5*(rank - earnwt/2)/rank[_N]

egen p = cut(rank), at(0(1000)99000 999999)

// Get rid of top 10% (not informative because of top-coding)
drop if p >= 90000

gcollapse (mean) avg_mthly_wages=earnweek [pw=earnwt], by(year month p)
generate version = "CPS"

// -------------------------------------------------------------------------- //
// Make seasonal adjustment
// -------------------------------------------------------------------------- //

generate time = ym(year, month)
tsset p time, monthly

// Log-transform
generate x = log(avg_mthly_wages)

// Initial estimate of trend
egen trend = filter(x), lags(-6/6) coef(0.5 1 1 1 1 1 1 1 1 1 1 1 0.5) normalize
generate seas_irreg = x - trend
// Filter out outliers from seasonal adjustment estimation
gegen med_seas = median(seas_irreg), by(version p month)
gegen med_seas_irreg = median(seas_irreg - med_seas), by(version p)
gegen mad_seas_irreg = median(abs(seas_irreg - med_seas - med_seas_irreg)), by(version p)
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
    gegen med_seas = median(seas_irreg), by(version p month)
    gegen med_seas_irreg = median(seas_irreg - med_seas - med_seas), by(version p)
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

// -------------------------------------------------------------------------- //
// Clean up and save
// -------------------------------------------------------------------------- //

xtset, clear
keep version year month p avg_mthly_wages_sa

save "$work/02-cps-monthly-earnings/cps-monthly-earnings.dta", replace
