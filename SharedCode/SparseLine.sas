
%macro SparseLine(Var=,
Filter=,
Data=,
Format=, /* allow space for minus sign to handle when last change is negative */
DPI=300,
ImageWidth=6.5in,
ImageHeight=2in,
DateDisplayFormat=DATE7., /* use MONYY5. for monthly data   */
                          /* use YEAR4.  for yearly data    */
                          /* use YYQ4.   for quarterly data */  
TitleText=,
TargetFolder=C:\temp,
ImageName=,
Font=Arial,
FontSize=11pt,
FontWeight=Bold);

proc means data=&Data min max noprint;
  &Filter;
  var &Var;
  output out=MinMax;
run;

data _null_;
set MinMax end=LastOne;
retain MinY MaxY;
if _STAT_ EQ 'MIN'
then do;
  MinY = &Var;
  call symput('MinY',&Var);
  call symput('DisplayMinY',put(&Var,&Format));
end;
else
if _STAT_ EQ 'MAX'
then do;
  MaxY = &Var;
  call symput('MaxY',&Var);
  call symput('DisplayMaxY',put(&Var,&Format));
end;
if LastOne;
call symput('YvalueRange',MaxY - MinY);
run;

data work.ToBeUsed;
keep Date &Var;
set &Data;
&Filter;
run;

proc sort data=work.ToBeUsed;
by Date;
run;

%let NoIntermediateMinY = N;
%let NoIntermediateMaxY = N;

data _null_;
length label $ 4;
retain SecondLast_N_ SecondLastValue 0;
if _N_ EQ 1 then SecondLast_N_ = ObsCount - 1;
set work.ToBeUsed end=LastOne nobs=ObsCount;
if _N_ EQ 1
then do;
  call symput('StartX',Date);
  call symput('StartY',&Var);
  call symput('DisplayStartY',put(&Var,&Format));
  if &Var EQ &MinY
  then call symput('NoIntermediateMinY','Y');
  if &Var EQ &MaxY
  then call symput('NoIntermediateMaxY','Y');
end;
else 
if _N_ EQ SecondLast_N_
then SecondLastValue = &Var;
else
if LastOne 
then do;
  call symput('EndX',Date);
  call symput('EndY',&Var);
  call symput('DisplayEndY',put(&Var,&Format));
  if &Var EQ &MinY
  then call symput('NoIntermediateMinY','Y');
  if &Var EQ &MaxY
  then call symput('NoIntermediateMaxY','Y');
  change = &Var - SecondLastValue;
  if change GE 0
  then label = '+' || trim(left(put(change,&Format)));
  else label = '-' || trim(left(put(change,&Format)));
  put change=;
  put label=;
  call symput('LastChange',trim(left(label)));
end;
if _N_ NE 1 and NOT LastOne
then do;
  if &Var EQ &MinY
  then call symput('MinX',Date);
  if &Var EQ &MaxY
  then call symput('MaxX',Date);
end;
run;

data work.Start work.End work.Max work.Min;
Date = &StartX;
&Var = &StartY;
Start = "&DisplayStartY" || ',' || put(Date,&DateDisplayFormat);
output work.Start;
Date = &EndX;
&Var = &EndY;
End = "&DisplayEndY" || ',' || put(Date,&DateDisplayFormat);
output work.End;
if "&NoIntermediateMinY" EQ 'N'
then do;
  Date = &MinX;
  &Var = &MinY;
  Min = "&DisplayMinY" || ',' || put(Date,&DateDisplayFormat);
  output work.Min;
end;
if "&NoIntermediateMaxY" EQ 'N'
then do;
  Date = &MaxX;
  &Var = &MaxY;
  Max = "&DisplayMaxY" || ',' || put(Date,&DateDisplayFormat);
  output work.Max;
end;
run;

data work.LastChange;
length LastChange $ 4;
Date = &EndX;
&Var = &EndY;
LastChange = "&LastChange";
output;
run;

data work.Merged;
drop Start End LastChange Min Max;
merge work.ToBeUsed work.Start(in=InStart) 
      work.End(in=InEnd) work.LastChange(in=InLastChange) 
      work.Min(in=InMin) 
      work.Max(in=InMax);
by Date;
if InStart      then MergeStart=Start;
if InEnd        then MergeEnd=End;
if InLastChange then MergeLastChange=LastChange;
if InMin        then MergeMin=Min;
if InMax        then MergeMax=Max;
run;

ods results off;
ods _all_ close;
ods listing gpath="&TargetFolder" style=LISTING dpi=&DPI; 
ods graphics on / 
  reset=all
  scale=off 
  border=on
  width=&ImageWidth 
  height=&ImageHeight 
  imagename="&ImageName";
title1 justify=center height=&FontSize font=&Font Bold "&TitleText";
title2 justify=center height=&FontSize font=&Font Bold 
  "Critical Points and Last Change";
proc sgplot data=work.Merged noborder noautolegend pad=3%;
series x=Date y=&Var / 
  markers
  markerattrs=(color=Blue symbol=CircleFilled) 
    /* default symbol is an open Circle */ 
  lineattrs=(color=Red pattern=Solid thickness=3);
text x=Date y=&Var Text=MergeStart / position=topleft
  textattrs=(family=&Font size=&FontSize weight=&FontWeight);
text x=Date y=&Var Text=MergeEnd / position=topright 
  textattrs=(family=&Font size=&FontSize weight=&FontWeight);
text x=Date y=&Var Text=MergeLastChange / position=bottom 
  textattrs=(family=&Font size=&FontSize weight=&FontWeight);
text x=Date y=&Var Text=MergeMin / position=bottom 
  textattrs=(family=&Font size=&FontSize weight=&FontWeight);
text x=Date y=&Var Text=MergeMax / position=top 
  textattrs=(family=&Font size=&FontSize weight=&FontWeight); 
yaxis 
  values=(&MinY to &MaxY by &YvalueRange) 
  display=(noline noticks nolabel) valuesdisplay=(''  '');
xaxis display=none;  
run;
 
ods listing close;

%mend SparseLine;
