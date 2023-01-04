%macro InformativeBoxPlot(
data=,
where=,
var=,
varlabel=,
format=,
ShowOutliers=Y,
XaxisOffsetMin=,
XaxisOffsetMax=,
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
  /* other data items available include:
     qrange (computable later with q1 and q3)
     percentiles P1 P5 P10 P90 P95 P99 */
  min=min&var q1=q1&var median=median&var 
  mean=mean&var q3=q3&var max=max&var 
  range=range&var std=std&var nobs=nobs&var sum=Total&var;
run;

data _null_;
set work.statistics;
call symput('LowerFence',trim(left(q1&var - 1.5 * (q3&var - q1&var))));
call symput('UpperFence',trim(left(q3&var + 1.5 * (q3&var - q1&var))));
run;

options nosource;
%put LowerFence = &LowerFence;
%put UpperFence = &UpperFence;
options source;

proc sort data=work.Extract out=work.Sorted;
by &var;
run;

data _null_;
length Outliers $ 1024 LowerWhisker UpperWhisker $ 32;
retain Outliers 'X' LowerWhisker UpperWhisker ' ';
set work.Sorted end=LastOne;
if &var LT &LowerFence OR &var GT &UpperFence
then do;
  if Outliers EQ 'X'
  then Outliers = compress(put(&var,&format));
  else Outliers = trim(left(Outliers)) || ', ' ||
                  compress(put(&var,&format));
end;
if LowerWhisker EQ ' '
  and
   &var GE &LowerFence
then LowerWhisker = compress(put(&var,&format));
if &var LE &UpperFence
then UpperWhisker = compress(put(&var,&format));
if LastOne;
call symput('Outliers',trim(left(Outliers)));
  /* Use of COMPRESS above would remove blanks between values */ 
call symput('LowerWhisker',compress(LowerWhisker));
call symput('UpperWhisker',compress(UpperWhisker));
run;

options nosource;
%put Look Between LLL and RRR;
%put Outliers = LLL&Outliers.RRR;
%put LowerWhisker = LLL&LowerWhisker.RRR;
%put UpperWhisker = LLL&UpperWhisker.RRR;
options source;

data _null_;
set work.statistics;
call symput('min',compress(put(min&var,&format)));
call symput('minvalue',min&var);
call symput('Q1',compress(put(q1&var,&format)));
call symput('median',compress(put(median&var,&format)));
call symput('mean',compress(put(mean&var,&format)));
call symput('Q3',compress(put(q3&var,&format)));
call symput('max',compress(put(max&var,&format)));
call symput('maxvalue',max&var);
call symput('range',range&var);
call symput('std',compress(put(std&var,13.2)));
call symput('Nobs',compress(put(Nobs&var,10.)));
call symput("Total",compress(put(Total&var,&format)));
run;

proc summary data=work.Extract nway;
where &var NE .;
class &var;
var &var;
output out=work.freq(keep=&var _freq_) sum=OfNoRealInterest;
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
&var = 333;
_freq_ = &FreqMax;
output;
run;
proc sort data=work.freq;
by &var;
run;
   To simulate case where multiple responses share maximum freq */

data _null_;
length MaxFreqAndWhere $ 64.;
retain MaxFreqAndWhere ' ';
keep &var MaxFreq;
set work.freq end=LastOne;
if _freq_ EQ &FreqMax
then do;
  MaxFreq = _freq_;
/* Since multiple X values might have the maximum response: */
  if MaxFreqAndWhere EQ ' '
  then MaxFreqAndWhere = compress(put(_freq_,9.) || '@' || put(&var.,&format));
  else MaxFreqAndWhere = compress(MaxFreqAndWhere || ',' || put(&var.,&format));
end;
if LastOne then do;
  put 'Last One - ' MaxFreqAndWhere=; 
  call symput('MaxFreqAndWhere',trim(left(MaxFreqAndWhere)));
end;
run;

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
  %let NextTITLE = 3; 
%end;
%else %let NextTITLE = 2;
%if %length(&Subtitle) NE 0 %then %do;
title&NextTITLE justify=left "&Subtitle";
%end;
footnote1 justify=left "&Nobs Values, Standard Deviation &std";
footnote2 justify=left "Maximum Frequency: &MaxFreqAndWhere";
footnote3 justify=left color=red "Minimum &min and Maximum &max";
footnote4 justify=left "Left End of Lower Whisker &LowerWhisker";
footnote5 justify=left "First Quartile (left edge of box) &Q1"; 
footnote6 justify=left "Median (vertical bar in box) &median";
footnote7 justify=left color=red "Mean (diamond in box) &mean";
footnote8 justify=left "Third Quartile (right edge of box) &Q3";
footnote9 justify=left "Right End of Upper Whisker &UpperWhisker";
%if &ShowOutliers EQ N %then %do;
footnote10 justify=left color=blue "Outliers (not shown): &Outliers";
%end;
proc sgplot data=work.Extract noborder;
hbox &var /
%if &ShowOutliers EQ Y %then %do; 
  datalabel datalabelattrs=(color=blue)
  /* data labels are provided only for the outliers */
  spread /* not always really needed,
    only has effect if there are duplicate outlier values */     
  outlierattrs=(color=blue symbol=CircleFilled)
%end;
%else %do;
  nooutliers
%end;     
  fillattrs=(color=yellow)
  medianattrs=(color=black thickness=3px) /* Make this thicker
    if too hidden when overlaid by the mean red diamond. 
    With this image height, enough of the median line is exposed
    above and below the mean diamond */
  meanattrs=(color=red symbol=DiamondFilled)
  lineattrs=(thickness=3px)
  whiskerattrs=(thickness=3px)
  nocaps /* no bars at the ends of the whiskers */
  outlierattrs=(color=blue symbol=Circle); /* open circles are more
    distiguishable when overlaid */
%if &ShowOutliers EQ Y %then %do;
  /* If Y, one or both offsets might be needed,
  to prevent clipping of the most extreme outlier data labels.
  A prior run of this macro with N will present a complete
  list of all of the outliers in FOOTNOTE10 of the image.
  That list can be compared with the output from the run with Y. 
  Increasing the offset can also eliminate data label overlays. */
xaxis display=none
  %if %length(&XaxisOffsetMax) NE 0 %then %do;
  offsetmax=&XaxisOffsetMax
  %end;
  %if %length(&XaxisOffsetMin) NE 0 %then %do;
  offsetmin=&XaxisOffsetMin
  %end;
  ;
%end;
%else %do;
xaxis display=(noline noticks nolabel) 
  values=(&minValue to &maxValue by &range)
  valueattrs=(color=red) 
  grid gridattrs=(color=red thickness=2px); /* use black 
         to make grid lines more conspicuous */
%end;
format &var &format; 
run;
  /* FOOTNOTE1 assures that any subsequent code run during the same
     SAS session does not inherent the footnotes created above */
footnote1;
%mend InformativeBoxPlot;
