library(gpinter)
library(haven)
library(dplyr)

work_dir <- commandArgs(trailingOnly = TRUE)

data_rank <- read_dta(file.path(work_dir, "rank-uiinc-gpinter.dta"))
data_dist <- read_dta(file.path(work_dir, "tabul-uiinc-gpinter.dta"))

data_dist <- data_dist %>%
    arrange(p) %>%
    mutate(avg_uiinc = sort(avg_uiinc)) %>%
    mutate(n = diff(c(p, 1e5))) %>%
    mutate(avg_uiinc2 = round(1e7*avg_uiinc)) %>%
    group_by(avg_uiinc2) %>%
    summarize(avg_uiinc = weighted.mean(avg_uiinc, n), p = min(p), n = sum(n)) %>%
    select(-avg_uiinc2)

dist <- shares_fit(
    p = data_dist$p/1e5,
    bracketavg = data_dist$avg_uiinc,
    average = weighted.mean(data_dist$avg_uiinc, data_dist$n)
)

data_rank$uiinc <- bracket_average(dist, data_rank$rank_uiinc, c(data_rank$rank_uiinc[-1], 1))
data_rank$uiinc[is.na(data_rank$uiinc)] <- fitted_quantile(dist, data_rank$rank_uiinc[is.na(data_rank$uiinc)])

data_rank$uiinc <- approx(x = data_rank$rank_uiinc, y = data_rank$uiinc, xout = data_rank$rank_uiinc, rule = 2)$y

write_dta(data_rank, file.path(work_dir, "uiinc-gpinter.dta"))

