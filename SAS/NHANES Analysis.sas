libname nh1516d xport "/home/ejanettygallarde0/NHANES/DEMO_I.XPT";
libname nh1718d xport "/home/ejanettygallarde0/NHANES/DEMO_J.XPT";
libname nh1516bp xport "/home/ejanettygallarde0/NHANES/BPX_I.XPT";
libname nh1718bp xport "/home/ejanettygallarde0/NHANES/BPXO_J.XPT";
libname nh1516di xport "/home/ejanettygallarde0/NHANES/GHB_I.XPT";
libname nh1718di xport "/home/ejanettygallarde0/NHANES/GHB_J.XPT";

data demo_1516 (keep=seqn sddsrvyr riagendr ridageyr ridreth3 sdmvstra sdmvpsu ridexprg WTMEC2YR WTINT2YR);
    set nh1516d.DEMO_I;
run;

data bp_1516 (keep=seqn BPXSY1 BPXSY2 BPXSY3 BPXDI1 BPXDI2 BPXDI3);
    set nh1516bp.BPX_I;
run;

data dia_1516 (keep=seqn LBXGH);
    set nh1516di.GHB_I;
run;

data demo_1718 (keep=seqn sddsrvyr riagendr ridageyr ridreth3 sdmvstra sdmvpsu ridexprg WTMEC2YR WTINT2YR);
    set nh1718d.DEMO_J;
run;

data bp_1718 (keep=seqn BPXOSY1 BPXOSY2 BPXOSY3 BPXODI1 BPXODI2 BPXODI3);
    set nh1718bp.BPXO_J;
run;

data dia_1718 (keep=seqn LBXGH);
    set nh1718di.GHB_J;
run;

proc sort data=demo_1516; by SEQN; run;
proc sort data=bp_1516; by SEQN; run;
proc sort data=dia_1516; by SEQN; run;

proc sort data=demo_1718; by SEQN; run;
proc sort data=bp_1718; by SEQN; run;
proc sort data=dia_1718; by SEQN; run;

data nhanes_1516;
    merge demo_1516 bp_1516 dia_1516;
    by SEQN;
run;

data nhanes_1718;
    merge demo_1718 bp_1718 dia_1718;
    by SEQN;
run;

data nhanes_1516_clean;
    set nhanes_1516;
    if nmiss(of BPXSY1 BPXSY2 BPXSY3 BPXDI1 BPXDI2 BPXDI3 LBXGH) = 0 then do;
        Avg_BPXSY = mean(of BPXSY1-BPXSY3);
        Avg_BPXDI = mean(of BPXDI1-BPXDI3);
        cycle = '2015-2016';
        output;
    end;
run;

data nhanes_1718_clean;
    set nhanes_1718;
    if nmiss(of BPXOSY1 BPXOSY2 BPXOSY3 BPXODI1 BPXODI2 BPXODI3 LBXGH) = 0 then do;
        Avg_BPXSY = mean(of BPXOSY1-BPXOSY3);
        Avg_BPXDI = mean(of BPXODI1-BPXODI3);
        cycle = '2017-2018'; 
        output;
    end;
run;

data nhanes_combined;
    set nhanes_1516_clean nhanes_1718_clean;
run;

data nhanes_combined;
    set nhanes_combined;

    if Avg_BPXSY < 120 and Avg_BPXDI < 80 then BP_Category = 'BP0';
    else if Avg_BPXSY >= 120 and Avg_BPXDI < 130 and Avg_BPXDI < 80 then BP_Category = 'BP1';
    else if (Avg_BPXSY >= 130 and Avg_BPXSY < 140) or (Avg_BPXDI >= 80 and Avg_BPXDI < 90) then BP_Category = 'BP2';
    else if Avg_BPXSY >= 140 or Avg_BPXDI >= 90 then BP_Category = 'BP3';

    if LBXGH < 5.7 then Glucose_Category = 'DIA0';
    else if LBXGH >= 5.7 and LBXGH < 6.5 then Glucose_Category = 'DIA1';
    else if LBXGH >= 6.5 then Glucose_Category = 'DIA2';

    if RIDRETH3 = 1 then Race_Category = 'MexAm';
    else if RIDRETH3 = 2 then Race_Category = 'OHis';
    else if RIDRETH3 = 3 then Race_Category = 'NH White';
    else if RIDRETH3 = 4 then Race_Category = 'NH Black';
    else if RIDRETH3 = 6 then Race_Category = 'Others';

    if RIDAGEYR < 12 then Age_Category = 'AgeCat1';
    else if 12 <= RIDAGEYR < 18 then Age_Category = 'AgeCat2';
    else if 18 <= RIDAGEYR < 60 then Age_Category = 'AgeCat3';
    else if RIDAGEYR >= 60 then Age_Category = 'AgeCat4';
    
    if sddsrvyr in (9,10) then MEC4YR = 1/2 * WTMEC2YR; 
