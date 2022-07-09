/* Inspired by ROI_Color_Coder.ijm
	IJ BAR: https://github.com/tferr/Scripts#scripts
	http://imagejdocu.tudor.lu/doku.php?id=macro:roi_color_coder
	Tiago Ferreira, v.5.2 2015.08.13 -	v.5.3 2016.05.1 + pjl mods 6/16-30/2016 to automate defaults and add labels to ROIs
	This macro adds scaled result labels to each ROI object.
	3/16/2017 Add labeling by ID number and additional image label locations.
	v180612 set to work on only one slice.
	v180723 Allows use of system fonts.
	+ v200707 Changed imageDepth variable name added macro label.  + bugfix v210415
	+ v211022 Updated color choices  f5: updated functions f6: updated colors Replaced binary[-]Check with toWhiteBGBinary
 */
macro "Add scaled value labels to each ROI object"{
	macroL = "Fancy_Feature_Labeler_v211022-f6";
	requires("1.47r");
	saveSettings;
	/* Some cleanup */
	run("Select None");
	/* Set options for black objects on white background as this works better for publications */
	run("Options...", "iterations=1 white count=1"); /* Set the background to white */
	run("Colors...", "foreground=black background=white selection=yellow"); /* Set the preferred colors for these macros */
	setOption("BlackBackground", false);
	run("Appearance...", " "); if(is("Inverting LUT")) run("Invert LUT"); /* do not use Inverting LUT */
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
	imageDepth = bitDepth();
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
	/* Object number column has to be replaced, default column does not work for labeling */
	if (headingsWithRange[0]==" :  Infinity - -Infinity")
	headingsWithRange[0] = "Object#" + ":  1 - " + items; /* relabels ImageJ ID column */
	/*
	Feature Label Formatting Dialog */
	Dialog.create("Feature Label Formatting Options:" + macroL);
		Dialog.addMessage("Image: " + getTitle);
		Dialog.addChoice("Parameter", headingsWithRange, headingsWithRange[0]);
		colorChoices = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray");
		if (imageDepth==24){
			colorChoicesStd = newArray("red", "cyan", "pink", "green", "blue", "magenta", "yellow", "orange");
			colorChoicesMod = newArray("garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "blue_honolulu", "gray_modern", "green_dark_modern", "green_modern", "green_modern_accent", "green_spring_accent", "orange_modern", "pink_modern", "purple_modern", "red_n_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern");
			colorChoicesNeon = newArray("jazzberry_jam", "radical_red", "wild_watermelon", "outrageous_orange", "supernova_orange", "atomic_tangerine", "neon_carrot", "sunglow", "laser_lemon", "electric_lime", "screamin'_green", "magic_mint", "blizzard_blue", "dodger_blue", "shocking_pink", "razzle_dazzle_rose", "hot_magenta");
			colorChoices = Array.concat(colorChoices, colorChoicesStd, colorChoicesMod, colorChoicesNeon);
		}
		Dialog.addChoice("Object label color:", colorChoices, colorChoices[0]);
		Dialog.addNumber("Font scaling % of Auto", 80);
		Dialog.addNumber("Minimum Label Font Size", round(imageWidth/90));
		Dialog.addNumber("Maximum Label Font Size", round(imageWidth/16));
		fontStyleChoice = newArray("bold", "bold antialiased", "italic", "italic antialiased", "bold italic", "bold italic antialiased", "unstyled");
		Dialog.addChoice("Font style:", fontStyleChoice, fontStyleChoice[1]);
		fontNameChoice = getFontChoiceList();
		Dialog.addChoice("Font name:", fontNameChoice, fontNameChoice[0]);
		Dialog.addString("Label:", unit+"^2", 8);
		Dialog.setInsets(-35, 270, 0);
		Dialog.addMessage("^2 & um etc. replaced by " + fromCharCode(178) + " & " + fromCharCode(181) + "m etc.\n If the units are in the parameter\n label, within \(...\) i.e. \(unit\) they will \noverride this selection:");
		Dialog.addChoice("Decimal places:", newArray("Auto", "Manual", "Scientific", "0", "1", "2", "3", "4"), "Auto");
		Dialog.addNumber("Outline stroke:", outlineStroke,0,3,"% of font size");
		Dialog.addChoice("Outline (background) color:", colorChoices, colorChoices[1]);
		Dialog.addNumber("Shadow drop: ±", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow displacement right: ±", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Gaussian blur:", floor(0.75 * shadowDrop),0,3,"% of font size");
		Dialog.addNumber("Shadow Darkness:", 75,0,3,"%\(darkest = 100%\)");
		Dialog.addMessage("The following \"Inner Shadow\" options do not change the Overlay scale bar");
		Dialog.addNumber("Inner shadow drop: ±", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner displacement right: ±", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner shadow mean blur:",floor(dIShO/2),1,3,"% of font size");
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
		fontSizeCorrection = Dialog.getNumber/100;
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
		if (isNaN(getResult("mc_X\(px\)",0)) && ctrChoice=="Morphological Center"){
			if (!is("binary")){
				run("Duplicate...", "title=temp_binary_for_MCs");
				run("8-bit");
				AddMCsToResultsTable();
				closeImageByTitle("temp_binary_for_MCs");
			}
			else AddMCsToResultsTable();
		}
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
	run("Clear", "slice");
	run("Select None");
	getSelectionFromMask("label_mask");
	setBackgroundFromColorName(labelColor);
	run("Clear", "slice");
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
	run("Clear", "slice");
	run("Select None");
	getSelectionFromMask("label_mask");
	setBackgroundFromColorName(labelColor);
	run("Clear", "slice");
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
	call("java.lang.System.gc");
/*
	( 8(|)   ( 8(|)  Functions  ( 8(|)  ( 8(|)
*/
	function AddMCsToResultsTable() {
	/* 	Based on "MCentroids.txt" Morphological centroids by thinning assumes white particles: G. Landini
		http://imagejdocu.tudor.lu/doku.php?id=plugin:morphology:morphological_operators_for_imagej:start
		http://www.mecourse.com/landinig/software/software.html
		Modified to add coordinates to Results Table: Peter J. Lee NHMFL  7/20-29/2016
		v180102	Fixed typos and updated functions.
		v180104 Removed unnecessary changes to settings.
		v180312 Add minimum and maximum morphological radii.
		v180602 Add 0.5 pixels to output co-ordinates to match X,Y, XM and YM system for ImageJ results
		v190802 Updated distance measurement to use more compact pow function.
		v220707 Uses toWhiteBGBinary instead of binary[-]Check. Use duplicate image to retain color.
	*/
		workingTitle = getTitle();
		if (!checkForPlugin("morphology_collection")) restoreExit("Exiting: Gabriel Landini's morphology suite is needed to run this function.");
		toWhiteBGBinary(workingTitle); /* Makes sure image is binary and sets to white background, black objects */
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
			Roi.getContainedPoints(RPx, RPy); /* This includes holes when ROIs are used, so no hole filling is needed */
			newImage("Contained Points","8-bit black",Rwidth,Rheight,1); /* Give each sub-image a unique name for debugging purposes */
			for (j=0; j<lengthOf(RPx); j++)
				setPixel(RPx[j]-Rx, RPy[j]-Ry, 255);
			selectWindow("Contained Points");
			run("BinaryThin2 ", "kernel_a='0 2 2 0 1 1 0 0 2 ' kernel_b='0 0 2 0 1 1 0 2 2 ' rotations='rotate 45' iterations=-1 white");
			for (j=0; j<lengthOf(RPx); j++){
				if((getPixel(RPx[j]-Rx, RPy[j]-Ry))==255) {
					centroidX = RPx[j]; centroidY = RPy[j];
					setResult("mc_X\(px\)", i, centroidX + 0.5); /* Add 0.5 pixel to correct pixel coordinates to center of pixel */
					setResult("mc_Y\(px\)", i, centroidY + 0.5);
					setResult("mc_offsetX\(px\)", i, getResult("X",i)/lcf-(centroidX + 0.5));
					setResult("mc_offsetY\(px\)", i, getResult("Y",i)/lcf-(centroidY + 0.5));
					j = lengthOf(RPx); /* one point and done */
				}
			}
			closeImageByTitle("Contained Points");
			if(addRadii) {
				/* Now measure min and max radii from M-Centroid */
				rMin = Rwidth + Rheight; rMax = 0;
				for (j=0 ; j<(lengthOf(xPoints)); j++) {
					dist = sqrt(pow(centroidX-xPoints[j],2)+pow(centroidY-yPoints[j],2));
					if (dist < rMin) { rMin = dist; rMinX = xPoints[j]; rMinY = yPoints[j];}
					if (dist > rMax) { rMax = dist; rMaxX = xPoints[j]; rMaxY = yPoints[j];}
				}
				if (rMin == 0) rMin = 0.5; /* Correct for 1 pixel width objects and interpolate error */
				setResult("mc_minRadX", i, rMinX + 0.5); /* Add 0.5 pixel to correct pixel coordinates to center of pixel */
				setResult("mc_minRadY", i, rMinY + 0.5);
				setResult("mc_maxRadX", i, rMaxX + 0.5);
				setResult("mc_maxRadY", i, rMaxY + 0.5);
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
		call("java.lang.System.gc");
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
	function binaryCheck(windowTitle) { /* For black objects on a white background */
		/* v180104 added line to remove inverting LUT and changed to auto default threshold
		v180602 Added dialog option to opt out of inverting image */
		selectWindow(windowTitle);
		if (is("binary")==0) run("8-bit");
		/* Quick-n-dirty threshold if not previously thresholded */
		getThreshold(t1,t2);
		if (t1==-1)  {
			run("8-bit");
			run("Auto Threshold", "method=Default");
			run("Convert to Mask");
			}
		/* Make sure black objects on white background for consistency */
		if (((getPixel(0, 0))==0 || (getPixel(0, 1))==0 || (getPixel(1, 0))==0 || (getPixel(1, 1))==0)) {
			inversion = getBoolean("The background appears to have intensity zero, do you want the intensities inverted?", "Yes Please", "No Thanks");
			if (inversion==true) run("Invert");
		}
		/*	Sometimes the outline procedure will leave a pixel border around the outside - this next step checks for this.
			i.e. the corner 4 pixels should now be all black, if not, we have a "border issue". */
		if (((getPixel(0, 0))+(getPixel(0, 1))+(getPixel(1, 0))+(getPixel(1, 1))) != 4*(getPixel(0, 0)) )
				restoreExit("Border Issue");
		if(is("Inverting LUT")) run("Invert LUT");
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
		/* v161109 adds the return of the updated ROI count and also adds dialog if there are already entries just in case . .
			v180104 only asks about ROIs if there is a mismatch with the results */
		nROIs = roiManager("count");
		nRES = nResults; /* Used to check for ROIs:Results mismatch */
		if(nROIs==0) runAnalyze = true; /* Assumes that ROIs are required and that is why this function is being called */
		else if(nROIs!=nRES) runAnalyze = getBoolean("There are " + nRES + " results and " + nROIs + " ROIs; do you want to clear the ROI manager and reanalyze?");
		else runAnalyze = false;
		if (runAnalyze) {
			roiManager("reset");
			Dialog.create("Analysis check");
			Dialog.addCheckbox("Run Analyze-particles to generate new roiManager values?", true);
			Dialog.addMessage("This macro requires that all objects have been loaded into the ROI manager.\n \nThere are   " + nRES +"   results.\nThere are   " + nROIs +"   ROIs.");
			Dialog.show();
			analyzeNow = Dialog.getCheckbox();
			if (analyzeNow) {
				setOption("BlackBackground", false);
				if (nResults==0)
					run("Analyze Particles...", "display add");
				else run("Analyze Particles..."); /* Let user select settings */
				if (nResults!=roiManager("count"))
					restoreExit("Results and ROI Manager counts do not match!");
			}
			else restoreExit("Goodbye, your previous setting will be restored.");
		}
		return roiManager("count"); /* Returns the new count of entries */
	}
	function cleanLabel(string) {
		/* v161104 */
		string= replace(string, "\\^2", fromCharCode(178)); /* superscript 2 */
		string= replace(string, "\\^3", fromCharCode(179)); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, "\\^-1", fromCharCode(0x207B) + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-2", fromCharCode(0x207B) + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "\\^-^1", fromCharCode(0x207B) + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-^2", fromCharCode(0x207B) + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "(?<![A-Za-z0-9])u(?=m)", fromCharCode(181)); /* micron units */
		string= replace(string, "\\b[aA]ngstrom\\b", fromCharCode(197)); /* Ångström unit symbol */
		string= replace(string, "  ", " "); /* Replace double spaces with single spaces */
		string= replace(string, "_", fromCharCode(0x2009)); /* Replace underlines with thin spaces */
		string= replace(string, "px", "pixels"); /* Expand pixel abbreviation */
		string = replace(string, " " + fromCharCode(0x00B0), fromCharCode(0x00B0)); /* Remove space before degree symbol */
		string= replace(string, " °", fromCharCode(0x2009)+"°"); /* Remove space before degree symbol */
		return string;
	}
	function closeImageByTitle(windowTitle) {  /* Cannot be used with tables */
        if (isOpen(windowTitle)) {
		selectWindow(windowTitle);
        close();
		}
	}
	function createInnerShadowFromMask() {
		/* Requires previous run of: imageDepth = bitDepth();
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
		if (imageDepth==16 || imageDepth==32) run(imageDepth + "-bit");
		run("Enhance Contrast...", "saturated=0 normalize");
		run("Invert");  /* Create an image that can be subtracted - this works better for color than Min */
		divider = (100 / abs(innerShadowDarkness));
		run("Divide...", "value=[divider]");
	}
	function createShadowDropFromMask() {
		/* Requires previous run of: imageDepth = bitDepth();
		because this version works with different bitDepths
		v161104 */
		showStatus("Creating drop shadow for labels . . . ");
		newImage("shadow", "8-bit black", imageWidth, imageHeight, 1);
		getSelectionFromMask("label_mask");
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX+shadowDisp, selMaskY+shadowDrop);
		setBackgroundColor(255,255,255);
		if (outlineStroke>0) run("Enlarge...", "enlarge=[outlineStroke] pixel"); /* Adjust shadow size so that shadow extends beyond stroke thickness */
		run("Clear", "slice");
		run("Select None");
		if (shadowBlur>0) {
			run("Gaussian Blur...", "sigma=[shadowBlur]");
			// run("Unsharp Mask...", "radius=[shadowBlur] mask=0.4"); /* Make Gaussian shadow edge a little less fuzzy */
		}
		/* Now make sure shadow or glow does not impact outline */
		getSelectionFromMask("label_mask");
		if (outlineStroke>0) run("Enlarge...", "enlarge=[outlineStroke] pixel");
		setBackgroundColor(0,0,0);
		run("Clear", "slice");
		run("Select None");
		/* The following are needed for different bit depths */
		if (imageDepth==16 || imageDepth==32) run(imageDepth + "-bit");
		run("Enhance Contrast...", "saturated=0 normalize");
		divider = (100 / abs(shadowDarkness));
		run("Divide...", "value=[divider]");
	}
	/* ASC Color Functions */
	function getColorArrayFromColorName(colorName) {
		/* v180828 added Fluorescent Colors
		   v181017-8 added off-white and off-black for use in gif transparency and also added safe exit if no color match found
		   v191211 added Cyan
		   v211022 all names lower-case, all spaces to underscores v220225 Added more hash value comments as a reference v220706 restores missing magenta
		   REQUIRES restoreExit function.  56 Colors
		*/
		if (colorName == "white") cA = newArray(255,255,255);
		else if (colorName == "black") cA = newArray(0,0,0);
		else if (colorName == "off-white") cA = newArray(245,245,245);
		else if (colorName == "off-black") cA = newArray(10,10,10);
		else if (colorName == "light_gray") cA = newArray(200,200,200);
		else if (colorName == "gray") cA = newArray(127,127,127);
		else if (colorName == "dark_gray") cA = newArray(51,51,51);
		else if (colorName == "off-black") cA = newArray(10,10,10);
		else if (colorName == "light_gray") cA = newArray(200,200,200);
		else if (colorName == "gray") cA = newArray(127,127,127);
		else if (colorName == "dark_gray") cA = newArray(51,51,51);
		else if (colorName == "red") cA = newArray(255,0,0);
		else if (colorName == "pink") cA = newArray(255, 192, 203);
		else if (colorName == "green") cA = newArray(0,255,0); /* #00FF00 AKA Lime green */
		else if (colorName == "blue") cA = newArray(0,0,255);
		else if (colorName == "magenta") cA = newArray(255,0,255); /* #FF00FF */
		else if (colorName == "yellow") cA = newArray(255,255,0);
		else if (colorName == "orange") cA = newArray(255, 165, 0);
		else if (colorName == "cyan") cA = newArray(0, 255, 255);
		else if (colorName == "garnet") cA = newArray(120,47,64);
		else if (colorName == "gold") cA = newArray(206,184,136);
		else if (colorName == "aqua_modern") cA = newArray(75,172,198); /* #4bacc6 AKA "Viking" aqua */
		else if (colorName == "blue_accent_modern") cA = newArray(79,129,189); /* #4f81bd */
		else if (colorName == "blue_dark_modern") cA = newArray(31,73,125); /* #1F497D */
		else if (colorName == "blue_modern") cA = newArray(58,93,174); /* #3a5dae */
		else if (colorName == "blue_honolulu") cA = newArray(0,118,182); /* Honolulu Blue #30076B6 */
		else if (colorName == "gray_modern") cA = newArray(83,86,90); /* bright gray #53565A */
		else if (colorName == "green_dark_modern") cA = newArray(121,133,65); /* Wasabi #798541 */
		else if (colorName == "green_modern") cA = newArray(155,187,89); /* #9bbb59 AKA "Chelsea Cucumber" */
		else if (colorName == "green_modern_accent") cA = newArray(214,228,187); /* #D6E4BB AKA "Gin" */
		else if (colorName == "green_spring_accent") cA = newArray(0,255,102); /* #00FF66 AKA "Spring Green" */
		else if (colorName == "orange_modern") cA = newArray(247,150,70); /* #f79646 tan hide, light orange */
		else if (colorName == "pink_modern") cA = newArray(255,105,180); /* hot pink #ff69b4 */
		else if (colorName == "purple_modern") cA = newArray(128,100,162); /* blue-magenta, purple paradise #8064A2 */
		else if (colorName == "jazzberry_jam") cA = newArray(165,11,94);
		else if (colorName == "red_n_modern") cA = newArray(227,24,55);
		else if (colorName == "red_modern") cA = newArray(192,80,77);
		else if (colorName == "tan_modern") cA = newArray(238,236,225);
		else if (colorName == "violet_modern") cA = newArray(76,65,132);
		else if (colorName == "yellow_modern") cA = newArray(247,238,69);
		/* Fluorescent Colors https://www.w3schools.com/colors/colors_crayola.asp */
		else if (colorName == "radical_red") cA = newArray(255,53,94);			/* #FF355E */
		else if (colorName == "wild_watermelon") cA = newArray(253,91,120);		/* #FD5B78 */
		else if (colorName == "outrageous_orange") cA = newArray(255,96,55);	/* #FF6037 */
		else if (colorName == "supernova_orange") cA = newArray(255,191,63);	/* FFBF3F Supernova Neon Orange*/
		else if (colorName == "atomic_tangerine") cA = newArray(255,153,102);	/* #FF9966 */
		else if (colorName == "neon_carrot") cA = newArray(255,153,51);			/* #FF9933 */
		else if (colorName == "sunglow") cA = newArray(255,204,51); 			/* #FFCC33 */
		else if (colorName == "laser_lemon") cA = newArray(255,255,102); 		/* #FFFF66 "Unmellow Yellow" */
		else if (colorName == "electric_lime") cA = newArray(204,255,0); 		/* #CCFF00 */
		else if (colorName == "screamin'_green") cA = newArray(102,255,102); 	/* #66FF66 */
		else if (colorName == "magic_mint") cA = newArray(170,240,209); 		/* #AAF0D1 */
		else if (colorName == "blizzard_blue") cA = newArray(80,191,230); 		/* #50BFE6 Malibu */
		else if (colorName == "dodger_blue") cA = newArray(9,159,255);			/* #099FFF Dodger Neon Blue */
		else if (colorName == "shocking_pink") cA = newArray(255,110,255);		/* #FF6EFF Ultra Pink */
		else if (colorName == "razzle_dazzle_rose") cA = newArray(238,52,210); 	/* #EE34D2 */
		else if (colorName == "hot_magenta") cA = newArray(255,0,204);			/* #FF00CC AKA Purple Pizzazz */
		else restoreExit("No color match to " + colorName);
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
	  /* This version by Tiago Ferreira 6/6/2022 eliminates the toString macro function */
	  if (lengthOf(n)==1) n= "0"+n; return n;
	  if (lengthOf(""+n)==1) n= "0"+n; return n;
	}
	function getHexColorFromRGBArray(colorNameString) {
		colorArray = getColorArrayFromColorName(colorNameString);
		 r = toHex(colorArray[0]); g = toHex(colorArray[1]); b = toHex(colorArray[2]);
		 hexName= "#" + ""+pad(r) + ""+pad(g) + ""+pad(b);
		 return hexName;
	}
	function getFontChoiceList() {
		/* v180723 first version */
		systemFonts = getFontList();
		IJFonts = newArray("SansSerif", "Serif", "Monospaced");
		fontNameChoice = Array.concat(IJFonts,systemFonts);
		faveFontList = newArray("Your favorite fonts here", "SansSerif", "Arial Black", "Open Sans ExtraBold", "Calibri", "Roboto", "Roboto Bk", "Tahoma", "Times New Roman", "Helvetica");
		faveFontListCheck = newArray(faveFontList.length);
		counter = 0;
		for (i=0; i<faveFontList.length; i++) {
			for (j=0; j<fontNameChoice.length; j++) {
				if (faveFontList[i] == fontNameChoice[j]) {
					faveFontListCheck[counter] = faveFontList[i];
					counter +=1;
					j = fontNameChoice.length;
				}
			}
		}
		faveFontListCheck = Array.trim(faveFontListCheck, counter);
		fontNameChoice = Array.concat(faveFontListCheck,fontNameChoice);
		return fontNameChoice;
	}
	function getSelectionFromMask(selection_Mask){
		batchMode = is("Batch Mode"); /* Store batch status mode before toggling */
		if (!batchMode) setBatchMode(true); /* Toggle batch mode on if previously off */
		tempTitle = getTitle();
		selectWindow(selection_Mask);
		run("Create Selection"); /* Selection inverted perhaps because the mask has an inverted LUT? */
		run("Make Inverse");
		selectWindow(tempTitle);
		run("Restore Selection");
		if (!batchMode) setBatchMode("exit");
	}
	function restoreExit(message){ /* Make a clean exit from a macro, restoring previous settings */
		/* 9/9/2017 added Garbage clean up suggested by Luc LaLonde - LBNL */
		restoreSettings(); /* Restore previous settings before exiting */
		setBatchMode("exit & display"); /* Probably not necessary if exiting gracefully but otherwise harmless */
		call("java.lang.System.gc");
		exit(message);
	}
	function unCleanLabel(string) {
	/* v161104 This function replaces special characters with standard characters for file system compatible filenames.
	+ 041117b to remove spaces as well.
	+ v220126 added getInfo("micrometer.abbreviation").
	+ v220128 add loops that allow removal of multiple duplication.
	+ v220131 fixed so that suffix cleanup works even if extensions are included.
	*/
		/* Remove bad characters */
		string= replace(string, fromCharCode(178), "\\^2"); /* superscript 2 */
		string= replace(string, fromCharCode(179), "\\^3"); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, fromCharCode(0xFE63) + fromCharCode(185), "\\^-1"); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
		string= replace(string, fromCharCode(0xFE63) + fromCharCode(178), "\\^-2"); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
		string= replace(string, fromCharCode(181), "u"); /* micron units */
		string= replace(string, getInfo("micrometer.abbreviation"), "um"); /* micron units */
		string= replace(string, fromCharCode(197), "Angstrom"); /* Ångström unit symbol */
		string= replace(string, fromCharCode(0x2009) + fromCharCode(0x00B0), "deg"); /* replace thin spaces degrees combination */
		string= replace(string, fromCharCode(0x2009), "_"); /* Replace thin spaces  */
		string= replace(string, "%", "pc"); /* % causes issues with html listing */
		string= replace(string, " ", "_"); /* Replace spaces - these can be a problem with image combination */
		/* Remove duplicate strings */
		unwantedDupes = newArray("8bit","lzw");
		for (i=0; i<lengthOf(unwantedDupes); i++){
			iLast = lastIndexOf(string,unwantedDupes[i]);
			iFirst = indexOf(string,unwantedDupes[i]);
			if (iFirst!=iLast) {
				string = substring(string,0,iFirst) + substring(string,iFirst + lengthOf(unwantedDupes[i]));
				i=-1; /* check again */
			}
		}
		unwantedDbls = newArray("_-","-_","__","--","\\+\\+");
		for (i=0; i<lengthOf(unwantedDbls); i++){
			iFirst = indexOf(string,unwantedDbls[i]);
			if (iFirst>=0) {
				string = substring(string,0,iFirst) + substring(string,iFirst + lengthOf(unwantedDbls[i])/2);
				i=-1; /* check again */
			}
		}
		string= replace(string, "_\\+", "\\+"); /* Clean up autofilenames */
		/* cleanup suffixes */
		unwantedSuffixes = newArray(" ","_","-","\\+"); /* things you don't wasn't to end a filename with */
		extStart = lastIndexOf(string,".");
		sL = lengthOf(string);
		if (sL-extStart<=4) extIncl = true;
		else extIncl = false;
		if (extIncl){
			preString = substring(string,0,extStart);
			extString = substring(string,extStart);
		}
		else {
			preString = string;
			extString = "";
		}
		for (i=0; i<lengthOf(unwantedSuffixes); i++){
			sL = lengthOf(preString);
			if (endsWith(preString,unwantedSuffixes[i])) {
				preString = substring(preString,0,sL-lengthOf(unwantedSuffixes[i])); /* cleanup previous suffix */
				i=-1; /* check one more time */
			}
		}
		if (!endsWith(preString,"_lzw") && !endsWith(preString,"_lzw.")) preString = replace(preString, "_lzw", ""); /* Only want to keep this if it is at the end */
		string = preString + extString;
		/* End of suffix cleanup */
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
		labelString = d2s(labelValue,decPlaces); /* Reduce decimal places for labeling (move these two lines to below the labels you prefer) */
		Roi.getBounds(roiX, roiY, roiWidth, roiHeight);
		lFontSize = fontSize; /* Initial estimate */
		setFont(font,lFontSize,fontStyle);
		lFontSize = fontSizeCorrection * fontSize * roiWidth/(getStringWidth(labelString)); /* Adjust label font size so that the label fits within object width */
		if (lFontSize>fontSizeCorrection*roiHeight) lFontSize = fontSizeCorrection*roiHeight; /* Readjust the label font size so that the label fits within the object height */
		if (lFontSize>maxLFontSize) lFontSize = maxLFontSize;
		if (lFontSize<minLFontSize) lFontSize = minLFontSize;
		setFont(font,lFontSize,fontStyle);
		if (ctrChoice=="ROI Center")
			textOffset = roiX + ((roiWidth) - getStringWidth(labelString))/2;
		else textOffset = getResult("mc_X\(px\)",i) - getStringWidth(labelString)/2;
		setColorFromColorName("white");
		if (ctrChoice=="ROI Center")
			drawString(labelString, textOffset, roiY+roiHeight/2 + lFontSize/2);
		else drawString(labelString, textOffset, round(getResult("mc_Y\(px\)",i) + lFontSize/2));
	}
}