// -------------------------------------------------------------------------- //
// Generate monthly DINA files
// -------------------------------------------------------------------------- //

tempfile cps_changes

global date_begin = ym(2022, 06)
global date_end   = ym(2022, 06)

global dina_last_year = 2019

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
        local dina_end = min(`t', ym($dina_last_year, 12))
        local dina_end = max(`dina_end', ym(1976, 12)) // Because the monthly CPS starts in 1976
        local dina_start = `dina_end' - 11
        
        noisily di "    -> Using DINA files covering " %tm = `dina_start' " to " %tm = `dina_end'
        
        // Retrieve information on changes in empoyment, etc. from CPS estimates
        use if inrange(time, `dina_start', `dina_end') | time == `t' using "$work/02-cps-monthly-cells/cps-monthly-cells.dta", clear
        // Calculate relative changes between the average of the DINA period and the current period
        foreach v of varlist unemployment_rate employment_rate earnings_rank {
            generate avg_`v' = `v' if inrange(time, `dina_start', `dina_end')
            generate last_`v' = `v' if time == `t'
        }
        gcollapse (mean) avg_* last_*, by(sex married educ age_group race)
        foreach v in unemployment_rate employment_rate earnings_rank {
            generate chg_`v' = (last_`v' - avg_`v')/(avg_`v'*(1 - avg_`v'))
        }
        drop avg_unemployment_rate avg_employment_rate avg_earnings_rank last_unemployment_rate last_employment_rate
        save "`cps_changes'", replace
        
        // Retrieve employment & unemployment data
        use if ym(year, month) == `t' using "$work/02-prepare-bls-employment/ssa-bls-employment.dta", clear
        merge 1:1 year month using "$work/02-prepare-ui/ui-data-sa.dta", keep(match) nogenerate
        merge 1:1 year month using "$work/02-prepare-pop/pop-data-monthly.dta", keep(match) nogenerate
        generate employment_rate = ssa_employed_monthly/monthly_adult
        generate frac_ui = ui_claims/monthly_adult
        local employment_rate_target = employment_rate
        loca frac_ui_target = frac_ui
        
        // ------------------------------------------------------------------ //
        // Update DINA microfile
        // ------------------------------------------------------------------ //
        
        if (`year' == 1976) {
            use if inlist(year, 1976) using "$work/02-prepare-dina/dina-simplified-normalized.dta", clear
        }
        else if (`year' <= ${dina_last_year}) {
            use if inlist(year, `year', `year' - 1) using "$work/02-prepare-dina/dina-simplified-normalized.dta", clear
            replace weight = `month'/12*weight if year == `year'
            replace weight = (1 - `month'/12)*weight if year == `year' - 1
            drop if weight == 0
        }
        else {
            use if inlist(year, ${dina_last_year}) using "$work/02-prepare-dina/dina-simplified-normalized.dta", clear
        }
        
        // Recalculate IDs to separate tax units with same ID in different years
        gegen id = group(year id), replace
        
        replace year = `year'
        generate month = `month', after(year)
        
        // Rescale population, keeping the Forbes 400 observation at 400 if necessary
        merge n:1 year month using "$work/02-prepare-pop/pop-data-monthly.dta", nogenerate keep(match) assert(match using) keepusing(monthly_adult)
        quietly count if top400
        if (r(N) == 0) {
            summarize weight, meanonly
            replace weight = weight/r(sum)*monthly_adult
        }
        else {
            summarize weight if !top400, meanonly
            replace weight = weight/r(sum)*(monthly_adult - 800) if !top400
            
            summarize weight if top400, meanonly
            replace weight = weight/r(sum)*800 if top400   
        }
        
        // Match with CPS info
        merge n:1 educ age_group sex married race using "`cps_changes'", ///
            nogenerate keep(match) assert(match using)
        gegen cell = group(educ age_group sex married race)
        
        generate has_ui = (uiinc > 0)
        generate employed = (dina_flemp > 0)
        
        // ------------------------------------------------------------------ //
        // Adjust employment
        // ------------------------------------------------------------------ //
        
        // Gap in employment numbers
        summarize employed [aw=weight], meanonly
        local employment_rate_source = r(mean)
        
        local employment_rate_delta = `employment_rate_target' - `employment_rate_source'
        
        noisily di "    -> Adjusting number employed people"
        noisily di "        * Source employment rate = " %6.4g = 100*`employment_rate_source' "%"
        noisily di "        * Target employment rate = " %6.4g = 100*`employment_rate_target' "%"
        noisily di "        * Difference = " %5.3g = 100*`employment_rate_delta' "%"
        
        // Current employment within each cell
        gegen employment_rate = mean(employed) [aw=weight], by(cell)
        // Convert to absolute change in employment rate
        replace chg_employment_rate = chg_employment_rate*employment_rate*(1 - employment_rate)
        // Calibrate changes in the unemployment rate: we adjust the variable
        // chg_employment_rate to match the difference between the source and
        // the target, but do it in proportion to employment_rate*(1 - employment_rate)
        // to keep everything in relative terms
        generate k = employment_rate*(1 - employment_rate)
        summarize k [aw=weight], meanonly
        replace k = k/r(mean)
        
        summarize chg_employment_rate [aw=weight], meanonly
        replace chg_employment_rate = chg_employment_rate + k*(`employment_rate_delta' - r(mean))
        generate new_employment_rate = employment_rate + chg_employment_rate
        drop k
        
        // The adjustment may saturate some cells (typically those with 0% or 100%
        // employment already). So we adjust if cells become saturated, we redistribute
        // the saturating mass to other cells until there is no saturation anymore
        // (note: this is a rare occurence)
        while (1) {
            count if new_employment_rate > 1 | new_employment_rate < 0
            if (r(N) == 0) {
                continue, break
            }
            generate excess = max(0, new_employment_rate - 1) + min(0, new_employment_rate)
            
            replace new_employment_rate = 1 if new_employment_rate > 1
            replace new_employment_rate = 0 if new_employment_rate < 0
            
            generate k = employment_rate*(1 - employment_rate)
            summarize k [aw=weight], meanonly
            replace k = k/r(mean)
            
            summarize excess [aw=weight], meanonly
            replace new_employment_rate = new_employment_rate + k*r(mean)
            drop k excess
        }
        // Check that the new employment rate is valid
        noisily summarize new_employment_rate [aw=weight], meanonly
        assert reldif(r(mean), `employment_rate_target') < 1e-5
        assert inrange(new_employment_rate, 0, 1)
        
        // Then, modify employment at the margin within each cell
        sort id female
        generate u = uniform()
        hashsort cell -employed has_ui u
        // Calculate both right and left rank for each observation
        by cell: generate rank_r = sum(weight)
        by cell: replace rank_r = rank_r/rank_r[_N]
        by cell: generate rank_l = cond(_n == 1, 0, rank_r[_n - 1])
        
        generate employed_new = (rank_r <= new_employment_rate)
        // The observation at the margin is partially employed/partially not employed:
        // we split it in two to account for that
        generate at_margin = (new_employment_rate > rank_l) & (new_employment_rate < rank_r)
        // We also need to split an observation if they are the spouse of a splitted observation
        // to maintain consistency
        sort id female
        by id: generate spouse_at_margin = cond(married, at_margin[3 - _n], 0)
        // Note: tricky edge case to consider here: when two members of a couple are at the margin of
        // different cells. In that case need to split each obs in 4.
        generate num_split = 1
        replace num_split = 2 if (married == 0) & (at_margin == 1)
        replace num_split = 2 if (married == 1) & (at_margin == 1) & (spouse_at_margin == 0)
        replace num_split = 2 if (married == 1) & (at_margin == 0) & (spouse_at_margin == 1)
        replace num_split = 4 if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1)
        // Determine how much weight we'll have to redistribute for observations at the margin
        generate k = (new_employment_rate - rank_l)/(rank_r - rank_l) if at_margin
        by id: generate k_spouse = cond(married, k[3 - _n], .)
        // Expand observations
        expand num_split
        // Identify duplication numbers
        sort id female
        by id female: generate dup_id = _n
        assert inlist(dup_id, 1) if (num_split == 1)
        assert inlist(dup_id, 1, 2) if (num_split == 2)
        assert inlist(dup_id, 1, 2, 3, 4) if (num_split == 4)
        // Redistribute weights/adjustment employment dummy
        sort id
        // Case (1): single, at the margin
        by id: replace weight = weight*k       if (married == 0) & (at_margin == 1) & (dup_id == 1)
        by id: replace weight = weight*(1 - k) if (married == 0) & (at_margin == 1) & (dup_id == 2)
        by id: replace employed_new = 1        if (married == 0) & (at_margin == 1) & (dup_id == 1)
        by id: replace employed_new = 0        if (married == 0) & (at_margin == 1) & (dup_id == 2)
        // Case (2): married, at the margin, spouse not at the margin
        by id: replace weight = weight*k       if (married == 1) & (at_margin == 1) & (spouse_at_margin == 0) & (dup_id == 1)
        by id: replace weight = weight*(1 - k) if (married == 1) & (at_margin == 1) & (spouse_at_margin == 0) & (dup_id == 2)
        by id: replace employed_new = 1        if (married == 1) & (at_margin == 1) & (spouse_at_margin == 0) & (dup_id == 1)
        by id: replace employed_new = 0        if (married == 1) & (at_margin == 1) & (spouse_at_margin == 0) & (dup_id == 2)
        // Case (3): married, not at the margin, spouse at the margin
        by id: replace weight = weight*k_spouse       if (married == 1) & (at_margin == 0) & (spouse_at_margin == 1) & (dup_id == 1)
        by id: replace weight = weight*(1 - k_spouse) if (married == 1) & (at_margin == 0) & (spouse_at_margin == 1) & (dup_id == 2)
        // Case (4): married, at the margin, spouse at the margin as well in another cell
        // Subcase (4a): both employed
        by id: replace weight = weight*k*k_spouse if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 1)
        by id: replace employed_new = 1           if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 1)
        // Subcase (4b): not employed, spouse employed
        by id: replace weight = weight*(1 - k)*k_spouse if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 2) & (female == 1)
        by id: replace weight = weight*k*(1 - k_spouse) if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 2) & (female == 0)
        by id: replace employed_new = female            if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 2)
        by id: replace employed_new = !female           if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 2)
        // Subcase (4c): employed, spouse non employed
        by id: replace weight = weight*k*(1 - k_spouse) if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 3) & (female == 1)
        by id: replace weight = weight*(1 - k)*k_spouse if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 3) & (female == 0)
        by id: replace employed_new = !female           if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 3)
        by id: replace employed_new = female            if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 3)
        // Subcase (4d): none employed
        by id: replace weight = weight*(1 - k)*(1 - k_spouse) if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 4)
        by id: replace employed_new = 0                       if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 4)
        // Check
        gegen check = mean(employed_new) [pw=weight], by(cell)
        assert reldif(check, new_employment_rate) < 1e-5
        // Create new IDs
        gegen id = group(id dup_id), replace
        // Clean up
        drop u rank_r rank_l at_margin spouse_at_margin num_split k k_spouse dup_id check
        
        // ------------------------------------------------------------------ //
        // Adjust UI recipients
        // ------------------------------------------------------------------ //
        
        // Gap in employment numbers
        summarize has_ui [aw=weight], meanonly
        local frac_ui_source = r(mean)
        
        local frac_ui_delta = `frac_ui_target' - `frac_ui_source'
        
        noisily di "    -> Adjusting number of UI recipients"
        noisily di "        * Source fraction of UI recipients = " %6.4g = 100*`frac_ui_source' "%"
        noisily di "        * Target fraction of UI recipients = " %6.4g = 100*`frac_ui_target' "%"
        noisily di "        * Difference = " %5.3g = 100*`frac_ui_delta' "%"
        
        // Current employment within each cell
        gegen frac_ui = mean(has_ui) [aw=weight], by(cell)
        // Convert to absolute change in employment rate
        replace chg_unemployment_rate = chg_unemployment_rate*frac_ui*(1 - frac_ui)
        // Calibrate changes in the unemployment rate: we adjust the variable
        // chg_employment_rate to match the difference between the source and
        // the target, but do it in proportion to frac_ui*(1 - frac_ui)
        // to keep everythin in relative terms
        generate k = frac_ui*(1 - frac_ui)
        summarize k [aw=weight], meanonly
        replace k = k/r(mean)
        
        summarize chg_unemployment_rate [aw=weight], meanonly
        replace chg_unemployment_rate = chg_unemployment_rate + k*(`frac_ui_delta' - r(mean))
        generate new_frac_ui = frac_ui + chg_unemployment_rate
        drop k
        
        // The adjustment may saturate some cells (typically those with 0% or 100%
        // UI recipients already). So we adjust if cells become saturated, we redistribute
        // the saturating mass to other cells until there is no saturation anymore
        // (note: this is a rare occurence)
        while (1) {
            count if new_frac_ui > 1 | new_frac_ui < 0
            if (r(N) == 0) {
                continue, break
            }
            generate excess = max(0, new_frac_ui - 1) + min(0, new_frac_ui)
            
            replace new_frac_ui = 1 if new_frac_ui > 1
            replace new_frac_ui = 0 if new_frac_ui < 0
            
            generate k = frac_ui*(1 - frac_ui)
            summarize k [aw=weight], meanonly
            replace k = k/r(mean)
            
            summarize excess [aw=weight], meanonly
            replace new_frac_ui = new_frac_ui + k*r(mean)
            drop k excess
        }
        // Check that the new employment rate is valid
        noisily summarize new_frac_ui [aw=weight], meanonly
        assert reldif(r(mean), `frac_ui_target') < 1e-5
        assert inrange(new_frac_ui, 0, 1)
        
        // Then, modify employment at the margin within each cell
        sort id female
        generate u = uniform()
        hashsort cell -has_ui employed_new u
        // Calculate both right and left rank for each observation
        by cell: generate rank_r = sum(weight)
        by cell: replace rank_r = rank_r/rank_r[_N]
        by cell: generate rank_l = cond(_n == 1, 0, rank_r[_n - 1])
        
        generate has_ui_new = (rank_r <= new_frac_ui)
        // The observation at the margin is partially has_ui/partially not has_ui:
        // we split it in two to account for that
        generate at_margin = (new_frac_ui > rank_l) & (new_frac_ui < rank_r)
        // We also need to split an observation if they are the spouse of a splitted observation
        // to maintain consistency
        sort id female
        by id: generate spouse_at_margin = cond(married, at_margin[3 - _n], 0)
        // Note: tricky edge case to consider here: when two members of a couple are at the margin of
        // different cells. In that case need to split each obs in 4.
        generate num_split = 1
        replace num_split = 2 if (married == 0) & (at_margin == 1)
        replace num_split = 2 if (married == 1) & (at_margin == 1) & (spouse_at_margin == 0)
        replace num_split = 2 if (married == 1) & (at_margin == 0) & (spouse_at_margin == 1)
        replace num_split = 4 if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1)
        // Determine how much weight we'll have to redistribute for observations at the margin
        generate k = (new_frac_ui - rank_l)/(rank_r - rank_l) if at_margin
        by id: generate k_spouse = cond(married, k[3 - _n], .)
        // Expand observations
        expand num_split
        // Identify duplication numbers
        sort id female
        by id female: generate dup_id = _n
        assert inlist(dup_id, 1) if (num_split == 1)
        assert inlist(dup_id, 1, 2) if (num_split == 2)
        assert inlist(dup_id, 1, 2, 3, 4) if (num_split == 4)
        // Redistribute weights/adjustment employment dummy
        sort id
        // Case (1): single, at the margin
        by id: replace weight = weight*k       if (married == 0) & (at_margin == 1) & (dup_id == 1)
        by id: replace weight = weight*(1 - k) if (married == 0) & (at_margin == 1) & (dup_id == 2)
        by id: replace has_ui_new = 1          if (married == 0) & (at_margin == 1) & (dup_id == 1)
        by id: replace has_ui_new = 0          if (married == 0) & (at_margin == 1) & (dup_id == 2)
        // Case (2): married, at the margin, spouse not at the margin
        by id: replace weight = weight*k       if (married == 1) & (at_margin == 1) & (spouse_at_margin == 0) & (dup_id == 1)
        by id: replace weight = weight*(1 - k) if (married == 1) & (at_margin == 1) & (spouse_at_margin == 0) & (dup_id == 2)
        by id: replace has_ui_new = 1          if (married == 1) & (at_margin == 1) & (spouse_at_margin == 0) & (dup_id == 1)
        by id: replace has_ui_new = 0          if (married == 1) & (at_margin == 1) & (spouse_at_margin == 0) & (dup_id == 2)
        // Case (3): married, not at the margin, spouse at the margin
        by id: replace weight = weight*k_spouse       if (married == 1) & (at_margin == 0) & (spouse_at_margin == 1) & (dup_id == 1)
        by id: replace weight = weight*(1 - k_spouse) if (married == 1) & (at_margin == 0) & (spouse_at_margin == 1) & (dup_id == 2)
        // Case (4): married, at the margin, spouse at the margin as well in another cell
        // Subcase (4a): both has_ui
        by id: replace weight = weight*k*k_spouse if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 1)
        by id: replace has_ui_new = 1             if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 1)
        // Subcase (4b): not has_ui, spouse has_ui
        by id: replace weight = weight*(1 - k)*k_spouse if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 2) & (female == 1)
        by id: replace weight = weight*k*(1 - k_spouse) if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 2) & (female == 0)
        by id: replace has_ui_new = female              if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 2)
        by id: replace has_ui_new = !female             if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 2)
        // Subcase (4c): has_ui, spouse non has_ui
        by id: replace weight = weight*k*(1 - k_spouse) if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 3) & (female == 1)
        by id: replace weight = weight*(1 - k)*k_spouse if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 3) & (female == 0)
        by id: replace has_ui_new = !female             if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 3)
        by id: replace has_ui_new = female              if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 3)
        // Subcase (4d): none has_ui
        by id: replace weight = weight*(1 - k)*(1 - k_spouse) if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 4)
        by id: replace has_ui_new = 0                         if (married == 1) & (at_margin == 1) & (spouse_at_margin == 1) & (dup_id == 4)
        // Check
        gegen check = mean(has_ui_new) [pw=weight], by(cell)
        assert reldif(check, new_frac_ui) < 1e-5
        // Create new IDs
        gegen id = group(id dup_id), replace
        // Clean up
        drop u rank_r rank_l at_margin spouse_at_margin num_split k k_spouse dup_id check
        
        // ------------------------------------------------------------------ //
        // Rank in wage (and UI) distribution
        // ------------------------------------------------------------------ //
        
        noisily di "    -> Adjusting ranks in the earnings distribution"
            
        if (`dina_start' >= ym(1982, 1)) {
            // Current rank
            sort dina_flemp
            generate rank_flemp = sum(weight) if (dina_flemp > 0)
            replace rank_flemp = (rank_flemp - weight/2)/rank_flemp[_N] if (dina_flemp > 0)
                    
            sort uiinc
            generate rank_uiinc = sum(weight) if (uiinc > 0)
            replace rank_uiinc = (rank_uiinc - weight/2)/rank_uiinc[_N] if (uiinc > 0)
            
            // Adjust ranks in relative terms
            replace rank_flemp = rank_flemp + chg_earnings_rank*rank_flemp*(1 - rank_flemp)
            replace rank_uiinc = rank_uiinc + chg_earnings_rank*rank_uiinc*(1 - rank_uiinc)
            
            // Observations that have entered the support: give them their cell's rank
            replace rank_flemp = last_earnings_rank if (employed_new == 1) & (employed == 0)
            replace rank_uiinc = last_earnings_rank if (has_ui_new == 1) & (has_ui == 0)
            
            // Observations that have left the support: set their rank to missing
            replace rank_flemp = . if (employed_new == 0)
            replace rank_uiinc = . if (has_ui_new == 0)
            
            // Recalculate the rank
            sort rank_flemp
            replace rank_flemp = sum(weight) if !missing(rank_flemp)
            egen last = max(rank_flemp)
            replace rank_flemp = (rank_flemp - weight)/last
            drop last
            
            sort rank_uiinc
            replace rank_uiinc = sum(weight) if !missing(rank_uiinc)
            egen last = max(rank_uiinc)
            replace rank_uiinc = (rank_uiinc - weight)/last
            drop last
        }
        else {
            // Before 1982 the CPS has no monthly earnings data. So we just
            // to new emplyed/unemployed observations the same rank as
            // their cell's average, and otherwise do not change them.
            
            // Current rank
            sort dina_flemp
            generate rank_flemp = sum(weight) if (dina_flemp > 0)
            replace rank_flemp = (rank_flemp - weight/2)/rank_flemp[_N] if (dina_flemp > 0)
                    
            sort uiinc
            generate rank_uiinc = sum(weight) if (uiinc > 0)
            replace rank_uiinc = (rank_uiinc - weight/2)/rank_uiinc[_N] if (uiinc > 0)
            
            // Average rank by cell
            gegen avg_rank_flemp = mean(rank_flemp), by(cell)
            gegen avg_rank_uiinc = mean(rank_uiinc), by(cell)
            
            replace rank_flemp = avg_rank_flemp if !employed & employed_new
            replace rank_uiinc = avg_rank_uiinc if !has_ui & has_ui_new
            
            // Observations that have left the support: set their rank to missing
            replace rank_flemp = . if (employed_new == 0)
            replace rank_uiinc = . if (has_ui_new == 0)
            
            drop avg_rank_flemp avg_rank_uiinc
        }
            
        // Sanity check
        assert missing(rank_flemp) if !employed_new
        assert !missing(rank_flemp) if employed_new
        assert missing(rank_uiinc) if !has_ui_new
        assert !missing(rank_uiinc) if has_ui_new
        
        // Create within-tax unit IDs
        sort id
        by id: generate pid = _n
        
        // Housekeeping
        drop last_earnings_rank chg_unemployment_rate chg_employment_rate ///
            chg_earnings_rank cell employed employment_rate ///
            new_employment_rate has_ui frac_ui new_frac_ui uiinc ///
            dina_flemp dina_uiben
        
        rename employed_new employed
        rename has_ui_new has_ui
        
        save "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", replace

        // ------------------------------------------------------------------ //
        // Interpolate wages to correspond to microdata ranks
        // ------------------------------------------------------------------ //
        
        noisily di "    -> Distribute wages and UI benefits"
        
        // Export ranks to interpolate
        keep if employed
        sort rank_flemp
        keep id pid rank_flemp
        // Fix numerical inconsistencies
        replace rank_flemp = 0 if rank_flemp < 0
        replace rank_flemp = 1 if rank_flemp > 1
        save "$work/03-build-monthly-microfiles/rank-flemp-gpinter.dta", replace
        
        // Export tabulation to interpolate
        use if year == `year' & month == `month' using "$work/02-create-monthly-wages/monthly-tabulations-flemp.dta", clear
        rename flemp flemp_qcew
        keep p flemp_qcew
        save "$work/03-build-monthly-microfiles/tabul-flemp-gpinter.dta", replace
        
        // Interpolate with gpinter
        rsource using "$programs/03-interpolate-qcew.R", roptions(`" --vanilla --args "$work/03-build-monthly-microfiles" "')
        
        // ------------------------------------------------------------------ //
        // Same for UI benefits
        // ------------------------------------------------------------------ //
        
        use "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear
        
        // Export ranks to interpolate
        keep if has_ui
        sort rank_uiinc
        keep id pid rank_uiinc
        // Fix numerical inconsistencies
        replace rank_uiinc = 0 if rank_uiinc < 0
        replace rank_uiinc = 1 if rank_uiinc > 1
        save "$work/03-build-monthly-microfiles/rank-uiinc-gpinter.dta", replace
        
        // Export tabulation to interpolate
        use if year == min(`year', $dina_last_year) using "$work/02-prepare-ui/dina-ui-dist.dta", clear
        keep p avg_uiinc
        save "$work/03-build-monthly-microfiles/tabul-uiinc-gpinter.dta", replace
        
        // Interpolate with gpinter
        rsource using "$programs/03-interpolate-uiinc.R", roptions(`" --vanilla --args "$work/03-build-monthly-microfiles" "')
        
        // ------------------------------------------------------------------ //
        // Incorporate wages and UI benefits into the main file
        // ------------------------------------------------------------------ //
        
        use "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", clear 
        
        merge 1:1 id pid using "$work/03-build-monthly-microfiles/flemp-gpinter.dta", nogenerate assert(master match)
        merge 1:1 id pid using "$work/03-build-monthly-microfiles/uiinc-gpinter.dta", nogenerate assert(master match)
        
        rename flemp dina_flemp
        rename uiinc dina_uiben
        
        replace dina_flemp = 0 if !employed
        replace dina_uiben = 0 if !has_ui
        
        assert !missing(dina_flemp)
        assert !missing(dina_uiben)
        
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
        
        // ------------------------------------------------------------------ //
        // Explicit simulations of COVID relief rebates
        // ------------------------------------------------------------------ //    
        
        noisily di "    -> Other adjustments + income computations"
        
        // The checks depend on the AGI of the tax unit
        gegen fiinc = total(fiinc), by(id) replace
        
        generate covidrelief = 0
        
        // CARES Act relief rebates
        if (`year' == 2020 & inrange(`month', 4, 11)) {
            replace covidrelief = 1200 + 500*xkidspop if !married & filer
            replace covidrelief = 2400 + 500*xkidspop if married & filer
            
            generate phase_out_start = 75000 if !married & xkidspop == 0
            replace phase_out_start = 112500 if !married & xkidspop > 0
            replace phase_out_start = 150000 if married
            
            replace covidrelief = covidrelief + min(0, -0.05*(fiinc - phase_out_start))
            replace covidrelief = 0 if covidrelief < 0
            
            // Equal-split
            replace covidrelief = covidrelief/2 if married
            
            // Rescale of macro data
            summarize covidrelief [aw=weight]
            local ttcovidrelief = r(sum)
            replace covidrelief = covidrelief*(nipa_covidchecks/`ttcovidrelief')
            
            summarize othcash [aw=weight]
            local ttothcash = r(sum)
            
            replace othcash = othcash*((`ttothcash' - nipa_covidchecks)/`ttothcash')
            
            drop phase_out_start
        }
        // Second checks (Consolidated Appropriations)
        if (`year' == 2021 & inrange(`month', 1, 2)) {
            replace covidrelief = 600 + 600*xkidspop if !married & filer
            replace covidrelief = 1200 + 600*xkidspop if married & filer
            
            generate phase_out_start = 75000 if !married & xkidspop == 0
            replace phase_out_start = 112500 if !married & xkidspop > 0
            replace phase_out_start = 150000 if married
            
            replace covidrelief = covidrelief + min(0, -0.05*(fiinc - phase_out_start))
            replace covidrelief = 0 if covidrelief < 0
            
            // Equal-split
            replace covidrelief = covidrelief/2 if married
            
            // Rescale of macro data
            summarize covidrelief [aw=weight]
            local ttcovidrelief = r(sum)
            replace covidrelief = covidrelief*(nipa_covidchecks/`ttcovidrelief')
            
            summarize othcash [aw=weight]
            local ttothcash = r(sum)
            
            replace othcash = othcash*((`ttothcash' - nipa_covidchecks)/`ttothcash')
            
            drop phase_out_start
        }
        // Third checks (American Rescue Plan Act of 2021)
        if (`year' == 2021 & inrange(`month', 3, 11)) {
            replace covidrelief = 1400 + 1400*xkidspop if !married & filer
            replace covidrelief = 2800 + 1400*xkidspop if married & filer
            
            generate phase_out_start = 75000 if !married & xkidspop == 0
            replace phase_out_start = 112500 if !married & xkidspop > 0
            replace phase_out_start = 150000 if married
            
            replace covidrelief = covidrelief + min(0, -0.28*(fiinc - phase_out_start))
            replace covidrelief = 0 if covidrelief < 0
            
            // Equal-split
            replace covidrelief = covidrelief/2 if married
            
            // Rescale of macro data
            summarize covidrelief [aw=weight]
            local ttcovidrelief = r(sum)
            replace covidrelief = covidrelief*(nipa_covidchecks/`ttcovidrelief')
            
            summarize othcash [aw=weight]
            local ttothcash = r(sum)
            
            replace othcash = othcash*((`ttothcash' - nipa_covidchecks)/`ttothcash')
            
            drop phase_out_start
        }
        
        // ------------------------------------------------------------------ //
        // Redistribute surplus/deficits based on new distributions
        // ------------------------------------------------------------------ //

        // Surplus/deficit of social insurance
        generate surplus_ss = surplus - prisupenprivate
        
        // New approach: distribution-neutral (prop. to disposable income + medicare/medicaid)
        generate dispo = flemp + proprietors + rental + profits + corptax + fkfix - fknmo ///
            - contrib - othercontrib - taxes - estatetax - corptax + vet + othcash + covidrelief ///
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
        // Distribute excess subsidies in COVID times based on the distribution
        // estimated for PPP + 30% labor, 70% capital
        // ------------------------------------------------------------------ //

        if (nipa_covidsub > 0) {
            // Identify ranks in the distribution of people with positive
            // labor income
            summarize rank_flemp if flemp > 0
            generate rank_flemp_ppp = (rank_flemp - r(min))/(1 - r(min)) if flemp > 0
            
            append using "$work/02-distribute-ppp-covid/ppp-distribution.dta", generate(is_ppp)
            
            sort rank_flemp_ppp
            carryforward p frac_jobs share_wage_bill share_flemp share_housing_tenant ///
                share_fkfix share_princ if dina_flemp > 0, replace
            drop if is_ppp
            
            // Incidence: use 30% flemp, 70% capital (do not use declared use of
            // proceeds anymore)
            drop share_flemp
            generate share_flemp = 0.3
            generate share_ppp_capital = 0.7
            generate ppp_capital = proprietors + profits
            
            // Proceeds spent on payroll: distribute depending on percentile
            // of flemp distribution
            set seed 19920902
            generate covered_ppp = runiform() < frac_jobs & flemp > 0
            
            gegen share_flemp = firstnm(share_flemp), replace
            generate covidsub = 0
            replace covidsub = flemp*share_wage_bill if covered_ppp
            summarize covidsub [aw=weight]
            replace covidsub = (covidsub/r(mean))*(nipa_covidsub/monthly_adult)*share_flemp
            
            // Rest of proceeds distributed according to capital income
            gegen share_capital = firstnm(share_ppp_capital), replace
            summarize ppp_capital [aw=weight]
            replace covidsub = covidsub + (ppp_capital/r(mean))*(nipa_covidsub/monthly_adult)*share_ppp_capital
            
            // Make sure we distribute the right amount of subsidy in total
            summarize covidsub [aw=weight]
            assert reldif(r(sum), nipa_covidsub) < 1e-7
            local ttcovidsub = r(mean)
        }
        else {
            generate covidsub = 0
        }
        
        // ------------------------------------------------------------------ //
        // Calculate broad income components
        // ------------------------------------------------------------------ //
        
        drop dispo
        
        generate princ = flemp + proprietors + rental + profits + corptax + ///
            fkfix - fknmo + prodtax - prodsub - covidsub + govin + npinc, after(weight)
        
        generate peinc = princ + uiben + penben - contrib + surplus, after(princ)
        
        generate dispo = peinc - surplus - govin - npinc - othercontrib ///
            - taxes - estatetax - corptax - prodtax + prodsub + covidsub + vet + othcash + covidrelief, after(peinc)
        
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
        
        // Import Forbes 400 monthly total if available
        merge n:1 year month using "$work/01-import-forbes/forbes400-monthly.dta", keep(master match)
        // Monthly Forbes only exists in recent years, we skip this step is not available
        cap assert _merge == 3
        if (_rc == 0) {
            // Check there is indeed a Forbes observation
            count if top400
            assert r(N) > 0
            
            generate dina_hweal = dina_housing_tenant + dina_housing_owner - dina_mortgage_tenant - ///
                dina_mortgage_owner + dina_equ_scorp + dina_equ_nscorp + dina_business + dina_pensions - dina_nonmortage + dina_fixed if top400
            
            foreach compo in housing_tenant housing_owner mortgage_tenant ///
                             mortgage_owner equ_scorp equ_nscorp business pensions nonmortage fixed {
                                     
                generate `compo' = dina_`compo'/dina_hweal*forbes_wealth/800 if top400
                
                summarize dina_`compo' [aw=weight] if top400, meanonly
                local tot_forbes = r(sum)
                summarize dina_`compo' [aw=weight] if !top400, meanonly
                local coef = (fa_`compo'[1] - `tot_forbes')/r(sum)
                di "`compo': `coef'"
                replace `compo' = dina_`compo'*`coef' if !top400
            }
            
            drop dina_hweal
        }
        else {
            assert _merge == 1
            foreach compo in housing_tenant housing_owner mortgage_tenant mortgage_owner ///
                             equ_scorp equ_nscorp business pensions nonmortage fixed {
                                 
                summarize dina_`compo' [aw=weight], meanonly
                local coef = fa_`compo'[1]/r(sum)
                di "`compo': `coef'"
                generate `compo' = dina_`compo'*`coef'
            }
        }
        drop _merge
        
        generate hweal = housing_tenant + housing_owner - mortgage_tenant - ///
                mortgage_owner + equ_scorp + equ_nscorp + business + pensions - nonmortage + fixed
                
        keep year month id top400 weight princ peinc dispo poinc married age sex race educ flemp contrib uiben ///
            penben surplus proprietors rental profits fkfix govin fknmo corptax ///
            prodtax prodsub taxes estatetax othercontrib vet othcash medicare ///
            medicaid otherkin colexp prisupenprivate prisupgov govcontrib ///
            covidrelief covidsub surplus_ss housing_tenant housing_owner mortgage_tenant ///
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
        save "$work/03-build-monthly-microfiles/microfiles/dina-monthly-`year'm`month'.dta", replace
    }
}