run;

data nhanes_combined;
    set nhanes_combined;

    if BP_Category in ('BP2', 'BP3') then HTN_Binary = 1;
    else if BP_Category in ('BP0', 'BP1') then HTN_Binary = 0;

    if Glucose_Category = 'DIA2' then Diabetes_Binary = 1;
    else if Glucose_Category in ('DIA0', 'DIA1') then Diabetes_Binary = 0;

    if HTN_Binary = 1 and Diabetes_Binary = 0 then Condition_Group = 'HTN only';
    else if HTN_Binary = 0 and Diabetes_Binary = 1 then Condition_Group = 'Diabetes only';
    else if HTN_Binary = 1 and Diabetes_Binary = 1 then Condition_Group = 'HTN-DIA';
    else if HTN_Binary = 0 and Diabetes_Binary = 0 then Condition_Group = 'Neither';
run;

proc freq data=nhanes_combined;
    tables HTN_Binary Diabetes_Binary BP_Category;
run;

proc surveymeans data=nhanes_combined mean stddev min max;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    var Avg_BPXSY Avg_BPXDI LBXGH;
run;

proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables cycle*Age_Category*Race_Category*HTN_Binary*Condition_Group / row cl;
run;

proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables cycle*Age_Category*Race_Category*Diabetes_Binary*Condition_Group / row cl;
run;

proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables Race_Category*Glucose_Category / chisq;
run;

proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables Race_Category*BP_Category / chisq;
run;

proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables Age_Category*Glucose_Category / chisq;
run;




proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables RIAGENDR*BP_Category / chisq;
run;

proc surveylogistic data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    class Race_Category Age_Category RIAGENDR;
    model Diabetes_Binary(event='1') = Race_Category Age_Category RIAGENDR;
run;

proc surveylogistic data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    class Race_Category Age_Category RIAGENDR;
    model HTN_Binary(event='1') = Race_Category Age_Category RIAGENDR;
run;

proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables cycle*Condition_Group*RIAGENDR*Race_Category / row cl;
run;

proc freq data=nhanes_combined;
    tables cycle*Condition_Group;
run;

proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables cycle*Condition_Group / chisq;
run;

/* Correlation Studies */


proc surveyreg data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    model LBXGH = Avg_BPXSY Avg_BPXDI RIDAGEYR;
run;

/* Visualizations */

/* Scatter plots for correlation studies */


proc sgscatter data=nhanes_combined;
    title "Scatter Plot for Avg_BPXSY vs LBXGH";
    plot Avg_BPXSY*LBXGH / grid;
run;


/* Bar charts for categorical variables */
proc sgplot data=nhanes_combined;
    title "Bar Chart for Blood Pressure Categories";
    vbar BP_Category / response=Avg_BPXSY stat=mean;
run;

proc sgplot data=nhanes_combined;
    title "Bar Chart for Glucose Categories";
    vbar Glucose_Category / response=LBXGH stat=mean;
run;

proc sgplot data=nhanes_combined;
    title "Bar Chart for Race Categories";
    vbar Race_Category / response=Avg_BPXSY stat=mean;
run;

proc sgpanel data=nhanes_combined;
    panelby cycle;
    vbar Age_Category / response=HTN_Binary stat=percent group=Race_Category groupdisplay=cluster;
    rowaxis label="Prevalence (%)";
    colaxis label="Age Category";
    title "Prevalence of Hypertension by Age, Race, and Condition Group";
run;

proc sgpanel data=nhanes_combined;
    panelby cycle;
    vbar Age_Category / response=Diabetes_Binary stat=percent group=Race_Category groupdisplay=cluster;
    rowaxis label="Prevalence (%)";
    colaxis label="Age Category";
    title "Prevalence of Diabetes by Age, Race, and Condition Group";
run;