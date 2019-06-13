/*
VIVECA STITCHING
Started in January 2019
Macro build and maintained by Vasco Fachada (vasco.fachada@gmail.com)

At the moment this macro is using the stitching plugin "Grid/Collection stitching" used in Preibisch et al. Bioinformatics (2009).
This macro basically goes throught the folder of the user's choice and opens .czi files.
The metadata from the .czi is read and the individual tiles of the file are saved as orderly tiff files in a temp folder. 
The read metada is used to feed the mentioned plugin the parameters for stitching. These include number of tiles in each axis.
The laser excitation data is also read and the image should display: 405->Blue; 488->Green; 555->Orange; 639->Red.
The tile overlap data is also read from the metdata and fed into the stitching plugin
Z-stack stiching is supported
Both modes of tile scanning in ZEN black are supported, uni and bidirectional
*/

/*Dialog.create("Ok, grab your needle. This is just like knitting");
Dialog.addMessage("Welcome to our stitching tool. \n");
Dialog.addMessage("\nThis macro is mainly aimed at stitching tiled-images produced by our Zeiss LSM700. \nAt the moment, stitching is only working with .czi files which cannot contain spaces in their file name. \nThis tool is prepared for stiching simple tiled images. You may encouter problems if you used 'positions' or 'timeseries'.");
Dialog.addCheckbox("  Open your images once they are stitched? (They will be saved anyways.)", false); 
Dialog.addCheckbox("  Process images for enhanced display? (not recommended for analysis)", false);
Dialog.addMessage("Still under development. Any issues should be reported in order to improve the tool. \ncontact: vasco.fachada(at)gmail.com");
Dialog.show();
visualize_checkBox = Dialog.getCheckbox();
processing_checkBox = Dialog.getCheckbox();*/

//Finding the .czi files to stitch
dir = getDirectory("Select a directory containing your CZI files you want to stitch");
files = getFileList(dir);
start = getTime();

setBatchMode(true);

//Deleting any previously produced folders in the case the macro broke half-way  
for(f=0; f<files.length; f++) {
	if(matches(files[f], ".*stitch_temp.*")){
		old_temp_folder = dir+File.separator+files[f];
		old_content = getFileList(old_temp_folder);
		for (li=0; li<old_content.length; li++){
			old_images = getFileList(old_temp_folder+File.separator+old_content[li]);
			for (lii=0; lii<old_images.length; lii++){
				File.delete(old_temp_folder+File.separator+old_content[li]+File.separator+old_images[lii]);
			} 
			File.delete(old_temp_folder+File.separator+old_content[li]);
		}
  		File.delete(old_temp_folder);	
		print("successfully deleted previously produced temp files");
	}
}

k=0;
n=0;

