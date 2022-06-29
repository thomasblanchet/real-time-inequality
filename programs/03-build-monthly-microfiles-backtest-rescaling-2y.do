// -------------------------------------------------------------------------- //
// Generate monthly DINA files
// -------------------------------------------------------------------------- //

tempfile cps_changes

global date_begin = ym(1976, 01)
global date_end   = ym(2019, 12)

set seed 19920902

foreach t of numlist $date_begin / $date_end {
    
    local year = year(dofm(`t'))
    local month = month(dofm(`t'))
    
    di "-> `year'm`month'"
    
    quietly {
        // ------------------------------------------------------------------ //
        // Preliminaries
        // ------------------------------------------------------------------ //
        
        // Period covered by DINA microfiles
        local dina_end = ym(`year' - 1, 12)
        local dina_end = max(`dina_end', ym(1976, 12)) // Because the monthly CPS starts in 1976
        local dina_start = `dina_end' - 11
        
        noisily di "    -> Using DINA files covering " %tm = `dina_start' " to " %tm = `dina_end'
        
        // ------------------------------------------------------------------ //
        // Update DINA microfile
        // ------------------------------------------------------------------ //
        
        if (`year' <= 1977) {
            use if inlist(year, 1976) using "$work/02-prepare-dina/dina-simplified-normalized.dta", clear
        }
        else {
            use if inlist(year, `year' - 2) using "$work/02-prepare-dina/dina-simplified-normalized.dta", clear
        }
        
        // Recalculate IDs to separate tax units with same ID in different years
        gegen id = group(year id), replace
        
        replace year = `year'
        generate month = `month', after(year)
        
        merge n:1 year month using "$work/02-prepare-pop/pop-data-monthly.dta", nogenerate keep(match) assert(match using) keepusing(monthly_adult)
        summarize weight, meanonly
        replace weight = weight/r(sum)*monthly_adult
        
        // ------------------------------------------------------------------ //
        // Rescale income components
        // ------------------------------------------------------------------ //

        noisily di "    -> Rescaling income components"
        
        // Income components to use
        local components flemp contrib uiben penben surplus proprietors rental ///
            profits fkfix govin fknmo corptax prodtax prodsub taxes estatetax othercontrib ///
            vet othcash medicare medicaid otherkin colexp prisupenprivate prisupgov ///
            govcontrib salestax proptax npinc
        
        // Rescale macro components (income)
        merge n:1 year month using "$work/02-prepare-nipa/nipa-simplified-monthly.dta", nogenerate keep(match) assert(match using)
        foreach compo in `components' {
            summarize dina_`compo' [aw=weight], meanonly
            local coef = nipa_`compo'[1]/r(sum)
            generate `compo' = dina_`compo'*`coef'
        }
        
        // Surplus/deficit of social insurance
        generate surplus_ss = surplus - prisupenprivate
        
        // New approach: distribution-neutral (prop. to disposable income + medicare/medicaid)
        generate dispo = flemp + proprietors + rental + profits + corptax + fkfix - fknmo ///
            - contrib - othercontrib - taxes - estatetax - corptax + vet + othcash ///
            + medicare + medicaid
        
        summarize dispo [aw=weight], meanonly
        local ttdispo = r(mean)
        
        summarize flemp [aw=weight], meanonly
        local ttflemp = r(mean)
        
        summarize prisupenprivate [aw=weight], meanonly
        local ttprisupenprivate = r(mean)
        
        summarize surplus_ss [aw=weight], meanonly
        local ttsurplus_ss = r(mean)
        
        summarize salestax [aw=weight], meanonly
        local ttsalestax = r(mean)
        
        replace prisupenprivate = flemp/`ttflemp'*`ttprisupenprivate' 
        replace surplus_ss = dispo/`ttdispo'*`ttsurplus_ss'
        replace surplus = prisupenprivate + surplus_ss
        
        // Surplus/deficit of government
        summarize prisupgov [aw=weight]
        local ttprisupgov = r(mean)
        
        replace prisupgov = dispo/`ttdispo'*`ttprisupgov'
        
        // Gov interest income
        summarize govin [aw=weight]
        local ttgovin = r(mean)
        replace govin = dispo/`ttdispo'*`ttgovin'
        
        // Indirect taxes added for posttax income
        generate potax = dispo/`ttdispo'*`ttsalestax'
        
        // ------------------------------------------------------------------ //
        // Calculate broad income components
        // ------------------------------------------------------------------ //
        
        drop dispo
        
        generate princ = flemp + proprietors + rental + profits + corptax + ///
            fkfix - fknmo + prodtax - prodsub + govin + npinc, after(weight)
        
        generate peinc = princ + uiben + penben - contrib + surplus, after(princ)
        
        generate dispo = peinc - surplus - govin - npinc - othercontrib ///
            - taxes - estatetax - corptax - prodtax + prodsub + vet + othcash, after(peinc)
        
        generate poinc = dispo - salestax + potax + medicare + medicaid + otherkin ///
            + govin + npinc + colexp + prisupenprivate + prisupgov, after(dispo)
        
        assert !missing(princ)
        assert !missing(peinc)
        assert !missing(dispo)
        assert !missing(poinc)
        
        // ------------------------------------------------------------------ //   
        // Calculate wealth
        // ------------------------------------------------------------------ //   

        noisily di "    -> Calculate wealth"
        
        // Rescale macro components (wealth)
        merge n:1 year month using "$work/02-prepare-fa/fa-simplified.dta", nogenerate keep(match) assert(match using)
        
        foreach compo in housing_tenant housing_owner mortgage_tenant mortgage_owner equ_scorp equ_nscorp business pensions nonmortage fixed {
            summarize dina_`compo' [aw=weight], meanonly
            local coef = fa_`compo'[1]/r(sum)
            di "`compo': `coef'"
            generate `compo' = dina_`compo'*`coef'
        }
        
        generate hweal = housing_tenant + housing_owner - mortgage_tenant - ///
                mortgage_owner + equ_scorp + equ_nscorp + business + pensions - nonmortage + fixed
                
        keep year month id weight princ peinc dispo poinc married age sex race educ flemp contrib uiben ///
            penben surplus proprietors rental profits fkfix govin fknmo corptax ///
            prodtax prodsub taxes estatetax othercontrib vet othcash medicare ///
            medicaid otherkin colexp prisupenprivate prisupgov govcontrib ///
            surplus_ss housing_tenant housing_owner mortgage_tenant ///
            mortgage_owner equ_scorp equ_nscorp business pensions nonmortage fixed hweal acs
        
        // ------------------------------------------------------------------ //
        // Display some results
        // ------------------------------------------------------------------ //
        
        noisily di "    -> Results:"
        pshare estimate princ [pw=weight], perc(99)
        noisily di "        * Top 1% factor income share   = " %6.4g = 100*e(b)[1, 2] "%"
        pshare estimate peinc [pw=weight], perc(99)
        noisily di "        * Top 1% pretax income share   = " %6.4g = 100*e(b)[1, 2] "%"
        pshare estimate poinc [pw=weight], perc(99)
        noisily di "        * Top 1% post-tax income share = " %6.4g = 100*e(b)[1, 2] "%"
        pshare estimate hweal [pw=weight], perc(99)
        noisily di "        * Top 1% wealth share          = " %6.4g = 100*e(b)[1, 2] "%"
        
        // ------------------------------------------------------------------ //
        // Save
        // ------------------------------------------------------------------ //
        
        noisily di "    -> Saving"
        
        compress
        save "$work/03-build-monthly-microfiles-backtest-rescaling-2y/microfiles/dina-monthly-`year'm`month'.dta", replace
    }
}
