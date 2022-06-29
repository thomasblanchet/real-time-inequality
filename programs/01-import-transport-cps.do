// -------------------------------------------------------------------------- //
// Import CPS data to be matched with DINA
// -------------------------------------------------------------------------- //

cap mkdir "$transport"
cap mkdir "$transport/cps"

clear
save "$work/01-import-transport-cps/cps-transport-summary.dta", replace emptyok

// -------------------------------------------------------------------------- //
// Import the data
// -------------------------------------------------------------------------- //

clear
quietly infix                ///
  int     year      1-4      ///
  long    serial    5-9      ///
  byte    month     10-11    ///
  str     cpsid     12-25    ///
  byte    asecflag  26-26    ///
  byte    hflag     27-27    ///
  double  asecwth   28-37    ///
  byte    pernum    38-39    ///
  str     cpsidp    40-53    ///
  double  asecwt    54-63    ///
  byte    age       64-65    ///
  byte    sex       66-66    ///
  int     race      67-69    ///
  byte    sploc     70-71    ///
  int     hispan    72-74    ///
  byte    empstat   75-76    ///
  int     educ      77-79    ///
  double  incwage   80-87    ///
  double  incbus    88-95    ///
  double  incfarm   96-103   ///
  long    incss     104-109  ///
  long    incwelfr  110-115  ///
  long    incgov    116-120  ///
  double  incretir  121-128  ///
  long    incdrt    129-133  ///
  long    incint    134-140  ///
  long    incunemp  141-146  ///
  long    incwkcom  147-152  ///
  long    incvet    153-159  ///
  long    incdivid  160-166  ///
  long    incrent   167-173  ///
  long    incrann   174-179  ///
  long    incpens   180-186  ///
  using "$rawdata/cps-data/cps.dat"

replace asecwth  = asecwth  / 10000
replace asecwt   = asecwt   / 10000

format asecwth  %10.4f
format asecwt   %10.4f
format incwage  %8.0f
format incbus   %8.0f
format incfarm  %8.0f
format incretir %8.0f

