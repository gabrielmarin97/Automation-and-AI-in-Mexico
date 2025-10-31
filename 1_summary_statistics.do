/* =====================================================

	Summary Statistics
	Gabriel Marin, Anahuac University
	gabriel.marinmu@anahuac.mx

	Note: This do-file computes several tables for the paper.
	
====================================================== */

clear all
set more off

* Setup working directory (change accordingly)
cd "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data"

global raw_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Raw_Data"

global processed_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Processed_Data"

global do_files "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Do-Files"

global output "/Users/gmm/Dropbox/Apps/Overleaf/Labor Markets and Automation in the Open Economy"

*-----------------------------------------------------------------------
**#  TABLE 1: Log Mean Wage and Employment Shares Formal
*-----------------------------------------------------------------------
clear all
use "$processed_data/enoe_annual_soc_tasks.dta", clear
drop if occ_category == ""
* Merge wdi inflation data  
merge m:1 yr using "$raw_data//wb_wdi_variables.dta",  keep(match) nogen

* Create table variables
foreach t in formal informal {
	bys occ_category yr: egen Lcat_`t' = total(labor_`t')
	bys yr: egen L`t' = total(labor_`t')
	gen employment_share_`t' = (Lcat_`t'/L`t')*100
	gen lnw_`t' = ln((net_wage_`t'/cpi_2005)/(20*8)) if net_wage_`t' > 0
	bys occ_category yr: egen avg_wage_`t' = wtmean(lnw_`t'), weight(labor_`t')

}

* Keep relevant years, make category shorter for table
keep if inlist(yr, 2005, 2010, 2015, 2019, 2022, 2025)
replace occ_category = "Transportation*" if occ_category == "Transportation/construction/mechanics/mining/farm"
replace occ_category = "Managers*" if occ_category == "Managers/ professionals / technicians / finance/ public safety"
* Create occupation ranking based on average wage levels across all years
bys occ_category: egen avg_wage_overall = mean(lnw_formal)
egen occ_rank = rank(-avg_wage_overall), unique
sort occ_rank yr


* Collapse to relevant variables
collapse (mean) employment_share* lnw_* (first) occ_rank, by(occ_category yr )
sort occ_rank yr

* Calculate growth rates 
local t = "formal"
sort occ_category yr
by occ_category: gen emp_share_2005 = employment_share_`t' if yr == 2005
by occ_category: gen emp_share_2010 = employment_share_`t' if yr == 2010
by occ_category: gen emp_share_2015 = employment_share_`t' if yr == 2015
by occ_category: gen emp_share_2019 = employment_share_`t' if yr == 2019
by occ_category: gen emp_share_2022 = employment_share_`t' if yr == 2022
by occ_category: gen emp_share_2025 = employment_share_`t' if yr == 2025

by occ_category: gen wage_2005 = lnw_`t' if yr == 2005
by occ_category: gen wage_2010 = lnw_`t' if yr == 2010
by occ_category: gen wage_2015 = lnw_`t' if yr == 2015
by occ_category: gen wage_2019 = lnw_`t' if yr == 2019
by occ_category: gen wage_2022 = lnw_`t' if yr == 2022
by occ_category: gen wage_2025 = lnw_`t' if yr == 2025


by occ_category: egen emp_2005 = max(emp_share_2005)
by occ_category: egen emp_2019 = max(emp_share_2019)
by occ_category: egen emp_2022 = max(emp_share_2022)
by occ_category: egen emp_2025 = max(emp_share_2025)
by occ_category: egen w_2005 = max(wage_2005)
by occ_category: egen w_2019 = max(wage_2019)
by occ_category: egen w_2022 = max(wage_2022)
by occ_category: egen w_2025 = max(wage_2025)

* Growth calculations
gen emp_growth_05_19 = ((emp_2019/emp_2005)-1) * 100
gen emp_growth_22_25 = ((emp_2025/emp_2022)-1) * 100
gen wage_growth_05_19 = ((w_2019/w_2005)-1) * 100  
gen wage_growth_22_25 = ((w_2025/w_2022)-1) * 100

collapse(mean) emp_share_2005-wage_growth_22_25 occ_rank, by(occ_category)
gen rank = -wage_2005
sort rank
replace rank = _n

