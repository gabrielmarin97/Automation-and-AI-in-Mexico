/* =====================================================

	Employment, Wage Polarization, and RTI Graphs
	Gabriel Marin, Anahuac University
	gabriel.marinmu@anahuac.mx

	Note: This do-file creates the respective graphs of
	Autor and Dorn 2013 for the case of Mexico by type
	of labor (total, formal and informal)

====================================================== */
clear all
set more off

cd "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data"
global processed_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Processed_Data"
global raw_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Raw_Data"
global output "/Users/gmm/Dropbox/Apps/Overleaf/Labor Markets and Automation in the Open Economy"

*------------------------------------------------------------------------
**# Employment Share and Log Wage Change 2019-2005 Figures
*------------------------------------------------------------------------


foreach t in total informal formal {
	* Select which type of labor (formal, informal, total)
	* Select which type of income will classify (mon_inc net_wage)
	local v = "net_wage"
	local num_pctiles = 100

	* helpful trims as percentiles (keep 5%..95%)
	local p_lo = ceil(0.05*`num_pctiles')
	local p_hi = floor(0.95*`num_pctiles')

	*local p_lo = 0
	*local p_hi = 100
	local base_year = 2005
	local end_year = 2019

	* Bandwith smoothing parameter (paper uses 0.4)
	local smooth = 0.3

	*-----------------------------
	* 1) Build `base_year' percentile map
	*-----------------------------
	use "$processed_data/enoe_annual_soc_tasks.dta", clear

	* Construct RTI measure (AD 2013 page 1570)
	gen rti = ln(task_routine) - ln(task_manual) - ln(task_abstract)
	drop if rti == .

	keep if yr == `base_year'
	drop if `v'_`t' == .

	bys yr: egen L = total(labor_`t')
	gen weight = labor_`t' / L

	* Employment-weighted 66.6667th percentile of RTI in 2005
	_pctile rti , p(66.6667)
	scalar rti_p66_2005 = r(r1)

	gen routine2005 = rti > rti_p66_2005
	
	* Employment-weighted 66.6667th percentile of SML in 2005
	* More is more suitable to be replaced by ML technologies
	_pctile msml , p(66.6667)
	scalar sml_p66_2005 = r(r1)
	gen sml2005 = msml > sml_p66_2005
	
	* More is more suitable to be replaced by ML technologies
	_pctile alpha , p(66.6667)
	scalar ai_p66_2005 = r(r1)
	gen ai2005 = alpha > ai_p66_2005
	
	
	gen logwage = ln(`v'_`t')
	sort logwage
	gen cum_share = sum(weight)

	* [0,num_pctiles] segment for each occupation
	gen left100  = `num_pctiles' * (cum_share - weight)
	gen right100 = `num_pctiles' * cum_share
	gen margwt   = right100 - left100
	*assert margwt > 0.00000000000001
	gen segwt = margwt/`num_pctiles'

	* psh_p: share of each occupation that lies in percentile p
	forvalues p = 1/`num_pctiles' {
		gen p`p' = 0
		replace p`p' = right100 - (`p' - 1) if right100 > (`p' - 1) & right100 <= `p'   & left100 < (`p' - 1)
		replace p`p' = `p' - left100         if left100  >= (`p' - 1) & left100  <  `p'  & right100 >  `p'
		replace p`p' = 1                     if left100  <  (`p' - 1) & right100 >= `p'
		replace p`p' = right100 - left100    if left100  >= (`p' - 1) & right100 <= `p'
		gen psh`p' = p`p' / margwt
		drop p`p'
	}

	keep soc segwt psh* rti routine2005 msml sml2005 alpha ai2005
	order soc segwt psh*
	save "$processed_data/rti_percentile_mapping_2005.dta", replace

	*----------------------------------------------------------
	* 2) Apply mapping to panel; then keep only 2005 and 2019
	*----------------------------------------------------------
	use "$processed_data/enoe_annual_soc_tasks.dta", clear
	gen rti = ln(task_routine) - ln(task_manual) - ln(task_abstract)
	drop if rti == .
	drop if `v'_`t' == .

	* Transform income variable to real terms
	merge m:1 yr using "$raw_data//wb_wdi_variables.dta"
	drop if _m == 2
	drop _m
	replace `v'_`t' = `v'_`t'/cpi_2005

	* Merge percentile mapping
	merge m:1 soc using "$processed_data/rti_percentile_mapping_2005.dta", keep(3) nogen

	* Keep only base and end years for changes
	keep if inlist(yr, `base_year', `end_year')

	* Yearly employment weight
	bys yr: egen Ltot = total(labor_`t')
	gen empwt = labor_`t'/Ltot

	* ---- Wage by percentile (percwg_p), 2005 mapping ----
	forvalues p = 1/`num_pctiles' {
		gen  num`p' = psh`p' * segwt * `v'_`t'
		gen  den`p' = psh`p' * segwt * (`v'_`t' < .)
		bys yr: egen Num_`p' = total(num`p')
		bys yr: egen Den_`p' = total(den`p')
		gen  percwg_`p' = Num_`p'/Den_`p'
		drop num`p' den`p' Num_`p' Den_`p'
	}

	* ---- Employment share by percentile (share_p), 2005 mapping ----
	forvalues p = 1/`num_pctiles' {
		gen emp_p`p' = psh`p' * segwt * empwt
		bys yr: egen share_`p' = total(emp_p`p')
		drop emp_p`p'
	}

	* ---- Routine-occupation share by percentile (rshare_p), 2005 mapping ----
	* routine2005 is a 0/1 dummy at SOC; compute employment-weighted mean within percentile
	forvalues p = 1/`num_pctiles' {
		gen  rout_num`p' = psh`p' * segwt * empwt * (routine2005==1)
		gen  rout_den`p' = psh`p' * segwt * empwt
		bys yr: egen ROUT_Num_`p' = total(rout_num`p')
		bys yr: egen ROUT_Den_`p' = total(rout_den`p')
		gen  rshare_`p' = ROUT_Num_`p'/ROUT_Den_`p'
		drop rout_num`p' rout_den`p' ROUT_Num_`p' ROUT_Den_`p'
	}

	* ---- SML-occupation share by percentile (rshare_p), 2005 mapping ----
	* sml2005 is a 0/1 dummy at SOC; compute employment-weighted mean within percentile
	forvalues p = 1/`num_pctiles' {
		gen  sml_num`p' = psh`p' * segwt * empwt * (sml2005==1)
		gen  sml_den`p' = psh`p' * segwt * empwt
		bys yr: egen SML_Num_`p' = total(sml_num`p')
		bys yr: egen SML_Den_`p' = total(sml_den`p')
		gen  smlshare_`p' = SML_Num_`p'/SML_Den_`p'
		drop sml_num`p' sml_den`p' SML_Num_`p' SML_Den_`p'
	}
	
		* ---- AI-occupation share by percentile (rshare_p), 2005 mapping ----
	* sml2005 is a 0/1 dummy at SOC; compute employment-weighted mean within percentile
	forvalues p = 1/`num_pctiles' {
		gen  ai_num`p' = psh`p' * segwt * empwt * (ai2005==1)
		gen  ai_den`p' = psh`p' * segwt * empwt
		bys yr: egen AI_Num_`p' = total(ai_num`p')
		bys yr: egen AI_Den_`p' = total(ai_den`p')
		gen  aishare_`p' = AI_Num_`p'/AI_Den_`p'
		drop ai_num`p' ai_den`p' AI_Num_`p' AI_Den_`p'
	}
	
	
	
	* Reduce to one row per year, reshape long
	bys yr: keep if _n==1
	reshape long percwg_ share_ rshare_ smlshare_ aishare_, i(yr) j(pctile)
	rename percwg_ percwg
	rename share_  share
	rename rshare_ rshare
	rename smlshare_ smlshare
	rename aishare_ aishare

	* -----------------------------
	* 3) End to base year changes
	* -----------------------------

	* Base levels (`base_year') by percentile
	gen percwg_real = percwg
	bys pctile: egen base_wage2005  = max(cond(yr==`base_year', percwg_real, .))
	bys pctile: egen base_share2005 = max(cond(yr==`base_year', share,       .))
	bys pctile: egen base_routs2005 = max(cond(yr==`base_year', rshare,      .))
	bys pctile: egen base_sml2005 = max(cond(yr==`base_year', smlshare,      .))
	bys pctile: egen base_ai2005 = max(cond(yr==`base_year', aishare,      .))

	* Keep only end year for deltas
	keep if yr == `end_year'

	* Changes
	gen dwage2005   = ln(percwg_real) - ln(base_wage2005)
	gen dshare2005  = (share - base_share2005)*100
	gen drshare2005 = (rshare - base_routs2005)*100

	label var dwage2005   "Δ log wage (`end_year'–`base_year', `base_year' mapping)"
	label var dshare2005  "Δ employment share, pp (`end_year'–`base_year', `base_year' mapping)"
	label var drshare2005 "Δ routine share, pp (`end_year'–`base_year', `base_year' mapping)"

	* -----------------------------
	* 4) Smooth and plot
	* -----------------------------
	lowess dwage2005  pctile, gen(s_dwage2005)  bwidth(`smooth')
	lowess dshare2005 pctile, gen(s_dshare2005) bwidth(`smooth')
	lowess base_routs2005 pctile, gen(s_rshare2005) bwidth(`smooth')
	lowess base_sml2005 pctile, gen(s_smlshare2005) bwidth(`smooth')
	lowess base_ai2005 pctile, gen(s_aishare2005) bwidth(`smooth')

	* Change in Wages
	twoway (scatter s_dwage2005  pctile if inrange(pctile, `p_lo', `p_hi'), connect(l) msymbol(o) msize(small)), ///
		xtitle("Skill percentile (ranked by `base_year' occupational mean wages)") ///
		ytitle("Δ log monthly wage") legend(off) ///
		name(wages, replace)
	graph export "$output/Figures/wage_change_`t'.png", replace
	* Change in employment share
	twoway (scatter s_dshare2005 pctile if inrange(pctile, `p_lo', `p_hi'), connect(l) msymbol(o) msize(small)), ///
		xtitle("Skill percentile (ranked by `base_year' occupational mean wages)") ///
		ytitle("100 x Δ employment share (pp)") legend(off) ///
		name(labor, replace)
	graph export "$output/Figures/share_change_`t'.png", replace
	* RTI share
	twoway (scatter s_rshare2005 pctile if inrange(pctile, `p_lo', `p_hi'), connect(l) msymbol(o) msize(small)), ///
		ylabel(0(0.10)1.0) ///
		xtitle("Skill percentile (ranked by `base_year' occupational mean wages)") ///
		ytitle("Routine occupation share") legend(off) ///
		name(routi, replace)
	graph export "$output/Figures/rti_share_`t'.png", replace
	* SML Share 2022
		twoway (scatter s_smlshare2005 pctile if inrange(pctile, `p_lo', `p_hi'), connect(l) msymbol(o) msize(small)), ///
		ylabel(0(0.10)1.0) ///
		xtitle("Skill percentile (ranked by `base_year' occupational mean wages)") ///
		ytitle("SML occupation share") legend(off) ///
		name(routi, replace)
	graph export "$output/Figures/sml_share_`t'.png", replace
	* AI Share 2022
		twoway (scatter s_smlshare2005 pctile if inrange(pctile, `p_lo', `p_hi'), connect(l) msymbol(o) msize(small)), ///
		ylabel(0(0.10)1.0) ///
		xtitle("Skill percentile (ranked by `base_year' occupational mean wages)") ///
		ytitle("SML occupation share") legend(off) ///
		name(routi, replace)
	graph export "$output/Figures/sml_share_`t'.png", replace

}

*------------------------------------------------------------------------
**# SML and AI Figures by 2022 Wages
*------------------------------------------------------------------------

foreach t in total informal formal {
	* Select which type of labor (formal, informal, total)
	* Select which type of income will classify (mon_inc net_wage)
	local v = "net_wage"
	local num_pctiles = 100

	* helpful trims as percentiles (keep 5%..95%)
	local p_lo = ceil(0.05*`num_pctiles')
	local p_hi = floor(0.95*`num_pctiles')

	*local p_lo = 0
	*local p_hi = 100
	local base_year = 2022
	local end_year = 2025

	* Bandwith smoothing parameter (paper uses 0.4)
	local smooth = 0.3

	*-----------------------------
	* 1) Build `base_year' percentile map
	*-----------------------------
	use "$processed_data/enoe_annual_soc_tasks.dta", clear

	* Construct RTI measure (AD 2013 page 1570)
	gen rti = ln(task_routine) - ln(task_manual) - ln(task_abstract)
	drop if rti == .

	keep if yr == `base_year'
	drop if `v'_`t' == .

	bys yr: egen L = total(labor_`t')
	gen weight = labor_`t' / L

	* Employment-weighted 66.6667th percentile of RTI in 2005
	_pctile rti , p(66.6667)
	scalar rti_p66_2005 = r(r1)

	gen routine2005 = rti > rti_p66_2005
	
	* Employment-weighted 66.6667th percentile of SML in 2005
	* More is more suitable to be replaced by ML technologies
	_pctile msml , p(66.6667)
	scalar sml_p66_2005 = r(r1)
	gen sml2005 = msml > sml_p66_2005
	
	* More is more suitable to be replaced by ML technologies
	_pctile alpha , p(66.6667)
	scalar ai_p66_2005 = r(r1)
	gen ai2005 = alpha > ai_p66_2005
	
	
	gen logwage = ln(`v'_`t')
	sort logwage
	gen cum_share = sum(weight)

	* [0,num_pctiles] segment for each occupation
	gen left100  = `num_pctiles' * (cum_share - weight)
	gen right100 = `num_pctiles' * cum_share
	gen margwt   = right100 - left100
	*assert margwt > 0.00000000000001
	gen segwt = margwt/`num_pctiles'

	* psh_p: share of each occupation that lies in percentile p
	forvalues p = 1/`num_pctiles' {
		gen p`p' = 0
		replace p`p' = right100 - (`p' - 1) if right100 > (`p' - 1) & right100 <= `p'   & left100 < (`p' - 1)
		replace p`p' = `p' - left100         if left100  >= (`p' - 1) & left100  <  `p'  & right100 >  `p'
		replace p`p' = 1                     if left100  <  (`p' - 1) & right100 >= `p'
		replace p`p' = right100 - left100    if left100  >= (`p' - 1) & right100 <= `p'
		gen psh`p' = p`p' / margwt
		drop p`p'
	}

	keep soc segwt psh* rti routine2005 msml sml2005 alpha ai2005
	order soc segwt psh*
	save "$processed_data/rti_percentile_mapping_2005.dta", replace

	*----------------------------------------------------------
	* 2) Apply mapping to panel; then keep only 2005 and 2019
	*----------------------------------------------------------
	use "$processed_data/enoe_annual_soc_tasks.dta", clear
	gen rti = ln(task_routine) - ln(task_manual) - ln(task_abstract)
	drop if rti == .
	drop if `v'_`t' == .

	* Transform income variable to real terms
	merge m:1 yr using "$raw_data//wb_wdi_variables.dta"
	drop if _m == 2
	drop _m
	replace `v'_`t' = `v'_`t'/cpi_2005

	* Merge percentile mapping
	merge m:1 soc using "$processed_data/rti_percentile_mapping_2005.dta", keep(3) nogen

	* Keep only base and end years for changes
	keep if inlist(yr, `base_year', `end_year')

	* Yearly employment weight
	bys yr: egen Ltot = total(labor_`t')
	gen empwt = labor_`t'/Ltot

	* ---- Wage by percentile (percwg_p), 2005 mapping ----
	forvalues p = 1/`num_pctiles' {
		gen  num`p' = psh`p' * segwt * `v'_`t'
		gen  den`p' = psh`p' * segwt * (`v'_`t' < .)
		bys yr: egen Num_`p' = total(num`p')
		bys yr: egen Den_`p' = total(den`p')
		gen  percwg_`p' = Num_`p'/Den_`p'
		drop num`p' den`p' Num_`p' Den_`p'
	}

	* ---- Employment share by percentile (share_p), 2005 mapping ----
	forvalues p = 1/`num_pctiles' {
		gen emp_p`p' = psh`p' * segwt * empwt
		bys yr: egen share_`p' = total(emp_p`p')
		drop emp_p`p'
	}

	* ---- Routine-occupation share by percentile (rshare_p), 2005 mapping ----
	* routine2005 is a 0/1 dummy at SOC; compute employment-weighted mean within percentile
	forvalues p = 1/`num_pctiles' {
		gen  rout_num`p' = psh`p' * segwt * empwt * (routine2005==1)
		gen  rout_den`p' = psh`p' * segwt * empwt
		bys yr: egen ROUT_Num_`p' = total(rout_num`p')
		bys yr: egen ROUT_Den_`p' = total(rout_den`p')
		gen  rshare_`p' = ROUT_Num_`p'/ROUT_Den_`p'
		drop rout_num`p' rout_den`p' ROUT_Num_`p' ROUT_Den_`p'
	}

	* ---- SML-occupation share by percentile (rshare_p), 2005 mapping ----
	* sml2005 is a 0/1 dummy at SOC; compute employment-weighted mean within percentile
	forvalues p = 1/`num_pctiles' {
		gen  sml_num`p' = psh`p' * segwt * empwt * (sml2005==1)
		gen  sml_den`p' = psh`p' * segwt * empwt
		bys yr: egen SML_Num_`p' = total(sml_num`p')
		bys yr: egen SML_Den_`p' = total(sml_den`p')
		gen  smlshare_`p' = SML_Num_`p'/SML_Den_`p'
		drop sml_num`p' sml_den`p' SML_Num_`p' SML_Den_`p'
	}
	
		* ---- AI-occupation share by percentile (rshare_p), 2005 mapping ----
	* sml2005 is a 0/1 dummy at SOC; compute employment-weighted mean within percentile
	forvalues p = 1/`num_pctiles' {
		gen  ai_num`p' = psh`p' * segwt * empwt * (ai2005==1)
		gen  ai_den`p' = psh`p' * segwt * empwt
		bys yr: egen AI_Num_`p' = total(ai_num`p')
		bys yr: egen AI_Den_`p' = total(ai_den`p')
		gen  aishare_`p' = AI_Num_`p'/AI_Den_`p'
		drop ai_num`p' ai_den`p' AI_Num_`p' AI_Den_`p'
	}
	
	
	
	* Reduce to one row per year, reshape long
	bys yr: keep if _n==1
	reshape long percwg_ share_ rshare_ smlshare_ aishare_, i(yr) j(pctile)
	rename percwg_ percwg
	rename share_  share
	rename rshare_ rshare
	rename smlshare_ smlshare
	rename aishare_ aishare

	* -----------------------------
	* 3) End to base year changes
	* -----------------------------

	* Base levels (`base_year') by percentile
	gen percwg_real = percwg
	bys pctile: egen base_wage2005  = max(cond(yr==`base_year', percwg_real, .))
	bys pctile: egen base_share2005 = max(cond(yr==`base_year', share,       .))
	bys pctile: egen base_routs2005 = max(cond(yr==`base_year', rshare,      .))
	bys pctile: egen base_sml2005 = max(cond(yr==`base_year', smlshare,      .))
	bys pctile: egen base_ai2005 = max(cond(yr==`base_year', aishare,      .))

	* Keep only end year for deltas
	keep if yr == `end_year'

	* Changes
	gen dwage2005   = ln(percwg_real) - ln(base_wage2005)
	gen dshare2005  = (share - base_share2005)*100
	gen drshare2005 = (rshare - base_routs2005)*100

	label var dwage2005   "Δ log wage (`end_year'–`base_year', `base_year' mapping)"
	label var dshare2005  "Δ employment share, pp (`end_year'–`base_year', `base_year' mapping)"
	label var drshare2005 "Δ routine share, pp (`end_year'–`base_year', `base_year' mapping)"

	* -----------------------------
	* 4) Smooth and plot
	* -----------------------------
	lowess dwage2005  pctile, gen(s_dwage2005)  bwidth(`smooth')
	lowess dshare2005 pctile, gen(s_dshare2005) bwidth(`smooth')
	lowess base_routs2005 pctile, gen(s_rshare2005) bwidth(`smooth')
	lowess base_sml2005 pctile, gen(s_smlshare2005) bwidth(`smooth')
	lowess base_ai2005 pctile, gen(s_aishare2005) bwidth(`smooth')
	/*
	* Change in Wages
	twoway (scatter s_dwage2005  pctile if inrange(pctile, `p_lo', `p_hi'), connect(l) msymbol(o) msize(small)), ///
		xtitle("Skill percentile (ranked by `base_year' occupational mean wages)") ///
		ytitle("Δ log monthly wage") legend(off) ///
		name(wages, replace)
	graph export "$output/Figures/wage_change_`t'.png", replace
	* Change in employment share
	twoway (scatter s_dshare2005 pctile if inrange(pctile, `p_lo', `p_hi'), connect(l) msymbol(o) msize(small)), ///
		xtitle("Skill percentile (ranked by `base_year' occupational mean wages)") ///
		ytitle("100 x Δ employment share (pp)") legend(off) ///
		name(labor, replace)
	graph export "$output/Figures/share_change_`t'.png", replace
	* RTI share
	twoway (scatter s_rshare2005 pctile if inrange(pctile, `p_lo', `p_hi'), connect(l) msymbol(o) msize(small)), ///
		ylabel(0(0.10)1.0) ///
		xtitle("Skill percentile (ranked by `base_year' occupational mean wages)") ///
		ytitle("Routine occupation share") legend(off) ///
		name(routi, replace)
	graph export "$output/Figures/rti_share_`t'.png", replace
	*/
	* SML Share 2022
		twoway (scatter s_smlshare2005 pctile if inrange(pctile, `p_lo', `p_hi'), connect(l) msymbol(o) msize(small)), ///
		ylabel(0(0.10)1.0) ///
		xtitle("Skill percentile (ranked by `base_year' occupational mean wages)") ///
		ytitle("SML occupation share") legend(off) ///
		name(routi, replace)
	graph export "$output/Figures/sml_share_`t'.png", replace
	* AI Share 2022
		twoway (scatter s_smlshare2005 pctile if inrange(pctile, `p_lo', `p_hi'), connect(l) msymbol(o) msize(small)), ///
		ylabel(0(0.10)1.0) ///
		xtitle("Skill percentile (ranked by `base_year' occupational mean wages)") ///
		ytitle("AI occupation share") legend(off) ///
		name(routi, replace)
	graph export "$output/Figures/ai_share_`t'.png", replace

}




/*

*------------------------------------------------------------------------
**# RTI, SML and AI Exposure Figures
*------------------------------------------------------------------------


foreach t in total informal formal {
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
			
			_pctile msml, p(66.6667)
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

	* Collapse to muni-year; keep Lmun once with first nonmissing
	collapse (sum) rti_share sml_share alpha_share (firstnm) Lmun, by(ent yr)

	gen rti_exposure = (rti_share / Lmun)*100
	gen sml_exposure = (sml_share /Lmun)*100
	gen ai_exposure = (alpha_share / Lmun)*100
	* IMPORTANT: do NOT replace missings with 0 — we want them gray on the map.

	* 4) Build INEGI keys
	gen str2 CVE_ENT = string(ent, "%02.0f")
	*gen str3 CVE_MUN = string(mun, "%03.0f")
	*gen str5 CVEGEO  = CVE_ENT + CVE_MUN
	gen str5 CVEGEO  = CVE_ENT

	* 5) Keep the year to plot
	preserve 
	keep if yr == `end_year'
	tempfile panel2005
	save `panel2005'

	* 6) Open shape DB as MASTER and merge muni values for that year
	use "$processed_data/aegm_ent_mx.dta", clear   
	
	* Ensure CVEGEO is a 5-char string
	capture confirm string variable CVEGEO
	if _rc tostring CVEGEO, replace format(%05.0f)

	merge m:1 CVEGEO using `panel2005', nogen
	
	* Format exposure variables
	format rti_exposure %9.2f


	* RTI EXPOSURE GRAPH
	spmap rti_exposure if yr == `end_year' using "$processed_data/coords_ent_mx.dta", id(ent_id) ///
		  ndfcolor(gs13) fcolor(Blues) ocolor(black ..) ///
		  legstyle(2) legend( size(*2) region(lwidth(none)))
	graph export "$output/Figures/rti_exp_`t'.png", replace

	restore
	
	preserve 
	keep if yr == 2025
	tempfile panel2005
	save `panel2005'

	* 6) Open shape DB as MASTER and merge muni values for that year
	use "$processed_data/aegm_ent_mx.dta", clear   
	
	* Ensure CVEGEO is a 5-char string
	capture confirm string variable CVEGEO
	if _rc tostring CVEGEO, replace format(%05.0f)

	merge m:1 CVEGEO using `panel2005', nogen
	
	* Format exposure variables	
	format sml_exposure %9.2f
	format ai_exposure %9.2f
	
	
	* SML EXPOSURE GRAPH
	spmap sml_exposure if yr == 2025  using "$processed_data/coords_ent_mx.dta", id(ent_id) ///
		  ndfcolor(gs13) fcolor(Greens) ocolor(black ..) ///
		  legstyle(2) legend( size(*2) region(lwidth(none)))
	graph export "$output/Figures/sml_exp_`t'.png", replace

	* AI EXPOSURE GRAPH
	spmap ai_exposure if yr == 2025  using "$processed_data/coords_ent_mx.dta", id(ent_id) ///
		  ndfcolor(gs13) fcolor(Oranges) ocolor(black ..) ///
		  legstyle(2) legend( size(*2) region(lwidth(none)))
						   
	graph export "$output/Figures/ai_exp_`t'.png", replace
	
	restore 

}




