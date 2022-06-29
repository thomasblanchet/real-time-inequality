// -------------------------------------------------------------------------- //
// Prepapre FA aggregates to match with DINA
// -------------------------------------------------------------------------- //

use "$work/01-import-fa/fa.dta", clear

// -------------------------------------------------------------------------- //
// Use data on pension funds to split equities/bonds
// -------------------------------------------------------------------------- //

merge 1:1 year quarter using "$work/01-import-ici/ici-data-stocks.dta", nogenerate

generate time = yq(year, quarter)

tsset time, quarterly
tsfill

foreach v of varlist ici_* {
    ipolate `v' time, gen(i)
    gsort -time
    carryforward i, replace
    gsort time
    carryforward i, replace
    replace `v' = i
    drop i
}

generate share_ira_equ = 0.9*(ici_domestic_equity + ici_world_equity + 0.7*ici_hybrid_equity)/(ici_total - ici_money_market)

// -------------------------------------------------------------------------- //
// Make some extrapolations for the last quarter(s)
// -------------------------------------------------------------------------- //

// Variables to extrapolate
local to_extrapolate "fl763131573q fl473131573q lm653131573q lm153131575q fl893131573q lm543131503q"

// Variables to use to make the extrapolation
local ref_fl763131573q "ici_bonds" // IRA deposits at depository insitutions --> Bonds held at IRAs
local ref_fl473131573q "ici_bonds" // IRA deposits at credit unions --> Bonds held at IRAs
local ref_lm653131573q "ici_bonds" // IRA deposits held at mutual funds --> Bonds held at IRAs
local ref_lm153131575q "ici_bonds" // IRA deposits held at other self-directed accounts --> Bonds held at IRAs

local ref_fl893131573q "ici_total" // IRA assets --> IRA assets from ICI
local ref_lm543131503q "ici_total" // IRA assets held at insurance companies --> IRA assets from ICI

sort year quarter
foreach v of local to_extrapolate {
    generate coef = `v'/`ref_`v''
    carryforward coef, replace
    replace `v' = `ref_`v''*coef
    drop coef
}

// -------------------------------------------------------------------------- //
// DINA variables
// -------------------------------------------------------------------------- //

// Import some hisotrical imputations from DINA Excel
replace lm883164133q = . if year <= 1996 // S-corporation equity, not available before 1996
merge 1:1 year quarter using "$work/01-import-dina-macro/dina-wealth-detailed.dta", ///
    update noreplace nogenerate keep(master match match_update match_conflict)

// Assume no IRA assets before the 1980s
replace lm653131573q = 0 if year < 1981 | (year == 1981 & quarter < 4)
replace lm153131575q = 0 if year < 1981 | (year == 1981 & quarter < 4)

replace fl763131573q = 0 if year < 1981 | (year == 1981 & quarter < 4)
replace fl473131573q = 0 if year < 1981 | (year == 1981 & quarter < 4)
replace lm653131573q = 0 if year < 1981 | (year == 1981 & quarter < 4)
replace lm153131575q = 0 if year < 1981 | (year == 1981 & quarter < 4)

replace fl893131573q = 0 if year < 1981 | (year == 1981 & quarter < 4)
replace lm543131503q = 0 if year < 1981 | (year == 1981 & quarter < 4)

replace ici_bonds = 0 if year < 1990
replace ici_money_market = 0 if year < 1990
replace ici_hybrid_equity = 0 if year < 1990

// Housing: owner vs. tenant-occupied
generate fa_housing_owner = lm155035015q
generate fa_housing_tenant = lm115035023q

// Equities: S-corp vs. others (also separate pensions from the rest)
generate fa_equ_scorp = lm883164133q
generate fa_equ_nscorp = lm153064105q /// Corporate equities, directly held
    + lm653064155q /// Corporate equities held through mutual funds
    - lm883164133q /// S-corporation equity
    - lm163064005q /// Corporate equities of non-profits
    - share_ira_equ*(lm653131573q + lm153131575q) // Corporate equities in IRAs

// Fixed income assets: pension + non-pension
generate fa_deposits = fl153030005q /// Time and savings deposits
    + lm153091003q /// Foreign deposits
    - fl163030205q // Non-interest bearing deposits
generate fa_treasury = lm153061105q /// Treasury securities
    + lm153061705q /// agency and GSE-backed securities
    //- 0.7*(lm153061105q + lm153061705q + lm153062005q) // other gov securties (assume 70% of gov + municipal)
generate fa_corpbonds = lm153063005q /// Domestic bonds
    - lm163063005q // Foreign-held bonds
generate fa_loans = fl154023005q /// Loans and security credits
    - fl164023005q /// Loans of non-profits
    - fl163072003q // PPP receivable of non-profits
generate fa_munis_direct = lm153062005q /// Municipal bonds, directly held
    - lm163061005q // Municipal bonds of non-profits
generate fa_munis_indirect = lm653062003q /// Municipal bonds held through mutual funds
    + fl633062000q // Municipal bonds held via MMFs
generate fa_mmf = fl153034005q /// MMFs shares
    - fl633062000q // Municipal bonds held via MMFs
generate fa_bonds_indirect = lm654022055q /// Bonds held through mutual funds
    - lm653062003q /// Municipal bonds held through mutual funds
    + (lm653164205q - lm653064100q - lm654022005q)*lm153064205q/lm653164205q // Other assets held by mutual funds

// Fixed income assets: IRAs only
generate fa_ira_deposits = fl763131573q /// IRA deposits at depository insitutions
    + fl473131573q /// IRA deposits at credit unions
    + 0.1*lm653131573q /// IRA deposits held at mlutual funds
    + 0.1*lm153131575q // IRA deposits held at other self-directed accounts
