/* Inspired by ROI_Color_Coder.ijm
	IJ BAR: https://github.com/tferr/Scripts#scripts
	http://imagejdocu.tudor.lu/doku.php?id=macro:roi_color_coder
	Tiago Ferreira, v.5.2 2015.08.13 -	v.5.3 2016.05.1 + pjl mods 6/16-30/2016 to automate defaults and add labels to ROIs
	This macro adds scaled result labels to each ROI object.
	This version: 3/16/2017 Add labelling by ID number and additional image label locations
 */
macro "Add scaled value labels to each ROI object"{
	requires("1.47r");
	saveSettings;
	/* Some cleanup */
	run("Select None");
	/* Set options for black objects on white background as this works better for publications */
	run("Options...", "iterations=1 white count=1"); /* set white background */
	run("Colors...", "foreground=black background=white selection=yellow"); /* set colors */
	setOption("BlackBackground", false);
	run("Appearance...", " "); /* do not use Inverting LUT */
	/*	The above should be the defaults but this makes sure (black particles on a white background)
		http://imagejdocu.tudor.lu/doku.php?id=faq:technical:how_do_i_set_up_imagej_to_deal_with_white_particles_on_a_black_background_by_default */
	t=getTitle();
	/* Now checks to see if a Ramp legend has been selected by accident */
	if (matches(t, ".*Ramp.*")==1) showMessageWithCancel("Title contains \"Ramp\"", "Do you want to label" + t + " ?"); 
	checkForRoiManager(); /* macro requires that the objects are in the ROI manager */
		
	setBatchMode(true);
	nROIs= roiManager("count");
	nRES= nResults;
	/* get id of image and number of ROIs */
	nMismatch = nROIs-nRES;
	items = nROIs;
	if (nMismatch>0) {
		nMB = getBoolean("Results table \(" + nRES + "\) and ROI Manager \(" + nROIs + "\) mismatch do you want to continue with largest number?");
			if(nMB){
				items = maxOf(nROIs, nRES);
				}
			else {
				nMBn = getBoolean("Do you want to continue with the smallest number?");
				if(nMBn){
				items = minOf(nROIs, nRES);
				}
				else restoreExit("ROI mismatch not to your liking; will exit macro");
				}
	}
	roiManager("Show All without labels");
	id = getImageID();
	imageWidth = getWidth();
	imageHeight = getHeight();
	imageDims = imageWidth + imageHeight;
	originalImageDepth = bitDepth();
	getPixelSize(unit, null, null);
	/* Set default label settings */
	fontSize = round(imageDims/80); /* default font size */
	paraLabFontSize = round(imageDims/60);
	outlineStroke = 8; /* default outline stroke: % of font size */
	shadowDrop = 12;  /* default outer shadow drop: % of font size */
	dIShO = 5; /* default inner shadow drop: % of font size */
	offsetX = round(1 + imageWidth/150); /* default offset of label from edge */
	offsetY = round(1 + imageHeight/150); /* default offset of label from edge */
	decPlaces = -1;	/* defaults to scientific notation */
	headings = split(String.getResultsHeadings, "\t"); /* the tab specificity avoids problems with unusual column titles */
	headingsWithRange= newArray(lengthOf(headings));
	for (i=0; i<lengthOf(headings); i++) {
		resultsColumn = newArray(items);
		for (j=0; j<items; j++)
			resultsColumn[j] = getResult(headings[i], j);
		Array.getStatistics(resultsColumn, min, max, null, null); 
		headingsWithRange[i] = headings[i] + ":  " + min + " - " + max;
	}
	/* Object number column has to be replaced, default column does not work for labelling */
	if (headingsWithRange[0]==" :  Infinity - -Infinity")
	headingsWithRange[0] = "Object#" + ":  1 - " + items; /* relabels ImageJ ID column */
	/*
	Feature Label Formatting Dialog */
	Dialog.create("Feature Label Formatting Options");
		Dialog.addMessage("Image: "+getTitle);
		Dialog.addChoice("Parameter", headingsWithRange, headingsWithRange[0]);
		if (originalImageDepth==24)
				colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray", "red", "pink", "green", "blue", "yellow", "orange", "garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "gray_modern", "green_dark_modern", "green_modern", "orange_modern", "pink_modern", "purple_modern", "red_N_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern"); 
		else colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray");
		Dialog.addChoice("Object label color:", colorChoice, colorChoice[0]);
		Dialog.addNumber("Font scaling % of Auto", 80);
		Dialog.addNumber("Minimum Label Font Size", round(imageWidth/90));
		Dialog.addNumber("Maximum Label Font Size", round(imageWidth/16));
		fontStyleChoice = newArray("bold", "bold antialiased", "italic", "italic antialiased", "bold italic", "bold italic antialiased", "unstyled");
		Dialog.addChoice("Font style:", fontStyleChoice, fontStyleChoice[1]);
		fontNameChoice = newArray("SansSerif", "Serif", "Monospaced");
		Dialog.addChoice("Font name:", fontNameChoice, fontNameChoice[0]);
		Dialog.addString("Label:", unit+"^2", 8);
		Dialog.setInsets(-35, 270, 0);
		Dialog.addMessage("^2 & um etc. replaced by " + fromCharCode(178) + " & " + fromCharCode(181) + "m etc.\n If the units are in the parameter\n label, within \(...\) i.e. \(unit\) they will \noverride this selection:");
		Dialog.addChoice("Decimal places:", newArray("Auto", "Manual", "Scientific", "0", "1", "2", "3", "4"), "Auto");
		Dialog.addNumber("Outline Stroke:", outlineStroke,0,3,"% of font size");
		Dialog.addChoice("Outline (background) color:", colorChoice, colorChoice[1]);
		Dialog.addNumber("Shadow Drop: ±", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Displacement Right: ±", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Gaussian Blur:", floor(0.75 * shadowDrop),0,3,"% of font size");
		Dialog.addNumber("Shadow Darkness:", 75,0,3,"%\(darkest = 100%\)");
		Dialog.addMessage("The following \"Inner Shadow\" options do not change the Overlay scale bar");
		Dialog.addNumber("Inner Shadow Drop: ±", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner Displacement Right: ±", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner Shadow Mean Blur:",floor(dIShO/2),1,3,"% of font size");
		Dialog.addNumber("Inner Shadow Darkness:", 20,0,3,"% \(darkest = 100%\)");
		if (isNaN(getResult("mc_X\(px\)",0))) {
			Dialog.addRadioButtonGroup("Object Labels At:_____________________ ", newArray("ROI Center", "Morphological Center"), 1, 2, "ROI Center");
			Dialog.addMessage("If selected, Morphological Centers will be added to the Results table.");
		}
		else Dialog.addRadioButtonGroup("Object Label At:", newArray("ROI Center", "Morphological Center"), 1, 2, "Morphological Center");
		paraLocChoice = newArray("Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right", "Center of New Selection"); 
		Dialog.addChoice("Location of Parameter Label:", paraLocChoice, paraLocChoice[0]);
		Dialog.addNumber("Image Label Font size:", paraLabFontSize);			
	
		Dialog.show();
		parameterWithLabel= Dialog.getChoice;
		parameter= substring(parameterWithLabel, 0, indexOf(parameterWithLabel, ":  "));
		labelColor = Dialog.getChoice();
		fontSizeCorrection =  Dialog.getNumber()/100;
		minLFontSize = Dialog.getNumber(); 
		maxLFontSize = Dialog.getNumber(); 
		fontStyle = Dialog.getChoice();
		font = Dialog.getChoice();
		unitLabel = cleanLabel(Dialog.getString());
		dpChoice= Dialog.getChoice();
		outlineStroke = Dialog.getNumber();
		outlineColor = Dialog.getChoice();
		shadowDrop = Dialog.getNumber();
		shadowDisp = Dialog.getNumber();
		shadowBlur = Dialog.getNumber();
		shadowDarkness = Dialog.getNumber();
		innerShadowDrop = Dialog.getNumber();
		innerShadowDisp = Dialog.getNumber();
		innerShadowBlur = Dialog.getNumber();
		innerShadowDarkness = Dialog.getNumber();
		ctrChoice = Dialog.getRadioButton();
		paraLabPos = Dialog.getChoice();
		paraLabFontSize =  Dialog.getNumber();
		
		if (isNaN(getResult("mc_X\(px\)",0)) && ctrChoice=="Morphological Center") 
			AddMCsToResultsTable ();
				
		negAdj = 0.5;  /* negative offsets appear exaggerated at full displacement */
		if (shadowDrop<0) shadowDrop *= negAdj;
		if (shadowDisp<0) shadowDisp *= negAdj;
		if (shadowBlur<0) shadowBlur *= negAdj;
		if (innerShadowDrop<0) innerShadowDrop *= negAdj;
		if (innerShadowDisp<0) innerShadowDisp *= negAdj;
		if (innerShadowBlur<0) innerShadowBlur *= negAdj;
		
		fontPC = (100/imageDims) * fontSize/10; /* convert percent to pixels */
		outlineStroke = floor(fontPC * outlineStroke);
		shadowDrop = floor(fontPC * shadowDrop);
		shadowDisp = floor(fontPC * shadowDisp);
		shadowBlur = floor(fontPC * shadowBlur);
		innerShadowDrop = floor(fontPC * innerShadowDrop);
		innerShadowDisp = floor(fontPC * innerShadowDisp);
		innerShadowBlur = floor(fontPC * innerShadowBlur);
		
		shadowDarkness = (255/100) * (abs(shadowDarkness));
		innerShadowDarkness = (255/100) * (100 - (abs(innerShadowDarkness)));
		unitLabelCheck = matches(unitLabel, ".*[A-Za-z].*");
		
		if (dpChoice=="Manual") 
			decPlaces = getNumber("Choose Number of Decimal Places", decPlaces);
		else if (dpChoice=="scientific") 
			decPlaces = -1;
		else if (dpChoice!="Auto")
			decPlaces = dpChoice;
		
	if (fontStyle=="unstyled") fontStyle="";
	roiManager("show none"); /* I hope you did not want roi overlays */
	run("Flatten");
	flatImage = getTitle();
	if (is("Batch Mode")==false) setBatchMode(true);
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	
	/* iterate through the ROI Manager list and colorize ROIs and rename ROIs and draw scaled label */
	for (i=0; i<items; i++) {
		writeObjectLabelNoRamp();
	}
	setThreshold(0, 128);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	/* Create drop shadow if desired */
	if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0) {
		createShadowDropFromMask();
	}
	/* Create inner shadow if desired */
	if (innerShadowDrop!=0 || innerShadowDisp!=0 || innerShadowBlur!=0) {
		createInnerShadowFromMask();
	}
	if (isOpen("shadow"))
		imageCalculator("Subtract", flatImage,"shadow");
	run("Select None");
	getSelectionFromMask("label_mask");
	run("Enlarge...", "enlarge=[outlineStroke] pixel");
	setBackgroundFromColorName(outlineColor);
	run("Clear");
	run("Select None");
	getSelectionFromMask("label_mask");
	setBackgroundFromColorName(labelColor);
	run("Clear");
	run("Select None");
	if (isOpen("inner_shadow"))
		imageCalculator("Subtract", flatImage,"inner_shadow");
	closeImageByTitle("shadow");
	closeImageByTitle("inner_shadow");
	closeImageByTitle("label_mask");
	selectWindow(flatImage);
	/* Now repeat with the Parameter Label over the top of the object labels */
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	if (paraLabPos!="None") {
		setFont(font,paraLabFontSize,fontStyle);
		if (unitLabelCheck==0)	paraLabel = parameter;
		else paraLabel = parameter + ", " + unitLabel;
		if (paraLabPos == "Top Left") {
			selEX = offsetX;
			selEY = offsetY;
		} else if (paraLabPos == "Top Right") {
			selEX = imageWidth - getStringWidth(paraLabel) - offsetX;
			selEY = offsetY;
		} else if (paraLabPos == "Center") {
				selEX = round((imageWidth - getStringWidth(paraLabel))/2);
				selEY = round((imageHeight - paraLabFontSize)/2);
		} else if (paraLabPos == "Bottom Left") {
			selEX = offsetX;
			selEY = imageHeight - (offsetY); 
		} else if (paraLabPos == "Bottom Right") {
			selEX = imageWidth - getStringWidth(paraLabel) - offsetX;
			selEY = imageHeight - (offsetY); 
		} else if (paraLabPos == "Center of New Selection"){
			setBatchMode("false"); /* Does not accept interaction while batch mode is on */
			setTool("rectangle");
			msgtitle="Location for the summary labels...";
			msg = "Draw a box in the image where you want to center the image-parameter...";
			waitForUser(msgtitle, msg);
			getSelectionBounds(newSelEX, newSelEY, newSelEWidth, newSelEHeight);
			run("Select None");
			selEX = newSelEX + round((newSelEWidth - getStringWidth(paraLabel))/2);
			selEY = newSelEY + round((newSelEHeight - paraLabFontSize)/2);
			setBatchMode("true");	// toggle batch mode back on
		}if (selEY<=1.5*paraLabFontSize)
			selEY += paraLabFontSize;
		if (selEX<offsetX) selEX = offsetX;
		endX = selEX + getStringWidth(paraLabel);
		if ((endX+offsetX)>imageWidth) selEX = imageWidth - getStringWidth(paraLabel) - offsetX;
		setColorFromColorName("white");
		drawString(paraLabel, selEX,  selEY);
	}
	setThreshold(0, 128);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	/* Create drop shadow if desired */
	if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0) {
		createShadowDropFromMask();
	}
	/* Create inner shadow if desired */
	if (innerShadowDrop!=0 || innerShadowDisp!=0 || innerShadowBlur!=0) {
		createInnerShadowFromMask();
	}
	if (isOpen("shadow"))
		imageCalculator("Subtract", flatImage,"shadow");
	run("Select None");
	getSelectionFromMask("label_mask");
	run("Enlarge...", "enlarge=[outlineStroke] pixel");
	setBackgroundFromColorName(outlineColor); // functionoutlineColor]")
	run("Clear");
	run("Select None");
	getSelectionFromMask("label_mask");
	setBackgroundFromColorName(labelColor);
	run("Clear");
	run("Select None");
	if (isOpen("inner_shadow"))
		imageCalculator("Subtract", flatImage,"inner_shadow");
	closeImageByTitle("shadow");
	closeImageByTitle("inner_shadow");
	closeImageByTitle("label_mask");
	selectWindow(flatImage);
	if ((lastIndexOf(t,"."))>0)  labeledImageNameWOExt = unCleanLabel(substring(flatImage, 0, lastIndexOf(flatImage,".")));
	else labeledImageNameWOExt = unCleanLabel(flatImage);
	rename(labeledImageNameWOExt + "_" + parameter);
	restoreSettings;
	setBatchMode("exit & display");
	showStatus("Fancy Feature Labeler Macro Finished");
	run("Collect Garbage"); 