label var year     `"Survey year"'
label var serial   `"Household serial number"'
label var month    `"Month"'
label var cpsid    `"CPSID, household record"'
label var asecflag `"Flag for ASEC"'
label var hflag    `"Flag for the 3/8 file 2014"'
label var asecwth  `"Annual Social and Economic Supplement Household weight"'
label var pernum   `"Person number in sample unit"'
label var cpsidp   `"CPSID, person record"'
label var asecwt   `"Annual Social and Economic Supplement Weight"'
label var age      `"Age"'
label var sex      `"Sex"'
label var race     `"Race"'
label var sploc    `"Person number of spouse (from programming)"'
label var hispan   `"Hispanic origin"'
label var empstat  `"Employment status"'
label var educ     `"Educational attainment recode"'
label var incwage  `"Wage and salary income"'
label var incbus   `"Non-farm business income"'
label var incfarm  `"Farm income"'
label var incss    `"Social Security income"'
label var incwelfr `"Welfare (public assistance) income"'
label var incgov   `"Income from other govt programs"'
label var incretir `"Retirement income"'
label var incdrt   `"Income from dividends, rent, trusts"'
label var incint   `"Income from interest"'
label var incunemp `"Income from unemployment benefits"'
label var incwkcom `"Income from worker's compensation"'
label var incvet   `"Income from veteran's benefits"'
label var incdivid `"Income from dividends"'
label var incrent  `"Income from rent"'
label var incrann  `"Retirement income from annuities"'
label var incpens  `"Pension income"'

label define month_lbl 01 `"January"'
label define month_lbl 02 `"February"', add
label define month_lbl 03 `"March"', add
label define month_lbl 04 `"April"', add
label define month_lbl 05 `"May"', add
label define month_lbl 06 `"June"', add
label define month_lbl 07 `"July"', add
label define month_lbl 08 `"August"', add
label define month_lbl 09 `"September"', add
label define month_lbl 10 `"October"', add
label define month_lbl 11 `"November"', add
label define month_lbl 12 `"December"', add
label values month month_lbl

label define asecflag_lbl 1 `"ASEC"'
label define asecflag_lbl 2 `"March Basic"', add
label values asecflag asecflag_lbl

label define hflag_lbl 0 `"5/8 file"'
label define hflag_lbl 1 `"3/8 file"', add
label values hflag hflag_lbl

label define age_lbl 00 `"Under 1 year"'
label define age_lbl 01 `"1"', add
label define age_lbl 02 `"2"', add
label define age_lbl 03 `"3"', add
label define age_lbl 04 `"4"', add
label define age_lbl 05 `"5"', add
label define age_lbl 06 `"6"', add
label define age_lbl 07 `"7"', add
label define age_lbl 08 `"8"', add
label define age_lbl 09 `"9"', add
label define age_lbl 10 `"10"', add
label define age_lbl 11 `"11"', add
label define age_lbl 12 `"12"', add
label define age_lbl 13 `"13"', add
label define age_lbl 14 `"14"', add
label define age_lbl 15 `"15"', add
label define age_lbl 16 `"16"', add
label define age_lbl 17 `"17"', add
label define age_lbl 18 `"18"', add
label define age_lbl 19 `"19"', add
label define age_lbl 20 `"20"', add
label define age_lbl 21 `"21"', add
label define age_lbl 22 `"22"', add
label define age_lbl 23 `"23"', add
label define age_lbl 24 `"24"', add
label define age_lbl 25 `"25"', add
label define age_lbl 26 `"26"', add
label define age_lbl 27 `"27"', add
label define age_lbl 28 `"28"', add
label define age_lbl 29 `"29"', add
label define age_lbl 30 `"30"', add
label define age_lbl 31 `"31"', add
label define age_lbl 32 `"32"', add
label define age_lbl 33 `"33"', add
label define age_lbl 34 `"34"', add
label define age_lbl 35 `"35"', add
label define age_lbl 36 `"36"', add
label define age_lbl 37 `"37"', add
label define age_lbl 38 `"38"', add
label define age_lbl 39 `"39"', add
label define age_lbl 40 `"40"', add
label define age_lbl 41 `"41"', add
label define age_lbl 42 `"42"', add
label define age_lbl 43 `"43"', add
label define age_lbl 44 `"44"', add
label define age_lbl 45 `"45"', add
label define age_lbl 46 `"46"', add
label define age_lbl 47 `"47"', add
label define age_lbl 48 `"48"', add
label define age_lbl 49 `"49"', add
label define age_lbl 50 `"50"', add
label define age_lbl 51 `"51"', add
label define age_lbl 52 `"52"', add
label define age_lbl 53 `"53"', add
label define age_lbl 54 `"54"', add
label define age_lbl 55 `"55"', add
label define age_lbl 56 `"56"', add
label define age_lbl 57 `"57"', add
label define age_lbl 58 `"58"', add
label define age_lbl 59 `"59"', add
label define age_lbl 60 `"60"', add
label define age_lbl 61 `"61"', add
label define age_lbl 62 `"62"', add
label define age_lbl 63 `"63"', add
label define age_lbl 64 `"64"', add
label define age_lbl 65 `"65"', add
label define age_lbl 66 `"66"', add
label define age_lbl 67 `"67"', add
label define age_lbl 68 `"68"', add
label define age_lbl 69 `"69"', add
label define age_lbl 70 `"70"', add
label define age_lbl 71 `"71"', add
label define age_lbl 72 `"72"', add
label define age_lbl 73 `"73"', add
label define age_lbl 74 `"74"', add
label define age_lbl 75 `"75"', add
label define age_lbl 76 `"76"', add
label define age_lbl 77 `"77"', add
label define age_lbl 78 `"78"', add
label define age_lbl 79 `"79"', add
label define age_lbl 80 `"80"', add
label define age_lbl 81 `"81"', add
label define age_lbl 82 `"82"', add
label define age_lbl 83 `"83"', add
label define age_lbl 84 `"84"', add
label define age_lbl 85 `"85"', add
label define age_lbl 86 `"86"', add
label define age_lbl 87 `"87"', add
label define age_lbl 88 `"88"', add
label define age_lbl 89 `"89"', add
label define age_lbl 90 `"90 (90+, 1988-2002)"', add
label define age_lbl 91 `"91"', add
label define age_lbl 92 `"92"', add
label define age_lbl 93 `"93"', add
label define age_lbl 94 `"94"', add
label define age_lbl 95 `"95"', add
label define age_lbl 96 `"96"', add
label define age_lbl 97 `"97"', add
label define age_lbl 98 `"98"', add
label define age_lbl 99 `"99+"', add
label values age age_lbl

label define sex_lbl 1 `"Male"'
label define sex_lbl 2 `"Female"', add
label define sex_lbl 9 `"NIU"', add
label values sex sex_lbl

