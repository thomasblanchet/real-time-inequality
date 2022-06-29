// -------------------------------------------------------------------------- //
// Create a version of the DINA microfiles that can be matched to the NIPA
// -------------------------------------------------------------------------- //

use "$work/02-match-dina-transport/dina-transport-full.dta", clear
keep if year < 2020
merge n:1 year using "$work/01-import-dina-macro/dina-macro-parameters.dta", nogenerate keep(master match) assert(match using) ///
    keepusing(ttfkinc ttfkprk ttfksubk ttproptax_bus ttproptax_res ttfkcot ttdivw ttscorw ttschcpartw ttpenw ttpeniraw fraceqpen ttfkpen_eq ttfpen_fix ttfkpen)
merge n:1 year using "$work/01-import-dina-macro/dina-npinc.dta", nogenerate keep(master match) assert(match using)
merge n:1 year using "$work/01-import-dina-macro/dina-govin.dta", nogenerate keep(master match) assert(match using)
merge n:1 year using "$work/01-import-dina-macro/dina-nmix-proprietors.dta", nogenerate keep(master match) assert(match using)

// -------------------------------------------------------------------------- //
// Use SSA data
// -------------------------------------------------------------------------- //

foreach v of varlist flemp flsup flwag {
    gegen mean_dina = mean(`v') [pw=weight], by(year)
    gegen mean_ssa = mean(`v'_ssa) [pw=weight], by(year)
    replace `v'_ssa = `v'_ssa/mean_ssa*mean_dina
    drop mean_ssa mean_dina
}

replace princ = princ - flemp + flemp_ssa
replace peinc = peinc - flemp + flemp_ssa
replace dicsh = dicsh - flemp + flemp_ssa
replace poinc = poinc - flemp + flemp_ssa
replace flemp = flemp_ssa

// -------------------------------------------------------------------------- //
// Formula for the allocation of business property taxes
// -------------------------------------------------------------------------- //

generate ratio_propbustax = ttproptax_bus/(ttdivw + ttscorw + ttschcpartw + fraceqpen*(ttpenw + ttpeniraw))
// Checks consistency with the microfiles
generate discr = reldif(propbustax, ratio_propbustax*(hwequ + hwbus + fraceqpen*hwpen))
assert abs(discr) < 1e-5 if !missing(discr)
drop discr

// -------------------------------------------------------------------------- //
// Formula for the allocation of production taxes falling on capital:
// fkprk is proportional to fkinc. So we just need to estimate the ratio
// of fkprk to fkinc
// -------------------------------------------------------------------------- //

generate ratio_fkprk = ttfkprk/(ttfkinc - ttfksubk - ttfkprk)
generate ratio_fksubk = ttfksubk/(ttfkinc - ttfksubk - ttfkprk)
// Checks consistency with the microfiles
generate discr = reldif(fkprk, ratio_fkprk*(fkinc - fkprk - fksubk))
assert abs(discr) < 1e-5 if !missing(discr)
replace discr = reldif(fksubk, ratio_fksubk*(fkinc - fkprk - fksubk))
drop discr

// -------------------------------------------------------------------------- //
// Share of pension income coming from equity and fixed-income assets
// -------------------------------------------------------------------------- //

generate share_pen_equ = ttfkpen_eq/ttfkpen
generate share_pen_fix = ttfpen_fix/ttfkpen
// Sums up to 1
generate discr = share_pen_equ + share_pen_fix - 1
assert abs(discr) < 1e-4 if !missing(discr)
drop discr

// -------------------------------------------------------------------------- //
// Share of nonprofit income falling on the different components
// -------------------------------------------------------------------------- //

generate share_npinc_profits = (ttnpinc_div + ttnpinc_nos)/ttnpinc
generate share_npinc_netint  = ttnpinc_int/ttnpinc
// Sums up to 1
generate discr = share_npinc_profits + share_npinc_netint - 1
assert abs(discr) < 1e-4 if !missing(discr)
drop discr

// -------------------------------------------------------------------------- //
// Discrepancy between net mixed income and proprietor's income
// -------------------------------------------------------------------------- //

generate share_nmix_proprietors = ttproprietors/ttnmix
generate share_nmix_profits = ttbustrans/ttnmix
generate share_nmix_rental = (ttroyalties - ttrental_ncor)/ttnmix
// Sums up to 1
generate discr = share_nmix_proprietors + share_nmix_profits + share_nmix_rental - 1
assert abs(discr) < 1e-4 if !missing(discr)
drop discr

// -------------------------------------------------------------------------- //
// Intermediary variables
// -------------------------------------------------------------------------- //

// Busness property taxes falling on corporate vs. noncorporate businesses
generate propbustax_ncor = ratio_propbustax*hwbus
generate propbustax_corp = ratio_propbustax*(hwequ + fraceqpen*hwpen)
generate discr = reldif(propbustax_ncor + propbustax_corp, propbustax)
assert discr < 1e-4 if !missing(discr)
drop discr

// Sales taxes falling on capital
generate fkprk_bus = (ratio_fkprk + ratio_fksubk)*fkbus
generate fkprk_equ = (ratio_fkprk + ratio_fksubk)*(fkequ + share_pen_equ*fkpen)
generate fkprk_fix = (ratio_fkprk + ratio_fksubk)*(fkfix + share_pen_fix*fkpen)
generate fkprk_hou = (ratio_fkprk + ratio_fksubk)*fkhou
generate fkprk_mor = (ratio_fkprk + ratio_fksubk)*fkmor
generate fkprk_nmo = (ratio_fkprk + ratio_fksubk)*fknmo
generate discr = reldif(fkprk_bus + fkprk_equ + fkprk_fix + fkprk_hou + fkprk_mor + fkprk_nmo, fkprk + fksubk)
assert discr < 1e-3 if !missing(discr)
drop discr

// Net mixed income variable (slightly different from proprietor's income)
generate nmix = flmil ///
                + fkbus ///
                - fkprk_bus ///
                - propbustax_ncor
                
// -------------------------------------------------------------------------- //
// Create DINA variables to match to NIPA
// -------------------------------------------------------------------------- //

// Income
generate dina_princ = princ
generate dina_peinc = peinc
generate dina_poinc = poinc
generate dina_dispo = dicsh + invpen
generate dina_flemp = flemp
generate dina_flwag = flwag
generate dina_flsup = flsup

generate dina_contrib  = -plcon
generate dina_uiben    = plobe - 0.8*ssinc_di
generate dina_penben   = plpbe + 0.8*ssinc_di
generate dina_surplus  = prisupen

generate dina_proprietors = flmil + fkbus - propbustax_ncor
generate dina_rental      = fkhou + fkmor - proprestax
generate dina_profits     = fkequ + share_pen_equ*fkpen - propbustax_corp - corptax
generate dina_fkfix       = fkfix + share_pen_fix*fkpen
generate dina_fknmo       = -fknmo
                     
generate dina_govin = govin
generate dina_npinc = npinc
                        
generate dina_corptax = corptax

generate dina_prodtax  = fkprk + flprl + proprestax + propbustax
generate dina_prodsub  = -fksubk - flsubl
generate dina_proptax  = proprestax + propbustax
generate dina_salestax = salestax

generate dina_taxes        = ditax
generate dina_estatetax    = estatetax
generate dina_othercontrib = othercontrib
generate dina_vet          = divet
generate dina_othcash      = dicab - divet
generate dina_govcontrib   = ssuicontrib + othercontrib 

generate dina_medicare = medicare
generate dina_medicaid = medicaid
generate dina_otherkin = otherkin
generate dina_colexp   = colexp

generate dina_prisupenprivate = prisupenprivate
generate dina_prisupgov = prisupgov

// Wealth
generate dina_housing_tenant  = rentalhome
generate dina_housing_owner   = ownerhome_heter
generate dina_mortgage_tenant = -rentalmort
generate dina_mortgage_owner  = -ownermort
generate dina_equ_scorp       = scorw
generate dina_equ_nscorp      = hwequ - scorw
generate dina_business        = hwbus
generate dina_pensions        = hwpen
generate dina_nonmortage      = -nonmort
generate dina_fixed           = hwfix
generate dina_wealth          = hweal

// Sanity checks
generate discr = .

replace discr = reldif(dina_princ, dina_flemp + dina_proprietors + dina_rental + ///
    dina_profits + dina_corptax + dina_fkfix - dina_fknmo + dina_prodtax - dina_prodsub + dina_govin + dina_npinc)
assert discr < 1e-2 if !missing(discr)
    
replace discr = reldif(dina_princ + dina_uiben + dina_penben - dina_contrib + dina_surplus, dina_peinc)
assert discr < 1e-2 if !missing(discr)

replace discr = reldif(dina_dispo, dina_peinc - dina_surplus - dina_govin - dina_npinc - dina_othercontrib ///
    - dina_taxes - dina_estatetax - dina_corptax - dina_prodtax + dina_prodsub + dina_vet + dina_othcash)
assert discr < 2e-2 if !missing(discr)

replace discr = reldif(dina_poinc + dina_salestax - potax, dina_dispo + dina_medicare + dina_medicaid + dina_otherkin ///
    + dina_govin + dina_npinc + dina_colexp + dina_prisupenprivate + dina_prisupgov)
assert discr < 1e-2 if !missing(discr)

// -------------------------------------------------------------------------- //
// Save
// -------------------------------------------------------------------------- //

keep year id weight fiinc uiinc xkidspop married filer acs female age age_group top400 sex race educ dina_*
compress
save "$work/02-prepare-dina/dina-simplified.dta", replace

// -------------------------------------------------------------------------- //
// Version with normalized components
// -------------------------------------------------------------------------- //

use "$work/02-prepare-dina/dina-simplified.dta", clear

foreach v of varlist dina_* {
    gegen avg = mean(`v') [pw=weight], by(year)
    replace `v' = `v'/avg
    drop avg
}
summarize weight, meanonly
replace weight = weight*1e8/r(sum)
compress
save "$work/02-prepare-dina/dina-simplified-normalized.dta", replace

// -------------------------------------------------------------------------- //
// Version with rescaled factor incomes
// -------------------------------------------------------------------------- //

use "$work/02-prepare-dina/dina-simplified.dta", clear

merge n:1 year using "$work/02-prepare-nipa/nipa-simplified-yearly.dta", nogenerate keep(match)

local components flemp contrib uiben penben surplus proprietors rental ///
    profits fkfix govin fknmo corptax prodtax prodsub taxes estatetax othercontrib ///
    vet othcash medicare medicaid otherkin colexp prisupenprivate prisupgov ///
    govcontrib salestax proptax npinc

foreach compo in `components' {
    gegen dina_agg = total(weight*dina_`compo'), by(year)
    replace dina_`compo' = dina_`compo'*(nipa_`compo'/dina_agg)
    drop dina_agg
}

