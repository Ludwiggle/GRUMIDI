Get[Directory[]<>"/data/"<>#]&/@{"trained.mx","dt-rsub-notesN.mx"}


"|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| Functions: 					                                       |
|									                                   |	          
|  * clearoutF: split the generated string, select the parts that      |
|               do not contain BAR and that have the correct length    |
|                                                                      |
|  * decompF: decompose the patterns into unit vectors that represent  |
|             single notes/events      								   |
|                                                                      |
|  * decodeF: substitute the unit vectors with correponding notes      |
|             and encode them as Sound object                          |
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
	

clearoutF=
	(Transpose@{Function[p,
	                     StringContainsQ[p,#]&/@
	                       Characters@"BAR"//Or@@#&
	                    ]/@#,
	            #}&@StringSplit@#~
	                  Select~Function@Not@First@#
	)[[All,2]]~Select~(StringLength@#==notesN &) &


decompF=Module[{enc=ToExpression@Characters@#,sl=StringLength@#},
               Projection[enc,sl~UnitVector~#]&~
                 Map~Range@sl~Select~(Total@#==1&)
              ]&




decodeF=Module[{out=#,notes,song},
               notes=Map[StringJoin[ToString/@#]&,
                         decompF/@clearoutF@out,
                     {2}]/.rsub;
               song=({notes,
                     {#,#+dt}&/@
                        Accumulate@Array[dt&,Length@notes]}//Transpose
                    )~Select~(Length@First@#>0&);
               SoundNote[#1,#2]&@@@song//Sound
              ]&



"|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| Generate and decode ||||||||||||||||||||||||||||||||||||||||||||||||||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"

generate[net_,start_,len_]:=
	Nest[StringJoin[#,net[#]]&,
	     start,len]
	
	
generateSample[net_,start_,len_]:=
	Nest[StringJoin[#, (Run["echo -n '"<>#<>"'"];
               #)&@ net[#,"RandomSample"]]&, 
	     start,len ]
	     
	
nchar=300

"  Trained net generating "<>ToString@nchar<>
   " characters \n "//Print
   
out=decodeF@generateSample[trainedNet,"000 010 ",nchar];

Print@"\n"


"|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| Export MIDI ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"

Directory[]<>"/data"//SetDirectory

Export[(DateString@"ISODateTime"<>".mid")~
            StringReplace~{"T"->":"}, out]//
   Echo["MIDI saved as\n  "<>Directory[]<>"/"<>#]&
