# okstate-wikidata-project  

This repository contains the most recent versions of R scripts for a Wikidata project being conducted at the Oklahoma State University Library.    
  
Script 1 (`01_obtain-ORCID-iDs.R`) is modified from code that was originally developed by Clarke Iakovakis as part of a course for the FORCE11 Scholarly Communication Institute (FSCI) in 2019. The most recent iteraction of this course and code is available on Zenodo:
> Kirsch, D., & Clarke Iakovakis. (2024). FSCI 2024 Course V11: Using the ORCID, Sherpa Romeo, and Unpaywall APIs in R to Harvest Institutional Data (v1.0.0). Zenodo. <https://doi.org/10.5281/zenodo.13742679>

The remaining scripts were compiled specifically for this project and were made possible by existing packages that interface with Wikidata, cited below:
> Shafee T, Keyes O, Signorelli S (2021). WikidataR: Read-Write API Client Library for Wikidata. <https://doi.org/10.32614/CRAN.package.WikidataR>, R package version 2.3.3.
  
> Comai G (2024). tidywikidatar: Explore 'Wikidata' Through Tidy Data Frames. <https://doi.org/10.32614/CRAN.package.tidywikidatar>, R package version 0.5.9.    
  
## Repository Contents  
### `01_obtain-ORCID-iDs.R`  
- Authenticate the user with the ORCID API  
- Create a custom query to search the ORCID database for ORCID iDs based on the presence of the institution's name, ROR ID, or email domain  
- Obtain a list of ORCID iDs affiliated with the user's institution  
### `02_wikidata-orcid-exploration.R`  
- Search Wikidata for items (QIDs) that are associated with the ORCID iDs obtained in Phase 1  
- Explore basic features of the data, such as  
  - Number of properties per QID  
  - Number of QIDs including each property  
### `03_wikidata-metadata-extraction.R`  
- Extract basic metadata from Wikidata  
  - QID  
  - Property  
  - Value  
- Extract qualifiers that provide additional detail for certain properties  
- Extract property labels and descriptions  
- Identify QIDs that represent institutional affiliations (e.g., campus, college, department) and explore their presence in the metadata  

## Contact Information  
**Principal Project Manager**  
Name: Dani Kirsch  
ORCID: 0000-0002-0928-3778  
Institution: Oklahoma State University  
Email: danielle.kirsch@okstate.edu  

**Graduate Research Assistant** (January 2025 - May 2025)  
Name: Rachana Kulkarni  
Institution: Oklahoma State University  
Email: rachana.kulkarni@okstate.edu  

## Sharing/Reuse Information  
The scripts provided in this repository are available for sharing and reuse under the [GNU General Public License, Version 3](https://www.gnu.org/licenses/gpl-3.0.en.html).  
