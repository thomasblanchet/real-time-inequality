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

cap mkdir "$work/01-import-forbes"
python script "$programs/01-scrape-forbes.py", args("$rawdata/forbes-data/forbes.csv")
do "$programs/01-import-forbes.do"

// Wealth indexes
// --------------
//
// The wealth indexes are downloaded directly from FRED and should not require
// manual updates.

cap mkdir "$work/01-import-wealth-indexes"
cap mkdir "$graphs/01-import-wealth-indexes"
do "$programs/01-import-wealth-indexes.do"

// Monthly CPS data
// ----------------
//
// The monthly CPS data extracts needs to be downloaded from IPUMS CPS every
// month. See <https://cps.ipums.org/cps/>.
//
// It is stored under raw-data/cps-monthly/cps-monthly.dat

cap mkdir "$work/01-import-cps-monthly"
do "$programs/01-import-cps-monthly.do"

// ACS/Census data (for transport)
// -------------------------------
//
// The ACS/Census data must be downloaded from IPUMS USA
// <https://usa.ipums.org/usa/>
//
// It is stored under raw-data/acs-data/usa.dat

cap mkdir "$work/01-import-transport-acs"
do "$programs/01-import-transport-acs.do"

// Yearly CPS data (for transport)
// -------------------------------
//
// The CPS data extract needs to be downloaded from IPUMS CPS
// <https://cps.ipums.org/cps/>
//
// It is stored under raw-data/cps-data/cps.dat

cap mkdir "$work/01-import-transport-cps"
do "$programs/01-import-transport-cps.do"

// SCF data (for transport)
// ------------------------
//
// The SCF data must be downloaded from the Federal Reserve website
// <https://www.federalreserve.gov/econres/scfindex.htm> and stored under
// raw-data/scf-data. We use both the full public dataset and the extract
// public data.

cap mkdir "$work/01-import-transport-scf"
do "$programs/01-import-transport-scf.do"

// DINA microdata (for transport) --> move after 02-add-ssa-wages
// ------------------------------

cap mkdir "$work/01-import-transport-dina"
do "$programs/01-import-transport-dina.do"

// -------------------------------------------------------------------------- //
// Preparation of the data
// -------------------------------------------------------------------------- //

// Prepare NIPA data
// -----------------

cap mkdir "$work/02-prepare-nipa"
cap mkdir "$graphs/02-prepare-nipa"
do "$programs/02-prepare-nipa.do"

// Prepare Financial Accounts data
// --------------------------------

cap mkdir "$work/02-prepare-fa"
cap mkdir "$graphs/02-prepare-fa"
do "$programs/02-prepare-fa.do"

// Prepare national population data
// --------------------------------

cap mkdir "$work/02-prepare-pop"
cap mkdir "$graphs/02-prepare-pop"
do "$programs/02-prepare-pop.do"

// Prepate BLS Employment data
// ---------------------------

cap mkdir "$work/02-prepare-bls-employment"
cap mkdir "$graphs/02-prepare-bls-employment"
do "$programs/02-prepare-bls-employment.do"

// Adjust DINA files using SSA yearly employment and wages
// -------------------------------------------------------

