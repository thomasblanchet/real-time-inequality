// -------------------------------------------------------------------------- //
// Master-file to run programs in the right order
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Data import
// -------------------------------------------------------------------------- //

// Import NIPA aggregate income data
// ---------------------------------
//
// BEA NIPA data [nipa]
// See: https://apps.bea.gov/iTable/iTable.cfm?reqid=19&step=4&isuri=1&nipa_table_list=1&categories=flatfiles
//
// The NIPA data is automatically downloaded and should not require manual
// changes, as long as series codes remain the same.

cap mkdir "$work/01-import-nipa"
do "$programs/01-import-nipa.do"

// Import BLS price data
// ---------------------
//
// BLS CPI [cu]
// See: https://download.bls.gov/pub/time.series/cu/
//
// The BLS data is automatically downloaded and should not require manual
// changes, as long as series codes remain the same.
//
// The BLS price data is updated a bit more quickly than the BEA's, and is
// used for some basic manipulations of the BLS data that are more meaningful
// in real terms

cap mkdir "$work/01-import-cu"
do "$programs/01-import-cu.do"

// Import BLS employment data
// --------------------------
//
// BLS Employment, Hours, and Earnings (National, NAICS) [ce]
// See: https://download.bls.gov/pub/time.series/ce/
//
// BLS State and Area Employment, Hours and Earnings [sm]
// See: https://download.bls.gov/pub/time.series/sm
//
// The BLS data is automatically downloaded and should not require manual
// changes, as long as series codes reamin the same.

cap mkdir "$work/01-import-ce"
cap mkdir "$work/01-import-sm"
do "$programs/01-import-ce.do"
do "$programs/01-import-sm.do"

// Import data on weekly unemployment insurance claims
// ---------------------------------------------------
//
// Note: The file $rawdata/ui-data/weekly-unemployment-report.xlsx must be
// updated by hand. To do so:
//  - go to <https://oui.doleta.gov/unemploy/claims.asp>
//  - select "national", "XML" (not "spreadsheet") and the latest year
//  - save the result in XLSX

cap mkdir "$work/01-import-ui"
do "$programs/01-import-ui.do"

// Import FED Financial Accounts
// -----------------------------
//
// FED Financial Accounts [fa]
// https://www.federalreserve.gov/releases/z1/release-dates.htm
//
// The FED data is automatically downloaded and should not require manual
// changes, as long as series codes reamin the same.

cap mkdir "$work/01-import-fa"
do "$programs/01-import-fa.do"

// Import minimum wage data
// ------------------------
//
// The minimum wage data is imported from FRED and therefore should update
// automatically.

cap mkdir "$work/01-import-minwage"
do "$programs/01-import-minwage.do"

// Import DINA macro data
// ----------------------
//
// The DINA macro data comes from the Excel file of the PSZ paper and are
// update whenever these files are updated. The cellrange when importing
// the files must be adjusted when the update happens.

cap mkdir "$work/01-import-dina-macro"
do "$programs/01-import-dina-macro.do"

// Import DINA micro data
// ----------------------
//
// The DINA micro data comes from the PSZ microfiles and are to be updated
// whenever these files are updated. The range of years must be adjusted when
// the update happens.

cap mkdir "$work/01-import-dina"
do "$programs/01-import-dina.do"

// Import social security wage data
// --------------------------------
//
// Social Security Administration data [ssa]
// https://www.ssa.gov/cgi-bin/netcomp.cgi?year=2020
//
// The SSA data is scraped automatically and updates should not require manual
// changes as long as the format online stay the same, except to adjust
// the last year.

