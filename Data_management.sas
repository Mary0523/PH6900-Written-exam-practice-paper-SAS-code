*Yinjiao Ma PHS6900 written exam practice assignments;
/*2011-2012 data*/
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2011-2012 data\DEMO_g.xpt";
proc copy inlib=xptfile outlib=work;
run;
*demographic codebook: https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/DEMO_H.htm;
*read in cognitive variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2011-2012 data\CFQ_g.xpt";
proc copy inlib=xptfile outlib=work;
run;
*cognitive variable codebook: https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/CFQ_H.htm;
*read in sleep variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2011-2012 data\SLQ_g.xpt";
proc copy inlib=xptfile outlib=work;
run;
*sleep variables codebook: https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/SLQ_H.htm;
*read in blood pressure variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2011-2012 data\BPQ_g.xpt";
proc copy inlib=xptfile outlib=work;
run;
*read in Depression variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2011-2012 data\DPQ_g.xpt";
proc copy inlib=xptfile outlib=work;
run;
*read in Diabetes variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2011-2012 data\DIQ_g.xpt";
proc copy inlib=xptfile outlib=work;
run;
/*Merge the above datasets together*/
data DEMO_G;
   set DEMO_G;
   keep SEQN RIDAGEYR RIAGENDR RIDRETH1 DMDEDUC2 INDHHIN2 WTMEC2YR SDMVPSU SDMVSTRA;
run;
proc sql;
   create table DEMO_CFQ as
   select a.*,b.*
   from DEMO_G as a
      left join CFQ_G as b
	     on a.SEQN=b.SEQN;
quit;
proc sql;
   create table DEMO_CFQ_SLQ as
   select a.*,b.*
   from DEMO_CFQ as a
      left join SLQ_G as b
	     on a.SEQN=b.SEQN;
quit;
proc sql;
   create table DEMO_CFQ_SLQ2 as
   select a.*,b.BPQ020 /*Ever told you had high blood pressure*/
   from DEMO_CFQ_SLQ as a
      left join BPQ_G as b
	     on a.SEQN=b.SEQN;
quit;
proc sql;
   create table DEMO_CFQ_SLQ3 as
   select a.*,b.DIQ010/*Doctor told you have diabetes*/
   from DEMO_CFQ_SLQ2 as a
      left join DIQ_G as b
	     on a.SEQN=b.SEQN;
quit;
proc sql;
   create table DEMO_CFQ_SLQ4 as
   select a.*,b.*
   from DEMO_CFQ_SLQ3 as a
      left join DPQ_G as b
	     on a.SEQN=b.SEQN;
quit;
/*All participants in the CFQ dataset are age 60 and older*/
/*Create a varaible for depressive disorder*/
Data DEMO_CFQ_SLQ5;
   set DEMO_CFQ_SLQ4;
   array dep{9} DPQ010--DPQ090;
   do i=1 to 9;
      if dep{i} in (7 9) then dep{i}=.;
   end;
   drop i;
Run;
Data DEMO_CFQ_SLQ5;
   set DEMO_CFQ_SLQ5;
   array dep{8} DPQ010--DPQ080;
   array dep2{8} DPQ010_n DPQ020_n DPQ030_n DPQ040_n DPQ050_n DPQ060_n DPQ070_n DPQ080_n;
   do i=1 to 8;
      if dep[i] in (2 3) then dep2[i]=1;
	  else if dep[i] =0 then dep2[i]=0;
   end;
   drop i;
   if DPQ090 in (1 2 3) then DPQ090_n=1;
   else if DPQ090=0 then DPQ090_n=0;
Run;
Data DEMO_CFQ_SLQ5;
   set DEMO_CFQ_SLQ5;
   Dep_total=sum(DPQ010_n, DPQ020_n, DPQ030_n, DPQ040_n, DPQ050_n, DPQ060_n, DPQ070_n, DPQ080_n, DPQ090_n);
   if Dep_total>=4 then Depression="Yes";
   else if 0<=Dep_total<4 then Depression="No";