run("Bio-Formats Macro Extensions");
for(f=0; f<files.length; f++) {

	if(endsWith(files[f], ".czi")) { 

		nmrOfFilesStitched = 0;
		nmrOfTilesOpened = 0;
		pixelTotal = 0;
		sizeLoaded = 0;
		
		k++;
		id = dir+files[f];
		Ext.setId(id);
		Ext.getSeriesCount(seriesCount);
		n+=seriesCount;

		//Creating folder where stiched image(s) and raw data file will be be saved
		savingDir = dir+File.separator+"READY_"+substring(files[f], 0, lengthOf(files[f])-4);

		//READING METADATA
		run("Bio-Formats Importer", "open=["+id+"] color_mode=Default view=Hyperstack stack_order=XYCZT use_virtual_stack series_"+(1));
		fullMeta=getMetadata("Info");
	
		//Determining if 2D or 3D
		zSteps = parseInt(substring(fullMeta, indexOf(fullMeta, "SizeZ =")+8, indexOf(fullMeta, "SizeZ =")+10));  
				
		//Determining if timeseries
		tPoints = parseInt(substring(fullMeta, indexOf(fullMeta, "SizeT =")+8, indexOf(fullMeta, "SizeT =")+9));

		//Determining number of positions. Ine the case of the 12-well plate container functions in LSM700 Zen black, each position corresponds to each well.
		if (indexOf(fullMeta, "Information|Image|SizeS #1 =") > -1){//if string exists 
			positionsNum = substring(fullMeta, lastIndexOf(fullMeta, "Information|Image|SizeS #1 =")+lengthOf("Information|Image|SizeS #1 =")+0, lastIndexOf(fullMeta, "Information|Image|SizeS #1 =")+lengthOf("Information|Image|SizeS #1 =")+3);
			positionsNum = parseInt(positionsNum);				
		}else positionsNum = 1;

		print("number of positions should be 12. Now they are: "+positionsNum);
								
		//Getting the number of tiles in each axis for later stitching steps
		posStartInd = 3+lengthOf(toString(positionsNum));
		posLastInd = 4+lengthOf(toString(positionsNum));	
		gridMetaX = substring(fullMeta, lastIndexOf(fullMeta, "PositionGroup|TilesX #")+lengthOf("PositionGroup|TilesX #")+posStartInd, lastIndexOf(fullMeta, "PositionGroup|TilesX #")+lengthOf("PositionGroup|TilesX #")+posLastInd);
		gridMetaY = substring(fullMeta, lastIndexOf(fullMeta, "PositionGroup|TilesY #")+lengthOf("PositionGroup|TilesY #")+posStartInd, lastIndexOf(fullMeta, "PositionGroup|TilesY #")+lengthOf("PositionGroup|TilesY #")+posLastInd);
		gridX = parseInt(gridMetaX);
		gridY = parseInt(gridMetaY);
		TilesPerPos = gridX * gridY;
		TotalNumTiles = TilesPerPos * positionsNum * tPoints;
		if (TotalNumTiles < 10)
			mosaicSize = "{i}";
		else if (TotalNumTiles > 9 && TotalNumTiles < 100)
			mosaicSize = "{ii}";
		else if (TotalNumTiles > 99 && TotalNumTiles < 1000)
			mosaicSize = "{iii}";
		else
			mosaicSize = "{iiii}";

		//Reading tile scanning direction
		if (substring(fullMeta, indexOf(fullMeta, "BiDirectional #1")+19, indexOf(fullMeta, "BiDirectional #1")+23) == "fals") 
			tilingDirection = "[Grid: row-by-row] order=[Right & Down                ]";
		if (substring(fullMeta, indexOf(fullMeta, "BiDirectional #1")+19, indexOf(fullMeta, "BiDirectional #1")+23) == "true") 
			tilingDirection = "[Grid: snake by rows] order=[Right & Down                ]";				
				
		//Reading tile overlap
		tlOverlap = 100*parseFloat(substring(fullMeta, indexOf(fullMeta, "TileAcquisitionOverlap #")+28, indexOf(fullMeta, "TileAcquisitionOverlap #")+39));

		//Looking and determining number of channels in data
		channels_nmr = 	parseInt(substring(fullMeta, indexOf(fullMeta, "SizeC =")+8, indexOf(fullMeta, "SizeC =")+9)); 
		channels = newArray(channels_nmr);
		colors = newArray(channels_nmr);
		markers = newArray(channels_nmr);
		processMacro = newArray(channels_nmr);
				
		for (ii=0; ii<channels_nmr; ii++){
			channels[ii] = substring(fullMeta, indexOf(fullMeta, "ExcitationWavelength #"+ii+1+" =")+26, indexOf(fullMeta, "ExcitationWavelength #"+ii+1+" =")+29);
			if (channels[ii] == "405") colors[ii] = "Blue";
			if (channels[ii] == "488") colors[ii] = "Green";
			if (channels[ii] == "555") colors[ii] = "Yellow";
			if (channels[ii] == "639") colors[ii] = "Red";

			//Creating images to show user
			Stack.setChannel(ii+1);
			run(colors[ii]);
			run("Enhance Contrast", "saturated=0.35");
			scrHeight = screenHeight;
			scrWidth = screenHeight;
			setBatchMode(false);
			setLocation(0, 0, scrWidth, scrHeight);
			getLocationAndSize(nx, ny, nw, nh);

			run("Duplicate...", "title=cur_zoom duplicate channels="+ii+1);
			run("View 100%");
			getLocationAndSize(zx, zy, zw, zh);
			makeRectangle(zx, zy, zw, zh);
			run("Crop");
			run("View 100%");
			run("In [+]");
			setLocation(nw, 0, zw, zh);
			
			Dialog.create("Excited with "+channels[ii]+" laser");
			Dialog.addString("Name this marker:", "include_no_spaces_please", 24);
			Dialog.addMessage("For particle segmentation and analysis, this channel needs to be binarized.");
			items = newArray("Just auto-threshold it.","Use already built pre-processing macro.","Build a new pre-processing macro now.");
			Dialog.addRadioButtonGroup("How to process before measuring?", items, 3, 1, items[1]);
			Dialog.setLocation(nw,zh);
			Dialog.show();
			markers[ii] = Dialog.getString();
			processAns = Dialog.getRadioButton;
			
			if (matches(processAns, items[0])){
				print(processAns);
				processMacro[ii] = File.separator+"\\fileservices.ad.jyu.fi\\homes\\varufach\\Desktop\\research\\BCAA\\2019\\analysis_program\\Fiji_script\\stand_thresh.ijm";
			}else if (matches(processAns, items[1])){
				print(processAns);
				processMacro[ii] = File.openDialog("Which file contains the processing steps to binarize "+markers[ii]+"?");
			}else if (matches(processAns, items[2])){
				print(processAns);
				run("Record...");
				run("Threshold...");
				waitForUser("Use the 'recorder' to built a macro file.\nHope you know what you're doing.\nPress 'OK' when done.");
				processMacro[ii] = File.openDialog("If you want to use the file you just produced, tell us where it is.");
			}
			close("cur_zoom");		
		}

		//Colocalization dialog options
		if (channels_nmr > 1){
			Dialog.create("Colocalization option");
			//Dialog.addString("Name this marker:", "include_no_spaces_please", 24);
			Dialog.addCheckbox("I want to perform colocalization analysis.", false);
			Dialog.addMessage("Select two channels:");
			Dialog.addChoice("Channel-1", markers, markers[0]);
			Dialog.addChoice("Channel-2", markers, markers[1]);	
			Dialog.show();
			colocOpt = Dialog.getCheckbox();
			chColoc1 = Dialog.getChoice();
			chColoc2 = Dialog.getChoice();
		}
		
		getVoxelSize(width, height, depth, unit); //detecting the voxel size of the current raw file, so the final image also has the same scale.
		close();
		setBatchMode(true);

		if (!File.exists(savingDir)){			
			File.makeDirectory(savingDir);

			//Creating temporary tiff files for analysis and organization of stiched file
			for (l=1; l<positionsNum+1; l++){

				//For file naming purposes
				if (l < 10) prefix = "_00";
				if (l > 9)  prefix = "_0";
				if (l > 99) prefix = "_";
							
				savingDir_temp = dir+File.separator+"stitch_temp";
				File.makeDirectory(savingDir_temp);
				positionDir = savingDir_temp+File.separator+"position"+prefix+l;
				File.makeDirectory(positionDir);
				positionDir_bin = savingDir_temp+File.separator+"position"+prefix+l+"_bin";
				File.makeDirectory(positionDir_bin);

				//OPENING TILES from .czi file orderly. For analysis (parallel macro) and stiching
				if (seriesCount > 1){
					for (i=1; i<TilesPerPos+1; i++) {
						run("Bio-Formats Importer", "open=["+id+"] color_mode=Default view=Hyperstack stack_order=XYCZT use_virtual_stack series_"+(i+nmrOfTilesOpened));

						fullName	= getTitle();
						dirName 	= substring(fullName, 0,lastIndexOf(fullName, ".czi"));
						fileName 	= substring(fullName, lastIndexOf(fullName, " - ")+3, lengthOf(fullName));
						fileSeries  = substring(fileName, indexOf(fileName, "#"), lengthOf(fileName)); //collects the number of series starting from the hashtag. #1 or #0001

						saveAs("tiff", positionDir+File.separator+fileName+".tif");

						dataFileName = substring(files[f], 0, lengthOf(files[f])-4)+"_pos"+prefix+toString(l)+".tsv";	
						
						getData ();	//run function to get gray value and binary data from images
						
						saveAs("tiff", positionDir_bin+File.separator+fileName+"_bin.tif");
						close(fileName+"_bin.tif");
						close(fileName+".tif");
					}
					  				
					//STICHING AND VISUALIZATION
						
					//binary data
					run("Grid/Collection stitching", "type="+tilingDirection+" grid_size_x="+gridX+" grid_size_y="+gridY+" tile_overlap="+tlOverlap+" first_file_index_i="+1+nmrOfTilesOpened+" directory="+positionDir_bin+" file_names=["+substring(fileName, 0, lengthOf(fileName)-lengthOf(fileSeries))+"#"+mosaicSize+"_bin.tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 ignore_z_stage computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");			
					post_stitch(); //post stich adjustments
					saveAs("tiff", savingDir+File.separator+"BIN_"+substring(files[f], 0, lengthOf(files[f])-4)+"_pos"+prefix+l+".tif");//saving stiched image
					close();
					//gray valued data
					run("Grid/Collection stitching", "type="+tilingDirection+" grid_size_x="+gridX+" grid_size_y="+gridY+" tile_overlap="+tlOverlap+" first_file_index_i="+1+nmrOfTilesOpened+" directory="+positionDir+" file_names=["+substring(fileName, 0, lengthOf(fileName)-lengthOf(fileSeries))+"#"+mosaicSize+".tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 ignore_z_stage computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
					post_stitch(); //post stich adjustments
					nmrOfTilesOpened = nmrOfTilesOpened + TilesPerPos;

					//measure colocalization
					if (colocOpt == 1){ //not performing these measurements on last row of wells since there is no second channel (C3) stained as these were controls. In the future this piece of codes needs to be changed if the whole plate is to be analyzed for colocalization!
						run("Duplicate...", "title=coloc duplicate");						
						run("Split Channels");
						for (ix=0; ix<channels_nmr; ix++){
							selectWindow("C"+ix+1+"-coloc");
							rename("coloc-"+markers[ix]);
						}
						run("Colocalization Threshold", "channel_1=coloc-"+chColoc1+" channel_2=coloc-"+chColoc2+" use=None channel=[Red : Green] set mander's mander's number % % % %");
						close("coloc*");
						//save colocalization result window for well/position
						selectWindow("Results");
						saveAs("Text", savingDir+File.separator+"coloc_"+substring(files[f], 0, lengthOf(files[f])-4)+"_pos"+prefix+l+".txt");
						close("Results");
					}/*else{
						run("Text Window");
						saveAs("Text", savingDir+File.separator+"coloc_"+substring(files[f], 0, lengthOf(files[f])-4)+"_pos"+prefix+l+".txt");
					}*/
					
				
					saveAs("tiff", savingDir+File.separator+"STITCHED_"+substring(files[f], 0, lengthOf(files[f])-4)+"_pos"+prefix+l+".tif"); //saving stiched image
					saveType = "CHED_";
											
					pixelTotal = pixelTotal+ (getHeight()*getWidth());
					imgInfo=getImageInfo();
					sizeLoaded = sizeLoaded + parseInt(substring(imgInfo, lastIndexOf(imgInfo, "Size:")+7, lastIndexOf(imgInfo, "MB")));
					nmrOfFilesStitched = nmrOfFilesStitched+1;
					close();
					//close("Fused");
				
					list = getFileList(positionDir);
					list_bin = getFileList(positionDir_bin);
  					for (li=0; li<list.length; li++){
  						File.delete(positionDir+File.separator+list[li]); //deleting individual files created. The original data is still intact in the .czi files
  						File.delete(positionDir_bin+File.separator+list_bin[li]); //deleting individual files created. The original data is still intact in the .czi files
  						File.delete(positionDir);	//deletes folder
  						File.delete(positionDir_bin);	//deletes folder
  						File.delete(savingDir_temp);	//deletes folder										
					}
				}
			}
			buildWell();
		}
		else if (File.exists(savingDir)){
			if (File.exists(savingDir+File.separator+"positions"+".tif")){
				exit("You already have tiles stitched into their positions together with the final well thumbnail image assembled in "+files[f]+".");
			}	
			buildWell();
			setBatchMode(false);
			//open(savingDir+File.separator+"positions"+".tif");
			exit("You already had tiles stitched into their positions in "+files[f]+".\nWe've now assembled you the 12-well thumbnail overview.");
		}
	}
}

if (k==0) 
	exit("Sorry, there seems to be no .czi files in \n"+dir+".");
else if (seriesCount == 1) 
	exit("Your .czi file(s) in \n"+dir+" \ndon't seem to have more than 1 tile.");
	
		
setBatchMode(false);


list = getFileList(dir);
for (st=0; st<list.length; st++){
  	if (matches(list[st], ".*STIT"+saveType+".*")) open(dir+File.separator+list[st]);
}

end = getTime();
Dialog.create("This is not good for Zeiss business...");
Dialog.addMessage("You just stitched "+nmrOfTilesOpened+" Tile(s) into "+nmrOfFilesStitched+" Mosaic file(s).\n \nThat's a total of "+pixelTotal+" pixels and "+sizeLoaded+" MB... \n...within "+(end-start)/1000+" seconds ("+(end-start)/1000/60+" minutes).\n \nYou know, that's Super Computer kind of stuff...clap clap!");
Dialog.show();


function getData(){

	//MEASURING AND CREATING VARIABLES
	
	//creating variable recipients
	totArea=newArray(channels_nmr);
	mean=newArray(channels_nmr);
    standard=newArray(channels_nmr);
    modal=newArray(channels_nmr);
    integrated=newArray(channels_nmr);
    median=newArray(channels_nmr);
    fraction=newArray(channels_nmr);
    particlesArea = newArray(channels_nmr);
    binFraction = newArray(channels_nmr);
    meanSize = newArray(channels_nmr);
    number = newArray(channels_nmr);

	for (chnM=0; chnM<channels_nmr; chnM++){
		selectWindow(fileName+".tif");
		//setBatchMode(false);
		Stack.setChannel(chnM+1);

		//measure signal
		List.setMeasurements;
		totArea[chnM]=List.getValue("Area");
		mean[chnM]=List.getValue ("Mean");
    	standard[chnM]=List.getValue ("StdDev");
    	modal[chnM]=List.getValue ("Mode");
    	integrated[chnM]=List.getValue ("IntDen");
    	median[chnM]=List.getValue ("Median");
    	fraction[chnM]=List.getValue ("%Area");

		//measure particles
		selectWindow(fileName+".tif");
		run("Duplicate...", "duplicate channels="+chnM+1);
		runMacro(processMacro[chnM]);
		rename("bin_"+chnM);
		//run("Invert");
		run("Analyze Particles...", "clear");
		number[chnM]=nResults();
		particlesArea[chnM]=0;
		size= newArray(nResults);
		for (n=0; n<nResults; n++){
			//cmX[n]=getResult("XM", n);
			//cmY[n]=getResult("YM", n);
			size[n] = getResult("Area", n);
			particlesArea[chnM] = particlesArea[chnM]+size[n];
			//File.append(n+"\t"+size[n]+"\t"+cmX[n]+"\t"+cmY[n]+"\t", p_data_file);	
		}
		meanSize[chnM]= particlesArea[chnM]/nResults;
		//setBatchMode(false);
		//print(meanSize[chnM]);
		binFraction[chnM] = (particlesArea[chnM]/totArea[chnM])*100;
		//print(binFraction[chnM]);
		//waitForUser("maaaaan");
	}
	
	run("Images to Stack", "name=merged_bin title=bin_");
	run("Make Composite", "display=Grayscale");
	run("Invert", "stack");


	//Saving data into text files. TILES BY POSITIONS
	data_file = savingDir+File.separator+dataFileName;
	if (!File.exists(data_file)){
		
		markerCol="Position "+prefix+l+"                 \t	";
		markerCol2="Tile        ";
		for (mC=0; mC<markers.length; mC++){
			markerCol=markerCol+markers[mC]+"	\t";
			markerCol2=markerCol2+"\tmean\tStdev\tMode\tMedian\t%fraction\tNumber\tSize\t%binFraction";
		}

    	// Create a header
    	File.append(markerCol, data_file);
    	File.append(markerCol2, data_file);
	}
	// Create data content
	markerDat=fileSeries+ "\t";
		for (mC=0; mC<markers.length; mC++){
			markerDat=markerDat+ mean[mC] + "\t" + standard[mC] + "\t" + modal[mC] + "\t" + median[mC] + "\t" + fraction[mC] + "\t" + number[mC]+ "\t" + meanSize[mC]+ "\t" + binFraction[mC]+ "\t";
		}
	File.append(markerDat, data_file);						
}



//post stich adjustments
function post_stitch(){
	if (colors.length<2) 
		run(colors[0]);
	else{
		for (ii=0; ii<colors.length; ii++){ //Assigning colors to final image corresponding to excitation laser wavelengths
			Stack.setDisplayMode("color");
			Stack.setChannel(ii+1);
			run(colors[ii]);
		}
		run("Make Composite", "stack");
		//run("RGB Color", "slices");
	}
	//Setting the native scale
	run("Properties...", "channels="+channels_nmr+" slices="+zSteps+" frames="+tPoints+" unit="+unit+" pixel_width="+width+" pixel_height="+height+" voxel_depth="+depth+"");
}



function buildWell(){
	stitch_files = getFileList(savingDir);
	stitch_files = Array.sort(stitch_files); 
	kk=0;

	
	//open container image
	open("C:\\Program Files\\Fiji2.app\\macros\\toolsets\\Vasco\\stitching_tools\\12.tif");

	for (chnM=0; chnM<channels_nmr; chnM++){
		selectWindow("12.tif");
		run("Duplicate...", " ");
	}

	run("Images to Stack", "name=12_master title=12");
	run("Make Composite", "display=Color");

	//identify coordinates of well postitions


	A1_x = 345; 
	A1_y = 290;

	A2_x = 910; 
	A2_y = 290;

	A3_x = 1480; 
	A3_y = 290;

	A4_x = 2055; 
	A4_y = 290;

	B1_x = 345; 
	B1_y = 850;

	B2_x = 910; 
	B2_y = 850;

	B3_x = 1480; 
	B3_y = 850;

	B4_x = 2055; 
	B4_y = 850;

	C1_x = 345; 
	C1_y = 1400;

	C2_x = 910; 
	C2_y = 1400;

	C3_x = 1480; 
	C3_y = 1400;

	C4_x = 2055; 
	C4_y = 1400;


	well = newArray ("A1","A2","A3","A4","B1","B2","B3","B4","C1","C2","C3","C4");


	run("Bio-Formats Macro Extensions");
		for(ff=0; ff<stitch_files.length; ff++) {
			if(startsWith(stitch_files[ff], "STITCHED")) { 
				kk++;
				id_ = savingDir+File.separator+stitch_files[ff];
				Ext.setId(id_);
				print(stitch_files[ff]);


				//READING METADATA
				open(id_);
				//img_pos = (substring(id, lastIndexOf(id, "_pos")+lengthOf("PositionGroup|TilesX #")+posStartInd, lastIndexOf(fullMeta, "PositionGroup|TilesX #")+lengthOf("PositionGroup|TilesX #")+posLastInd););
				getDimensions(width, height, channels, slices, frames);


				rename("pasting_img");

				selectWindow("pasting_img");
				Stack.setDisplayMode("color");
				for (fi=0; fi<channels; fi++){
					//getLut(reds, greens, blues);
					//setLut(reds, greens, blues);
					Stack.setChannel(fi+1);
					run("Enhance Contrast", "saturated=0.35");
	
					selectWindow("12_master");
					Stack.setChannel(fi+1); 
					run(colors[fi]);
					//run("Grays");
					//setLut(reds, greens, blues);
				}
				selectWindow("pasting_img");
				run("Despeckle", "stack");
				run("Size...", "width=360 height=360 depth="+channels+" constrain average interpolation=Bilinear");


				run("Insert...", "source=pasting_img destination=12_master x="+well[kk-1]+"_x y="+well[kk-1]+"_y");
				close("pasting_img");
			}
			selectWindow("12_master");
			for (u=0; u<3; u++){
				Stack.setChannel(u+1);
				run("Enhance Contrast", "saturated=0.35");
			}
		}

	saveAs("tiff", savingDir+File.separator+"positions"+".tif");//saving image
	//open(savingDir+File.separator+"positions"+".tif");

	Stack.setDisplayMode("composite");
	run("Stack to RGB");
	close("positions-1.tif");
	selectWindow("positions.tif");
	Stack.setDisplayMode("color");
	run("Split Channels");
	run("Images to Stack", "name=Stack title=positions keep");
	saveAs("tiff", savingDir+File.separator+"positions"+".tif");//saving image
	//open(savingDir+File.separator+"positions"+".tif");
}

