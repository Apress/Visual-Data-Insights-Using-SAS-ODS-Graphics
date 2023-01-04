%macro AllGraphTextSetup(Size,Family=Arial,Weight=Bold);

/* If stored, this macro fileName must be AllGraphTextSetup.sas */ 
/* The other option for Weight is Normal. */
/* The number N specified for Size is used as Point Size, Npt.
   This number is the macro's positional parameter. A macro may have
   at most one positional parameter, and it must be first in the
   invocation of the macro, when other parameters are used. */

/* Family may be used for font names with imbedded blanks,
   such as Times New Roman, but the style created omits blanks,
   as in style name GraphFontTimesNewRoman10ptBold.
   Blanks are removed with the %LET statement below. */
%let FamilyForStyle = %sysfunc(compress(&Family,' '));

proc template;  
  define style GraphFont&FamilyForStyle.&Size.pt&Weight;   
  parent=styles.listing;    
  class GraphFonts /
     'GraphValueFont' = ("&Family",&Size.pt,&Weight)
     'GraphLabelFont' = ("&Family",&Size.pt,&Weight)
     'GraphDataFont'  = ("&Family",&Size.pt,&Weight) 
     'GraphTitleFont' = ("&Family",&Size.pt,&Weight) 
     'GraphFootnoteFont' = ("&Family",&Size.pt,&Weight);  
end;
run;

%mend AllGraphTextSetup;
