
/* IBM1998CloseAndMaxCloseMacroVariable.sas */

/* The macro variables
   (MaxClose, MaxCloseDisplay, and MaxCloseRoundedUp) 
   disappear at end of SAS session.
   So, any examples that reference them must either be run
   during the same session as this code has been run, 
   or this DATA step must be rerun. */
data work.IBM1998Close;
retain MaxClose 0;
set sashelp.Stocks end=LastOne;
where year(Date) EQ 1998 and Stock EQ 'IBM';
output;
MaxClose = max(MaxClose,Close);
if LastOne;
call symput('MaxClose',MaxClose);
call symput('MaxCloseDisplay',trim(left(put(MaxClose,6.2))));
call symput('MaxCloseRoundedUp',ceil(MaxClose)); 
          /* round up to next integer */
run;