Run;
proc freq data=DEMO_CFQ_SLQ5;
   tables Dep_total Depression;
run;

/*Create a indicator variable to indicate data analysis inclusion*/
/*Use the whole demographic data to make the using of weight variable WTMEC2YR valid*/
Data DEMO_CFQ_SLQ6;
   set DEMO_CFQ_SLQ5;
   if CFASTAT=1 and not missing(CFDCSR) and not missing(CFDCST1) and not missing(CFDCST2) and not missing(CFDCST3)
      and not missing(CFDAST) and not missing(CFDDS) and SLD010H NE 99 and not missing(SLD010H)/*People who have both 3 cogintive tests and sleep variable value:1359*/
      and BPQ020 in (1 2) and DIQ010 in (1 2 3) and not missing(Depression)/*People also have blood presure, diabetes, and depression value:1341*/
	  and not missing(RIAGENDR) and not missing(RIDAGEYR) and not missing(RIDRETH1) and DMDEDUC2 in (1 2 3 4 5) /*People also have demographic value:1339*/
   then inclusion=1;
   else inclusion=0;
Run;
/*SLQ050 - Ever told doctor had trouble sleeping?*/
proc freq data=DEMO_CFQ_SLQ6;
   tables inclusion;
run;
/*Create variables: CERAD immediate learning ability for new verbal information
                      CERAD delayed learning ability for new verbal information
                      Classifiy sleep duration into 3 categories: short(less than 7 hours), recommended(7-9 hours), long(more than 9 hours*/
data analysis_dat;
   set DEMO_CFQ_SLQ6;
   CERAD_imme=(CFDCST1+CFDCST2+CFDCST3)/3;
   CERAD_delay=CFDCSR;

   if SLD010H < 7 then sleep_duration="Short";
   else if 7<= SLD010H <= 9 then sleep_duration="Recom";
   else if SLD010H > 9 then sleep_duration="Long"; /*https://www.cdc.gov/sleep/about_sleep/how_much_sleep.html*/
run;
/*Create variables: convert the cognitive test score into z score
                    calculate global cognitive score
Calculiont method adapted from: Longitudinal relationships among biomarkers for Alzheimer disease in the Adult Children Study*/
proc means data=analysis_dat mean std;
  var  CERAD_imme CERAD_delay CFDAST CFDDS;
run;
/*creat z score for each test score*/
data analysis_dat2;
   set analysis_dat;
   CERAD_imme_z=CERAD_imme;
   CERAD_delay_z=CERAD_delay;
   CFDAST_z=CFDAST;
   CFDDS_z=CFDDS;
run;
PROC STANDARD DATA=analysis_dat2 MEAN=0 STD=1 OUT=analysis_dat3;
  VAR CERAD_imme_z CERAD_delay_z CFDAST_z CFDDS_z;
RUN;
proc means data=analysis_dat3 mean std;
  var  CERAD_imme_z CERAD_delay_z CFDAST_z CFDDS_z;
run;
data Dat_2011_2012;
   set analysis_dat3;
   global_score_z=(CERAD_imme_z + CERAD_delay_z + CFDAST_z + CFDDS_z)/4;
run;

/*2013-2014 data*/
*read in demographic variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2013-2014 data\DEMO_h.xpt";
proc copy inlib=xptfile outlib=work;
run;
*demographic codebook: https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/DEMO_H.htm;
*read in cognitive variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2013-2014 data\CFQ_h.xpt";
proc copy inlib=xptfile outlib=work;
run;
*cognitive variable codebook: https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/CFQ_H.htm;
*read in sleep variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2013-2014 data\SLQ_h.xpt";
proc copy inlib=xptfile outlib=work;
run;
*sleep variables codebook: https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/SLQ_H.htm;
*read in blood pressure variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2013-2014 data\BPQ_h.xpt";
proc copy inlib=xptfile outlib=work;
run;
*read in Depression variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2013-2014 data\DPQ_h.xpt";
proc copy inlib=xptfile outlib=work;
run;
*read in Diabetes variables;
libname xptfile Xport "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam\NHANES 2013-2014 data\DIQ_h.xpt";
proc copy inlib=xptfile outlib=work;
run;
/*Merge the above datasets together*/
data DEMO_H;
   set DEMO_H;
   keep SEQN RIDAGEYR RIAGENDR RIDRETH1 DMDEDUC2 INDHHIN2 WTMEC2YR SDMVPSU SDMVSTRA;
