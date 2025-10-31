/* =====================================================

	Regression Analysis with Growth Statistics
	Gabriel Marin, Anahuac University
	gabriel.marinmu@anahuac.mx

	Note: This do-file computes regressions and regression figures 
	for the paper, including mean and SD of growth rates
====================================================== */

clear all
set more off

* Setup working directory (change accordingly)
cd "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data"

global raw_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Raw_Data"

global processed_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Processed_Data"

global do_files "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Do-Files"

global output "/Users/gmm/Dropbox/Apps/Overleaf/Labor Markets and Automation in the Open Economy"

* ---------------------------------------------------------------------------
**# Regression: RTI and Employment Share (Formal Employment)
* ---------------------------------------------------------------------------
* Import regression database
use "$processed_data/reg_data.dta", clear

* Open LaTeX file for writing
file open regtable using "$output/Tables/reg_rti_formal.tex", write replace

* Write table header
file write regtable "\begin{table}[htbp]" _n
file write regtable "\centering" _n
file write regtable "\caption{OLS Estimates of Routine Employment Share and Growth of Formal Employment within Municipalities (2005-2025)}" _n
file write regtable "\label{tab:regression_results}" _n
file write regtable "\resizebox{0.8\textwidth}{!}{%" _n
file write regtable "\begin{threeparttable}" _n
file write regtable "\begin{tabular}{@{}lcccc@{}}" _n
file write regtable "\toprule" _n
file write regtable "& \multicolumn{4}{c}{Dependent Variable: Change in Employment Share} \\" _n
file write regtable "\cmidrule(l){2-5}" _n
file write regtable "& 2005-2010 & 2010-2015 & 2015-2019 & 2022-2025 \\" _n
file write regtable "\midrule" _n

* Initialize matrices to store ALL results (2 occupations x 4 time periods)
matrix coef_results = J(2, 4, .)
matrix se_results = J(2, 4, .)
matrix r2_results = J(2, 4, .)
matrix mean_growth = J(2, 4, .)
matrix sd_growth = J(2, 4, .)

* First run all regressions and store results
* Panel A: Service Occupations
preserve
keep if occ_category == "Service occupations"

local start_years "2005 2010 2015 2022"
local end_years "2010 2015 2019 2025"

