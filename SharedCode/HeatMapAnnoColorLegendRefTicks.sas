
/* About This HeatMapAnnoAndColorLegendRefTicks Macro */

/* This macro creates a heat map, 
using X, Y, and a response variable.
It can optionally provide a gradient legend.
It can optionally annotate the heat map cells.
It can optionally provide reference X and Y axis values 
at the top and right side of the heat map. 
The REFTICKS option for the XAXIS statement and YAXIS statement 
does this, but the macro suppresses the tick marks.

It assumes that predecessor processing, such as that done by the 
macros BinsForHeatMap or OneXYperCellForHeatMap has been done.
They store X and Y values in the global symbol table that are 
retrieved by the HeatMapAnnoAndColorLegend macro.

For each input X-Y pair, the macro determines the average of the 
response variable. At the same time, it also makes available the 
frequency count for each X-Y pair. 

What variable, if any, is assigned to AnnoVar for annotation.
is optional. This macro requires ColorVar to be assigned.
AnnoVar and ColorVar may be the same variable, but need not be.

See examples of what the macro can do in Figures 6-15, 6-16, 
6-17, and 6-18, using its invocation code in those Listings. 

In retrospect, I don't recall why I made the legend optional. 
It helps explain the heat map. */

%macro HeatMapAnnoColorLegendRefTicks(
data=
,OneXYperCell=NO /* YES or NO */
,Xvar=
,Yvar=
,ResponseVar=
,AnnoVar=  /* Needed if DoAnnotate=YES */
,ColorVar= /* Always Needed. May be same as AnnoVar. */
,ImageFileName=
,ImageFolder=C:\temp
,ImageWidth=
,ImageHeight=
,DPI=
,Xgrid=NO
,Ygrid=NO
,RefTicksForX=NO /* YES: duplicate XAXIS values at top */
,RefTicksForY=NO /* YES: duplicate YAXIS values at right side */
,GraphFontSize=
,TitleAndFootnoteHeight= /* use this only if different from GraphFontSize */
,AnnotateFontSize=       /* use this only if different from GraphFontSize */
,LegendTitle=YES
,LegendTitleText=
,RattrMap=
,RattrID=
,ColorModel= /* If used, this must be 
                a blank-separated string of color names */ 
/* If you specify both ColorModel AND RattrMap & RattrID.
   ONLY ColorModel will be used. */
/* If neither RattrMap & RattrID nor ColorModel are specified,
   then the default ThreeColorRamp will be used. */
,DoAnnotate=  /* valid values are YES, NO, or null */
,BackFill=    /* valid values are YES, NO, or null */
,BackLight=   /* valid values are YES, NO, or null,
                 if BackFill=YES, BackLight is ignored */
,TitleAndFootnoteJustify=left /* automatic TITLE3 and TITLE4
                                 are left-justified */
,Title1=
,Title2=
,Title5=
,FootNote1=
,FootNote2=
);

%if %upcase(&RefTicksForX) EQ YES
  OR
    %upcase(&RefTicksForY) EQ YES
%then %do;
ods path(prepend) work.template(update);
proc template;
define style StyleWhenRefTicksPresent;
  parent=GraphFontArial&GraphFontSize.Bold;
  style graphaxislines from graphaxislines / linethickness=0px;
end;
run
%end;

proc summary data=&data nway;
class &Xvar &Yvar;
var &ResponseVar;
output out=work.SUMMARYout mean=Avg&ResponseVar;
run;

proc means data=work.SUMMARYout noprint;
var Avg&ResponseVar;
output out=work.stats;
run;

data _null_;
set work.stats;
if _stat_ EQ 'N'
then call symput('NonEmptyHeatMapCells',
                 trim(left(put(Avg&ResponseVar,10.)))); 
                 /* Prepared for 1 Billion! :-) */
if _stat_ EQ 'MIN'
then call symput("Min_&ResponseVar",
                 trim(left(put(Avg&ResponseVar,2.))));
else if _stat_ EQ 'MAX'
then call symput("Max_&ResponseVar",
                 trim(left(put(Avg&ResponseVar,4.))));
else if _stat_ EQ 'MEAN'
then call symput("Mean_&ResponseVar",
                 trim(left(round(Avg&ResponseVar,0.1))));
else if _stat_ EQ 'STD'
then call symput("StdDev_&ResponseVar",
                 trim(left(round(Avg&ResponseVar,0.1))));
run; 

%macro Get(Value=,Count=); /* Used in AXIS statements */ 

%do i = 1 %to &Count %by 1;
  &&&Value&i
%end;
%mend  Get;

ods results=off;
ods _all_ close;

%if %upcase(&RefTicksForX) EQ NO
  AND
    %upcase(&RefTicksForY) EQ NO
