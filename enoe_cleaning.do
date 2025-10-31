/* =====================================================

	ENOE Data Cleaning
	Gabriel Marin, Anahuac University
	gabrielmarinmu.97@gmail.com

	Note: This do-file cleans ENOE database to compute
	wages by occupation in the aggregate for graphs.
====================================================== */

clear all
set more off

* Setup working directory (change accordingly)
cd "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data"

global raw_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Raw_Data"

global processed_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Processed_Data"

global do_files "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Do-Files"

*-----------------------------------------------------------------
**# Collapse to annual data and recompute wages and labor
*-----------------------------------------------------------------
* ENOE has annualized labor, so annual transformation requires
* the mean, not the sum of all quarters

* Start from quarterly municipality×SOC file
use "$processed_data/enoe_agem_quarterly_soc_onet.dta", clear
* keys present: yr quarter ent mun soc0 soc dot
* vars: labor_total labor_formal labor_informal, mon_inc_*, net_wage_*

/*** 1) Build wage numerators (quarterly) ***/
foreach type in total formal informal {
    foreach v in mon_inc net_wage {
        gen `v'_`type'_w = `v'_`type' * labor_`type'
    }
}

/*** 2) First collapse: get QUARTERLY NATIONAL totals by SOC/DOT ***/
* Sum across municipalities/states within each yr×quarter×SOC/DOT
collapse (sum) ///
    labor_total labor_formal labor_informal ///
    mon_inc_total_w mon_inc_formal_w mon_inc_informal_w ///
    net_wage_total_w net_wage_formal_w net_wage_informal_w, ///
    by(yr quarter soc0 soc SOCTitle dot)
	
* Recompute wages
foreach type in total formal informal {
    foreach v in mon_inc net_wage {
        gen `v'_`type' = `v'_`type'_w / labor_`type'
		drop `v'_`type'_w
    }
}


* Save database
save "$processed_data/enoe_quarterly_soc_onet.dta", replace

/*** 3) Annualize at the SOC/DOT level (no municipalities) ***/
use "$processed_data/enoe_quarterly_soc_onet.dta", clear

* Create annual wage numerators
foreach type in total formal informal {
    foreach v in mon_inc net_wage {
        gen `v'_`type'_w = `v'_`type' * labor_`type'
    }
}


collapse (mean) labor_total_mean     = labor_total ///
           labor_formal_mean    = labor_formal ///
           labor_informal_mean  = labor_informal ///
    (sum)  labor_total_sum      = labor_total ///
           labor_formal_sum     = labor_formal ///
           labor_informal_sum   = labor_informal ///
    (sum)  mon_inc_total_w      mon_inc_formal_w      mon_inc_informal_w ///
           net_wage_total_w     net_wage_formal_w     net_wage_informal_w ///
    (count) q_obs = quarter, ///
    by(yr soc0 soc SOCTitle dot)

/*** 4) Compute annual wages (labor-weighted across quarters) ***/
foreach type in total formal informal {
    gen mon_inc_`type'  = mon_inc_`type'_w  / labor_`type'_sum  if labor_`type'_sum>0
    gen net_wage_`type' = net_wage_`type'_w / labor_`type'_sum  if labor_`type'_sum>0
    replace mon_inc_`type'  = . if labor_`type'_sum==0
    replace net_wage_`type' = . if labor_`type'_sum==0
}

/*** 5) Set the annual labor series to the MEAN across quarters ***/
gen labor_total     = labor_total_mean
gen labor_formal    = labor_formal_mean
gen labor_informal  = labor_informal_mean

/*** 6) Cleanup and save ***/
order yr soc0 soc dot ///
      labor_total labor_formal labor_informal ///
      mon_inc_total net_wage_total ///
      mon_inc_formal net_wage_formal ///
      mon_inc_informal net_wage_informal

* Drop auxiliary variables
drop labor_total_mean-q_obs

* Label variables and save database
lab var soc "SOC code"
lab var soc0 "SOC code (double) "
lab var SOCTitle "SOC Title"
lab var dot "DOT code"
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

save "$processed_data/enoe_annual_soc_onet.dta", replace

* Sanity Check, no jumps
preserve
	collapse(sum) labor_total, by(yr)
	tabstat labor_total, stat(mean) by(yr) format(%15.0fc)
restore

*-----------------------------------------------------------------
**# Merge task information ALM (2003)
*-----------------------------------------------------------------
use "$processed_data//enoe_annual_soc_onet.dta", clear
merge m:1 soc using "$raw_data/RTI/tasks_data.dta"	
drop if _m == 2
drop _m 

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
save "$processed_data//enoe_annual_soc_tasks.dta", replace				
					





