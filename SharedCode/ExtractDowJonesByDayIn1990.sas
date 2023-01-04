%macro ExtractDowJonesByDayIn1990
(SASETSsiteUseSASHELPDataLib=,
OtherSiteFolderForCitiData=,
OutLib=SASUSER);

%if %length(&OtherSiteFolderForCitiData) NE 0
%then %do;
libname CitiLib "&OtherSiteFolderForCitiData"; 
%end;
data &OutLib..DowJonesByDayIn1990; /* SASUSER data set persists */
keep Date Day Month DailyDJ;
label DailyDJ='Daily Dow Jones';
%if &SASETSsiteUseSASHELPDataLib EQ YES
%then %do;
set sashelp.citiday(keep=SNYDJCM Date);
%end;
%else %do;
set CitiLib.citiday(keep=SNYDJCM Date);
%end;
where SNYDJCM NE . AND YEAR(Date) EQ 1990;
DailyDJ = SNYDJCM; 
Day = DAY(Date);
Month = MONTH(Date);
run;

%mend  ExtractDowJonesByDayIn1990; 
