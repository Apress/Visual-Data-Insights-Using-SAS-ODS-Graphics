
%macro LatticeDotPlotWithDataLabels(
imagename=,
imageheight=,
data=,
title=,
datalabelformat=,
datalabelpos=,
rowaxisoffsetmin=,
rowaxisoffsetmax=,
colaxisoffsetmin=,
colaxisoffsetmax=);

ods graphics on / reset=all scale=off imagename="&imagename"
  width=5.7in height=&imageheight;
title1 justify=center "&title";
proc sgpanel data=&data;
panelby Type Drivetrain / layout=lattice
  rowheaderpos=left /* text is easier to read at the left */ 
  onepanel novarname noheaderborder spacing=3;
dot Origin / response=MSRP stat=mean 
  datalabel datalabelpos=&datalabelpos
  markerattrs=(color=Green symbol=CircleFilled size=7pt);
rowaxis display=none fitpolicy=none
  refticks=(values) /* move the values to the right side,
    to prevent their visually clashing with the row labels */
  offsetmin=&rowaxisoffsetmin offsetmax=&rowaxisoffsetmax;
colaxis display=none
  offsetmin=&colaxisoffsetmin offsetmax=&colaxisoffsetmax;
format MSRP &datalabelformat; 
run;

%mend  LatticeDotPlotWithDataLabels;
