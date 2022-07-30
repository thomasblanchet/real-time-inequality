// -------------------------------------------------------------------------- //
// Create monthly NIPA files
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Monthly series
// -------------------------------------------------------------------------- //

// Table 2.6. Personal Income and Its Disposition, Monthly
// -------------------------------------------------------
//
// (=) a065rc [Equals: Personal income]
//     (+) a033rc [Compensation of employees]
//         (+) a034rc [Wages and salaries]
//             (+) b202rc [Government]
//             (+) [Other]
//         (+) a038rc [Supplements to wages and salaries]
//             (+) b040rc [Employer contributions for employee pension and insurance funds]
//             (+) b039rc [Employer contributions for government social insurance]
//     (+) a041rc [Proprietors' income with inventory valuation and capital consumption adjustments]
//     (+) a048rc [Rental income of persons with capital consumption adjustment]
//     (+) w210rc [Personal income receipts on assets]
//         (+) a064rc [Personal interest income]
//         (+) b703rc [Personal dividend income]
//     (+) a577rc [Personal current transfer receipts]
//         (+) a063rc [Government social benefits to persons]
//             (+) w823rc [Social security]
//             (+) w824rc [Medicare]
//             (+) w729rc [Medicaid]
//             (+) w825rc [Unemployment insurance]
//             (+) w826rc [Veterans' benefits]
//             (+) w827rc [Other]
//         (+) b931rc [Other current transfer receipts, from business (net)]
//     (-) a061rc [Contributions for government social insurance, domestic]
// (-) w055rc [Less: Personal current taxes]
// (=) a067rc [Equals: Disposable personal income]
// (-) a068rc [Less: Personal outlays]
//     (+) dpcerc [Personal consumption expenditures]
//     (+) b069rc [Personal interest payments]
//     (+) w211rc [Personal current transfer payments]
// (=) a071rc [Personal saving]
//
// Addenda:
// (=) b230rc [Population (midperiod, thousands)]
// (=) dpcerg [Personal consumption expenditures, price index]

use "$work/01-import-nipa/nipa-monthly-series.dta", clear

replace series_code = strlower(series_code)

generate to_keep = 0
replace to_keep = 1 if series_code == "a065rc"
replace to_keep = 1 if series_code == "a033rc"
replace to_keep = 1 if series_code == "a034rc"
replace to_keep = 1 if series_code == "b202rc"
replace to_keep = 1 if series_code == "a038rc"
replace to_keep = 1 if series_code == "b040rc"
replace to_keep = 1 if series_code == "b039rc"
replace to_keep = 1 if series_code == "a041rc"
replace to_keep = 1 if series_code == "a048rc"
replace to_keep = 1 if series_code == "w210rc"
replace to_keep = 1 if series_code == "a064rc"
replace to_keep = 1 if series_code == "b703rc"
replace to_keep = 1 if series_code == "a577rc"
replace to_keep = 1 if series_code == "a063rc"
replace to_keep = 1 if series_code == "w823rc"
replace to_keep = 1 if series_code == "w824rc"
replace to_keep = 1 if series_code == "w729rc"
replace to_keep = 1 if series_code == "w825rc"
replace to_keep = 1 if series_code == "w826rc"
replace to_keep = 1 if series_code == "w827rc"
replace to_keep = 1 if series_code == "b931rc"
replace to_keep = 1 if series_code == "a061rc"
replace to_keep = 1 if series_code == "w055rc"
replace to_keep = 1 if series_code == "a067rc"
replace to_keep = 1 if series_code == "a068rc"
replace to_keep = 1 if series_code == "dpcerc"
replace to_keep = 1 if series_code == "b069rc"
replace to_keep = 1 if series_code == "w211rc"
replace to_keep = 1 if series_code == "a071rc"
replace to_keep = 1 if series_code == "b230rc"
replace to_keep = 1 if series_code == "dpcerg"
keep if to_keep
drop to_keep

// Reshape
replace series_code = strlower(series_code)
replace value = 1e6*value if series_code != "b230rc" & series_code != "dpcerg"
replace value = 1e3*value if series_code == "b230rc"

greshape wide value, i(year month) j(series_code) string
renvars value*, predrop(5)

