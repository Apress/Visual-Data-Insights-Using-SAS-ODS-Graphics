
%macro ActualDistWithOptionalNormalDist(
NormalDistOverlay=N,
DuplicateYaxisAtRightSide=Y, /* Y is IGNORED if NormalDistOverlay=Y */
Data=,
Where=%str(),
Var=,
VarLabel=,
Format=,
ImageWidth=,
ImageHeight=,
AntiAliasMax=,
XaxisCustom=N,
XaxisMin=,
XaxisMax=,
XaxisIncrement=,
XaxisStagger=N,
YaxisCustom=N,
YaxisMax=,
YaxisIncrement=,
YaxisGrid=N,
ForceYaxisThresholdMax=N,
ForceXaxisThresholdMin=N,
ForceXaxisThresholdMax=N,
EssentialValueFlagHeight=0, /* Adjust if needed. This should be OK.
  It is a holdover from when the essential-value markers were
  drawn with needles with Y=1, the previous default for this. */
SubTitle=,
ImageName=);

/* %include "C:\SharedCode\GetEssentialValues.sas"; 
   UNCOMMENT this 
   if not doing include before macro invocation */

%if &NormalDistOverlay EQ Y
%then %let DuplicateYaxisAtRightSide = N;

data work.Extract;
set &Data;
%if %length(&Where) NE 0 %then %do;
where &Where.;
%end;
run;

%GetEssentialValues(
EVdataIN=work.Extract,
EVvar=&Var,
EVformat=&Format,
EVflagHeight=&EssentialValueFlagHeight);

proc sort data=work.Percentiles;
by &Var;
run;

proc sort data=work.OtherStatistics;
by &Var;
run;

proc summary data=work.Extract nway;
where &Var NE .;
class &Var;
var &Var;
output out=work.freq(keep=&Var _freq_) sum=OfNoRealInterest;
run;

proc sql noprint;
select max(_freq_) into :FreqMax trimmed
from work.freq
quit;

/* To simulate case where multiple responses share maximum freq
data work.freq;
set work.freq end=LastOne;
output;
if LastOne;
&Var = 65; 
COMMENT: Use a value distinguishable from the real mode;
_freq_ = &FreqMax;
output;
run;
proc sort data=work.freq;
by &Var;
run;
  To simulate case where multiple responses share maximum freq */

%let ModeForPlot    = %str();
%let ModeForDisplay = %str();
data work.MaxFreqAndVarValue;
length MaxFreqAndWhere $ 64 MaxFreq 3. Where 8. Mode $ 32;
retain MaxFreqAndWhere ' ' MaxFreq 0 Where 0;
keep &Var MaxFreq;
set work.freq end=LastOne;
if _freq_ EQ &FreqMax
then do;
  MaxFreq = _freq_;
  Where = &Var;
/* Since multiple X values might have the maximum response: */
  if MaxFreqAndWhere EQ ' '
  then MaxFreqAndWhere = compress(put(MaxFreq,9.) || '@' || put(Where,&Format));
  else MaxFreqAndWhere = compress(MaxFreqAndWhere || ',' || put(Where,&Format));  
  output;
end;
if LastOne then do;
  call symput('MaxFreqAndWhere',trim(left(MaxFreqAndWhere)));
  call symput('MaxFreq',MaxFreq);
  if index(MaxFreqAndWhere,',') EQ 0
  then do;
    call symput('ModeForPlot',Where);
    Mode = put(Where,&Format);
    call symput('ModeForDisplay',compress(Mode));
  end;
  else  Mode = 'Multiple Values with Max Freq';
end;
run;

data work.OtherStatistics;
set work.OtherStatistics end=LastOne;
output;
if LastOne;
if %length(&ModeForPlot) NE 0 then do;
  &Var = &ModeForPlot;
  output;
end;
run;

proc sort data=work.OtherStatistics;
by &Var;
run; 

data work.ToMergeWithNormDist;
merge 
  work.freq 
  work.Percentiles
  work.OtherStatistics
  work.MaxFreqAndVarValue;
by &Var;
run;
 
data work.pdf_&Var(keep=PDF_Y &Var);
set work.Extract;
format PDF_Y best20.;
where &Var NE .;
PDF_Y = pdf("Normal", &Var, &mean, &std);
run;

proc sort data=work.pdf_&Var;
by &Var;
run;

proc sql noprint;
select max(pdf_Y) into :MAXpdf_Y trimmed
from work.pdf_&Var
quit; 

data work.ToPlot;
merge 
  work.ToMergeWithNormDist
  work.pdf_&Var;
by &Var;
* pdf_Y = ( pdf_Y * &MaxFreq ) / &MAXpdf_Y;
run;

proc sort data=work.ToPlot out=work.Distinct&Var nodupkey;
by &Var;
run;

proc sql noprint;
select Count(&Var) into :Ndistinct&Var trimmed
from work.Distinct&Var;
quit; 

ods graphics on / reset=all scale=off width=&ImageWidth 
%if %length(&ImageHeight) NE 0 %then %do;
  height=&ImageHeight
