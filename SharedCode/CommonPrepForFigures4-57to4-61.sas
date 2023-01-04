
/* The following prep code can be stored as, e.g.,
   C:\SharedCode\CommonPrepForFigures4-57to4-61.sas */

/* The prep code below must be run for each example. Even if the 
output data set were stored in the SASUSER data library to assure 
persistence after the SAS session ends, there are four macro 
variables needed in every example that disappear at the end of the 
SAS session. Unless the post-prep parts of each example’s code were 
all concatenated in the same code submission for a single SAS 
session, the macro variables need to be created for each SAS 
session, if each example is run in a separate session. So, a 
practical solution is to store the prep code in a folder and 
%INCLUDE it for each example. */

data totals;
input Site $ Quarter Sales Salespersons;
format Sales dollar12.2;
datalines;
Lima 1  4043.97  4
NY   1  8225.26 12
Rome 1  3543.97  6
Lima 2  3723.44  5
NY   2  8595.07 18
Rome 2  5558.29 10
Lima 3  4437.96  8
NY   3  9847.91 24
Rome 3  6789.85 14
Lima 4  6065.57 10
NY   4 11388.51 26
Rome 4  8509.08 16
;
run;

proc summary data=totals;
class Site;
var Sales Salespersons;
output out=SiteTotals(drop=_freq_) sum=SiteTotalSales SiteSalespersons;
run;

data work.SiteTotalsAndAreasAndYperX;
drop MaxSiteTotalSales;
retain MaxSiteTotalSales 0;
length NumbersForSite $ 8 SiteWithNumbers $ 13;
set SiteTotals end=LastOne;
if _type_ EQ 0
then do;
  call symput('GrandTotalSales',
    trim(left(put(SiteTotalSales,dollar7.))));
  call symput('GrandTotalSalespersons',
    trim(left(put(SiteSalespersons,3.))));
  delete;
end; /* macro variables disappear at end of SAS session */
NumbersForSite =
  trim(left(SiteSalesPersons)) || '-' || 
  trim(left(put((SiteTotalSales / 1000),dollar5.1)));
SiteWithNumbers = 
  trim(left(Site)) || '-' || trim(left(NumbersForSite));
Area = SiteTotalSales * SiteSalespersons;
YperX = SiteTotalSales / SiteSalespersons;
MaxSiteTotalSales = max(MaxSiteTotalSales,SiteTotalSales);
if LastOne then do;
  call symput('MaxSiteTotalSales',MaxSiteTotalSales);
  call symput('MaxSiteTotalSalesDisplay',
    trim(left(put((MaxSiteTotalSales / 1000),dollar5.1))));
end; /* macro variables disappear at end of SAS session */
run;

/* End of Prep Code for Area Bar Chart Examples */
