/* =====================================================

	AI Exposure Index Creation
	Gabriel Marin, Anahuac University
	gabriel.marinmu@anahuac.mx

	Note: This do-file follows Dani Rock's 2023 paper
	to create the impact of AI on tasks. The idea
	is to merge the labelling from ChatGPT to O*NET tasks
	then merge to SOC-ONET, and then compute an index
	of AI exposure according to the labelling.
	
	
	***** Can be refined by using importance and relevance
	directly from the O*NET database instead of their
	catalogue of Core and Supplemental.
	
	Need to verify collapse is being done properly as I
	collapse by SOC instead of ONET
	
====================================================== */
clear all
set more off

* Import database
global raw_data "/Users/gmm/Dropbox/ASU/Research/Technological Change MX/Data/Raw_Data"

* Import excel and save as dta
import excel "$raw_data/ONET/onet_tasks_labeled.xlsx", sheet("Sheet1") firstrow clear
keep TaskID Task TaskType ExposureLabel

* Save
save "$raw_data/ONET/onet_tasks_labeled.dta", replace


* Now import SOC*ONET Database
* Core (mean importance > 3.0 & relevance higher than 66%)
import excel "$raw_data/ONET/onet_task_statements.xlsx", firstrow clear

merge m:1 TaskID using "$raw_data/ONET/onet_tasks_labeled.dta", keepusing(ExposureLabel) nogen

* Transform variables to lowercase
ren *, lower
drop date incumbent domainsource

* Create soc code
gen soc = substr(onetsoccode,1,2) + "." + substr(onetsoccode,4,3) + "0"

* Here I will compute the AI exposure according to the paper
* Core tasks have a weight twice bigger than supplemental tasks

gen weight = 1 if tasktype == "Core"
replace weight = 0.5 if tasktype == "Supplemental"

* Some tasks are not yet fully evaluated by O*NET, remove them
drop if weight == .

* Create sum of weights
bys onetsoccode: egen weight_sum = total(weight)

* Change to E3 to E2 as in the paper (Image generating capabilities)
replace exposurelabel = "E2" if exposurelabel == "E3"

* Generate value assigned to each label
gen value = 1
replace value = 0 if exposurelabel == "E0"

* Generate weighted value as in the paper
* Alpha is just E1 (50% or more exposure)
gen alpha = value*(weight/weight_sum) if exposurelabel == "E1"
replace alpha = 0 if alpha == .

* Beta is E1 + 0.5*E2, which is already included in the weight
gen beta = value*(weight/weight_sum) 

* Gamma E1 + E2 (upper bound of exposure)
bys onetsoccode: egen weight_sumg = count(exposurelabel)
gen gamma = value/weight_sumg

* Collapse by occupation to obtain AI Exposure Measure 
collapse(sum) alpha beta gamma, by(onetsoccode soc title)

* Verify means, alpha must be around 15% according to paper
tabstat alpha beta gamma, stat(mean)

* Now drop 6 digit occupations
drop if substr(onetsoccode,9,10) != "00"

drop if soc == ""

* Collapse by soc, will need to assume equal weights for now
collapse(mean) alpha beta gamma, by(soc)


* Save dataset
save "$processed_data//ai_exposure.dta", replace

* Import excel that contains sector labelling by ChatGPT
import excel "$raw_data/ONET/occ_data_sectors_label.xlsx", firstrow clear

* Transform to lowercase
ren *, lower
* Create soc code
gen soc = substr(onetsoccode,1,2) + "." + substr(onetsoccode,4,3) + "0"

* Now drop 6 digit occupations
drop if substr(onetsoccode,9,10) != "00"

drop if soc == ""
* Keep relevant variables
keep soc category*

ren category_label occ_category

* Remove duplicates
duplicates drop

* There are 17 occupations that need manual labelling, the six digit ONET 
* had a different classification than the group itself.
* 51.3090 is production craft
* 51.4050 Pourers and Casters, Metal also prod craft
* Will keep second classification instead of the first

* 
bys soc: gen rank = _n
duplicates tag soc, gen(aux)

drop if rank == 1 & aux == 1
drop rank aux
* Save 
save "$processed_data//occ_category.dta", replace


















