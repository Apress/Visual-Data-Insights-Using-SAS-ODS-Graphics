
%macro AlternativeToVboxPlot(
data=,
where=,
var=,
varlabel=,
format=,
/* If P1 is too close the minimum, use showP1=N.
   If P99 is too close the maximum, use showP99=N.
   Turn off P5 and/or p95, if desired. */
showP1=Y,
showP5=Y,
showP95=Y,
showP99=Y,
imagename=,
imagewidth=,
imageheight=,
subtitle=
);

data work.Extract;
set &data;
%if %length(&where) NE 0 %then %do;
WHERE &where;
%end;
if &var NE .;
run;

proc univariate data=work.Extract noprint;
var &var;
output out=work.statistics
  /* qrange (computable later with q1 and q3) */
  P1=P1&var P5=P5&var P10=P10&var
  P90=P90&var P95=P95&var P99=P99&var
  min=min&var q1=q1&var median=median&var 
  mean=mean&var q3=q3&var max=max&var 
  range=range&var std=std&var nobs=nobs&var sum=Total&var;
run;

proc summary data=work.Extract nway;
where &var NE .;
class &var;
var &var;
output out=work.freq(keep=&var _freq_) sum=OfNoRealInterest;
run;

proc sql noprint;
select max(_freq_) into :MaxFreq trimmed
from work.freq
quit;

/* To simulate case where multiple responses share maximum freq 
data work.freq;
set work.freq end=LastOne;
output;
if LastOne;
&var = 333;
_freq_ = &MaxFreq;
output;
run;
proc sort data=work.freq;
by &var;
run;
   To simulate case where multiple responses share maximum freq */

data _null_;
length MaxFreqAndWhere $ 256;
retain MaxFreqAndWhere ' ';
set work.freq end=LastOne;
if _freq_ EQ &MaxFreq
then do;
/* Since multiple X values might have the maximum response: */
  if MaxFreqAndWhere EQ ' '
  then MaxFreqAndWhere = compress(put(_freq_,9.) || '@' || put(&var.,&format));
  else MaxFreqAndWhere = compress(MaxFreqAndWhere || ',' || put(&var.,&format));
  output;
end;
if LastOne then do;
  put 'Last One - ' MaxFreqAndWhere=; 
  call symput('MaxFreqAndWhere',trim(left(MaxFreqAndWhere)));
end;
run;

data work.ToPlot;
keep XvarZero YaxisBound Ystat MeanStat DataLabelVar MedianStat MedianDataLabelVar; 
set work.statistics;
length DataLabelVar DataLabelVarLeft $ 64;
retain XvarZero 0;
call symput('std',compress(put(std&var,13.2)));
call symput('Nobs',compress(put(Nobs&var,10.)));
call symput('min',min&var);
call symput('max',max&var);
call symput('range',range&var);
YaxisBound = min&var;
DataLabelVar = compress('Minimum=' || put(min&var,&format));
output;
YaxisBound = .;
%if &showP1 EQ Y %then %do;
Ystat = p1&var;
DataLabelVar = compress('Pctl_01=' || put(p1&var,&format));
output;
%end;
%if &showP5 EQ Y %then %do;
Ystat = p5&var;
DataLabelVar = compress('Pctl_05=' || put(p5&var,&format));
output;
%end;
Ystat = p10&var;
DataLabelVar = compress('Pctl_10=' || put(p10&var,&format));
output;
Ystat = q1&var;
DataLabelVar = compress('Quartile_1=' || put(q1&var,&format));
output;
Ystat = .;
DataLabelVar = '';
MedianStat = median&var;
MedianDataLabelVar = compress('Median=' || put(median&var,&format));
output;
MedianStat = .;
MedianDataLabelVar = '';
MeanStat = mean&var;
DataLabelVar = compress('Mean=' || put(mean&var,&format));
output;
MeanStat = .;
Ystat = q3&var;
DataLabelVar = compress('Quartile_3=' || put(q3&var,&format));
output;
Ystat = p90&var;
DataLabelVar = compress('Pctl_90=' || put(p90&var,&format));
output;
%if &showP95 EQ Y %then %do;
Ystat = p95&var;
DataLabelVar = compress('Pctl_95=' || put(p95&var,&format));
output;
%end;
%if &showP99 EQ Y %then %do;
Ystat = p99&var;
DataLabelVar = compress('Pctl_99=' || put(p99&var,&format));
output;
%end;
ystat = .;
YaxisBound = max&var;
DataLabelVar = compress('Maximum=' || put(max&var,&format));
output;
run;

%put _global_;

ods graphics on / reset=all scale=off 
%if %length(&imagewidth) NE 0 %then %do;
  width=&imagewidth
%end; 
%if %length(&imageheight) NE 0 %then %do;
  height=&imageheight
%end;
  imagename="&imagename";

title1 justify=left "Distribution of "
  %if %length(&varlabel) NE 0 %then %do;
  "&varlabel"
  %end;
  %else %do;
  "&var"
  %end;
  " in &data Data Set";
%if %length(&where) NE 0 %then %do;
title2 justify=left "Data Selection Filter: &where";
%end;
%if %length(&Subtitle) NE 0 %then %do;
title3 justify=left "&Subtitle";
%end;
title4 justify=left "&Nobs &Var Values, Standard Deviation &std";
title5 justify=left "Maximum Frequency: &MaxFreqAndWhere";
proc sgplot data=work.ToPlot noautolegend noborder;
series x=XvarZero y=YaxisBound / 
  lineattrs=(color=black)
  markers markerattrs=(color=black symbol=SquareFilled size=7px)
  datalabel=DataLabelVar datalabelpos=right datalabelattrs=(color=black);
scatter x=XvarZero y=Ystat /
  markerattrs=(color=black symbol=CircleFilled size=7px)
  datalabel=DataLabelVar datalabelpos=right datalabelattrs=(color=black);
scatter x=XvarZero y=MedianStat /
  markerattrs=(color=black symbol=TriangleRightFilled size=12px)
  datalabel=MedianDataLabelVar datalabelpos=left datalabelattrs=(color=black);
scatter x=XvarZero y=MeanStat /
  markerattrs=(color=red symbol=TriangleLeftFilled size=12px)
  datalabel=DataLabelVar datalabelpos=right datalabelattrs=(color=black);
yaxis display=none values=(&min to &max by &range);
xaxis display=none;
run;
%mend AlternativeToVboxPlot;
