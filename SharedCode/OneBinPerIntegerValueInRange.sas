
/* The source code for the OneBinPerIntegerValueInRange macro
   and this invocation code are in Appendix A12-09. */

/* NOTE: The result includes gaps for values that are missing within the range. */
/*       This is a necessity for this macro, not a defect.                      */

%macro OneBinPerIntegerValueInRange(
data=,
where=,
var=,
RoundedFormat=,
stagger=N,
imagewidth=,
imageheight=,
imagename=,
subtitle=);

data work.RoundedResponse(keep=Rounded);
format Rounded &RoundedFormat;
set &data
%if %length(&where) NE 0 %then %do;
(where=(&where))
%end;
  ;
Rounded = round(&var);
run;

proc sql noprint;
select count(Rounded),min(Rounded),max(Rounded) into :Nobs trimmed,:Min trimmed,:Max trimmed
from work.RoundedResponse;
quit;

%let BinCount = %sysevalf(&Max - &Min + 1);

ods graphics on / reset=all scale=off
%if %length(&imagewidth) NE 0 %then %do;
  width=&imagewidth
%end; 
%if %length(&imageheight) NE 0 %then %do;
  height=&imageheight
%end;
  imagename="&imagename";
title1 "Histogram of &var - &data Data Set - &Nobs Values";
%if %length(&subtitle) NE 0 %then %do;
title2 "&subtitle";
%end;
proc sgplot data=work.RoundedResponse noborder;
histogram Rounded / 
  nbins=&BinCount /* includes any empty bins */ 
  outline
  fill fillattrs=(color=CX9999FF)
  scale=count datalabel=count;
xaxis display=(nolabel noline noticks)
%if &Stagger EQ Y %then %do;
  fitpolicy=stagger
%end;
%else %do;
  fitpolicy=none /* do not trim values */
%end;
  values=(&Min to &Max by 1);
yaxis display=none; 
run;

%mend OneBinPerIntegerValueInRange;
