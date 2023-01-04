/* About This OneXYperCellForHeatMap Macro */

/* This macro is analogous to the BinsForHeatMap macro. 
It prepares output for the HeatMapAnnoAndColorLegend macro, 
as well as axis values in the global symbol table from which 
they are retrieved by that macro.

The difference is that with the BinsForHeatMap macro, 
output observations carry X and Y values that are X bin and Y 
bin averages of X and Y. With this OneXYperCellForHeatMap macro, 
all output observations still retain their original X and Y 
values. When there are few enough distinct X and Y values in the 
input, a heat map can provide a cell for each X-Y pair. That is 
the case for which this OneXYperCellForHeatMap macro is used. 

When there are too many distinct X and Y values, multiple X 
values and multiple Y values are divided into bins by the 
BinsForHeatMap macro. Its output does carry only one X-Y pair 
for each heat map cell, but X and Y are not the original input X 
and Y, but bin averages instead.
 
The last thing in this macro is the code for the Get macro, 
which is needed by any subsequent processing that would work 
with this macro's outputs. */

%macro OneXYperCellForHeatMap(
data=
,out=
,ResponseVar=
,Xvar=
,Xformat=
,Yvar=
,Yformat=
);

/* As currently written,
   this macro delivers only integer X and Y values,
   and only X, Y, and the Response Variable */

data &out;
set &data
  (keep=&Xvar &Yvar &ResponseVar);
where &Xvar NE . AND &Yvar NE . AND &ResponseVar NE .;
&Xvar = round(&Xvar,1);
&Yvar = round(&Yvar,1);
run;

%global ObsCount; /* need to access it outside of this macro */
data _null_;
call symput('ObsCount',trim(left(InputCount)));
stop;
set &out nobs=InputCount;
run;

%macro Globals(Prefix=,N=);

%do i = 1 %to &N %by 1;
  %global &Prefix&i;
%end;

%mend  Globals;

proc sort data=&out out=work.distinct&Xvar nodupkey;
by &Xvar;
run; 

%global Xcount; 
/* also need to access it outside of this macro */

data _null_;
call symput('Xcount',trim(left(Xcount)));
stop;
set work.distinct&Xvar nobs=Xcount;
run; 

%Globals(Prefix=Xvalue,N=&Xcount); 
/* need to access these outside of this macro */

data _null_;
set work.distinct&Xvar;
call symput('Xvalue'||trim(left(_N_)),
            trim(left(put(&Xvar,&Xformat))));
run;

proc sort data=&out out=work.distinct&Yvar nodupkey;
by &Yvar;
run;

%global Ycount; 
/* also need to access it outside of this macro */

data _null_;
call symput('Ycount',trim(left(Ycount)));
stop;
set work.distinct&Yvar nobs=Ycount;
run; 

%Globals(Prefix=Yvalue,N=&Ycount); 
/* need to access these outside of this macro */

data _null_;
set work.distinct&Yvar;
call symput('Yvalue'||trim(left(_N_)),
            trim(left(put(&Yvar,&Yformat))));
run;

/* The Get macro is included here so that it will be available 
when needed outside of this macro. It must be used in XAXIS and 
YAXIS statements to retrieve axis values created above as macro 
variables. It is also in the HeatMapAnnoAndColorLegend macro. */

%macro Get(Value=,Count=); 

%do i = 1 %to &Count %by 1;
  &&&Value&i
%end;
%mend  Get;

%mend OneXYperCellForHeatMap;
