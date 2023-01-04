/* The code for the macro below is in Appendix A8-26. */
/* It is used in multiple Chapter 8 examples. */

%macro MonthlyDataForMultiLinePlot(
Data=,
Filter=,
Out=,
ClassVar=,
ResponseVar=,
DateVar=,
MinMaxWithMonthLabels=NO,
ResponseVarFormat= ,/* Needed only if MinMaxWithMonthLabels=YES */
MonthFormat=,       /* Needed only if MinMaxWithMonthLabels=YES */
DataLabelLength=    /* Needed only if MinMaxWithMonthLabels=YES */
);

data work.extract(keep=&ClassVar &&DateVar &ResponseVar Month);
set &data;
%if %length(&Filter) NE 0 %then %do;
&Filter;
%end;
Month=month(&DateVar);
run;

data work.MinMax(keep=&ClassVar Month Min&ResponseVar Max&ResponseVar);
retain Min 999999999 Max 0 MinMonth MaxMonth 0;
set work.Extract;
by &ClassVar;
if &ResponseVar GE Max
then do;
  Max = &ResponseVar;
  MaxMonth  = Month;
end;
if &ResponseVar LE Min
then do;
  Min = &ResponseVar;
  MinMonth  = Month;
end;
if last.&ClassVar;
Month = MaxMonth;
Max&ResponseVar = Max;
Min&ResponseVar = .;
output;
Month = MinMonth;
Min&ResponseVar = Min;
Max&ResponseVar = .;
output;
Min = 999999999;
Max = 0;
run;

proc sort data=work.extract;
by &ClassVar Month;
run;

proc sort data=work.MinMax;
by &ClassVar Month;
run;

data work.DataPlusMinMax;
merge work.extract work.MinMax;
by &ClassVar Month;
run;

data &Out;
set work.DataPlusMinMax;
%if &MinMaxWithMonthLabels EQ YES %then %do;
length Max Min $ &DataLabelLength;
%end;
by &ClassVar;
if First.&ClassVar then do;
  if &ResponseVar NE Min&ResponseVar and &ResponseVar NE Max&ResponseVar
  then &ResponseVar.FirstIn&ClassVar = &ResponseVar;
end;
if Last.&ClassVar then do;
  if &ResponseVar NE Min&ResponseVar and &ResponseVar NE Max&ResponseVar
  then &ResponseVar.LastIn&ClassVar = &ResponseVar;
end;
%if &MinMaxWithMonthLabels EQ YES %then %do;
if Min&ResponseVar NE . then do;
  Min = put(Min&ResponseVar,&ResponseVarFormat);
  if month(&DateVar) NOT IN (1 12) 
  then Min = trim(left(Min)) || ',' || put(&DateVar,&MonthFormat);
end;
if Max&ResponseVar NE . then do; 
  Max = put(Max&ResponseVar,3.);
  if month(&DateVar) NOT IN (1 12) 
  then Max = trim(left(Max)) || ',' || put(&DateVar,&MonthFormat);
end;
%end;
run;

%mend MonthlyDataForMultiLinePlot;