%then %let StyleForHeatMap = GraphFontArial&GraphFontSize.Bold;
%else %let StyleForHeatMap = StyleWhenRefTicksPresent;

ods listing style=&StyleForHeatMap
  gpath="&ImageFolder" 
%if %length(&DPI) NE 0 %then %do;
  dpi=&dpi
%end;
  ;

ods graphics / reset=all scale=off 
  width=&ImageWidth 
  height=&ImageHeight
  imagename="&ImageFileName";

title1
%if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
%end;
  justify=&TitleAndFootnoteJustify "&Title1"; 
title2
%if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
%end;
  justify=&TitleAndFootnoteJustify "&Title2";
title3 
%if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
%end;
  justify=&TitleAndFootnoteJustify 
  "For &ObsCount Observations in &Ycount &Yvar Bins, &Xcount &Xvar Bins, & &NonEmptyHeatMapCells Cells";
title4 
%if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
%end;
  justify=&TitleAndFootnoteJustify  
  "Range of Avg &ResponseVar is &&Min_&ResponseVar.-&&Max_&ResponseVar with Mean &&Mean_&ResponseVar & Standard Deviation &&StdDev_&ResponseVar";
%if %length(&Title5) NE 0 %then %do;
title5 
%if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
%end;
  justify=&TitleAndFootnoteJustify color=blue "&Title5";
%end;
%else %do;
title5 height=1pt ' '; /* minimize the white space for the missing TITLE5 */
%end;
%if &OneXYperCell NE YES %then %do;
title6 
%if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
%end;
  justify=&TitleAndFootnoteJustify
  "All bins are equal width, but axis values are averages, not bin midpoints.";
title7 
%if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
%end;
  justify=&TitleAndFootnoteJustify
  "So the increment between axis values along an axis can vary.";
%end;
%else %do;
title6 
%if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
%end;
  justify=&TitleAndFootnoteJustify
  "Each bin is for only one rounded value of &Xvar or &Yvar.";
title7 
%if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
%end;
  justify=&TitleAndFootnoteJustify
  "Each cell is only one &Xvar-&Yvar, but may be for multiple data points.";
%end;
%if %length(&FootNote1) NE 0 %then %do;
footnote1 
  %if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
  %end; 
  justify=&TitleAndFootnoteJustify "&FootNote1";
%end;
%if %length(&FootNote2) NE 0 %then %do;
footnote2
  %if %length(&TitleAndFootnoteHeight) NE 0 %then %do;
  height=&TitleAndFootnoteHeight
  %end; 
  justify=&TitleAndFootnoteJustify "&FootNote2"; 
%end;

proc sgplot data=work.SUMMARYout
%if %length(&RattrMap) NE 0 %then %do;  
  rattrmap=&RattrMap
%end;
;
heatmap x=&Xvar y=&Yvar / outline
  colorresponse=&ColorVar
%if %length(&RattrID) NE 0 %then %do;
  rattrid=&RattrID 
%end;
%else
%if %length(&ColorModel) NE 0 %then %do;
  ColorModel=(&ColorModel)
%end; 
  discretex discretey;
%if &DoAnnotate EQ YES %then %do;
text x=&Xvar y=&Yvar text=&AnnoVar / strip
  %if &BackFill EQ YES %then %do; 
  backfill fillattrs=(color=white)
  %end;
  %else
  %if &BackLight EQ YES %then %do;
  backlight=1
  %end;
  textattrs=(family=ArialBlack /* thicker than Arial */
  %if %length(&AnnotateFontSize) NE 0 %then %do; 
             size=&AnnotateFontSize
  %end;
            );
%end;
xaxis display=(noline noticks nolabel)
%if &Xgrid EQ YES %then %do;
  grid
%end;
%if &RefTicksForX EQ YES %then %do;
  refticks=(values)
  tickstyle=inside
%end;
  fitpolicy=none /* prevent thinning */
  values=( %Get(Value=Xvalue,Count=&Xcount) );          
yaxis display=(noline noticks nolabel)
%if &Ygrid EQ YES %then %do;
  grid
%end;
%if &RefTicksForY EQ YES %then %do;
  refticks=(values)
  tickstyle=inside
%end;
  fitpolicy=none /* prevent thinning */
  values=( %Get(Value=Yvalue,Count=&Ycount) );
format AvgDiastolic 3.;
gradlegend / integer
%if &LegendTitle EQ YES %then %do; 
  title=
  %if %length(&LegendTitleText) NE 0 %then %do;
  "&LegendTitleText";
  %end;
  %else
  %if &ColorVar EQ _freq_ %then %do;
  'Frequency';
  %end;
  %else %do; 
  "Average &ResponseVar";
  %end; 
%end;
%else %do;
  notitle;
%end;
run;

ods listing close;

%mend HeatMapAnnoColorLegendRefTicks;