label define race_lbl 100 `"White"'
label define race_lbl 200 `"Black"', add
label define race_lbl 300 `"American Indian/Aleut/Eskimo"', add
label define race_lbl 650 `"Asian or Pacific Islander"', add
label define race_lbl 651 `"Asian only"', add
label define race_lbl 652 `"Hawaiian/Pacific Islander only"', add
label define race_lbl 700 `"Other (single) race, n.e.c."', add
label define race_lbl 801 `"White-Black"', add
label define race_lbl 802 `"White-American Indian"', add
label define race_lbl 803 `"White-Asian"', add
label define race_lbl 804 `"White-Hawaiian/Pacific Islander"', add
label define race_lbl 805 `"Black-American Indian"', add
label define race_lbl 806 `"Black-Asian"', add
label define race_lbl 807 `"Black-Hawaiian/Pacific Islander"', add
label define race_lbl 808 `"American Indian-Asian"', add
label define race_lbl 809 `"Asian-Hawaiian/Pacific Islander"', add
label define race_lbl 810 `"White-Black-American Indian"', add
label define race_lbl 811 `"White-Black-Asian"', add
label define race_lbl 812 `"White-American Indian-Asian"', add
label define race_lbl 813 `"White-Asian-Hawaiian/Pacific Islander"', add
label define race_lbl 814 `"White-Black-American Indian-Asian"', add
label define race_lbl 815 `"American Indian-Hawaiian/Pacific Islander"', add
label define race_lbl 816 `"White-Black--Hawaiian/Pacific Islander"', add
label define race_lbl 817 `"White-American Indian-Hawaiian/Pacific Islander"', add
label define race_lbl 818 `"Black-American Indian-Asian"', add
label define race_lbl 819 `"White-American Indian-Asian-Hawaiian/Pacific Islander"', add
label define race_lbl 820 `"Two or three races, unspecified"', add
label define race_lbl 830 `"Four or five races, unspecified"', add
label define race_lbl 999 `"Blank"', add
label values race race_lbl

label define hispan_lbl 000 `"Not Hispanic"'
label define hispan_lbl 100 `"Mexican"', add
label define hispan_lbl 102 `"Mexican American"', add
label define hispan_lbl 103 `"Mexicano/Mexicana"', add
label define hispan_lbl 104 `"Chicano/Chicana"', add
label define hispan_lbl 108 `"Mexican (Mexicano)"', add
label define hispan_lbl 109 `"Mexicano/Chicano"', add
label define hispan_lbl 200 `"Puerto Rican"', add
label define hispan_lbl 300 `"Cuban"', add
label define hispan_lbl 400 `"Dominican"', add
label define hispan_lbl 500 `"Salvadoran"', add
label define hispan_lbl 600 `"Other Hispanic"', add
label define hispan_lbl 610 `"Central/South American"', add
label define hispan_lbl 611 `"Central American, (excluding Salvadoran)"', add
label define hispan_lbl 612 `"South American"', add
label define hispan_lbl 901 `"Do not know"', add
label define hispan_lbl 902 `"N/A (and no response 1985-87)"', add
label values hispan hispan_lbl

