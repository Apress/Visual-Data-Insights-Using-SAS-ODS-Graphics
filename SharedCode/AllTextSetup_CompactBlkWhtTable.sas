%macro AllTextSetup_CompactBlkWhtTable(
  Size,CellHeight=,Family=Arial,Weight=Bold,Parent=PRINTER);
%let FamilyForStyle = %sysfunc(compress(&Family,' '));
proc template;  
  define style AllTextFont&FamilyForStyle.&Size.pt&Weight._CompactBlkWhtTable;   
  parent=styles.&Parent;    
  class GraphFonts /
     'GraphValueFont' = ("&Family",&Size.pt,&Weight)
     'GraphLabelFont' = ("&Family",&Size.pt,&Weight)
     'GraphDataFont'  = ("&Family",&Size.pt,&Weight) 
     'GraphTitleFont' = ("&Family",&Size.pt,&Weight) 
     'GraphFootnoteFont' = ("&Family",&Size.pt,&Weight);
  class Fonts / 
    'TitleFont'   = ("&Family",&Size.pt,&Weight)
    'headingFont' = ("&Family",&Size.pt,&Weight) 
    'docFont'     = ("&Family",&Size.pt,&Weight);
  class Header / 
    backgroundcolor = white 
    color = black;
  class RowHeader / 
    backgroundcolor = white 
    color = black;
  class data / 
    backgroundcolor = white 
    color = black;
  class Table /
    rules=none frame=void; /* turn off the table grid */
/* All above is from the AllTextSetup_BlackWhiteTblNoGrid macro */
  class Data / 
    cellheight = &CellHeight;
  class RowHeader / 
    cellheight = &CellHeight;
end;
run;
%mend AllTextSetup_CompactBlkWhtTable;