// Sanity checks
generate discr = reldif(a033rc + a041rc + a048rc + w210rc + a577rc - a061rc, a065rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(a034rc + a038rc, a033rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(b040rc + b039rc, a038rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(a064rc + b703rc, w210rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(a063rc + b931rc, a577rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(w823rc + w824rc + w729rc + w825rc + w826rc + w827rc, a063rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(a065rc - w055rc, a067rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(dpcerc + b069rc + w211rc, a068rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(a067rc - a068rc, a071rc)
assert discr < 1e-3 if !missing(discr)
drop discr

// Create a personal net interest variable (to disaggregate the quarterly 'net interest')
generate a064rc_b069rc = a064rc - b069rc

// Create a variable "population times price level" to serve a default in
// disaggration procedure
generate concap = dpcerg*b230rc

// Add data for COVID aid
merge 1:1 year month using "$work/01-import-aid-covid/covid-aid-monthly.dta", nogenerate
replace covid_relief = 0 if missing(covid_relief)
replace ppp_proprietors = 0 if missing(ppp_proprietors)

generate time_mthly = ym(year, month), after(month)
tsset time_mthly, monthly

tempfile nipa_monthly
save "`nipa_monthly'", replace

// -------------------------------------------------------------------------- //
// Quarterly series
// -------------------------------------------------------------------------- //

// Table 1.12. National Income by Type of Income
// ---------------------------------------------
//
// (=) a032rc [National income]
//     (+) a033rc [Compensation of employees]
//         (+) a034rc [Wages and salaries]
//             (+) b202rc [Government]
//             (+) [Other]
//         (+) a038rc [Supplements to wages and salaries]
//             (+) b040rc [Employer contributions for employee pension and insurance funds]
//             (+) b039rc [Employer contributions for government social insurance]
//     (+) a041rc [Proprietors' income with inventory valuation and capital consumption adjustments]
//     (+) a048rc [Rental income of persons with capital consumption adjustment]
//     (+) a051rc [Corporate profits with inventory valuation and capital consumption adjustments]
//         (+) a054rc [Taxes on corporate income]
//         (+) a551rc [Profits after tax with inventory valuation and capital consumption adjustments]
//     (+) w255rc [Net interest and miscellaneous payments on assets]
//     (+) w056rc [Taxes on production and imports]
//     (-) a107rc [Subsidies]
//     (+) b029rc [Business current transfer payments (net)]
//     (+) a108rc [Current surplus of government enterprises]
//
// Addenda:
// (=) a191rc [GDP]
// (=) a191rd [Implicit price deflator, GDP]
//
// Variables to forecast profits in last quarter:
// (=) a261rc [Gross Domestic Income]
//     (+) a4002c [Compensation of employees, paid]
//     (+) w056rc [Taxes on production and imports]
//     (-) a107rc [Subsidies]
//     (+) w272rc [Net interest and miscellaneous payments, domestic industries]
//     (+) a445rc [Corporate profits with inventory valuation and capital consumption adjustments, domestic industries]
//     (+) b029rc [Business current transfer payments (net)]
//     (+) a041rc [Proprietors' income with inventory valuation and capital consumption adjustments]
//     (+) a048rc [Rental income of persons with capital consumption adjustment]
//     (+) a108rc [Current surplus of government enterprises]
//     (+) a262rc [Consumption of fixed capital]
// (=) a191rc [GDP]
//     (+) a030rc [Statistical discrepancy]
//     (+) a261rc [Gross Domestic Income]
//
// Table 1.14. Gross Value Added of Domestic Corporate Business
// ------------------------------------------------------------
// 
// (*) w323rc [Business current transfer payments (net)]
// (*) a453rc [Net interest and miscellaneous payments]
//
// Table 3.1. Government Current Receipts and Expenditures
// -------------------------------------------------------
//
// (=) [Government surplus/deficit]
//     (+) w055rc [Personal current taxes]
//     (+) w056rc [Taxes on production and imports]
//     (+) a054rc [Taxes on corporate income]
//     (+) a061rc [Contributions for government social insurance, domestic]
//     (-) a107rc [Subsidies]
//     (+) a108rc [Current surplus of government enterprises]
//     (+) w067rc [Capital transfers receipts = estate tax revenue]
//     (-) a955rc [Consumption expenditures]
//     (-) w063rc [Government social benefits]
//
// (=) [Government net property income]
//     (+) w058rc [Income receipts on assets]
//     (-) a180rc [Interest payments]
//
// (*) w065rc [Dividends received by government]

use "$work/01-import-nipa/nipa-quarterly-series.dta", clear

replace series_code = strlower(series_code)

generate to_keep = 0
replace to_keep = 1 if series_code == "a261rc"
replace to_keep = 1 if series_code == "a4002c"
replace to_keep = 1 if series_code == "w272rc"
replace to_keep = 1 if series_code == "a445rc"
replace to_keep = 1 if series_code == "a262rc"
replace to_keep = 1 if series_code == "a030rc"
replace to_keep = 1 if series_code == "a191rc"
replace to_keep = 1 if series_code == "a032rc"
replace to_keep = 1 if series_code == "a033rc"
replace to_keep = 1 if series_code == "a034rc"
replace to_keep = 1 if series_code == "b202rc"
replace to_keep = 1 if series_code == "a038rc"
replace to_keep = 1 if series_code == "b040rc"
replace to_keep = 1 if series_code == "b039rc"
replace to_keep = 1 if series_code == "a041rc"
replace to_keep = 1 if series_code == "a048rc"
replace to_keep = 1 if series_code == "a051rc"
replace to_keep = 1 if series_code == "a054rc"
replace to_keep = 1 if series_code == "a551rc"
replace to_keep = 1 if series_code == "w255rc"
replace to_keep = 1 if series_code == "w056rc"
replace to_keep = 1 if series_code == "a107rc"
replace to_keep = 1 if series_code == "b029rc"
replace to_keep = 1 if series_code == "a108rc"
replace to_keep = 1 if series_code == "con520"
replace to_keep = 1 if series_code == "trp250"
replace to_keep = 1 if series_code == "b1044c"
replace to_keep = 1 if series_code == "a191rd"
replace to_keep = 1 if series_code == "w067rc"
replace to_keep = 1 if series_code == "w058rc"
replace to_keep = 1 if series_code == "a180rc"
replace to_keep = 1 if series_code == "w054rc"
replace to_keep = 1 if series_code == "w782rc"
replace to_keep = 1 if series_code == "a955rc"
replace to_keep = 1 if series_code == "w063rc"
replace to_keep = 1 if series_code == "w008rc"
replace to_keep = 1 if series_code == "w323rc"
replace to_keep = 1 if series_code == "w065rc"
replace to_keep = 1 if series_code == "a453rc"
keep if to_keep
drop to_keep

// Reshape
replace value = 1e6*value if series_code != "a191rd"

greshape wide value, i(year quarter) j(series_code) string
renvars value*, predrop(5)

// Sanity checks
generate discr = reldif(a033rc + a041rc + a048rc + a051rc + w255rc + w056rc - a107rc + b029rc + a108rc, a032rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(a4002c + w056rc - a107rc + w272rc + a445rc + b029rc + a041rc + a048rc + a108rc + a262rc, a261rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(a191rc, a261rc + a030rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(a034rc + a038rc, a033rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(a034rc + a038rc, a033rc)
assert discr < 1e-5 if !missing(discr)

replace discr = reldif(a034rc + a038rc, a033rc)
assert discr < 1e-5 if !missing(discr)
drop discr

// Fix big glitches in the estate tax data
replace w067rc = . if year == 2017 & quarter == 4

generate time = yq(year, quarter)
tsset time, quarterly

ipolate w067rc time, gen(i)
replace w067rc = i
drop i
tsset, clear
drop time

// Add data for COVID aid
merge 1:1 year quarter using "$work/01-import-aid-covid/covid-aid-quarterly.dta", nogenerate
replace covid_subsidies = 0 if missing(covid_subsidies)
replace covid_ppp = 0 if missing(covid_ppp)

// Extrapolate profits with GDP in last quarter if needed
// To that end: impute statistical discrepancy & foreign capital incomes
generate time = yq(year, quarter)
format time %tq
tsset time, quarterly

// Assume same growth for GDP and national income
replace a032rc = L.a032rc*(a191rc/L.a191rc) if missing(a032rc)
// Get corporate profits from this
replace a051rc = a032rc - (a033rc + a041rc + a048rc + w255rc + w056rc - a107rc + b029rc + a108rc) if missing(a051rc)
// Split corporate tax
replace a054rc = a051rc*(L.a054rc/L.a051rc) if missing(a054rc)
replace a551rc = a051rc*(L.a551rc/L.a051rc) if missing(a551rc)

generate gdp_growth = 100*(((a191rc/a191rd)/(L.a191rc/L.a191rd))^4 - 1)
generate gdi_growth = 100*(((a261rc/a191rd)/(L.a261rc/L.a191rd))^4 - 1)

generate time_label = strofreal(year) + "Q" + strofreal(quarter)
generate label_pos = 3
replace label_pos = 5 if time_label == "2020Q2"
replace label_pos = 3 if time_label == "2022Q1"
replace label_pos = 2 if time_label == "2021Q4"
replace label_pos = 10 if time_label == "2021Q2"
replace label_pos = 3 if time_label == "2021Q3"
replace label_pos = 4 if time_label == "2021Q1"

gr tw (sc gdp_growth gdi_growth if year < 2020, col(ebblue)) ///
    (sc gdp_growth gdi_growth if year >= 2020 & !inlist(time_label, "2020Q2"), col(cranberry) msym(T) mlabel(time_label) mlabvpos(label_pos) mlabcolor(cranberry)) ///
    (line gdi_growth gdi_growth if inrange(gdi_growth, -10, 30), col(black)), aspectratio(1) scale(1.2) xsize(4) ysize(4) ///
    legend(off) xtitle("Quarterly GDI growth (annualized, %)") ytitle("Quarterly GDP growth (annualized, %)")
graph export "$graphs/02-prepare-nipa/gdp-gdi-growth.pdf", replace

// Remove COVID subsidies from subsidies
replace a107rc = a107rc - covid_subsidies
replace covid_subsidies = . if yq(year, quarter) < yq(2020, 2)

// Disaggregate quarterly series using the proportional Denton method
keep if year >= 1959 // Monthly series start in 1959
generate time_qtrly = yq(year, quarter), after(quarter)
tsset time_qtrly, quarterly

// Variables to disaggregate
local to_disaggregate_qtrly ///
    a054rc a551rc b029rc w255rc w056rc con520 trp250 b1044c a191rd ///
    w067rc w058rc a180rc w054rc w782rc a955rc w063rc a107rc a108rc w008rc ///
    covid_subsidies w323rc w065rc a453rc

// Define the variable to use for the disaggregation in each case:
local disag_a054rc "b703rc" // Taxes on corporate income -> dividends
local disag_a551rc "concap" // Unidstributed profits -> constant per capita
local disag_b029rc "concap" // Business current transfer payments (net) -> constant per capita

local disag_w255rc "a064rc_b069rc" // Net interest -> Net personal interest income

local disag_w058rc "concap" // Gov income receipts on assets -> constant per capita
local disag_a180rc "concap" // Gov interest payments -> constant per capita
local disag_a264rc "concap" // Gov consumption of fixed capital -> constant per capita

local disag_w056rc "dpcerc" // Production taxes -> consumption
local disag_a107rc "concap" // Subsidies -> constant per capita
local disag_a108rc "concap" // Current surplus of gov enterprises -> constant per capita

local disag_a107rc  "concap" // Subsidies excluding COVID -> constant per capita
local disag_covid_subsidies "concap" // COVID subsidies -> constant per capita

local disag_w323rc "concap" // Business current transfer payments -> constant per capita

local disag_con520 "a038rc" // Self-employed social security contributions -> supplements to wages

local disag_trp250 "w823rc" // Railroad retirement -> pension benefits
local disag_b1044c "w823rc" // Pension benefit guaranty -> pension benefits

local disag_a191rd "dpcerg" // Deflator -> PCE price index

local disag_w067rc "concap" // Estate tax -> constant per capita
local disag_w054rc "w055rc" // Current tax receipts -> Personal current taxes
local disag_w008rc "w055rc" // Taxes from the rest of the world -> Personal current taxes

local disag_w782rc "a061rc" // Contributions for government social insurance -> *Domestic* contributions to government social insurance
local disag_w063rc "a063rc" // Government social benefits -> Government social benefits *to persons*
local disag_a955rc "concap" // Collective expenditures -> constant per capita

local disag_w065rc "concap" // Dividends received by government -> constant per capita

local disag_a453rc "concap" // Net interest and miscellaneous payments of businesses -> constant per capita

// Perform disaggregation
foreach v of varlist `to_disaggregate_qtrly' {
    tempfile `v'
    
    preserve
    drop if missing(`v')
    denton `v' using "``v''", interp(`disag_`v'') from("`nipa_monthly'") generate(`v'_mthly)
    restore
}

tempfile nipa_quarterly
save "`nipa_quarterly'", replace

// -------------------------------------------------------------------------- //
// Annual series
// -------------------------------------------------------------------------- //

// Table 2.9. Personal Income and Its Disposition by Households and by Nonprofit Institutions Serving Households
// -------------------------------------------------------------------------------------------------------------
// 
// (*) w404rc [Nonprofit institution dividend income]
// (*) w403rc [Nonprofit institution interest income]
//
// Table 3.5. Taxes on Production and Imports
// ------------------------------------------
//
// (*) la000355 [Property taxes]
//
// Table 3.6. Contributions for Government Social Insurance
// --------------------------------------------------------
// 
// (=) w782rc [Contributions for government social insurance]
//     (+) a1580c [Employer contributions]
//         (+) [Federal social insurance funds]
//             (+) con110 [Old-age, survivors, disability, and hospital insurance]
//                 (+) l30605 [Old-age, survivors, and disability insurance]
//                 (+) l30606 [Hospital insurance]
//             (+) a1581c [Unemployment insurance]
//                 (+) con120 [State unemployment insurance]
//                 (+) con150 [Federal unemployment tax]
//                 (+) con160 [Railroad employees unemployment insurance]
//                 (+) conbfe [Federal employees unemployment insurance]
//             (+) con170 [Railroad retirement]
//             (+) b1043c [Pension benefit guaranty]
//             (+) con574 [Veterans life insurance]
//             (+) s15300 [Workers' compensation]
//             (+) b1606c [Military medical insurance]
//         (+) [State and local social insurance funds]
//             (+) s25210 [Temporary disability insurance]
//             (+) s25300 [Workers' compensation]
//     (+) a1585c [Employee and self-employed contributions]
//         (+) [Federal social insurance funds]
//             (+) a1586c [Old-age, survivors, disability, and hospital insurance]
//                 (+) a1587c [Employees]
//                     (+) l30622 [Old-age, survivors, and disability insurance]
//                     (+) l30623 [Hospital insurance]
//                 (+) con520 [Self-employed]
//             (+) con530 [Supplementary medical insurance]
//             (+) con544 [State unemployment insurance]
//             (+) con550 [Railroad retirement]
//             (+) con574 [Veterans life insurance]
//         (+) b738rc [State and local social insurance funds]
//     (+) w781rc [Rest-of-the-world contributions]
//
// Table 3.12. Government Social Benefits
// --------------------------------------
// 
// (=) Other government transfers in kind
//     (+) b1606c [Military medical insurance]
//     (+) trp650 [Black lung benefits]
//     (+) trp810 [Other medical assistance]
//     (+) b1603c [State studen aid]
//     (+) w812rc [Other federal social assistance benefits]
//
// Table 7.25. Transactions of Defined Contribution Pension Plans
// --------------------------------------------------------------
//
// (=) y338rc [Current receipts]
//     (+) [Output]
//     (+) y339rc [Contributions]
//         (+) y347rc [Claims to benefits]
//             (+) y340rc [Actual employer contributions]
//                 (+) y934rc [Private plans]
//                 (+) y912rc [Federal government plans]
//                 (+) y955rc [State and local government plans]
//             (+) y344rc [Actual household contributions]
//         (+) y345rc [Household pension contribution supplements]
//         (-) y349rc [Less: Pension service charges for defined contribution pension plans]
//     (+) [Income receipts on assets]
//         (+) y900rc [Interest]
//         (+) y901rc [Dividends]
// (=) y346rc [Current expenditures]
//     (+) [Administrative expenses]
//     (+) [Imputed income payments on assets to persons]
//     (+) y353rc [Benefit payments and withdrawals]
//     (+) y905rc [Net change in assets from current transactions for defined contribution plans]
// (=) y350rc [Cash flow]
//      (+) y351rc [Actual employer and household contributions (5+9)]
// (=) y355rc [Effect on personal income (1-9-10 or 15-9-10)]
// (=) y357rc [Equals: Effect on personal saving]
// (=) y906rc [Plus: Holding gains and other changes in assets]
// (=) y907rc [Equals: Change in personal wealth]
//
// Table 7.12. Imputations in the National Income and Product Accounts
// -------------------------------------------------------------------
//
// (*) y672rc [Imputed interest on plans' claims on employers]
// (*) y240rc [Imputed interest paid by corporations on underfunded pension plans]
//
// Table 7.4.5. Housing Sector Output, Gross Value Added, and Net Value Added
// --------------------------------------------------------------------------
//
// (*) b1034c [Proprietors' income with inventory valuation and capital consumption adjustments]
// (*) w166rc [Current transfert payment]
//
// Table 7.9. Rental Income of Persons by Legal Form of Organization and by Type of Income
// ---------------------------------------------------------------------------------------
//
// (*) b1439c [Royalties]
// (*) w159rc [Rental income of nonprofit institutions with capital consumption adjustment]
//
// Table 7.11. Interest Paid and Received by Sector and Legal Form of Organization
// -------------------------------------------------------------------------------
//
// (*) b1612c [Imputed interest received from life-insurance carriers]
// (*) w499rc [Domestic businesses]
// (*) a085rc [Net interest paid by government]
// (*) y668rc [Government imputed interest]

use "$work/01-import-nipa/nipa-annual-series.dta", clear

replace series_code = strlower(series_code)

generate to_keep = 0
replace to_keep = 1 if series_code == "l30605"
replace to_keep = 1 if series_code == "l30622"
replace to_keep = 1 if series_code == "y344rc"
replace to_keep = 1 if series_code == "y912rc"
replace to_keep = 1 if series_code == "y934rc"
replace to_keep = 1 if series_code == "y955rc"
replace to_keep = 1 if series_code == "y603rc"
replace to_keep = 1 if series_code == "y604rc"
replace to_keep = 1 if series_code == "y605rc"
replace to_keep = 1 if series_code == "a2213c"
replace to_keep = 1 if series_code == "a1581c"
replace to_keep = 1 if series_code == "con544"
replace to_keep = 1 if series_code == "con170"
replace to_keep = 1 if series_code == "con550"
replace to_keep = 1 if series_code == "y672rc"
replace to_keep = 1 if series_code == "b1606c"
replace to_keep = 1 if series_code == "trp650"
replace to_keep = 1 if series_code == "trp810"
replace to_keep = 1 if series_code == "b1603c"
replace to_keep = 1 if series_code == "w812rc"
replace to_keep = 1 if series_code == "b1034c"
replace to_keep = 1 if series_code == "w166rc"
replace to_keep = 1 if series_code == "b1439c"
replace to_keep = 1 if series_code == "w159rc"
replace to_keep = 1 if series_code == "w404rc"
replace to_keep = 1 if series_code == "y240rc"
replace to_keep = 1 if series_code == "b1612c"
replace to_keep = 1 if series_code == "w499rc"
replace to_keep = 1 if series_code == "w403rc"
replace to_keep = 1 if series_code == "a085rc"
replace to_keep = 1 if series_code == "y668rc"
replace to_keep = 1 if series_code == "la000355"
keep if to_keep
drop to_keep

// Reshape
replace value = 1e6*value

greshape wide value, i(year) j(series_code) string
renvars value*, predrop(5)

// Add some annual DINA series not available in NIPA
merge 1:1 year using "$work/01-import-dina/dina-full-aggregates.dta", keep(master match) ///
    keepusing(peninc) nogenerate
ipolate peninc year, gen(i)
replace peninc = i
drop i

// Add some data on IRA pensions
merge 1:1 year using "$work/01-import-ici/ici-data-flows.dta", keepusing(contrib_ira_pretax) nogenerate

// Disaggregate annual series using the proportional Denton method
keep if year >= 1959 // Monthly series start in 1959
tsset year, yearly

// Variables to disaggregate
local to_disaggregate_yrly ///
    l30605 l30622 y344rc y912rc y934rc y955rc y603rc ///
    y604rc y605rc a2213c a1581c con544 con170 con550 y672rc ///
    b1606c trp650 trp810 b1603c w812rc peninc contrib_ira_pretax w499rc ///
    b1034c w166rc b1439c w159rc w404rc b1612c y240rc w403rc a085rc y668rc la000355

// Define the variable to use for the disaggregation in each case:

// Evolving like employer contribution to pensions funds
local disag_y344rc "b040rc"
local disag_y912rc "b040rc"
local disag_y934rc "b040rc"
local disag_y955rc "b040rc"
local disag_y603rc "b040rc"
local disag_y604rc "b040rc"
local disag_y605rc "b040rc"
local disag_y672rc "b040rc"
local disag_y240rc "b040rc"

// Evolving like employer contribution to gov social insurance
local disag_l30605 "b039rc"
local disag_a2213c "b039rc"
local disag_a1581c "b039rc"
local disag_con170 "b039rc"

// Evolving like employee contributions
local disag_l30622 "a061rc"
local disag_con544 "a061rc"
local disag_con550 "a061rc"
local disag_contrib_ira_pretax "a061rc"

// Evolving like social security pension benefits
local disag_peninc "w823rc"

// Remaining constant per capita
local disag_b1606c "concap"
local disag_trp650 "concap"
local disag_trp810 "concap"
local disag_b1603c "concap"
local disag_w812rc "concap"
local disag_b1034c "concap"
local disag_w166rc "concap"
local disag_b1439c "concap"
local disag_w159rc "concap"
local disag_w404rc "concap"
local disag_b1612c "concap"
local disag_w499rc "concap"
local disag_w403rc "concap"
local disag_a085rc "concap"
local disag_y668rc "concap"
local disag_la000355 "concap"

// Perform disaggregation
foreach v of varlist `to_disaggregate_yrly' {
    tempfile `v'
    
    preserve
    drop if missing(`v')
    denton `v' using "``v''", interp(`disag_`v'') from("`nipa_monthly'") generate(`v'_mthly)
    restore
}

tempfile nipa_yearly
save "`nipa_yearly'", replace

// -------------------------------------------------------------------------- //
// Create the monthly NIPA files
// -------------------------------------------------------------------------- //

use "`nipa_monthly'", clear

// Merge the disaggregated values
foreach v in `to_disaggregate_qtrly' {
    merge n:1 time using "``v''", nogenerate keep(master match) 
    // Annualize the disaggregated variables
    replace `v'_mthly = 3*`v'_mthly
    count if missing(`v'_mthly)
    di "`v'"
    // Extrapolate in case the last quarter was not covered
    sort time_mthly
    generate ratio = `v'_mthly/`disag_`v''
    carryforward ratio, replace
    gsort -time_mthly
    carryforward ratio, replace
    gsort time_mthly
    replace `v'_mthly = `disag_`v''*ratio
    drop ratio
}

foreach v in `to_disaggregate_yrly' {
    merge n:1 time using "``v''", nogenerate keep(master match) 
    // Annualize the disaggregated variables
    replace `v'_mthly = 12*`v'_mthly
    // Extrapolate in case the last quarter was not covered
    sort time_mthly
    generate ratio = `v'_mthly/`disag_`v''
    carryforward ratio, replace
    gsort -time_mthly
    carryforward ratio, replace
    gsort time_mthly
    replace `v'_mthly = `disag_`v''*ratio
    drop ratio
}

// -------------------------------------------------------------------------- //
// Treatment of corporate profits in current quarter
// -------------------------------------------------------------------------- //

// We anchor corporate profits in the current quarter to the consensus
// prediction from <https://tradingeconomics.com/forecast/corporate-profits?continent=america>

generate quarter = quarter(dofm(time_mthly))
gegen quarterly_profits = mean(a551rc_mthly), by(year quarter)

replace a551rc_mthly = a551rc_mthly/quarterly_profits*2400e9 if time_mthly > ym(2022, 3)
replace a054rc_mthly = a054rc_mthly/quarterly_profits*2400e9 if time_mthly > ym(2022, 3)

drop quarter quarterly_profits

// -------------------------------------------------------------------------- //
// Simplified national income decompositions
// -------------------------------------------------------------------------- //

replace covid_subsidies_mthly = 0 if ym(year, month) < ym(2020, 04)

// Factor income
// -------------

generate nipa_flemp = a033rc
generate nipa_flwag = a034rc
generate nipa_flsup = a038rc

generate nipa_proprietors = a041rc /// Proprietor's income XX
    - b1034c_mthly /// Rental income included in proprietor's income XX
    + (b029rc_mthly - w323rc_mthly - w166rc_mthly) /// Net non-corporate business transfers paid XX
    + b1439c_mthly // Royalties XX
    
generate nipa_rental = a048rc /// Rental income XX
    + w166rc_mthly /// Housing net current transfer payments XX
    + b1034c_mthly /// Rental income included in proprietors’ income XX
    - b1439c_mthly /// Royalties XX
    - w159rc_mthly // Tenant-occupied rental income of nonprofits XX
    
generate nipa_corptax = a054rc_mthly // XX

generate nipa_profits = a551rc_mthly /// Corporate profits XX
    - w065rc_mthly /// Dividends received by government 
    - w404rc_mthly /// Dividends received by nonprofits XX
    + w323rc_mthly /// Net corporate business transfers paid XX
    + y240rc_mthly /// Imputed interest paid by corporations on underfunded pension plans XX
    + 0.1*b1612c_mthly // Dividend receipts of life-insurance companies included under "imputed interest received from life-insurance carriers" XX
    
generate nipa_fkfix = w255rc_mthly /// Net interest and misc. XX
    + b069rc /// Non-mortage interest payments XX
    - (a453rc_mthly - w499rc_mthly) /// Misc. corporate payments
    - y240rc_mthly /// Imputed interest paid by corporations on underfunded pension plans XX
    - 0.1*b1612c_mthly /// Dividend receipts of life-insurance companies included under "imputed interest received from life-insurance carriers" XX
    - w403rc_mthly /// Interest received by nonprofits XX
    + a085rc_mthly - y668rc_mthly // Net interest paid by government, other than imputed for unfunded pension plans
    
generate nipa_fknmo = b069rc // XX

generate nipa_proptax = la000355_mthly
generate nipa_prodtax = w056rc_mthly /// Taxes on production and imports XX
    + a108rc_mthly // Current surplus of government enterprises XX
generate nipa_salestax = nipa_prodtax - nipa_proptax
    
generate nipa_prodsub  = a107rc_mthly // XX
generate nipa_covidsub = covid_subsidies_mthly // XX

generate nipa_govin = w065rc_mthly /// Dividends received by government
    + (a453rc_mthly - w499rc_mthly) /// Misc. corporate payments
    - (a085rc_mthly - y668rc_mthly) // Net interest paid by government, other than imputed for unfunded pension plans
    
generate nipa_npinc = w403rc_mthly /// Interest received by nonprofits XX
    + w404rc_mthly /// Dividends received by nonprofits XX
    + w159rc_mthly // Tenant-occupied rental income of nonprofits XX

generate nipa_princ = nipa_flemp ///
    + nipa_proprietors ///
    + nipa_rental ///
    + nipa_corptax ///
    + nipa_profits ///
    + nipa_fkfix ///
    - nipa_fknmo ///
    + nipa_prodtax ///
    - nipa_prodsub ///
    - nipa_covidsub ///
    + nipa_govin ///
    + nipa_npinc
    
preserve
    generate quarter = quarter(dofm(time_mthly))
    gcollapse (mean) nipa_princ, by(year quarter)
    merge 1:1 year quarter using "`nipa_quarterly'", keepusing(a032rc) nogenerate keep(match)
    keep if !missing(nipa_princ) & !missing(a032rc)
    assert reldif(nipa_princ, a032rc) < 1e-4 if yq(year, quarter) < yq(2022, 01)
restore

// Pretax income
// -------------

generate nipa_contrib = l30605_mthly /// Old-age, survivors, and disability insurance (employer, federal)
    + l30622_mthly /// Old-age, survivors, and disability insurance (employee)
    + 0.75*con520_mthly /// Old-age, survivors, and disability insurance (self-employed)
    + y344rc_mthly /// Actual household contributions
    + y912rc_mthly /// Federal government plans
    + y934rc_mthly /// Private plans
    + y955rc_mthly /// State and local government plans
    + y603rc_mthly /// Actual employer contributions
    + y604rc_mthly /// Imputed employer contributions
    + y605rc_mthly /// Actual household contributions
    + 0.1*y344rc_mthly /// IRA contributions, not identified in the NIPAs, imputed as ~10% of employee contributions to DC pension plans
    + a2213c_mthly /// Unemployment insurance

generate nipa_uiben = w825rc
generate nipa_penben = w823rc + trp250_mthly + b1044c_mthly + (1 + 1/6)*peninc_mthly
generate nipa_surplus = nipa_contrib - nipa_uiben - nipa_penben

generate nipa_peinc = nipa_princ ///
    - nipa_contrib ///
    + nipa_uiben ///
    + nipa_penben ///
    + nipa_surplus
    
preserve
    generate quarter = quarter(dofm(time_mthly))
    gcollapse (mean) nipa_peinc, by(year quarter)
    merge 1:1 year quarter using "`nipa_quarterly'", keepusing(a032rc) nogenerate keep(match)
    keep if !missing(nipa_peinc) & !missing(a032rc)
    gen discr = reldif(nipa_peinc, a032rc)
    assert reldif(nipa_peinc, a032rc) < 1e-4 if yq(year, quarter) < yq(2022, 01)
restore

// Disposable income
// -----------------

generate nipa_govcontrib = a061rc
    
generate nipa_othercontrib = a061rc /// Contributions for government social insurance, domestic
    - l30605_mthly /// Old-age, survivors, and disability insurance (employers)
    - l30622_mthly /// Old-age, survivors, and disability insurance (employees + self-employed)
    - a2213c_mthly /// Unemployment insurance
    - con170_mthly /// Railroad retirement (employer, federal)
    - con550_mthly /// Railroad retirement (employee, state)
    - 0.75*con520_mthly // Old-age, survivors, disability insurance (self-employed)
    
generate nipa_taxes     = w055rc
generate nipa_estatetax = w067rc_mthly
generate nipa_vet       = w826rc
generate nipa_othcash   = w827rc - (b1606c_mthly + trp650_mthly + trp810_mthly + b1603c_mthly + w812rc_mthly)

generate nipa_covidchecks = covid_relief

generate nipa_dispo = nipa_peinc ///
    - nipa_surplus ///
    - nipa_govin ///
    - nipa_othercontrib ///
    - nipa_taxes ///
    - nipa_estatetax ///
    - nipa_corptax ///
    - nipa_prodtax ///
    + nipa_prodsub ///
    + nipa_covidsub ///
    + nipa_vet ///
    + nipa_othcash

// Post-tax income
// ---------------
//
// (=) nipa_poinc [Posttax national income]
//     (+) nipa_dispo [Posttax disposable income]
//     (+) nipa_medicare [Medicare]
//     (+) nipa_medicaid [Medicaid]
//     (+) nipa_otherkin [Other in-kind transfers]  
//     (+) nipa_govin [Government property income]
//     (+) nipa_colexp [Collective expenditures]
//     (+) nipa_prisupenprivate [Surplus/deficit of private insurance systems]
//     (+) nipa_prisupgov [Primary surplus/deficit of government]

generate nipa_medicare = w824rc
generate nipa_medicaid = w729rc
generate nipa_otherkin = b1606c_mthly + trp650_mthly + trp810_mthly + b1603c_mthly + w812rc_mthly
generate nipa_colexp = a955rc_mthly

generate nipa_prisupenprivate = y344rc_mthly /// Actual household contributions
    + y912rc_mthly /// Federal government plans
    + y934rc_mthly /// Private plans
    + y955rc_mthly /// State and local government plans
    + y603rc_mthly /// Actual employer contributions
    + y604rc_mthly /// Imputed employer contributions
    + y605rc_mthly /// Actual household contributions
    + contrib_ira_pretax_mthly /// IRA contributions (pretax income)
    - (1 + 1/6)*peninc_mthly // Pension distributions

generate nipa_prisupgov = nipa_taxes ///
    + nipa_estatetax ///
    + nipa_corptax ///
    + nipa_prodtax ///
    - nipa_prodsub ///
    - nipa_covidsub ///
    + nipa_contrib ///
    + nipa_othercontrib ///
    - nipa_uiben ///
    - nipa_penben ///
    - nipa_vet ///
    - nipa_othcash ///
    - nipa_medicare ///
    - nipa_medicaid ///
    - nipa_otherkin ///
    - nipa_colexp ///
    - nipa_prisupenprivate

generate nipa_poinc = nipa_dispo ///
    + nipa_medicare ///
    + nipa_medicaid ///
    + nipa_otherkin ///
    + nipa_govin ///
    + nipa_colexp ///
    + nipa_prisupenprivate ///
    + nipa_prisupgov
    
preserve
    generate quarter = quarter(dofm(time_mthly))
    gcollapse (mean) nipa_poinc, by(year quarter)
    merge 1:1 year quarter using "`nipa_quarterly'", keepusing(a032rc) nogenerate keep(match)
    keep if !missing(nipa_poinc) & !missing(a032rc)
    gen discr = reldif(nipa_poinc, a032rc)
    assert reldif(nipa_poinc, a032rc) < 1e-4 if yq(year, quarter) < yq(2022, 01)
restore
    
// Monthly population
generate nipa_pop = b230rc

// Monthly deflator
generate nipa_deflator = a191rd_mthly
sort year month
replace nipa_deflator = nipa_deflator/nipa_deflator[_N]

// -------------------------------------------------------------------------- //
// Correct some outliers for monthly values
// -------------------------------------------------------------------------- //

keep year month nipa_*

rename nipa_deflator deflator
rename nipa_pop pop

// Create a smooth princ for normalization
generate time = ym(year, month)
tsset time
tsfilter hp ref=nipa_princ
replace ref = nipa_princ - ref
tsset, clear
drop time

greshape long nipa, i(year month) j(variable) string

// Covert to % of national income
replace nipa = nipa/ref

// Determine outliers as quarters where the maximum deviation from the
// year median exceed a multiple of the median maximum deviation from the
// year median
generate time = ym(year, month)
format time %tm
generate quarter = quarter(dofm(time))
gegen qtrly_median = median(nipa), by(variable year quarter)
generate deviation = abs(nipa - qtrly_median)
gegen max_deviation = max(deviation), by(variable year quarter)
gegen median_max = median(max_deviation), by(variable)
generate relative_deviation = max_deviation/median_max

// Do not include Covid years in the outliers
generate glitch = (relative_deviation >= 4) & (year < 2020)
replace glitch = 0 if variable == "_otherkin"
replace glitch = 0 if variable == "_covidsub"
replace glitch = 0 if variable == "_covidchecks"

generate nipa_corr = nipa if !glitch
sort variable time
by variable: ipolate nipa_corr time, gen(i)
replace nipa_corr = i
drop i

replace nipa = nipa*ref
replace nipa_corr = nipa_corr*ref

keep year month time deflator pop variable nipa* nipa_corr*
greshape wide nipa nipa_corr, i(year month time) j(variable) string

// Re-apply basic accountign identities
enforce ///
    (nipa_corr_prodtax = nipa_corr_salestax + nipa_corr_proptax) ///
    (nipa_corr_princ = nipa_corr_flemp + nipa_corr_proprietors + nipa_corr_rental + ///
        nipa_corr_corptax + nipa_corr_profits + nipa_corr_fkfix - nipa_corr_fknmo + ///
            nipa_corr_prodtax - nipa_corr_prodsub - nipa_covidsub + nipa_corr_govin) ///
    (nipa_corr_peinc = nipa_corr_princ - nipa_corr_contrib + nipa_corr_uiben + ///
        nipa_corr_penben + nipa_corr_surplus) ///
    (nipa_corr_dispo = nipa_corr_peinc - nipa_corr_surplus - nipa_corr_govin - ///
        nipa_corr_othercontrib - nipa_corr_taxes - nipa_corr_estatetax - ///
           nipa_corr_corptax - nipa_corr_prodtax + nipa_corr_prodsub + nipa_corr_covidsub + nipa_corr_vet + nipa_corr_othcash) ///
    (nipa_corr_poinc = nipa_corr_dispo + nipa_corr_medicare + nipa_corr_medicaid + ///
        nipa_corr_otherkin + nipa_corr_govin + nipa_corr_colexp + nipa_corr_prisupenprivate + nipa_corr_prisupgov) ///
    (nipa_corr_princ = nipa_corr_peinc) ///
    (nipa_corr_princ = nipa_corr_poinc), ///
    replace

// -------------------------------------------------------------------------- //
// Plot: correction for outliers
// -------------------------------------------------------------------------- //

foreach v of varlist nipa_corr* {
    local stub = substr("`v'", 11, .)
    
    generate a = nipa_`stub'/deflator/1e9
    generate b = nipa_corr_`stub'/deflator/1e9
    
    gr tw line a b time, col(ebblue cranberry) ///
        legend(label(1 "Orignal") label(2 "Corrected")) ///
        title("`stub'") ylabel(, format(%9.0gc)) xtitle("") ytitle("Billion USD")
    gr export "$graphs/02-prepare-nipa/nipa-corr-`stub'.pdf", replace
    
    
    drop a b
}

keep year month deflator pop nipa_corr*
renvars nipa_corr*, subst("nipa_corr" "nipa")
rename deflator nipa_deflator
rename pop nipa_pop

keep if year >= 1973

save "$work/02-prepare-nipa/nipa-simplified-monthly.dta", replace

// Make quarterly/yearly version
generate quarter = ceil(month/3)
gcollapse (mean) nipa_*, by(year quarter)
save "$work/02-prepare-nipa/nipa-simplified-quarterly.dta", replace

gcollapse (mean) nipa_*, by(year)
save "$work/02-prepare-nipa/nipa-simplified-yearly.dta", replace
