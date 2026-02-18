# Data loading script for populism experiment
# Shared by analysis.Rmd and efa.Rmd

library(tidyverse)
library(here)

# Load and merge data from three sources
load_experiment_data <- function() {
  df <- read_csv(here('experiment/data/populism and news_January 30, 2026_13.27.csv')) %>%
    left_join(read_csv(here('experiment/data/prolific_demo_pilot.csv')), by=c('PROLIFIC_PID'='Participant id')) %>%
    left_join(read_tsv(here('experiment/data/responses.stance.tsv')))

  # Filter by date
  df <- df %>% filter(StartDate >= as.Date('2026-01-29'))

  # Define ordered levels
  pop_levels <- c('Strongly Disagree', 'Somewhat Disagree', 'Neither', 'Somewhat Agree', 'Strongly Agree')
  econ_levels <- c('Much Worse', 'Somewhat Worse', 'About the Same', 'Somewhat Better', 'Much Better')
  personality_levels <- c('Disagree strongly', 'Disagree moderately', 'Neither agree nor disagree', 'Agree moderately', 'Agree strongly')

  # Rename columns
  df <- df %>%
    rename(
      race = `Ethnicity simplified`,
      unemp = `Employment status`
    )

  # Create derived variables
  df <- df %>% mutate(
    # Pre-treatment information
    econ_pre = ordered(Q_econ_pre, levels=econ_levels) %>% as.numeric,
    pop_pre = ordered(Q_pop1_pre, levels=c('Strongly disagree', 'Somewhat disagree', 'Neither', 'Somewhat agree', 'Strongly agree')) %>% as.numeric,
    newsint = ordered(Q_newsint, levels=c('Hardly at all', 'Only now and then', 'Some of the time', 'Most of the time')) %>% as.numeric,
    pers1 = ordered(Q_personality_1, levels=personality_levels) %>% as.numeric,
    pers2 = ordered(Q_personality_2, levels=personality_levels) %>% as.numeric,
    pers3 = ordered(Q_personality_3, levels=personality_levels) %>% as.numeric,
    pers4 = ordered(Q_personality_4, levels=personality_levels) %>% as.numeric,
    faminc_num = str_extract(Q_faminc, "\\d[\\d,]*") %>% str_remove(',') %>% as.numeric(),
    faminc_num_log = log(faminc_num),

    # Post-treatment outcomes
    econ_post = ordered(Q_econ_post, levels=econ_levels) %>% as.numeric,
    news_trust_post = ordered(Q_news_trust, levels=c('Not at all', 'Not too much', 'Some', 'A lot')) %>% as.numeric,
    econ_post_z = scale(econ_post),
    news_trust_post_z = scale(news_trust_post),

    # Populism items with descriptive names
    # pop1: The will of the people should be the highest principle in this country's politics
    will_of_ppl = ordered(Q_pop1, levels=pop_levels) %>% as.numeric(),
    # pop2: Politicians and elites use their power to try to improve people's lives (reverse coded)
    power_improve_rev = ordered(Q_pop2, levels=rev(pop_levels)) %>% as.numeric(),
    # pop3: The system is stacked against people like me
    system_stacked = ordered(Q_pop3, levels=pop_levels) %>% as.numeric(),
    # pop4: I'd rather put my trust in the opinions of experts than the wisdom of ordinary people (reverse coded)
    trust_experts_rev = ordered(Q_pop4, levels=rev(pop_levels)) %>% as.numeric(),
    # pop5: Politics is a fight between the good people and the corrupt elite
    good_corrupt = ordered(Q_pop5, levels=pop_levels) %>% as.numeric(),

    # Backwards compatibility - keep pop1-5 names
    pop1 = will_of_ppl,
    pop2 = power_improve_rev,
    pop3 = system_stacked,
    pop4 = trust_experts_rev,
    pop5 = good_corrupt,

    # Standardized versions with descriptive names
    will_of_ppl_z = as.numeric(scale(will_of_ppl)),
    power_improve_rev_z = as.numeric(scale(power_improve_rev)),
    system_stacked_z = as.numeric(scale(system_stacked)),
    trust_experts_rev_z = as.numeric(scale(trust_experts_rev)),
    good_corrupt_z = as.numeric(scale(good_corrupt)),

    # Backwards compatibility - keep pop1z-5z names
    pop1z = will_of_ppl_z,
    pop2z = power_improve_rev_z,
    pop3z = system_stacked_z,
    pop4z = trust_experts_rev_z,
    pop5z = good_corrupt_z,

    # Populism indices
    populism_idx = (will_of_ppl + power_improve_rev + system_stacked + trust_experts_rev + good_corrupt)/5,
    populism_z_idx = as.numeric(scale(will_of_ppl_z + power_improve_rev_z + system_stacked_z + trust_experts_rev_z + good_corrupt_z)),
    populism_z_idx_2 = as.numeric(scale(will_of_ppl_z + power_improve_rev_z + system_stacked_z + trust_experts_rev_z + good_corrupt_z - news_trust_post_z)),

    # Treatment variables
    comment_neg_tone = group %in% c(1,3),
    article_pos_tone = group %in% c(1,2),

    # Demographics
    age = as.numeric(Age),

    # Comment variables
    comment_text = coalesce(Qcomment1, Qcomment2, Qcomment3, Qcomment4),
    comment_stance = case_when(
      Stance == 'POSITIVE' ~ 1,
      Stance == 'OTHER' ~ 0,
      Stance == 'NEGATIVE' ~ -1,
      TRUE ~ NA,
    ),
    comment_stance_na = replace_na(comment_stance, 0),
    comment = !is.na(comment_stance),
    cmneg = comment_stance == -1,

    # Attention check
    failed = (Q_att1 == 'Somewhat disagree') | is.na(Q_socmed_bc)
  )

  # Composite indices using standardized versions
  df <- df %>% mutate(
    populism_gp = as.numeric(scale(will_of_ppl_z + system_stacked_z + good_corrupt_z)),
    populism_ae = as.numeric(scale(power_improve_rev_z + trust_experts_rev_z - news_trust_post_z + system_stacked_z)),
  )

  return(df)
}