generate dispo2 = dina_flemp + dina_proprietors + dina_rental + dina_profits + dina_corptax + dina_fkfix - dina_fknmo ///
    - dina_contrib - dina_othercontrib - dina_taxes - dina_estatetax - dina_corptax + dina_vet + dina_othcash ///
    + dina_medicare + dina_medicaid
    
generate dina_surplus_ss = dina_surplus - dina_prisupenprivate

gegen ttdispo           = mean(dispo2) [pw=weight], by(year)
gegen ttflemp           = mean(dina_flemp) [pw=weight], by(year)
gegen ttprisupenprivate = mean(dina_prisupenprivate) [pw=weight], by(year)
gegen ttsurplus_ss      = mean(dina_surplus_ss) [pw=weight], by(year)
gegen ttsalestax        = mean(dina_salestax) [pw=weight], by(year)
gegen ttprisupgov       = mean(dina_prisupgov) [pw=weight], by(year)
gegen ttgovin           = mean(dina_govin) [pw=weight], by(year)

replace dina_prisupenprivate = dina_flemp/ttflemp*ttprisupenprivate
replace dina_surplus_ss = dispo2/ttdispo*ttsurplus_ss
replace dina_surplus = dina_prisupenprivate + dina_surplus_ss
replace dina_prisupgov = dispo2/ttdispo*ttprisupgov
replace dina_govin = dispo2/ttdispo*ttgovin

