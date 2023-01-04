
%macro DisplaySparseData(xVar=,yVar=);

series x=&xVar y=&yVar /
  markers markerattrs=(color=Black symbol=CircleFilled) 
  lineattrs=(color=LightGray pattern=Solid thickness=3);
scatter x=&xVar y=FirstY /
  markerattrs=(color=Black symbol=CircleFilled)
  DataLabel=FirstTopDataLabel datalabelpos=TopLeft;
scatter x=&xVar y=FirstY /
  markerattrs=(color=Black symbol=CircleFilled)
  datalabel=FirstBottomDataLabel datalabelpos=BottomLeft;
scatter x=&xVar y=LastY /
  markerattrs=(color=Black symbol=CircleFilled)
  datalabel=LastTopDataLabel datalabelpos=TopRight;
scatter x=&xVar y=LastY /
  markerattrs=(color=Black symbol=CircleFilled)
  datalabel=LastChangeY_Label datalabelpos=BottomRight;
scatter x=&xVar y=IntermediateMinY /
  markerattrs=(color=Black symbol=CircleFilled)
  datalabel datalabelpos=bottom;
scatter x=&xVar y=IntermediateMinY /
  markerattrs=(color=Black symbol=CircleFilled)
  DataLabel=&xVar datalabelpos=top;
scatter x=&xVar y=IntermediateMaxY /
  markerattrs=(color=Black symbol=CircleFilled)
  datalabel datalabelpos=top;
scatter x=&xVar y=IntermediateMaxY /
  markerattrs=(color=Black symbol=CircleFilled)
  DataLabel=&xVar datalabelpos=bottom;
scatter x=&xVar y=MinY /
  markerattrs=(color=CX00FFFF symbol=CircleFilled);
scatter x=&xVar y=MaxY /
  markerattrs=(color=CXFF00FF symbol=CircleFilled);

%mend  DisplaySparseData;
