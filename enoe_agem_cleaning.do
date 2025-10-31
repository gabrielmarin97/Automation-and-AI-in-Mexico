/* =====================================================

	ENOE AGEM Data Cleaning
	Gabriel Marin, Anahuac University
	gabrielmarinmu.97@gmail.com

	Note: This do-file cleans ENOE database to compute
	wages by occupation and the AGEMs. Will require several
	merges with the household information part of the survey

====================================================== */

clear all
set more off

* Setup working directory (change accordingly)
cd "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data"

global raw_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Raw_Data"

global processed_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Processed_Data"

global do_files "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Do-Files"


* Looping through all years and quarters
forvalues year = 2022/2025 {
    if (`year' <= 2019 | `year' == 2022 | `year' == 2023 | `year' == 2024 | `year' == 2025 ) {
		
	di "Looping through `year'..."
	
	* Year identifier to read file format, example, 5 will be 05 if single digit
        local qmax = cond(`year'==2025, 2, 4)
        local yr_id : display %02.0f (`year' - 2000)

	forval quarter = 1/`qmax' {
	
	di "Starting Quarter `quarter'..."
	
qui {
	cap drop yr quarter
	gen yr = `year'
	gen quarter = `quarter'

	/*
	* Manually renamed
	* Variable names are in caps starting 2019Q3
	if (yr == 2019 & inlist(quarter,3,4)) {
		
		* Import data
		use "$raw_data/ENOE/`year'trim`quarter'_dta/COE1T`quarter'`yr_id'.dta", clear
		merge 1:1 CD_A-EDA using "$raw_data/ENOE/`year'trim`quarter'_dta/COE2T`quarter'`yr_id'.dta"
		drop _m
		
		* Now merge the agem data
		merge m:1 CON-PER using "$raw_data/ENOE/`year'trim`quarter'_dta/HOGT`quarter'`yr_id'.dta", keepusing(EST MUN LOC)
		drop if _m == 2
		drop _m 
		
		* standardize variable names back to lowercase
		rename *, lower

	}
	*/
	
		* Import data
		use "$raw_data/ENOE/`year'trim`quarter'_dta/COE1T`quarter'`yr_id'.dta", clear
		merge 1:1 cd_a-eda using "$raw_data/ENOE/`year'trim`quarter'_dta/COE2T`quarter'`yr_id'.dta", nogen 

		* Now merge the agem data
		merge m:1 con upm ent d_sem n_pro_viv v_sel n_hog h_mud n_ent per using "$raw_data/ENOE/`year'trim`quarter'_dta/HOGT`quarter'`yr_id'.dta", keepusing(est mun loc)
		drop if _m == 2
		drop _m 
		
		
		cap drop yr quarter
		
		* Generate year variable again
		gen yr = `year'
		gen quarter = `quarter'
		
		* Keep only those who work
		* p3h subordinates and those who obtain monetary wages
		* p6b2 declared salary
		* p6_7 those who declare they obtain salaries

		drop if p6b2 == . 
		drop if p1 == 2
		drop if p3h == . 
		drop if p6_7 == .

		* Drop agricultural workers, codes switch by ENOE year
		
		if yr <= 2008 {
			drop if inrange(p3, 4100, 4199)
		}
		
		else if inrange(yr, 2009, 2017) {
			drop if inlist(p3, ///
			1150,1153,1240,1242, ///
			4100,4101,4102,4103,4104,4105,4106,4107,4108,4109, ///
			4110,4111,4112,4113,4114,4115,4116,4119,4120, ///
			4130,4131,4132,4133,4134,4135,4136,4139,4140, ///
			4150,4151,4159,4160,4161,4169,4170,4190, ///
			5500,6170)
		}
		
		else if inrange(yr, 2018, 2025) {
			drop if  inlist(p3, 2231,2234,2613,2614,6111,6116,6112,6113,6114,6115) ///
         |  inlist(p3, 6119,6121,6122,6123,6124,6126,6125,6127,6129,6131) ///
         |  inlist(p3, 6221,6222,6223,6224,6225,6227,6226,6999,9123,6211) ///
         |  inlist(p3, 6212,6117,6213,6101,6311,1611)
		}
		
		
		* Monthly income estimation, multiply time by reported wage periodicity
		gen time = .
		replace time = 1 if p6b1 == 1
		replace time = 2 if p6b1 == 2
		replace time = 4 if p6b1 == 3
		replace time = 30 if p6b1 == 4
		drop if time == .

		gen mon_inc = time*p6b2
		lab var mon_inc "Monthly income (Pesos)"

		* Informal worker label
		* Drop workers who do not know if they receive health care
		drop if p6d == 9
		gen inf = 0 
		replace inf = 1 if p6d > 5
		lab var inf "Informal worker dummy."

		* Net Salary Calculator
		do "$do_files/net_salary_program.do"

		* Vacations value (question name changes after 2005)
		gen vacations = 0 
		if yr == 2005 {
			replace vacations = ((mon_inc/30)*6*1.25)/12 if p3l2 > 0
		}
		else {
			replace vacations = ((mon_inc/30)*6*1.25)/12 if p3k2 > 0
		}
		
		* Bonus
		gen bonus = 0
		if yr == 2005 {
			replace bonus = mon_inc/24 if p3l1 > 0
		}
		else { 
			replace bonus = mon_inc/24 if p3k1 > 0
		}

		* Social security
		gen inst = 0
		* ISSTE
		replace inst = 1 if p4d1 == 1
		replace inst = 1 if inlist(p3, 2100, 2101, 2110, 2130)
		replace inst = 1 if p3 > 8300 & p3 < 8309 | p3 > 6100 & p3 <6109

		* Armed forces
		replace inst = 3 if p3 > 8310 & p3 < 8390 

		* IMSS
		replace inst = 2 if inst == 0

		* Medical attention
		gen med_at = 0
		* ISSTE
		replace med_at = (.0275+.0625+.005) if inst == 1
		* IMSS 
		gen rate_aux = 0 
		replace rate_aux = 46.8
		replace rate_aux = 52.59 if inrange(yr, 2009, 2010)
		replace rate_aux = 59.82 if yr == 2011
		replace rate_aux = 46.8 if inrange(yr, 2012, 2017)
		replace rate_aux = 88.36 if inrange(yr, 2018, 2025)
		replace med_at = (.00625+.01125+.02) if inst == 2 & mon_inc > 90*rate_aux
		*ISSFAM 
		replace med_at = (.06+.03) if inst == 3
		drop rate_aux 

		* Social security
		gen social_sec = med_at*mon_inc

		* Net Wages
		gen net_wage = mon_inc - social_sec - tax - fee + vacations

		* Drop age groups below 15
		drop if eda < 15
		ren eda age
		* Keep relevant variables
		if yr == 2022 | yr == 2023 | yr == 2024| yr == 2025 {
			ren fac_tri fac
		}
		*-------------------------------------------------------
		* Create control variables for regression analysis
		*-------------------------------------------------------

		* College/NonCollege population
		* Manufacturing share of total employment
		* Unemployment rate
		* Female share in population
		* Elderly (65+) share in population
		* Share of workers with wages below minimum wage
		
		
		
		keep yr quarter mon_inc net_wage fac age p3 inf mun ent
		
		* Remember that wages for informal sector have not tax accrued
		replace net_wage = mon_inc if inf == 1
		
		* Create wages weighted by expansion factor
		
		* create weighted numerators
		gen mon_inc_total  = mon_inc * fac
		gen net_wage_total = net_wage * fac
				
		gen fac_informal = fac if inf == 1
		gen fac_formal = fac if inf == 0
		
		* Create wages for formal and informal workers
		gen mon_inc_formal = mon_inc*fac_formal
		gen mon_inc_informal = mon_inc*fac_informal

		gen net_wage_formal = net_wage*fac_formal
		gen net_wage_informal = net_wage*fac_informal

		drop mon_inc net_wage
		
		
		* collapse sums
		collapse (sum) mon_inc_* net_wage* fac*, by(yr quarter p3 mun ent)
		
		* Sinco remains until 2012Q2, modify boolean to include this
		local qmax1 = cond(`year'==2012, 2, 4)
		if inrange(yr, 2005, 2012) & inrange(quarter,1,	`qmax1') {
			ren p3 cmo
		}
		else {
			ren p3 sinco
		}
		ren fac fac_total
		* compute weighted means
		foreach t in total formal informal {
			replace mon_inc_`t'  = mon_inc_`t' / fac_`t'
			replace net_wage_`t' = net_wage_`t' / fac_`t'
		}
		
		local qmax1 = cond(`year'==2012, 2, 4)
		if inrange(yr, 2005, 2012) & inrange(quarter,1,	`qmax1') {				
			save "$processed_data/enoe_agem_`year'q`quarter'_cmo.dta", replace	
		}
		
		else{ 
			save "$processed_data/enoe_agem_`year'q`quarter'_sinco.dta", replace
		}
		}
	}

}

}


