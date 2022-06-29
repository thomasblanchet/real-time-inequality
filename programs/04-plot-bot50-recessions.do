// -------------------------------------------------------------------------- //
// Plot the dynamics of bottom 50% income during each recession
// -------------------------------------------------------------------------- //

use "$work/03-decompose-components/decomposition-monthly-princ-working_age.dta", clear
merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate keepusing(nipa_deflator) keep(master match) assert(match using)
replace princ = princ/nipa_deflator

// Calculate bracket averages
sort year month p
by year month: generate n = cond(_n == _N, 1e5 - p, p[_n + 1] - p)

preserve
    keep if p < 50000
    gcollapse (mean) princ_bot50=princ [pw=n], by(year month)
    tempfile bot50
    save "`bot50'", replace
restore
gcollapse (mean) princ_total=princ [pw=n], by(year month)
merge 1:1 year month using "`bot50'", nogenerate keep(match)


generate time = ym(year, month)
format time %tm

// Normalize at the beginning of each recession
keep if ym(year, month) >= ym(2007, 12)
generate period = (ym(year, month) >= ym(2020, 02))
generate elapsed = ym(year, month) - ym(2007, 12) if period == 0
replace elapsed = ym(year, month) - ym(2020, 02) if period == 1
keep if elapsed <= 120

keep year month princ_bot50 princ_total time elapsed period
reshape wide year month princ_bot50 princ_total time, i(elapsed) j(period)

foreach v of varlist princ* {
    generate init = `v'[1]
    replace `v' = 100*`v'/init
    drop init
}

gr tw (line princ_bot500 princ_bot501 princ_total0 princ_total1 elapsed, ///
        lw(medthick..) lcol(ebblue ebblue cranberry cranberry) lp(solid dash solid dash)) ///
    (pcarrowi 91 105 100 109, lw(medthick) col(black)) ///
    (pcarrowi 105 8 100 17, lw(medthick) col(black)), ///
    legend(off) ///
    xlabel(0(12)120) xtitle("Months after recession started") ///
    ytitle("Real average factor income per working-age adult" "(Index, 100 in the month preceding the recession)") ///
    yline(100, lcol(black)) ///
    text(89 105 "February 2017" "(9 years, 2 months)", col(black) size(small)) ///
    text(108 8 "July 2021" "(1 year," "5 months)", col(black) size(small)) ///
    text(83.5 40 "Bottom 50%" "(Great recession)", col(ebblue) size(small)) ///
    text(108 90 "Working-age adults" "(Great recession)", col(cranberry) size(small)) ///
    text(110 27 "Bottom 50%" "(COVID recession)", col(ebblue) size(small) justification(left) placement(right)) ///
    text(104.5 26 "Working-age adults" "(COVID recession)", col(cranberry) size(small) justification(left) placement(right))
gr export "$graphs/04-plot-bot50-recessions/bot50-recessions.pdf", replace
