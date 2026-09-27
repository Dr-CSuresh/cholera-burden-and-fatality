# 05_hotspot_persistence.R
#
# Project: Cholera Burden and Fatality



# 1. Load packages 
library(tidyverse)
library(here)
library(scales)


# 2. Import cleaned case data 

cholera_cases <- read_csv(
  here(
    "data",
    "processed",
    "cholera_cases.csv"
  ),
  show_col_types = FALSE
)


# 3. Restrict hotspot analysis to 1970-2021 

cholera_hotspot_data <- cholera_cases |>
  filter(
    year >= 1970,
    !is.na(reported_cases)
  )



# ANALYSIS 1: Annual country ranking



# 4. Rank countries by reported cholera cases within each year 

annual_ranked <- cholera_hotspot_data |>
  group_by(year) |>
  arrange(
    desc(reported_cases),
    .by_group = TRUE
  ) |>
  mutate(
    
    n_reporting =
      n(),
    
    burden_rank =
      row_number(),
    
    top_decile_n =
      pmax(
        1,
        ceiling(
          n_reporting * 0.10
        )
      ),
    
    top_decile =
      burden_rank <= top_decile_n
    
  ) |>
  ungroup()


# 5. Inspect ranked observations 

print(
  annual_ranked,
  n = 30
)


# ANALYSIS 2: Persistent hotspot countries



# 6. Calculate hotspot persistence
#
# A hotspot year: a year in which a country was among the top 10% of reporting countries by reported cholera cases.

hotspot_persistence <- annual_ranked |>
  group_by(
    entity,
    code
  ) |>
  summarise(
    
    reporting_years =
      n(),
    
    hotspot_years =
      sum(
        top_decile,
        na.rm = TRUE
      ),
    
    proportion_reporting_years_hotspot =
      100 *
      hotspot_years /
      reporting_years,
    
    total_reported_cases =
      sum(
        reported_cases,
        na.rm = TRUE
      ),
    
    median_annual_cases =
      median(
        reported_cases,
        na.rm = TRUE
      ),
    
    .groups = "drop"
  ) |>
  filter(
    reporting_years >= 10
  ) |>
  arrange(
    desc(hotspot_years),
    desc(proportion_reporting_years_hotspot)
  )


print(
  hotspot_persistence,
  n = 30
)


write_csv(
  hotspot_persistence,
  here(
    "tables",
    "cholera_hotspot_persistence.csv"
  )
)


# 7. Select the most persistent hotspots

top_persistent_hotspots <- hotspot_persistence |>
  slice_head(
    n = 15
  )


# 8. Plot persistent hotspots 

plot_persistence <- top_persistent_hotspots |>
  mutate(
    entity = fct_reorder(
      entity,
      hotspot_years
    )
  ) |>
  ggplot(
    aes(
      x = entity,
      y = hotspot_years
    )
  ) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Persistent reported cholera hotspots, 1970–2021",
    subtitle = "Number of years ranked among the top 10% of reporting countries by case count",
    x = NULL,
    y = "Years classified as a hotspot"
  ) +
  theme_minimal(
    base_size = 12
  )


plot_persistence


ggsave(
  here(
    "plots",
    "07_persistent_cholera_hotspots.png"
  ),
  plot_persistence,
  width = 9,
  height = 7,
  dpi = 300
)


# ANALYSIS 3: Countries appearing most often among annual top five



# 9. Extract annual top five countries 

annual_top_five <- cholera_hotspot_data |>
  group_by(year) |>
  slice_max(
    order_by = reported_cases,
    n = 5,
    with_ties = FALSE
  ) |>
  ungroup()


# 10. Count frequency of top-five appearances 

top_five_frequency <- annual_top_five |>
  count(
    entity,
    code,
    name = "years_in_top_five"
  ) |>
  arrange(
    desc(years_in_top_five)
  )


print(
  top_five_frequency,
  n = 30
)


write_csv(
  top_five_frequency,
  here(
    "tables",
    "cholera_top_five_frequency.csv"
  )
)


# 11. Plot frequent top-five countries 

plot_top_five <- top_five_frequency |>
  slice_head(
    n = 15
  ) |>
  mutate(
    entity = fct_reorder(
      entity,
      years_in_top_five
    )
  ) |>
  ggplot(
    aes(
      x = entity,
      y = years_in_top_five
    )
  ) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Countries most frequently among the five highest reported cholera burdens",
    subtitle = "Annual rankings, 1970–2021",
    x = NULL,
    y = "Years in annual top five"
  ) +
  theme_minimal(
    base_size = 12
  )


plot_top_five


ggsave(
  here(
    "plots",
    "08_cholera_top_five_frequency.png"
  ),
  plot_top_five,
  width = 9,
  height = 7,
  dpi = 300
)


# ANALYSIS 4: Concentration of reported cases



# 12. Calculate annual burden concentration 

annual_concentration <- cholera_hotspot_data |>
  group_by(year) |>
  summarise(
    
    n_reporting =
      n(),
    
    total_cases =
      sum(
        reported_cases,
        na.rm = TRUE
      ),
    
    top_country_cases =
      max(
        reported_cases,
        na.rm = TRUE
      ),
    
    top_five_cases =
      sum(
        head(
          sort(
            reported_cases,
            decreasing = TRUE
          ),
          5
        )
      ),
    
    .groups = "drop"
  ) |>
  mutate(
    
    top_country_share =
      100 *
      top_country_cases /
      total_cases,
    
    top_five_share =
      100 *
      top_five_cases /
      total_cases
  )


print(
  annual_concentration,
  n = Inf
)


write_csv(
  annual_concentration,
  here(
    "tables",
    "annual_cholera_concentration.csv"
  )
)


# 13. Plot burden concentration

plot_concentration <- annual_concentration |>
  select(
    year,
    top_country_share,
    top_five_share
  ) |>
  pivot_longer(
    cols = c(
      top_country_share,
      top_five_share
    ),
    names_to = "measure",
    values_to = "share"
  ) |>
  mutate(
    measure = recode(
      measure,
      
      "top_country_share" =
        "Highest-burden country",
      
      "top_five_share" =
        "Five highest-burden countries"
    )
  ) |>
  ggplot(
    aes(
      x = year,
      y = share,
      colour = measure
    )
  ) +
  geom_line(
    linewidth = 0.9
  ) +
  scale_y_continuous(
    labels = label_percent(
      scale = 1
    ),
    limits = c(
      0,
      100
    )
  ) +
  labs(
    title = "Geographic concentration of reported cholera burden",
    subtitle = "Share of annual reported cases contributed by the highest-burden countries",
    x = "Year",
    y = "Share of reported cases",
    colour = NULL
  ) +
  theme_minimal(
    base_size = 12
  ) +
  theme(
    legend.position = "bottom"
  )


plot_concentration


ggsave(
  here(
    "plots",
    "09_cholera_burden_concentration.png"
  ),
  plot_concentration,
  width = 11,
  height = 6,
  dpi = 300
)


# ANALYSIS 5: Years with greatest burden concentration



highest_concentration_years <- annual_concentration |>
  arrange(
    desc(top_country_share)
  ) |>
  slice_head(
    n = 15
  )


print(
  highest_concentration_years,
  n = Inf
)


write_csv(
  highest_concentration_years,
  here(
    "tables",
    "highest_cholera_concentration_years.csv"
  )
)



message(
  "Cholera hotspot persistence analysis complete."
)