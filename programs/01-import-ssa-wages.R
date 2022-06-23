# ---------------------------------------------------------------------------- #
# Fetch SSA wage data
# ---------------------------------------------------------------------------- #

if (!require("pacman")) {
    install.packages("pacman")
}
library(pacman)
library(gpinter)

p_load(dplyr)
p_load(magrittr)
p_load(rvest)
p_load(glue)
p_load(stringr)
p_load(readr)
p_load(purrr)
p_load(haven)

work_dir <- commandArgs(trailingOnly=TRUE)[1]

ssa_tables <- NULL

for (yr in 1991:2020) {
    # Scrap wages table
    url <- glue("https://www.ssa.gov/cgi-bin/netcomp.cgi?year={yr}")
    ssa_page <- read_html(url)
    wage_table <- ssa_page %>%
        html_node("body > table:nth-child(4)") %>%
        html_table(fill = TRUE, header = FALSE)

    # Clean it up
    wage_table <- wage_table[-c(1, 2), ] # Remove headers
    colnames(wage_table) <- c("thr", "pop", "cum_pop", "cum_pct", "total", "avg")
    wage_table <- wage_table %>%
        mutate(thr = parse_number(str_split_fixed(wage_table$thr, "—", n = 2)[, 1])) %>%
        mutate(pop = parse_number(pop)) %>%
        mutate(cum_pop = parse_number(cum_pop)) %>%
        mutate(cum_pct = parse_number(cum_pct)/100) %>%
        mutate(total = parse_number(total)) %>%
        mutate(avg = parse_number(avg)) %>%
        mutate(year = yr) %>%
        as_tibble()

    ssa_tables <- bind_rows(ssa_tables, wage_table)
}

write_dta(ssa_tables, file.path(work_dir, "01-import-ssa-wages", "ssa-tables.dta"))
