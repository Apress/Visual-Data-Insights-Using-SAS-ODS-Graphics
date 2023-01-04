
%macro HistogramBinsBySTDranges(
Data=,
Where=,
Var=,
Label=,
XaxisValueFormat=,
Format=,
XaxisMinAndMaxOffSets=0.05, 
  /* make larger if X axis value clipping,
     smaller if too much white space at sides. */
SubTitle=,
Imagename=,
ImageWidth=,
ImageHeight=);

proc sort data=&Data(where=(&Var NE .)) out=work.Sorted;
%if %length(&Where) NE 0 %then %do;
where &Where;
%end; 
by &Var; 
run;

proc summary data=work.Sorted nway; 
/* prior sort is coincidental, not needed for PROC SUMMARY */
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
&Var = 333;
_freq_ = &FreqMax;
output;
run;
proc sort data=work.freq;
by &Var;
run;
   To simulate case where multiple responses share maximum freq */

data work.MaxFreqAndVarValue;
length MaxFreqAndWhere $ 64.;
retain MaxFreqAndWhere ' ' Where 8.;
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
  put 'Last One - ' MaxFreqAndWhere=; 
  call symput('MaxFreqAndWhere',trim(left(MaxFreqAndWhere)));
  if index(MaxFreqAndWhere,',') EQ 0
  then call symput('Mode',trim(left(put(Where,&Format)))); 
  else call symput('Mode','Multiple'); 
end;
run;

proc sql noprint;
select count(&Var),median(&Var),mean(&Var),STD(&Var),min(&Var),max(&Var) 
  into :Nobs trimmed,:median trimmed,:mean trimmed,:STD trimmed,:min trimmed,:max trimmed
  from work.Sorted;
quit;

data _null_;
call symput('Boundary1',%sysevalf(&mean - (3 * &STD)));
call symput('Boundary2',%sysevalf(&mean - (2 * &STD)));
call symput('Boundary3',%sysevalf(&mean - (1 * &STD)));
call symput('Boundary4',%sysevalf(&mean + (1 * &STD)));
call symput('Boundary5',%sysevalf(&mean + (2 * &STD)));
call symput('Boundary6',%sysevalf(&mean + (3 * &STD)));
call symput('RangeCount',6);
call symput('MeanForTitle',compress(put(&mean,&Format)));
call symput('STDForTitle',compress(put(&STD,&Format)));
run;

data work.binned;
retain Bin 1;
set work.Sorted;
%do j = 1 %to &RangeCount %by 1;
if &Var LE &&Boundary&j
then do;
  Boundary = &&Boundary&j;
  Bin = &j;
  output;
end;
else
%end;
do;
  Bin = &RangeCount + 1;
  output;
end;
run;

proc summary data=work.binned nway;
class Bin;
Var Bin;
id Boundary;
output out=work.BinnedAndCounted(keep=Bin Boundary _freq_) sum=UselessAndNotMeaningful;
run;

data work.CountsBySTD;
retain WithinOneSTDiation WithinTwoStandardDeviations WithinThreeStandardDeviations 0;
set work.BinnedAndCounted end=LastOne;
if 2 LE Bin LE 6
then WithinThreeStandardDeviations + _freq_;
if 3 LE Bin LE 5
then WithinTwoStandardDeviations + _freq_;
if Bin EQ 4
then WithinOneSTDiation =_freq_;
if LastOne;
call symput('In1STD',compress(WithinOneSTDiation));
call symput('In2STD',compress(WithinTwoStandardDeviations));
call symput('In3STD',compress(WithinThreeStandardDeviations));
/* NOTE: When using the PERCENTw.d format to deliver two digits 
   to the right of the decimal point, it is mandatory to leave
   space for parenthesis used for negative values,
   regardless of the fact that they might be impossible.
   (Apparently, it is NOT necessary to allow for 100.00%.)
   In the statements below, PERCENT8.2 is necessary. */
call symput('Pct1STD',compress(put((WithinOneSTDiation / &Nobs),percent8.2)));
call symput('Pct2STD',compress(put((WithinTwoStandardDeviations / &Nobs),percent8.2)));
call symput('Pct3STD',compress(put((WithinThreeStandardDeviations / &Nobs),percent8.2)));
run;