* Write LaTeX table manually
file open table using "$output/Tables/table1_manual_formal.tex", write replace

file write table "\begin{table}[htbp]" _n
file write table "\centering" _n  
file write table "\caption{Levels and Changes in Formal Employment Share and Mean Real Log Hourly Wages by Major Occupation Groups, 2005-2025: Occupations Ordered by Average Wage Level}" _n
file write table "\label{tab:employment_wages_formal}" _n
file write table "\resizebox{\textwidth}{!}{%" _n
file write table "\begin{threeparttable}" _n
file write table "\begin{tabular}{@{}lccccccc@{}}" _n
file write table "\toprule" _n
file write table "& \multicolumn{5}{c}{Level} & \multicolumn{2}{c}{Percent growth/} \\" _n
file write table "& & & & & & \multicolumn{2}{c}{(growth per 10 yrs)} \\" _n
file write table "\cmidrule(r){2-6} \cmidrule(l){7-8}" _n
file write table "& 2005 & 2010 & 2015 & 2019 & 2022 & 2005--2019 & 2022--2025 \\" _n
file write table "\midrule" _n
file write table "\textit{Panel A. Share of employment (\%)} & & & & & & & \\" _n
file write table "\addlinespace[0.1cm]" _n

* Loop through occupations to write employment data
levelsof rank, local(ranks)
foreach r of local ranks {
	preserve
	keep if rank == `r'
	local occ_name = occ_category[1]
	
	* Get values for each year
	qui sum emp_share_2005
	local emp05 = string(r(mean), "%6.2f")
	qui sum emp_share_2010 
	local emp10 = string(r(mean), "%6.2f")
	qui sum emp_share_2015
	local emp15 = string(r(mean), "%6.2f")
	qui sum emp_share_2019
	local emp19 = string(r(mean), "%6.2f")
	qui sum emp_share_2022
	local emp22 = string(r(mean), "%6.2f")
	
	* Get growth rates
	qui sum emp_growth_05_19 if !missing(emp_growth_05_19)
	local growth_early = string(r(mean), "%6.2f")
	qui sum emp_growth_22_25 if !missing(emp_growth_22_25)  
	local growth_late = string(r(mean), "%6.2f")
	
	file write table "`occ_name' & `emp05' & `emp10' & `emp15' & `emp19' & `emp22' & `growth_early' & `growth_late' \\" _n
	file write table "\addlinespace[0.1cm]" _n
	
	restore
}

file write table "\addlinespace[0.3cm]" _n
file write table "\textit{Panel B. Mean log hourly wage (2005)} & & & & & & & \\" _n
file write table "\addlinespace[0.1cm]" _n

* Loop through occupations to write wage data
foreach r of local ranks {
	preserve  
	keep if rank == `r'
	local occ_name = occ_category[1]
	
	* Get wage values for each year
	qui sum wage_2005
	local wage05 = string(r(mean), "%6.2f")
	qui sum wage_2010
	local wage10 = string(r(mean), "%6.2f") 
	qui sum wage_2015
	local wage15 = string(r(mean), "%6.2f")
	qui sum wage_2019
	local wage19 = string(r(mean), "%6.2f")
	qui sum wage_2022
	local wage22 = string(r(mean), "%6.2f")
	
	* Get wage growth rates
	qui sum wage_growth_05_19 if !missing(wage_growth_05_19)
	local wgrowth_early = string(r(mean), "%6.2f")
	qui sum wage_growth_22_25 if !missing(wage_growth_22_25)
	local wgrowth_late = string(r(mean), "%6.2f") 
	
	file write table "`occ_name' & `wage05' & `wage10' & `wage15' & `wage19' & `wage22' & `wgrowth_early' & `wgrowth_late' \\" _n
	file write table "\addlinespace[0.1cm]" _n
	
	restore
}