generate dina_potax = dispo2/ttdispo*ttsalestax

generate dina_princ_resc = dina_flemp + dina_proprietors + dina_rental + ///
    dina_profits + dina_corptax + dina_fkfix - dina_fknmo + dina_prodtax - dina_prodsub + dina_govin + dina_npinc
generate dina_peinc_resc = dina_princ_resc + dina_uiben + dina_penben - dina_contrib + dina_surplus
generate dina_dispo_resc = dina_peinc_resc - dina_surplus - dina_govin - dina_npinc - dina_othercontrib ///
    - dina_taxes - dina_estatetax - dina_corptax - dina_prodtax + dina_prodsub + dina_vet + dina_othcash
generate dina_poinc_resc = dina_dispo_resc - dina_salestax + dina_potax + dina_medicare + dina_medicaid + dina_otherkin ///
    + dina_govin + dina_npinc + dina_colexp + dina_prisupenprivate + dina_prisupgov

// Then do wealth
merge n:1 year using "$work/02-prepare-fa/fa-simplified-yearly.dta", nogenerate keep(match)

local components housing_tenant housing_owner mortgage_tenant ///
    mortgage_owner equ_scorp equ_nscorp business pensions nonmortage fixed
    
foreach compo in `components' {
    gegen dina_agg = total(weight*dina_`compo'), by(year)
    replace dina_`compo' = dina_`compo'*(fa_`compo'/dina_agg)
    drop dina_agg
}

