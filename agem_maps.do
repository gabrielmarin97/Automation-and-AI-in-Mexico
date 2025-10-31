/* =====================================================

	AGEM Map Creation
	Gabriel Marin, Anahuac University
	gabriel.marinmu@anahuac.mx

	Note: This do-file creates the shape file for AGEM
	RTI and SML plotmaps.
	
	You require:
	
	      ssc install spmap

          ssc install shp2dta

          ssc install mif2dta

====================================================== */

clear all
set more off

* Transform shape file to stata dta
shp2dta using "$raw_data//Maps/INEGI/mg_2024_integrado/conjunto_de_datos/00mun.shp", database("$processed_data//aegm_mx.dta") coordinates("$processed_data//coords_mx") genid(mun_id) replace

* Use the shape file
use "$processed_data//aegm_mx.dta", clear

* Describe
describe

* To test, will create a random number between 0 and 1 and then plot by municipality

gen test = runiform(0,1)

* Create a map
spmap test using "$processed_data//coords_mx", id(mun_id) fcolor(Blues)



** State maps
* Transform shape file to stata dta
shp2dta using "$raw_data//Maps/INEGI/mg_2024_integrado/conjunto_de_datos/00ent.shp", database("$processed_data//aegm_ent_mx.dta") coordinates("$processed_data//coords_ent_mx") genid(ent_id) replace

* Use the shape file
use "$processed_data//aegm_ent_mx.dta", clear

* Describe
describe

* To test, will create a random number between 0 and 1 and then plot by municipality

gen test = runiform(0,1)

* Create a map
spmap test using "$processed_data//coords_ent_mx", id(ent_id) fcolor(Blues)


/*
** Metropolitan maps
* Transform shape file to stata dta
shp2dta using "$raw_data//Maps/INEGI/mg_2024_integrado/conjunto_de_datos/00a.shp", database("$processed_data//aegm_zm_mx.dta") coordinates("$processed_data//coords_zm_mx") genid(zm_id) replace

* Use the shape file
use "$processed_data//aegm_zm_mx.dta", clear

* Describe
describe

* To test, will create a random number between 0 and 1 and then plot by municipality

gen test = runiform(0,1)

* Create a map
spmap test using "$processed_data//coords_zm_mx", id(zm_id) fcolor(Blues)

*/