file write table "\bottomrule" _n
file write table "\end{tabular}" _n
file write table "\begin{tablenotes}" _n
file write table "\footnotesize"_n
file write table "\item Note: Sample includes persons who were age 18--64 and working in the prior year. Hourly wages are defined as yearly wage and salary income divided by the product of weeks worked times usual weekly hours. Employment share is defined as share in total employment. All calculations use labor supply weights. Managers* is Managers/professionales/technicians/finance/public safety. Transportation* is Transportation/construction/mechanics/mining/farm" _n
file write table "\end{tablenotes}" _n
file write table "\begin{tablenotes}[Source]" _n
file write table "\footnotesize"_n
file write table "\item Source: ENOE survey data for 2005, 2010, 2015, 2019, and 2022; projections for 2025." _n
file write table "\end{tablenotes}" _n
file write table "\end{threeparttable}}" _n
file write table "\end{table}" _n

file close table

display "LaTeX tables created successfully!"
display "Files generated:"
display "  - table1_manual_formal.tex (manual file writing with full control)"


*-----------------------------------------------------------------------
**#  TABLE 2: Log Mean Wage and Employment Shares Informal
*-----------------------------------------------------------------------

clear all
use "$processed_data/enoe_annual_soc_tasks.dta", clear
drop if occ_category == ""
* Merge wdi inflation data  
merge m:1 yr using "$raw_data//wb_wdi_variables.dta",  keep(match) nogen

* Create table variables
foreach t in formal informal {
	bys occ_category yr: egen Lcat_`t' = total(labor_`t')
	bys yr: egen L`t' = total(labor_`t')
	gen employment_share_`t' = (Lcat_`t'/L`t')*100
	gen lnw_`t' = ln((net_wage_`t'/cpi_2005)/(20*8)) if net_wage_`t' > 0
	bys occ_category yr: egen avg_wage_`t' = wtmean(lnw_`t'), weight(labor_`t')

}

* Keep relevant years, make category shorter for table
keep if inlist(yr, 2005, 2010, 2015, 2019, 2022, 2025)
replace occ_category = "Transportation*" if occ_category == "Transportation/construction/mechanics/mining/farm"
replace occ_category = "Managers*" if occ_category == "Managers/ professionals / technicians / finance/ public safety"
* Create occupation ranking based on average wage levels across all years
bys occ_category: egen avg_wage_overall = mean(lnw_formal)
egen occ_rank = rank(-avg_wage_overall), unique
sort occ_rank yr


* Collapse to relevant variables
collapse (mean) employment_share* lnw_* (first) occ_rank, by(occ_category yr )
sort occ_rank yr

* Calculate growth rates 
local t = "informal"
sort occ_category yr
by occ_category: gen emp_share_2005 = employment_share_`t' if yr == 2005
by occ_category: gen emp_share_2010 = employment_share_`t' if yr == 2010
by occ_category: gen emp_share_2015 = employment_share_`t' if yr == 2015
by occ_category: gen emp_share_2019 = employment_share_`t' if yr == 2019
by occ_category: gen emp_share_2022 = employment_share_`t' if yr == 2022
by occ_category: gen emp_share_2025 = employment_share_`t' if yr == 2025

by occ_category: gen wage_2005 = lnw_`t' if yr == 2005
by occ_category: gen wage_2010 = lnw_`t' if yr == 2010
by occ_category: gen wage_2015 = lnw_`t' if yr == 2015
by occ_category: gen wage_2019 = lnw_`t' if yr == 2019
by occ_category: gen wage_2022 = lnw_`t' if yr == 2022
by occ_category: gen wage_2025 = lnw_`t' if yr == 2025


by occ_category: egen emp_2005 = max(emp_share_2005)
by occ_category: egen emp_2019 = max(emp_share_2019)
by occ_category: egen emp_2022 = max(emp_share_2022)
by occ_category: egen emp_2025 = max(emp_share_2025)
by occ_category: egen w_2005 = max(wage_2005)
by occ_category: egen w_2019 = max(wage_2019)
by occ_category: egen w_2022 = max(wage_2022)
by occ_category: egen w_2025 = max(wage_2025)

* Growth calculations
gen emp_growth_05_19 = ((emp_2019/emp_2005)-1) * 100
gen emp_growth_22_25 = ((emp_2025/emp_2022)-1) * 100
gen wage_growth_05_19 = ((w_2019/w_2005)-1) * 100  
gen wage_growth_22_25 = ((w_2025/w_2022)-1) * 100

collapse(mean) emp_share_2005-wage_growth_22_25 occ_rank, by(occ_category)
gen rank = -wage_2005
sort rank
replace rank = _n

