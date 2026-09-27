# 03_burden_and_cfr_trends.R
#
# Project: Cholera Burden and Fatality

# 1. Load packages 

library(tidyverse)
library(here)
library(scales)


# 2. Import processed datasets 

cholera_cases <- read_csv(
  here(
    "data",
    "processed",
    "cholera_cases.csv"
  ),
  show_col_types = FALSE
)


cholera_deaths <- read_csv(
  here(
    "data",
    "processed",
    "cholera_deaths.csv"
  ),
  show_col_types = FALSE
)


cholera_linked <- read_csv(
  here(
    "data",
    "processed",
    "cholera_linked.csv"
  ),
  show_col_types = FALSE
)


# ANALYSIS 1: Annual reported cholera cases



# 3. Calculate annual case burden 

annual_cases <- cholera_cases |>
  group_by(year) |>
  summarise(
    
    n_entities_reporting_cases = n(),
    
    total_cases =
      sum(
        reported_cases,
        na.rm = TRUE
      ),
    
    .groups = "drop"
  )


print(
  annual_cases,
  n = Inf
)


# 4. Plot annual reported cases 

plot_cases <- annual_cases |>
  ggplot(
    aes(
      x = year,
      y = total_cases
    )
  ) +
  geom_line(
    linewidth = 0.9
  ) +
  scale_y_continuous(
    labels = label_number(
      scale_cut = cut_short_scale()
    )
  ) +
  labs(
    title = "Reported cholera cases, 1949–2021",
    subtitle = "Annual totals across available country-level observations",
    x = "Year",
    y = "Reported cases",
    caption = "Changing surveillance and reporting completeness should be considered when interpreting trends."
  ) +
  theme_minimal(
    base_size = 12
  )


plot_cases


ggsave(
  here(
    "plots",
    "01_reported_cholera_cases_over_time.png"
  ),
  plot_cases,
  width = 11,
  height = 6,
  dpi = 300
)


# ANALYSIS 2: Annual reported cholera deaths


# 5. Calculate annual death burden 

annual_deaths <- cholera_deaths |>
  group_by(year) |>
  summarise(
    
    n_entities_reporting_deaths = n(),
    
    total_deaths =
      sum(
        reported_deaths,
        na.rm = TRUE
      ),
    
    .groups = "drop"
  )


print(
  annual_deaths,
  n = Inf
)


# 6. Plot annual reported deaths 

plot_deaths <- annual_deaths |>
  ggplot(
    aes(
      x = year,
      y = total_deaths
    )
  ) +
  geom_line(
    linewidth = 0.9
  ) +
  scale_y_continuous(
    labels = label_number(
      scale_cut = cut_short_scale()
    )
  ) +
  labs(
    title = "Reported cholera deaths, 1949–2021",
    subtitle = "Annual totals across available country-level observations",
    x = "Year",
    y = "Reported deaths"
  ) +
  theme_minimal(
    base_size = 12
  )


plot_deaths


ggsave(
  here(
    "plots",
    "02_reported_cholera_deaths_over_time.png"
  ),
  plot_deaths,
  width = 11,
  height = 6,
  dpi = 300
)


# ANALYSIS 3: Annual weighted case-fatality ratio



# 7. Calculate annual weighted CFR 
#
# Annual CFR is calculated as: total reported deaths / total reported cases × 100
#
# It is preferable because averaging CFRs would give small and large outbreaks equal statistical weight.
#
# Only matched country-years with more than zero reported cases are included.


annual_cfr <- cholera_linked |>
  filter(
    reported_cases > 0,
    !deaths_exceed_cases
  ) |>
  group_by(year) |>
  summarise(
    
    n_matched_entities = n(),
    
    matched_cases =
      sum(
        reported_cases,
        na.rm = TRUE
      ),
    
    matched_deaths =
      sum(
        reported_deaths,
        na.rm = TRUE
      ),
    
    weighted_cfr =
      100 *
      matched_deaths /
      matched_cases,
    
    .groups = "drop"
  )


print(
  annual_cfr,
  n = Inf
)


# 8. Plot weighted CFR

plot_cfr <- annual_cfr |>
  ggplot(
    aes(
      x = year,
      y = weighted_cfr
    )
  ) +
  geom_line(
    linewidth = 0.9
  ) +
  labs(
    title = "Reported cholera case-fatality ratio over time",
    subtitle = "Weighted annual CFR among matched country-year observations",
    x = "Year",
    y = "Reported CFR (%)",
    caption = "Italy 1998 was excluded from CFR trends because reported deaths exceeded reported cases."
  ) +
  theme_minimal(
    base_size = 12
  )


plot_cfr


ggsave(
  here(
    "plots",
    "03_weighted_cholera_cfr_over_time.png"
  ),
  plot_cfr,
  width = 11,
  height = 6,
  dpi = 300
)


# ANALYSIS 4: Reporting availability over time



# 9. Combine reporting counts 

reporting_summary <- full_join(
  annual_cases |>
    select(
      year,
      n_entities_reporting_cases
    ),
  
  annual_deaths |>
    select(
      year,
      n_entities_reporting_deaths
    ),
  
  by = "year"
) |>
  pivot_longer(
    cols = starts_with("n_entities"),
    names_to = "measure",
    values_to = "n_entities"
  ) |>
  mutate(
    measure = recode(
      measure,
      
      "n_entities_reporting_cases" =
        "Case records",
      
      "n_entities_reporting_deaths" =
        "Death records"
    )
  )


# 10. Plot reporting availability 

plot_reporting <- reporting_summary |>
  ggplot(
    aes(
      x = year,
      y = n_entities,
      colour = measure
    )
  ) +
  geom_line(
    linewidth = 0.9
  ) +
  labs(
    title = "Cholera reporting availability changed over time",
    subtitle = "Number of country-level observations contributing to annual case and death totals",
    x = "Year",
    y = "Entities reporting",
    colour = NULL
  ) +
  theme_minimal(
    base_size = 12
  ) +
  theme(
    legend.position = "bottom"
  )


plot_reporting


ggsave(
  here(
    "plots",
    "04_cholera_reporting_over_time.png"
  ),
  plot_reporting,
  width = 11,
  height = 6,
  dpi = 300
)


# ANALYSIS 5: Highest-burden years



# 11. Identify years with most reported cases 

highest_case_years <- annual_cases |>
  arrange(
    desc(total_cases)
  ) |>
  slice_head(
    n = 10
  )


print(
  highest_case_years,
  n = Inf
)


# 12. Identify years with most reported deaths 

highest_death_years <- annual_deaths |>
  arrange(
    desc(total_deaths)
  ) |>
  slice_head(
    n = 10
  )


print(
  highest_death_years,
  n = Inf
)


# SAVE TABLES



write_csv(
  annual_cases,
  here(
    "tables",
    "annual_cholera_cases.csv"
  )
)


write_csv(
  annual_deaths,
  here(
    "tables",
    "annual_cholera_deaths.csv"
  )
)


write_csv(
  annual_cfr,
  here(
    "tables",
    "annual_cholera_cfr.csv"
  )
)


write_csv(
  highest_case_years,
  here(
    "tables",
    "highest_cholera_case_years.csv"
  )
)


write_csv(
  highest_death_years,
  here(
    "tables",
    "highest_cholera_death_years.csv"
  )
)


message(
  "Cholera burden and CFR trend analysis complete."
)