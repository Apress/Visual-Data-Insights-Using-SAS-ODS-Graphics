
/* AddCustomDataLabelsToIBM1998Close.sas */
/* REQUIRES work.IBM1998Close to already exist.
   It can be created with
   ExtractIBM1998CloseAndMaxCloseMacroVariable.sas */

data work.IBM1998Close_CustomDataLabels;
keep Date Close DataLabelForYandX;
length DataLabelForYandX $ 7;
set work.IBM1998Close;
DataLabelForYandX = put(Close,3.) || ',' || put(Date,monname3.);
run;
