// -------------------------------------------------------------------------- //
// Import DINA microdata
// -------------------------------------------------------------------------- //

foreach year of numlist 1975/2019 {
    use "$rawdata/dina-data/microfiles/usdina`year'.dta", clear
        
    replace dweght = dweght/1e5
    
    keep id dweght princ flemp flsup flwag flmil flprl fkinc fkhou fkequ ///
        fkfix fkbus fkpen fkprk fksubk flsubl fkmor fknmo hwbus hwpen hwequ proprestax ///
        propbustax corptax govin npinc plcon plobe plpbe ssinc_di peninc ///
        plben prisupen plpbe plobe peinc invpen pkinc rentalhome rentalmort ///
        ownerhome_heter ownermort nonmort scorw hwequ hwfix hwpen hwbus hwfix ///
        hweal poinc dicsh ditax dicab divet otherkin medicare medicaid ///
        inkindinc colexp estatetax othercontrib prisupenprivate prisupgov ///
        fiinc xkidspop married age female ssuicontrib uiinc top400 filer potax salestax
    generate year = `year', before(id)
    
    tempfile dina`year'
    local dinafiles `dinafiles' "`dina`year'''"
    save "`dina`year'''", replace
}
clear
append using `dinafiles'
compress
save "$work/01-import-dina/dina-full.dta", replace

// -------------------------------------------------------------------------- //
// DINA totals from the microfiles (some quantities not
// from national accounts)
// -------------------------------------------------------------------------- //

use "$work/01-import-dina/dina-full.dta", clear

generate dina_taxunits = cond(married, 0.5, 1)
generate dina_adults = 1

ds year id dweght, not
local vars = r(varlist)

gcollapse (sum) `vars' [pw=dweght], by(year)

save "$work/01-import-dina/dina-full-aggregates.dta", replace
