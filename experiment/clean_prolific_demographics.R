# Clean and merge Prolific demographic data
# This script loads all Prolific demographic exports and combines them

library(tidyverse)
library(here)

# Get all prolific demographic CSV files
demo_files <- list.files(
  here('experiment/data/prolific_demographics'),
  pattern = "*.csv",
  full.names = TRUE
)

cat("Found", length(demo_files), "demographic files\n")

# Load and combine all demographic files
demo_data <- demo_files %>%
  map_dfr(function(file) {
    cat("Loading:", basename(file), "\n")
    read_csv(file, show_col_types = FALSE, col_types = cols(.default = "c")) %>%
      mutate(source_file = basename(file))
  })

cat("\nTotal rows loaded:", nrow(demo_data), "\n")
cat("Unique participants:", n_distinct(demo_data$`Participant id`), "\n")

# Check for duplicates
duplicates <- demo_data %>%
  group_by(`Participant id`) %>%
  filter(n() > 1) %>%
  arrange(`Participant id`)

if (nrow(duplicates) > 0) {
  cat("\nWarning:", n_distinct(duplicates$`Participant id`), "participants appear in multiple files\n")
  cat("Keeping most recent submission for each participant\n")

  # Keep most recent submission
  demo_data <- demo_data %>%
    arrange(`Participant id`, desc(`Completed at`)) %>%
    distinct(`Participant id`, .keep_all = TRUE)
}

# Clean and standardize variable names
# Note: Some files have extended demographics (party ID, SES), others don't
demo_clean <- demo_data %>%
  select(
    participant_id = `Participant id`,
    submission_id = `Submission id`,
    status = Status,
    age = Age,
    sex = Sex,
    ethnicity = `Ethnicity simplified`,
    country_birth = `Country of birth`,
    country_residence = `Country of residence`,
    employment = `Employment status`,
    student = `Student status`,
    total_approvals = `Total approvals`,
    time_taken = `Time taken`,
    completed_at = `Completed at`,
    # Extended demographics (available in pilot 2 & 3)
    education = any_of('Highest education level completed'),
    ses = any_of('Socioeconomic status'),
    political_spectrum = any_of('Political spectrum (us)'),
    party_affiliation = any_of('U.s. political affiliation')
  ) %>%
  mutate(
    # Standardize missing values
    across(everything(), ~na_if(., "DATA_EXPIRED")),
    across(everything(), ~na_if(., "")),

    # Convert types
    age = as.numeric(age),
    time_taken = as.numeric(time_taken),

    # Create binary/factor variables
    female = case_when(
      sex == "Female" ~ 1,
      sex == "Male" ~ 0,
      TRUE ~ NA_real_
    ),

    white = case_when(
      ethnicity == "White" ~ 1,
      !is.na(ethnicity) ~ 0,
      TRUE ~ NA_real_
    ),

    employed = case_when(
      employment %in% c("Full-Time", "Part-Time") ~ 1,
      employment %in% c("Unemployed (and job seeking)", "Not in paid work") ~ 0,
      TRUE ~ NA_real_
    ),

    student_binary = case_when(
      student == "Yes" ~ 1,
      student == "No" ~ 0,
      TRUE ~ NA_real_
    ),

    # Party ID (from Prolific, pilots 2 & 3)
    party_dem = case_when(
      party_affiliation == "Democrat" ~ 1,
      !is.na(party_affiliation) ~ 0,
      TRUE ~ NA_real_
    ),

    party_rep = case_when(
      party_affiliation == "Republican" ~ 1,
      !is.na(party_affiliation) ~ 0,
      TRUE ~ NA_real_
    ),

    party_ind = case_when(
      party_affiliation == "Independent" ~ 1,
      !is.na(party_affiliation) ~ 0,
      TRUE ~ NA_real_
    ),

    # SES as 1-10 scale (subjective socioeconomic status)
    ses_scale = as.numeric(ses)
  )

# Summary statistics
cat("\n=== Demographic Summary ===\n")
cat("Age: Mean =", round(mean(demo_clean$age, na.rm=TRUE), 1),
    "SD =", round(sd(demo_clean$age, na.rm=TRUE), 1), "\n")
cat("Female:", round(mean(demo_clean$female, na.rm=TRUE)*100, 1), "%\n")
cat("White:", round(mean(demo_clean$white, na.rm=TRUE)*100, 1), "%\n")
cat("Employed:", round(mean(demo_clean$employed, na.rm=TRUE)*100, 1), "%\n")
cat("Student:", round(mean(demo_clean$student_binary, na.rm=TRUE)*100, 1), "%\n")

cat("\n=== Extended Demographics (Pilots 2 & 3) ===\n")
cat("N with party affiliation data:", sum(!is.na(demo_clean$party_affiliation)), "\n")
if (sum(!is.na(demo_clean$party_dem)) > 0) {
  cat("Democrat:", round(mean(demo_clean$party_dem, na.rm=TRUE)*100, 1), "%\n")
  cat("Republican:", round(mean(demo_clean$party_rep, na.rm=TRUE)*100, 1), "%\n")
  cat("Independent:", round(mean(demo_clean$party_ind, na.rm=TRUE)*100, 1), "%\n")
}

cat("\nN with SES data:", sum(!is.na(demo_clean$ses_scale)), "\n")
if (sum(!is.na(demo_clean$ses_scale)) > 0) {
  cat("SES scale (1-10): Mean =", round(mean(demo_clean$ses_scale, na.rm=TRUE), 2),
      "SD =", round(sd(demo_clean$ses_scale, na.rm=TRUE), 2), "\n")
}

cat("\nEthnicity breakdown:\n")
print(table(demo_clean$ethnicity, useNA = "ifany"))

if (sum(!is.na(demo_clean$party_affiliation)) > 0) {
  cat("\nParty affiliation breakdown:\n")
  print(table(demo_clean$party_affiliation, useNA = "ifany"))
}

# Save cleaned data
output_file <- here('experiment/data/prolific_demographics_clean.rds')
saveRDS(demo_clean, output_file)
cat("\nCleaned demographic data saved to:", output_file, "\n")

# Also save as CSV for inspection
write_csv(demo_clean, here('experiment/data/prolific_demographics_clean.csv'))
cat("Also saved as CSV for inspection\n")

# Return the cleaned data (useful if sourcing this script)
demo_clean
