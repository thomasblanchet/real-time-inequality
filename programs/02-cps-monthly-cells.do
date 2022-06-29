// -------------------------------------------------------------------------- //
// Estimate employment rates and rank in the income distribution by cell
// from the CPS
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Clean up CPS
// -------------------------------------------------------------------------- //

use "$work/01-import-cps-monthly/cps-monthly.dta", clear

// Weights
generate earnings_sample = (year >= 1982) & (eligorg == 1) & (earnweek < 9999.99) & (earnwt > 0)
generate weight = wtfinl
generate weight_earnings = earnwt if earnings_sample

// Identify couples
generate spouse1 = min(pernum, sploc)
generate spouse2 = max(pernum, sploc)
gegen id = group(year month serial spouse1 spouse2), counts(num)
assert inlist(num, 1, 2)
generate married = cond(num == 1, 0, 1)
drop num

// Employment status
generate is_employed = .
replace is_employed = 1 if inlist(empstat, 01, 10, 12)
replace is_employed = 0 if inlist(empstat, 20, 21, 22, 30, 31, 32, 33, 34, 35, 36)

// Unemployment status
generate is_unemployed = .
replace is_unemployed = 1 if inlist(empstat, 20, 21, 22)
replace is_unemployed = 0 if inlist(empstat, 01, 10, 12, 30, 31, 32, 33, 34, 35, 36)

assert !missing(is_employed) if empstat != 0
assert !missing(is_unemployed) if empstat != 0

// Education level
rename educ educ_full
recode educ_full ///
    (000/019 = 01)  /// No schooling to 4th grade
    (020/039 = 02)  /// 5th to 8th grade
    (040     = 03)  /// 9th grade
    (050     = 04)  /// 10th grade
    (060     = 05)  /// 11th grade
    (070/079 = 06)  /// 12th grade (High School)
    (080/089 = 07)  /// 1 year of college/some college but no degree
    (090/099 = 08)  /// 2 years of college/associate degree
    (100/119 = 09)  /// 3-4 years of college/bachelor degree
    (110/199 = 10), /// 5+ years of college
    generate(educ)
drop educ_full

// Simplify further
replace educ = 1 if inlist(educ, 1, 2) // Less than high school
replace educ = 3 if inlist(educ, 3, 4, 5) // Some high school

// Age group
egen age_group = cut(age), at(20(5)75 999)

// Race
rename race race_full
generate race = .
replace race = 1 if (race_full == 100 & hispan == 0) // Non-hispanic whites
replace race = 2 if (race_full == 200 & hispan == 0) // Non-hispanic blacks
replace race = 3 if inrange(hispan, 1, 699) // Hispanics
replace race = 4 if missing(race) // Others

// Weekly earnings
generate earnings = earnweek if earnings_sample

// Time variable
generate time = ym(year, month)

// Rank in earnings distribution
hashsort year month earnings_sample earnings
by year month earnings_sample: generate rank_earnings = sum(weight_earnings)
by year month earnings_sample: replace rank_earnings = (rank_earnings - weight_earnings/2)/rank_earnings[_N]
// Censor rank for rounded observations
gegen rank_lower = min(rank_earnings), by(year month earnings_sample earnings)
gegen rank_upper = max(rank_earnings), by(year month earnings_sample earnings)
// Censor rank for top-coded observations
gegen rank_max = max(rank_earnings), by(year month earnings_sample)
replace rank_upper = . if rank_upper == rank_max
drop rank_max
// Logistic transform
replace rank_lower = invlogistic(rank_lower)
replace rank_upper = invlogistic(rank_upper)

label drop _all
keep year month time is_employed is_unemployed married educ age_group sex married race ///
    earnings rank_lower rank_upper earnings_sample weight weight_earnings
compress
save "$work/02-cps-monthly-cells/cps-monthly-simplified.dta", replace

// -------------------------------------------------------------------------- //
// Estimate employment probability and earnings rank by cell
// -------------------------------------------------------------------------- //