cap mkdir "$work/01-import-ssa-wages"
rsource using "$programs/01-import-ssa-wages.R", roptions(`" --vanilla --args "$work" "')

// Import SEER population data
// ---------------------------
// 
// SEER data on population [pop]
// See: https://seer.cancer.gov/popdata/download.html
//
// The SEER data is automatically downloaded, but the name of the file to be
// downloaded should be changed after each update to reflect the last
// year of the data.

cap mkdir "$work/01-import-pop"
do "$programs/01-import-pop.do"

// Import ICI data on the composition of pension funds
// ---------------------------------------------------
//
// ICI data on the composition of pension funds [ici]
// See: https://www.ici.org/research/stats/retirement
//
// The download should work without changes, except that the URL of the file to
// update should be changed to match the last file available.

cap mkdir "$work/01-import-ici"
do "$programs/01-import-ici.do"

// Data on total amounts for various COVID relief programs
// -------------------------------------------------------
// 
// BEA Effects of Selected Federal Pandemic Response Programs on Personal Income
// See: https://www.bea.gov/federal-recovery-programs-and-bea-statistics/archive
//
// The data needs to be updated manually based on the information available
// on the BEA's website (tables not harmonized enough for automatic retrieval)

cap mkdir "$work/01-import-aid-covid"
do "$programs/01-import-aid-covid.do"

// Data on the Paycheck Protection Program (PPP) during COVID
// ----------------------------------------------------------
//
// The PPP loan data must be updated from the Small Business Administration 
// website <https://data.sba.gov/dataset/ppp-foia>.

cap mkdir "$work/01-import-ppp-covid"
do "$programs/01-import-ppp-covid.do"

// QCEW data
// ---------
//
// BLS QCEW data [qcew]
// See: https://www.bls.gov/cew/downloadable-data-files.htm
//
// QCEW files are automatically downloaded, but the last year available
// must be updated in the code every year.
//
// QCEW files are very large, so we recommend only downloading the latest
// year every time.

cap mkdir "$work/01-import-qcew"
do "$programs/01-import-qcew.do"

// Forbes data
// -----------
//
// The Forbes data is automatically scraped from the Wayback Machine,
// so this part of the code should not require any change.

python script "$programs/01-scrape-forbes.py", args("$rawdata/forbes-data/forbes.csv")
do "$programs/01-import-forbes.do"

// Wealth indexes
// --------------
//
// The wealth indexes are downloaded directly from FRED and should not require
// manual updates.

do "$programs/01-import-wealth-indexes.do"

// -------------------------------------------------------------------------- //
// Preparation of the data
// -------------------------------------------------------------------------- //

// Prepare NIPA data
// -----------------

do "$programs/02-prepare-nipa.do"

// Prepare Financial Accounts data
// --------------------------------

do "$programs/02-prepare-fa.do"

// Prepare national population data
// --------------------------------

do "$programs/02-prepare-pop.do"

// Prepate BLS Employment data
// ---------------------------

do "$programs/02-prepare-bls-employment.do"

// Adjust DINA files using SSA yearly employment and wages
// -------------------------------------------------------

rsource using "$programs/02-add-ssa-wages.R", roptions(`" --vanilla --args "$work" "')

// Data to match via optimal transport
// -----------------------------------
//
// These data need to be downloaded manually from IPUMS or from the 
// Federal Reserve website whenever a new version is available.
//
// IPUMS CPS: https://cps.ipums.org/cps/
// IPUMS USA: https://usa.ipums.org/usa/ (for census/ACS)
// SCF: https://www.federalreserve.gov/econres/scfindex.htm

do "$programs/02-transport-import-acs.do"
do "$programs/02-transport-import-cps.do"
do "$programs/02-transport-import-scf.do"
do "$programs/02-transport-import-dina.do"

// Perform match via optimal transport
// -----------------------------------

do "$programs/02-transport-check-consistency.do"

// Note: the actual transport is computationally intensive and must run on
// the computing cluster with large memory
//
// Python script to execute: transport.py
//
// Command to run it on the appropriate node:
// >> sbatch -C mem768g transport.sh

// Match the DINA data with CPS/SCF/ACS using the calculated transport maps
// ------------------------------------------------------------------------

do "$programs/02-match-dina-transport.do"

// Prepare DINA data
// -----------------

do "$programs/02-prepare-dina.do"

// Prepare series on UI benefits recipients
// ----------------------------------------

do "$programs/02-prepare-ui.do"

// Prepare QCEW data
// -----------------

do "$programs/02-disaggregate-qcew.do"
do "$programs/02-update-qcew.do"
do "$programs/02-tabulate-qcew.do"
do "$programs/02-adjust-seasonality-qcew.do"

// Prepare monthly CPS data
// -------------------------

do "$programs/02-cps-monthly-earnings.do"
do "$programs/02-cps-monthly-cells.do"

// Construct the monthly wage distribution
// ---------------------------------------

do "$programs/02-create-monthly-wages.do"

// Distribute Paycheck Protection Program
// --------------------------------------

do "$programs/02-distribute-ppp-covid.do"

// -------------------------------------------------------------------------- //
// Generations of microfiles and online database
// -------------------------------------------------------------------------- //

// Monthly microfiles
// ------------------

do "$programs/03-build-monthly-microfiles.do"

// Backtesting version of the microfiles (using 1 and 2-year old IRS files)
// ------------------------------------------------------------------------

do "$programs/03-build-monthly-microfiles-backtest-1y.do"
do "$programs/03-build-monthly-microfiles-backtest-2y.do"
// Version with pure rescaling (to compare results)
do "$programs/03-build-monthly-microfiles-backtest-rescaling-1y.do"
do "$programs/03-build-monthly-microfiles-backtest-rescaling-2y.do"

// Online database
// ---------------

do "$programs/03-build-online-database.do"
// Dataset for the daily projection of wealth (done by the website)
do "$programs/03-build-online-extrapolation.do"

// Decompositions
// --------------

do "$programs/03-decompose-components.do"
do "$programs/03-decompose-education.do"
do "$programs/03-decompose-race.do"

// -------------------------------------------------------------------------- //
// Report the results
// -------------------------------------------------------------------------- //

// Backtests
// ---------

do "$programs/04-backtest.do"
do "$programs/04-backtest-rescaling.do"

// Other graphs
// ------------

do "$programs/04-analyze-wage-growth.do"
do "$programs/04-gic-wages.do"

do "$programs/04-plot-covid.do"
do

do "$programs/04-plot-income.do"
do "$programs/04-plot-hweal.do"
do "$programs/04-plot-online-database.do"
do "$programs/04-plot-presentation.do"


