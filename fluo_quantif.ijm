//Macro by Félix de Carpentier, 2022, CNRS - Sorbonne University - Paris-Saclay University (France) and UC Berkeley - HHMI (USA)
//This macro allows the detection of cells and quatification of fluroescence levels of several channels of multiple stack.

// Before use, a configuration of the Bio-Formats is needed:
// 1. Plugins > Bio-Formats > Bio-Formats Plugins Configuration
// 2. Select your desired file format (e.g. “Nikon ND2”) and select “Windowless”

setBatchMode(true);

//Choose directories
input_path=getDirectory("Choose input folder");
output_path=getDirectory("Choose output folder for the results");

//Get lists of files in the input directory
list=getFileList(input_path);

//Process images
for(i=0; i<list.length; i++) {
	//Open image
	open(input_path+list[i]);

	//Clean image name
	fileExtension=lastIndexOf(list[i],"."); 
	if(fileExtension!=-1) name=substring(list[i],0,fileExtension);
	rename(name);
	print(name);
	
	//Detection of particles based on mVenus and Chloro fluorescence
	run("Duplicate...", "duplicate channels=2-3"); //Duplicate suffix = "-1"
	run("Make Composite");
	selectWindow(name+"-1");
	run("Flatten");
	run("8-bit");
	run("Gaussian Blur...", "sigma=5");
	setAutoThreshold("Yen dark");
	run("Convert to Mask");
	run("Fill Holes");
	run("Watershed");
	run("Options...", "iterations=3 count=2 do=Erode");
	run("Set Measurements...", "  redirect=None decimal=4");
	run("Analyze Particles...", "size=10-Infinity add"); //exclude 
	
	//Create a ROI containing the background and add it to the ROI manager
	//waitForUser("Pause"); 
	//selectWindow(name+"-2");
	run("Invert");
	run("Analyze Particles...", "size=10-Infinity add composite");

	//Transfer of the particles shape to the original stack
	selectWindow(name);
	run("Duplicate...", "duplicate channels=2-3"); //Duplicate suffix = "-1"
	run("Gaussian Blur...", "sigma=2");
	roiManager("Show All");
	roiManager("Set Color", "red"); 

	//Measurement of grey values of mVenus and Chloro channels
	run("Set Measurements...", "mean min redirect=None decimal=4");
	roiManager("multi-measure measure_all one append");
	
	//Save composite with particles shapes
	run("Make Composite");
	run("Flatten"); 
	roiManager("Show All without labels");
	roiManager("Set Color", "red"); 
	saveAs("Jpeg", output_path+name+"_composite.jpg");
	
	//Transfer particles shapes to the phase contrast image and save
	selectWindow(name);
	run("Slice Keeper", "first=1 last=1 increment=1");
	roiManager("Show All without labels");
	roiManager("Set Color", "red"); 
	run("Flatten"); 
	saveAs("Jpeg", output_path+name+"_phase.jpg");
	
	//Clean and close
	roiManager("Delete");
	close("*");	

	//Shows the progress bar
	showProgress(i, list.length);  //Shows a progress bar  
}

//Save log containing images names
selectWindow("Log");
saveAs("Text", output_path+ "log"+ ".txt");
run("Close");

//Save results
saveAs("results", output_path+ "results"+ ".csv"); 
selectWindow("Results");
run("Close"); 

if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
	}

setBatchMode(false);