* Write LaTeX table manually
file open table using "$output/Tables/table1_manual_informal.tex", write replace

file write table "\begin{table}[htbp]" _n
file write table "\centering" _n  
file write table "\caption{Levels and Changes in Informal Employment Share and Mean Real Log Hourly Wages by Major Occupation Groups, 2005-2025: Occupations Ordered by Average Wage Level}" _n
file write table "\label{tab:employment_wages_informal}" _n
file write table "\resizebox{\textwidth}{!}{%" _n
file write table "\begin{threeparttable}" _n
file write table "\begin{tabular}{@{}lccccccc@{}}" _n
file write table "\toprule" _n
file write table "& \multicolumn{5}{c}{Level} & \multicolumn{2}{c}{Percent growth/} \\" _n
file write table "& & & & & & \multicolumn{2}{c}{(growth per 10 yrs)} \\" _n
file write table "\cmidrule(r){2-6} \cmidrule(l){7-8}" _n
file write table "& 2005 & 2010 & 2015 & 2019 & 2022 & 2005--2019 & 2022--2025 \\" _n
file write table "\midrule" _n
file write table "\textit{Panel A. Share of employment (\%)} & & & & & & & \\" _n
file write table "\addlinespace[0.1cm]" _n

* Loop through occupations to write employment data
levelsof rank, local(ranks)
foreach r of local ranks {
	preserve
	keep if rank == `r'
	local occ_name = occ_category[1]
	
	* Get values for each year
	qui sum emp_share_2005
	local emp05 = string(r(mean), "%6.2f")
	qui sum emp_share_2010 
	local emp10 = string(r(mean), "%6.2f")
	qui sum emp_share_2015
	local emp15 = string(r(mean), "%6.2f")
	qui sum emp_share_2019
	local emp19 = string(r(mean), "%6.2f")
	qui sum emp_share_2022
	local emp22 = string(r(mean), "%6.2f")
	
	* Get growth rates
	qui sum emp_growth_05_19 if !missing(emp_growth_05_19)
	local growth_early = string(r(mean), "%6.2f")
	qui sum emp_growth_22_25 if !missing(emp_growth_22_25)  
	local growth_late = string(r(mean), "%6.2f")
	
	file write table "`occ_name' & `emp05' & `emp10' & `emp15' & `emp19' & `emp22' & `growth_early' & `growth_late' \\" _n
	file write table "\addlinespace[0.1cm]" _n
	
	restore
}

file write table "\addlinespace[0.3cm]" _n
file write table "\textit{Panel B. Mean log hourly wage (2005)} & & & & & & & \\" _n
file write table "\addlinespace[0.1cm]" _n

* Loop through occupations to write wage data
foreach r of local ranks {
	preserve  
	keep if rank == `r'
	local occ_name = occ_category[1]
	
	* Get wage values for each year
	qui sum wage_2005
	local wage05 = string(r(mean), "%6.2f")
	qui sum wage_2010
	local wage10 = string(r(mean), "%6.2f") 
	qui sum wage_2015
	local wage15 = string(r(mean), "%6.2f")
	qui sum wage_2019
	local wage19 = string(r(mean), "%6.2f")
	qui sum wage_2022
	local wage22 = string(r(mean), "%6.2f")
	
	* Get wage growth rates
	qui sum wage_growth_05_19 if !missing(wage_growth_05_19)
	local wgrowth_early = string(r(mean), "%6.2f")
	qui sum wage_growth_22_25 if !missing(wage_growth_22_25)
	local wgrowth_late = string(r(mean), "%6.2f") 
	
	file write table "`occ_name' & `wage05' & `wage10' & `wage15' & `wage19' & `wage22' & `wgrowth_early' & `wgrowth_late' \\" _n
	file write table "\addlinespace[0.1cm]" _n
	
	restore
}

