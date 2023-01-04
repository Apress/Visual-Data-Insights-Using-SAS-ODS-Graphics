/* About This BinsForHeatMap Macro */

/* This macro assigns input data to bins in a way that SAS
software does not. It allows a user to accomplish a result which
SAS software cannot support. It also makes axis values for the
bins available via the global symbol table, from which they can
be retrieved by the HeatMapAnnoAndColorLegend macro.

The X and Y axis values that are created as macro variables near
the end of this macro processing are AVERAGES within each bin.
To create its heat map output, an SGPLOT step must retrieve
those macro variables in AXIS statements.

Although the bins are equally sized, the averages of the X and Y
values for data within those bins are NOT equally spaced. Since
these axis values are averages, not midpoints, there could be
two successive axis values separated by as little as 1. 

The last thing in this macro is the code for the Get macro,
which is needed by any subsequent processing that would work
with this macro's outputs. */ 

%macro BinsForHeatMap(
data=
,out=
,ResponseVar=
,Xvar=
,roundForXincr=0.2
,nXbins=
,Yvar=
,roundForYincr=0.2
,nYbins=
);

data 
  work.ToBinning(keep=NonMissingObsID &Xvar &Yvar) 
  work.ResponseVarWithObsID(keep=NonMissingObsID &ResponseVar);
set &data
  (keep=&Xvar &Yvar &ResponseVar);
where &Xvar NE . and &Yvar NE .;
NonMissingObsID=_N_;
run;

proc means data=work.ToBinning noprint;
var &Yvar &Xvar;
output out=work.FromMEANS 
  N=NonMissingObsCount min=MinYvar MinXvar max=MaxYvar MaxXvar;
run;

%global ObsCount; /* make it accessible outside of this macro */

data _null_;
set work.FromMEANS;
call symput('ObsCount',trim(left(NonMissingObsCount)));
call symput('MinYvar',MinYvar);
call symput('MinXvar',MinXvar);
call symput('MaxYvar',MaxYvar);
call symput('MaxXvar',MaxXvar);
call symput('RangeYvar',MaxYvar - MinYvar );
call symput('RangeXvar',MaxXvar - MinXvar);
call symput('IncrYvar',
  round(((MaxYvar - MinYvar) / &nYbins),&roundForYincr));
call symput('IncrXvar',
  round(((MaxXvar - MinXvar) / &nXbins),&roundForXincr));
run;

%macro Binning(var=,min=,max=,incr=,nbins=);

%do i = 1 %to %eval(&nbins - 1) %by 1;

if &var LE %sysevalf(&min + &i*&incr)
then bin = &i;
else 

%end;

%mend  Binning;

options mprint;

proc sort data=work.ToBinning out=work.ByYvar;
by &Yvar;
run;

data work.YvarBins(keep=NonMissingObsID bin &Yvar);
set work.ByYvar;
%Binning(var=&Yvar,min=&MinYvar,incr=&IncrYvar,nbins=&nYbins)
bin = &nYbins;
run;

/* You COULD check the SAS log after the run of this macro
   to verify that there are no more than nYbins for Yvar, 
   but there might be some void(s). */
proc sort data=work.YvarBins out=DistinctYvarBins nodupkey;
by bin;
run;

proc sort data=work.ToBinning out=work.ByXvar;
by &Xvar;
run;

data work.XvarBins(keep=NonMissingObsID bin &Xvar);
set work.ByXvar;
%Binning(var=&Xvar,min=&MinXvar,incr=&IncrXvar,nbins=&nXbins)
bin = &nXbins;
run;

/* You COULD check the SAS log after the run of this macro
   to verify that there are no more than nXbins for Xvar, 
   but there might be some void(s). */
proc sort data=work.XvarBins out=DistinctXvarBins nodupkey;
by bin;
run;

proc summary data=work.YvarBins nway;
class bin;
var &Yvar;
output out=work.BinYvarAvgs(drop=_freq_ _type_) mean=;
run;

data work.BinnedYvar;
merge work.YvarBins(drop=&Yvar) work.BinYvarAvgs;
by bin;
&Yvar = round(&Yvar,1);
run;

proc summary data=work.XvarBins nway;
class bin;
var &Xvar;
output out=work.BinXvarAvgs(drop=_freq_ _type_) mean=;
run;

data work.BinnedXvar;
merge work.XvarBins(drop=&Xvar) work.BinXvarAvgs;
by bin;
&Xvar = round(&Xvar,1);
run;

proc sort data=work.BinnedYvar;
by NonMissingObsID;
run;

proc sort data=work.BinnedXvar;
by NonMissingObsID;
run;

data &out(drop=bin);
merge work.BinnedYvar(in=InYvar) 
      work.BinnedXvar(in=InXvar) 
      work.ResponseVarWithObsID(in=ResponseData);
by NonMissingObsID;
if not InYvar  then do;
  put "Missing &Yvar Value for Join " 
      NonMissingObsID= bin= &Xvar=;
  delete;
end;
else
if not InXvar then do;
  put "Missing &Xvar Value for Join " 
      NonMissingObsID= bin= &Yvar=;
  delete;
end;
else
if not ResponseData then do;
  put "Missing &ResponseVar Value for Join " 
      NonMissingObsID= bin= &Xvar= &Yvar=;
  delete;
end;
else output;
run;

 /* Restore gaps in the X bins.
    This is an example DATA step
    from a past situation.
data work.BinXvarAvgs;
set work.BinXvarAvgs end=LastOne;
output;
if LastOne;
&Xvar = 462;
output;
&Xvar = 509;
output;
run;
 */

%macro Globals(Prefix=,N=);

%do i = 1 %to &N %by 1;
  %global &Prefix&i;
%end;

%mend  Globals;

proc sort data=work.BinXvarAvgs;
by &Xvar;
run;

%Globals(Prefix=Xvalue,N=&nXbins); 
/* need to access these outside of this macro */

%global Xcount; /* need to access it outside of this macro */

data _null_;
set work.BinXvarAvgs end=LastOne;
call symput('Xvalue'||trim(left(_N_)),
            trim(left(round(&Xvar,1))));
if LastOne;
call symput('Xcount',trim(left(_N_)));
run;

proc sort data=work.BinYvarAvgs;
by &Yvar;
run;

%Globals(Prefix=Yvalue,N=&nYbins); 
/* need to access these outside of this macro */

%global Ycount; /* need to access it outside of this macro */

data _null_;
set work.BinYvarAvgs end=LastOne;
call symput('Yvalue'||trim(left(_N_)),
            trim(left(round(&Yvar,1))));
if LastOne;
call symput('Ycount',trim(left(_N_)));
run;

/* The Get macro is included here so that it will be available
when needed outside of this macro. It must be used in XAXIS and
YAXIS statements to retrieve axis values created above as macro
variables. It is also in the HeatMapAnnoAndColorLegend macro. */

%macro Get(Value=,Count=); 

%do i = 1 %to &Count %by 1;
  &&&Value&i
%end;
%mend  Get;

%mend BinsForHeatMap;
