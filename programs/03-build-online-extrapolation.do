// -------------------------------------------------------------------------- //
// Build the file for the online extrapolation of wealth
// -------------------------------------------------------------------------- //

clear
tempfile db
save "`db'", emptyok replace

global date_last = ym(2022, 04)

local year = year(dofm($date_last))
local month = month(dofm($date_last))

foreach unit in "adults" "households" "working-age" {
    use "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear

    // Variables needed to extrapolate
    generate housing = housing_tenant + housing_owner
    generate equity = equ_scorp + equ_nscorp
    generate other_wealth = hweal - housing - equity

    if ("`unit'" == "households") {
        gcollapse (sum) hweal housing equity other_wealth (mean) weight (first) top400, by(id)
    }
    else if ("`unit'" == "working-age") {
        drop if age >= 65
    }
    
    // Create brackets
    sort hweal
    generate rank = sum(weight)
    replace rank = (rank - weight/2)/rank[_N]

    generate bracket = ""
    replace bracket = "bot50"      if inrange(rank, 0, 0.5)
    replace bracket = "mid40"      if inrange(rank, 0.5, 0.9)
    replace bracket = "top10_1"    if inrange(rank, 0.9, 0.99)
    replace bracket = "top1_01"    if inrange(rank, 0.99, 0.999)
    replace bracket = "top01_001"  if inrange(rank, 0.999, 0.9999)
    replace bracket = "top001_400" if inrange(rank, 0.9999, 1)
    replace bracket = "top400"     if top400 == 1

    generate bracket_order = .
    replace bracket_order = 1 if bracket == "bot50"
    replace bracket_order = 2 if bracket == "mid40"
    replace bracket_order = 3 if bracket == "top10_1"
    replace bracket_order = 4 if bracket == "top1_01"
    replace bracket_order = 5 if bracket == "top01_001"
    replace bracket_order = 6 if bracket == "top001_400"
    replace bracket_order = 7 if bracket == "top400"

    gcollapse (sum) housing equity other_wealth (rawsum) population=weight [pw=weight], by(bracket_order bracket)
    
    generate unit = "`unit'"
    
    append using "`db'"
    save "`db'", replace
}

sort unit bracket_order
drop bracket_order

export delimited "$website/wealth-extrapolation-data.csv", replace

