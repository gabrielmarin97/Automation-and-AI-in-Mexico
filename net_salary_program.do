/* ===========================================================
	
	ENOE Net Salary Program
	Gabriel Marin, Anahuac University
	This program computes net salary from ENOE according to 
	survey year. Based in Rodrigo Razo's R code.
	
   =========================================================== */
   
	* Generate temporary variables that will be filed out
	cap gen tax = 0
	cap gen fee = 0
	cap gen bracket = 0

	* Setup upper bounds for each bracket (11 brackets in total)
	* Different tax rates and bound depending on fiscal year and ENOE
	
	if yr < 2008 {
		
		* --- Bracket 1
		local ub_b1   = 496.07
		local tax_b1  = 0.0192
		local fee_b1  = 0

		* --- Bracket 2
		local ub_b2   = 4210.41
		local tax_b2  = 0.064
		local fee_b2  = 9.52

		* --- Bracket 3
		local ub_b3   = 7399.42
		local tax_b3  = 0.1088
		local fee_b3  = 247.23

		* --- Bracket 4
		local ub_b4   = 8601.50
		local tax_b4  = 0.16
		local fee_b4  = 594.24

		* --- Bracket 5
		local ub_b5   = 10298.35
		local tax_b5  = 0.1792
		local fee_b5  = 786.55

		* --- Bracket 6
		local ub_b6   = 20770.29
		local tax_b6  = 0.2136
		local fee_b6  = 1090.62

		* --- Bracket 7
		local ub_b7   = 32736.83
		local tax_b7  = 0.2352
		local fee_b7  = 3327.42

		* --- Bracket 8
		local ub_b8   = 62500
		local tax_b8  = 0.30
		local fee_b8  = 6141.95

		* --- Bracket 9
		local ub_b9   = 83333.33
		local tax_b9  = 0.32
		local fee_b9  = 15070.90

		* --- Bracket 10
		local ub_b10  = 250000
		local tax_b10 = 0.34
		local fee_b10 = 21737.57

		* --- Bracket 11 (no upper bound)
		local ub_b11  = .
		local tax_b11 = 0.35
		local fee_b11 = 78404.23
	
	}
	
	else if inrange(yr, 2008, 2025) {

		* ---- Upper bounds (inclusive, except last which is open)
		local ub_b1   = 496.07
		local ub_b2   = 4210.41
		local ub_b3   = 7399.42
		local ub_b4   = 8601.50
		local ub_b5   = 10298.35
		local ub_b6   = 20770.29
		local ub_b7   = 32736.83
		local ub_b8   = 62500
		local ub_b9   = 83333.33
		local ub_b10  = 250000
		local ub_b11  = .

		* ---- Marginal rates
		local tax_b1  = 0.0192
		local tax_b2  = 0.064
		local tax_b3  = 0.1088
		local tax_b4  = 0.16
		local tax_b5  = 0.1792
		local tax_b6  = 0.2136
		local tax_b7  = 0.2352
		local tax_b8  = 0.30
		local tax_b9  = 0.32
		local tax_b10 = 0.34
		local tax_b11 = 0.35

		* ---- Fixed fee
		local fee_b1  = 0
		local fee_b2  = 9.52
		local fee_b3  = 247.23
		local fee_b4  = 594.24
		local fee_b5  = 786.55
		local fee_b6  = 1090.62
		local fee_b7  = 3327.42
		local fee_b8  = 6141.95
		local fee_b9  = 15070.90
		local fee_b10 = 21737.57
		local fee_b11 = 78404.23
	}
	
	
	* Fill in brackets for each individual of the household
	
	replace bracket = 1 if mon_inc > 0 & mon_inc < `ub_b1'
	
	forval i = 2/10 {
		local j = `i' - 1
		replace bracket = `i' if mon_inc >= `ub_b`j'' & mon_inc < `ub_b`i''
	}
	
	replace bracket = 11 if mon_inc >= `ub_b10'
	
	forval i = 1/11 {
		if `i' == 1 {
			replace tax = (mon_inc*`tax_b`i'') if bracket == `i'
			replace fee = `fee_b`i'' if bracket == `i'
		}
		else {
			local j = `i' - 1
			replace tax = (mon_inc - `ub_b`j'')*`tax_b`i'' if bracket == `i'
			replace fee = `fee_b`i'' if bracket == `i'
		}
	}
	

	