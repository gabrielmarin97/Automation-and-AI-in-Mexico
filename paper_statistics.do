/* =====================================================

	Paper Statistics
	Gabriel Marin, Anahuac University
	gabrielmarinmu.97@gmail.com

	Note: This do-file creates the numbers used on the 
	body of the paper. 

====================================================== */

clear all
set more off

* Setup working directory (change accordingly)
cd "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data"

global raw_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Raw_Data"

global processed_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Processed_Data"

global do_files "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Do-Files"

*------------------------------------------------------------------------
**# Size of informal market 2025 Q1
*------------------------------------------------------------------------
/*
use "$raw_data//ENOE/2025trim1_dta/COE1T125.dta", clear
merge m:1 cd_a-eda using "$raw_data//ENOE/2025trim1_dta/COE2T125.dta"
		* Keep only those who work
		* p3h subordinates and those who obtain monetary wages
		* p6b2 declared salary
		* p6_7 those who declare they obtain salaries

		drop if p6b2 == . 
		drop if p1 == 2
		drop if p3h == . 
		drop if p6_7 == .

		
	* Informal classifier
		gen inf = 0 
		replace inf = 1 if p6d > 5
		lab var inf "Informal worker dummy."

	* Compute size of informal market
	gen fac = fac_tri*4
	tabstat fac, by(inf) stat(sum) format(%03.0f)
*/

*------------------------------------------------------------------------
**# Composition of occupations / occupational groups in 2019 (RTI) by State
*------------------------------------------------------------------------

* Relevant states for the text
* Tamaulipas, 28
* Nuevo Leon, 19
* Oaxaca, 20
* Chiapas, 7
* Yucatan 31
* Quintana Roo 23

local statenum = 31

	local t = "informal"
	local base_year = 2005
	local end_year = 2019

	* --- RTI Map (year-specific, with gray gaps) ---
	use "$processed_data/enoe_agem_annual_soc_tasks.dta", clear

	* 1) RTI measure
	gen rti = ln(task_routine) - ln(task_manual) - ln(task_abstract)
	drop if missing(rti)

	* 2) Weighted 66th percentile threshold in 2005
	preserve
		keep if yr == `base_year'
		bys yr: egen L = total(labor_`t')
		gen weight = labor_`t' / L
		_pctile rti , p(66.6667)
		scalar rti_p66 = r(r1)
			
	restore
	
	preserve
			keep if yr == 2019
			bys yr: egen L = total(labor_`t')
			gen weight_`t' = labor_`t' / L
			
			_pctile msml , p(66.6667)
			scalar sml_p66 = r(r1)
			
			_pctile alpha , p(66.6667)
			scalar alpha_p66 = r(r1)
			
	restore


	gen byte routine66 = rti > rti_p66
	gen byte sml66 = msml > sml_p66
	gen byte alpha66 = alpha > alpha_p66

	* 3) Muni-year totals (share of labor in high-RTI occs)
	gen rti_share = labor_`t' * routine66
	gen sml_share = labor_`t' * sml66
	gen alpha_share = labor_`t'* alpha66
	
	bys ent yr: egen Lmun = total(labor_`t')
	
	ren ent state
	keep if state == `statenum'
	keep if yr == 2019
	collapse(sum) labor_total labor_formal labor_informal rti_share (mean) Lmun, by(soc SOCTitle occ_category state)
	replace rti_share = rti_share/Lmun
	sort labor_`t'
	
	* Create share of total labor
	egen L = total(labor_`t')
	gen share_pop = labor_`t'/L
	
	
	di "Sanity Check: Total `t' Employment"
	tabstat labor_total, stat(sum)
	
	tabstat rti_share share_pop, by(occ_category) stat(sum)


*------------------------------------------------------------------------
**# Composition of occupations / occupational groups in 2025 (SML/AI) by State
*------------------------------------------------------------------------

