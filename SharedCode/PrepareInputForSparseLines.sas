
%macro PrepareInputForSparseLines(
Data=,
Out=,
ClassVar=,
ClassVarFormat=,
Yvar=,
YvarFormat=,
Xvar=,
XvarFormat=,
LastChangePosCount=);

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

data work.DataPlusMinMaxYandAssociatedX;
label MinY="&ClassVar Minimum &Yvar";
label MaxY="&ClassVar Maximum &Yvar";
merge &Data(in=BasicInfo)
      work.MinYandXbyClass
      work.MaxYandXbyClass;
by &ClassVar &Xvar;
if BasicInfo;
run;

/* prepare input for the sparse lines */

%let LastChangePosCountPlusOne = %sysevalf(&LastChangePosCount + 1);

data &Out;
length FirstBottomDataLabel LastTopDataLabel $ 16;
length LastChangeY_Label $ 6;
retain MinY MaxY PrevY;
format &Xvar &XvarFormat;
format &Yvar FirstY LastY 
       IntermediateMinY IntermediateMaxY &YvarFormat;
set work.DataPlusMinMaxYandAssociatedX;
by &ClassVar;
if First.&ClassVar then do;
  FirstY = &Yvar;
  FirstTopDataLabel = compress(put(&ClassVar,&ClassVarFormat));
  FirstBottomDataLabel = compress(put(&Yvar,&YvarFormat) || ',' ||
    trim(left(put(&Xvar,&Xvarformat))));
end;
if not Last.&ClassVar then PrevY = &Yvar;
if Last.&ClassVar then do;
  LastY = &Yvar;
  LastTopDataLabel = compress(put(&Yvar,&YvarFormat) || ',' || 
    trim(left(put(&Xvar,&Xvarformat))));
  LastChangeY = round((&Yvar - PrevY),0.1);
  if LastChangeY GE 0
  then LastChangeY_Label = '+' || trim(left(put(LastChangeY,&LastChangePosCount..1)));
  else LastChangeY_Label = trim(left(put(LastChangeY,&LastChangePosCountPlusOne..1)));
                           /* minus sign is automatically added */ 
end;
if MinY NE FirstY AND MinY NE LastY
then IntermediateMinY = MinY;
if MaxY NE FirstY AND MaxY NE LastY
then IntermediateMaxY = MaxY;
run;

/* create min/max macro variables */

proc summary data=&data;
class &ClassVar;
var &Yvar;
output out=work.MinMaxBy&ClassVar
  min=MinY max=MaxY;
run;

%global MinY MaxY MinYdisplay MaxYdisplay;
data _null_;
set work.MinMaxBy&ClassVar;
where _type_ EQ 0;
call symput('MinY',MinY);
call symput('MinYdisplay',compress(put(MinY,&YvarFormat.)));
call symput('MaxY',MaxY);
call symput('MaxYdisplay',compress(put(MaxY,&YvarFormat.)));
run;

%mend  PrepareInputForSparseLines;