generate fa_ira_bonds = ici_bonds + 0.3*ici_hybrid_equity
generate fa_ira_mmf = ici_money_market

// Fixed income assets, excluding pensions
generate fa_deposits_noint = fl153020005q - fl163020005q
generate fa_munis = fa_munis_direct + fa_munis_indirect
generate fa_fixed = fa_deposits + fa_treasury + fa_corpbonds ///
    + fa_loans + fa_munis_direct + fa_munis_indirect + fa_deposits_noint ///
    - fa_ira_deposits - fa_ira_bonds

// Business assets
generate fa_business = lm152090205q /// Equity in non-corporate businesses
    - lm115035023q /// Tenant-occupied housing
    + fl113165105q + fl113165405q + fl233165605q // residential mortages
    
// Pension assets
generate fa_pensions = fl592000075q /// Funded DB plans
    + fl594090055q /// DC pensions
    + fl153040005q /// Life insurance reserves
    + fl543150005q /// Annuity reserves held by life insurance companies
    + fl893131573q /// IRA assets
    - lm543131503q // IRA assets held at insurance companies

// Liabilities
generate fa_mortgage_owner = fl153165105q
generate fa_mortgage_tenant = fl113165105q + fl113165405q + fl233165605q
generate fa_nonmortage = fl153166000q /// Consumer credit
    + fl153168005q + fl153169005q + fl543077073q // Other loans + depository institutions loans + deferred premiums
    
// Other assets
generate fa_misc = fl154090005q /// Total financial assets
    - fl154023005q /// Loans and security credits
    - lm153064105q /// Directly held corporate equities
    - fl153034005q /// Money market fund shares
    - lm154022005q /// Directly held bonds
    - fl153030005q - lm153091003q /// Interest-bearing deposits
    - fl153020005q /// Checkable currency & deposits
    - lm152090205q /// Equity in non-corporate businesses
    - lm153064205q /// Mutual funds shares held by households
    - fl153040005q /// Life insurance reserves
    - fl583150005q /// Pension entitlements
    - fl163070005q // Grants and trade receivable

generate fa_bonds_indirect_tax = fa_mmf + fa_bonds_indirect - fa_ira_bonds - fa_ira_mmf

// Fixed assets in DINA include taxable bonds + misc
replace fa_fixed = fa_fixed + fa_bonds_indirect_tax + fa_misc

foreach v of varlist fa_* {
    replace `v' = `v'*1e6
}

keep year quarter fa_housing_tenant fa_housing_owner fa_mortgage_tenant ///
    fa_mortgage_owner fa_equ_scorp fa_equ_nscorp fa_business fa_pensions fa_nonmortage fa_fixed

// -------------------------------------------------------------------------- //
// Monthly disaggregation
// -------------------------------------------------------------------------- //

local to_disaggregate_fa housing_tenant housing_owner mortgage_tenant ///
    mortgage_owner equ_scorp equ_nscorp business pensions nonmortage fixed

preserve
    use "$work/01-import-wealth-indexes/wealth-indexes.dta", clear
    merge 1:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate keepusing(nipa_deflator nipa_pop)
    generate concap = nipa_deflator*nipa_pop
    
    foreach v of varlist caseschiller wilshire {
        generate coef = `v'/concap
        gsort -time
        carryforward coef, replace
        gsort time
        carryforward coef, replace
        replace `v' = concap*coef if missing(`v')
        drop coef 
    }
    keep year month time caseschiller wilshire concap
    
    rename time time_mthly
    tsset time_mthly, monthly
    
    tempfile benchmarks
    save "`benchmarks'", replace
restore

local disag_housing_tenant  "caseschiller"
local disag_housing_owner   "caseschiller"
local disag_mortgage_tenant "concap"
local disag_mortgage_owner  "concap"
local disag_equ_scorp       "wilshire"
local disag_equ_nscorp      "wilshire"
local disag_business        "wilshire"
local disag_pensions        "concap"
local disag_nonmortage      "concap"
local disag_fixed           "concap"

generate time = yq(year, quarter)
tsset time, quarterly
keep if year >= 1974

// Perform disaggregation
foreach v in `to_disaggregate_fa' {
    tempfile `v'
    
    preserve
    drop if missing(fa_`v')
    denton fa_`v' using "``v''", interp(`disag_`v'') from("`benchmarks'") generate(fa_`v'_mthly) stock
    restore
}

use "`benchmarks'", clear

// Merge the disaggregated values
foreach v in `to_disaggregate_fa' {
    merge n:1 time_mthly using "``v''", nogenerate keep(master match)
    // Extrapolate in case the last quarter was not covered
    sort time_mthly
    generate ratio = fa_`v'_mthly/`disag_`v''
    carryforward ratio, replace
    gsort -time_mthly
    carryforward ratio, replace
    gsort time_mthly
    replace fa_`v'_mthly = `disag_`v''*ratio
    drop ratio
}

keep year month fa_*_mthly
renvars fa_*, subst("_mthly" "")
drop if missing(fa_housing_owner)

generate fa_wealth = fa_housing_tenant + fa_housing_owner - fa_mortgage_tenant - ///
    fa_mortgage_owner + fa_equ_scorp + fa_equ_nscorp + fa_business + fa_pensions - fa_nonmortage + fa_fixed

// -------------------------------------------------------------------------- //
// Save
// -------------------------------------------------------------------------- //

save "$work/02-prepare-fa/fa-simplified.dta", replace

gcollapse (mean) fa_*, by(year)
save "$work/02-prepare-fa/fa-simplified-yearly.dta", replace



