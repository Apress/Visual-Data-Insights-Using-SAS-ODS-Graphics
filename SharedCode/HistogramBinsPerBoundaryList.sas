
%macro HistogramBinsPerBoundaryList(
BoundaryList=%str(),
SubRangesDescriptions=%str(),
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

data work.Extract(rename=(Rounded=&Var));
drop &Var;
set &Data;
%if %length(&Where) NE 0 %then %do;
where &Where;
%end; 
if &Var NE .;
Rounded = round(&Var);
run;

proc sort data=work.Extract(keep=&Var) out=work.Sorted;
by &Var; 
run;

proc sql noprint;
select count(&Var),mean(&Var),std(&Var),min(&Var),max(&Var) 
  into :Nobs trimmed,:mean trimmed,:stddev trimmed,:min trimmed,:max trimmed
  from work.Sorted;
quit;

data _null_;
call symput('MeanForTitle',compress(round(&mean)));
call symput('StdDevForTitle',compress(put(&stddev,&Format)));
run;

data _null_;
length Boundary $ 16;
length BoundaryList $ 1024;
BoundaryList = "&BoundaryList";
do i=1 by 1 until (Boundary=' ');
   Boundary = scan(BoundaryList, i, ',');
   put Boundary=;
   if Boundary NE ' ' 
   then call symput('Boundary'||trim(left(i)),Boundary);
end;
call symput('RangeCount',i-1);
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

data work.vertices;
retain PrevX PrevY;
set work.BinnedAndCounted end=LastOne;
if _N_ EQ 1 then do;
  x=&Min; y=_freq_; 
  DataLabelTopRight=y;
    
  output;
  DataLabelTopRight=.;
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
  DataLabelTopLeft=y; 
  output;
  delete;
end; 
x=PrevX; y=_freq_;
if Bin NE %eval(&RangeCount + 1) then do;
  if PrevY LT y 
  then DataLabelTopLeft=y; 
  else DataLabelTopRight=y;
end;  
output;
DataLabelTopLeft=.; 
DataLabelTopRight=.; 
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
  * YforAxisValue=0;
  output BoundaryAxisValues; 
end;
if LastOne then do;;
  x = &Max;
  YforBoundaryLine=_freq_;
  output work.BoundaryLines;
  * YforAxisValue=0;
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
title1 justify=left "Distribution of &Var in &Data Data Set";
%if %length(&Where) NE 0 %then %do;
title2 justify=left "where &Where";
%end;
title3 justify=left "Count:&Nobs, Min:&min., Max:&max., Mean:&MeanForTitle., StdDev:&StdDevForTitle";
title4 justify=left "Values: &SubRangesDescriptions";
%if %length(&SubTitle) NE 0 %then %do;
title5 justify=left "&SubTitle";
%end;
proc sgplot data=work.ToPlot noborder noautolegend;
series x=x y=y;
needle x=x y=YforBoundaryLine / displaybaseline=off;
scatter x=x y=YforAxisValue / /* NOT Yzero */
  markerattrs=(size=1px color=black)
  DataLabel=x /* Not XforBoundary */ DataLabelPos=Bottom;
scatter x=x y=YforFreqDataLabel /
  markerattrs=(size=1px color=black)
  DataLabel=FreqDataLabel /* not Y */ DataLabelPos=Top;
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

%mend HistogramBinsPerBoundaryList;
