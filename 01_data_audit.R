# 01_data_audit.R
#
# Project: Cholera Burden and Fatality



# 1. Load packages 

library(tidyverse)
library(here)


# 2. Create output directory if needed 

if (!dir.exists(here("tables"))) {
  dir.create(
    here("tables"),
    recursive = TRUE
  )
}



# IMPORT DATA



# 3. Import cholera case data 
#
# The original infectious-disease dataset contains several unrelated disease variables. Only the variables required for the cholera analysis are imported.
#
# Column types are specified explicitly to avoid parsing problems in unrelated columns within the source file.

cholera_cases_raw <- read_csv(
  here(
    "data",
    "raw",
    "1- the-number-of-cases-of-infectious-diseases.csv"
  ),
  col_select = c(
    Entity,
    Code,
    Year,
    `Reported cholera cases`
  ),
  col_types = cols(
    Entity = col_character(),
    Code = col_character(),
    Year = col_double(),
    `Reported cholera cases` = col_double()
  )
)


# 4. Import cholera death data 

cholera_deaths_raw <- read_csv(
  here(
    "data",
    "raw",
    "5- number-of-reported-cholera-deaths.csv"
  ),
  col_types = cols(
    Entity = col_character(),
    Code = col_character(),
    Year = col_double(),
    `Reported cholera deaths` = col_double()
  )
)


# CHECK IMPORT


# 5. Inspect dataset structures 

glimpse(cholera_cases_raw)

glimpse(cholera_deaths_raw)


# 6. Check for parsing problems

case_parsing_problems <- problems(
  cholera_cases_raw
)

death_parsing_problems <- problems(
  cholera_deaths_raw
)


case_parsing_problems

death_parsing_problems


# DATASET COVERAGE



# 7. Summarise cholera case coverage 

case_summary <- cholera_cases_raw |>
  filter(
    !is.na(`Reported cholera cases`)
  ) |>
  summarise(
    n_observations = n(),
    first_year = min(
      Year,
      na.rm = TRUE
    ),
    last_year = max(
      Year,
      na.rm = TRUE
    ),
    n_entities = n_distinct(Entity),
    n_codes = n_distinct(
      Code,
      na.rm = TRUE
    )
  )


case_summary


# 8. Summarise cholera death coverage 

death_summary <- cholera_deaths_raw |>
  filter(
    !is.na(`Reported cholera deaths`)
  ) |>
  summarise(
    n_observations = n(),
    first_year = min(
      Year,
      na.rm = TRUE
    ),
    last_year = max(
      Year,
      na.rm = TRUE
    ),
    n_entities = n_distinct(Entity),
    n_codes = n_distinct(
      Code,
      na.rm = TRUE
    )
  )


death_summary



# DUPLICATES



# 9. Check duplicate entity-year observations in case data 

case_duplicates <- cholera_cases_raw |>
  filter(
    !is.na(`Reported cholera cases`)
  ) |>
  count(
    Entity,
    Code,
    Year,
    name = "n"
  ) |>
  filter(
    n > 1
  )


case_duplicates


# 10. Check duplicate entity-year observations in death data 

death_duplicates <- cholera_deaths_raw |>
  filter(
    !is.na(`Reported cholera deaths`)
  ) |>
  count(
    Entity,
    Code,
    Year,
    name = "n"
  ) |>
  filter(
    n > 1
  )


death_duplicates


# MISSING DATA



# 11. Assess missingness in case data 

case_missingness <- cholera_cases_raw |>
  summarise(
    across(
      everything(),
      ~ sum(is.na(.x))
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    percent_missing = round(
      100 *
        n_missing /
        nrow(cholera_cases_raw),
      2
    )
  )


case_missingness


# 12. Assess missingness in death data 

death_missingness <- cholera_deaths_raw |>
  summarise(
    across(
      everything(),
      ~ sum(is.na(.x))
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    percent_missing = round(
      100 *
        n_missing /
        nrow(cholera_deaths_raw),
      2
    )
  )


death_missingness


# ENTITY CHECKS



# 13. Identify observations without country codes 

case_entities_without_codes <- cholera_cases_raw |>
  filter(
    is.na(Code)
  ) |>
  distinct(
    Entity,
    Code
  ) |>
  arrange(Entity)


death_entities_without_codes <- cholera_deaths_raw |>
  filter(
    is.na(Code)
  ) |>
  distinct(
    Entity,
    Code
  ) |>
  arrange(Entity)


print(
  case_entities_without_codes,
  n = Inf
)


print(
  death_entities_without_codes,
  n = Inf
)


# TEMPORAL COVERAGE



# 14. Count observed cholera case records by year 

cases_by_year <- cholera_cases_raw |>
  filter(
    !is.na(`Reported cholera cases`)
  ) |>
  count(
    Year,
    name = "n_case_records"
  ) |>
  arrange(Year)


print(
  cases_by_year,
  n = Inf
)


# 15. Count observed cholera death records by year

deaths_by_year <- cholera_deaths_raw |>
  filter(
    !is.na(`Reported cholera deaths`)
  ) |>
  count(
    Year,
    name = "n_death_records"
  ) |>
  arrange(Year)


print(
  deaths_by_year,
  n = Inf
)


# BASIC VALUE CHECKS



# 16. Check for negative case counts 

negative_cases <- cholera_cases_raw |>
  filter(
    `Reported cholera cases` < 0
  )


negative_cases


# 17. Check for negative death counts 

negative_deaths <- cholera_deaths_raw |>
  filter(
    `Reported cholera deaths` < 0
  )


negative_deaths


# 18. Examine largest reported case counts 

largest_case_counts <- cholera_cases_raw |>
  filter(
    !is.na(`Reported cholera cases`)
  ) |>
  arrange(
    desc(`Reported cholera cases`)
  ) |>
  slice_head(
    n = 20
  )


print(
  largest_case_counts,
  n = Inf
)


# 19. Examine largest reported death counts 

largest_death_counts <- cholera_deaths_raw |>
  filter(
    !is.na(`Reported cholera deaths`)
  ) |>
  arrange(
    desc(`Reported cholera deaths`)
  ) |>
  slice_head(
    n = 20
  )


print(
  largest_death_counts,
  n = Inf
)


# SAVE AUDIT OUTPUTS



write_csv(
  case_summary,
  here(
    "tables",
    "cholera_case_dataset_summary.csv"
  )
)


write_csv(
  death_summary,
  here(
    "tables",
    "cholera_death_dataset_summary.csv"
  )
)


write_csv(
  case_missingness,
  here(
    "tables",
    "cholera_case_missingness.csv"
  )
)


write_csv(
  death_missingness,
  here(
    "tables",
    "cholera_death_missingness.csv"
  )
)


write_csv(
  case_duplicates,
  here(
    "tables",
    "cholera_case_duplicates.csv"
  )
)


write_csv(
  death_duplicates,
  here(
    "tables",
    "cholera_death_duplicates.csv"
  )
)


write_csv(
  cases_by_year,
  here(
    "tables",
    "cholera_case_records_by_year.csv"
  )
)


write_csv(
  deaths_by_year,
  here(
    "tables",
    "cholera_death_records_by_year.csv"
  )
)



message(
  "Cholera data audit complete."
)