run;
proc sql;
   create table DEMO_CFQ as
   select a.*,b.*
   from DEMO_H as a
      left join CFQ_H as b
	     on a.SEQN=b.SEQN;
quit;
proc sql;
   create table DEMO_CFQ_SLQ as
   select a.*,b.*
   from DEMO_CFQ as a
      left join SLQ_H as b
	     on a.SEQN=b.SEQN;
quit;
proc sql;
   create table DEMO_CFQ_SLQ2 as
   select a.*,b.BPQ020 /*Ever told you had high blood pressure*/
   from DEMO_CFQ_SLQ as a
      left join BPQ_H as b
	     on a.SEQN=b.SEQN;
quit;
proc sql;
   create table DEMO_CFQ_SLQ3 as
   select a.*,b.DIQ010/*Doctor told you have diabetes*/
   from DEMO_CFQ_SLQ2 as a
      left join DIQ_H as b
	     on a.SEQN=b.SEQN;
quit;
proc sql;
   create table DEMO_CFQ_SLQ4 as
   select a.*,b.*
   from DEMO_CFQ_SLQ3 as a
      left join DPQ_H as b
	     on a.SEQN=b.SEQN;
quit;
/*All participants in the CFQ dataset are age 60 and older*/
/*Create a varaible for depressive disorder*/
Data DEMO_CFQ_SLQ5;
   set DEMO_CFQ_SLQ4;
   array dep{9} DPQ010--DPQ090;
   do i=1 to 9;
      if dep{i} in (7 9) then dep{i}=.;
   end;
   drop i;
Run;
Data DEMO_CFQ_SLQ5;
   set DEMO_CFQ_SLQ5;
   array dep{8} DPQ010--DPQ080;
   array dep2{8} DPQ010_n DPQ020_n DPQ030_n DPQ040_n DPQ050_n DPQ060_n DPQ070_n DPQ080_n;
   do i=1 to 8;
      if dep[i] in (2 3) then dep2[i]=1;
	  else if dep[i] =0 then dep2[i]=0;
   end;
   drop i;
   if DPQ090 in (1 2 3) then DPQ090_n=1;
   else if DPQ090=0 then DPQ090_n=0;
Run;
Data DEMO_CFQ_SLQ5;
   set DEMO_CFQ_SLQ5;
   Dep_total=sum(DPQ010_n, DPQ020_n, DPQ030_n, DPQ040_n, DPQ050_n, DPQ060_n, DPQ070_n, DPQ080_n, DPQ090_n);
   if Dep_total>=4 then Depression="Yes";
   else if 0<=Dep_total<4 then Depression="No";
Run;
proc freq data=DEMO_CFQ_SLQ5;
   tables Dep_total Depression;
run;

/*Create a indicator variable to indicate data analysis inclusion*/
/*Use the whole demographic data to make the using of weight variable WTMEC2YR valid*/
Data DEMO_CFQ_SLQ6;
   set DEMO_CFQ_SLQ5;
   if CFASTAT=1 and not missing(CFDCIR) and not missing(CFDAST) and not missing(CFDDS) and SLD010H NE 99 and not missing(SLD010H)/*People who have both 3 cogintive tests and sleep variable value:1569*/
      and BPQ020 in (1 2) and DIQ010 in (1 2 3) and not missing(Depression)/*People also have blood presure, diabetes, and depression value:1532*/
	  and not missing(RIAGENDR) and not missing(RIDAGEYR) and not missing(RIDRETH1) and DMDEDUC2 in (1 2 3 4 5) /*People also have demographic value:1531*/
   then inclusion=1;
   else inclusion=0;
