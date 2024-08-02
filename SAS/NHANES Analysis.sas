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
    else if (Avg_BPXSY >= 130 and Avg_BPXDI < 140) or (Avg_BPXDI >= 80 and Avg_BPXDI < 90) then BP_Category = 'BP2';
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

proc surveymeans data=nhanes_combined mean stddev min max median;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    var Avg_BPXSY Avg_BPXDI LBXGH;
run;


proc surveylogistic data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    model Diabetes_Binary(event='1') = HTN_Binary;
    output out=pred_htn_diabetes p=pred_prob;
run;

proc sgplot data=pred_htn_diabetes;
    title "Predicted Probability of Diabetes by Hypertension Status";
    vbar HTN_Binary / response=pred_prob stat=mean;
    xaxis label="Hypertension Status (0=No, 1=Yes)";
    yaxis label="Predicted Probability of Diabetes";
run;


proc surveylogistic data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    model HTN_Binary(event='1') = RIDAGEYR;
    output out=pred_age_htn p=pred_prob;
run;

proc sgplot data=pred_age_htn;
    title "Predicted Probability of Hypertension by Age";
    scatter x=RIDAGEYR y=pred_prob;
    xaxis label="Age";
    yaxis label="Predicted Probability of Hypertension";
run;


proc surveylogistic data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    model Diabetes_Binary(event='1') = RIDAGEYR;
    output out=pred_age_diabetes p=pred_prob;
run;

proc sgplot data=pred_age_diabetes;
    title "Predicted Probability of Diabetes by Age";
    scatter x=RIDAGEYR y=pred_prob;
    xaxis label="Age";
    yaxis label="Predicted Probability of Diabetes";
run;


proc surveylogistic data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    class Race_Category;
    model HTN_Binary(event='1') = Race_Category;
    output out=pred_race_htn p=pred_prob;
run;

proc sgplot data=pred_race_htn;
    title "Predicted Probability of Hypertension by Race";
    vbar Race_Category / response=pred_prob stat=mean;
    xaxis label="Race Category";
    yaxis label="Predicted Probability of Hypertension";
run;

/* Logistic Regression and Visualization for Race and Diabetes */
proc surveylogistic data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    class Race_Category;
    model Diabetes_Binary(event='1') = Race_Category;
    output out=pred_race_diabetes p=pred_prob;
run;

proc sgplot data=pred_race_diabetes;
    title "Predicted Probability of Diabetes by Race";
    vbar Race_Category / response=pred_prob stat=mean;
    xaxis label="Race Category";
    yaxis label="Predicted Probability of Diabetes";
run;

/* Prevalence Analysis Over Time */
proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables cycle*HTN_Binary cycle*Diabetes_Binary / row cl;
run;

/* Bar Chart for Hypertension Prevalence by Age, Race, and Cycle */
proc sgpanel data=nhanes_combined;
    panelby cycle;
    vbar Age_Category / response=HTN_Binary stat=percent group=Race_Category groupdisplay=cluster;
    rowaxis label="Prevalence (%)";
    colaxis label="Age Category";
    title "Prevalence of Hypertension by Age, Race, and Cycle";
    keylegend / title="Race Category";
run;

proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables Age_Category*HTN_Binary Age_Category*Diabetes_Binary / row cl;
run;

/* Bar Chart for Hypertension Prevalence by Age Group */
proc sgpanel data=nhanes_combined;
    panelby cycle;
    vbar Age_Category / response=HTN_Binary stat=percent group=cycle groupdisplay=cluster;
    rowaxis label="Prevalence (%)";
    colaxis label="Age Category";
    title "Prevalence of Hypertension by Age Group and Cycle";
    keylegend / title="Cycle";
run;

/* Bar Chart for Diabetes Prevalence by Age Group */
proc sgpanel data=nhanes_combined;
    panelby cycle;
    vbar Age_Category / response=Diabetes_Binary stat=percent group=cycle groupdisplay=cluster;
    rowaxis label="Prevalence (%)";
    colaxis label="Age Category";
    title "Prevalence of Diabetes by Age Group and Cycle";
    keylegend / title="Cycle";
run;


proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables RIAGENDR*HTN_Binary RIAGENDR*Diabetes_Binary / row cl;
run;

/* Bar Chart for Hypertension Prevalence by Gender */
proc sgpanel data=nhanes_combined;
    panelby cycle;
    vbar RIAGENDR / response=HTN_Binary stat=percent group=cycle groupdisplay=cluster;
    rowaxis label="Prevalence (%)";
    colaxis label="Gender";
    title "Prevalence of Hypertension by Gender and Cycle";
    keylegend / title="Cycle";
run;

/* Bar Chart for Diabetes Prevalence by Gender */
proc sgpanel data=nhanes_combined;
    panelby cycle;
    vbar RIAGENDR / response=Diabetes_Binary stat=percent group=cycle groupdisplay=cluster;
    rowaxis label="Prevalence (%)";
    colaxis label="Gender";
    title "Prevalence of Diabetes by Gender and Cycle";
    keylegend / title="Cycle";
run;

proc surveyfreq data=nhanes_combined;
    strata SDMVSTRA;
    cluster SDMVPSU;
    weight MEC4YR;
    tables Race_Category*HTN_Binary Race_Category*Diabetes_Binary / row cl;
run;

/* Bar Chart for Hypertension Prevalence by Race */
proc sgpanel data=nhanes_combined;
    panelby cycle;
    vbar Race_Category / response=HTN_Binary stat=percent group=cycle groupdisplay=cluster;
    rowaxis label="Prevalence (%)";
    colaxis label="Race Category";
    title "Prevalence of Hypertension by Race and Cycle";
    keylegend / title="Cycle";
run;

/* Bar Chart for Diabetes Prevalence by Race */
proc sgpanel data=nhanes_combined;
    panelby cycle;
    vbar Race_Category / response=Diabetes_Binary stat=percent group=cycle groupdisplay=cluster;
    rowaxis label="Prevalence (%)";
    colaxis label="Race Category";
    title "Prevalence of Diabetes by Race and Cycle";
    keylegend / title="Cycle";
run;
