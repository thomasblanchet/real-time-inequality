// -------------------------------------------------------------------------- //
// Decompose income by education
// -------------------------------------------------------------------------- //

clear
save "$work/03-decompose-education/decomposition-monthly-education.dta", replace emptyok

global date_begin = ym(1989, 01)
global date_end   = ym(2022, 04)

quietly {
    foreach income in peinc wage pkinc hweal {
        foreach t of numlist $date_begin / $date_end {
            noisily di "* " %tm = `t' ", `income'"
            
            local year = year(dofm(`t'))
            local month = month(dofm(`t'))
            
            // Calculate additional incomes if necessary
            if ("`income'" == "peinc") {
                use id weight educ peinc using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
            }
            else if ("`income'" == "wage") {
                use id weight age educ flemp proprietors if age < 65 using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
            
                generate wage = flemp + 0.7*proprietors
            }
            else if ("`income'" == "pkinc") {
                use id weight educ proprietors rental corptax profits fkfix fknmo prodtax prodsub govin covidsub ///
                    surplus using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
                
                generate pkinc = 0.3*proprietors + rental + corptax + profits + fkfix - fknmo
            }
            else if ("`income'" == "hweal") {
                use id weight educ hweal using "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
            }
            
            // Equal-split
            gegen `income' = mean(`income'), by(id) replace
            
            // Recode education
            replace educ = 1 if educ <= 6
            replace educ = 2 if educ >= 7
            drop if !inlist(educ, 1, 2)
            
            // Generate groups by education
            hashsort educ `income'
            by educ: generate rank = sum(weight)
            by educ: replace rank = 1e5*(rank - weight/2)/rank[_N]
            
            egen p = cut(rank), at(0(1000)99000 999999)
            
            gcollapse (mean) average=`income' [pw=weight], by(educ p)
            generate year = `year'
            generate month = `month'
            generate type = "`income'"
            
            append using "$work/03-decompose-education/decomposition-monthly-education.dta"
            save "$work/03-decompose-education/decomposition-monthly-education.dta", replace
        }
    }
}

// -------------------------------------------------------------------------- //
// Plot college premium
// -------------------------------------------------------------------------- //

use "$work/03-decompose-education/decomposition-monthly-education.dta", clear

generate time = ym(year, month)
format time %tm

sort time type educ p
by time type educ: generate n = cond(_n == _N, 1e5 - p, p[_n + 1] - p)

gcollapse (mean) average [pw=n], by(year month time educ type)

generate quarter = quarter(dofm(time))

gcollapse (mean) average, by(year quarter educ type)
generate time = yq(year, quarter)
format time %tq

greshape wide average, i(year quarter time type) j(educ)

generate gap = 100*(average2/average1 - 1)

gr tw (line gap time if type == "wage", lw(medthick) col(ebblue)), ///
    yscale(range(0 250)) ylabel(0(50)250) xtitle("") ytitle("College premium" "(% increase between no college and some college)") ///
    legend(off) xlabel(`=yq(1990, 1)'(20)`=yq(2020, 1)') scale(1.1) ///
    text(90 `=yq(2017, 1)' "Labor income" "(working-age population)", col(ebblue) size(small))
graph export "$graphs/03-decompose-education/college-premium-1.pdf", replace

gr tw (line gap time if type == "wage", lw(medthick) col(ebblue)) ///
    (line gap time if type == "hweal", lw(medthick) col(purple)), ///
    yscale(range(0 250)) ylabel(0(50)250) xtitle("") ytitle("College premium" "(% increase between no college and some college)") ///
    legend(off) xlabel(`=yq(1990, 1)'(20)`=yq(2020, 1)') scale(1.1) ///
    text(90 `=yq(2017, 1)' "Labor income" "(working-age population)", col(ebblue) size(small)) ///
    text(195 `=yq(2019, 1)' "Wealth", col(purple) size(small))
graph export "$graphs/03-decompose-education/college-premium-2.pdf", replace

gr tw (line gap time if type == "wage", lw(medthick) col(ebblue)) ///
    (line gap time if type == "hweal", lw(medthick) col(purple)) ///
    (line gap time if type == "pkinc", lw(medthick) col(orange)), ///
    yscale(range(0 250)) ylabel(0(50)250) xtitle("") ytitle("College premium" "(% increase between no college and some college)") ///
    legend(off) xlabel(`=yq(1990, 1)'(20)`=yq(2020, 1)') scale(1.1) ///
    text(90 `=yq(2017, 1)' "Labor income" "(working-age population)", col(ebblue) size(small)) ///
    text(210 `=yq(2009, 1)' "Pretax capital income", col(orange) size(small)) ///
    text(195 `=yq(2019, 1)' "Wealth", col(purple) size(small))
graph export "$graphs/03-decompose-education/college-premium-3.pdf", replace

gr tw (line gap time if type == "wage", lw(medthick) col(ebblue)) ///
    (line gap time if type == "peinc", lw(medthick) col(cranberry)) ///
    (line gap time if type == "hweal", lw(medthick) col(purple)) ///
    (line gap time if type == "pkinc", lw(medthick) col(orange)), ///
    yscale(range(0 250)) ylabel(0(50)250) xtitle("") ytitle("College premium" "(% increase between no college and some college)") ///
    legend(off) xlabel(`=yq(1990, 1)'(20)`=yq(2020, 1)') scale(1.1) ///
    text(90 `=yq(2017, 1)' "Labor income" "(working-age population)", col(ebblue) size(small)) ///
    text(130 `=yq(2010, 1)' "Pretax income", col(cranberry) size(small)) ///
    text(210 `=yq(2009, 1)' "Pretax capital income", col(orange) size(small)) ///
    text(195 `=yq(2019, 1)' "Wealth", col(purple) size(small))
graph export "$graphs/03-decompose-education/college-premium-4.pdf", replace

