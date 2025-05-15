# ATTRIBUTION
# This code was originally developed by Clarke Iakovakis as part of a
# workshop for the FORCE11 Scholarly Communication Institute (FSCI) in 2019.
# The most recent iteration of this course and code is available on Zenodo:
  # Kirsch, D., & Clarke Iakovakis. (2024). FSCI 2024 Course V11: 
  # Using the ORCID, Sherpa Romeo, and Unpaywall APIs in R to Harvest 
  # Institutional Data (v1.0.0). Zenodo. https://doi.org/10.5281/zenodo.13742679

library(rorcid)
library(tidyverse)
library(glue)
library(httr)
library(usethis)
library(janitor)

# mark system date for use in file naming
today <- Sys.Date()

# ORCID authentication ----------------------------------------------------

### Set up orcid ------------------------------------------------------------

# 1. If you haven’t done so already, create an ORCID account at https://orcid.org/signin. 
# 2. In the upper right corner, click your name, then in the drop-down menu, click Developer Tools. Note: In order to access Developer Tools, you must verify your email address. 
# 3. If you have not already verified your email address, you will be prompted to do so at this point.
# 4. Click the “Register for the free ORCID public API” button
# 5. Review and agree to the terms of service when prompted.
# 6. Add your name in the Name field, https://www.orcid.org in the Your Website URL field, “Getting public API key” in Description field, and https://www.orcid.org in the redirect URI field. Click the diskette button to save.
# 7. A gray box will appear including your Client ID and Client Secret. In the below code chunk, copy and paste the client ID and the client secret respectively. 
# 8. Make sure to leave the quotation marks (e.g. orcid_client_id <- "APP-FDFJKDSLF320SDFF" and orcid_client_secret <- "c8e987sa-0b9c-82ed-91as-1112b24234e"). 

# copy/paste your client ID from https://orcid.org/developer-tools
orcid_client_id <- "PASTE MY CLIENT ID HERE"

# copy/paste your client secret from https://orcid.org/developer-tools
orcid_client_secret <- "PASTE MY CLIENT SECRET HERE"

orcid_request <- POST(url  = "https://orcid.org/oauth/token",
                      config = add_headers(`Accept` = "application/json",
                                           `Content-Type` = "application/x-www-form-urlencoded"),
                      body = list(grant_type = "client_credentials",
                                  scope = "/read-public",
                                  client_id = orcid_client_id,
                                  client_secret = orcid_client_secret),
                      encode = "form")

# parse the API request with content
orcid_response <- content(orcid_request)


# run the following code
print(orcid_response$access_token)


#You will see a string of text print out in your R console.
# Copy that string to the keyboard for use below

# now we are going to save the token to our R environment
# Run this code:
usethis::edit_r_environ()



# A new window will open in RStudio.
# In this separate R environment page, type the following (except the pound sign):
# ORCID_TOKEN="my-token"
# replace 'my-token' with the access_token you just copied. 
# Then press enter to create a new line, and leave it blank. 
# Press Ctrl + S (Mac: Cmd + S) to save this information to your R environment and close the window. You won't see anything happen here because it is just saving the page.
# Click Session > Restart R. Your token should now be saved to your R environment. 

# You will need to reload all packages after restarting R

# build the query  --------------------------------------------------------

email_domain <- "@okstate.edu" 
organization_name <- "Oklahoma State University"
ror_id <- "https://ror.org/01g9vbr38"

# create the query
my_orcid_query <- glue('ror-org-id:"', 
                       ror_id, 
                       '" OR email:*', 
                       email_domain, 
                       ' OR affiliation-org-name:"', 
                       organization_name, '"')

# examine my_orcid_query
my_orcid_query

# get the counts
orcid_count <- base::attr(rorcid::orcid(query = my_orcid_query),
                          "found")

# create the page vector
my_pages <- seq(from = 0, to = orcid_count, by = 200)

# get the ORCID iDs
my_orcids <- purrr::map(
  my_pages,
  function(page) {
    print(page)
    my_orcids <- rorcid::orcid(query = my_orcid_query,
                               rows = 200,
                               start = page)
    return(my_orcids)
  })

# put the ORCID iDs into a single tibble
my_orcids_data <- my_orcids %>%
  map_dfr(., as_tibble) %>%
  janitor::clean_names()

# save dataset with list of ORCID iDs
write_csv(my_orcids_data, paste("./data/my_orcids_data_",today,".csv"))
