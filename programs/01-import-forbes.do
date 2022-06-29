// -------------------------------------------------------------------------- //
// Import the monthly Forbes data scraped using Python
// -------------------------------------------------------------------------- //

import delimited "$rawdata/forbes-data/forbes.csv", bindquote(strict) clear

keep year month uri countryofcitizenship finalworth

keep if countryofcitizenship == "United States"

gsort year month -finalworth
by year month: generate rank = _n
keep if rank <= 400

replace finalworth = finalworth*1e6

gcollapse (sum) forbes_wealth=finalworth, by(year month)

save "$work/01-import-forbes/forbes400-monthly.dta", replace