use "$work/02-cps-monthly-cells/cps-monthly-simplified.dta", clear
glevelsof time, local(times)
clear
save "$work/02-cps-monthly-cells/cps-monthly-employment-cells.dta", replace emptyok
save "$work/02-cps-monthly-cells/cps-monthly-unemployment-cells.dta", replace emptyok
save "$work/02-cps-monthly-cells/cps-monthly-rank-cells.dta", replace emptyok
foreach t of local times {
    di "* " %tm = `t'
    quietly {
        // Employment cells
        use if time == `t' using "$work/02-cps-monthly-cells/cps-monthly-simplified.dta", clear
        
        logit is_employed i.educ i.age_group i.sex##i.married i.race [pw=weight]
        keep year month educ age_group sex married race
        gduplicates drop
        fillin year month educ age_group sex married race
        drop _fillin
        predict employment_rate, pr
        predict employment_rate_stdp, stdp
        
        append using "$work/02-cps-monthly-cells/cps-monthly-employment-cells.dta"
        save "$work/02-cps-monthly-cells/cps-monthly-employment-cells.dta", replace
        
        // Unemployment cells
        use if time == `t' using "$work/02-cps-monthly-cells/cps-monthly-simplified.dta", clear
        
        logit is_unemployed i.educ i.age_group i.sex##i.married i.race [pw=weight]
        keep year month educ age_group sex married race
        gduplicates drop
        fillin year month educ age_group sex married race
        drop _fillin
        predict unemployment_rate, pr
        predict unemployment_rate_stdp, stdp
        
        append using "$work/02-cps-monthly-cells/cps-monthly-unemployment-cells.dta"
        save "$work/02-cps-monthly-cells/cps-monthly-unemployment-cells.dta", replace
        
        // Earnings rank
        use if time == `t' & earnings_sample using "$work/02-cps-monthly-cells/cps-monthly-simplified.dta", clear
        count
        if (r(N) > 0) {
            intreg rank_lower rank_upper i.educ i.age_group i.sex##i.married i.race [pw=weight_earnings]
            keep year month educ age_group sex married race
            gduplicates drop
            fillin year month educ age_group sex married race
            drop _fillin
            predict earnings_rank, xb
            predict earnings_rank_stdp, stdp
            replace earnings_rank_stdp = earnings_rank_stdp*logisticden(earnings_rank)
            replace earnings_rank = logistic(earnings_rank)
                        
            append using "$work/02-cps-monthly-cells/cps-monthly-rank-cells.dta"
            save "$work/02-cps-monthly-cells/cps-monthly-rank-cells.dta", replace
        }
    }
}

// -------------------------------------------------------------------------- //
// Adjust seasonal variations
// -------------------------------------------------------------------------- //

use "$work/02-cps-monthly-cells/cps-monthly-employment-cells.dta", clear
merge 1:1 year month educ age_group sex married race using "$work/02-cps-monthly-cells/cps-monthly-unemployment-cells.dta", nogenerate
merge 1:1 year month educ age_group sex married race using "$work/02-cps-monthly-cells/cps-monthly-rank-cells.dta", nogenerate

generate time = ym(year, month)
gegen id = group(educ age_group sex married race)
tsset id time, monthly

