library(gpinter)
library(haven)
library(dplyr)

work_dir <- commandArgs(trailingOnly = TRUE)

data_rank <- read_dta(file.path(work_dir, "rank-flemp-gpinter.dta"))
data_dist <- read_dta(file.path(work_dir, "tabul-flemp-gpinter.dta"))

data_dist <- data_dist %>%
    arrange(p) %>%
    mutate(flemp_qcew = sort(flemp_qcew)) %>%
    mutate(n = diff(c(p, 1e5))) %>%
    group_by(flemp_qcew) %>%
    summarize(p = min(p), n = sum(n))

dist <- shares_fit(
    p = data_dist$p/1e5,
    bracketavg = data_dist$flemp_qcew,
    average = weighted.mean(data_dist$flemp_qcew, data_dist$n)
)

data_rank$flemp <- bracket_average(dist, data_rank$rank_flemp, c(data_rank$rank_flemp[-1], 1))
data_rank$flemp[is.na(data_rank$flemp)] <- fitted_quantile(dist, data_rank$rank_flemp[is.na(data_rank$flemp)])

data_rank$flemp <- approx(x = data_rank$rank_flemp, y = data_rank$flemp, xout = data_rank$rank_flemp, rule = 2)$y

write_dta(data_rank, file.path(work_dir, "flemp-gpinter.dta"))

