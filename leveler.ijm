//Macro by Félix de Carpentier, 2022, CNRS - Sorbonne University - Paris-Saclay University (France) and UC Berkeley - HHMI (USA)
//This macro allows to adjust images stacks to the same levels.

// Before use, a configuration of the Bio-Formats is needed:
// 1. Plugins > Bio-Formats > Bio-Formats Plugins Configuration
// 2. Select your desired file format (e.g. “Nikon ND2”) and select “Windowless”

//Choose directories and create a list of files
inputFolder=getDirectory("Choose input folder");
outputFolder=getDirectory("Choose output folder for the results");
list=getFileList(inputFolder);


//General options
setBatchMode(false);
setOption("ExpandableArrays", true);
levelsArray = newArray(610, 1220, 490, 750, 300, 5500); //Set the desired levels values here. 
namesArray = newArray("Phase","YFP", "Chloro"); //Set the names of the channel here. 
sliceDelArray = newArray("1"); //Contains the slices to remove from the composite, if none put nothing.

//Processing loop of the images
for(i=0; i<list.length; i++)
{
	//Open the images
	imgPath=inputFolder+list[i];
	open(imgPath);
	//Change LUT of a slice
	setLUT(list[i], 2, "Yellow");
	
	//Set the min and max levels of the channels according to the values
	setLevels(list[i], levelsArray); 
	
	//Setup output path	
	outputPath=outputFolder+list[i];
	fileExtension=lastIndexOf(outputPath,"."); 
	if(fileExtension!=-1) outputPath=substring(outputPath,0,fileExtension);
	//waitForUser("Win Name "+list[i]);
	
	//Exports individual channels and composite images. 
	selectImage(list[i]);
	run("Duplicate...", "duplicate");
	saveAs("Tiff", outputPath+".tif"); //Saves leveled stack as Tiff. 
	saveAsSingle(list[i], namesArray); //Saves single channels.
	makeFlatComposite(list[i], sliceDelArray); //Makes compostite witouth the channels chosen in sliceDelArray
	saveAs("Jpeg", outputPath+"_Compo.jpg"); //Saves composite image. 
	close("*"); //Close all images	
	showProgress(i, list.length); //Shows a progress bar
}

setBatchMode(false);
//Save parameters of the levels
for(k=1; k<=levelsArray.length/2; k++) print(
	"chan"+k+"_min : "+levelsArray[(2*k)-2]+"\n"+
	"chan"+k+"_max : "+levelsArray[(2*k)-1]
	);
selectWindow("Log");
saveAs("Text", outputFolder+ "log"+ ".txt");
closeWin("Log");

//Functions
function setLUT(winName, slice, lut) 
{
	selectWindow(winName);
	setSlice(slice);
	run(lut);
}

function setLevels(winName, levels)
{
	selectWindow(winName);
	min = newArray();
	max = newArray();
	for(j=0; j<levels.length; j=j+2){
		min = Array.concat(min, levels[j]);
	}
	for(j=1; j<levels.length; j=j+2){
		max = Array.concat(max, levels[j]);
	}
	run("Brightness/Contrast...");
	for(k=1; k<levels.length/2+1; k++) {
		setSlice(k);
		setMinAndMax(min[k-1], max[k-1]);

	}
	run("Close");
}

function makeFlatComposite(winName, delSlice)
{
	selectWindow(winName);
	if(delSlice.length > 0) {
		delSlice = Array.reverse(Array.sort(delSlice));
		for(i=0; i<delSlice.length; i++) {
			setSlice(delSlice[i]);
			run("Delete Slice", "delete=channel");
		}		
	}
	if(is("Composite") == true){
		run("Make Composite");
		run("Flatten");
	}
}

function saveAsSingle(winName, chanNames)
{
	for(j=1; j<chanNames.length+1; j++) {
		selectWindow(winName);
		run("Duplicate...", "duplicate channels="+j);
		saveAs("Jpeg", outputPath+"_"+j+"_"+chanNames[j-1]+".jpg");
	}
}

function closeWin(winName)
{
	if (isOpen(winName)) 
	{
		selectWindow(winName);
		run("Close");
	}
}