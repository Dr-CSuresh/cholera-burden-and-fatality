# 02_data_cleaning_and_linkage.R
#
# Project: Cholera Burden and Fatality


# 1. Load packages 

library(tidyverse)
library(here)


# 2. Create output directories if required 


if (!dir.exists(here("data", "processed"))) {
  dir.create(
    here("data", "processed"),
    recursive = TRUE
  )
}

if (!dir.exists(here("tables"))) {
  dir.create(
    here("tables"),
    recursive = TRUE
  )
}


# IMPORT DATA



# 3. Import cholera cases 

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


# 4. Import cholera deaths 

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



# CLEAN DATA



# 5. Clean cholera cases 

cholera_cases <- cholera_cases_raw |>
  transmute(
    entity = Entity,
    code = Code,
    year = Year,
    reported_cases = `Reported cholera cases`
  ) |>
  filter(
    !is.na(code),
    code != "OWID_WRL",
    !is.na(reported_cases)
  )


# 6. Clean cholera deaths 

cholera_deaths <- cholera_deaths_raw |>
  transmute(
    entity = Entity,
    code = Code,
    year = Year,
    reported_deaths = `Reported cholera deaths`
  ) |>
  filter(
    !is.na(code),
    code != "OWID_WRL",
    !is.na(reported_deaths)
  )


# 7. Inspect cleaned datasets 

glimpse(cholera_cases)

glimpse(cholera_deaths)


# LINKAGE


# 8. Link case and death records 

cholera_linked <- inner_join(
  cholera_cases,
  cholera_deaths,
  by = c(
    "entity",
    "code",
    "year"
  )
)


glimpse(cholera_linked)


# 9. Summarise linkage 

linkage_summary <- tibble(
  
  case_records =
    nrow(cholera_cases),
  
  death_records =
    nrow(cholera_deaths),
  
  matched_country_years =
    nrow(cholera_linked),
  
  case_records_without_death_match =
    nrow(
      anti_join(
        cholera_cases,
        cholera_deaths,
        by = c(
          "entity",
          "code",
          "year"
        )
      )
    ),
  
  death_records_without_case_match =
    nrow(
      anti_join(
        cholera_deaths,
        cholera_cases,
        by = c(
          "entity",
          "code",
          "year"
        )
      )
    )
)


linkage_summary


# 10. Save unmatched records 

unmatched_cases <- anti_join(
  cholera_cases,
  cholera_deaths,
  by = c(
    "entity",
    "code",
    "year"
  )
)


unmatched_deaths <- anti_join(
  cholera_deaths,
  cholera_cases,
  by = c(
    "entity",
    "code",
    "year"
  )
)


write_csv(
  unmatched_cases,
  here(
    "tables",
    "unmatched_cholera_case_records.csv"
  )
)


write_csv(
  unmatched_deaths,
  here(
    "tables",
    "unmatched_cholera_death_records.csv"
  )
)


# CASE-FATALITY RATIO



# 11. Calculate reported CFR
#
# CFR (%) = reported deaths / reported cases × 100
#
# CFR is only calculated when reported cases are greater than zero.

cholera_linked <- cholera_linked |>
  mutate(
    
    cfr_percent =
      if_else(
        reported_cases > 0,
        100 *
          reported_deaths /
          reported_cases,
        NA_real_
      )
  )


# DATA QUALITY FLAGS



# 12. Create epidemiological quality flags 
cholera_linked <- cholera_linked |>
  mutate(
    
    deaths_exceed_cases =
      reported_deaths > reported_cases,
    
    zero_cases_with_deaths =
      reported_cases == 0 &
      reported_deaths > 0,
    
    zero_cases =
      reported_cases == 0,
    
    small_outbreak =
      reported_cases > 0 &
      reported_cases < 100,
    
    very_small_outbreak =
      reported_cases > 0 &
      reported_cases < 10,
    
    cfr_over_100 =
      cfr_percent > 100
  )


# 13. Summarise quality flags 

quality_summary <- cholera_linked |>
  summarise(
    
    matched_country_years = n(),
    
    deaths_exceed_cases =
      sum(
        deaths_exceed_cases,
        na.rm = TRUE
      ),
    
    zero_cases_with_deaths =
      sum(
        zero_cases_with_deaths,
        na.rm = TRUE
      ),
    
    zero_case_records =
      sum(
        zero_cases,
        na.rm = TRUE
      ),
    
    outbreaks_under_100_cases =
      sum(
        small_outbreak,
        na.rm = TRUE
      ),
    
    outbreaks_under_10_cases =
      sum(
        very_small_outbreak,
        na.rm = TRUE
      ),
    
    cfr_over_100 =
      sum(
        cfr_over_100,
        na.rm = TRUE
      )
  )


quality_summary


# 14. Extract suspicious observations 

suspicious_records <- cholera_linked |>
  filter(
    deaths_exceed_cases |
      zero_cases_with_deaths |
      cfr_over_100
  ) |>
  arrange(
    desc(cfr_percent)
  )


print(
  suspicious_records,
  n = Inf
)


# DESCRIBE CFR



# 15. Summarise CFR distribution

cfr_summary <- cholera_linked |>
  filter(
    reported_cases > 0,
    !is.na(cfr_percent)
  ) |>
  summarise(
    
    n_country_years = n(),
    
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
    
    maximum_cfr =
      max(
        cfr_percent,
        na.rm = TRUE
      )
  )


cfr_summary


# SAVE PROCESSED DATA


# 16. Save cleaned case dataset 

write_csv(
  cholera_cases,
  here(
    "data",
    "processed",
    "cholera_cases.csv"
  )
)


# 17. Save cleaned death dataset 

write_csv(
  cholera_deaths,
  here(
    "data",
    "processed",
    "cholera_deaths.csv"
  )
)


# 18. Save linked dataset 

write_csv(
  cholera_linked,
  here(
    "data",
    "processed",
    "cholera_linked.csv"
  )
)


# 19. Save linkage and QA tables 

write_csv(
  linkage_summary,
  here(
    "tables",
    "linkage_summary.csv"
  )
)


write_csv(
  quality_summary,
  here(
    "tables",
    "data_quality_summary.csv"
  )
)


write_csv(
  suspicious_records,
  here(
    "tables",
    "suspicious_cholera_records.csv"
  )
)


write_csv(
  cfr_summary,
  here(
    "tables",
    "cfr_summary.csv"
  )
)


message(
  "Cholera data cleaning and linkage complete."
)