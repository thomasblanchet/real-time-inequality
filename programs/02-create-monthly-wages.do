// -------------------------------------------------------------------------- //
// Adjust the level of QCEW series to match that of annual DINA files
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Import DINA data (flemp, equal-split)
// -------------------------------------------------------------------------- //

use "$work/02-add-ssa-wages/dina-ssa-full.dta", clear

// Use SSA flemp variable
replace flemp = flemp_ssa

keep if flemp > 0

sort year flemp
by year: generate rank = sum(dweght)
by year: replace rank = 1e5*(rank - dweght/2)/rank[_N]

egen p = cut(rank), at(0(1000)99000 100001)

gcollapse (mean) flemp [pw=dweght], by(year p)

tempfile dina_flemp
save "`dina_flemp'"

// -------------------------------------------------------------------------- //
// Calculate DINA/QCEW/CPS adjustment
// -------------------------------------------------------------------------- //

use "$work/02-adjust-seasonality-qcew/qcew-tabulations-sa.dta", clear
append using "$work/02-cps-monthly-earnings/cps-monthly-earnings.dta"

drop if version == "SIC" & year > 1990

// Aggregate QCEW wages at year level to make the match
gcollapse (mean) flemp_=avg_mthly_wages_sa, by(year p version)

replace version = strlower(version)

greshape wide flemp_, i(year p) j(version) string

merge 1:1 year p using "`dina_flemp'", nogenerate

generate slope_cps = .
generate const_cps = .
generate wgt_cps = 1/3

generate slope_naics = .
generate const_naics = .
generate wgt_naics = 1/3

generate slope_sic = .
generate const_sic = .
generate wgt_sic = 1/3

levelsof p, local(plist)
foreach p of local plist {
    
    if (`p' < 90000) {
        reg flemp flemp_cps if p == `p', coeflegend
        replace slope_cps = _b[flemp_cps] if p == `p'
        replace const_cps =  _b[_cons] if p == `p'
        
        predict flemp_cps_pred, xb
    }
    
    reg flemp flemp_naics if p == `p', coeflegend
    replace slope_naics = _b[flemp_naics] if p == `p'
    replace const_naics =  _b[_cons] if p == `p'
    
    predict flemp_naics_pred, xb
    
    reg flemp flemp_sic if p == `p', coeflegend
    replace slope_sic = _b[flemp_sic] if p == `p'
    replace const_sic =  _b[_cons] if p == `p'
    
    predict flemp_sic_pred, xb
    
    local pretty_p = strofreal(`p'/1000, "%9.0g")
    
    if (`p' < 90000) {
        /*
        gr tw (line flemp flemp if p == `p', col(back) lw(medthick)) ///
            (scatter flemp_naics_pred flemp_sic_pred flemp_cps_pred flemp if p == `p', col(cranberry ebblue green) msym(Oh Sh Th)), ///
            xtitle("DINA wage (USD)") ytitle("Predicted wage (USD)") ///
            legend(rows(1) label(2 "NAICS") label(3 "SIC") label(4 "CPS") order(2 3 4)) ///
            /*title("DINA vs. QCEW vs. CPS relationship")*/ subtitle("percentile p = `pretty_p'%")
        graph export "$graphs/02-create-monthly-wages/dina-qcew-cps-adj-`p'.pdf", replace
        */
        drop flemp_cps_pred flemp_naics_pred flemp_sic_pred
    }
    else {
        /*
        gr tw (line flemp flemp if p == `p', col(back) lw(medthick)) ///
            (scatter flemp_naics_pred flemp_sic_pred flemp if p == `p', col(cranberry ebblue green) msym(Oh Sh Th)), ///
            xtitle("DINA wage (USD)") ytitle("Predicted wage (USD)") ///
            legend(rows(1) label(2 "NAICS") label(3 "SIC") order(2 3)) ///
            /*title("DINA vs. QCEW vs. CPS relationship")*/ subtitle("percentile p = `pretty_p'%")
        */
        drop flemp_naics_pred flemp_sic_pred
    }
}

keep p slope_* const_* wgt_*
duplicates drop p, force

// Make CPS weights go to zero from p = 80% to p = 90% (not informative because of topcoding)
replace wgt_cps = 0 if p >= 90000
replace wgt_cps = wgt_cps*(1 - (p - 80000)/(90000 - 80000)) if inrange(p, 80000, 89000)

tempfile coefs
save "`coefs'"

