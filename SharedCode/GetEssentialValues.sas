
%macro GetEssentialValues(
EVdataIN=,
EVvar=,
EVformat=,
EVflagHeight=);

proc univariate data=&EVdataIN(keep=&EVvar) noprint;
where &EVvar NE .;
var &EVvar;
output out=work.statistics
  min=min&EVvar q1=q1&EVvar median=median&EVvar 
  mean=mean&EVvar q3=q3&EVvar max=max&EVvar 
  std=std&EVvar nobs=nobs&EVvar 
  p1=p1&EVvar p10=p10&EVvar p90=p90&EVvar p99=p99&EVvar;
run;

%global min Q1 median mean Q3 max p1 p10 p90 p99 std nobs;

data _null_;
set work.statistics;
call symput('min',compress(put(min&EVvar,&EVformat)));
call symput('Q1',compress(put(q1&EVvar,&EVformat)));
call symput('median',compress(put(median&EVvar,&EVformat)));
call symput('mean',compress(put(mean&EVvar,&EVformat)));
call symput('Q3',compress(put(q3&EVvar,&EVformat)));
call symput('max',compress(put(max&EVvar,&EVformat)));
call symput('P1',compress(put(p1&EVvar,&EVformat)));
call symput('P10',compress(put(p10&EVvar,&EVformat)));
call symput('P90',compress(put(p90&EVvar,&EVformat)));
call symput('P99',compress(put(p99&EVvar,&EVformat)));
call symput('std',compress(put(std&EVvar,&EVformat)));
call symput('Nobs',compress(put(Nobs&EVvar,10.)));
run;

data 
  work.Percentiles(keep=&EVvar FlagPercentiles)  
  work.OtherStatistics(keep=&EVvar FlagOtherStatistics);
retain FlagPercentiles FlagOtherStatistics &EVflagHeight;
&EVvar=&min; output work.OtherStatistics;
&EVvar=&Q1; output work.Percentiles;
&EVvar=&median; output work.OtherStatistics;
&EVvar=&mean; output work.OtherStatistics;
&EVvar=&Q3; output work.Percentiles;
&EVvar=&max; output work.OtherStatistics;
&EVvar=&P1; output work.Percentiles;
&EVvar=&P10; output work.Percentiles;
&EVvar=&P90; output work.Percentiles;
&EVvar=&P99; output work.Percentiles;
run;

%put _global_;

%mend GetEssentialValues;
