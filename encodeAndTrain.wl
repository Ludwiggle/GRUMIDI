"| Import MIDI file |||||||||||||||||||||||||||||||||||||||||||||||||||"
midinput=First@
         Import@If[
                   InputString[" Learn from "<>#<>"? (y/n)\n"]=="y", #,
                   InputString@"Insert midi filename: "
                  ]&@First[FileNames["*.mid"]~SortBy~FileDate]
  
"| Eliminate initial silence and extract the notes ||||||||||||||||||||"
midi=Function[midi,
              MapAt[#-midi[[1,2,1]]&, midi, {All,2}]
             ]@midinput

notes=First/@midi
notesN=Length@DeleteDuplicates@notes

	                         
"|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| Time Quantization ||||||||||||||||||||||||||||||||||||||||||||||||||||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"

time=Rationalize@midi[[All,2]]

dt=Differences/@time//Flatten//Min

tgrid=Table[t,{t,time[[1,1]],time[[-1,-1]]+dt,dt}]

qt=Nearest[tgrid,
           time[[All,1]],
           1,DistanceFunction->EuclideanDistance
          ]//Flatten

qt1={#,#+dt}&/@qt

tsil=Partition[tgrid,2,1]~Complement~DeleteDuplicates@qt1



"|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| MIDI binary encoding |||||||||||||||||||||||||||||||||||||||||||||||||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"

words=#<>" "&/@
       StringJoin/@
        Map[ToString,
            (notesN~UnitVector~#&/@Range@notesN)~
			   Append~StringPadLeft["",notesN,"0"],
	    {2}]
	                         


fullmidi=( Transpose@{notes,qt1}~Join~({"silence",#}&/@tsil))~
             SortBy~(#[[2,1]]&)

sub=fullmidi[[All,1]]//Thread[Union@#->words]&

rsub=Thread@Rule[Values@sub~StringDrop~(-1),Keys@sub]

sumInstr=Function[line,
                  ToExpression/@
                   Characters[#][[;;-2]]&/@Last/@line//
					ToString/@Plus@@#&//#<>" "&
			     ]

encoded=sumInstr/@
         GatherBy[Transpose@{fullmidi,
                             fullmidi[[All,1]]/.sub},
                  #[[1,2,1]]&
                 ]



"|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| Trainig set ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"


corpus=Riffle[encoded,"BAR ",17]//StringJoin

corpus~StringTake~200//
	"\n "<>midinput<>" encoded as\n "<>#<>"  ... \n"&//Print


sampleCorpus[corpus_,len_,num_]:=
   Module[
          {
           positions=RandomInteger[{len+1,StringLength[corpus]-1},num]
          },
	      Thread[
	             StringTake[corpus,
	                        {#-len,#}&/@positions
	                       ]->StringPart[corpus,positions+1]
	            ]
	     ]
	     
	      
(*trainingData=sampleCorpus[corpus,16,10000];*)
trainingData=sampleCorpus[corpus,#,1]&/@
               RandomInteger[{4,60},10000]//Flatten




"|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| Net Model (LSTM-RNN) and training ||||||||||||||||||||||||||||||||||||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"

characters=Union@Characters@corpus

net=NetChain[{
			 UnitVectorLayer[],
             GatedRecurrentLayer[32],
             GatedRecurrentLayer[32],
             DropoutLayer[.1],
             SequenceLastLayer[],
             LinearLayer[],
             SoftmaxLayer[]
             },
             "Input"->NetEncoder[{"Characters",characters}],
             "Output"->NetDecoder[{"Class",characters}]
           ]



trainedNet=NetTrain[net,
                   trainingData,
                   ValidationSet->Scaled[0.1],
                   BatchSize->64,
                   MaxTrainingRounds->10,
                   TargetDevice->"CPU"]



"|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| Save trained net and data for generateAndDecode.wl script ||||||||||||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"

CreateDirectory@"data"//Quiet
Directory[]<>"/data"//SetDirectory

"trained.mx"~DumpSave~trainedNet
"dt-rsub-notesN.mx"~DumpSave~{dt,rsub,notesN}
