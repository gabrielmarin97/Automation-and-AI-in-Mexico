/* =====================================================

	SML Cleaning
	Gabriel Marin, Anahuac University
	gabrielmarinmu.97@gmail.com

	Note: This do-file creates the SML index by Eric and Dani
	changing SOC 2018 to SOC 2010

====================================================== */
clear all
set more off

* Import CSV
import delimited "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/R-Scripts/AI Exposure DR/allscores_SML.csv", clear 

* Create SOC subgroup, data comes with a "-", and enoe database has "."
gen soc = substr(onetsoc_code,1,2) + "." + substr(onetsoc_code,4,3) + "0"

* Quick fix that needs to be done properly, collapse with equal weights
* (weights must correspond some base year).

collapse (mean) msml, by(soc)

* Save database
save "$processed_data//sml_data.dta", replace
