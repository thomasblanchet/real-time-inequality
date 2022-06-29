# ---------------------------------------------------------------------------- #
# Incorporate SSA wages into the DINA data
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
p_load(ggplot2)
p_load(FNN)

work_dir <- commandArgs(trailingOnly = TRUE)

# ---------------------------------------------------------------------------- #
# Import SSA tabulations. Pre-1991, use IRS to extrapolate SSA.
# ---------------------------------------------------------------------------- #

gperc <- c(
    seq(0, 99000, 1000), seq(99100, 99900, 100),
    seq(99910, 99990, 10), seq(99991, 99999, 1)
)

dina_micro <- read_dta(file.path(work_dir, "01-import-dina", "dina-full.dta"))
ssa_tables <- read_dta(file.path(work_dir, "01-import-ssa-wages", "ssa-tables.dta"))
ssa_employment <- read_dta(file.path(work_dir, "02-prepare-bls-employment", "ssa-bls-employment-yearly.dta"))

gperc <- c(
    seq(0, 99000, 1000), seq(99100, 99900, 100),
    seq(99910, 99990, 10), seq(99991, 99999, 1)
)

ssa_tables_inter <- ssa_tables %>% group_by(year) %>% group_split() %>% map_dfr(~ {
    p <- .x$cum_pop/sum(.x$pop)
    p <- p[-length(p)]
    p <- c(0, p)

    dist <- tabulation_fit(
        p = p,
        threshold = .x$thr,
        bracketavg = .x$total/.x$pop,
        average = sum(.x$total)/sum(.x$pop)
    )
    return(as_tibble(generate_tabulation(dist, fractiles = gperc/1e5)) %>%
        transmute(p = gperc, year = first(.x$year), a_ssa = bracket_average))
})

dina_micro_tabul <- dina_micro %>%
    filter(flwag > 0) %>%
    group_by(year) %>%
    arrange(year, flwag) %>%
    mutate(rank = (cumsum(dweght) - dweght/2)/sum(dweght)) %>%
    mutate(bracket = findInterval(1e5*rank, gperc)) %>%
    group_by(year, bracket) %>%
    summarise(a_dina = weighted.mean(flwag, dweght)) %>%
    transmute(year, p = gperc[bracket], a_dina)

dina_ssa_tabul <- full_join(dina_micro_tabul, ssa_tables_inter) %>%
    group_by(year) %>%
    arrange(year, p) %>%
    mutate(n = diff(c(p, 1e5))) %>%
    mutate(a_dina = a_dina/weighted.mean(a_dina, n)) %>%
    mutate(a_ssa = a_ssa/weighted.mean(a_ssa, n))

dina_ssa_adj <- dina_ssa_tabul %>%
    mutate(ratio_ssa_dina = a_ssa/a_dina) %>%
    group_by(p) %>%
    summarise(ratio_ssa_dina = median(ratio_ssa_dina, na.rm = TRUE))

dina_ssa_tabul <- dina_ssa_tabul %>%
    left_join(dina_ssa_adj) %>%
    group_by(year) %>%
    mutate(a_ssa_extra = a_dina*ratio_ssa_dina) %>%
    mutate(s_ssa = a_ssa*n/weighted.mean(a_ssa, n)/1e5) %>%
    mutate(s_ssa_extra = a_ssa_extra*n/weighted.mean(a_ssa_extra, n)/1e5) %>%
    group_by(year) %>%
    arrange(year, desc(p)) %>%
    mutate(ts_ssa = cumsum(s_ssa)) %>%
    mutate(ts_ssa_extra = cumsum(s_ssa_extra))

ssa_tables_extra <- bind_rows(
    ssa_tables,
    dina_ssa_tabul %>%
        filter(year < 1991) %>%
        inner_join(ssa_employment) %>%
        group_by(year) %>%
        arrange(year, p) %>%
        transmute(
            year,
            thr = NA_real_,
            pop = ssa_employed*n/1e5,
            cum_pop = cumsum(pop),
            cum_pct = cum_pop/sum(pop),
            total = a_ssa_extra*pop,
            avg = a_ssa_extra
        )
)

# ---------------------------------------------------------------------------- #
# Create the SSA wage variable in the microfiles
# ---------------------------------------------------------------------------- #

# Add the year 2020
dina_micro <- bind_rows(dina_micro, dina_micro %>% filter(year == 2019) %>%  mutate(year = 2020))

