// -------------------------------------------------------------------------- //
// Setup paths, packages, themes, etc.
// -------------------------------------------------------------------------- //

clear all
set maxvar 10000

// -------------------------------------------------------------------------- //
// Paths
// -------------------------------------------------------------------------- //

if strpos("`c(pwd)'", "/Users/thomasblanchet") {
	global root "~/Dropbox/SaezZucman2014/RealTime/repository/real-time-inequality"
}

global programs   "$root/programs"
global work       "$root/work-data"
global graphs     "$root/graphs"
global tables     "$root/tables"
global rawdata    "$root/raw-data"
global auxiliary  "$root/auxiliary-data"
global transport  "$root/transport"
global website    "$root/website"

sysdir set PERSONAL "$programs"

global Rterm_path `"/usr/local/bin/r"'

set tracedepth 1

// -------------------------------------------------------------------------- //
// Stata commands to install
// -------------------------------------------------------------------------- //

cap which gtools
if (_rc != 0) {
	ssc install gtools
}

cap which ftools
if (_rc != 0) {
	ssc install ftools
}

cap which grstyle
if (_rc != 0) {
	ssc install grstyle
}

cap which renvars
if (_rc != 0) {
	ssc install renvars
}

cap which ereplace
if (_rc != 0) {
	ssc install ereplace
}

cap which enforce
if (_rc != 0) {
	ssc install enforce
}

cap which reghdfe
if (_rc != 0) {
	ssc install reghdfe
}

cap which _gwtmean
if (_rc != 0) {
	ssc install _gwtmean
}

cap which denton
if (_rc != 0) {
	ssc install denton
}

// -------------------------------------------------------------------------- //
// Theme for plots
// -------------------------------------------------------------------------- //

set scheme s2color
grstyle init
grstyle color background white
grstyle anglestyle vertical_tick horizontal
grstyle yesno draw_major_hgrid yes
grstyle yesno grid_draw_min yes
grstyle yesno grid_draw_max yes
grstyle color grid                   gs13
grstyle color major_grid             gs13
grstyle color minor_grid             gs13
grstyle linewidth major_grid thin

grstyle linewidth foreground   vvthin
grstyle linewidth background   vvthin
grstyle linewidth grid         vvthin
grstyle linewidth major_grid   vvthin
grstyle linewidth minor_grid   vvthin
grstyle linewidth tick         vvthin
grstyle linewidth minortick    vvthin

grstyle yesno extend_grid_low        yes
grstyle yesno extend_grid_high       yes
grstyle yesno extend_minorgrid_low   yes
grstyle yesno extend_minorgrid_high  yes
grstyle yesno extend_majorgrid_low   yes
grstyle yesno extend_majorgrid_high  yes

grstyle clockdir legend_position     6
grstyle gsize legend_key_xsize       8
grstyle color legend_line            background
grstyle yesno legend_force_draw      yes

grstyle margin axis_title          medsmall

graph set window fontface default
