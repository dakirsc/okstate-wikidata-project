# install.packages("tidywikidatar")
library(tidywikidatar)
library(tidyverse)
library(lubridate)
library(anytime)
library(WikidataR)
library(scales)

today <- Sys.Date()

# Round 1 - Researcher QIDs -----------------------------------------------

# read in QID-ORCID dataframe 
# filter out entries without QIDs
# extract QIDs into a list
# NOTE: your file name is likely different
qid_list <- read_csv("data/orcid_qid_2025-05-15.csv") %>% 
  filter(!is.na(qid)) %>% 
  pull(qid)


### Extract Properties & Values from QIDs -----------------------------------

# return info from Wikidata items for list of QIDs
qid_basic <- tw_get(qid_list)

head(qid_basic)
# id  property  value rank
# properties are primary Wikidata properties (P496, P106, etc.)
# but a few are `label_en` (item name in English)
# and other info such as `alias_en`,`description_en`
# as well as links to other places in the Wikidata infrastruture where the
# individual appears: `sitelink_enwiki`, `sitelink_commonswiki`, `sitelink_enwikiquote`

# tease apart basic info provided
unique(qid_basic$rank) # normal, preferred, deprecated, NA


### Identify Values that are QIDs Themselves --------------------------------

# extract the QIDs returned as property values
# regular expression searches for items in the "value" column
# that start with Q and are followed by 1 or more digits
# pulls these values into a list
property_value_qid <- qid_basic %>% 
  filter(grepl("^Q[0-9]+",value)) %>% 
  select(value) %>% 
  distinct() %>% 
  pull()


# Round 2 - Property Value QIDs -------------------------------------------

# Researcher --> Property --> QID --> label

# get labels for those QIDs (this may take a while)
prop_val_qid_label <- tw_get_label(property_value_qid)

# merge QIDs and labels
pv_qid_label_merge <- as.data.frame(cbind(property_value_qid,prop_val_qid_label))

# rename columns
colnames(pv_qid_label_merge) <- c("pv_qid","pv_qid_label")

head(pv_qid_label_merge)

# then merge this information with qid_basic data frame
pv_qid_merge <- qid_basic %>% 
  left_join(.,pv_qid_label_merge, by = c("value" = "pv_qid"))

# save this iteration
write_csv(pv_qid_merge,paste0("data/pv_qid_label_only_",today,".csv"))

### Extracting Qualifiers ---------------------------------------------------------
# Researcher --> Property --> Value 1 (+ Qualifiers) + Value 2 (+ Qualifiers)

# trying to get more granular data
pv_qid_df <- pv_qid_merge %>% 
  select(id, property,value,pv_qid_label)

# if interested (or relevant), can identify "duplicate" properties & values
# which should be distinguished by qualifiers (if info is present)
duplicate_prop_val <- pv_qid_df %>% 
  filter(duplicated(pv_qid_df) == TRUE)

# query for additional info on individual QIDs + properties
tw_get_qualifiers("Q99710398","P69")

# extract all qualifier information for QIDs & Properties in dataframe
# depending on how many items you have, this can take quite a while!!
pv_qualifiers <- tw_get_qualifiers(id = pv_qid_df$id,
                                   p = pv_qid_df$property)

head(pv_qualifiers)

# combine with qid-property-value info
# there may be multiple matches, since a property/value can have more than one qualifier
pv_qid_qual <- pv_qid_df %>% 
  left_join(.,pv_qualifiers,
            by = c("id" = "id",
                   "property" = "property",
                   "value" = "qualifier_id")) %>% 
  distinct()

write_csv(pv_qid_qual,
          paste0("data/pv_qid_qual_", today, ".csv"))


# Round 3 - Qualifier Value QIDs -----------------------------------------------------
# Researcher --> Property --> Value --> Qualifier Property --> QID

# types of items reported as qualifiers
pv_qid_qual %>% 
  group_by(qualifier_value_type) %>% 
  count()

# wikibase-entityid --> indicates QIDs
pvq_qual_qid_list <- pv_qid_qual %>% 
  filter(qualifier_value_type == "wikibase-entityid") %>% 
  select(qualifier_value) %>% 
  distinct() %>% 
  pull()
  

# get label from those QIDs
pvq_qual_qid_label <- tw_get_label(pvq_qual_qid_list)

# merge QIDs and labels
pv_qual_qid_label_merge <- as.data.frame(cbind(pvq_qual_qid_list,pvq_qual_qid_label))

# rename columns
colnames(pv_qual_qid_label_merge) <- c("qual_qid","qual_qid_label")

head(pv_qual_qid_label_merge)

# then merge this information with qid_info data frame
pvq_qual_qid_merge <- pv_qid_qual %>% 
  left_join(.,pv_qual_qid_label_merge, by = c("qualifier_value" = "qual_qid")) %>% 
  select(id,property,value,pv_qid_label,
         qualifier_property,qualifier_value,
         qual_qid_label,everything())

write_csv(pvq_qual_qid_merge,
          paste0("data/pvq_qual_qid_label_", today, ".csv"))


# Info on Properties ---------------------------------------------------

### QID Property Label & Description ------------------------------------------------

# extract list of properties
qid_prop_list <- pvq_qual_qid_merge %>% 
  select(property) %>% 
  filter(grepl("^P+",property)) %>% 
  distinct() %>% 
  pull()

# extract property label & property description for each property
qid_prop_lab <- tw_get_property_label(qid_prop_list)
qid_prop_desc <- tw_get_property_description(qid_prop_list)

# create a dataframe with property IDs, labels, and descriptions
qid_prop_df <- data.frame(qid_prop_list,
                          qid_prop_lab,
                          qid_prop_desc,
                          stringsAsFactors = FALSE)