dina_micro <- dina_micro %>%
    filter(year >= 1975) %>%
    group_by(year) %>%
    group_split() %>%
    map_dfr(~ {
        yr <- first(.x$year)

        # Mean wage from DINA
        mean_flwag <- weighted.mean(.x$flwag[.x$flwag > 0], .x$dweght[.x$flwag > 0])

        # Employed population from SSA
        ssa_employed <- ssa_employment %>% filter(year == yr) %>% pull(ssa_employed)

        # Distribution of SSA wage
        ssa_table <- ssa_tables_extra %>% filter(year == yr) %>% arrange(cum_pop)

        p <- ssa_table$cum_pop/sum(ssa_table$pop)
        p <- p[-length(p)]
        p <- c(0, p)

        if (all(is.na(ssa_table$thr))) {
            ssa_dist <- shares_fit(
                p = p,
                bracketshare = ssa_table$total/sum(ssa_table$total),
                average = mean_flwag
            )
        } else {
            ssa_dist <- tabulation_fit(
                p = p,
                threshold = ssa_table$thr/weighted.mean(ssa_table$avg, ssa_table$pop)*mean_flwag,
                bracketshare = ssa_table$total/sum(ssa_table$total),
                average = mean_flwag
            )
        }

        # Distribute wages in DINA files using same ranking. If the support needs
        # to be expanded, we do it to working-age non-filers.
        .x <- .x %>%
            mutate(i = (!filer) & (age < 65) & (flwag == 0)) %>%
            mutate(u = runif(n())) %>%
            arrange(desc(flwag), desc(i), u) %>%
            mutate(rank = cumsum(dweght)) %>%
            mutate(employed_ssa = (rank <= ssa_employed)) %>%
            group_by(employed_ssa) %>%
            select(-rank, -i) %>%
            arrange(employed_ssa, flwag, u) %>%
            mutate(rank_upper = cumsum(dweght)/sum(dweght)) %>%
            mutate(rank_lower = c(0, rank_upper[-n()])) %>%
            mutate(flwag_ssa = if_else(
                employed_ssa,
                fitted_quantile(ssa_dist, (rank_lower + rank_upper)/2),
                #bracket_average(ssa_dist, rank_lower, rank_upper),
                rep(0, n())
            )) %>%
            ungroup() %>%
            select(-employed_ssa, -u, -rank_lower, -rank_upper)

        return(.x)
    })

# ---------------------------------------------------------------------------- #
# Re-impute supplement to wages
# ---------------------------------------------------------------------------- #

# Impute flsup for SSA wages using the flsup value by wage rank/marital status/age
# (consistent with the way the imputation is done in DINA)
dina_micro <- dina_micro %>%
    mutate(employed = flwag > 0) %>%
    mutate(employed_ssa = flwag_ssa > 0) %>%
    mutate(old = (age >= 65)) %>%
    # DINA wage deciles
    group_by(year, employed) %>%
    arrange(year, employed, flwag) %>%
    mutate(rank = (cumsum(dweght) - dweght/2)/sum(dweght)) %>%
    mutate(rank = if_else(employed, rank, NA_real_)) %>%
    # SSA wage deciles
    group_by(year, employed_ssa) %>%
    arrange(year, employed_ssa, flwag_ssa) %>%
    mutate(rank_ssa = (cumsum(dweght) - dweght/2)/sum(dweght)) %>%
    mutate(rank_ssa = if_else(employed_ssa, rank_ssa, NA_real_)) %>%
    # Use the value from the observation with the closest rank within the cell
    group_by(year, married, old) %>%
    group_split() %>%
    map_dfr(~ {
        flsup_dina <- .x %>% filter(employed) %>% pull(flsup)
        rank_dina <- .x %>% filter(employed) %>% pull(rank)
        rank_ssa <- .x %>% pull(rank_ssa)

        .x[.x$employed_ssa, "flsup_ssa"] <- flsup_dina[get.knnx(
            data = rank_dina,
            query = rank_ssa[.x$employed_ssa],
            k = 1
        )$nn.index]
        .x[!(.x$employed_ssa), "flsup_ssa"] <- 0

        return(.x)
    })

# Rescale flsup_ssa to the aggregate
dina_micro <- dina_micro %>% group_by(year) %>% mutate(
    flsup_ssa = flsup_ssa/weighted.mean(flsup_ssa, dweght)*weighted.mean(flsup, dweght),
    flemp_ssa = flwag_ssa + flsup_ssa
) %>% ungroup() %>% select(-rank, -rank_ssa, -employed, -employed_ssa)

top_shares <- function(y, weights = NULL, p, rank_by = NULL) {
    if (is.null(weights)) {
        weights <- rep(1, length(y))
    }
    if (is.null(rank_by)) {
        rank_by <- y
    }
    data <- cbind(y, weights, rank_by)
    data <- na.omit(data)
    data <- data[order(data[, 3]), ]
    n <- nrow(data)

    # Calculate ranks
    r <- cumsum(data[, 2])
    r <- c(0, r[-n])/r[n]

    # Calculate top shares
    return(sapply(p, function(p) {
        return(sum(data[r >= p, 1]*data[r >= p, 2])/sum(data[, 1]*data[, 2]))
    }))
}

write_dta(dina_micro, file.path(work_dir, "02-add-ssa-wages", "dina-ssa-full.dta"))
