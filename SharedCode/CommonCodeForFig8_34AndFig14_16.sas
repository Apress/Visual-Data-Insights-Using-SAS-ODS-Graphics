/* START of Common Code used to create Figure 8-34 & Figure 14-16 */

/* requires prior run of Listing 8-0 or 14-0 to create input data */

proc summary data=sasuser.DowJonesByDayIn1990;
class Month;
var DailyDJ;
output out=work.MinMedianMaxDJandMinMaxDay
  (drop=_freq_)
  min=MinDJ minid(DailyDJ(day))=MinDay 
  median=MedDJ
  max=MaxDJ maxid(DailyDJ(day))=MaxDay;
run;

data work.MinMedianMaxDJandMinMaxDay
     work.MinDJandDay(keep=Month MinDj MinDay rename=(MinDay=Day))
     work.MaxDJandDay(keep=Month MaxDj MaxDay rename=(MaxDay=Day));
drop _type_;
length Month MinDay MinDJ MedDJ MaxDJ MaxDay 8;
label MinDJ='Minimum Daily Dow Jones in Month';
label MedDJ='Median Daily Dow Jones in Month';
label MaxDJ='Maximum Daily Dow Jones in Month';
set work.MinMedianMaxDJandMinMaxDay;
if _type_ EQ 0 then do; /* for statistics in TITLE1 */
  call symput('MinDJ1990',put(MinDJ,4.));
  call symput('MedDJ1990',put(MedDJ,4.));
  call symput('MaxDJ1990',put(MaxDJ,4.));
  delete;
end;
run; 

data work.DowJonesByDayIn1990MonthlyMinMax;
set sasuser.DowJonesByDayIn1990 work.MinDJandDay work.MaxDJandDay;
run;

data work.DJ_MonthlyStartAndEnd;
retain StartDJ 0;
set sasuser.DowJonesByDayIn1990;
by Month;
if First.Month then StartDJ=DailyDJ;
if Last.Month;
EndDJ = DailyDJ;
run; 

proc format library=work;
value MonthNm
  1 = 'January'  2 = 'February'  3 = 'March' 
  4 = 'April'    5 = 'May'       6 = 'June' 
  7 = 'July'     8 = 'August'    9 = 'September' 
 10 = 'October' 11 = 'November' 12 = 'December';
run;

data work.ToFormat;
keep fmtname type start label;
retain fmtname 'MonthStats' type 'N';
length start 3 label $ 64;
merge work.MinMedianMaxDJandMinMaxDay work.DJ_MonthlyStartAndEnd;
by Month;
start = Month;
label = compress(put(Month,MonthNm9.))     || 
  ': Start='  || compress(put(StartDJ,4.)) || 
  ', Min='    || compress(put(MinDJ,4.))   || 
  ', Median=' || compress(put(MedDJ,4.))   || 
  ', Max='    || compress(put(MaxDJ,4.))   ||
  ', End='    || compress(put(EndDJ,4.));
run; 
proc format library=work cntlin=work.ToFormat;
run;

/* END of Common Code used to create Figures 8-34 and 14-16 */