### Qualifier QID Property Label & Description ------------------------

# extract list of properties
qual_qid_prop_list <- pvq_qual_qid_merge %>% 
  select(qualifier_property) %>% 
  filter(grepl("^P+",qualifier_property)) %>% 
  distinct() %>% 
  pull()

qual_qid_prop_lab <- tw_get_property_label(qual_qid_prop_list)
qual_qid_prop_desc <- tw_get_property_description(qual_qid_prop_list)

qual_qid_prop_df <- data.frame(qual_qid_prop_list,
                               qual_qid_prop_lab,
                               qual_qid_prop_desc,
                               stringsAsFactors = FALSE)


# Merge Property & QID/Qualifier Info -------------------------------------

qual_qid_prop_all <- pvq_qual_qid_merge %>% 
  left_join(.,qid_prop_df,
            by = c("property" = "qid_prop_list")) %>% 
  left_join(.,qual_qid_prop_df,
            by = c("qualifier_property" = "qual_qid_prop_list")) %>% 
  # rename("property_lab" = "lvl2_property_lab",
  #        "property_desc" = "lvl2_property_desc",
  #        "qual_property_lab" = "lvl2_qual_property_lab",
  #        "qual_property_desc" = "lvl2_qual_property_desc") %>% 
  select(id,property,qid_prop_lab,qid_prop_desc,value,
         pv_qid_label,qualifier_property,qual_qid_prop_lab,
         qual_qid_prop_desc,qualifier_value,qual_qid_label,
         everything())


write_csv(qual_qid_prop_all,
          paste0("data/wikidata_metadata_all_", today, ".csv"))


# Data Visualization ------------------------------------------------------

# write to CSV
# NOTE: your file name is likely different
prop_freq <- read_csv(paste0("data/property_qid_frequency_2025-05-13.csv")) %>% 
  select(prop_id,count) %>% 
  mutate(prop_name = tw_get_property_label(prop_id))

# visualize property frequency

prop_freq %>% 
  filter(count >= 34) %>% 
  ggplot(aes(x = reorder(prop_name,count),
             y = count)) +
  geom_bar(stat = "identity",
           fill = "red4",
           color = "black") +
  theme_bw() +
  labs(y = "Number of QIDs with the Property") +
  geom_text(aes(label = count),
            hjust = -0.25) +
  theme(text = element_text(size = 14),
        axis.title.y = element_blank()) +
  coord_flip() +
  ylim(0,900)

ggsave(paste0("figures/number_QIDs_",today,".png"),plot = last_plot(),
       width = 6, height = 4, dpi = 300)


# Identify Institutional Affiliations -------------------------------------


# see list of items with "Oklahoma State University" in the item name
osu_qids <- find_item("Oklahoma State University",
                      limit = 100) 

osu_qid_df <- data.frame(matrix(nrow = length(osu_qids), ncol = 2))
colnames(osu_qid_df) <- c("qid","label")

for(x in 1:length(osu_qids)){
  item <- x
  osu_qid_df[item,1] <- osu_qids[[item]]$id
  osu_qid_df[item,2] <- osu_qids[[item]]$label
}

# list out unneeded entries (your will be different)
# e.g., Oklahoma State Cowboys and Cowgirls (sports teams), Oklahoma State University Bookstore

osu_removals <- c("Q3001865","Q7082382","Q7082380",
                  "Q7082387","Q67425031","Q29007509",
                  "Q99476304","Q67421779","Q132577836")

# and extract the desired institutional QIDs
osu_qid_list <- osu_qid_df %>% 
  filter(!(qid %in% osu_removals)) %>%  
  pull(qid)

# search for values and qualifier values with OSU mentions
osu_in_wikidata <- qual_qid_prop_all %>% 
  filter(value %in% osu_qid_list | qualifier_value %in% osu_qid_list)

# and explore information about these entries

# what properties are they providing info for?
osu_in_wikidata %>% 
  group_by(qid_prop_lab,qual_qid_prop_lab) %>% 
  count() %>% 
  arrange(desc(n))

# for qualifier info, which QIDs have these?
osu_qual_mentions <- osu_in_wikidata %>% 
  filter(qualifier_value %in% osu_qid_list) %>% 
  select(id,qid_prop_lab,qual_qid_prop_lab,qualifier_value) %>% 
  distinct() %>% 
  pull()

# which OSU QIDs are being used?
osu_in_wikidata %>% 
  group_by(pv_qid_label) %>% 
  count() %>% 
  arrange(desc(n))

osu_in_wikidata %>% 
  group_by(qual_qid_label) %>% 
  count() %>% 
  arrange(qual_qid_label) %>% # alphabetize
  print(n = 50) 


### Visualize OSU Affiliations ----------------------------------------------

osu_in_wikidata %>% 
  filter(!is.na(pv_qid_label)) %>% 
  select(id,value,pv_qid_label) %>% 
  distinct() %>% 
  group_by(value,pv_qid_label) %>% 
  count() %>% 
  mutate(pv_qid_label = gsub("Oklahoma State University",
                             "OSU",
                             pv_qid_label)) %>% 
  ggplot(aes(x = reorder(pv_qid_label,-n),
             y = n)) +
  geom_bar(stat = "identity",
           fill = "black") +
  theme_bw() +
  labs(x = "OSU Affiliations",
       y = "Number of QIDs with the Affiliation") +
  geom_text(aes(label = n),
            vjust = -0.5) +
  theme(text = element_text(size = 14),
        axis.text.x = element_text(size = 8)) +
  ylim(0,630) +
  scale_x_discrete(labels = wrap_format(10))

ggsave(paste0("figures/number_affiliations_",today,".png"),plot = last_plot(),
       width = 8, height = 4, dpi = 300)
