
%macro ExtractSandPbyMonthTwoRanges
(SASETSsiteUseSASHELPDataLib=,
OtherSiteFolderForCitiData=,
OutLib=SASUSER);

%if %length(&OtherSiteFolderForCitiData) NE 0
%then %do;
libname CitiLib "&OtherSiteFolderForCitiData"; 
%end;
data &OutLib..SandPbyMonth1980to1991
     &OutLib..SandPbyMonth1987to1991;
keep Date Year Month FSPCOM;
%if &SASETSsiteUseSASHELPDataLib EQ YES
%then %do;
set sashelp.citimon((keep=FSPCOM Date);
%end;
%else %do;
set CitiLib.citimon(keep=FSPCOM Date);
%end;
Month = MONTH(Date);
Year = YEAR(Date);
if Year LE 1991;
output &OutLib..SandPbyMonth1980to1991;
if Year GE 1987;
output &OutLib..SandPbyMonth1987to1991;
run;

%mend  ExtractSandPbyMonthTwoRanges;
