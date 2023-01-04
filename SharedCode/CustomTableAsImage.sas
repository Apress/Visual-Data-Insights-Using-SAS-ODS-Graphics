
%macro CustomTableAsImage(
parent=PRINTER,
CustomStyleName=,
Family=Arial,
Size=11pt,
Weight=Bold,
tablegridoff=, /* use YES to turn it off, leave unassigned for NO */
NonDefaultCellHeight=, /* if non-null (As Is here),
  this macro will internally set tablegridoff=YES.
  The presumption is that a nonDefault CellHeight is for compaction,
  in which case a table and the cell content would collide. */
dpi=300,
title=%str(),
title_justify=left,
title_color=black,
whitespaceabovetitleInPts=,
center=NO,
date=NO,
imagefolder=,
imagefilename=, /* filetype is PNG */
data=,
where=,
ShowWhere=YES,
idlist=,
varlist=,
width_inches=, /* If width is too narroe for table, results are unpredictable */
height_inches=); /* If height is too short for table, the table is truncated. */

/* NOTE: The amcro assures that table text is black,
         and table background is white. */

%if %length(&NonDefaultCellHeight) NE 0
  OR 
    &tablegridoff EQ YES 
%then %let GridOff = YES;
%else %let GridOff = NO; 
%if %length(&CustomStyleName) NE 0 
%then %let CustomStyle = &CustomStyleName;
%else %let CustomStyle = ToBeDeleted;
proc template;  
  define style &CustomStyle;  
  parent=styles.&parent;   
  class GraphFonts /
     'GraphValueFont' = ("&Family",&Size,&Weight)
     'GraphLabelFont' = ("&Family",&Size,&Weight)
     'GraphDataFont'  = ("&Family",&Size,&Weight) 
     'GraphTitleFont' = ("&Family",&Size,&Weight) 
     'GraphFootnoteFont' = ("&Family",&Size,&Weight);
  class Fonts / 
    'TitleFont'   = ("&Family",&Size,&Weight)
    'headingFont' = ("&Family",&Size,&Weight) 
    'docFont'     = ("&Family",&Size,&Weight);
  class Header / 
    backgroundcolor = white 
    color = black;
  class RowHeader / 
    backgroundcolor = white 
    color = black;
  class data / 
    backgroundcolor = white 
    color = black;
%if &GridOff EQ YES %then %do;
  class Table /
    rules=none frame=void;
%end;
%if %length(&NonDefaultCellHeight) NE 0 %then %do;
  class Data / 
    cellheight = &NonDefaultCellHeight;
  class RowHeader / 
    cellheight = &NonDefaultCellHeight;
%end;
end;
run;

options nonumber; /* page numbers off */
/* NUMBER is SAS default. turn back on after macro use, if needed. */
  
%if %upcase(&center) EQ YES %then %do;
options center;
%end;
%else %do;
options nocenter;
/* CENTER is default. turn back on after macro use, if needed. */
%end;
  
%if %upcase(&date) EQ YES %then %do;
options date;
%end;
%else %do;
options nodate;
/* DATE is default. turn back on after macro use, if needed. */
%end;

options papersize=(&width_inches.in &height_inches.in);
ods results off;
ods _all_ close;
ods printer style=ToBeDeleted
  file="&imagefolder.\&imagefilename..png"
%if %length(&dpi) NE 0 %then %do;
  dpi=&dpi
%end;   
  printer=PNG300;
title1;
%if %length(&whitespaceabovetitleInPts) NE 0 %then %do;
title1 height=&whitespaceabovetitleInPts.pt " ";
  %let WhereTitleNumber = 3;
title2 
%end;
%else %do;
  %let WhereTitleNumber = 2;
title1 
%end;
  justify=&title_justify color=&title_color "&title";
%if %length(&where) NE 0 
  AND
    &ShowWhere EQ YES
%then %do;
title&WhereTitleNumber 
  justify=&title_justify color=&title_color"where &where";
%end; 
proc print data=&data noobs;
%if %length(&where) NE 0 %then %do;
where &where;
%end;
%if %length(&idlist) NE 0 %then %do;
id &idlist;
%end;
%if %length(&varlist) NE 0 %then %do;
var &varlist;
%end;
run;
title1; 
ods printer close;

%if &CustomStyle EQ ToBeDeleted %then %do;
proc template;
  delete ToBeDeleted / store=sasuser.templat;
run;
%end;

%mend CustomTableAsImage;