Run;
/*SLQ050 - Ever told doctor had trouble sleeping?*/
proc freq data=DEMO_CFQ_SLQ6;
   tables inclusion;
run;
/*Create variables: CERAD immediate learning ability for new verbal information
                      CERAD delayed learning ability for new verbal information
                      Classifiy sleep duration into 3 categories: short(less than 7 hours), recommended(7-9 hours), long(more than 9 hours*/
data analysis_dat;
   set DEMO_CFQ_SLQ6;
   CERAD_imme=(CFDCST1+CFDCST2+CFDCST3)/3;
   CERAD_delay=CFDCSR;

   if SLD010H < 7 then sleep_duration="Short";
   else if 7<= SLD010H <= 9 then sleep_duration="Recom";
   else if SLD010H > 9 then sleep_duration="Long"; /*https://www.cdc.gov/sleep/about_sleep/how_much_sleep.html*/
run;
/*Create variables: convert the cognitive test score into z score
                    calculate global cognitive score
Calculiont method adapted from: Longitudinal relationships among biomarkers for Alzheimer disease in the Adult Children Study*/
proc means data=analysis_dat mean std;
  var  CERAD_imme CERAD_delay CFDAST CFDDS;
run;
/*creat z score for each test score*/
data analysis_dat2;
   set analysis_dat;
   CERAD_imme_z=CERAD_imme;
   CERAD_delay_z=CERAD_delay;
   CFDAST_z=CFDAST;
   CFDDS_z=CFDDS;
run;
PROC STANDARD DATA=analysis_dat2 MEAN=0 STD=1 OUT=analysis_dat3;
  VAR CERAD_imme_z CERAD_delay_z CFDAST_z CFDDS_z;
RUN;
proc means data=analysis_dat3 mean std;
  var  CERAD_imme_z CERAD_delay_z CFDAST_z CFDDS_z;
run;
data Dat_2013_2014;
   set analysis_dat3;
   global_score_z=(CERAD_imme_z + CERAD_delay_z + CFDAST_z + CFDDS_z)/4;
run;
proc means data=analysis_dat3 mean std;
  var  CERAD_imme_z CERAD_delay_z CFDAST_z CFDDS_z global_score_z;
run;
/*create variable ever told doctor had trouble sleeping or ever told by doctor have sleep disorder*/

/*Combine 2011-2012 and 2013-2014 data and create new weighting variable*/
Data all;
   set Dat_2011_2012 Dat_2013_2014;
   WTMEC4YR=WTMEC2YR/2;
run;
/*Final data: will use 2870 participants for data analysis*/
libname wexam "C:\Users\mayinjiao\Box\SLU courses\PHS6900\Practice written exam";
data wexam.NHANRS_2011_2014_final;
   set all;
run;

/*data all;
   set all;
   if SLQ050=1 or SLQ060=1 then ever_sleep_problem="Yes";
   else if SLQ050=2 and SLQ060=2 then ever_sleep_problem="No";
   where SLQ060 NE 9;
run;
proc freq data=all;
   tables SLQ050 SLQ060 ever_sleep_problem;
   where inclusion=1;
run;*/
/*
proc sgplot data=analysis_dat3;
   scatter x=SLD010H y=CERAD_imme_z;
   where inclusion=1;
run;
proc glm data=analysis_dat3;
   class sleep_duration;
   model CERAD_imme = sleep_duration/solution;
   estimate "Short vs Recommendate"  sleep_duration 0 -1 1;
   estimate "Long vs Recommendate"  sleep_duration 1 -1 0;
   estimate "Long vs Short" sleep_duration 1 0 -1;
   where inclusion=1;
quit;
proc glm data=all;
   class SLQ060;
   model CFDAST = SLQ060/solution;
   where inclusion=1;
quit;
proc glm data=all;
   class SLQ050;
   model CFDAST = SLQ050/solution;
   where inclusion=1;
quit;
proc glm data=all;
   class ever_sleep_problem;
   model CFDAST = ever_sleep_problem/solution;
   where inclusion=1;
quit;
*/
 /*Results not significant*/