forvalues i = 1/4 {
    local start_year : word `i' of `start_years'
    local end_year : word `i' of `end_years'
    local div = cond(`i' == 1, 5, cond(`i' == 2, 5, cond(`i' == 3, 4, 3)))
    
    gen emp_share_dif = (share_formal`end_year' - share_formal`start_year')/`div'
	gen tot_share = share_formal`end_year' - share_formal`start_year'
    rename rti_share_formal`start_year' rti_share_start_period
    
    * Calculate mean and SD of growth (weighted by population share)
    qui sum tot_share [aweight = popshare_formal`start_year'] if !missing(tot_share)
    matrix mean_growth[1,`i'] = r(mean)/`div'
    matrix sd_growth[1,`i'] = r(sd)/`div'
    
    capture areg emp_share_dif rti_share_start_period [pw = popshare_formal`start_year'], absorb(state) cluster(state)
    
    if _rc == 0 {
        matrix coef_results[1,`i'] = _b[rti_share_start_period]
        matrix se_results[1,`i'] = _se[rti_share_start_period]
        matrix r2_results[1,`i'] = e(r2)
    }
    
    rename rti_share_start_period rti_share_formal`start_year'
    drop emp_share_dif tot_share
}
restore

* Panel B: Transportation Occupations
preserve
keep if occ_category == "Transportation/construction/mechanics/mining/farm"

forvalues i = 1/4 {
    local start_year : word `i' of `start_years'
    local end_year : word `i' of `end_years'
    local div = cond(`i' == 1, 5, cond(`i' == 2, 5, cond(`i' == 3, 4, 3)))
    
    gen emp_share_dif = (share_formal`end_year' - share_formal`start_year')/`div'
	gen tot_share = share_formal`end_year' - share_formal`start_year'
    rename rti_share_formal`start_year' rti_share_start_period
    
    * Calculate mean and SD of growth (weighted by population share)
    qui sum tot_share [aweight = popshare_formal`start_year'] if !missing(tot_share)
    matrix mean_growth[2,`i'] = r(mean)/`div'
    matrix sd_growth[2,`i'] = r(sd)/`div'
    
    capture areg emp_share_dif rti_share_start_period [pw = popshare_formal`start_year'], absorb(state) cluster(state)
    
    if _rc == 0 {
        matrix coef_results[2,`i'] = _b[rti_share_start_period]
        matrix se_results[2,`i'] = _se[rti_share_start_period]
        matrix r2_results[2,`i'] = e(r2)
    }
    
    rename rti_share_start_period rti_share_formal`start_year'
    drop emp_share_dif tot_share
}
restore

* Now write the table using stored matrix results
* Panel A: Service Occupations
file write regtable "\textit{Panel A. Service Occupations} & & & & \\" _n
file write regtable "\addlinespace[0.1cm]" _n

local coef_row_a ""
local se_row_a ""
local r2_row_a ""
local growth_row_a ""

forvalues i = 1/4 {
    local coeff = coef_results[1,`i']
    local se = se_results[1,`i']
    local r2_val = r2_results[1,`i']
    local mean_gr = mean_growth[1,`i']
    local sd_gr = sd_growth[1,`i']
    
    if !missing(`coeff') {
        local coeff_str = string(`coeff', "%6.3f")
        local se_str = string(`se', "%6.3f")
        local r2_str = string(`r2_val', "%6.3f")
        
        * Add significance stars
        local t_stat = `coeff'/`se'
        if abs(`t_stat') > 2.576 {
            local coeff_str "`coeff_str'***"
        }
        else if abs(`t_stat') > 1.96 {
            local coeff_str "`coeff_str'**"
        }
        else if abs(`t_stat') > 1.645 {
            local coeff_str "`coeff_str'*"
        }
    }
    else {
        local coeff_str "---"
        local se_str "---"
        local r2_str "---"
    }
    
    * Format growth statistics
    if !missing(`mean_gr') & !missing(`sd_gr') {
        local mean_str = string(`mean_gr', "%6.3f")
        local sd_str = string(`sd_gr', "%6.3f")
        local growth_str "`mean_str' (`sd_str')"
    }
    else {
        local growth_str "--- (---)"
    }
    
    if `i' == 1 {
        local coef_row_a "`coeff_str'"
        local se_row_a "(`se_str')"
        local r2_row_a "`r2_str'"
        local growth_row_a "`growth_str'"
    }
    else {
        local coef_row_a "`coef_row_a' & `coeff_str'"
        local se_row_a "`se_row_a' & (`se_str')"
        local r2_row_a "`r2_row_a' & `r2_str'"
        local growth_row_a "`growth_row_a' & `growth_str'"
    }
}

file write regtable "Starting Routine Share & `coef_row_a' \\" _n
file write regtable "& `se_row_a' \\" _n
file write regtable "\addlinespace[0.1cm]" _n
file write regtable "R-squared & `r2_row_a' \\" _n
file write regtable "Mean Growth (SD) & `growth_row_a' \\" _n
file write regtable "\addlinespace[0.3cm]" _n

* Panel B: Transportation Occupations
file write regtable "\textit{Panel B. Transportation*} & & & & \\" _n
file write regtable "\addlinespace[0.1cm]" _n

local coef_row_b ""
local se_row_b ""
local r2_row_b ""
local growth_row_b ""

forvalues i = 1/4 {
    local coeff = coef_results[2,`i']
    local se = se_results[2,`i']
    local r2_val = r2_results[2,`i']
    local mean_gr = mean_growth[2,`i']
    local sd_gr = sd_growth[2,`i']
    
    if !missing(`coeff') {
        local coeff_str = string(`coeff', "%6.3f")
        local se_str = string(`se', "%6.3f")
        local r2_str = string(`r2_val', "%6.3f")
        
        * Add significance stars
        local t_stat = `coeff'/`se'
        if abs(`t_stat') > 2.576 {
            local coeff_str "`coeff_str'***"
        }
        else if abs(`t_stat') > 1.96 {
            local coeff_str "`coeff_str'**"
        }
        else if abs(`t_stat') > 1.645 {
            local coeff_str "`coeff_str'*"
        }
    }
    else {
        local coeff_str "---"
        local se_str "---"
        local r2_str "---"
    }
    
    * Format growth statistics
    if !missing(`mean_gr') & !missing(`sd_gr') {
        local mean_str = string(`mean_gr', "%6.3f")
        local sd_str = string(`sd_gr', "%6.3f")
        local growth_str "`mean_str' (`sd_str')"
    }
    else {
        local growth_str "--- (---)"
    }
    
    if `i' == 1 {
        local coef_row_b "`coeff_str'"
        local se_row_b "(`se_str')"
        local r2_row_b "`r2_str'"
        local growth_row_b "`growth_str'"
    }
    else {
        local coef_row_b "`coef_row_b' & `coeff_str'"
        local se_row_b "`se_row_b' & (`se_str')"
        local r2_row_b "`r2_row_b' & `r2_str'"
        local growth_row_b "`growth_row_b' & `growth_str'"
    }
}

file write regtable "Starting Routine Share & `coef_row_b' \\" _n
file write regtable "& `se_row_b' \\" _n
file write regtable "\addlinespace[0.1cm]" _n
file write regtable "R-squared & `r2_row_b' \\" _n
file write regtable "Mean Growth (SD) & `growth_row_b' \\" _n

* Write table footer
file write regtable "\bottomrule" _n
file write regtable "\end{tabular}" _n
file write regtable "\begin{tablenotes}" _n
file write regtable "\footnotesize" _n
file write regtable "\item Note: Each column represents a different time period. Regressions include state fixed effects and are weighted by population share in the starting year of each period. Standard errors are clustered at the state level. Mean Growth (SD) shows the weighted mean and standard deviation of employment share changes for each period. *, **, *** denote significance at the 10\%, 5\%, and 1\% levels, respectively. Transportation* refers to Transportation/construction/mechanics/mining/farm occupations." _n
file write regtable "\end{tablenotes}" _n
file write regtable "\begin{tablenotes}[Source]" _n
file write regtable "\footnotesize" _n
file write regtable "\item Source: ENOE survey data for 2005, 2010, 2015, 2019, and 2022; projections for 2025." _n
file write regtable "\end{tablenotes}" _n
file write regtable "\end{threeparttable}}" _n
file write regtable "\end{table}" _n

* Close file
file close regtable
display "Manual regression LaTeX table with growth statistics created successfully!"





* ---------------------------------------------------------------------------
**# Regression: RTI and Employment Share (Informal Employment)
* ---------------------------------------------------------------------------
clear all
* Import regression database
use "$processed_data/reg_data.dta", clear

* Open LaTeX file for writing
file open regtable using "$output/Tables/reg_rti_informal.tex", write replace

* Write table header
file write regtable "\begin{table}[htbp]" _n
file write regtable "\centering" _n
file write regtable "\caption{OLS Estimates of Routine Employment Share and Growth of Informal Employment within Municipalities (2005-2025)}" _n
file write regtable "\label{tab:regression_results}" _n
file write regtable "\resizebox{0.8\textwidth}{!}{%" _n
file write regtable "\begin{threeparttable}" _n
file write regtable "\begin{tabular}{@{}lcccc@{}}" _n
file write regtable "\toprule" _n
file write regtable "& \multicolumn{4}{c}{Dependent Variable: Change in Employment Share} \\" _n
file write regtable "\cmidrule(l){2-5}" _n
file write regtable "& 2005-2010 & 2010-2015 & 2015-2019 & 2022-2025 \\" _n
file write regtable "\midrule" _n

* Initialize matrices to store ALL results (2 occupations x 4 time periods)
matrix coef_results = J(2, 4, .)
matrix se_results = J(2, 4, .)
matrix r2_results = J(2, 4, .)
matrix mean_growth = J(2, 4, .)
matrix sd_growth = J(2, 4, .)

* First run all regressions and store results
* Panel A: Service Occupations
preserve
keep if occ_category == "Service occupations"

local start_years "2005 2010 2015 2022"
local end_years "2010 2015 2019 2025"

forvalues i = 1/4 {
    local start_year : word `i' of `start_years'
    local end_year : word `i' of `end_years'
    local div = cond(`i' == 1, 5, cond(`i' == 2, 5, cond(`i' == 3, 4, 3)))
    
    gen emp_share_dif = (share_informal`end_year' - share_informal`start_year')/`div'
	gen tot_share = share_informal`end_year' - share_informal`start_year'
    rename rti_share_informal`start_year' rti_share_start_period
    
    * Calculate mean and SD of growth (weighted by population share)
    qui sum tot_share [aweight = popshare_informal`start_year'] if !missing(tot_share)
    matrix mean_growth[1,`i'] = r(mean)/`div'
    matrix sd_growth[1,`i'] = r(sd)/`div'
    
    capture areg emp_share_dif rti_share_start_period [pw = popshare_formal`start_year'], absorb(state yr) cluster(state)
    
    if _rc == 0 {
        matrix coef_results[1,`i'] = _b[rti_share_start_period]
        matrix se_results[1,`i'] = _se[rti_share_start_period]
        matrix r2_results[1,`i'] = e(r2)
    }
    
    rename rti_share_start_period rti_share_informal`start_year'
    drop emp_share_dif tot_share
}
restore

* Panel B: Transportation Occupations
preserve
keep if occ_category == "Transportation/construction/mechanics/mining/farm"

forvalues i = 1/4 {
    local start_year : word `i' of `start_years'
    local end_year : word `i' of `end_years'
    local div = cond(`i' == 1, 5, cond(`i' == 2, 5, cond(`i' == 3, 4, 3)))
    
    gen emp_share_dif = (share_informal`end_year' - share_informal`start_year')/`div'
	gen tot_share = share_informal`end_year' - share_informal`start_year'
    rename rti_share_informal`start_year' rti_share_start_period
    
    * Calculate mean and SD of growth (weighted by population share)
    qui sum tot_share [aweight = popshare_informal`start_year'] if !missing(tot_share)
    matrix mean_growth[2,`i'] = r(mean)/`div'
    matrix sd_growth[2,`i'] = r(sd)/`div'
    
    capture areg emp_share_dif rti_share_start_period [pw = popshare_informal`start_year'], absorb(state yr) cluster(state)
    
    if _rc == 0 {
        matrix coef_results[2,`i'] = _b[rti_share_start_period]
        matrix se_results[2,`i'] = _se[rti_share_start_period]
        matrix r2_results[2,`i'] = e(r2)
    }
    
    rename rti_share_start_period rti_share_informal`start_year'
    drop emp_share_dif tot_share
}
restore

* Now write the table using stored matrix results
* Panel A: Service Occupations
file write regtable "\textit{Panel A. Service Occupations} & & & & \\" _n
file write regtable "\addlinespace[0.1cm]" _n

local coef_row_a ""
local se_row_a ""
local r2_row_a ""
local growth_row_a ""

forvalues i = 1/4 {
    local coeff = coef_results[1,`i']
    local se = se_results[1,`i']
    local r2_val = r2_results[1,`i']
    local mean_gr = mean_growth[1,`i']
    local sd_gr = sd_growth[1,`i']
    
    if !missing(`coeff') {
        local coeff_str = string(`coeff', "%6.3f")
        local se_str = string(`se', "%6.3f")
        local r2_str = string(`r2_val', "%6.3f")
        
        * Add significance stars
        local t_stat = `coeff'/`se'
        if abs(`t_stat') > 2.576 {
            local coeff_str "`coeff_str'***"
        }
        else if abs(`t_stat') > 1.96 {
            local coeff_str "`coeff_str'**"
        }
        else if abs(`t_stat') > 1.645 {
            local coeff_str "`coeff_str'*"
        }
    }
    else {
        local coeff_str "---"
        local se_str "---"
        local r2_str "---"
    }
    
    * Format growth statistics
    if !missing(`mean_gr') & !missing(`sd_gr') {
        local mean_str = string(`mean_gr', "%6.3f")
        local sd_str = string(`sd_gr', "%6.3f")
        local growth_str "`mean_str' (`sd_str')"
    }
    else {
        local growth_str "--- (---)"
    }
    
    if `i' == 1 {
        local coef_row_a "`coeff_str'"
        local se_row_a "(`se_str')"
        local r2_row_a "`r2_str'"
        local growth_row_a "`growth_str'"
    }
    else {
        local coef_row_a "`coef_row_a' & `coeff_str'"
        local se_row_a "`se_row_a' & (`se_str')"
        local r2_row_a "`r2_row_a' & `r2_str'"
        local growth_row_a "`growth_row_a' & `growth_str'"
    }
}

file write regtable "Starting Routine Share & `coef_row_a' \\" _n
file write regtable "& `se_row_a' \\" _n
file write regtable "\addlinespace[0.1cm]" _n
file write regtable "R-squared & `r2_row_a' \\" _n
file write regtable "Mean Growth (SD) & `growth_row_a' \\" _n
file write regtable "\addlinespace[0.3cm]" _n

* Panel B: Transportation Occupations
file write regtable "\textit{Panel B. Transportation*} & & & & \\" _n
file write regtable "\addlinespace[0.1cm]" _n

local coef_row_b ""
local se_row_b ""
local r2_row_b ""
local growth_row_b ""

forvalues i = 1/4 {
    local coeff = coef_results[2,`i']
    local se = se_results[2,`i']
    local r2_val = r2_results[2,`i']
    local mean_gr = mean_growth[2,`i']
    local sd_gr = sd_growth[2,`i']
    
    if !missing(`coeff') {
        local coeff_str = string(`coeff', "%6.3f")
        local se_str = string(`se', "%6.3f")
        local r2_str = string(`r2_val', "%6.3f")
        
        * Add significance stars
        local t_stat = `coeff'/`se'
        if abs(`t_stat') > 2.576 {
            local coeff_str "`coeff_str'***"
        }
        else if abs(`t_stat') > 1.96 {
            local coeff_str "`coeff_str'**"
        }
        else if abs(`t_stat') > 1.645 {
            local coeff_str "`coeff_str'*"
        }
    }
    else {
        local coeff_str "---"
        local se_str "---"
        local r2_str "---"
    }
    
    * Format growth statistics
    if !missing(`mean_gr') & !missing(`sd_gr') {
        local mean_str = string(`mean_gr', "%6.3f")
        local sd_str = string(`sd_gr', "%6.3f")
        local growth_str "`mean_str' (`sd_str')"
    }
    else {
        local growth_str "--- (---)"
    }
    
    if `i' == 1 {
        local coef_row_b "`coeff_str'"
        local se_row_b "(`se_str')"
        local r2_row_b "`r2_str'"
        local growth_row_b "`growth_str'"
    }
    else {
        local coef_row_b "`coef_row_b' & `coeff_str'"
        local se_row_b "`se_row_b' & (`se_str')"
        local r2_row_b "`r2_row_b' & `r2_str'"
        local growth_row_b "`growth_row_b' & `growth_str'"
    }
}

file write regtable "Starting Routine Share & `coef_row_b' \\" _n
file write regtable "& `se_row_b' \\" _n
file write regtable "\addlinespace[0.1cm]" _n
file write regtable "R-squared & `r2_row_b' \\" _n
file write regtable "Mean Growth (SD) & `growth_row_b' \\" _n

* Write table footer
file write regtable "\bottomrule" _n
file write regtable "\end{tabular}" _n
file write regtable "\begin{tablenotes}" _n
file write regtable "\footnotesize" _n
file write regtable "\item Note: Each column represents a different time period. Regressions include state fixed effects and are weighted by population share in the starting year of each period. Standard errors are clustered at the state level. Mean Growth (SD) shows the weighted mean and standard deviation of employment share changes for each period. *, **, *** denote significance at the 10\%, 5\%, and 1\% levels, respectively. Transportation* refers to Transportation/construction/mechanics/mining/farm occupations." _n
file write regtable "\end{tablenotes}" _n
file write regtable "\begin{tablenotes}[Source]" _n
file write regtable "\footnotesize" _n
file write regtable "\item Source: ENOE survey data for 2005, 2010, 2015, 2019, and 2022; projections for 2025." _n
file write regtable "\end{tablenotes}" _n
file write regtable "\end{threeparttable}}" _n
file write regtable "\end{table}" _n

* Close file
file close regtable
display "Manual regression LaTeX table with growth statistics created successfully!"

*--------------------------------------------------------------------------
**# Regression: RTI 2SLS FORMAL , table 7 of paper
* ---------------------------------------------------------------------------
clear all
set more off
local controls "yr state_occ occ_yr sex married foreign min_wage sex_yr married_yr foreign_yr min_wage_yr "


* Open LaTeX file for writing
file open regtable using "$output/Tables/rti_tab7.tex", write replace

* Write table header
file write regtable "\begin{table}[htbp]" _n
file write regtable "\centering" _n
file write regtable "\caption{Routine Employment Share and Change in Occupational Employment Shares and Wage Levels by Region, 2SLS and Reduced Form OLS Estimates}" _n
file write regtable "\label{tab:rti_tab7}" _n
file write regtable "\resizebox{\textwidth}{!}{%" _n
file write regtable "\begin{threeparttable}" _n
file write regtable "\begin{tabular}{@{}llcccccc@{}}" _n
file write regtable "\toprule" _n
file write regtable "& & \multicolumn{3}{c}{I. Occupations with} & \multicolumn{3}{c}{II. Occupations with} \\" _n
file write regtable "& & \multicolumn{3}{c}{low routine content} & \multicolumn{3}{c}{high routine content} \\" _n
file write regtable "\cmidrule(r){3-5} \cmidrule(l){6-8}" _n
file write regtable "& & Service & Transport, & Managers, & Clerical & Precision & Machine \\" _n
file write regtable "& & occs & construct, & prof, tech, & retail, & production, & operators, \\" _n
file write regtable "& & & mechanics, & finance, & sales & craft & assemblers \\" _n
file write regtable "& & & mining, & public &  & workers & \\" _n
file write regtable "& & & farm & safety & & & \\" _n
file write regtable "& & (1) & (2) & (3) & (4) & (5) & (6) \\" _n
file write regtable "\midrule" _n

* Initialize matrices to store results (4 regions x 6 occupations x 2 panels)
matrix coef_panel_a = J(4, 6, .)
matrix se_panel_a = J(4, 6, .)
matrix coef_panel_b = J(4, 6, .)
matrix se_panel_b = J(4, 6, .)

* Define occupation categories in order (simplified quote handling)
local occ1 "Service occupations"
local occ2 "Transportation/construction/mechanics/mining/farm"
local occ3 "Managers/ professionals / technicians / finance/ public safety"
local occ4 "Clerical/ retail sales"
local occ5 "Production/craft"
local occ6 "Machine operators/assemblers"

* Define regions
local regions "All North Center South"

* Panel A: Employment Share Regressions
* Import regression database
use "$processed_data/reg_data_2sls.dta", clear

* Setup panel dataset
xtset id yr, yearly

* Compute share change
gen share_dif = share_formal - L.share_formal
replace share_dif = (share_formal - L5.share_formal)/5 if inlist(yr,2010,2015)
replace share_dif = (share_formal - L4.share_formal)/4 if yr == 2019

gen lag_rti_share_formal = L1.rti_share_formal
replace lag_rti_share_formal =  L5.rti_share_formal if inlist(yr, 2010,2015)
replace lag_rti_share_formal =  L4.rti_share_formal if inlist(yr, 2019)

* Keep relevant years
keep if inlist(yr, 2010, 2015, 2019)

* Run Panel A regressions for each occupation and region
forvalues occ = 1/6 {
    local occ_name "`occ`occ''"
    
    forvalues reg = 1/4 {
        local region_name : word `reg' of `regions'
        
        if "`region_name'" == "All" {
            capture ivreghdfe share_dif (lag_rti_share_formal = rti_instrument) [aweight = popshare_formal] if occ_category == "`occ_name'", absorb(yr state) cluster(state) first
        }
        else {
            capture ivreghdfe share_dif (lag_rti_share_formal = rti_instrument) [aweight = popshare_formal] if occ_category == "`occ_name'" & region == "`region_name'", absorb(yr state) cluster(state) first
        }
        
        if _rc == 0 {
            matrix b = e(b)
            matrix V = e(V)
            matrix coef_panel_a[`reg',`occ'] = b[1,1]
            matrix se_panel_a[`reg',`occ'] = sqrt(V[1,1])
        }
    }
}

* Panel B: Wage Regressions
use "$processed_data//enoe_pols_reg_db.dta", clear

* Run Panel B regressions for each occupation and region
forvalues occ = 1/6 {
    local occ_name "`occ`occ''"
    
    forvalues reg = 1/4 {
        local region_name : word `reg' of `regions'
        
        if "`region_name'" == "All" {
            capture areg ln_rwages rsh05_formal [fweight = labor] if inf == 0 & inlist(yr,2005,2019) & occ_category == "`occ_name'", absorb(`controls') cluster(agem) iter(2000) tol(1e-2)
        }
        else {
            capture areg ln_rwages rsh05_formal [fweight = labor] if inf == 0 & inlist(yr,2005,2019) & occ_category == "`occ_name'" & region == "`region_name'", absorb(`controls') cluster(agem) iter(2000) tol(1e-2)
        }
        
        if _rc == 0 {
            matrix b = e(b)
            matrix V = e(V)
            matrix coef_panel_b[`reg',`occ'] = b[1,1]
            matrix se_panel_b[`reg',`occ'] = sqrt(V[1,1])
        }
    }
}

* Write Panel A results
file write regtable "\multicolumn{8}{l}{\textit{Panel A. Change in share of formal employment}} \\" _n
file write regtable "\addlinespace[0.1cm]" _n

forvalues reg = 1/4 {
    local region_name : word `reg' of `regions'
    
    if `reg' == 1 {
        file write regtable "(i) `region_name' & Share of routine occs\$_{t-1}\$ & "
    }
    else if `reg' == 2 {
        file write regtable "(ii) `region_name' & Share of routine occs\$_{t-1}\$ & "
    }
    else if `reg' == 3 {
        file write regtable "(iii) `region_name' & Share of routine occs\$_{t-1}\$ & "
    }
    else {
        file write regtable "(iv) `region_name' & Share of routine occs\$_{t-1} \$ & "
    }
    
    * Build coefficient row
    local coef_row ""
    local se_row ""
    
    forvalues occ = 1/6 {
        local coeff = coef_panel_a[`reg',`occ']
        local se = se_panel_a[`reg',`occ']
        
        if !missing(`coeff') {
            local coeff_str = string(`coeff', "%6.3f")
            local se_str = string(`se', "%6.3f")
            
            * Add significance stars
            local t_stat = `coeff'/`se'
            if abs(`t_stat') > 2.576 {
                local coeff_str "`coeff_str'***"
            }
            else if abs(`t_stat') > 1.96 {
                local coeff_str "`coeff_str'**"
            }
            else if abs(`t_stat') > 1.645 {
                local coeff_str "`coeff_str'*"
            }
        }
        else {
            local coeff_str "---"
            local se_str "---"
        }
        
        if `occ' == 1 {
            local coef_row "`coeff_str'"
            local se_row "(`se_str')"
        }
        else {
            local coef_row "`coef_row' & `coeff_str'"
            local se_row "`se_row' & (`se_str')"
        }
    }
    
    file write regtable "`coef_row' \\" _n
    file write regtable "& & `se_row' \\" _n
    file write regtable "\addlinespace[0.1cm]" _n
}

* Write Panel B results
file write regtable "\addlinespace[0.3cm]" _n
file write regtable "\multicolumn{8}{l}{\textit{Panel B. log hourly wages of formal workers}} \\" _n
file write regtable "\addlinespace[0.1cm]" _n


forvalues reg = 1/4 {
    local region_name : word `reg' of `regions'
    
    if `reg' == 1 {
        file write regtable "(i) `region_name' & Share of routine occs\$_{05}\$ × 2019 & "
    }
    else if `reg' == 2 {
        file write regtable "(ii) `region_name' & Share of routine occs\$_{05}\$ × 2019 & "
    }
    else if `reg' == 3 {
        file write regtable "(iii) `region_name' & Share of routine occs\$_{05}\$ × 2019 & "
    }
    else {
        file write regtable "(iv) `region_name' & Share of routine occs\$_{05}\$ × 2019 & "
    }
    
    
    * Build coefficient row
    local coef_row ""
    local se_row ""
    
    forvalues occ = 1/6 {
        local coeff = coef_panel_b[`reg',`occ']
        local se = se_panel_b[`reg',`occ']
        
        if !missing(`coeff') {
            local coeff_str = string(`coeff', "%6.3f")
            local se_str = string(`se', "%6.3f")
            
            * Add significance stars
            local t_stat = `coeff'/`se'
            if abs(`t_stat') > 2.576 {
                local coeff_str "`coeff_str'***"
            }
            else if abs(`t_stat') > 1.96 {
                local coeff_str "`coeff_str'**"
            }
            else if abs(`t_stat') > 1.645 {
                local coeff_str "`coeff_str'*"
            }
        }
        else {
            local coeff_str "---"
            local se_str "---"
        }
        
        if `occ' == 1 {
            local coef_row "`coeff_str'"
            local se_row "(`se_str')"
        }
        else {
            local coef_row "`coef_row' & `coeff_str'"
            local se_row "`se_row' & (`se_str')"
        }
    }
    
    file write regtable "`coef_row' \\" _n
    file write regtable "& & `se_row' \\" _n
    file write regtable "\addlinespace[0.1cm]" _n
}

* Write table footer
file write regtable "\bottomrule" _n
file write regtable "\end{tabular}" _n
file write regtable "\begin{tablenotes}" _n
file write regtable "\footnotesize" _n
file write regtable "\item Note: Panel A: Each coefficient is based on a separate 2SLS regression. Models include state and time dummies and are weighted by start of period population share. Panel B: Each row presents coefficients from one pooled OLS reduced form regression. All models include extensive controls as described in the text. Standard errors are clustered at the state level for Panel A and at the AGEM level for Panel B. *, **, *** denote significance at the 10\%, 5\%, and 1\% levels, respectively." _n
file write regtable "\end{tablenotes}" _n
file write regtable "\begin{tablenotes}[Source]" _n
file write regtable "\footnotesize" _n
file write regtable "\item Source: ENOE survey data for 2010, 2015, and 2019." _n
file write regtable "\end{tablenotes}" _n
file write regtable "\end{threeparttable}}" _n
file write regtable "\end{table}" _n

* Close file
file close regtable

display "Regional analysis LaTeX table created successfully!"
display "File generated: rti_tab7.tex"

* ---------------------------------------------------------------------------
**# Regression: RTI 2SLS Informal, table 7 of paper
* ---------------------------------------------------------------------------
clear all
set more off
local controls "yr state_occ occ_yr sex married foreign min_wage sex_yr married_yr foreign_yr min_wage_yr "


* Open LaTeX file for writing
file open regtable using "$output/Tables/rti_inf_tab7.tex", write replace

* Write table header
file write regtable "\begin{table}[htbp]" _n
file write regtable "\centering" _n
file write regtable "\caption{Routine Employment Share and Change in Occupational Employment Shares and Wage Levels by Region, 2SLS and Reduced Form OLS Estimates}" _n
file write regtable "\label{tab:rti_inf_tab7}" _n
file write regtable "\resizebox{\textwidth}{!}{%" _n
file write regtable "\begin{threeparttable}" _n
file write regtable "\begin{tabular}{@{}llcccccc@{}}" _n
file write regtable "\toprule" _n
file write regtable "& & \multicolumn{3}{c}{I. Occupations with} & \multicolumn{3}{c}{II. Occupations with} \\" _n
file write regtable "& & \multicolumn{3}{c}{low routine content} & \multicolumn{3}{c}{high routine content} \\" _n
file write regtable "\cmidrule(r){3-5} \cmidrule(l){6-8}" _n
file write regtable "& & Service & Transport, & Managers, & Clerical & Precision & Machine \\" _n
file write regtable "& & occs & construct, & prof, tech, & retail, & production, & operators, \\" _n
file write regtable "& & & mechanics, & finance, & sales & craft & assemblers \\" _n
file write regtable "& & & mining, & public &  & workers & \\" _n
file write regtable "& & & farm & safety & & & \\" _n
file write regtable "& & (1) & (2) & (3) & (4) & (5) & (6) \\" _n
file write regtable "\midrule" _n

* Initialize matrices to store results (4 regions x 6 occupations x 2 panels)
matrix coef_panel_a = J(4, 6, .)
matrix se_panel_a = J(4, 6, .)
matrix coef_panel_b = J(4, 6, .)
matrix se_panel_b = J(4, 6, .)

* Define occupation categories in order (simplified quote handling)
local occ1 "Service occupations"
local occ2 "Transportation/construction/mechanics/mining/farm"
local occ3 "Managers/ professionals / technicians / finance/ public safety"
local occ4 "Clerical/ retail sales"
local occ5 "Production/craft"
local occ6 "Machine operators/assemblers"

* Define regions
local regions "All North Center South"

* Panel A: Employment Share Regressions
* Import regression database
use "$processed_data/reg_data_2sls.dta", clear

* Setup panel dataset
xtset id yr, yearly

* Compute share change
gen share_dif = share_informal - L.share_informal
replace share_dif = (share_informal - L5.share_informal)/5 if inlist(yr,2010,2015)
replace share_dif = (share_informal - L4.share_informal)/4 if yr == 2019

gen lag_rti_share_informal = L1.rti_share_informal
replace lag_rti_share_informal =  L5.rti_share_informal if inlist(yr, 2010,2015)
replace lag_rti_share_informal =  L4.rti_share_informal if inlist(yr, 2019)

* Keep relevant years
keep if inlist(yr, 2015, 2019)

* Run Panel A regressions for each occupation and region
forvalues occ = 1/6 {
    local occ_name "`occ`occ''"
    
    forvalues reg = 1/4 {
        local region_name : word `reg' of `regions'
        
        if "`region_name'" == "All" {
            capture ivreghdfe share_dif (lag_rti_share_informal = rti_instrument_inf) [aweight = popshare_informal] if occ_category == "`occ_name'", absorb(yr state) cluster(state) first
        }
        else {
            capture ivreghdfe share_dif (lag_rti_share_informal = rti_instrument_inf) [aweight = popshare_informal] if occ_category == "`occ_name'" & region == "`region_name'", absorb(yr state) cluster(state) first
        }
        
        if _rc == 0 {
            matrix b = e(b)
            matrix V = e(V)
            matrix coef_panel_a[`reg',`occ'] = b[1,1]
            matrix se_panel_a[`reg',`occ'] = sqrt(V[1,1])
        }
    }
}

* Panel B: Wage Regressions
use "$processed_data//enoe_pols_reg_db.dta", clear

* Run Panel B regressions for each occupation and region
forvalues occ = 1/6 {
    local occ_name "`occ`occ''"
    
    forvalues reg = 1/4 {
        local region_name : word `reg' of `regions'
        
        if "`region_name'" == "All" {
            capture areg ln_rwages rsh05_informal [fweight = labor] if inf == 1 & inlist(yr,2005,2019) & occ_category == "`occ_name'", absorb(`controls') cluster(agem) iter(2000) tol(1e-2)
        }
        else {
            capture areg ln_rwages rsh05_informal [fweight = labor] if inf == 1 & inlist(yr,2005,2019) & occ_category == "`occ_name'" & region == "`region_name'", absorb(`controls') cluster(agem) iter(2000) tol(1e-2)
        }
        
        if _rc == 0 {
            matrix b = e(b)
            matrix V = e(V)
            matrix coef_panel_b[`reg',`occ'] = b[1,1]
            matrix se_panel_b[`reg',`occ'] = sqrt(V[1,1])
        }
    }
}

* Write Panel A results
file write regtable "\multicolumn{8}{l}{\textit{Panel A. Change in share of informal employment}} \\" _n
file write regtable "\addlinespace[0.1cm]" _n

forvalues reg = 1/4 {
    local region_name : word `reg' of `regions'
    
    if `reg' == 1 {
        file write regtable "(i) `region_name' & Share of routine occs\$_{t-1}\$ & "
    }
    else if `reg' == 2 {
        file write regtable "(ii) `region_name' & Share of routine occs\$_{t-1}\$ & "
    }
    else if `reg' == 3 {
        file write regtable "(iii) `region_name' & Share of routine occs\$_{t-1}\$ & "
    }
    else {
        file write regtable "(iv) `region_name' & Share of routine occs\$_{t-1} \$ & "
    }
    
	
    * Build coefficient row
    local coef_row ""
    local se_row ""
    
    forvalues occ = 1/6 {
        local coeff = coef_panel_a[`reg',`occ']
        local se = se_panel_a[`reg',`occ']
        
        if !missing(`coeff') {
            local coeff_str = string(`coeff', "%6.3f")
            local se_str = string(`se', "%6.3f")
            
            * Add significance stars
            local t_stat = `coeff'/`se'
            if abs(`t_stat') > 2.576 {
                local coeff_str "`coeff_str'***"
            }
            else if abs(`t_stat') > 1.96 {
                local coeff_str "`coeff_str'**"
            }
            else if abs(`t_stat') > 1.645 {
                local coeff_str "`coeff_str'*"
            }
        }
        else {
            local coeff_str "---"
            local se_str "---"
        }
        
        if `occ' == 1 {
            local coef_row "`coeff_str'"
            local se_row "(`se_str')"
        }
        else {
            local coef_row "`coef_row' & `coeff_str'"
            local se_row "`se_row' & (`se_str')"
        }
    }
    
    file write regtable "`coef_row' \\" _n
    file write regtable "& & `se_row' \\" _n
    file write regtable "\addlinespace[0.1cm]" _n
}

* Write Panel B results
file write regtable "\addlinespace[0.3cm]" _n
file write regtable "\multicolumn{8}{l}{\textit{Panel B. log hourly wages of informal workers}} \\" _n
file write regtable "\addlinespace[0.1cm]" _n


forvalues reg = 1/4 {
    local region_name : word `reg' of `regions'
    
    if `reg' == 1 {
        file write regtable "(i) `region_name' & Share of routine occs\$_{05}\$ × 2019 & "
    }
    else if `reg' == 2 {
        file write regtable "(ii) `region_name' & Share of routine occs\$_{05}\$ × 2019 & "
    }
    else if `reg' == 3 {
        file write regtable "(iii) `region_name' & Share of routine occs\$_{05}\$ × 2019 & "
    }
    else {
        file write regtable "(iv) `region_name' & Share of routine occs\$_{05}\$ × 2019 & "
    }
    
	
    * Build coefficient row
    local coef_row ""
    local se_row ""
    
    forvalues occ = 1/6 {
        local coeff = coef_panel_b[`reg',`occ']
        local se = se_panel_b[`reg',`occ']
        
        if !missing(`coeff') {
            local coeff_str = string(`coeff', "%6.3f")
            local se_str = string(`se', "%6.3f")
            
            * Add significance stars
            local t_stat = `coeff'/`se'
            if abs(`t_stat') > 2.576 {
                local coeff_str "`coeff_str'***"
            }
            else if abs(`t_stat') > 1.96 {
                local coeff_str "`coeff_str'**"
            }
            else if abs(`t_stat') > 1.645 {
                local coeff_str "`coeff_str'*"
            }
        }
        else {
            local coeff_str "---"
            local se_str "---"
        }
        
        if `occ' == 1 {
            local coef_row "`coeff_str'"
            local se_row "(`se_str')"
        }
        else {
            local coef_row "`coef_row' & `coeff_str'"
            local se_row "`se_row' & (`se_str')"
        }
    }
    
    file write regtable "`coef_row' \\" _n
    file write regtable "& & `se_row' \\" _n
    file write regtable "\addlinespace[0.1cm]" _n
}

* Write table footer
file write regtable "\bottomrule" _n
file write regtable "\end{tabular}" _n
file write regtable "\begin{tablenotes}" _n
file write regtable "\footnotesize" _n
file write regtable "\item Note: Panel A: Each coefficient is based on a separate 2SLS regression. Models include state and time dummies and are weighted by start of period population share. Panel B: Each row presents coefficients from one pooled OLS reduced form regression. All models include extensive controls as described in the text. Standard errors are clustered at the state level for Panel A and at the AGEM level for Panel B. *, **, *** denote significance at the 10\%, 5\%, and 1\% levels, respectively." _n
file write regtable "\end{tablenotes}" _n
file write regtable "\begin{tablenotes}[Source]" _n
file write regtable "\footnotesize" _n
file write regtable "\item Source: ENOE survey data for 2010, 2015, and 2019." _n
file write regtable "\end{tablenotes}" _n
file write regtable "\end{threeparttable}}" _n
file write regtable "\end{table}" _n

* Close file
file close regtable

display "Regional analysis LaTeX table created successfully!"
display "File generated: rti_inf_tab7.tex"

*--------------------------------------------------------------------------
**# Regression: AI and SML by Employment Type
* ---------------------------------------------------------------------------
clear all
set more off
local controls "yr state_occ occ_yr sex married foreign min_wage sex_yr married_yr foreign_yr min_wage_yr "

foreach v in sml ai {

    local name = cond("`v'" == "sml", "SML", "AI")
    local v1 = cond("`v'" == "sml", "sml", "alpha")
    
    * Open LaTeX file for writing
    file open regtable using "$output/Tables/`v'_combined_tab7.tex", write replace

    * Write table header
    file write regtable "\begin{table}[htbp]" _n
    file write regtable "\centering" _n
    file write regtable "\caption{`name' Employment Share and Change in Occupational Employment Shares and Wage Levels, 2SLS and Reduced Form OLS Estimates}" _n
    file write regtable "\label{tab:`v1'_tab7}" _n
    file write regtable "\resizebox{\textwidth}{!}{%" _n
    file write regtable "\begin{threeparttable}" _n
    file write regtable "\begin{tabular}{@{}llcccccc@{}}" _n
    file write regtable "\toprule" _n
    file write regtable "& & \multicolumn{3}{c}{I. Occupations more} & \multicolumn{3}{c}{II. Occupations less} \\" _n
    file write regtable "& & \multicolumn{3}{c}{exposed to `name'} & \multicolumn{3}{c}{exposed to `name'} \\" _n
    file write regtable "\cmidrule(r){3-5} \cmidrule(l){6-8}" _n
    file write regtable "& & Clerical & Machine & Managers, & Production, & Service & Transport, \\" _n
    file write regtable "& & retail, & operators, & prof, tech, & craft & occs & construct, \\" _n
    file write regtable "& & sales & assemblers & finance, & workers & & mechanics, \\" _n
    file write regtable "& & & & public & & & mining, \\" _n
    file write regtable "& & & & safety & & & farm \\" _n
    file write regtable "& & (1) & (2) & (3) & (4) & (5) & (6) \\" _n
    file write regtable "\midrule" _n

    * Initialize matrices to store results (3 samples x 6 occupations x 2 panels)
    matrix coef_panel_a = J(3, 6, .)
    matrix se_panel_a = J(3, 6, .)
    matrix coef_panel_b = J(3, 6, .)
    matrix se_panel_b = J(3, 6, .)

    * Define occupation categories in order (simplified quote handling)
    local occ1 "Clerical/ retail sales"
    local occ2 "Machine operators/assemblers"
    local occ3 "Managers/ professionals / technicians / finance/ public safety"
    local occ4 "Production/craft"
    local occ5 "Service occupations"
    local occ6 "Transportation/construction/mechanics/mining/farm"

    * Define sample types and corresponding variables
    local sample_types "total formal informal"
    local sample_labels "Total Formal Informal"

    * Panel A: Employment Share Regressions
    local samp_num = 1
    foreach t in `sample_types' {
        
        * Import regression database for each sample type
        use "$processed_data/reg_data_2sls.dta", clear

        * Setup panel dataset
        xtset id yr, yearly

        * Compute share change for current sample type
        gen share_dif = share_`t' - L.share_`t'
        replace share_dif = (share_`t' - L1.share_`t') if yr == 2024
        replace share_dif = (share_`t' - L2.share_`t')/2 if yr == 2025

        gen lag_`v1'_share_`t' = L1.`v1'_share_`t'
        replace lag_`v1'_share_`t' = L1.`v1'_share_`t' if inlist(yr, 2024)
        replace lag_`v1'_share_`t' = L2.`v1'_share_`t' if inlist(yr, 2025)

        * Modify instrument with corresponding sample 
        if "`t'" == "total" {
            gen instrument_current = `v1'_instrument_t
        }
        else if "`t'" == "formal" {
            gen instrument_current = `v1'_instrument
        }
        else if "`t'" == "informal" {
            gen instrument_current = `v1'_instrument_inf
        }

        * Keep relevant years
        keep if inlist(yr, 2024,2025)

        forvalues occ = 1/6 {
            local occ_name "`occ`occ''"
            
           capture ivreghdfe share_dif (lag_`v1'_share_`t' = instrument_current) [aweight = popshare_`t'] if occ_category == "`occ_name'", absorb(yr state) cluster(agem) first
            
            if _rc == 0 {
                matrix b = e(b)
                matrix V = e(V)
                matrix coef_panel_a[`samp_num',`occ'] = b[1,1]
                matrix se_panel_a[`samp_num',`occ'] = sqrt(V[1,1])
            }
        }
        
        local samp_num = `samp_num' + 1
    }
    
    * Panel B: Wage Regressions
    use "$processed_data//enoe_pols_reg_db.dta", clear

    * Run Panel B regressions for each sample type and occupation
    local samp_num = 1
    foreach t in `sample_types' {
        local sample_condition = cond("`t'" == "total", "if inlist(yr,2024,2025)", ///
                                 cond("`t'" == "formal", "if inf == 0 & inlist(yr,2024,2025)", ///
                                      "if inf == 1 & inlist(yr,2024,2025)"))
        
        forvalues occ = 1/6 {
            local occ_name "`occ`occ''"
            
            capture areg ln_rwages `v'sh22_`t' [fweight = labor] `sample_condition' & occ_category == "`occ_name'", absorb(`controls') cluster(agem) iter(2000) tol(1e-2)
            
            if _rc == 0 {
                matrix b = e(b)
                matrix V = e(V)
                matrix coef_panel_b[`samp_num',`occ'] = b[1,1]
                matrix se_panel_b[`samp_num',`occ'] = sqrt(V[1,1])
            }
        }
        
        local samp_num = `samp_num' + 1
    }

    * Write Panel A results
    file write regtable "\multicolumn{8}{l}{\textit{Panel A. Change in share of employment}} \\" _n
    file write regtable "\addlinespace[0.1cm]" _n

    forvalues samp = 1/3 {
        local sample_label : word `samp' of `sample_labels'
        
        file write regtable "(`samp') `sample_label' & Share of `name' occs\$_{t-1}\$ & "
        
        * Build coefficient row
        local coef_row ""
        local se_row ""
        
        forvalues occ = 1/6 {
            local coeff = coef_panel_a[`samp',`occ']
            local se = se_panel_a[`samp',`occ']
            
            if !missing(`coeff') {
                local coeff_str = string(`coeff', "%6.3f")
                local se_str = string(`se', "%6.3f")
                
                * Add significance stars
                local t_stat = `coeff'/`se'
                if abs(`t_stat') > 2.576 {
                    local coeff_str "`coeff_str'***"
                }
                else if abs(`t_stat') > 1.96 {
                    local coeff_str "`coeff_str'**"
                }
                else if abs(`t_stat') > 1.645 {
                    local coeff_str "`coeff_str'*"
                }
            }
            else {
                local coeff_str "---"
                local se_str "---"
            }
            
            if `occ' == 1 {
                local coef_row "`coeff_str'"
                local se_row "(`se_str')"
            }
            else {
                local coef_row "`coef_row' & `coeff_str'"
                local se_row "`se_row' & (`se_str')"
            }
        }
        
        file write regtable "`coef_row' \\" _n
        file write regtable "& & `se_row' \\" _n
        file write regtable "\addlinespace[0.1cm]" _n
    }

    * Write Panel B results
    file write regtable "\addlinespace[0.3cm]" _n
    file write regtable "\multicolumn{8}{l}{\textit{Panel B. Log hourly wages of workers}} \\" _n
    file write regtable "\addlinespace[0.1cm]" _n

    forvalues samp = 1/3 {
        local sample_label : word `samp' of `sample_labels'
        
        file write regtable "(`samp') `sample_label' & Share of `name' occs\$_{22}\$ × 2025 & "
        
        * Build coefficient row
        local coef_row ""
        local se_row ""
        
        forvalues occ = 1/6 {
            local coeff = coef_panel_b[`samp',`occ']
            local se = se_panel_b[`samp',`occ']
            
            if !missing(`coeff') {
                local coeff_str = string(`coeff', "%6.3f")
                local se_str = string(`se', "%6.3f")
                
                * Add significance stars
                local t_stat = `coeff'/`se'
                if abs(`t_stat') > 2.576 {
                    local coeff_str "`coeff_str'***"
                }
                else if abs(`t_stat') > 1.96 {
                    local coeff_str "`coeff_str'**"
                }
                else if abs(`t_stat') > 1.645 {
                    local coeff_str "`coeff_str'*"
                }
            }
            else {
                local coeff_str "---"
                local se_str "---"
            }
            
            if `occ' == 1 {
                local coef_row "`coeff_str'"
                local se_row "(`se_str')"
            }
            else {
                local coef_row "`coef_row' & `coeff_str'"
                local se_row "`se_row' & (`se_str')"
            }
        }
        
        file write regtable "`coef_row' \\" _n
        file write regtable "& & `se_row' \\" _n
        file write regtable "\addlinespace[0.1cm]" _n
    }

    * Write table footer
    file write regtable "\bottomrule" _n
    file write regtable "\end{tabular}" _n
    file write regtable "\begin{tablenotes}" _n
    file write regtable "\footnotesize" _n
    file write regtable "\item Note: Panel A: Each coefficient is based on a separate 2SLS regression. Models include state and time dummies and are weighted by start of period population share. Panel B: Each row presents coefficients from one pooled OLS reduced form regression. All models include extensive controls as described in the text. Standard errors are clustered at the AGEM level for both panels. *, **, *** denote significance at the 10\%, 5\%, and 1\% levels, respectively." _n
    file write regtable "\end{tablenotes}" _n
    file write regtable "\begin{tablenotes}[Source]" _n
    file write regtable "\footnotesize" _n
    file write regtable "\item Source: ENOE survey data for 2024-2025." _n
    file write regtable "\end{tablenotes}" _n
    file write regtable "\end{threeparttable}}" _n
    file write regtable "\end{table}" _n

    * Close file
    file close regtable

    display "Combined sample analysis LaTeX table created successfully!"

}
