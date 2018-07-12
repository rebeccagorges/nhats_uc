**first .do file for data cleaning, nhats waves 1-6 combined file

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\nhats\logs
log using `logpath'1_nhats_setup1.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\nhats\data

cd `data'

use round_1_to_6.dta
*********************************************
tab wave, missing

*********************************************
//interview type, varies by wave, use tracker status variables
tab r3spstat if wave==3
tab r3status if wave==3

gen ivw_type=3
replace ivw_type=1 if r1spstat==20 & wave==1 

forvalues w = 2/6 {
	replace ivw_type=1 if (r`w'spstat==20 & r`w'status!=62) & wave==`w'
	replace ivw_type=2 if (r`w'spstat==20 & r`w'status==62) & wave==`w'
}

la def ivw_type 1 "Alive, SP interview completed" 2"Died, proxy SP LML interview completed" ///
	3"SP interview not completed"
la val ivw_type ivw_type
tab ivw_type wave, missing

tab r1status r1spstat if wave==1, missing
tab rdresid r1spstat if wave==1, missing

gen sp_ivw_yes=1 if r1spstat==20 & wave==1
replace sp_ivw_yes=0 if inlist(r1spstat,11,24) & wave==1

forvalues w = 2/6 {
	tab r`w'status r`w'spstat if wave==`w', missing
	replace sp_ivw_yes=1 if r`w'spstat==20 & wave==`w'
	replace sp_ivw_yes=0 if inlist(r`w'spstat,11,12,24) & wave==`w'
}
la var sp_ivw_yes "SP interview conducted? yes=1" //note this includes lml interviews
tab sp_ivw_yes wave, missing

gen lml_ivw_yes = 0
forvalues w = 2/6 {
	replace lml_ivw_yes=1 if r`w'spstat==20 & r`w'status==62 & wave==`w'
}
la var lml_ivw_yes "LWL interview? yes=1"

tab sp_ivw_yes lml_ivw_yes, missing
tab lml_ivw_yes wave, missing

tab mooutoft r2status if wave==2, missing
tab mooutoft r3status if wave==3, missing

//identify proxy SP interviews
gen proxy_ivw=.
replace proxy_ivw=1 if isresptype==2
replace proxy_ivw=0 if isresptype==1

la var proxy_ivw "Interview via proxy"
tab proxy_ivw wave, missing
tab proxy_ivw wave if ivw_type==1, missing
tab proxy_ivw wave if ivw_type==2, missing

/*missing data convention per user guide
For our purposes, code all as missing
The following codes were used at the item level for missing data of different types:
-7 = Refusal
-8 = Don’t Know
-1 = Inapplicable
-9 = Not Ascertained*/
global miss -9,-8,-7,-1

*********************************************
*********************************************
//definitions of homebound
*********************************************
*********************************************
//how often go out of the house?
tab mooutoft, missing
gen freq_go_out=mooutoft
replace freq_go_out=. if inlist(freq_go_out,$miss)
la def freq_go_out 1 "Every day" 2 "Most days (5-6/week)" ///
	3 "Some days (2-4/week)" 4 "Rarely" 5 "Never"
la val 	freq_go_out freq_go_out
la var freq_go_out "How often go outside"
tab freq_go_out sp_ivw_yes, missing
tab freq_go_out sp_ivw_yes if wave==1, missing
tab freq_go_out sp_ivw_yes if wave==2 & lml_ivw_yes==0, missing
tab freq_go_out sp_ivw_yes if wave==2 & lml_ivw_yes==1, missing
tab freq_go_out sp_ivw_yes if wave==3 & lml_ivw_yes==0, missing

tab freq_go_out wave if sp_ivw_yes==1, missing

//MO questions not asked in lml interviews where persons were not alert(PD6)
//or not mobile(PD7) in last month so lml has more missingless
tab freq_go_out mooutoft if wave==2 & lml_ivw_yes==1, missing

*********************************************
//Did anyone ever help you - asked if report going outside
//left missing if report never go outside
tab moouthlp, missing

gen help_go_out=.
replace help_go_out=1 if moouthlp==1
replace help_go_out=0 if moouthlp==2

la var help_go_out "Anyone ever help you leave home?"
tab help_go_out wave if sp_ivw_yes==1, missing

*********************************************
//go out of the house on own?
//only asked if report having help when go outside (help_go_out==1)
tab mooutslf, missing

gen out_on_own=.
replace out_on_own=mooutslf
replace out_on_own=. if inlist(out_on_own,$miss)
replace out_on_own=5 if help_go_out==0
replace out_on_own=6 if freq_go_out==5
la def out_on_own 1"Most times" 2"Sometimes" 3"Rarely" 4"Never"5"NA, reported no help" ///
6"NA, never left home"
la val out_on_own out_on_own
la var out_on_own "When left house, left by yourself?"
tab out_on_own wave if sp_ivw_yes==1, missing

*********************************************
//needs help when go outside? gets help and also goes outside on own != never
gen needshelp=0
replace needshelp=1 if help_go_out==1& out_on_own~=4
la var needshelp "Leaves home but with help"
tab needshelp wave, missing

*********************************************
//has difficulty? when you used your walker,cane,etc? how much difficulty
//did you have leaving the house by yourself? 1=none, 2=a little, 3=some, 4=a lot
//inapplicable if don't report using any device to help, so set to 0 here
tab mooutdif, missing
gen hasdifficulty=0
replace hasdifficulty=1 if inlist(mooutdif,2,3,4,-8)
replace hasdifficulty=0 if mooutdif==1
la var hasdifficulty "Leaves home on own but has difficulty"
tab hasdifficulty wave if sp_ivw_yes==1, missing

*********************************************
//needs help or has difficulty going outside?
gen helpdiff=.
replace helpdiff=0 if needshelp==0 & hasdifficulty==0
replace helpdiff=1 if needshelp==1 | hasdifficulty==1
la var helpdiff "Either needs help or has difficulty going outside"
tab helpdiff wave if sp_ivw_yes==1, missing
*********************************************
//independent - go out some/most days but are independent
gen independent=0
replace independent=1 if help_go_out==0 & hasdifficulty==0
la var independent "Independently leaves home"
tab independent wave if sp_ivw_yes==1, missing

tab independent helpdiff, missing //no overlap
*********************************************
/*homebound categories
0 = never go out
1 = rarely go out
2 = go out but never by self
3 = go out but need help/have difficulty
4 = go out, independent - don't need help or have difficulty
*/
gen homebound_cat=.
replace homebound_cat=0 if freq_go_out==5
replace homebound_cat=1 if freq_go_out==4
replace homebound_cat=2 if inlist(freq_go_out,3,2,1) & out_on_own==4
replace homebound_cat=3 if inlist(freq_go_out,3,2,1) & helpdiff==1
replace homebound_cat=4 if inlist(freq_go_out,3,2,1) & independent==1

la var homebound_cat "Homebound status, categorical"
la def hb 0 "Never leave home" 1 "Rarely leaves home" 2 "Leaves home but never by self" ///
3 "Leaves home but needs help/has difficulty" 4 "Independent, not homebound"
la val homebound_cat hb
tab homebound_cat wave if sp_ivw_yes==1, missing
*********************************************
/*subcategories for level 4 homeboud category
independent but go out only rarely
independent and go out frequently*/
gen indeplow=0
replace indeplow=1 if freq_go_out==3 & independent==1
la var indeplow "Independent, go out rarely" 

gen indephigh=0
replace indephigh=1 if inlist(freq_go_out,2,1) & independent==1
la var indephigh "Independent, go out often"

tab indeplow wave if sp_ivw_yes==1, missing
tab indephigh wave if sp_ivw_yes==1, missing

*********************************************
*********************************************
//demographic information
*********************************************
*********************************************
//age at interview, old code using sensitive data variables
/*
gen age=.
foreach w in 1 2{
	replace age=r`w'dintvwrage if wave==`w'
	sum age if wave==`w', detail
	}
//for last month of life interviews, use age at death variable
tab ivw_type if age==-1, missing
replace age=r2ddeathage if ivw_type==2 & r2dintvwrage==-1
sum age
//some observations that died still have missing age, so set to missing
tab ivw_type if inlist(age,-7,-8)
replace age=. if inlist(age,-7,-8)

la var age "Age at interview or death"
sum age if ivw_type==1, detail
sum age if ivw_type==2, detail
sum age, detail
	
	*/
tab wd2intvrage wave, missing

*age not provided for lml interviews
tab wd2intvrage wave if ivw_type==1, missing
tab wd2intvrage wave if ivw_type==2, missing
	
//gender, only asked in r1 and r5
tab r1dgender r5dgender, missing

gen female=.
replace female=1 if (r1dgender==2 & wave==1) | (r5dgender==2 & wave==5)
replace female=0 if (r1dgender==1 & wave==1) | (r5dgender==1 & wave==5)

la var female "Female"
la def female 0"Male" 1"Female"
la val female female
tab female wave, missing

tab rl1dracehisp, missing
tab rl5dracehisp, missing
//race, ethnicity
gen race_cat=rl1dracehisp if wave==1 
replace race_cat=rl5dracehisp if (wave==5 & race_cat==.) 
replace race_cat=3 if inlist(race_cat,5) 
replace race_cat=. if race_cat==6

label define race 1 "White Non-His" 2 "Black Non-His" 4 "Hispanic" ///
	3 "Other race"

label values race_cat race
la var race_cat "Race, categorical"
tab race_cat if wave==1, missing
tab race_cat if wave==5, missing
/*

//education
generate education=.
replace education=1 if inlist(el1higstschl,1,2,3)
replace education=2 if el1higstschl==4
replace education=3 if inlist(el1higstschl,5,6,7)
replace education=4 if inlist(el1higstschl,8,9)
replace education=5 if inlist(el1higstschl,-8,-7)

la var education "Education level, categorical"
label define edulbl 1 "<High School" 2 "High School/GED" 3 "Some College" ///
	4 ">=Bachelors" 5 "DK/RF"
label values education edulbl
tab education el1higstschl if wave==1, missing

//income, just wave 1
sum ia1totinc, detail //this is the actual reported income, only present 40% sample

forvalues i = 1/5{
replace ia1toincim`i'=. if inlist(ia1toincim`i',-9,-1)
sum ia1toincim`i',detail //imputed income variables
}

egen aveincome=rowmean(ia1toincim1-ia1toincim5)

//use first income imputation to set income categorical variable
gen income_cat=0 if ia1toincim1<15000 & ia1toincim1!=.
replace income_cat=1 if ia1toincim1>=15000 & ia1toincim1<30000 & ia1toincim1!=.
replace income_cat=2 if ia1toincim1>=30000 & ia1toincim1<60000 & ia1toincim1!=.
replace income_cat=3 if ia1toincim1>=60000 & ia1toincim1!=.
label define income_cat 0 "<15000" 1 "15-29,999" 2 "30-59,999" 3 ">60000"
label values income_cat income_cat
tab income_cat wave, missing

//speak language other than english?
gen otherlang=1 if rl1spkothlan==1
replace otherlang=0 if rl1spkothlan==2
la var otherlang "Speak language other than English?"
tab otherlang wave, missing

//fill in gender, race, education, income, etc. for wave 2 interviews
sort spid wave
by spid (wave): carryforward female race_cat education income_cat otherlang, replace

//marital status
//wave 2,3, use derived variable which is populated if not asked b/c no change 
gen maritalstat=hh1martlstat if wave==1
foreach w in 2 3{
	replace maritalstat=hh`w'dmarstat if wave==`w'
}
replace maritalstat=-7 if inlist(maritalstat,`miss')

la var maritalstat "Marital status"
label define maritallbl 1 "Married" 2 "Live w/Part" 3 "Separated" ///
	4 "Divorced" 5 "Widowed" 6 "Never Married" -7 "Missing"
la val maritalstat maritallbl
tab maritalstat wave, missing

*********************************************
*********************************************
//Insurance coverage
*********************************************
*********************************************
//medicaid status
gen medicaid=.
foreach w in 1 2 3{
	tab ip`w'cmedicaid if wave==`w' , missing
	replace medicaid=1 if ip`w'cmedicaid==1 & wave==`w'
	replace medicaid=0 if ip`w'cmedicaid==2 & wave==`w'
}
la var medicaid "Medicaid"
tab medicaid wave,missing
tab medicaid if wave==1 & ivw_type==1,missing
//medigap status
gen medigap=.
foreach w in 1 2 3{
	tab ip`w'mgapmedsp if wave==`w' , missing
	replace medigap=1 if ip`w'mgapmedsp==1 & wave==`w'
	replace medigap=0 if ip`w'mgapmedsp==2 & wave==`w'
}
la var medigap "Medigap"
tab medigap wave,missing

//medicare part d
gen mc_partd=.
foreach w in 1 2 3{
	tab ip`w'covmedcad if wave==`w' , missing
	replace mc_partd=1 if ip`w'covmedcad==1 & wave==`w'
	replace mc_partd=0 if ip`w'covmedcad==2 & wave==`w'
}
la var mc_partd "Medicare Part D"
tab mc_partd wave,missing

//tricare - va insurance
gen tricare=.
foreach w in 1 2 3{
	tab ip`w'covtricar if wave==`w' , missing
	replace tricare=1 if ip`w'covtricar==1 & wave==`w'
	replace tricare=0 if ip`w'covtricar==2 & wave==`w'
}
la var tricare "Tricare - veterans insurance"
tab tricare wave,missing

//long term care nursing home insurance, private
gen private_ltc=.
foreach w in 1 2 3{
	tab ip`w'nginsnurs if wave==`w' , missing
	replace private_ltc=1 if ip`w'nginsnurs==1 & wave==`w'
	replace private_ltc=0 if ip`w'nginsnurs==2 & wave==`w'
}
la var private_ltc "Private nursing home insurance"
tab private_ltc wave,missing

//if report nh insurance in prev wave, asked to verify still have it curr wave
foreach w in 2 3{
tab ip`w'nginslast if wave==`w' & ip`w'nginsnurs==-1, missing
replace private_ltc=1 if ip`w'nginslast==1 & ip`w'nginsnurs==-1 & wave==`w'
replace private_ltc=0 if ip`w'nginslast==2 & ip`w'nginsnurs==-1 & wave==`w'
}
tab private_ltc wave,missing

*********************************************
*********************************************
//Residence information
*********************************************
*********************************************
//residence physical structure variable only in wave 1
tab re1resistrct if wave==1, missing
tab re1resistrct ht1placedesc if wave==1, missing
//derived variable in waves 2, 3
tab re2dresistrct if wave==2, missing
//per user guide, need to fix this variable since incorrectly coded for 71 obs
replace re2dresistrct = re2newstrct if inlist(re2spadrsnew,1,3) & inlist(re2newstrct,1,2,3,4,91)

tab re3dresistrct if wave==3, missing

//housing type in each wave, however missing if same residence as prior wave
foreach w in 1 2 3{
tab ht`w'placedesc if wave==`w', missing
}

//if missing housing type in waves 2,3, backfill with wave 1 info
//get indicators for moving in waves 2 or 3
tab re2dadrscorr, missing

gen w2_moved=1 if re2dadrscorr==2
replace w2_moved=0 if re2dadrscorr==1 | re2dadrscorr==3
tab w2_moved

tab re3spadrsnew, missing
gen w3_moved=1 if re3spadrsnew==2
replace w3_moved=0 if re3spadrsnew==1 | re3spadrsnew==3
tab w3_moved

gen ht_new=.
foreach w in 1 2 3{
replace ht_new=ht`w'placedesc if wave==`w'
}

foreach w in 2 3{
replace ht_new=. if ht`w'placedesc==-1 & w`w'_moved==0
}

tab ht_new wave, missing

sort spid wave
by spid (wave): carryforward ht_new, replace

tab ht_new wave, missing

//most residence information from wave 1
//used derived variables wave 2,3
gen residence=.
replace residence=re1resistrct if wave==1
replace residence=re2dresistrct if wave==2
replace residence=re3dresistrct if wave==3
replace residence=3 if inlist(residence,4,91)

tab residence wave

//now overwrite with the new housing type description as done in orig code
replace residence=1 if ht_new==1
replace residence=2 if inlist(ht_new,2,3,4,91)
replace residence=. if inlist(residence,-9,-1)
tab residence wave, missing

label define residlbl 1 "Private Res." 2 "Group Home/Facility" ///
	3 "Mobile Home/Multi-Unit"
label values residence residlbl
tab residence if wave==1, missing
tab residence if wave==2, missing
tab residence if wave==3, missing

***********************************************************
//living arrangement, NHATS derived variable
gen livearrang=.
foreach w in 1 2 3{
tab hh`w'dlvngarrg if wave==`w' & ivw_type==1, missing
replace livearrang=hh`w'dlvngarrg if wave==`w'
replace livearrang=1 if (hh`w'dlvngarrg==-9 & hh`w'dhshldnum==1)  & wave==`w'
}
replace livearrang=. if livearrang==-1 

la var livearrang "Living arrangmeent, categorical"
la def livearrang 1 "Alone" 2 "With spouse/partner" ///
	3"With spouse/partner + others" 4 "With others"
la val livearrang livearrang
tab livearrang wave if ivw_type==1, missing

//live alone?
gen livealone=1 if livearrang==1
replace livealone=0 if inlist(livearrang,2,3,4)
la var livealone "Lives alone"
tab livealone livearrang, missing

save round_1_3_cleanv1.dta, replace
*********************************************
log close
