/* =====================================================

	Pooled OLS Data Cleaning
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


foreach year in 2005 2019 2022 2025 {
	
	* Year identifier to read file format, example, 5 will be 05 if single digit
        local qmax = cond(`year'==2025, 2, 4)
        local yr_id : display %02.0f (`year' - 2000)

   forval quarter = 1/`qmax' {
   	
		* Import data
		use "$raw_data/ENOE/`year'trim`quarter'_dta/COE1T`quarter'`yr_id'.dta", clear
		merge 1:1 cd_a-eda using "$raw_data/ENOE/`year'trim`quarter'_dta/COE2T`quarter'`yr_id'.dta"
		drop _m

		* Now merge the agem data and sociodemographic
		* salario (minimum wage)
		* sex 
		* eda (age)
		* cs_p13_1 (education)
		* e_con (marital status) 
		* n_hij (# children)
		* anios_esc (years of schooling)
		* l_nac_c (place of birth)

		local vars = "salario sex eda cs_p13_1 e_con n_hij anios_esc l_nac_c"

		merge m:1 r_def-n_ren using "$raw_data/ENOE/`year'trim`quarter'_dta/SDEMT`quarter'`yr_id'.dta", keepusing(loc mun `vars')
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
		if yr == 2022 | yr == 2025 {
			ren fac_tri fac
		}
		
		*-------------------------------------------------------
		* Create control variables for regression analysis
		*-------------------------------------------------------

		* salario (minimum wage)
		* sex 
		* eda (age)
		* cs_p13_1 (education)
		* e_con (marital status) 
		* n_hij (# children)
		* anios_esc (years of schooling)
		* l_nac_c (place of birth)
		
		* Make sex dummy
		replace sex = 0 if sex == 1
		replace sex = 1 if sex == 2
		
		* Married dummy
		gen married = 0
		replace married = 1 if e_con == 5
		drop e_con
		
		* Rename children variable
		ren n_hij n_children
		
		* Rename education variable
		ren cs_p13_1 education
		
		* Rename years of schooling
		ren anios_esc schooling
		
		* Foreign dummy
		gen foreign = 0
		replace foreign = 1 if l_nac_c > 100
		drop l_nac_c
		
		* Keep relevant variables
		keep r_def-n_ren yr quarter mon_inc net_wage fac age p3 inf mun ent sex-schooling  salario married foreign
		
		* Remember that wages for informal sector have not tax accrued
		replace net_wage = mon_inc if inf == 1
		
		* Save dataset to append later
		save "$processed_data/enoe_pols_`year'q`quarter'_sinco.dta", replace
		
	}

}
		
		
* Append and compute means

clear
set more off

local first = 1

foreach year in 2005 2019 2022 2025 {
    if (`year' <= 2019 | `year' == 2022| `year' == 2025) {
        local qmax = cond(`year'==2025, 2, 4)
        forvalues quarter = 1/`qmax' {
        local f "$processed_data/enoe_pols_`year'q`quarter'_sinco.dta"
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

* Collapse to annual values, ENOE follows the individual for 5 quarters, so compute average
collapse (mean) mon_inc net_wage schooling n_children fac salario (first) age, by(r_def-n_ren p3 ent mun yr inf married foreign sex)

* Rename variables
ren p3 sinco
ren fac labor
* Minimum wage dummy
gen min_wage = 0
replace min_wage = 1 if mon_inc < salario
drop salario


* Merge WB WDI inflation rate and deflate wages
merge m:1 yr using "$raw_data//wb_wdi_variables.dta"
drop if _m == 2
drop _m

* Create log real hourly wages
gen ln_rwages = ln((net_wage/20*8)/cpi_2005)

* Label variables and save database
lab var sinco "Occupation Code (SINCO)"
lab var yr "Year"
lab var inf "Informal dummy"
lab var labor "Total Labor"
lab var schooling "Years of schooling"
lab var n_children "Number of children"
lab var age "age"
lab var foreign "Foreign dummy"
lab var married "Married dummy"
lab var sex "Sex dummy, male == 1"
lab var ln_rwages "Log Real Wages, (2005 Pesos)"
lab var mon_inc "Monthly monetary income (Pesos)"
lab var net_wage "Monthly Net Wage (Pesos)"
	
save "$processed_data/enoe_pols_sinco.dta", replace

* Crosswalk to SOC
use "$processed_data/enoe_pols_sinco.dta", replace

merge m:1 sinco using "$processed_data/crosswalk_sinco_soc.dta", keepusing(soc soc_def)
keep if _m == 3
drop _m
drop if soc == "na"

save "$processed_data/enoe_pols_soc.dta", replace

*-----------------------------------------------------------------
**# Crosswalk to O*NET
*-----------------------------------------------------------------

use "$processed_data/enoe_pols_soc.dta", replace
ren soc soc0
destring(soc0), replace
merge m:1 soc0 using "$processed_data/crosswalk_soc_dot.dta"
keep if _m == 3
drop _m
drop soc_def

save "$processed_data/enoe_pols_soc_onet.dta", replace


*-----------------------------------------------------------------
**# Merge task information ALM (2003)
*-----------------------------------------------------------------
* Merge RTI and AD(2013) occupational group classification
use "$processed_data//enoe_pols_soc_onet.dta", clear
merge m:1 soc using "$raw_data/RTI/tasks_data.dta"	
drop if _m == 2
drop _m 
drop if occ_category == ""


lab var task_abstract "Average Abstract Task Index Value"
lab var task_routine "Average Routine Task Index Value"
lab var task_manual "Average Manual Task Index Value"

* Create RTI variable
gen rti = ln(task_routine) - ln(task_manual) - ln(task_abstract)
drop if missing(rti)

lab var rti "Routine Task Intensiveness"

* Merge SML averages 
merge m:1 soc using "$processed_data/sml_data.dta"	
drop if _m == 2
drop _m 

drop if msml == .
lab var msml "Average SML value (1-5)"


* Merge AI exposure (Dani Rock 2023)
merge m:1 soc using "$processed_data/ai_exposure.dta"	
drop if _m == 2
drop _m 

lab var alpha "Share of jobs who have 1/2 their tasks affected by AI E1"
lab var beta "E1 + 0.5E2"
lab var gamma "E1 + E2"

* Generate employment shares, create AGEM id
replace mun = 0 if mun == .
gen aux = ent
tostring aux, replace
tostring mun, replace
gen agem = aux + mun
drop aux
ren ent state
order r_def-n_ren agem soc 

* Save accordingly
save "$processed_data//enoe_pols_soc_tasks.dta", replace				
					