* Crosswalk from CMO to SINCO until 2012 quarter 4

forval year = 2005/2012 {
	local qmax1 = cond(`year'==2012, 2, 4)
	forval quarter = 1/`qmax1' {

	use "$processed_data/enoe_agem_`year'q`quarter'_cmo.dta", clear	
	
	joinby cmo using "$processed_data/crosswalk_cmo_sinco.dta"

	* An issue here is that weights given sometimes don't add to one as not all occupations
	* appear every time, need to reweight in case this happens at any point in time
	sort ent cmo mun 
	by ent cmo mun: egen reweight = sum(weight)
	replace weight = weight/reweight

* Now create wages again, including the weight
	foreach var in mon_inc net_wage {
		foreach t in total formal informal{
			replace fac_`t' = fac_`t'*weight
			gen `var'_`t'_w = `var'_`t'*fac_`t'
		}	
	}
	
	collapse (sum) fac_total-fac_formal mon_inc_total_w-net_wage_informal_w, by(yr quarter mun ent sinco)
	
	foreach var in mon_inc net_wage {
	foreach t in total formal informal{
			replace `var'_`t'_w = `var'_`t'_w/fac_`t'
			ren `var'_`t'_w `var'_`t'
		}	
	}
	save "$processed_data/enoe_agem_`year'q`quarter'_sinco.dta", replace
		
	}
}



*-----------------------------------------------------------------
**# Database appending and Wage and Labor Computation
*-----------------------------------------------------------------

* After the merge, some occupations have formal wages only and others informal
* wages only. The ones who have informal wages seem reasonable codes,
* painters, agricultural workers, technicians.


* Appending databases 
clear
set more off

local first = 1

forvalues year = 2005/2025 {
    if (`year' <= 2019 | `year' == 2022| `year' == 2023|  `year' == 2024 | `year' == 2025) {
        local qmax = cond(`year'==2025, 2, 4)
        forvalues quarter = 1/`qmax' {
        local f "$processed_data/enoe_agem_`year'q`quarter'_sinco.dta"
        capture confirm file `"`f'"'
        if !_rc {
            if `first' {
                use `"`f'"', clear
                local first = 0
            }
            else {
                append using `"`f'"'
            }
            *erase `"`f'"'
        }
        // if file doesn't exist, quietly skip
    }
}
}


sort yr quarter sinco

foreach t in total formal informal{
	ren fac_`t' labor_`t'
	}


* Label variables and save database
lab var sinco "Occupation Code (SINCO)"
lab var yr "Year"
lab var quarter "Quarter"
lab var labor_formal "Total Labor (Formal)"
lab var mon_inc_formal "Monthly Income (Pesos, Formal)"
lab var net_wage_formal "Monthly Net Wages (Pesos, Formal)"
lab var labor_informal "Total Labor (Informal)"
lab var mon_inc_informal "Monthly Income (Pesos, Informal)"
lab var net_wage_informal "Monthly Net Wages (Pesos, Informal)"
lab var labor_total "Total Labor"
lab var mon_inc_total "Average Monthly Monetary Income"
lab var net_wage_total "Average Net Monthly Wage"
	
save "$processed_data/enoe_agem_quarterly_sinco.dta", replace
	
di as result "Appended and cleaned panel saved. Quarterly files removed."

di as result "Sanity Checks: Annualized Labor per Year"

use "$processed_data/enoe_agem_quarterly_sinco.dta", clear

preserve
	collapse(sum) labor_total, by(yr quarter)
	tabstat labor_total, by(yr) stat(mean) format(%15.0fc)
restore

*-----------------------------------------------------------------
**# Crosswalk to SOC
*-----------------------------------------------------------------

use "$processed_data/enoe_agem_quarterly_sinco.dta", clear


* You lose some observations in 2025, need to check

merge m:1 sinco using "$processed_data/crosswalk_sinco_soc.dta", keepusing(soc soc_def)
keep if _m == 3
drop _m
drop if soc == "na"

save "$processed_data/enoe_agem_quarterly_soc.dta", replace

*-----------------------------------------------------------------
**# Crosswalk to O*NET
*-----------------------------------------------------------------

use "$processed_data/enoe_agem_quarterly_soc.dta", clear
ren soc soc0
destring(soc0), replace
merge m:1 soc0 using "$processed_data/crosswalk_soc_dot.dta"
keep if _m == 3
drop _m
drop soc_def

save "$processed_data/enoe_agem_quarterly_soc_onet.dta", replace

*-----------------------------------------------------------------
**# Collapse to annual data and recompute wages and labor
*-----------------------------------------------------------------
* ENOE has annualized labor, so annual transformation requires
* the mean, not the sum of all quarters

* Start from quarterly municipality×SOC file
use "$processed_data/enoe_agem_quarterly_soc_onet.dta", clear
* keys: yr quarter ent mun soc0 soc dot
* vars: labor_total labor_formal labor_informal, mon_inc_*, net_wage_*

/*** 1) Build wage numerators (quarterly) ***/
foreach type in total formal informal {
    foreach v in mon_inc net_wage {
        gen `v'_`type'_w = `v'_`type' * labor_`type'
    }
}

/*** 2) Collapse to QUARTERLY cells at muni×SOC (if micro) ***/
collapse (sum) ///
    labor_total labor_formal labor_informal ///
    mon_inc_total_w mon_inc_formal_w mon_inc_informal_w ///
    net_wage_total_w net_wage_formal_w net_wage_informal_w, ///
    by(yr quarter ent mun soc0 soc SOCTitle dot)

/*** 3) Annualize MUNICIPALITY anchors (independent per total/formal/informal) ***/
preserve
    * Quarterly municipal totals
    collapse (sum) labor_total labor_formal labor_informal, by(yr quarter ent mun)
    * Annual municipal labor = mean across quarters (ENOE stock)
    collapse (mean) ///
        labor_mun_total_annual    = labor_total ///
        labor_mun_formal_annual   = labor_formal ///
        labor_mun_informal_annual = labor_informal ///
        (count) q_obs_mun = quarter, ///
        by(yr ent mun)
    tempfile MUN_ANCHOR
    save `MUN_ANCHOR'
restore

/*** 4) Annualize SOC/DOT within municipality ***/
collapse ///
    (mean) labor_total_mean     = labor_total ///
           labor_formal_mean    = labor_formal ///
           labor_informal_mean  = labor_informal ///
    (sum)  labor_total_sum      = labor_total ///
           labor_formal_sum     = labor_formal ///
           labor_informal_sum   = labor_informal ///
    (sum)  mon_inc_total_w      mon_inc_formal_w      mon_inc_informal_w ///
           net_wage_total_w     net_wage_formal_w     net_wage_informal_w ///
    (count) q_obs_soc = quarter, ///
    by(yr ent mun soc0 soc SOCTitle dot)

/*** 5) Bring in municipal anchors ***/
merge m:1 yr ent mun using `MUN_ANCHOR', nogen

* Optionally restrict to full coverage:
* keep if q_obs_mun==4 & q_obs_soc==4

/*** 6) Rescale SOC annual labor to match municipal anchors ***/
* Sum SOC annual (mean) labor within muni-year, per component
bys yr ent mun: egen Ltot_mean_sum = total(labor_total_mean)
bys yr ent mun: egen Lfor_mean_sum = total(labor_formal_mean)
bys yr ent mun: egen Linf_mean_sum = total(labor_informal_mean)

gen scale_tot = cond(Ltot_mean_sum>0, labor_mun_total_annual    / Ltot_mean_sum, .)
gen scale_for = cond(Lfor_mean_sum>0, labor_mun_formal_annual   / Lfor_mean_sum, .)
gen scale_inf = cond(Linf_mean_sum>0, labor_mun_informal_annual / Linf_mean_sum, .)

* Rescaled annual labor (SOC×muni)
gen labor_total     = labor_total_mean    * scale_tot
gen labor_formal    = labor_formal_mean   * scale_for
gen labor_informal  = labor_informal_mean * scale_inf
label var labor_total    "Annual labor TOTAL (SOC×muni) rescaled to muni anchor"
label var labor_formal   "Annual labor FORMAL (SOC×muni) rescaled to muni anchor"
label var labor_informal "Annual labor INFORMAL (SOC×muni) rescaled to muni anchor"

/*** 7) Compute annual wages separately for total/formal/informal ***/
* Use quarterly-scale denominators (sums of quarterly labor)
foreach type in total formal informal {
    gen mon_inc_`type'  = mon_inc_`type'_w  / labor_`type'_sum  if labor_`type'_sum>0
    gen net_wage_`type' = net_wage_`type'_w / labor_`type'_sum  if labor_`type'_sum>0
    replace mon_inc_`type'  = . if labor_`type'_sum==0
    replace net_wage_`type' = . if labor_`type'_sum==0
}



* Be explicit about what to drop; avoid range-dropping unintended vars
drop labor_total_mean-scale_inf

* Label variables and save database
lab var soc "SOC code"
lab var soc0 "SOC code (double) "
lab var SOCTitle "SOC Description"
lab var dot "DOT code"
lab var ent "State"
lab var mun "Municipality"
lab var yr "Year"
lab var labor_formal "Total Labor (Formal)"
lab var mon_inc_formal "Monthly Income (Pesos, Formal)"
lab var net_wage_formal "Monthly Net Wages (Pesos, Formal)"
lab var labor_informal "Total Labor (Informal)"
lab var mon_inc_informal "Monthly Income (Pesos, Informal)"
lab var net_wage_informal "Monthly Net Wages (Pesos, Informal)"
lab var labor_total "Total Labor"
lab var mon_inc_total "Average Monthly Monetary Income"
lab var net_wage_total "Average Net Monthly Wage"

save "$processed_data/enoe_agem_annual_soc_onet.dta", replace


* Sanity Check, no jumps
preserve
	collapse(sum) labor_total, by(yr)
	tabstat labor_total, stat(mean) by(yr) format(%15.0fc)
restore

*-----------------------------------------------------------------
**# Merge task information ALM (2003)
*-----------------------------------------------------------------
* Merge RTI and AD(2013) occupational group classification
use "$processed_data//enoe_agem_annual_soc_onet.dta", clear
merge m:1 soc using "$raw_data/RTI/tasks_data.dta"	
drop if _m == 2
drop _m 
drop if occ_category == ""

* Merge SML averages 
merge m:1 soc using "$processed_data/sml_data.dta"	
drop if _m == 2
drop _m 

drop if msml == .

* Merge AI exposure (Dani Rock 2023)
merge m:1 soc using "$processed_data/ai_exposure.dta"	
drop if _m == 2
drop _m 

* Save accordingly
save "$processed_data//enoe_agem_annual_soc_tasks.dta", replace				
					