generate dina_hweal_resc = dina_housing_tenant + dina_housing_owner - dina_mortgage_tenant - ///
    dina_mortgage_owner + dina_equ_scorp + dina_equ_nscorp + dina_business + dina_pensions - dina_nonmortage + dina_fixed
    
keep year id weight dina_princ_resc dina_peinc_resc dina_dispo_resc dina_poinc_resc dina_hweal_resc
renvars *_resc, postdrop(5)
save "$work/02-prepare-dina/dina-rescaled.dta", replace
    
// -------------------------------------------------------------------------- //
// Check income aggregates against NIPA
// -------------------------------------------------------------------------- //

use "$work/02-prepare-dina/dina-simplified.dta", clear

gcollapse (sum) dina_* [pw=weight], by(year)
merge 1:n year using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate

generate time = ym(year, month)
tsset time, monthly

local to_plot princ peinc poinc dispo flemp contrib uiben penben surplus ///
    proprietors rental profits fkfix govin fknmo corptax prodtax prodsub taxes ///
    estatetax othercontrib vet othcash medicare medicaid otherkin colexp ///
    prisupenprivate prisupgov govcontrib proptax salestax npinc
    
*local to_plot govin
    
local label_princ "Factor national income"
local label_peinc "Pretax national income"
local label_poinc "Post-tax national income"
local label_dispo "Post-tax disposable income"
local label_flemp "Compensation of employees"
local label_contrib "Social contributions"
local label_uiben "Unemployment insurance benefits"
local label_penben "Pension + disability insurance benefits"
local label_surplus "Surplus/deficit of social insurance"
local label_proprietors "Proprietor's income"
local label_rental "Rental income"
local label_profits "Undistributed profits"
local label_fkfix "Interest income"
local label_govin "Government interest income"
local label_fknmo "Nonmortage interest payments"
local label_corptax "Corporate tax"
local label_prodtax "Production taxes"
local label_prodsub "Subsidies"
local label_taxes "Current taxes on income and wealth"
local label_estatetax "Estate tax"
local label_othercontrib "Non social security contributions"
local label_vet "Veteran benefits"
local label_othcash "Other cash benefits"
local label_medicare "Medicare"
local label_medicaid "Medicaid"
local label_otherkin "Other in-kind transfers"
local label_colexp "Collective expenditures"
local label_prisupenprivate "Surplus/deficit of private insurance system"
local label_prisupgov "Surplus/deficit of governement"
local label_govcontrib "Contribution to governement social insurance"
local label_proptax "Property taxes"
local label_salestax "Sales taxes"
local label_npinc "Income of nonprofits"

