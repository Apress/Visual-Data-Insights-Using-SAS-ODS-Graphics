
/* The following macro source code can be stored as, e.g.,
   C:\SharedCode\Modified_genAreaBarDataBasic.sas */

/*******************************************************************
The original macro genAreaBarDataBasic by Dan Heath is found at 
 https://blogs.sas.com/content/graphicallyspeaking/2022/04/30/area-
bar-charts-using-sgplot
Any lines of code added or changed here for this derivative macro
are marked with: LeRB mod
*******************************************************************/

/***************************************************/
/*  Basic area bar chart                           */
/*  notes:                                         */
/*  - The values for the response and width        */
/*    input variables are summed.                  */
/*  - The response output column contains the      */
/*    response values for labeling.                */
/*  - The width output column contains the width   */
/*    values for labeling.                         */
/*                                                 */
/*  args:                                          */
/*  input - input data set name                    */
/*  output - output data set name                  */
/*  category - category variable for each bar      */
/*  response - variable for the length of each bar */
/*  width - variable for the width of each bar     */
/*  datalabel - variable for bar datalabel         */ /* LeRB mod */
/***************************************************/

/*  %macro genAreaBarDataBasic(input, output, category, response, 
width); Original Code COMMENTED OUT HERE AS LeRB mod */

%macro Modified_genAreaBarDataBasic(
  input, output, category, response, width 
  , datalabel  /* LeRB mod */
  );

proc summary data=&input nway;
%if %length(&datalabel) NE 0 %then %do; /* LeRB mod */
id &datalabel; /* LeRB mod */
%end; /* LeRB mod */
class &category;
var &response &width;
output out=_out_totals_ sum=;
run;

data &output;
retain x 0;
label x="&width" y="&response" ID="&category";
set _out_totals_;
ID=&category;
response=&response;
width=&width;
y=0;
x=x;
output;
y=&response;
output;
x = x + &width;
output;
y=0;
output;
run;

%mend Modified_genAreaBarDataBasic; 