file write table "\bottomrule" _n
file write table "\end{tabular}" _n
file write table "\begin{tablenotes}" _n
file write table "\footnotesize"_n
file write table "\item Note: Sample includes persons who were age 18--64 and working in the prior year. Hourly wages are defined as yearly wage and salary income divided by the product of weeks worked times usual weekly hours. Employment share is defined as share in total employment. All calculations use labor supply weights. Managers* is Managers/professionales/technicians/finance/public safety. Transportation* is Transportation/construction/mechanics/mining/farm" _n
file write table "\end{tablenotes}" _n
file write table "\begin{tablenotes}[Source]" _n
file write table "\footnotesize"_n
file write table "\item Source: ENOE survey data for 2005, 2010, 2015, 2019, and 2022; projections for 2025." _n
file write table "\end{tablenotes}" _n
file write table "\end{threeparttable}}" _n
file write table "\end{table}" _n

file close table

display "LaTeX tables created successfully!"
display "Files generated:"
display "  - table1_manual_informal.tex (manual file writing with full control)"

*-----------------------------------------------------------------------
**#  TABLE 3: Task Intensity by Major Occupation Groups and Emp Type
*-----------------------------------------------------------------------
clear all
use "$processed_data/enoe_annual_soc_tasks.dta", clear

* Keep relevant year
keep if yr == 2005			

* Create weighted average of RTI, and each task, then tag if higher or lower
* Construct RTI measure (AD 2013 page 1570)
gen rti = ln(task_routine) - ln(task_manual) - ln(task_abstract)
drop if rti == .

* Construct RTI above 66th percentile measure, first consider all occupations, equal weight
* Compute mean RTI, manual, routine and abstract measures

* Construct weighted mean for each sample, switch `t' or total to obtain diff mean
foreach t in formal informal {
	foreach X of varlist(rti task_routine task_manual task_abstract) {
		egen `X'_mean_`t' = wtmean(`X')
		bys occ_category: egen occ_`X'_mean_`t' = wtmean(`X'), weight(labor_`t')
	}
}

* Collapse by occupational group
collapse(mean) rti_mean_formal-occ_task_abstract_mean_informal , by(occ_category)


* Write Latex table
file open table using "$output/Tables/table_task_intensity.tex", write replace
file write table "\begin{table}[htbp]" _n
file write table "\centering" _n  
file write table "\caption{Task Intensity of Major Occupation Groups by Employment Type}" _n
file write table "\label{tab:task_intensity}" _n
file write table "\resizebox{\textwidth}{!}{%" _n
file write table "\begin{threeparttable}" _n
file write table "\begin{tabular}{@{}lcccc}" _n
file write table "\toprule" _n
file write table " & \makecell{\textit{RTI} \\ index} & \makecell{Abstract \\ tasks} & \makecell{Routine \\ tasks} & \makecell{Manual \\ tasks} \\" _n 
file write table "\midrule" _n
file write table "\textit{Panel A. Formal Employment} & & & & \\" _n
file write table "\addlinespace[0.1cm]" _n