/*
	( 8(|)   ( 8(|)  Functions  ( 8(|)  ( 8(|)
*/
	function AddMCsToResultsTable () {
/* 	Based on "MCentroids.txt" Morphological centroids by thinning assumes white particles: G.Landini
	http://imagejdocu.tudor.lu/doku.php?id=plugin:morphology:morphological_operators_for_imagej:start
	http://www.mecourse.com/landinig/software/software.html
	Modified to add coordinates to Results Table: Peter J. Lee NHMFL  7/20-29/2016
	v180102	fixed typos and updated functions.
	v180104 removed unnecessary changes to settings.
	v180312 Add minimum and maximum morphological radii.
*/
	workingTitle = getTitle();
	if (!checkForPlugin("morphology_collection")) restoreExit("Exiting: Gabriel Landini's morphology suite is needed to run this macro.");
	binaryCheck(workingTitle); /* Makes sure image is binary and sets to white background, black objects */
	checkForRoiManager(); /* This macro uses ROIs and a Results table that matches in count */
	roiOriginalCount = roiManager("count");
	addRadii = getBoolean("Do you also want to add the min and max M-Centroid radii to the Results table?");
	batchMode = is("Batch Mode"); /* Store batch status mode before toggling */
	if (!batchMode) setBatchMode(true); /* Toggle batch mode on if previously off */
	start = getTime();
	getPixelSize(unit, pixelWidth, pixelHeight);
	lcf=(pixelWidth+pixelHeight)/2;
	objects = roiManager("count");
	mcImageWidth = getWidth();
	mcImageHeight = getHeight();
	showStatus("Looping through all " + roiOriginalCount + " objects for morphological centers . . .");
	for (i=0 ; i<roiOriginalCount; i++) {
		showProgress(-i, roiManager("count"));
		selectWindow(workingTitle);
		roiManager("select", i);
		if(addRadii) run("Interpolate", "interval=1");	getSelectionCoordinates(xPoints, yPoints); /* place border coordinates in array for radius measurements - Wayne Rasband: http://imagej.1557.x6.nabble.com/List-all-pixel-coordinates-in-ROI-td3705127.html */
		Roi.getBounds(Rx, Ry, Rwidth, Rheight);
		setResult("ROIctr_X\(px\)", i, Rx + Rwidth/2);
		setResult("ROIctr_Y\(px\)", i, Ry + Rheight/2);
		Roi.getContainedPoints(RPx, RPy); /* this includes holes when ROIs are used so no hole filling is needed */
		newImage("Contained Points","8-bit black",Rwidth,Rheight,1); /* give each sub-image a unique name for debugging purposes */
		for (j=0; j<lengthOf(RPx); j++)
			setPixel(RPx[j]-Rx, RPy[j]-Ry, 255);
		selectWindow("Contained Points");
		run("BinaryThin2 ", "kernel_a='0 2 2 0 1 1 0 0 2 ' kernel_b='0 0 2 0 1 1 0 2 2 ' rotations='rotate 45' iterations=-1 white");
		for (j=0; j<lengthOf(RPx); j++){
			if((getPixel(RPx[j]-Rx, RPy[j]-Ry))==255) {
				centroidX = RPx[j]; centroidY = RPy[j];
				setResult("mc_X\(px\)", i, centroidX);
				setResult("mc_Y\(px\)", i, centroidY);
				setResult("mc_offsetX\(px\)", i, getResult("X",i)/lcf-(centroidX));
				setResult("mc_offsetY\(px\)", i, getResult("Y",i)/lcf-(centroidY));
				// if (lcf!=1) {
					// setResult("mc_X\(" + unit + "\)", i, (centroidX)*lcf); /* perhaps not too useful */
					// setResult("mc_Y\(" + unit + "\)", i, (centroidY)*lcf); /* perhaps not too useful */	
				// }
				j = lengthOf(RPx); /* one point and done */
			}
		}
		closeImageByTitle("Contained Points");
		if(addRadii) {
			/* Now measure min and max radii from M-Centroid */
			rMin = Rwidth + Rheight; rMax = 0;
			for (j=0 ; j<(lengthOf(xPoints)); j++) {
				dist = sqrt((centroidX-xPoints[j])*(centroidX-xPoints[j])+(centroidY-yPoints[j])*(centroidY-yPoints[j]));
				if (dist < rMin) { rMin = dist; rMinX = xPoints[j]; rMinY = yPoints[j];}
				if (dist > rMax) { rMax = dist; rMaxX = xPoints[j]; rMaxY = yPoints[j];}
			}
			if (rMin == 0) rMin = 0.5; /* Correct for 1 pixel width objects and interpolate error */
			setResult("mc_minRadX", i, rMinX);
			setResult("mc_minRadY", i, rMinY);
			setResult("mc_maxRadX", i, rMaxX);
			setResult("mc_maxRadY", i, rMaxY);
			setResult("mc_minRad\(px\)", i, rMin);
			setResult("mc_maxRad\(px\)", i, rMax);
			setResult("mc_AR", i, rMax/rMin);
			if (lcf!=1) {
				setResult('mc_minRad' + "\(" + unit + "\)", i, rMin*lcf);
				setResult('mc_maxRad' + "\(" + unit + "\)", i, rMax*lcf);
			}
		}
	}
	updateResults();
	run("Select None");
	if (!batchMode) setBatchMode(false); /* Toggle batch mode off */
	showStatus("MC Function Finished: " + roiManager("count") + " objects analyzed in " + (getTime()-start)/1000 + "s.");
	beep(); wait(300); beep(); wait(300); beep();
	run("Collect Garbage"); 
	}	
	function autoCalculateDecPlacesFromValueOnly(value){
		valueSci = d2s(value, -1);
		iExp = indexOf(valueSci, "E");
		valueExp = parseInt(substring(valueSci, iExp+1));
		if (valueExp>=2) dP = 0;
		if (valueExp<2) dP = 2-valueExp;
		if (valueExp<-5) dP = -1; /* Scientific Notation */
		if (valueExp>=4) dP = -1; /* Scientific Notation */
		return dP;
	}
	function binaryCheck(windowTitle) { /* for black objects on white background */
		selectWindow(windowTitle);
		if (is("binary")==0) run("8-bit");
		/* Quick-n-dirty threshold if not previously thresholded */
		getThreshold(t1,t2); 
		if (t1==-1)  {
			run("8-bit");
			setThreshold(0, 128);
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Invert");
			}
		/* Make sure black objects on white background for consistency */
		if (((getPixel(0, 0))==0 || (getPixel(0, 1))==0 || (getPixel(1, 0))==0 || (getPixel(1, 1))==0))
			run("Invert"); 
		/*	Sometimes the outline procedure will leave a pixel border around the outside - this next step checks for this.
			i.e. the corner 4 pixels should now be all black, if not, we have a "border issue". */
		if (((getPixel(0, 0))+(getPixel(0, 1))+(getPixel(1, 0))+(getPixel(1, 1))) != 4*(getPixel(0, 0)) ) 
				restoreExit("Border Issue"); 	
	}
	function checkForPlugin(pluginName) {
		/* v161102 changed to true-false */
		var pluginCheck = false, subFolderCount = 0;
		if (getDirectory("plugins") == "") restoreExit("Failure to find any plugins!");
		else pluginDir = getDirectory("plugins");
		if (!endsWith(pluginName, ".jar")) pluginName = pluginName + ".jar";
		if (File.exists(pluginDir + pluginName)) {
				pluginCheck = true;
				showStatus(pluginName + "found in: "  + pluginDir);
		}
		else {
			pluginList = getFileList(pluginDir);
			subFolderList = newArray(lengthOf(pluginList));
			for (i=0; i<lengthOf(pluginList); i++) {
				if (endsWith(pluginList[i], "/")) {
					subFolderList[subFolderCount] = pluginList[i];
					subFolderCount = subFolderCount +1;
				}
			}
			subFolderList = Array.slice(subFolderList, 0, subFolderCount);
			for (i=0; i<lengthOf(subFolderList); i++) {
				if (File.exists(pluginDir + subFolderList[i] +  "\\" + pluginName)) {
					pluginCheck = true;
					showStatus(pluginName + " found in: " + pluginDir + subFolderList[i]);
					i = lengthOf(subFolderList);
				}
			}
		}
		return pluginCheck;
	}
	function checkForRoiManager() {
		/* v161109 adds the return of the updated ROI count and also adds dialog if there are already entries just in case . . */
		nROIs = roiManager("count");
		nRES = nResults; /* not really needed except to provide useful information below */
		if (nROIs==0) runAnalyze = true;
		else runAnalyze = getBoolean("There are already " + nROIs + " in the ROI manager; do you want to clear the ROI manager and reanalyze?");
		if (runAnalyze) {
			roiManager("reset");
			Dialog.create("Analysis check");
			Dialog.addCheckbox("Run Analyze-particles to generate new roiManager values?", true);
			Dialog.addMessage("This macro requires that all objects have been loaded into the roi manager.\n \nThere are   " + nRES +"   results.\nThere are   " + nROIs +"   ROIs.");
			Dialog.show();
			analyzeNow = Dialog.getCheckbox();
			if (analyzeNow) {
				setOption("BlackBackground", false);
				if (nResults==0)
					run("Analyze Particles...", "display add");
				else run("Analyze Particles..."); /* let user select settings */
				if (nResults!=roiManager("count"))
					restoreExit("Results and ROI Manager counts do not match!");
			}
			else restoreExit("Goodbye, your previous setting will be restored.");
		}
		return roiManager("count"); /* returns the new count of entries */
	}	
	function cleanLabel(string) {
		/* v161104 */
		string= replace(string, "\\^2", fromCharCode(178)); /* superscript 2 */
		string= replace(string, "\\^3", fromCharCode(179)); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, "\\^-1", fromCharCode(0x207B) + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-2", fromCharCode(0x207B) + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "\\^-^1", fromCharCode(0x207B) + fromCharCode(185)); /*	superscript -1 */
		string= replace(string, "\\^-^2", fromCharCode(0x207B) + fromCharCode(178)); /*	superscript -2 */
		string= replace(string, "(?<![A-Za-z0-9])u(?=m)", fromCharCode(181)); /* micrometer units*/
		string= replace(string, "\\b[aA]ngstrom\\b", fromCharCode(197)); /* angstrom symbol*/
		string= replace(string, "  ", " "); /* double spaces*/
		string= replace(string, "_", fromCharCode(0x2009)); /* replace underlines with thin spaces*/
		string= replace(string, "px", "pixels"); /* expand pixel abbreviate*/
		string = replace(string, " " + fromCharCode(0x00B0), fromCharCode(0x00B0)); /*	remove space before degree symbol */
		string= replace(string, " °", fromCharCode(0x2009)+"°"); /*	remove space before degree symbol */
		return string;
	}	
	function closeImageByTitle(windowTitle) {  /* cannot be used with tables */
        if (isOpen(windowTitle)) {
		selectWindow(windowTitle);
        close();
		}
	}
	function createInnerShadowFromMask() {
		/* requires previous run of:  originalImageDepth = bitDepth();
		because this version works with different bitDepths
		v161104 */
		showStatus("Creating inner shadow for labels . . . ");
		newImage("inner_shadow", "8-bit white", imageWidth, imageHeight, 1);
		getSelectionFromMask("label_mask");
		setBackgroundColor(0,0,0);
		run("Clear Outside");
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX-innerShadowDisp, selMaskY-innerShadowDrop);
		setBackgroundColor(0,0,0);
		run("Clear Outside");
		getSelectionFromMask("label_mask");
		expansion = abs(innerShadowDisp) + abs(innerShadowDrop) + abs(innerShadowBlur);
		if (expansion>0) run("Enlarge...", "enlarge=[expansion] pixel");
		if (innerShadowBlur>0) run("Gaussian Blur...", "sigma=[innerShadowBlur]");
		run("Unsharp Mask...", "radius=0.5 mask=0.2"); /* A tweak to sharpen the effect for small font sizes */
		imageCalculator("Max", "inner_shadow","label_mask");
		run("Select None");
		/* The following are needed for different bit depths */
		if (originalImageDepth==16 || originalImageDepth==32) run(originalImageDepth + "-bit");
		run("Enhance Contrast...", "saturated=0 normalize");
		run("Invert");  /* create an image that can be subtracted - works better for color than min */
		divider = (100 / abs(innerShadowDarkness));
		run("Divide...", "value=[divider]");
	}
	function createShadowDropFromMask() {
		/* requires previous run of:  originalImageDepth = bitDepth();
		because this version works with different bitDepths
		v161104 */
		showStatus("Creating drop shadow for labels . . . ");
		newImage("shadow", "8-bit black", imageWidth, imageHeight, 1);
		getSelectionFromMask("label_mask");
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX+shadowDisp, selMaskY+shadowDrop);
		setBackgroundColor(255,255,255);
		if (outlineStroke>0) run("Enlarge...", "enlarge=[outlineStroke] pixel"); /* adjust so shadow extends beyond stroke thickness */
		run("Clear");
		run("Select None");
		if (shadowBlur>0) {
			run("Gaussian Blur...", "sigma=[shadowBlur]");
			// run("Unsharp Mask...", "radius=[shadowBlur] mask=0.4"); /* Make Gaussian shadow edge a little less fuzzy */
		}
		/* Now make sure shadow of glow does not impact outline */
		getSelectionFromMask("label_mask");
		if (outlineStroke>0) run("Enlarge...", "enlarge=[outlineStroke] pixel");
		setBackgroundColor(0,0,0);
		run("Clear");
		run("Select None");
		/* The following are needed for different bit depths */
		if (originalImageDepth==16 || originalImageDepth==32) run(originalImageDepth + "-bit");
		run("Enhance Contrast...", "saturated=0 normalize");
		divider = (100 / abs(shadowDarkness));
		run("Divide...", "value=[divider]");
	}

	/* ASC Color Functions */
	function getColorArrayFromColorName(colorName) {
		cA = newArray(255,255,255);
		if (colorName == "white") cA = newArray(255,255,255);
		else if (colorName == "black") cA = newArray(0,0,0);
		else if (colorName == "light_gray") cA = newArray(200,200,200);
		else if (colorName == "gray") cA = newArray(127,127,127);
		else if (colorName == "dark_gray") cA = newArray(51,51,51);
		else if (colorName == "red") cA = newArray(255,0,0);
		else if (colorName == "pink") cA = newArray(255, 192, 203);
		else if (colorName == "green") cA = newArray(255,255,0);
		else if (colorName == "blue") cA = newArray(0,0,255);
		else if (colorName == "yellow") cA = newArray(255,255,0);
		else if (colorName == "orange") cA = newArray(255, 165, 0);
		else if (colorName == "garnet") cA = newArray(120,47,64);
		else if (colorName == "gold") cA = newArray(206,184,136);
		else if (colorName == "aqua_modern") cA = newArray(75,172,198);
		else if (colorName == "blue_accent_modern") cA = newArray(79,129,189);
		else if (colorName == "blue_dark_modern") cA = newArray(31,73,125);
		else if (colorName == "blue_modern") cA = newArray(58,93,174);
		else if (colorName == "gray_modern") cA = newArray(83,86,90);
		else if (colorName == "green_dark_modern") cA = newArray(121,133,65);
		else if (colorName == "green_modern") cA = newArray(155,187,89);
		else if (colorName == "orange_modern") cA = newArray(247,150,70);
		else if (colorName == "pink_modern") cA = newArray(255,105,180);
		else if (colorName == "purple_modern") cA = newArray(128,100,162);
		else if (colorName == "red_N_modern") cA = newArray(227,24,55);
		else if (colorName == "red_modern") cA = newArray(192,80,77);
		else if (colorName == "tan_modern") cA = newArray(238,236,225);
		else if (colorName == "violet_modern") cA = newArray(76,65,132);
		else if (colorName == "yellow_modern") cA = newArray(247,238,69);
		return cA;
	}
	function setColorFromColorName(colorName) {
		colorArray = getColorArrayFromColorName(colorName);
		setColor(colorArray[0], colorArray[1], colorArray[2]);
	}
	function setBackgroundFromColorName(colorName) {
		colorArray = getColorArrayFromColorName(colorName);
		setBackgroundColor(colorArray[0], colorArray[1], colorArray[2]);
	}
	/* Hex conversion below adapted from T.Ferreira, 20010.01 http://imagejdocu.tudor.lu/doku.php?id=macro:rgbtohex */
	function pad(n) {
		n = toString(n);
		if(lengthOf(n)==1) n = "0"+n;
		return n;
	}
	function getHexColorFromRGBArray(colorNameString) {
		colorArray = getColorArrayFromColorName(colorNameString);
		 r = toHex(colorArray[0]); g = toHex(colorArray[1]); b = toHex(colorArray[2]);
		 hexName= "#" + ""+pad(r) + ""+pad(g) + ""+pad(b);
		 return hexName;
	}	
	// function removeTrailingZerosAndPeriod(string) { //removes trailing zeros after period
		// while (endsWith(string,".0")) {
			// string=substring(string,0, lastIndexOf(string, ".0"));
		// }
		// while(endsWith(string,".")) {
			// string=substring(string,0, lastIndexOf(string, "."));
		// }
		// return string;
	// }
	function getSelectionFromMask(selection_Mask){
		batchMode = is("Batch Mode"); /* Store batch status mode before toggling */
		if (!batchMode) setBatchMode(true); /* Toggle batch mode on if previously off */
		tempTitle = getTitle();
		selectWindow(selection_Mask);
		run("Create Selection"); /* selection inverted perhaps because mask has inverted lut? */
		run("Make Inverse");
		selectWindow(tempTitle);
		run("Restore Selection");
		if (!batchMode) setBatchMode("exit");
	}
	function restoreExit(message){ /* clean up before aborting macro then exit */
		/* 9/9/2017 added Garbage clean up suggested by Luc LaLonde - LBNL */
		restoreSettings(); /* clean up before exiting */
		setBatchMode("exit & display"); /* not sure if this does anything useful if exiting gracefully but otherwise harmless */
		run("Collect Garbage"); 
		exit(message);
	}
	function unCleanLabel(string) { 
	/* v161104 This function replaces special characters with standard characters for file system compatible filenames */
	/* mod 041117 to remove spaces as well */
		string= replace(string, fromCharCode(178), "\\^2"); /* superscript 2 */
		string= replace(string, fromCharCode(179), "\\^3"); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, fromCharCode(0x207B) + fromCharCode(185), "\\^-1"); /* superscript -1 */
		string= replace(string, fromCharCode(0x207B) + fromCharCode(178), "\\^-2"); /* superscript -2 */
		string= replace(string, fromCharCode(181), "u"); /* micrometer units */
		string= replace(string, fromCharCode(197), "Angstrom"); /* angstrom symbol */
		string= replace(string, fromCharCode(0x2009)+"fromCharCode(0x00B0)", "deg"); /* replace thin spaces degrees combination */
		string= replace(string, fromCharCode(0x2009), "_"); /* replace thin spaces  */
		string= replace(string, " ", "_"); /* replace spaces - these can be a problem with image combination */
		string= replace(string, "_\\+", "\\+"); /* clean up autofilenames */
		string= replace(string, "\\+\\+", "\\+"); /* clean up autofilenames */
		string= replace(string, "__", "_"); /* clean up autofilenames */
		return string;
	}
	function writeLabel(labelColor){
		setColorFromColorName(labelColor);
		drawString(finalLabel, finalLabelX, finalLabelY); 
	}	
	function writeObjectLabelNoRamp() {
		roiManager("Select", i);
		if (parameter=="Object#") labelValue = i+1;
		else labelValue = getResult(parameter,i);
		if (dpChoice=="Auto")
			decPlaces = autoCalculateDecPlacesFromValueOnly(labelValue);
		labelString = d2s(labelValue,decPlaces); /* Reduce Decimal places for labeling - move these two lines to below the labels you prefer */
		Roi.getBounds(roiX, roiY, roiWidth, roiHeight);
		lFontSize = fontSize; /* initial estimate */
		setFont(font,lFontSize,fontStyle);
		lFontSize = fontSizeCorrection * fontSize * roiWidth/(getStringWidth(labelString)); /* adjust label font size so it fits within object width */
		if (lFontSize>fontSizeCorrection*roiHeight) lFontSize = fontSizeCorrection*roiHeight; /* readjust label font size so label fits within object height */
		if (lFontSize>maxLFontSize) lFontSize = maxLFontSize; 
		if (lFontSize<minLFontSize) lFontSize = minLFontSize;
		setFont(font,lFontSize,fontStyle);
		if (ctrChoice=="ROI Center") 
			textOffset = roiX + ((roiWidth) - getStringWidth(labelString))/2;
		else textOffset = getResult("mc_X\(px\)",i) - getStringWidth(labelString)/2;
		setColorFromColorName("white");
		if (ctrChoice=="ROI Center")
			drawString(labelString, textOffset, roiY+roiHeight/2 + lFontSize/2);
		else drawString(labelString, textOffset, getResult("mc_Y\(px\)",i) + lFontSize/2);
	}
