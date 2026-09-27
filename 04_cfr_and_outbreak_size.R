# 04_cfr_and_outbreak_size.R
#
# Project: Cholera Burden and Fatality


# 1. Load packages 

library(tidyverse)
library(here)
library(scales)


# 2. Import linked cholera data 

cholera <- read_csv(
  here(
    "data",
    "processed",
    "cholera_linked.csv"
  ),
  show_col_types = FALSE
)



# PREPARE DATA



# 3. Restrict to interpretable CFR observations 
#
# Exclude:
# - zero case counts
# - the implausible observation where deaths exceed cases

cholera_cfr <- cholera |>
  filter(
    reported_cases > 0,
    reported_deaths <= reported_cases,
    !is.na(cfr_percent)
  )


# 4. Create outbreak-size categories 

cholera_cfr <- cholera_cfr |>
  mutate(
    outbreak_size = case_when(
      
      reported_cases < 10 ~
        "<10 cases",
      
      reported_cases < 100 ~
        "10–99 cases",
      
      reported_cases < 1000 ~
        "100–999 cases",
      
      reported_cases < 10000 ~
        "1,000–9,999 cases",
      
      reported_cases >= 10000 ~
        "≥10,000 cases"
    ),
    
    outbreak_size = factor(
      outbreak_size,
      levels = c(
        "<10 cases",
        "10–99 cases",
        "100–999 cases",
        "1,000–9,999 cases",
        "≥10,000 cases"
      )
    )
  )


# ANALYSIS 1: CFR versus outbreak size



# 5. Scatterplot 

plot_cases_cfr <- cholera_cfr |>
  ggplot(
    aes(
      x = reported_cases,
      y = cfr_percent
    )
  ) +
  geom_point(
    alpha = 0.4
  ) +
  scale_x_log10(
    labels = label_number(
      scale_cut = cut_short_scale()
    )
  ) +
  coord_cartesian(
    ylim = c(
      0,
      50
    )
  ) +
  labs(
    title = "Reported cholera CFR is highly variable in small outbreaks",
    subtitle = "Each point represents one matched country-year",
    x = "Reported cholera cases (log scale)",
    y = "Reported CFR (%)",
    caption = "Y-axis restricted to 0–50% for visual clarity."
  ) +
  theme_minimal(
    base_size = 12
  )


plot_cases_cfr


ggsave(
  here(
    "plots",
    "05_cfr_vs_outbreak_size.png"
  ),
  plot_cases_cfr,
  width = 10,
  height = 6,
  dpi = 300
)


# ANALYSIS 2: CFR distribution by outbreak-size category


# 6. Summarise CFR by outbreak size 

cfr_by_outbreak_size <- cholera_cfr |>
  group_by(
    outbreak_size
  ) |>
  summarise(
    
    n_country_years = n(),
    
    median_cases =
      median(
        reported_cases,
        na.rm = TRUE
      ),
    
    median_cfr =
      median(
        cfr_percent,
        na.rm = TRUE
      ),
    
    q1_cfr =
      quantile(
        cfr_percent,
        0.25,
        na.rm = TRUE
      ),
    
    q3_cfr =
      quantile(
        cfr_percent,
        0.75,
        na.rm = TRUE
      ),
    
    max_cfr =
      max(
        cfr_percent,
        na.rm = TRUE
      ),
    
    .groups = "drop"
  )


print(
  cfr_by_outbreak_size,
  n = Inf
)


write_csv(
  cfr_by_outbreak_size,
  here(
    "tables",
    "cfr_by_outbreak_size.csv"
  )
)


# 7. Boxplot 

plot_cfr_size_groups <- cholera_cfr |>
  ggplot(
    aes(
      x = outbreak_size,
      y = cfr_percent
    )
  ) +
  geom_boxplot(
    outlier.alpha = 0.25
  ) +
  coord_cartesian(
    ylim = c(
      0,
      25
    )
  ) +
  labs(
    title = "Reported CFR distribution varies with outbreak size",
    subtitle = "Country-year cholera observations grouped by reported case count",
    x = "Reported outbreak size",
    y = "Reported CFR (%)",
    caption = "Y-axis restricted to 0–25% for visual clarity."
  ) +
  theme_minimal(
    base_size = 12
  ) +
  theme(
    axis.text.x = element_text(
      angle = 20,
      hjust = 1
    )
  )


plot_cfr_size_groups


ggsave(
  here(
    "plots",
    "06_cfr_by_outbreak_size.png"
  ),
  plot_cfr_size_groups,
  width = 10,
  height = 6,
  dpi = 300
)


