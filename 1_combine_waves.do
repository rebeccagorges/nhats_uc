/*Combines rounds 1-6 sample person SP interview files,
and urban/rural rounds 1-6 file into single dataset

Data format is multiple observations per subject, one for each round
*/

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\nhats\logs
log using `logpath'1_nhats_setup1.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\nhats\data

cd `data'
*********************************************

capture program drop step1
program define step1
	args r name
	use raw/NHATS_R`r'/`name'
	//check to make sure sample ids are unique
	sort spid 
	quietly by spid: gen dup = cond(_N==1,0,_n)
	tab dup
	gen wave=`r'
	la var wave "Survey wave"
	save round_`r'_1.dta, replace
	clear
end 

step1 1 NHATS_Round_1_SP_File.dta 
step1 2 NHATS_Round_2_SP_File_v2.dta  
step1 3 NHATS_Round_3_SP_File.dta  
step1 4 NHATS_Round_4_SP_File.dta  
step1 5 NHATS_Round_5_SP_File_v2.dta  
step1 6 NHATS_Round_6_SP_File_V2.dta  

//round 1-6
forvalues w = 1/6 {
use round_`w'_1.dta, clear

//keep selected variables only
local keepallwaves spid wave r`w'dresid w`w'varunit w`w'anfinwgt0 w`w'varstrat  ///
	mo`w'out* r`w'd2intvrage hh`w'martlstat ///
	ip`w'cmedicaid ip`w'mgapmedsp ip`w'nginsnurs ip`w'covmedcad ip`w'covtricar ///
	hh* hc* ss* pc* cp* cg* ha* sc* mc* sd* ///
	is`w'resptype ht`w'placedesc

if `w'==1 {	
keep `keepallwaves' r`w'dgender rl`w'dracehisp rl`w'spkothlan el`w'higstschl ///
ia`w'toincim1-ia`w'toincim5 ia1totinc re`w'resistrct
}

if `w'==2 {	
keep `keepallwaves' re2intplace re2newstrct re2spadrsnew re2dresistrct ///
	re2dadrscorr re2dcensdiv ip2nginslast
}

if `w'==3 {	
keep `keepallwaves' re3intplace re3newstrct re3spadrsnew re3dresistrct ///
	re3dcensdiv ip3nginslast
}



save round_`w'_ltd.dta, replace
}

//combine 3 waves into single dataset
use round_1_ltd.dta
forvalues w= 2/6{
append using round_`w'_ltd.dta
}

save round_1_to_6.dta, replace

*********************************************
log close