cap mkdir "$work/02-add-ssa-wages"
rsource using "$programs/02-add-ssa-wages.R", roptions(`" --vanilla --args "$work" "')

// Perform match via optimal transport
// -----------------------------------

cap mkdir "$work/02-export-transport-dina"
do "$programs/02-export-transport-dina.do"
cap mkdir "$graphs/02-transport-check-consistency"
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

cap mkdir "$work/02-match-dina-transport"
do "$programs/02-match-dina-transport.do"

// Prepare DINA data
// -----------------

cap mkdir "$work/02-prepare-dina"
cap mkdir "$graphs/02-prepare-dina"
do "$programs/02-prepare-dina.do"

// Prepare series on UI benefits recipients
// ----------------------------------------

cap mkdir "$work/02-prepare-ui"
cap mkdir "$graphs/02-prepare-ui"
do "$programs/02-prepare-ui.do"

// Prepare QCEW data
// -----------------

cap mkdir "$work/02-disaggregate-qcew"
do "$programs/02-disaggregate-qcew.do"

cap mkdir "$work/02-update-qcew"
cap mkdir "$work/02-update-qcew/backtesting-ces"
cap mkdir "$graphs/02-update-qcew"
do "$programs/02-update-qcew.do"

cap mkdir "$work/02-tabulate-qcew"
do "$programs/02-tabulate-qcew.do"

cap mkdir "$work/02-adjust-seasonality-qcew"
cap mkdir "$graphs/02-adjust-seasonality-qcew"
do "$programs/02-adjust-seasonality-qcew.do"

// Prepare monthly CPS data
// ------------------------

cap mkdir "$work/02-cps-monthly-earnings"
do "$programs/02-cps-monthly-earnings.do"

cap mkdir "$work/02-cps-monthly-cells"
cap mkdir "$graphs/02-cps-monthly-cells"
do "$programs/02-cps-monthly-cells.do"

// Construct the monthly wage distribution
// ---------------------------------------

cap mkdir "$work/02-create-monthly-wages"
cap mkdir "$graphs/02-create-monthly-wages"
do "$programs/02-create-monthly-wages.do"

// Distribute Paycheck Protection Program
// --------------------------------------

cap mkdir "$work/02-distribute-ppp-covid"
cap mkdir "$graphs/02-distribute-ppp-covid"
do "$programs/02-distribute-ppp-covid.do"

// -------------------------------------------------------------------------- //
// Generations of microfiles and online database
// -------------------------------------------------------------------------- //

// Monthly microfiles
// ------------------

cap mkdir "$work/03-build-monthly-microfiles"
cap mkdir "$work/03-build-monthly-microfiles/microfiles"
do "$programs/03-build-monthly-microfiles.do"

// Backtesting version of the microfiles (using 1 and 2-year old IRS files)
// ------------------------------------------------------------------------

cap mkdir "$work/03-build-monthly-microfiles-backtest-1y"
cap mkdir "$work/03-build-monthly-microfiles-backtest-1y/microfiles"
do "$programs/03-build-monthly-microfiles-backtest-1y.do"

cap mkdir "$work/03-build-monthly-microfiles-backtest-2y"
cap mkdir "$work/03-build-monthly-microfiles-backtest-2y/microfiles"
do "$programs/03-build-monthly-microfiles-backtest-2y.do"

// Version with pure rescaling (to compare results)
cap mkdir "$work/03-build-monthly-microfiles-backtest-rescaling-1y"
cap mkdir "$work/03-build-monthly-microfiles-backtest-rescaling-1y/microfiles"
do "$programs/03-build-monthly-microfiles-backtest-rescaling-1y.do"

cap mkdir "$work/03-build-monthly-microfiles-backtest-rescaling-2y"
cap mkdir "$work/03-build-monthly-microfiles-backtest-rescaling-2y/microfiles"
do "$programs/03-build-monthly-microfiles-backtest-rescaling-2y.do"

// Online database
// ---------------

cap mkdir "$work/03-build-online-database"
do "$programs/03-build-online-database.do"

cap mkdir "$work/03-build-online-database-labor"
cap mkdir "$graphs/03-build-online-database-labor"
do "$programs/03-build-online-database-labor.do"

// Dataset for the daily projection of wealth (done by the website)
do "$programs/03-build-online-extrapolation.do"

// Decompositions
// --------------

cap mkdir "$work/03-decompose-components"
cap mkdir "$graphs/03-decompose-components"
do "$programs/03-decompose-components.do"

cap mkdir "$work/03-decompose-education"
cap mkdir "$graphs/03-decompose-education"
do "$programs/03-decompose-education.do"

cap mkdir "$work/03-decompose-race"
cap mkdir "$graphs/03-decompose-race"
do "$programs/03-decompose-race.do"

// -------------------------------------------------------------------------- //
// Report the results
// -------------------------------------------------------------------------- //

// Backtests
// ---------

cap mkdir "$work/04-backtest"
cap mkdir "$graphs/04-backtest"
do "$programs/04-backtest.do"

cap mkdir "$work/04-backtest-rescaling"
cap mkdir "$graphs/04-backtest-rescaling"
do "$programs/04-backtest-rescaling.do"

// Other graphs
// ------------

cap mkdir "$work/04-plot-covid"
cap mkdir "$graphs/04-plot-covid"
do "$programs/04-plot-covid.do"

cap mkdir "$work/04-plot-bot50-recessions"
cap mkdir "$graphs/04-plot-bot50-recessions"
do "$programs/04-plot-bot50-recessions.do"

cap mkdir "$work/04-analyze-wage-growth"
cap mkdir "$graphs/04-analyze-wage-growth"
do "$programs/04-analyze-wage-growth.do"

cap mkdir "$work/04-gic-wages"
cap mkdir "$graphs/04-gic-wages"
do "$programs/04-gic-wages.do"

cap mkdir "$work/04-plot-gender-gaps"
cap mkdir "$graphs/04-plot-gender-gaps"
do "$programs/04-plot-gender-gaps.do"