label define empstat_lbl 00 `"NIU"'
label define empstat_lbl 01 `"Armed Forces"', add
label define empstat_lbl 10 `"At work"', add
label define empstat_lbl 12 `"Has job, not at work last week"', add
label define empstat_lbl 20 `"Unemployed"', add
label define empstat_lbl 21 `"Unemployed, experienced worker"', add
label define empstat_lbl 22 `"Unemployed, new worker"', add
label define empstat_lbl 30 `"Not in labor force"', add
label define empstat_lbl 31 `"NILF, housework"', add
label define empstat_lbl 32 `"NILF, unable to work"', add
label define empstat_lbl 33 `"NILF, school"', add
label define empstat_lbl 34 `"NILF, other"', add
label define empstat_lbl 35 `"NILF, unpaid, lt 15 hours"', add
label define empstat_lbl 36 `"NILF, retired"', add
label values empstat empstat_lbl

label define educ_lbl 000 `"NIU or no schooling"'
label define educ_lbl 001 `"NIU or blank"', add
label define educ_lbl 002 `"None or preschool"', add
label define educ_lbl 010 `"Grades 1, 2, 3, or 4"', add
label define educ_lbl 011 `"Grade 1"', add
label define educ_lbl 012 `"Grade 2"', add
label define educ_lbl 013 `"Grade 3"', add
label define educ_lbl 014 `"Grade 4"', add
label define educ_lbl 020 `"Grades 5 or 6"', add
label define educ_lbl 021 `"Grade 5"', add
label define educ_lbl 022 `"Grade 6"', add
label define educ_lbl 030 `"Grades 7 or 8"', add
label define educ_lbl 031 `"Grade 7"', add
label define educ_lbl 032 `"Grade 8"', add
label define educ_lbl 040 `"Grade 9"', add
label define educ_lbl 050 `"Grade 10"', add
label define educ_lbl 060 `"Grade 11"', add
label define educ_lbl 070 `"Grade 12"', add
label define educ_lbl 071 `"12th grade, no diploma"', add
label define educ_lbl 072 `"12th grade, diploma unclear"', add
label define educ_lbl 073 `"High school diploma or equivalent"', add
label define educ_lbl 080 `"1 year of college"', add
label define educ_lbl 081 `"Some college but no degree"', add
label define educ_lbl 090 `"2 years of college"', add
label define educ_lbl 091 `"Associate's degree, occupational/vocational program"', add
label define educ_lbl 092 `"Associate's degree, academic program"', add
label define educ_lbl 100 `"3 years of college"', add
label define educ_lbl 110 `"4 years of college"', add
label define educ_lbl 111 `"Bachelor's degree"', add
label define educ_lbl 120 `"5+ years of college"', add
label define educ_lbl 121 `"5 years of college"', add
label define educ_lbl 122 `"6+ years of college"', add
label define educ_lbl 123 `"Master's degree"', add
label define educ_lbl 124 `"Professional school degree"', add
label define educ_lbl 125 `"Doctorate degree"', add
label define educ_lbl 999 `"Missing/Unknown"', add
label values educ educ_lbl

// -------------------------------------------------------------------------- //
// Clean it up
// -------------------------------------------------------------------------- //

// Account for 3/8 file redesign <https://cps.ipums.org/cps/three_eighths.shtml>
// We use both sample since we're insterested in the entire period
foreach v of varlist asecwt asecwth {
    replace `v' = (3/8)*`v' if hflag == 1
    replace `v' = (5/8)*`v' if hflag == 0
}

// Keep only people 20+
keep if age >= 20

// Income variables
generate cps_wage  = incwage
generate cps_pens  = incretir + cond(year < 2019, 0, incrann + incpens)
generate cps_bus   = incbus + incfarm
generate cps_int   = incint
generate cps_drt   = cond(year <= 1987, incdrt, incdivid + incrent)
generate cps_gov   = cond(year <= 1987, incgov, incunemp + incwkco + incvet)
generate cps_ss    = incss
generate cps_welfr = incwelfr

// Demographics
generate sex_cps = sex
generate age_cps = min(age, 80)