foreach v of varlist unemployment_rate employment_rate earnings_rank {
    replace `v' = invlogistic(`v')
    
    // Initial estimate of trend
    egen trend = filter(`v'), lags(-6/6) coef(0.5 1 1 1 1 1 1 1 1 1 1 1 0.5) normalize
    generate seas_irreg = `v' - trend
    // Filter out outliers from seasonal adjustment estimation
    gegen med_seas = median(seas_irreg), by(id month)
    gegen med_seas_irreg = median(seas_irreg - med_seas), by(id)
    gegen mad_seas_irreg = median(abs(seas_irreg - med_seas - med_seas_irreg)), by(id)
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
        count if missing(seas) & !missing(`v')
        if r(N) == 0 {
            continue, break
        }
    }
    // Initial estimate of seasonally adjusted series
    generate seasadj = `v' - seas

    // Refinements
    forvalue i = 1/5 {
        drop trend seas_irreg seas_irreg_noout seas outliers
        
        // New estimate of the trend
        tssmooth ma trend = seasadj, weights(0.5 1 1 1 1 1 <1> 1 1 1 1 1 0.5)
        
        generate seas_irreg = `v' - trend
        // New estimate of seasonality
        gegen med_seas = median(seas_irreg), by(id month)
        gegen med_seas_irreg = median(seas_irreg - med_seas), by(id)
        gegen mad_seas_irreg = median(abs(seas_irreg - med_seas - med_seas_irreg)), by(id)
        generate cval = abs(seas_irreg - med_seas - med_seas_irreg)/(mad_seas_irreg/invnormal(3/4))
        generate outliers = cval > invnormal(0.995)
        generate seas_irreg_noout = seas_irreg if !outlier
        drop cval med_seas_irreg mad_seas_irreg med_seas
        egen seas = filter(seas_irreg_noout), lags(-12 0 12) normalize
        while (1) {
            replace seas = (L12.seas + F12.seas)/2 if missing(seas)
            replace seas = L12.seas if missing(seas)
            replace seas = F12.seas if missing(seas)
            count if missing(seas) & !missing(`v')
            if r(N) == 0 {
                continue, break
            }
        }
        // New estimate of seasonally adjusted series
        replace seasadj = `v' - seas
    }
    rename seasadj `v'_sa
    drop trend seas_irreg seas_irreg_noout seas outliers
    
    replace `v' = logistic(`v')
    replace `v'_sa = logistic(`v'_sa)
}

gr tw line employment_rate employment_rate_sa time ///
    if race == 1 & sex == 1 & educ == 1 & married == 0 & age_group == 20, ///
    yscale(range(0 1)) sort(time) lw(medthick..) lc(ebblue cranberry) ///
    ylabel(0 "0%" 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" 0.5 "50%" 0.6 "60%" 0.7 "70%" 0.8 "80%" 0.9 "90%" 1 "100%") ///
    xtitle("") ytitle("Employment rate") /*title("Employment rate") subtitle("single white men, 20-24")*/ ///
    legend(rows(1) label(1 "Not seasonally adjusted") label(2 "Seasonally adjusted"))
graph export "$graphs/02-cps-monthly-cells/employment-rate-cell.pdf", replace
    
gr tw line unemployment_rate unemployment_rate_sa time ///
    if race == 1 & sex == 1 & educ == 1 & married == 0 & age_group == 20, ///
    yscale(range(0 0.3)) sort(time) lw(medthick..) lc(ebblue cranberry) ///
    ylabel(0 "0%" 0.05 "5%" 0.1 "10%" 0.15 "15%" 0.2 "20%" 0.25 "25%" 0.3 "30%") ///
    xtitle("") ytitle("Unemployment rate") /*title("Unemployment rate") subtitle("single white men, 20-24")*/ ///
    legend(rows(1) label(1 "Not seasonally adjusted") label(2 "Seasonally adjusted"))
graph export "$graphs/02-cps-monthly-cells/unemployment-rate-cell.pdf", replace
    
gr tw line earnings_rank earnings_rank_sa time ///
    if race == 1 & sex == 1 & educ == 1 & married == 0 & age_group == 20, ///
    yscale(range(0 0.3)) sort(time) lw(medthick..) lc(ebblue cranberry) ///
    ylabel(0 "0%" 0.05 "5%" 0.1 "10%" 0.15 "15%" 0.2 "20%" 0.25 "25%" 0.3 "30%") ///
    xtitle("") ytitle("Earnings rank") /*title("Earnings rank") subtitle("single white men, 20-24")*/ ///
    legend(rows(1) label(1 "Not seasonally adjusted") label(2 "Seasonally adjusted"))
graph export "$graphs/02-cps-monthly-cells/earnings-rank-cell.pdf", replace

keep year month time id sex married educ age_group race time unemployment_rate_sa employment_rate_sa earnings_rank_sa
rename unemployment_rate_sa unemployment_rate
rename employment_rate_sa employment_rate
rename earnings_rank_sa earnings_rank

compress
save "$work/02-cps-monthly-cells/cps-monthly-cells.dta", replace


