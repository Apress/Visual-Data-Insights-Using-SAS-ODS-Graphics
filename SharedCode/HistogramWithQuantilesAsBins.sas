
%macro HistogramWithQuantilesAsBins(
Data=,
Var=,
Format=,
QuantileCount=,
Fringe=N,
/* DividerOfStartValueToGetOffset=10, */
BoundaryNeedleColor=black, /* If Fringe=Y, this color is 
  dynamically overridden to be easily visible over blue fringe */
XaxisCustom=N,
XaxisMin=,
XaxisMax=,
XaxisIncrement=,
XaxisStagger=N,
ForceXaxisThresholdMin=N,
ForceXaxisThresholdMax=N,
SubTitle=,
Imagename=,
ImageWidth=,
ImageHeight=);

%if &QuantileCount LT 3 %then %do;
  %put Minimum QuantileCount is 3;
  %goto MacroExit;
%end;

proc sort data=&Data out=work.Sorted; 
where &Var NE .;
by &Var; 
run;

/* to create test data with 7 full bins for Figure 12-12
   to make 5057 become 5061

data work.Sorted;
set work.Sorted end=LastOne;
output;
if LastOne;
output;
output;
output;
output;
run;

 */

proc sql noprint;
select N(&Var) into :Nobs trimmed
  from work.Sorted;
quit;

data work.Binned(keep=Boundary BinFreq NeedleHeight &Var); 
length QuantilesList Title2Text $ 256;
retain PreviousBoundary /* Knowledge of this only needed when at LastOne.
  No need to save on exit from handling _N_ EQ 1 */
  BinFreq LastBinFreq HowManySoFar SaveFirstBinOffset QuantileIndex 0 QuantilesList ' ';
set work.Sorted end=LastOne;
NeedleHeight = .;
if _N_ EQ 1 then do;
  QuantilesList = "Min:" || compress(put(&Var,&Format));
  Boundary=&Var;
  BinFreq = CEIL( &Nobs / &QuantileCount );
  LastBinFreq = &Nobs - (BinFreq * (&QuantileCount - 1));
  call symput('BinFreq',compress(put(BinFreq,9.)));
  NeedleHeight = BinFreq;
  output;
  return;
end;
HowManySoFar + 1;
if LastOne then do;
  QuantileIndex + 1;
  QuantilesList = trim(QuantilesList) || ", Q" || compress(put(QuantileIndex,3.)) || "/Max:" || compress(put(&Var,&Format));
  if LastBinFreq EQ BinFreq
  then Title2Text = "&Nobs Values in &QuantileCount Bins of " || compress(BinFreq) || " values each";
  else Title2Text = "&Nobs Values in " || compress(&QuantileCount - 1) || " Bins of " || compress(BinFreq) || 
                    " values each and Last Bin with " || compress(LastBinFreq) || " values";
  call symput('Title2Text',trim(left(Title2Text)));
  Boundary = PreviousBoundary;
  BinFreq = LastBinFreq;
  NeedleHeight = .;
  output;
  Boundary = &Var;
  NeedleHeight = LastBinFreq;
  output;
  call symput('QuantilesList',compress(QuantilesList));
  stop;
end;
if HowManySoFar EQ BinFreq
then do;
  QuantileIndex + 1;
  if QuantileIndex EQ 1 OR QuantileIndex EQ (&QuantileCount - 1) 
  then NeedleHeight = BinFreq;
  else NeedleHeight = .; 
  QuantilesList = trim(QuantilesList) || ", Q" || compress(put(QuantileIndex,3.)) || ":" || compress(put(&Var,&Format));
  Boundary = &Var;
  BinCount + 1;
  output;
  HowManySoFar = 0;
  PreviousBoundary = Boundary;
end;
run;

data work.ToPlot;
merge work.Sorted work.Binned;
by &Var;
run;

ods graphics on / reset=all scale=off 
%if %length(&ImageWidth) NE 0 %then %do;
  width=&ImageWidth
%end;
%if %length(&ImageHeight) NE 0 %then %do;
  height=&ImageHeight
%end; 
  imagename="&ImageName";
title1 justify=left "&QuantileCount Quantiles Distribution of &Var in &Data";
title2 justify=left "&Title2Text";
title3 justify=left "&QuantilesList";
title4 justify=left "Red: " color=red "Min, First Quantile, Second from Last Quantile, Max/Last Quantile";

%if %length(&SubTitle) NE 0 %then %do;
title5 justify=left "&SubTitle";
%end;
proc sgplot data=work.ToPlot noborder
%if &Fringe EQ N %then %do;
  noautolegend
%end;
  ;
series x=Boundary y=BinFreq /
  lineattrs=(color=black thickness=1px pattern=solid);
needle x=Boundary y=BinFreq / displaybaseline=off
  lineattrs=(color=&BoundaryNeedleColor thickness=1px pattern=solid);
needle x=Boundary y=NeedleHeight / displaybaseline=off
  lineattrs=(color=red thickness=1px pattern=solid)
  datalabel=Boundary datalabelpos=top datalabelattrs=(color=red);
%if &Fringe EQ Y %then %do;
fringe &Var / name='fringe' legendlabel="Instances of &Var (may be duplicates)"
  height=15px lineattrs=(color=blue thickness=1px pattern=solid);
  %let BoundaryNeedleColor=gray;
%end; 
xaxis display=(nolabel noline)
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
yaxis display=(nolabel noline noticks) 
  values=(0 to &BinFreq by &BinFreq)
  thresholdmax=1;
label Boundary="&Var";
format Boundary &Format;
%if &Fringe EQ Y %then %do;
keylegend 'fringe' / noborder valueattrs=(color=blue);
%end;
run;

%MacroExit:

%mend HistogramWithQuantilesAsBins;
