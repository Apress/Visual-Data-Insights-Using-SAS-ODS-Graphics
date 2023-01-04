
%macro ExtractEconomicData
(SASETSsiteUseSASHELPDataLib=,
OtherSiteFolderForCitiData=,
OutLib=SASUSER);

%if %length(&OtherSiteFolderForCitiData) NE 0
%then %do;
libname CitiLib "&OtherSiteFolderForCitiData"; 
%end;
data &OutLib..EconomicData;
%if &SASETSsiteUseSASHELPDataLib EQ YES
%then %do;
set sashelp.citimon((keep=Date IP LHUR LUINC);
%end;
%else %do;
set CitiLib.citimon(keep=Date IP LHUR LUINC);
%end;
where 1980 LE YEAR(Date) LE 1991;
Month=put(Date,monname3.);
label
  IP='Industrial Production'
  LHUR='Unemployment Rate'
  LUINC='Avg Weekly UI Claims'; 
run;

%mend  ExtractEconomicData;