foreach v of local to_plot {
    generate a = 100*nipa_`v'/nipa_princ
    generate b = 100*dina_`v'/dina_princ
    
    gr tw (line a time, col(ebblue)) ///
        (scatter b time if month == 7, col(cranberry) msym(Oh) msize(small)), ///
        legend(off) xtitle("") ytitle("% of national income") ///
        title("`label_`v''")
    graph export "$graphs/02-prepare-dina/dina-vs-nipa-`v'.pdf", replace
    
    drop a b
}

// -------------------------------------------------------------------------- //
// Check wealth aggregates against FA
// -------------------------------------------------------------------------- //

use "$work/02-prepare-dina/dina-simplified.dta", clear

gcollapse (sum) dina_* [pw=weight], by(year)
merge 1:n year using "$work/02-prepare-fa/fa-simplified.dta", nogenerate
merge 1:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate keepusing(nipa_princ)

generate time = ym(year, month)
tsset time, month

local to_plot housing_tenant housing_owner mortgage_tenant mortgage_owner ///
    equ_scorp equ_nscorp business pensions nonmortage fixed
    
local label_housing_tenant "Tenant-occupied housing"
local label_housing_owner "Owner-occupied housing"
local label_mortgage_tenant "Mortgages for tenant-occupied housing"
local label_mortgage_owner "Mortgages for owner-occupied housing"
local label_equ_scorp "Equity of in S-corporation"
local label_equ_nscorp "Equity of in corporations other than S-corporations"
local label_business "Business assets"
local label_pensions "Pensions"
local label_nonmortage "Debt (excl. mortgages)"
local label_fixed "Fixed-income assets"
local label_wealth "Wealth"

generate a = 100*fa_wealth/nipa_princ
generate b = 100*dina_wealth/dina_princ

gr tw (line a time, col(ebblue)) ///
    (scatter b time if month == 7, col(cranberry) msym(Oh) msize(small)), ///
    legend(off) xtitle("") ytitle("% of national income") ///
    title("`label_wealth'")
graph export "$graphs/02-prepare-dina/dina-vs-fa-wealth.pdf", replace
drop a b

foreach v of local to_plot {
    generate a = 100*fa_`v'/fa_wealth
    generate b = 100*dina_`v'/dina_wealth
    
    gr tw (line a time, col(ebblue)) ///
        (scatter b time if month == 7, col(cranberry) msym(Oh) msize(small)), ///
        legend(off) xtitle("") ytitle("% of national wealth") ///
        title("`label_`v''")
    graph export "$graphs/02-prepare-dina/dina-vs-fa-`v'.pdf", replace
    
    drop a b
}

// -------------------------------------------------------------------------- //
// Plot: source of variation in top shares, fixed income & corporate profits
// -------------------------------------------------------------------------- //

use "$work/02-prepare-dina/dina-simplified.dta", clear

generate princ = dina_princ
generate profits = max(dina_profits + dina_corptax, 0)
generate fkfix = max(dina_fkfix, 0)
generate rental = max(dina_rental, 0)
generate proprietors = max(dina_proprietors, 0)

gcollapse (mean) princ profits fkfix rental proprietors (sum) weight, by(year id)

sort year princ
by year: generate rank = sum(weight)
by year: replace rank = (rank - weight/2)/rank[_N]

generate bracket = cond(rank >= 0.9, "_top", "_bot")

gcollapse (sum) princ profits fkfix rental proprietors [pw=weight], by(year bracket)

reshape wide princ profits fkfix rental proprietors, i(year) j(bracket) string

generate quarter = 1

merge 1:1 year quarter using "$work/02-prepare-nipa/nipa-simplified-quarterly.dta", ///
    nogenerate keepusing(quarter nipa_princ nipa_profits nipa_corptax nipa_fkfix nipa_proprietors nipa_rental)
replace nipa_profits = nipa_profits + nipa_corptax

foreach v in profits fkfix rental proprietors {
    generate share_`v'_top = `v'_top/(`v'_top + `v'_bot)
    generate share_`v'_tot = nipa_`v'/nipa_princ
}

keep year quarter share_*

keep if inrange(year, 1976, 2019)
sort year quarter

