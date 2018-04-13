# PIHM_Forcing
Generate PIHM Forcing file (no. 7 in http://www.pihm.psu.edu/Downloads/Doc/pihm2.0_input_file_format.pdf),
from VIC grids (Prep,Temp,RH,Wind,Rn,VP), leaf area index (LAI) and roughness length (RL) from this excel file (https://ldas.gsfc.nasa.gov/nldas/web/web.veg.monthly.table.xls)


the latest version is meForcing.sh

the 500m is the TINs_GRIDs mapping file for Choke Canyon reservoir (Nuces basin huc8 ..06 - ..10),
731 TINs are generated from PIHM_gis using DEM of 500m, and mapped to the 1/8 th degree VIC grids.

Usage:
to generate the forcing file for Choke Canyon reservoir (Nuces basin huc8 ..06 - ..10), for years 1950 to 2010,
type the following command
nohup ./meForcing.sh 500m 1950 2010 &

n.b. you can run multiple instances at the same time, each will generate it's own temp folder

