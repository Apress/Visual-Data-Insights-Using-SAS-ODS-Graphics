%macro ExtractDowJonesByDayInJan1991
(SASETSsiteUseSASHELPDataLib=,
OtherSiteFolderForCitiData=,
OutLib=WORK);

%if %length(&OtherSiteFolderForCitiData) NE 0
%then %do;
libname CitiLib "&OtherSiteFolderForCitiData"; 
%end;
data &OutLib..DowJonesByDayInJan1991;
keep Date Day DailyDJ;
label DailyDJ='Daily Dow Jones';
%if &SASETSsiteUseSASHELPDataLib EQ YES
%then %do;
set sashelp.citiday(keep=SNYDJCM Date);
%end;
%else %do;
set CitiLib.citiday(keep=SNYDJCM Date);
%end;
where SNYDJCM NE . AND year(Date) EQ 1991 AND month(Date) EQ 1; 
Day = DAY(Date);
DailyDJ = SNYDJCM;
run;

%mend  ExtractDowJonesByDayInJan1991;
