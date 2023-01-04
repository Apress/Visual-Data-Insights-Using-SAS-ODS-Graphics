%macro AllTextSetup_BlackWhiteTable(Size,Family=Arial,Weight=Bold,Parent=PRINTER);
%let FamilyForStyle = %sysfunc(compress(&Family,' '));
proc template;  
  define style AllTextFont&FamilyForStyle.&Size.pt&Weight._BlackWhiteTable;   
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
/* All above is from the AllTextSetup macro */
/* All below are for non-graph output */
  class Header / 
    backgroundcolor = white 
    color = black;
  class RowHeader / 
    backgroundcolor = white 
    color = black;
  class data / 
    backgroundcolor = white 
    color = black; /* These data colors might be unnecessary.
    Perhaps these are already in effect 
    for EVERY possible SAS-provided Parent style.
    But they do no harm, and this shows where to make a change
    if different colors are desired. */   
end;
run;
%mend AllTextSetup_BlackWhiteTable;