foreach v of varlist share_* {
    generate ref = `v'[1]
    replace `v' = 100*`v'/ref
    drop ref
}

generate time = yq(year, quarter)
format time %tq

gr tw (con share_profits_tot share_profits_top time, lw(medthick..) msize(small..) msym(Oh none) msize(small..) col(cranberry ebblue)) ///
    (pcarrowi 129 `=yq(1992, 1)' 115 `=yq(1995, 1)', col(cranberry) lw(medthick)) ///
    (pcarrowi 82 `=yq(2012, 1)' 96 `=yq(2010, 1)', col(ebblue) lw(medthick)), ///
    xlabel(`=yq(1980, 1)'(40)`=yq(2010, 1)') xtitle("") ylabel(70(10)140) ytitle("Index (1976 = 100)") legend(off) ///
    text(135 `=yq(1990, 1)' "The national income’s share" "of {bf:pretax corporate profits}" "is {bf:highly volatile}", col(cranberry)) ///
    text(75 `=yq(2012, 1)' "The share of" "{bf:pretax corporate profits}" "earned by the top 10%" "is {bf:comparatively stable}", col(ebblue))
graph export "$graphs/02-prepare-dina/volatility-profits.pdf", replace

gr tw (con share_fkfix_tot share_fkfix_top time, lw(medthick..) msize(small..) msym(Oh none) msize(small..) col(cranberry ebblue)) ///
    (pcarrowi 152 `=yq(2003, 1)' 125 `=yq(1999, 1)', col(cranberry) lw(medthick)) ///
    (pcarrowi 91 `=yq(1987, 1)' 105 `=yq(1990, 1)', col(ebblue) lw(medthick)), ///
    xlabel(`=yq(1980, 1)'(40)`=yq(2010, 1)') xtitle("") ylabel(70(10)170) ytitle("Index (1976 = 100)") legend(off) ///
    text(160 `=yq(2007, 1)' "The national income’s share" "of {bf:interest income}" "is {bf:highly volatile}", col(cranberry)) ///
    text(82 `=yq(1987, 1)' "The share of" "{bf:interest income}" "earned by the top 10%" "is {bf:comparatively stable}", col(ebblue))
graph export "$graphs/02-prepare-dina/volatility-interest.pdf", replace

gr tw (con share_proprietors_tot share_proprietors_top time, lw(medthick..) msize(small..) msym(Oh none) msize(small..) col(cranberry ebblue)) ///
    (pcarrowi 110 `=yq(1995, 1)' 105 `=yq(2000, 1)', col(cranberry) lw(medthick)) ///
    (pcarrowi 87 `=yq(2007, 1)' 100 `=yq(2003, 1)', col(ebblue) lw(medthick)), ///
    xlabel(`=yq(1980, 1)'(40)`=yq(2010, 1)') xtitle("") ylabel(70(10)120) ytitle("Index (1976 = 100)") legend(off) ///
    text(110 `=yq(1987, 1)' "The national income’s share" "of {bf:proprietor's income}" "is {bf:highly volatile}", col(cranberry)) ///
    text(82 `=yq(2007, 1)' "The share of" "{bf:proprietor's income}" "earned by the top 10%" "is {bf:comparatively stable}", col(ebblue))
graph export "$graphs/02-prepare-dina/volatility-proprietors.pdf", replace

gr tw (con share_rental_tot share_rental_top time, lw(medthick..) msize(small..) msym(Oh none) msize(small..) col(cranberry ebblue)) ///
    (pcarrowi 265 `=yq(1994, 1)' 210 `=yq(1997, 1)', col(cranberry) lw(medthick)) ///
    (pcarrowi 50 `=yq(2003, 1)' 100 `=yq(2000, 1)', col(ebblue) lw(medthick)), ///
    xlabel(`=yq(1980, 1)'(40)`=yq(2010, 1)') xtitle("") ylabel(0(100)400) ytitle("Index (1976 = 100)") legend(off) ///
    text(300 `=yq(1990, 1)' "The national income’s share" "of {bf:rental income}" "is {bf:highly volatile}", col(cranberry)) ///
    text(50 `=yq(2010, 1)' "The share of" "{bf:rental income}" "earned by the top 10%" "is {bf:comparatively stable}", col(ebblue))
graph export "$graphs/02-prepare-dina/volatility-rental.pdf", replace

// Lighter legends, for paper
gr tw (con share_profits_tot share_profits_top time, lw(medthick..) msize(small..) msym(Oh none) msize(small..) col(cranberry ebblue)) ///
    (pcarrowi 129 `=yq(1992, 1)' 115 `=yq(1995, 1)', col(cranberry) lw(medthick)) ///
    (pcarrowi 82 `=yq(2012, 1)' 96 `=yq(2010, 1)', col(ebblue) lw(medthick)), ///
    scale(1.2) xlabel(`=yq(1980, 1)'(40)`=yq(2010, 1)') xtitle("") ylabel(70(10)140) ytitle("Index (1976 = 100)") legend(off) ///
    text(135 `=yq(1990, 1)' "National income’s share" "of {bf:pretax corporate profits}", col(cranberry)) ///
    text(75 `=yq(2010, 1)' "Share of" "{bf:pretax corporate profits}" "earned by the top 10%", col(ebblue))
graph export "$graphs/02-prepare-dina/volatility-profits-paper.pdf", replace

gr tw (con share_fkfix_tot share_fkfix_top time, lw(medthick..) msize(small..) msym(Oh none) msize(small..) col(cranberry ebblue)) ///
    (pcarrowi 152 `=yq(2003, 1)' 125 `=yq(1999, 1)', col(cranberry) lw(medthick)) ///
    (pcarrowi 91 `=yq(1987, 1)' 105 `=yq(1990, 1)', col(ebblue) lw(medthick)), ///
    scale(1.2) xlabel(`=yq(1980, 1)'(40)`=yq(2010, 1)') xtitle("") ylabel(70(10)170) ytitle("Index (1976 = 100)") legend(off) ///
    text(160 `=yq(2007, 1)' "National income’s share" "of {bf:interest income}", col(cranberry)) ///
    text(82 `=yq(1987, 1)' "Share of" "{bf:interest income}" "earned by the top 10%", col(ebblue))
graph export "$graphs/02-prepare-dina/volatility-interest-paper.pdf", replace

gr tw (con share_proprietors_tot share_proprietors_top time, lw(medthick..) msize(small..) msym(Oh none) msize(small..) col(cranberry ebblue)) ///
    (pcarrowi 110 `=yq(1995, 1)' 105 `=yq(2000, 1)', col(cranberry) lw(medthick)) ///
    (pcarrowi 87 `=yq(2007, 1)' 100 `=yq(2003, 1)', col(ebblue) lw(medthick)), ///
    scale(1.2) xlabel(`=yq(1980, 1)'(40)`=yq(2010, 1)') xtitle("") ylabel(70(10)120) ytitle("Index (1976 = 100)") legend(off) ///
    text(110 `=yq(1985, 1)' "National income’s share" "of {bf:proprietors’ income}", col(cranberry)) ///
    text(82 `=yq(2007, 1)' "Share of" "{bf:proprietor's income}" "earned by the top 10%", col(ebblue))
graph export "$graphs/02-prepare-dina/volatility-proprietors-paper.pdf", replace

gr tw (con share_rental_tot share_rental_top time, lw(medthick..) msize(small..) msym(Oh none) msize(small..) col(cranberry ebblue)) ///
    (pcarrowi 265 `=yq(1994, 1)' 210 `=yq(1997, 1)', col(cranberry) lw(medthick)) ///
    (pcarrowi 50 `=yq(2003, 1)' 100 `=yq(2000, 1)', col(ebblue) lw(medthick)), ///
    scale(1.2) xlabel(`=yq(1980, 1)'(40)`=yq(2010, 1)') xtitle("") ylabel(0(100)400) ytitle("Index (1976 = 100)") legend(off) ///
    text(300 `=yq(1990, 1)' "National income’s share" "of {bf:rental income}", col(cranberry)) ///
    text(50 `=yq(2010, 1)' "Share of" "{bf:rental income}" "earned by the top 10%", col(ebblue))
graph export "$graphs/02-prepare-dina/volatility-rental-paper.pdf", replace