* Loop through occupations to write employment data
gen rank = _n
levelsof rank, local(ranks)
foreach r of local ranks {
	preserve
	keep if rank == `r'
	
	// Get the name of the occupation category
	local occ_name = occ_category[1]

	// --- 1. Get the numerical values for the three main tasks ---
	local val_abs  = occ_task_abstract_mean_formal[1]
	local val_rout = occ_task_routine_mean_formal[1]
	local val_manu = occ_task_manual_mean_formal[1]

	// --- 2. Create the display strings ("+" or "-") for all four columns ---
	local rti_disp  = cond(occ_rti_mean_formal > rti_mean_formal, "+", "-")
	local abs_disp  = cond(`val_abs' > task_abstract_mean_formal, "+", "-")
	local rout_disp = cond(`val_rout' > task_routine_mean_formal, "+", "-")
	local manu_disp = cond(`val_manu' > task_manual_mean_formal, "+", "-")
	
	// --- 3. Find the maximum value among the three tasks ---
	local max_task = max(`val_abs', `val_rout', `val_manu')
	
	// --- 4. Conditionally add the cell color to the correct display string ---
	if (`val_abs' == `max_task') {
		local abs_disp "\cellcolor{gray!30} `abs_disp'"
	}
	if (`val_rout' == `max_task') {
		local rout_disp "\cellcolor{gray!30} `rout_disp'"
	}
	if (`val_manu' == `max_task') {
		local manu_disp "\cellcolor{gray!30} `manu_disp'"
	}
	// --- 5. Write the final, formatted row to the file ---
	file write table "`occ_name' & `rti_disp' & `abs_disp' & `rout_disp' & `manu_disp' \\" _n
	file write table "\addlinespace[0.1cm]" _n
	
	restore
}
file write table "\addlinespace[0.3cm]" _n
file write table "\textit{Panel B. Informal Employment} & & & & \\" _n
file write table "\addlinespace[0.1cm]" _n

* Now loop through informal occupations
levelsof rank, local(ranks)
foreach r of local ranks {
	preserve
	keep if rank == `r'
	
	// Get the name of the occupation category
	local occ_name = occ_category[1]

	// --- 1. Get the numerical values for the three main tasks ---
	local val_abs  = occ_task_abstract_mean_informal[1]
	local val_rout = occ_task_routine_mean_informal[1]
	local val_manu = occ_task_manual_mean_informal[1]

	// --- 2. Create the display strings ("+" or "-") for all four columns ---
	local rti_disp  = cond(occ_rti_mean_formal > rti_mean_informal, "+", "-")
	local abs_disp  = cond(`val_abs' > task_abstract_mean_informal, "+", "-")
	local rout_disp = cond(`val_rout' > task_routine_mean_informal, "+", "-")
	local manu_disp = cond(`val_manu' > task_manual_mean_informal, "+", "-")
	
	// --- 3. Find the maximum value among the three tasks ---
	local max_task = max(`val_abs', `val_rout', `val_manu')
	local max_task = max(`val_abs', `val_rout', `val_manu')
	
	// --- 4. Conditionally add the cell color to the correct display string ---
	if (`val_abs' == `max_task') {
		local abs_disp "\cellcolor{gray!30} `abs_disp'"
	}
	if (`val_rout' == `max_task') {
		local rout_disp "\cellcolor{gray!30} `rout_disp'"
	}
	if (`val_manu' == `max_task') {
		local manu_disp "\cellcolor{gray!30} `manu_disp'"
	}
	// --- 5. Write the final, formatted row to the file ---
	file write table "`occ_name' & `rti_disp' & `abs_disp' & `rout_disp' & `manu_disp' \\" _n
	file write table "\addlinespace[0.1cm]" _n
	
	restore
}

file write table "\bottomrule" _n
file write table "\end{tabular}" _n
file write table "\begin{tablenotes}" _n
file write table "\footnotesize"_n
file write table "\item Note: The table indicates whether the average task value in occupation group is larger (+) or smaller (--) than the task average across all occupations. Shaded fields indicate the largest task value for each occupation group " _n
file write table "\end{tablenotes}" _n
file write table "\begin{tablenotes}[Source]" _n
file write table "\footnotesize"_n
file write table "\item Source: Author's elaboration using data from ENOE." _n
file write table "\end{tablenotes}" _n
file write table "\end{threeparttable}}" _n
file write table "\end{table}" _n

file close table

display "LaTeX tables created successfully!"



*-----------------------------------------------------------------------
**#  TABLE 4: AI Exposure by Occupational Group and Employment Type
*-----------------------------------------------------------------------
clear all
use "$processed_data/enoe_annual_soc_tasks.dta", clear

* Keep relevant year, any is fine, there is no change
keep if yr == 2022			

* Construct weighted mean for each sample
foreach t in formal informal {
	foreach X of varlist(msml alpha) {
		egen `X'_mean_`t' = wtmean(`X'), weight(labor_`t')
		bys occ_category: egen occ_`X'_mean_`t' = wtmean(`X'), weight(labor_`t')
	}
}
drop if occ_category == ""

* Collapse by occupational group
collapse(mean) msml_mean_formal-occ_alpha_mean_informal , by(occ_category)


* Write Latex table
file open table using "$output/Tables/table_smlai_intensity.tex", write replace
file write table "\begin{table}[htbp]" _n
file write table "\centering" _n  
file write table "\caption{SML/AI Intensity of Major Occupation Groups by Employment Type}" _n
file write table "\label{tab:ai_intensity}" _n
file write table "\resizebox{0.8\textwidth}{!}{%" _n
file write table "\begin{threeparttable}" _n
file write table "\begin{tabular}{@{}lcc}" _n
file write table "\toprule" _n
file write table " & \makecell{\textit{SML} \\ index} & \makecell{AI \\ Index}  \\" _n 
file write table "\midrule" _n
file write table "\textit{Panel A. Formal Employment} & & \\" _n
file write table "\addlinespace[0.1cm]" _n

* Loop through occupations to write employment data
gen rank = _n
levelsof rank, local(ranks)
foreach r of local ranks {
	preserve
	keep if rank == `r'
	
	// Get the name of the occupation category
	local occ_name = occ_category[1]

	// --- 1. Get the numerical values for the three main tasks ---
	local val_sml  = occ_msml_mean_formal[1]
	local val_ai = occ_alpha_mean_formal[1]

	// --- 2. Create the display strings ("+" or "-") for all four columns ---
	local sml_disp  = cond(`val_sml' > msml_mean_formal, "+", "-")
	local ai_disp  = cond(`val_ai' > alpha_mean_formal, "+", "-")

	// --- 3. Write the final, formatted row to the file ---
	file write table "`occ_name' & `sml_disp' & `ai_disp'  \\" _n
	file write table "\addlinespace[0.1cm]" _n
	
	restore
}
file write table "\addlinespace[0.3cm]" _n
file write table "\textit{Panel B. Informal Employment} & & \\" _n
file write table "\addlinespace[0.1cm]" _n

* Now loop through informal occupations
levelsof rank, local(ranks)
foreach r of local ranks {
	preserve
	keep if rank == `r'
	
	// Get the name of the occupation category
	local occ_name = occ_category[1]

	// --- 1. Get the numerical values for the three main tasks ---
	local val_sml  = occ_msml_mean_informal[1]
	local val_ai = occ_alpha_mean_informal[1]

	// --- 2. Create the display strings ("+" or "-") for all four columns ---
	local sml_disp  = cond(`val_sml' > msml_mean_informal, "+", "-")
	local ai_disp  = cond(`val_ai' > alpha_mean_informal, "+", "-")

	// --- 3. Write the final, formatted row to the file ---
	file write table "`occ_name' & `sml_disp' & `ai_disp'  \\" _n
	file write table "\addlinespace[0.1cm]" _n
	
	restore
}

file write table "\bottomrule" _n
file write table "\end{tabular}" _n
file write table "\begin{tablenotes}" _n
file write table "\footnotesize"_n
file write table "\item Note: The table indicates whether the average index value in occupation group is larger (+) or smaller (−) than the index value across all occupations." _n
file write table "\end{tablenotes}" _n
file write table "\begin{tablenotes}[Source]" _n
file write table "\footnotesize"_n
file write table "\item Source: Author's elaboration using data from ENOE." _n
file write table "\end{tablenotes}" _n
file write table "\end{threeparttable}}" _n
file write table "\end{table}" _n

file close table

display "LaTeX tables created successfully!"

*-----------------------------------------------------------------------
**#  TABLE A1: Top 5 Occupations by Percentile Group and type of labor
*-----------------------------------------------------------------------

* Need to compute top 5 occupations of each quantile
* 5-20 , 20-40, 40-60, 60-80, 80-95
clear all

foreach year in 2005 2022 {
			
		* Collect results across total / informal / formal
		tempfile top5
		save `top5', emptyok replace

		
	foreach t in total informal formal {


		use "$processed_data/enoe_annual_soc_tasks.dta", clear
		keep if yr == `year'

		* keep obs with both wage and labor for this class
		drop if missing(net_wage_`t') | missing(labor_`t')

		* if no employment in this class, skip
		quietly summarize labor_`t'
		if r(sum) == 0 continue

		local v "net_wage"
		local num_pctiles = 100

		* Employment weights (class-specific)
		bys yr: egen double L = total(labor_`t')
		gen double weight = labor_`t' / L
		drop if weight<=0 | missing(weight)

		* Rank by class-specific wage
		gen double logwage = ln(`v'_`t')
		sort logwage soc  // soc as tiebreaker

		* Cumulative employment share
		gen double cum_share = sum(weight)

		* Map each obs to the [0,100] axis
		gen double left100  = `num_pctiles' * (cum_share - weight)
		gen double right100 = `num_pctiles' * cum_share
		gen double margwt   = right100 - left100
		gen double segwt    = margwt/`num_pctiles'
		drop if segwt <= 0 | missing(segwt)

		* psh_p: share of each occupation lying in percentile p
		forvalues p = 1/`num_pctiles' {
			gen double p`p' = 0
			replace p`p' = right100 - (`p' - 1) if right100 > (`p' - 1) & right100 <= `p'   & left100 < (`p' - 1)
			replace p`p' = `p' - left100         if left100  >= (`p' - 1) & left100  <  `p'  & right100 >  `p'
			replace p`p' = 1                     if left100  <  (`p' - 1) & right100 >= `p'
			replace p`p' = right100 - left100    if left100  >= (`p' - 1) & right100 <= `p'
			gen double psh`p' = p`p' / margwt
			drop p`p'
		}

		* ----- Build percentile groups -----
		local glabs   "p5_20 p20_40 p40_60 p60_80 p80_95"
		local gstarts "5     20     40     60     80"
		local gstops  "20    40     60     80     95"

		forvalues k = 1/5 {
			local Lb : word `k' of `glabs'
			local S  : word `k' of `gstarts'
			local E  : word `k' of `gstops'
			gen double w_`Lb' = 0
			forvalues p = `S'/`=`E'-1' {
				quietly replace w_`Lb' = w_`Lb' + segwt * psh`p'
			}
		}

		* Tag class and (OPTIONAL) collapse in case SOC repeats on multiple rows
		gen str8 class = "`t'"
		collapse (sum) w_*, by(soc SOCTitle class)

		* Long layout, rank, keep top 5 per class x group
		reshape long w_, i(soc SOCTitle class) j(group) string
		gsort class group -w_ soc
		by class group: gen rank = _n
		keep if rank <= 5
		* Stash partial result
		append using `top5'
		save `top5', replace
	}

	* ------- Final touches: within-group shares and display -------
	use `top5', clear

	bys class group: egen double group_total = total(w_)
	gen double share_in_group = w_ / group_total 
	format share_in_group %6.2f

	order class group rank soc SOCTitle w_ share_in_group
	list, sepby(class group) noobs abbreviate(24)

	* Total top 5s are weird, which motivates the separation of formal and informal

	* Use your saved results
	use `top5', clear
	keep class group rank SOCTitle

	* ---- Make readable percentile-group labels ----
	gen str8 group_lbl = group
	replace group_lbl = "5--20"  if group == "p5_20"
	replace group_lbl = "20--40" if group == "p20_40"
	replace group_lbl = "40--60" if group == "p40_60"
	replace group_lbl = "60--80" if group == "p60_80"
	replace group_lbl = "80--95" if group == "p80_95"

	* For ordering the rows in the table
	gen group_order = .
	replace group_order = 1 if group == "p5_20"
	replace group_order = 2 if group == "p20_40"
	replace group_order = 3 if group == "p40_60"
	replace group_order = 4 if group == "p60_80"
	replace group_order = 5 if group == "p80_95"

	* ---- Reshape to wide so we have one row per (group, rank) ----
	* (produces SOCTitletotal, SOCTitleformal, SOCTitleinformal)
	* Clean and validate 'class'
	replace class = strtrim(strlower(class))
	drop if missing(class)                         // drop empty-string classes
	keep if inlist(class,"total","formal","informal")

	assert !missing(class)
	assert inlist(class,"total","formal","informal")
	reshape wide SOCTitle, i(group group_lbl group_order rank) j(class) string

	* Keep table order: by group (desired order) and rank
	sort group_order rank

	* ---- Escape LaTeX special characters in occupation titles ----
	foreach v in SOCTitletotal SOCTitleformal SOCTitleinformal {
		replace `v' = subinstr(`v',"&","\&",.)
		replace `v' = subinstr(`v',"_","\_",.)
		replace `v' = subinstr(`v',"%","\%",.)
		replace `v' = subinstr(`v',"$","\$",.)
		replace `v' = subinstr(`v',"{","\{",.)
		replace `v' = subinstr(`v',"}","\}",.)
	}

	* Export to Excel and format each occupation
	export excel using "$output/Tables/occupations_by_percentile_`year'.xls", firstrow(var) replace
}