%end;
%if %length(&AntiAliasMax) NE 0 %then %do;
  AntiAliasMax=&AntiAliasMax
%end;
  imagename="&ImageName";
title1 justify=left "Frequency Distribution of &Var in &Data";
%if &NormalDistOverlay EQ Y %then %do;
title2 justify=left "Overlaid with output from " color=blue "the SAS PDF function for a Normal Distribution";
%end;
title3 justify=left "&Nobs &Var Values with &&Ndistinct&Var Frequencies";
title4 justify=left color=CX00CCFF "(*ESC*){unicode '25B2'x} Max. Freq: &MaxFreqAndWhere"
  color=black " | StdDev: &std | Values for " color=red "Dots" color=black " & " color=black "Squares:";
title5 justify=left color=red "(*ESC*){unicode '25CF'x} Minimum:&min, Median:&median, Maximum:&max, Mean:&mean"
%if %length(&ModeForDisplay) NE 0 %then %do;
  ", Mode:&ModeForDisplay"
%end; 
  ;  
title6 justify=left "(*ESC*){unicode '25A0'x} Percentile 1:&p1, 10:&p10, 25:&q1, 75:&q3, 90:&p90, 99:&p99";
%if %length(&Where) NE 0 %then %do;
title7 justify=left "Data Selection Filter: &Where";
  %let NextTITLE = 8; 
%end;
%else %let NextTITLE = 7;
%if %length(&Subtitle) NE 0 %then %do;
title&NextTITLE justify=left color=blue "&Subtitle";
%end;
%if &NormalDistOverlay EQ Y %then %do;
footnote1 "If Normal Distribution: Mean = Median = Mode (i.e., value with max freq)";
%end;
proc sgplot data=work.ToPlot noborder noautolegend;
needle x=&Var y=_freq_ / displaybaseline=off
  lineattrs=(color=gray thickness=1px pattern=solid)
  markers markerattrs=(symbol=TriangleFilled color=black size=3px);
  /* without markers, the very small frequencies are barely visible */
%if &DuplicateYaxisAtRightSide EQ Y %then %do;
needle x=&Var y=_freq_ / y2axis displaybaseline=off
  lineattrs=(color=gray thickness=1px pattern=solid)
  markers markerattrs=(symbol=TriangleFilled color=black size=3px);
%end;
%if &NormalDistOverlay EQ Y %then %do;
series x=&Var y=PDF_Y / Y2axis smoothconnect
  lineattrs=(color=blue thickness=2px pattern=solid);
%end;
needle x=&Var y=MaxFreq / displaybaseline=off
  markers markerattrs=(color=CX00CCFF symbol=TriangleFilled size=8px)
  lineattrs=(color=gray thickness=1px pattern=solid);
scatter x=&Var y=FlagPercentiles /
  markerattrs=(color=black symbol=SquareFilled size=7px);
scatter x=&Var y=FlagOtherStatistics /
  markerattrs=(color=red symbol=CircleFilled size=4px);
xaxis display=(
%if %length(&VarLabel) EQ 0 %then %do;
  nolabel 
%end;
  noline)
%if &XaxisCustom EQ Y %then %do;
  %if &XaxisStagger EQ Y %then %do; 
  fitpolicy=stagger
  %end;
  values=(&XaxisMin to &XaxisMax by &XaxisIncrement)
%end;
%else %do; /* unneeded when X axis is custom */
  %if &ForceXaxisThresholdMin NE N %then %do;
  thresholdmin=1
  %end;
  %if &ForceXaxisThresholdMax NE N %then %do;
  thresholdmax=1
  %end;
%end;
  ;
%if &NormalDistOverlay EQ Y %then %do;
y2axis display=(noline noticks)
  valueattrs=(color=blue)
  labelattrs=(color=blue)
  labelpos=Top label='Probability Density';
%end;
%else 
%if &DuplicateYaxisAtRightSide EQ Y %then %do; 
y2axis display=(noline nolabel noticks) 
  %if &YaxisCustom EQ Y %then %do;
  fitpolicy=none
  values=(0 to &YaxisMax by &YaxisIncrement)
  %end;
  %else
  %if &ForceYaxisThresholdMax NE N %then %do;
  /* This Force is unneeded when Y axis is custom */
  thresholdmax=1
  %end;
  ;
%end;
yaxis display=(noline
%if &NormalDistOverlay EQ N %then %do;
               nolabel
%end; 
               noticks) 
%if &YaxisGrid EQ Y %then %do;
  grid
%end;
%if &NormalDistOverlay EQ Y %then %do;
  labelpos=Top label='Frequency'
%end; 
%if &YaxisCustom EQ Y %then %do;
  fitpolicy=none
  values=(0 to &YaxisMax by &YaxisIncrement)
%end;
%else %do;
  minorgrid
  %if &ForceYaxisThresholdMax NE N %then %do;
  /* This Force is unneeded when Y axis is custom */
  thresholdmax=1
  %end;
%end;
  ;
%if %length(&VarLabel) NE 0 %then %do;
label &Var="&VarLabel";
%end;
run;
footnote1;

%mend ActualDistWithOptionalNormalDist;
