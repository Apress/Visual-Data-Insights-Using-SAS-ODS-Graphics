/* This code is used at start of Listings 4-51 to 4-55A,
   after a %LET WHERE = statement appropriate to the case. */

/* The following common prep code is also in Appendix A4-51. */

proc summary data=sashelp.shoes;
&WHERE
class Region;
var Sales;
output out=work.Subset sum=Sales;
run;

data work.FromPrep;
length RegionPercent $ 6 DataLabel $ 48;
retain Invisible 'X' GrandTotal 0;
set work.Subset end=LastOne; 
if _type_ EQ 0
then do;
  Region = 'Total';
  RegionPercent = '100%';
  GrandTotal = Sales;
  call symput('GrandTotal',GrandTotal);
  call symput('GrandTotalDisplay',trim(left(put(GrandTotal,dollar11.))));
  /* two macro variables for use 
     in some examples other than Fig4-51 */
end;
else RegionPercent = 
  trim(left(put(((Sales / GrandTotal) * 100),5.1))) || '%';
DataLabel = 
  trim(left(substr(Region,1,15)))  || ' - ' ||
  trim(left(put(Sales,dollar11.))) || ' - ' ||
  trim(left(RegionPercent));
if LastOne then call symput('Count',_N_);
/* &Count macro variable is not used in Fig4-51 to Fig4-54 */
run;
