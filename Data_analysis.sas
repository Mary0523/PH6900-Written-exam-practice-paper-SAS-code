*Yinjiao Ma PHS6900 written exam practice assignments;
*Data analysis;
libname wexam "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam";
data dat;
   set wexam.NHANRS_2011_2014_final;
   if DIQ010=1 then DM="Yes";
   else if DIQ010 in ( 2 3 ) then DM="No";
run;

proc means data=dat n mean std stderr nmiss;
   where inclusion=1;
   var RIDAGEYR CERAD_imme CERAD_delay CFDAST CFDDS global_score_z;
   class sleep_duration;
   *ods output domain(match_all)=table1_means; 
run;

/*Table1. Demographic table*/
/*Total*/
proc surveymeans data=dat nobs mean std stderr;
   cluster sdmvpsu;
   stratum sdmvstra;
   var RIDAGEYR;
   weight wtmec4yr;
   domain inclusion;
run;
/*by sleep duration*/
proc surveymeans data=dat nobs mean std stderr;
   cluster sdmvpsu;
   stratum sdmvstra;
   class sleep_duration;
   var RIDAGEYR CERAD_imme CERAD_delay CFDAST CFDDS global_score_z;
   weight wtmec4yr;
   domain inclusion inclusion*sleep_duration;
   ods output domain=table1_means; 
run;
data table1_means2;
   set table1_means;
   where inclusion=1 and not missing(sleep_duration);
   output=cat(round(mean,0.01)," ","(",round(stderr,0.01),")");
run;

/*Total*/
proc surveyfreq data=dat;
   cluster sdmvpsu;
   stratum sdmvstra;
   weight wtmec4yr;
   tables inclusion*RIAGENDR inclusion*RIDRETH1
          inclusion*DMDEDUC2 inclusion*Depression
          inclusion*BPQ020 inclusion*DM/col;
   ods output crosstabs=table1_freq_total;
run;
data table1_freq_total2;
   set table1_freq_total;
   where inclusion=1 and _SkipLine NE "1" and ColPercent NE 100;
   output=cat(round(Frequency,0.01)," ","(",round(ColPercent,0.01),")");
   drop inclusion WgtFreq StdDev Percent StdErr _SkipLine;
run;

/*by sleep duration*/
proc surveyfreq data=dat;
   cluster sdmvpsu;
   stratum sdmvstra;
   weight wtmec4yr;
   tables inclusion*RIAGENDR*sleep_duration inclusion*RIDRETH1*sleep_duration
          inclusion*DMDEDUC2*sleep_duration inclusion*Depression*sleep_duration
          inclusion*BPQ020*sleep_duration inclusion*DM*sleep_duration/col;
   ods output crosstabs=table1_freq;
run;
data table1_freq2;
   set table1_freq;
   where inclusion=1 and not missing(ColPercent) and ColPercent NE 100;
   output=cat(round(Frequency,0.01)," ","(",round(ColPercent,0.01),")");
   drop inclusion F_sleep_duration WgtFreq StdDev Percent StdErr _SkipLine;
run;
proc sort data=table1_freq2;
   by sleep_duration;
run;

ODS csv file="C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\results\Table1_means.csv";
proc print data=table1_means2; run;
ODS csv close;
ODS csv file="C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\results\Table1_freqs.csv";
proc print data=table1_freq2; run;
ODS csv close;
ODS csv file="C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\results\Table1_freqs_total.csv";
proc print data=table1_freq_total2; run;
ODS csv close;

/*Chisq test for categorical variables*/
proc surveyfreq data=dat;
   cluster sdmvpsu;
   stratum sdmvstra;
   weight wtmec4yr;
   tables RIAGENDR*sleep_duration RIDRETH1*sleep_duration
          DMDEDUC2*sleep_duration Depression*sleep_duration
          BPQ020*sleep_duration DM*sleep_duration/col chisq;
   where inclusion=1;
run;
/*One-way ANOVA for continous variables*/
%let var=RIDAGEYR CERAD_imme CERAD_delay CFDAST CFDDS global_score_z;
%macro ANOVAt();
%do item=1 %to %sysfunc(countw(&var));
    %let _var=%scan(&var,&item);
PROC SURVEYREG data=dat nomcar;
   STRATA sdmvstra;
   CLUSTER sdmvpsu;
   WEIGHT wtmec4yr;
   CLASS sleep_duration;
   MODEL  &_var= sleep_duration/ANOVA;
   DOMAIN inclusion;
run; 
%end;
%mend ANOVAt;
%ANOVAt;


/*ANOVA test the association between cognition scores and sleep duration*/
/*Unadjusted models*/
%let var=CERAD_imme CERAD_delay CFDAST CFDDS global_score_z;
%macro unadj();
%do item=1 %to %sysfunc(countw(&var));
    %let _var=%scan(&var,&item);