// -------------------------------------------------------------------------- //
// Calculate and aggregate predictions
// -------------------------------------------------------------------------- //

use "$work/02-adjust-seasonality-qcew/qcew-tabulations-sa.dta", clear
append using "$work/02-cps-monthly-earnings/cps-monthly-earnings.dta"

drop if version == "SIC" & year > 1990

merge n:1 p using "`coefs'", nogenerate

generate flemp = const_naics + slope_naics*avg_mthly_wages_sa if version == "NAICS"
replace flemp = const_sic + slope_sic*avg_mthly_wages_sa if version == "SIC"
replace flemp = const_cps + slope_cps*avg_mthly_wages_sa if version == "CPS"

generate wgt = wgt_naics if version == "NAICS"
replace wgt = wgt_sic if version == "SIC"
replace wgt = wgt_cps if version == "CPS"

// Aggregate the prediction using the weights
gcollapse (mean) flemp [aw=wgt], by(year month p)

// Export adjusted series
save "$work/02-create-monthly-wages/monthly-tabulations-flemp.dta", replace

// -------------------------------------------------------------------------- //
// Plot prediction accuracy
// -------------------------------------------------------------------------- //

rename flemp flemp_mthly
merge n:1 year p using "`dina_flemp'", nogenerate keep(match)

gcollapse (mean) flemp_mthly flemp, by(year p)

sort year p
by year: generate n = cond(_n == _N, 1e5 - p, p[_n + 1] - p)

merge n:1 year using "$work/02-prepare-nipa/nipa-simplified-yearly.dta", ///
    keep(match) nogenerate keepusing(nipa_deflator)
foreach v of varlist flemp flemp_mthly {
    replace `v' = `v'/nipa_deflator
}
drop nipa_deflator

generate bracket = ""
replace bracket = "bot50" if inrange(p, 0, 49000)
replace bracket = "mid40" if inrange(p, 50000, 89000)
replace bracket = "next9" if inrange(p, 90000, 98000)
replace bracket = "top1"  if inrange(p, 99000, 100000)

gcollapse (sum) flemp_mthly flemp [pw=n], by(year bracket)
foreach v of varlist flemp flemp_mthly {
    egen tot = total(`v'), by(year)
    replace `v' = `v'/tot
    drop tot
}

gegen id = group(bracket)
tsset id year, yearly

generate chg_flemp = 100*(flemp - L.flemp)
generate chg_flemp_mthly = 100*(flemp_mthly - L.flemp)

generate chg2_flemp = 100*(flemp - L2.flemp)
generate chg2_flemp_mthly = 100*(flemp_mthly - L2.flemp)

generate correct_sign = (sign(chg_flemp) == sign(chg_flemp_mthly)) if !missing(chg_flemp) & !missing(chg_flemp_mthly)

// Mark recession years
generate recession = 0
replace recession = 1 if inlist(year, 1980, 1981, 1982, 1990, 1991, 2001, 2008, 2009)
replace recession = 1 if inlist(year, 1983, 1992, 2002, 2010)

// Top 1%
gr tw  (line chg_flemp chg_flemp if bracket == "top1", col(black) lw(medthick)) ///
    (sc chg_flemp chg_flemp_mthly if bracket == "top1", col(ebblue) msym(O)) if year < 2020, ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-1.5 1.5)) yscale(range(-1.5 1.5)) ///
    xlabel(-1.5(0.5)1.5, format(%2.1f)) ylabel(-1.5(0.5)1.5, format(%2.1f)) ///
    xtitle("QCEW + CPS") ///
    ytitle("Tax Data")
graph export "$graphs/02-create-monthly-wages/qcew-cps-accuracy-top1-1y.pdf", replace

gr tw  (line chg2_flemp chg2_flemp if bracket == "top1", col(black) lw(medthick)) ///
    (sc chg2_flemp chg2_flemp_mthly if bracket == "top1", col(ebblue) msym(O)) if year < 2020, ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-2 2)) yscale(range(-2 2)) ///
    xlabel(-2(0.5)2, format(%2.1f)) ylabel(-2(0.5)2, format(%2.1f)) ///
    xtitle("QCEW + CPS") ///
    ytitle("Tax Data")
graph export "$graphs/02-create-monthly-wages/qcew-cps-accuracy-top1-2y.pdf", replace

