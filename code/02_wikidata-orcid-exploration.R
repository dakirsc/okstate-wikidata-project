library(WikidataR)
library(tidyverse)


# Extract QIDs using ORCID iDs --------------------------------------------

# import list of ORCID iDs 
orcid_list <- read_csv("data/my_orcids_data_2025-05-09.csv")

# extract just the list of ORCID iDs
orcid_vec <- orcid_list$orcid_identifier_path 

# create an empty data frame
qid_df <- data.frame(matrix(nrow = length(orcid_vec), ncol = 2))
colnames(qid_df) <- c("orcid","qid")

# iterate through the list of ORCID iDs
# for each ORCID iD, use the qid_from_ORCID function
# and search for the ORCID iD in Wikidata
# if found, extract the QID (Wikidata ID)
for(x in orcid_vec){
  row <- which(orcid_vec == x)
  qid_df[row,1] <- orcid_vec[row]
  qid_df[row,2] <- qid_from_ORCID(orcid_vec[row])
}

# how many ORCID iDs matched a QID?
sum(!is.na(qid_df$qid)) # 858 unique QIDs

# write this file to CSV
write_csv(qid_df,paste0("data/orcid_qid_",today,".csv"))


# Extract basic information about QIDs ------------------------------------

# read in QID-ORCID dataframe 
# filter out entries without QIDs
# extract QIDs into a list
qid_list <- read_csv("data/orcid_qid_2025-05-09.csv") %>% 
  filter(!is.na(qid)) %>% 
  pull(qid)

# create an empty data frame
qid_info <- data.frame(matrix(nrow = length(qid_list), ncol = 3))
colnames(qid_info) <- c("qid","prop_count","prop_list")

# iterate through the list of QIDs
# extract information from item (get_item)
# extract a list of properties from the item (list_properties)
# count number of properties per QID
for(x in qid_list){
  row <- which(qid_list == x)
  print(paste(row, "of", length(qid_list)))
    qid_info[row,1] <- qid_list[row] # paste the QID in the data frame
    item <- get_item(x) # get information from Wikidata about the QID
    prop <- list_properties(item, names = FALSE) # list all properties for that QID
    vec <- prop[[1]] # convert to a vector
    how_many <- length(vec) # count how many properties 
    qid_info[row,2] <- how_many # paste that number in the data frame
    list <- paste(vec, collapse = "|") # collapse the list of properties into a single entry separated by |
    qid_info[row,3] <- list # paste this list in the data frame
}

# convert numberProperties column to numeric (rather than character)
qid_info_clean <- qid_info %>% 
  mutate(prop_count = as.numeric(prop_count))

# visualize number of properties per QID
ggplot(data = qid_info_clean,
       aes(x = prop_count)) +
  geom_histogram(fill = "orange",
                 color = "black",
                 binwidth = 1) +
  theme_bw() +
  labs(x = "Number of Properties",
       y = "QID Counts") +
  theme(text = element_text(size = 14)) +
  scale_x_continuous(minor_breaks = seq(2,40,2))

ggsave(paste0("figures/number_props_",today,".png"),plot = last_plot(),
       width = 6, height = 4, dpi = 300)

# write to CSV
write_csv(qid_info_clean,paste0("data/property_per_qid_",today,".csv"))


# Initial Property & QID Exploration --------------------------------------------
qid_info_clean <- read_csv(paste0("data/property_per_qid_",today,".csv"))

### Property Lists per QID --------------------------------------------------

# split properties apart by delimiter |
qid_info_long <- qid_info_clean %>% 
  separate_longer_delim(prop_list, delim = "|")

# count number of unique properties
length(unique(qid_info_long$prop_list))


# remove missing data
  # remove any QIDs without any information
  # for OSU, instance where QID Q92360915 redirects to Q26714701
  # but only Q92360915 is present in dataset (and has no metadata)
# widen the data frame
  # each property will have its own column
  # the column contents will be TRUE or FALSE
  # TRUE indicates the QID represented in that row has the property
  # FALSE indicates it does not
qid_info_wide <- qid_info_long %>% 
  filter(prop_list != "") %>% 
  mutate(prop_list_logic = TRUE) %>% 
  group_by(qid) %>% 
  pivot_wider(names_from = prop_list,
              values_from = prop_list_logic,
              values_fill = list(prop_list_logic = FALSE))

# write to CSV
write_csv(qid_info_wide,paste0("data/qid_property_logic_",today,".csv"))


### QID Lists per Property --------------------------------------------------

# extract just a list of Property names
# exclude `qid` and `prop_count`
qid_prop_list <- names(qid_info_wide)[3:length(qid_info_wide)] 

# create an empty data frame
prop_rank <- data.frame(matrix(nrow = length(qid_prop_list), ncol = 3))
colnames(prop_rank) <- c("prop_id","count","qid_list")

# iterate through the different Properties to identify which QIDs have them
# and how frequently the properties occur
for(x in qid_prop_list){
  row <- which(qid_prop_list == x)
  print(paste(row, "of", length(qid_prop_list)))
  prop_rank[row,1] <- qid_prop_list[row] # paste property in data frame
  prop_count <- sum(qid_info_wide[,row+2]) # count how many times the property occurs
  # row+2 needed to account for extra columns in qid_info_wide dataset
  prop_rank[row,2] <- prop_count
  which_qid <- qid_info_wide$qid[qid_info_wide[,row+2] == TRUE] # identify which QIDs have that property
  list <- paste(which_qid, collapse = "|") # collapse the list of QIDs into a single item separated by |
  prop_rank[row,3] <- list
}


# write to CSV
write_csv(prop_rank,paste0("data/property_qid_frequency_",today,".csv"))