data work.vertices;
retain PrevX PrevY;
set work.BinnedAndCounted end=LastOne;
if _N_ EQ 1 then do;
  x=&Min; y=_freq_; 
  output;
 x=Boundary; y=_freq_; 
  output;
  PrevX=x;
  PrevY=y;
  delete;
end;
if LastOne then do;
  x=PrevX; y=_freq_; 
  output;
  x=&Max; y=_freq_;
  output;
  delete;
end; 
x=PrevX; y=_freq_;
output;
x=Boundary; y=_freq_;
output;
PrevX=x;
PrevY=y;
run;

data work.BoundaryLines(keep=YforBoundaryLine x)
     work.BoundaryAxisValues(keep=YforAxisValue x);
retain PrevFreq 0 YforAxisValue 0;
set work.BinnedAndCounted end=LastOne;
if _N_ EQ 1 then do;
  x = &Min;
  YforBoundaryLine=_freq_;
  output work.BoundaryLines;
  output BoundaryAxisValues; 
end;
if LastOne then do;;
  x = &Max;
  YforBoundaryLine=_freq_;
  output work.BoundaryLines;
  output BoundaryAxisValues;
  return;
end;
x = Boundary;
YforBoundaryLine=_freq_;
output work.BoundaryLines;
* YforAxisValue=0;
output BoundaryAxisValues; 
run;

data work.CenteredDataLabels(keep=YforFreqDataLabel x FreqDataLabel);
length FreqDataLabel $ 16;
retain PrevX 0;
set work.BoundaryLines;
if _N_ EQ 1 then PrevX = x;
else do;
  XforFreqDataLabel = (PrevX + x) / 2;
  YforFreqDataLabel = YforBoundaryLine;
  PrevX = x;
  x = XforFreqDataLabel;
  FreqDataLabel = trim(left(put(YforFreqDataLabel,16.)));
  output;
end;
run;

data work.ToPlot;
set work.vertices work.BoundaryLines work.BoundaryAxisValues work.CenteredDataLabels;
run;

ods graphics on / reset=all scale=off 
%if %length(&ImageWidth) NE 0 %then %do;
  width=&ImageWidth
%end;
%if %length(&ImageHeight) NE 0 %then %do;
  height=&ImageHeight
%end; 
  imagename="&ImageName";
title1 justify=left "&Var By Standard Deviation Range in &Data Data Set";
%if %length(&Where) NE 0 %then %do;
title2 justify=left "where &Where";
%end;
title3 justify=left "Count:&Nobs,1 STD:&In1STD(&Pct1STD.), 2 STD:&In2STD(&Pct2STD.), 3 STD:&In3STD(&Pct3STD.)";
title4 justify=left "Mean:&MeanForTitle., Median:&Median.,"
  %if %length(&Mode) NE 0 %then %do;
  " Mode:&Mode"
  %end;
  " Max Freq: &MaxFreqAndWhere";
title5 justify=left "Min:&min., Max:&max., Mean:&MeanForTitle., STD:&STDForTitle";
%if %length(&SubTitle) NE 0 %then %do;
title6 justify=left "&SubTitles";
%end;
footnote1 justify=left "If Normal Distribution: Mean = Median = Mode, and";
footnote2 justify=left "68.27% of counts within 1 STD, 95.45% within 2 STD, 99.73% within 3 STD"; 
proc sgplot data=work.ToPlot noborder noautolegend;
series x=x y=y;
needle x=x y=YforBoundaryLine / displaybaseline=off;
scatter x=x y=YforAxisValue /
  DataLabel=x DataLabelPos=Bottom
  markerattrs=(size=1px color=black);
scatter x=x y=YforFreqDataLabel /
  DataLabel=FreqDataLabel DataLabelPos=Top
  markerattrs=(size=1px color=black);
xaxis display=(noline noticks novalues
%if %length(&Label) EQ 0 %then %do;
               nolabel
%end;
                      ) 
  values=(&min to &max by %sysevalf(&max - &min))
  offsetmin=&XaxisMinAndMaxOffSets 
  offsetmax=&XaxisMinAndMaxOffSets;
format x &XaxisValueFormat;
yaxis display=none;
%if %length(&Label) NE 0 %then %do;
label x="&Label";
%end;
run;
footnote1;

%mend HistogramBinsBySTDranges;
