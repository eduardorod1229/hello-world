clear all
cd "K:\Documents\PhD\Epi Methods III\Homework"


/*** Set up ***/

set seed 265
set obs 200

/*** Town level variables ***/

gen townid = _n
gen t_pov = rnormal()
gen t_numhh = int(1000+(runiform() - .5)*1000)
expand t_numhh

/*** Household level variables ***/

bysort townid: generate hhid= _n
gen h_pov = t_pov+rnormal()*.5
gen h_numpeople=round(1+rgamma(1,1))
expand h_numpeople

/***Individual level variables ***/

bysort townid (hhid): generate id = _n
gen r_educ = int(12+rnormal()*1.5-2*h_pov)
recode r_educ(1/8=0) (9/10 = 1)(11/12=2) (13/max = 3), gen(r_edcat)
gen r_health = .1*r_educ-0.05*h_pov-.2*t_pov + rnormal()



save simpop, replace



/*** Random sample***/

set seed 265

sample 10

/*** Unweighted ***/
generate wt=10
tabstat r_health, stat(N mean sd semean var)
char r_edcat[omit]3
xi: regress r_health i.r_edcat

/*** Weighted ***/
xi: tabstat r_health [aweight=10], stat (N mean sd semean var)
char r_edcat[omit]3
xi: regress r_health i.r_edcat [pweight=10]


save rand_sample, replace

/***Clustered sample***/
use simpop, clear
set seed 265


gen rnumber = runiform(0,1)
gen insample = 1 if rnumber < 0.2
bysort townid : replace insample=insample[1]
keep if insample == 1 
drop rnumber
save clust_sample, replace

/***Stratifying by education ***/

tabulate r_edcat

recode r_edcat (0 = 1 "=< 8 years ed")(1/3 = 2 "9 years ed"), gen(r_edstrat)
sample 9400 if r_edstrat==1, count
sample 29000 if r_edstrat==2, count
tabulate r_edcat
save samp_pop, replace

/***Unweigthed measures ***/
tabstat r_health, stat(N mean sd semean var)
char r_edcat[omit]3
xi: regress r_health i.r_edcat

/***Weighted measures ***/

gen r_weights = 1/(0.2*(29000/64224)) if r_edstrat==2
replace r_weights = 1/(0.2*(9400/10602)) if r_edstrat==1  

svyset [pweight=r_weights]
svy: mean r_health
// svy: char r_edcat[omit]3

svy: regress r_health ib3.r_edcat, baselevel

/***Weighted and clustered measures***/


svyset townid [pweight=r_weights]
svy: mean r_health
svy: regress r_health ib3.r_edcat, baselevel

/*** Weights + Clusters + Strata ***/
gen fpc = 384000
svyset townid [pweight=r_weights], fpc(fpc) strata(r_edstrat)
svy: mean r_health
svy: regress r_health ib3.r_edcat, baselevel

/*** Extra edit ***/