# ANALYSIS 3: Sensitivity analysis using minimum case thresholds



# 8. Compare CFR distributions after applying denominator thresholds 

threshold_summary <- bind_rows(
  
  cholera_cfr |>
    summarise(
      threshold = "All outbreaks",
      minimum_cases = 1,
      n_country_years = n(),
      median_cfr = median(
        cfr_percent,
        na.rm = TRUE
      ),
      q1_cfr = quantile(
        cfr_percent,
        0.25,
        na.rm = TRUE
      ),
      q3_cfr = quantile(
        cfr_percent,
        0.75,
        na.rm = TRUE
      )
    ),
  
  cholera_cfr |>
    filter(
      reported_cases >= 10
    ) |>
    summarise(
      threshold = "≥10 cases",
      minimum_cases = 10,
      n_country_years = n(),
      median_cfr = median(
        cfr_percent,
        na.rm = TRUE
      ),
      q1_cfr = quantile(
        cfr_percent,
        0.25,
        na.rm = TRUE
      ),
      q3_cfr = quantile(
        cfr_percent,
        0.75,
        na.rm = TRUE
      )
    ),
  
  cholera_cfr |>
    filter(
      reported_cases >= 100
    ) |>
    summarise(
      threshold = "≥100 cases",
      minimum_cases = 100,
      n_country_years = n(),
      median_cfr = median(
        cfr_percent,
        na.rm = TRUE
      ),
      q1_cfr = quantile(
        cfr_percent,
        0.25,
        na.rm = TRUE
      ),
      q3_cfr = quantile(
        cfr_percent,
        0.75,
        na.rm = TRUE
      )
    ),
  
  cholera_cfr |>
    filter(
      reported_cases >= 1000
    ) |>
    summarise(
      threshold = "≥1,000 cases",
      minimum_cases = 1000,
      n_country_years = n(),
      median_cfr = median(
        cfr_percent,
        na.rm = TRUE
      ),
      q1_cfr = quantile(
        cfr_percent,
        0.25,
        na.rm = TRUE
      ),
      q3_cfr = quantile(
        cfr_percent,
        0.75,
        na.rm = TRUE
      )
    )
)


print(
  threshold_summary,
  n = Inf
)


write_csv(
  threshold_summary,
  here(
    "tables",
    "cfr_threshold_sensitivity_analysis.csv"
  )
)

# ANALYSIS 4: Relationship between outbreak size and CFR



# 9. Spearman correlation 
# Outbreak size is strongly skewed and the association is not assumed to be linear.

spearman_test <- cor.test(
  log10(
    cholera_cfr$reported_cases
  ),
  cholera_cfr$cfr_percent,
  method = "spearman",
  exact = FALSE
)


spearman_results <- tibble(
  
  method =
    "Spearman correlation",
  
  n =
    nrow(
      cholera_cfr
    ),
  
  rho =
    unname(
      spearman_test$estimate
    ),
  
  p_value =
    spearman_test$p.value
)


spearman_results


write_csv(
  spearman_results,
  here(
    "tables",
    "outbreak_size_cfr_spearman.csv"
  )
)


# ANALYSIS 5: Extreme CFR observations



# 10. Highest apparent CFRs 
highest_cfr <- cholera_cfr |>
  arrange(
    desc(
      cfr_percent
    )
  ) |>
  select(
    entity,
    code,
    year,
    reported_cases,
    reported_deaths,
    cfr_percent,
    outbreak_size
  ) |>
  slice_head(
    n = 25
  )


print(
  highest_cfr,
  n = Inf
)


write_csv(
  highest_cfr,
  here(
    "tables",
    "highest_reported_cholera_cfr.csv"
  )
)


# ANALYSIS 6: High CFR after excluding very small outbreaks



# 11. Highest CFR where at least 100 cases were reported 

highest_cfr_100plus <- cholera_cfr |>
  filter(
    reported_cases >= 100
  ) |>
  arrange(
    desc(
      cfr_percent
    )
  ) |>
  select(
    entity,
    code,
    year,
    reported_cases,
    reported_deaths,
    cfr_percent
  ) |>
  slice_head(
    n = 20
  )


print(
  highest_cfr_100plus,
  n = Inf
)


write_csv(
  highest_cfr_100plus,
  here(
    "tables",
    "highest_cholera_cfr_100plus_cases.csv"
  )
)



message(
  "CFR and outbreak-size analysis complete."
)