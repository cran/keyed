## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(keyed)
library(dplyr)

## -----------------------------------------------------------------------------
df <- data.frame(id = 1:3, value = c("a", "b", "c"))

# Check happens HERE - at key definition
df <- key(df, id)

# No check here - just a filter
df_filtered <- df |> filter(id > 1)

# No check here - just adding a column
df_enriched <- df |> mutate(upper = toupper(value))

# Check happens HERE - at explicit assertion
df |> lock_no_na(value)

## ----error=TRUE---------------------------------------------------------------
try({
df <- data.frame(id = 1:3, x = c("a", "b", "c")) |>
  key(id)

# This would create duplicate ids - keyed stops you
df |> mutate(id = 1)
})

## -----------------------------------------------------------------------------
df |> unkey() |> mutate(id = 1)