// Next 9%
gr tw  (line chg_flemp chg_flemp if bracket == "next9", col(black) lw(medthick)) ///
    (sc chg_flemp chg_flemp_mthly if bracket == "next9", col(ebblue) msym(O)) if year < 2020, ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-1.5 1.5)) yscale(range(-1.5 1.5)) ///
    xlabel(-1.5(0.5)1.5, format(%2.1f)) ylabel(-1.5(0.5)1.5, format(%2.1f)) ///
    xtitle("QCEW + CPS") ///
    ytitle("Tax Data")
graph export "$graphs/02-create-monthly-wages/qcew-cps-accuracy-next9-1y.pdf", replace

gr tw  (line chg2_flemp chg2_flemp if bracket == "next9", col(black) lw(medthick)) ///
    (sc chg2_flemp chg2_flemp_mthly if bracket == "next9", col(ebblue) msym(O)) if year < 2020, ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-2 2)) yscale(range(-2 2)) ///
    xlabel(-2(0.5)2, format(%2.1f)) ylabel(-2(0.5)2, format(%2.1f)) ///
    xtitle("QCEW + CPS") ///
    ytitle("Tax Data")
graph export "$graphs/02-create-monthly-wages/qcew-cps-accuracy-next9-2y.pdf", replace

// Middle 40%
gr tw  (line chg_flemp chg_flemp if bracket == "mid40", col(black) lw(medthick)) ///
    (sc chg_flemp chg_flemp_mthly if bracket == "mid40", col(ebblue) msym(O)) if year < 2020, ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-1.5 1.5)) yscale(range(-1.5 1.5)) ///
    xlabel(-1.5(0.5)1.5, format(%2.1f)) ylabel(-1.5(0.5)1.5, format(%2.1f)) ///
    xtitle("QCEW + CPS") ///
    ytitle("Tax Data")
graph export "$graphs/02-create-monthly-wages/qcew-cps-accuracy-mid40-1y.pdf", replace

gr tw  (line chg2_flemp chg2_flemp if bracket == "mid40", col(black) lw(medthick)) ///
    (sc chg2_flemp chg2_flemp_mthly if bracket == "mid40", col(ebblue) msym(O)) if year < 2020, ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-2 2)) yscale(range(-2 2)) ///
    xlabel(-2(0.5)2, format(%2.1f)) ylabel(-2(0.5)2, format(%2.1f)) ///
    xtitle("QCEW + CPS") ///
    ytitle("Tax Data")
graph export "$graphs/02-create-monthly-wages/qcew-cps-accuracy-mid40-2y.pdf", replace

// Bottom 50%
gr tw  (line chg_flemp chg_flemp if bracket == "bot50", col(black) lw(medthick)) ///
    (sc chg_flemp chg_flemp_mthly if bracket == "bot50", col(ebblue) msym(O)) if year < 2020, ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-1.5 1.5)) yscale(range(-1.5 1.5)) ///
    xlabel(-1.5(0.5)1.5, format(%2.1f)) ylabel(-1.5(0.5)1.5, format(%2.1f)) ///
    xtitle("QCEW + CPS") ///
    ytitle("Tax Data")
graph export "$graphs/02-create-monthly-wages/qcew-cps-accuracy-bot50-1y.pdf", replace

gr tw  (line chg2_flemp chg2_flemp if bracket == "bot50", col(black) lw(medthick)) ///
    (sc chg2_flemp chg2_flemp_mthly if bracket == "bot50", col(ebblue) msym(O)) if year < 2020, ///
    aspectratio(1) xsize(4) ysize(4) legend(off) scale(1.2) ///
    xscale(range(-2 2)) yscale(range(-2 2)) ///
    xlabel(-2(0.5)2, format(%2.1f)) ylabel(-2(0.5)2, format(%2.1f)) ///
    xtitle("QCEW + CPS") ///
    ytitle("Tax Data")
graph export "$graphs/02-create-monthly-wages/qcew-cps-accuracy-bot50-2y.pdf", replace

// -------------------------------------------------------------------------- //
// Plot CPS/QCEW consistency
// -------------------------------------------------------------------------- //

use "$work/02-adjust-seasonality-qcew/qcew-tabulations-sa.dta", clear
append using "$work/02-cps-monthly-earnings/cps-monthly-earnings.dta"

replace version = "_" + strlower(version)
rename avg_mthly_wages_sa wage
merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", ///
    keep(match) nogenerate keepusing(nipa_deflator)
replace wage = wage/nipa_deflator
reshape wide wage, i(year month p) j(version) string

generate time = ym(year, month)
tsset p time, monthly

