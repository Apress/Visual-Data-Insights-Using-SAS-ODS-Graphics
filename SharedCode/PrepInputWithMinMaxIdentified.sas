
%macro PrepInputWithMinMaxIdentified(
Data=,
OutForPlot=,
OutForMinMaxByClass=,
ClassVar=,
Yvar=,
YvarFormat=,
Xvar=);

/* get min & max values and their dates (X values) */

proc summary data=&Data nway;
class &ClassVar;
var &Yvar;
output out=work.MinYandXbyClass(drop=_type_ _freq_)
  minid(&Yvar(&Xvar))=&Xvar min=MinY;
run;

proc summary data=&Data nway;
class &ClassVar;
var &Yvar;
output out=work.MaxYandXbyClass(drop=_type_ _freq_)
  maxid(&Yvar(&Xvar))=&Xvar max=MaxY;
run;

/* add the min & max values to those observations
   where they belong */

data &OutForPlot;
label MinY="&ClassVar Minimum &Yvar";
label MaxY="&ClassVar Maximum &Yvar";
merge &Data(in=BasicInfo)
      work.MinYandXbyClass
      work.MaxYandXbyClass;
by &ClassVar &Xvar;
if BasicInfo;
run;

/* create min/max macro variables */

proc summary data=&data;
class &ClassVar;
var &Yvar;
output out=work.SummaryAllAndByClass
  min=MinY max=MaxY;
run;

%global MinY MaxY MinYdisplay MaxYdisplay;
data _null_;
set work.SummaryAllAndByClass;
where _type_ EQ 0; /* for ALL Class values */
call symput('MinY',MinY);
call symput('MinYdisplay',compress(put(MinY,&YvarFormat.)));
call symput('MaxY',MaxY);
call symput('MaxYdisplay',compress(put(MaxY,&YvarFormat.)));
run;

%if %length(&OutForMinMaxByClass) NE 0 %then %do;

/* min/max by class for other possible use */

data &OutForMinMaxByClass;
set work.SummaryAllAndByClass;
where _type_ EQ 1; /* for each Class value */
run;

%end;

%mend  PrepInputWithMinMaxIdentified;