generate race_cps = .
replace race_cps = 1 if (race == 100 & hispan == 0) // Non-hispanic white
replace race_cps = 2 if (race == 200 & hispan == 0) // Black
replace race_cps = 3 if inrange(hispan, 1, 699) // Hispanic
replace race_cps = 4 if missing(race_cps)

// Education
recode educ ///
    (000/019 = 01)  /// No schooling to 4th grade
    (020/039 = 02)  /// 5th to 8th grade
    (040     = 03)  /// 9th grade
    (050     = 04)  /// 10th grade
    (060     = 05)  /// 11th grade
    (070/079 = 06)  /// 12th grade (High School)
    (080/089 = 07)  /// 1 year of college/some college but no degree
    (090/099 = 08)  /// 2 years of college/associate degree
    (100/119 = 09)  /// 3-4 years of college/bachelor degree
    (110/199 = 10), /// 5+ years of college
    generate(educ_cps)
    
rename asecwt weight

keep if inrange(year, 1976, 2020)

keep year serial pernum sploc weight *_cps cps_*
label drop _all

// Add group quarters people from ACS
append using "$work/01-import-transport-acs/acs-gq-data.dta", generate(acs)
gegen num_acs = total(acs), by(year)
assert num_acs > 0
drop num_acs

// Create new IDs
gegen serial = group(acs serial), replace

// Identify couples
generate spouse1 = min(pernum, sploc)
generate spouse2 = max(pernum, sploc)
gegen id = group(year serial spouse1 spouse2), counts(num)
assert num <= 2

sort year id
generate old = (age >= 65)
generate married = (num >= 2)
drop num
generate employed = (cps_wage > 0)

// Check people identifiers are unique
gegen num = count(weight), by(year id pernum)
assert num == 1
drop num

// Income is for the year T-1
replace year = year - 1

// Export univariate distributions
local firstiter = 1
foreach v of varlist cps_* {
    preserve
        // Equal-split the income
        gegen `v' = mean(`v'), by(year id) replace
        
        // Key statistics
        local stub = substr("`v'", 5, .)
        generate cps_has_`stub' = (`v' > 0)
        sort year `v'
        by year: generate rank = sum(weight) if cps_has_`stub'
        by year: replace rank = (rank - weight/2)/rank[_N] if cps_has_`stub'
        
        generate cps_bot50_`stub' = `v'*inrange(rank, 0, 0.5)
        generate cps_top10_`stub' = `v'*inrange(rank, 0.9, 1)
        
        gcollapse (sum) `v' cps_bot50_`stub' cps_top10_`stub' cps_has_`stub' (rawsum) pop=weight [pw=weight], by(year)
        
        replace cps_bot50_`stub' = 100*cps_bot50_`stub'/`v'
        replace cps_top10_`stub' = 100*cps_top10_`stub'/`v'
        replace cps_has_`stub' = 100*cps_has_`stub'/pop
        replace `v' = `v'/(pop*cps_has_`stub'/100)
        keep year `v' cps_bot50_`stub' cps_top10_`stub' cps_has_`stub'
        
        // Combine & save
        if (`firstiter' == 0) {
            merge 1:1 year using "$work/01-import-transport-cps/cps-transport-summary.dta", nogenerate
        }
        save "$work/01-import-transport-cps/cps-transport-summary.dta", replace
    restore
    local firstiter = 0
}

// Export data by individual
gisid year serial pernum
save "$work/01-import-transport-cps/cps-full.dta", replace

// Group by couple
gcollapse (max) old (sum) employed (firstnm) married (sum) cps_* (mean) weight, by(year id)

keep year id weight old married employed cps_*

// Export CSVs
levelsof year, local(yrs)
foreach yr of numlist `yrs' {
    export delimited id weight old married employed cps_* using "$transport/cps/cps`yr'.csv" if year == `yr', replace
}

// Check that all cells are represented
preserve
    gcollapse (count) weight, by(year married old employed)
    fillin year married old employed
    assert _fillin == 0 | (married == 0 & employed == 2)
restore