PROC SURVEYREG data=dat nomcar;
   STRATA sdmvstra;
   CLUSTER sdmvpsu;
   WEIGHT wtmec4yr;
   CLASS sleep_duration;
   MODEL  &_var= sleep_duration/ANOVA;
   DOMAIN inclusion;
   lsmeans sleep_duration/pdiff adjust=tukey plot=meanplot(connect cl) lines;
   estimate "Short vs Recommendate"  sleep_duration 0 -1 1/cl;
   estimate "Long vs Recommendate"  sleep_duration 1 -1 0/cl;
   ODS output estimates=est;
run;
data est2;
   set est;
   where Domain="inclusion=1";
   out=cat(round(Estimate,0.01)," ","(",round(Lower,0.01),", ",round(Upper,0.01),")");
   type="&_var";
run;
%if &item=1 %then %do;
   data output; set est2; run;
%end;
%else %do;
   data output; set output est2; run;
%end;
%end;
%mend unadj;
%unadj;
proc sort data=output; by label; run;

ODS csv file="C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\results\Table3_unadjusted_models.csv";
proc print data=output; run;
ODS csv close;

/*Adjusted models*/
data dat2;
   set dat;
   if DMDEDUC2 in (7 9) then DMDEDUC2=.;
   if BPQ020 = 9 then BPQ020=.;
run;
%let var=CERAD_imme CERAD_delay CFDAST CFDDS global_score_z;
%macro adj();
%do item=1 %to %sysfunc(countw(&var));
    %let _var=%scan(&var,&item);
PROC SURVEYREG data=dat2 nomcar;
   STRATA sdmvstra;
   CLUSTER sdmvpsu;
   WEIGHT wtmec4yr;
   CLASS sleep_duration RIAGENDR RIDRETH1 DMDEDUC2 Depression BPQ020 DM;
   MODEL  &_var= sleep_duration RIDAGEYR RIAGENDR RIDRETH1 DMDEDUC2 Depression BPQ020 DM/solution;
   DOMAIN inclusion;
   estimate "Short vs Recommendate"  sleep_duration 0 -1 1/cl;
   estimate "Long vs Recommendate"  sleep_duration 1 -1 0/cl;
   ODS output estimates=est;
run;
data est2;
   set est;
   where Domain="inclusion=1";
   out=cat(round(Estimate,0.01)," ","(",round(Lower,0.01),", ",round(Upper,0.01),")");
   type="&_var";
run;
%if &item=1 %then %do;
   data output; set est2; run;
%end;
%else %do;
   data output; set output est2; run;
%end;
%end;
%mend adj;
%adj;
proc sort data=output; by label; run;

ODS csv file="C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\results\Table4_adjusted_models.csv";
proc print data=output; run;
ODS csv close;


/*Race as effect modification*/
/*PROC SURVEYREG data=dat2 nomcar;
   STRATA sdmvstra;
   CLUSTER sdmvpsu;
   WEIGHT wtmec4yr;
   CLASS sleep_duration RIAGENDR RIDRETH1 DMDEDUC2 Depression BPQ020 DM;
   MODEL  CFDDS = sleep_duration|RIDRETH1 RIDAGEYR RIAGENDR DMDEDUC2 Depression BPQ020 DM/solution;
   DOMAIN inclusion;
   estimate "Short vs Recommendate, among Mexican American"  sleep_duration 0 -1 1 sleep_duration*RIDRETH1 0 0 0 0 0
                                                                                                           -1 0 0 0 0
                                                                                                           1 0 0 0 0/cl;
   estimate "Long vs Recommendate, among Mexican American"  sleep_duration 1 -1 0 sleep_duration*RIDRETH1  1 0 0 0 0
                                                                                                           -1 0 0 0 0
                                                                                                           0 0 0 0 0/cl;
   estimate "Short vs Recommendate, among Other Hispanic"  sleep_duration 0 -1 1 sleep_duration*RIDRETH1   0 0 0 0 0
                                                                                                           0 -1 0 0 0
                                                                                                           0 1 0 0 0/cl;
   estimate "Long vs Recommendate, among Non-Hispanic White"  sleep_duration 1 -1 0 sleep_duration*RIDRETH1    0 1 0 0 0
                                                                                                           0 -1  0 0 0
                                                                                                           0 0 0 0 0/cl;
   estimate "Short vs Recommendate, among Non-Hispanic White"  sleep_duration 0 -1 1 sleep_duration*RIDRETH1   0 0 0 0 0
                                                                                                               0 0 -1 0 0
                                                                                                               0 0 1 0 0/cl;
   estimate "Long vs Recommendate, among Non-Hispanic White"  sleep_duration 1 -1 0 sleep_duration*RIDRETH1    0 0 1 0 0
                                                                                                               0 0 -1 0 0
                                                                                                               0 0 0 0 0/cl;
   estimate "Short vs Recommendate, among Non-Hispanic Black"  sleep_duration 0 -1 1 sleep_duration*RIDRETH1   0 0 0 0 0
                                                                                                               0 0 0 -1 0
                                                                                                               0 0 0 1 0/cl;
   estimate "Long vs Recommendate, among Non-Hispanic Black"  sleep_duration 1 -1 0 sleep_duration*RIDRETH1    0 0 0 1 0
                                                                                                               0 0 0 -1 0
                                                                                                               0 0 0 0 0/cl;
   ODS output estimates=est;
run;*/
