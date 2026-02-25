## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(keyed)
library(dplyr)
set.seed(42)

## -----------------------------------------------------------------------------
# January export: clean data
january <- data.frame(
  customer_id = c(101, 102, 103, 104, 105),
  email = c("alice@example.com", "bob@example.com", "carol@example.com",
            "dave@example.com", "eve@example.com"),
  segment = c("premium", "basic", "premium", "basic", "premium")
)

# February export: corrupted upstream (duplicates + missing email)
february <- data.frame(
  customer_id = c(101, 102, 102, 104, 105),  # Note: 102 is duplicated

  email = c("alice@example.com", "bob@example.com", NA,
            "dave@example.com", "eve@example.com"),
  segment = c("premium", "basic", "basic", "basic", "premium")
)

## -----------------------------------------------------------------------------
head(february)
nrow(february)  # Same row count

## ----error=TRUE---------------------------------------------------------------
try({
# Define what you expect: customer_id is unique
january_keyed <- january |>
  key(customer_id) |>
  lock_no_na(email)

# This works - January data is clean
january_keyed
})

## ----error=TRUE---------------------------------------------------------------
try({
# This fails immediately - duplicates detected
february |>
  key(customer_id)
})

## -----------------------------------------------------------------------------
validate_customer_export <- function(df) {
  df |>
    key(customer_id) |>
    lock_no_na(email) |>
    lock_nrow(min = 1)
}

# January: passes
january_clean <- validate_customer_export(january)
summary(january_clean)

## -----------------------------------------------------------------------------
# Filter preserves key
premium_customers <- january_clean |>
  filter(segment == "premium")

has_key(premium_customers)
get_key_cols(premium_customers)

# Mutate preserves key
enriched <- january_clean |>
  mutate(domain = sub(".*@", "", email))

has_key(enriched)

## ----error=TRUE---------------------------------------------------------------
try({
# This creates duplicates - keyed stops you
january_clean |>
  mutate(customer_id = 1)
})

## -----------------------------------------------------------------------------
january_clean |>
  unkey() |>
  mutate(customer_id = 1)

## -----------------------------------------------------------------------------
customers <- data.frame(
  customer_id = 1:5,
  name = c("Alice", "Bob", "Carol", "Dave", "Eve"),
  tier = c("gold", "silver", "gold", "bronze", "silver")
) |>
  key(customer_id)

orders <- data.frame(
  order_id = 1:8,
  customer_id = c(1, 1, 2, 3, 3, 3, 4, 5),
  amount = c(100, 150, 200, 50, 75, 125, 300, 80)
) |>
  key(order_id)

## -----------------------------------------------------------------------------
diagnose_join(customers, orders, by = "customer_id", use_joinspy = FALSE)

## -----------------------------------------------------------------------------
compare_keys(customers, orders)

## -----------------------------------------------------------------------------
# Add UUIDs to rows
customers_tracked <- customers |>
  add_id()

customers_tracked

## -----------------------------------------------------------------------------
# Filter: IDs persist
gold_customers <- customers_tracked |>
  filter(tier == "gold")

get_id(gold_customers)

# Compare with original
compare_ids(customers_tracked, gold_customers)

## -----------------------------------------------------------------------------
batch1 <- data.frame(x = 1:3) |> add_id()
batch2 <- data.frame(x = 4:6)  # No IDs yet

# bind_id assigns new IDs to batch2 and checks for conflicts
combined <- bind_id(batch1, batch2)
combined

## -----------------------------------------------------------------------------
# Commit current state as reference
reference_data <- data.frame(
  region_id = c("US", "EU", "APAC"),
  tax_rate = c(0.08, 0.20, 0.10)
) |>
  key(region_id) |>
  stamp()

## -----------------------------------------------------------------------------
# No changes yet
check_drift(reference_data)

## -----------------------------------------------------------------------------
# Simulate upstream change: EU tax rate changed
modified_data <- reference_data
modified_data$tax_rate[2] <- 0.21

# Drift detected!
check_drift(modified_data)

## -----------------------------------------------------------------------------
old_rates <- key(data.frame(
  region_id = c("US", "EU", "APAC"),
  tax_rate  = c(0.08, 0.20, 0.10)
), region_id)

new_rates <- data.frame(
  region_id = c("US", "EU", "APAC", "LATAM"),
  tax_rate  = c(0.08, 0.21, 0.10, 0.15)
)

diff(old_rates, new_rates)

## -----------------------------------------------------------------------------
# Remove snapshots when done
clear_all_snapshots()