generate growth_qcew = 100*(wage_naics - L12.wage_naics)/L12.wage_naics
generate growth_cps = 100*(wage_cps - L12.wage_cps)/L12.wage_cps

tssmooth ma growth_cps_ma = growth_cps, window(3 1 3)

gr tw line growth_cps growth_cps_ma growth_qcew time if p == 25000 & inrange(year, 1992, 2018), ///
    col(gs13 ebblue cranberry) lw(thin medthick..) xsize(5) ysize(3) scale(1.2) ///
    legend(pos(3) cols(1) label(1 "raw") label(2 "moving" "average") label(3 "raw") ///
        order(- "{bf:CPS}" 1 2 - "" - "" - "{bf:QCEW}" 3)) ///
    xtitle("") ytitle("Year-over-year real growth rate (%)") subtitle("25th Monthly Wage Percentile")
graph export "$graphs/02-create-monthly-wages/qcew-cps-consistency.pdf", replace

// -------------------------------------------------------------------------- //
// Plot DINA comparison
// -------------------------------------------------------------------------- //

use "$work/02-create-monthly-wages/monthly-tabulations-flemp.dta", clear

generate version = "QCEW/CPS"
append using "`dina_flemp'"
replace version = "DINA" if missing(version)

sort version year month p
by version year month: generate n = cond(_n == _N, 1e5 - p, p[_n + 1] - p)

generate bracket = ""
replace bracket = "Bottom 50%" if inrange(p, 00000, 49000)
replace bracket = "Middle 40%" if inrange(p, 50000, 89000)
replace bracket = "Next 9%" if inrange(p, 90000, 98000)
replace bracket = "Top 1%"  if inrange(p, 99000, 99999)

collapse (sum) flemp [pw=n], by(version year month bracket)

egen total = total(flemp), by(version year month)

replace flemp = 100*flemp/total

generate time = ym(year, month)
replace time = ym(year, 7) if version == "DINA"
format time %tm

gr tw /// ///
    (line flemp time if version == "QCEW/CPS", col(ebblue) lw(medthick)) ///
    (scatter flemp time if version == "DINA" & year < 2020, msym(Oh) msize(small) col(cranberry)), ///
    ytitle("share of wage income (%)") xtitle("") xsize(5.5) ysize(3) ///
    by(bracket, rescale note("") scale(1.4) rows(2)) ///
    legend(pos(6) bmargin(zero) ///
        cols(2) label(1 "QCEW + CPS [Monthly]") ///
        label(2 "Public-use Tax Data [Yearly]") ///
        order(2 1) ///
    )
graph export "$graphs/02-create-monthly-wages/flemp-dina-qcew.pdf", replace

gr tw ///
    (sc flemp time if version == "DINA" & bracket == "Top 1%" & year < 2020, msym(Oh) msize(small) lw(medthick) col(cranberry)), ///
    ytitle("Top 1% share of wages (%)") xtitle("") xsize(4) ysize(3)  yscale(range(5 13)) ylabel(5(1)13) ///
    note("") legend(pos(3)) scale(1.3) xlabel(`=ym(1980, 1)'(120)`=ym(2020, 1)') xscale(range(`=ym(1980, 1)' `=ym(2022, 5)')) ///
    legend(pos(6) ///
        rows(1) ///
        label(1 "Annual Tax Data") ///
        order(1) ///
    )
graph export "$graphs/02-create-monthly-wages/flemp-dina-qcew-top1-step1.pdf", replace

gr tw ///
    (sc flemp time if version == "DINA" & bracket == "Top 1%" & year < 2020, msym(Oh) msize(small) lw(medthick) col(cranberry)) ///
    (line flemp time if version == "QCEW/CPS" & bracket == "Top 1%", col(ebblue) lw(medthick)), ///
    ytitle("Top 1% share of wages (%)") xtitle("") xsize(4) ysize(3) yscale(range(5 13)) ylabel(5(1)13) ///
    note("") legend(pos(3)) scale(1.3) xlabel(`=ym(1980, 1)'(120)`=ym(2020, 1)') xscale(range(`=ym(1980, 1)' `=ym(2022, 5)')) ///
    legend(pos(6) ///
        rows(1) label(2 "Monthly Estimate") ///
        label(1 "Annual Tax Data") ///
        order(2 1) ///
    )
graph export "$graphs/02-create-monthly-wages/flemp-dina-qcew-top1-step2.pdf", replace

