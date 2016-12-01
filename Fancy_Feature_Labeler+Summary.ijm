/* Inspired by ROI_Color_Coder.ijm
	IJ BAR: https://github.com/tferr/Scripts#scripts
	http://imagejdocu.tudor.lu/doku.php?id=macro:roi_color_coder
	Tiago Ferreira, v.5.2 2015.08.13 -	v.5.3 2016.05.1 + pjl mods 6/16-30/2016 to automate defaults and add labels to ROIs

	This macro adds scaled result labels to each ROI object as well as a summary.
	This version: 10/13/2016
 */
macro "Add scaled value labels to each ROI object and add summary"{
	// assess required conditions before proceeding
	requires("1.47r");
	saveSettings;
	// Some cleanup
	run("Select None");

	/* Set options for black objects on white background as this works better for publications */
	run("Options...", "iterations=1 white count=1"); /* set white background */
	run("Colors...", "foreground=black background=white selection=yellow"); /* set colors */
	setOption("BlackBackground", false);
	run("Appearance...", " "); /* do not use Inverting LUT */
	// The above should be the defaults but this makes sure (black particles on a white background)
	// http://imagejdocu.tudor.lu/doku.php?id=faq:technical:how_do_i_set_up_imagej_to_deal_with_white_particles_on_a_black_background_by_default

	t=getTitle();
	// Checks to see if a Ramp legend rather than the image has been selected by accident
	if (matches(t, ".*Ramp.*")==1) showMessageWithCancel("Title contains \"Ramp\"", "Do you want to label" + t + " ?"); 

	checkForRoiManager(); // macro requires that the objects are in the ROI manager
		
	setBatchMode(true);
	nROIs= roiManager("count");
	nRES= nResults;
	// get id of image and number of ROIs

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

	id = getImageID();
	roiManager("Show All without labels");
	imageHeight = getHeight();
	imageWidth = getWidth();
	imageDims = imageHeight + imageWidth;
	getPixelSize(unit, pixelWidth, pixelHeight);
	fontS = round(imageDims/160);
	outlineStroke = 8; /* default outline stroke: % of font size */
	shadowDrop = 12;  /* default outer shadow drop: % of font size */
	dIShO = 5; /* default inner shadow drop: % of font size */
	offsetX = round(1 + imageWidth/150); /* default offset of label from edge */
	offsetY = round(1 + imageHeight/150); /* default offset of label from edge */
	selColor = "white";
	outlineColor = "black"; 	
	originalImageDepth = bitDepth();
	paraLabfontS = round(imageDims/50);
	statsLabfontS = round(imageDims/60);

	headings = split(String.getResultsHeadings);
	headingsWithRange= newArray(headings.length);
	for (i=0; i<headings.length; i++) {
		resultsColumn = newArray(items);
		for (j=0; j<items; j++)
			resultsColumn[j] = getResult(headings[i], j);
		Array.getStatistics(resultsColumn, min, max, null, null); 
		headingsWithRange[i] = headings[i] + ":  " + min + " - " + max;
	}
	// create the dialog prompt
	Dialog.create("Feature Label Options: "+ getTitle);
		Dialog.addChoice("Measurement", headingsWithRange, headingsWithRange[0]);
		Dialog.addString("Label:", unit+"^2", 4);
		Dialog.setInsets(-40, 320, 0);
		Dialog.addMessage("^2 & um etc. replaced by " + fromCharCode(178) + " & " + fromCharCode(181) + "m...\n If units are part of the parameter\n label, within \(...\) i.e. \(unit\) they will \noverride this selection:");
		// Dialog.addMessage("^2 and um etc. replaced by " + fromCharCode(178) + " and " + fromCharCode(181) + "m etc.");
		Dialog.addChoice("Decimal Places:", newArray("Auto", "Manual", "Scientific"), "Auto");
		fontStyleChoice = newArray("bold", "bold antialiased", "italic", "italic antialiased", "bold italic", "bold italic antialiased", "unstyled");
		Dialog.addChoice("Font style:", fontStyleChoice, fontStyleChoice[1]);
		fontNameChoice = newArray("SansSerif", "Serif", "Monospaced");
		Dialog.addChoice("Font name:", fontNameChoice, fontNameChoice[0]);
		Dialog.addNumber("Font_size:", fontS, 0, 3, "pt \(ROI manager\)");
		if (originalImageDepth==24)
			colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray", "red", "pink", "green", "blue", "yellow", "orange", "garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "gray_modern", "green_dark_modern", "green_modern", "orange_modern", "pink_modern", "purple_modern", "red_N_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern"); 
		else colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray");
		Dialog.addChoice("Object label color:", colorChoice, colorChoice[0]);
		Dialog.addNumber("Font scaling % of Auto", 66);
		Dialog.addNumber("Minimum Label Font Size", round(imageDims/90));
		Dialog.addNumber("Maximum Label Font Size", round(imageDims/16));

		fontStyleChoice = newArray("bold", "bold antialiased", "italic", "bold italic", "unstyled");
		Dialog.addChoice("Font style:", fontStyleChoice, fontStyleChoice[1]);
		fontNameChoice = newArray("SansSerif", "Serif", "Monospaced");
		Dialog.addChoice("Font name:", fontNameChoice, fontNameChoice[0]);

		Dialog.addNumber("Outline Stroke:", outlineStroke,0,3,"% of font size");
		Dialog.addChoice("Outline (background) color:", colorChoice, colorChoice[1]);
		Dialog.addNumber("Shadow Drop: �", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Displacement Right: �", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Gaussian Blur:", floor(0.75 * shadowDrop),0,3,"% of font size");
		Dialog.addNumber("Shadow Darkness \(darkest = 100%\):", 60,0,3,"%");
		Dialog.addChoice("Shadow color \(overrides darkness in overlay\):", colorChoice, colorChoice[4]);
		Dialog.addMessage("The following \"Inner Shadow\" options do not change the Overlay scale bar");
		Dialog.addNumber("Inner Shadow Drop: �", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner Displacement Right: �", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner Shadow Mean Blur:",floor(dIShO/2),1,2,"pixels");
		Dialog.addNumber("Inner Shadow Darkness \(darkest = 100%\):", 20,0,3,"%");
		if (isNaN(getResult("mc_X\(px\)",0))) {
			Dialog.addRadioButtonGroup("Object Labels At:_____________________ ", newArray("ROI Center", "Morphological Center"), 1, 2, "ROI Center");
			Dialog.setInsets(-5, 50, 7);
			Dialog.addMessage("If selected, Morphological Centers will be added to the Results table.");
		}
		else Dialog.addRadioButtonGroup("Object Label At:", newArray("ROI Center", "Morphological Center"), 1, 2, "Morphological Center");

		Dialog.addRadioButtonGroup("Add statistical summary?", newArray("No", "Yes", "Parameter Label Only"), 1, 2, "Yes"); 
			
	Dialog.show;

		parameterWithLabel= Dialog.getChoice;
		parameter= substring(parameterWithLabel, 0, indexOf(parameterWithLabel, ":  "));
		unitLabel = Dialog.getString;
		dpChoice = Dialog.getChoice;
		fontStyle = Dialog.getChoice;
			if (fontStyle=="unstyled") fontStyle="";
		fontName = Dialog.getChoice;
		fontS = Dialog.getNumber;
		/* Then Dialog . . . */
		selColor = Dialog.getChoice();
		fontSCorrection =  Dialog.getNumber()/100;
		minLFontS = Dialog.getNumber(); 
		maxLFontS = Dialog.getNumber(); 
		fontStyle = Dialog.getChoice();

		fontName = Dialog.getChoice();
		outlineStroke = Dialog.getNumber();
		outlineColor = Dialog.getChoice();
		shadowDrop = Dialog.getNumber();
		shadowDisp = Dialog.getNumber();
		shadowBlur = Dialog.getNumber();
		shadowDarkness = Dialog.getNumber();
		shadowColor = Dialog.getChoice();
		innerShadowDrop = Dialog.getNumber();
		innerShadowDisp = Dialog.getNumber();
		innerShadowBlur = Dialog.getNumber();
		innerShadowDarkness = Dialog.getNumber();
		ctrChoice = Dialog.getRadioButton();
		summaryChoice = Dialog.getRadioButton();

		if (summaryChoice=="Yes") statsChoiceLines = 7;
		else statsChoiceLines = 0;
		if (isNaN(getResult("mc_X\(px\)",0)) && ctrChoice=="Morphological Center") 
			AddMCsToResultsTable ();

	// get values for chosen parameter
	values= newArray(items);
	for (i=0; i<items; i++)
		values[i]= getResult(parameter,i);
	Array.getStatistics(values, arrayMin, arrayMax, arrayMean, arraySD); 
	if (isNaN(min)) min= arrayMin;
	if (isNaN(max)) max= arrayMax;
	coeffVar = arraySD*100/arrayMean;
	sortedValues = Array.copy(values);
	sortedValues = Array.sort(sortedValues);
	arrayMedian = sortedValues[round(items/2)];

	if ((lastIndexOf(t,"."))>0) imageNameWOExt = unCleanLabel(substring(t, 0, lastIndexOf(t,".")));
	else imageNameWOExt = unCleanLabel(t);
	// parse symbols in unit and draw final unitLabel below ramp
	unitLabel= cleanLabel(unitLabel);
	parameterLabel= cleanLabel(parameter);
	parameterLabel = replace(parameterLabel, "px", "pixels"); // expand "px" used to keep Results columns narrower
		if (endsWith(parameterLabel,"\)")) { // label with units from parameter string if available
		unitIndexStart = lastIndexOf(parameterLabel, "\(");
		unitIndexEnd = lastIndexOf(parameterLabel, "\)");
		parameterUnit = substring(parameterLabel, unitIndexStart+1, unitIndexEnd);
		unitCheck = matches(parameterUnit, ".*[0-9].*");
		if (unitCheck==0) {  //if it contains a number it probably isn't a unit
			parameterLabel = substring(parameterLabel,0,unitIndexStart);
			unitLabel = parameterUnit;
		}
	}
	parameterLabel = replace(parameterLabel, "_", fromCharCode(0x2009)); // replace underlines with thin spaces
	// iterate through the ROI Manager list and draw scaled label
	selectImage(id);
	countNaN= 0;
	roiManager("Show All without labels");
	// Now to add scaled object labels
	selectWindow(t);
	shadowDarkness = (255/100) * (abs(shadowDarkness));
	innerShadowDarkness = (255/100) * (100 - (abs(innerShadowDarkness)));
	decPlaces = -1;	//defaults to scientific notation
	if (dpChoice=="Auto")
		decPlaces = autoCalculateDecPlacesFromValueOnly(decPlaces);
	if (dpChoice=="Manual") 
		decPlaces=getNumber("Choose Number of Decimal Places", 0);

	if (fontStyle=="unstyled") fontStyle="";
	if (summaryChoice!="No") {
		if (summaryChoice=="Yes") {
		Dialog.create("Summary Label Options: "+ getTitle);
			paraLocChoice = newArray("Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right", "Center of New Selection"); 
			Dialog.addChoice("Location of Summary Label:", paraLocChoice, paraLocChoice[0]);
			Dialog.addChoice("Parameter Label Too?", newArray("Yes", "No"), "Yes");
			Dialog.addNumber("Parameter Label Font size:", paraLabfontS);			
			statsChoice = newArray("None", "Dashed line:  ---", "Number of objects", "Mean", "Median", "StdDev", "CoeffVar", "Minimum", "Maximum", "Min-Max", "Long dashed underline:  ___","Blank line");
			for (i=0; i<statsChoiceLines; i++)
					Dialog.addChoice("Statistics Label Line "+(i+1)+":", statsChoice, statsChoice[i+2]);
			Dialog.addNumber("Statistics Label Font size:", statsLabfontS);
			if (originalImageDepth==24)
				colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray", "red", "pink", "green", "blue", "yellow", "orange", "garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "gray_modern", "green_dark_modern", "green_modern", "orange_modern", "pink_modern", "purple_modern", "red_N_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern"); 
			else colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray");
			Dialog.addChoice("Summary and Parameter Font Color:", colorChoice, selColor);
			Dialog.addChoice("Summary and Parameter Outline Color:", colorChoice, outlineColor);	

		Dialog.show;
			paraLabPos = Dialog.getChoice();
			paraLabChoice = Dialog.getChoice();
			paraLabfontS = Dialog.getNumber();
			statsLabLine = newArray(statsChoiceLines);
			for (i=0; i<statsChoiceLines; i++)
				statsLabLine[i] = Dialog.getChoice();
			statsLabfontS = Dialog.getNumber();
			summaryFontColor = Dialog.getChoice();
			summaryOutlineColor = Dialog.getChoice();
		}
		if (summaryChoice=="Parameter Label Only") {
			paraLabChoice = "Yes";
			statsLines = 0;
			Dialog.create("Parameter Label Options: "+ getTitle);
				paraLocChoice = newArray("Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right", "Center of New Selection"); 
				Dialog.addChoice("Location of Summary Label:", paraLocChoice, paraLocChoice[0]);
				Dialog.addNumber("Parameter Label Font size:", paraLabfontS);	
				Dialog.addChoice("Parameter Font Color:", colorChoice, selColor);
				Dialog.addChoice("Parameter Outline Color:", colorChoice, outlineColor);				
						
			Dialog.show;
				paraLabPos = Dialog.getChoice();
				paraLabfontS = Dialog.getNumber();
				statsLabLine = newArray(statsChoiceLines);
				summaryFontColor = Dialog.getChoice();
				summaryOutlineColor = Dialog.getChoice();
		}
		if (summaryChoice!="Parameter Label Only") {
			// Count lines of summary label
			if (paraLabChoice=="Yes") labLines = 1;
			else labLines = 0;
			statsLines = 0;
			// Reduce decimal places - but not as much as ramp labels
			arrayMean = d2s(arrayMean,decPlaces+2);
			coeffVar = d2s((100/arrayMean)*arraySD,decPlaces+2);
			arraySD = d2s(arraySD,decPlaces+2);
			arrayMin = d2s(arrayMin,decPlaces+2);
			arrayMax = d2s(arrayMax,decPlaces+2);
			statsLabLineText = newArray(statsChoiceLines);
			setFont(fontName, statsLabfontS, fontStyle);

			longestStringWidth = 0;
			for (i=0; i<statsChoiceLines; i++) {
				// if (statsLabLine[i]!="None") statsLines = statsLines + 1;
				if (statsLabLine[i]!="None") {
					statsLines = i + 1;
					if (statsLabLine[i]=="Dashed line:  ---") statsLabLineText[i] = "----------";
					else if (statsLabLine[i]=="Number of objects") statsLabLineText[i] = "Objects = " + items;
					else if (statsLabLine[i]=="Mean") statsLabLineText[i] = "Mean = " + arrayMean + " " + unitLabel;
					else if (statsLabLine[i]=="Median") {
						sortedValues = Array.copy(values);
						sortedValues = Array.sort(sortedValues);
						median = d2s((sortedValues[round(items/2)]),decPlaces+2);
						statsLabLineText[i] = "Median = " + median + " " + unitLabel;
					}
					else if (statsLabLine[i]=="StdDev") statsLabLineText[i] = "Std.Dev. = " + arraySD + " " + unitLabel;
					else if (statsLabLine[i]=="CoeffVar") statsLabLineText[i] = "Coeff.Var. = " + coeffVar + "%";
					else if (statsLabLine[i]=="Min-Max") statsLabLineText[i] = "Range = " + arrayMin + " - " + arrayMax + " " + unitLabel;
					else if (statsLabLine[i]=="Minimum") statsLabLineText[i] = "Minimum = " + arrayMin + " " + unitLabel;
					else if (statsLabLine[i]=="Maximum") statsLabLineText[i] = "Maximum = " + arrayMax + " " + unitLabel;
					else if (statsLabLine[i]=="Long dashed underline:  ___") statsLabLineText[i] = "__________";
					else if (statsLabLine[i]=="Blank line") statsLabLineText[i] = " ";
					lineLength = getStringWidth(statsLabLineText[i]);
					if (lineLength>longestStringWidth) longestStringWidth = lineLength;
				}
			}
			linesSpace = 1.2 * ((labLines*paraLabfontS)+(statsLines*statsLabfontS));
		}			
		if (paraLabChoice=="Yes") {		
			//recombine units and labels that were used in Ramp
			if (unitLabel!="") paraLabel = parameterLabel + ", " + unitLabel;
			else paraLabel = parameterLabel;
			if (paraLabChoice=="Yes") {
				setFont(fontName,paraLabfontS, fontStyle);
				if (summaryChoice!="Parameter Label Only") {
					if (getStringWidth(paraLabel)>longestStringWidth) longestStringWidth = getStringWidth(paraLabel);
				}
			}
			if (paraLabPos == "Top Left") {
				selEX = offsetX;
				selEY = offsetY;
			} else if (paraLabPos == "Top Right") {
				selEX = imageWidth - longestStringWidth - offsetX;
				selEY = offsetY;
			} else if (paraLabPos == "Center") {
				selEX = round((imageWidth - longestStringWidth)/2);
				selEY = round((imageHeight - linesSpace)/2);
			} else if (paraLabPos == "Bottom Left") {
				selEX = offsetX;
				selEY = imageHeight - offsetY + linesSpace; 
			} else if (paraLabPos == "Bottom Right") {
				selEX = imageWidth - longestStringWidth - offsetX;
				selEY = imageHeight - offsetY + linesSpace;

			} else if (paraLabPos == "Center of New Selection"){
				setBatchMode("false"); // Does not accept interaction while batch mode is on
				setTool("rectangle");
				msgtitle="Location for the summary labels...";
				msg = "Draw a box in the image where you want to center the summary labels...";
				waitForUser(msgtitle, msg);
				getSelectionBounds(newSelEX, newSelEY, newSelEWidth, newSelEHeight);
				run("Select None");
				selEX = newSelEX + round((newSelEWidth - longestStringWidth)/2);
				selEY = newSelEY + round((newSelEHeight - linesSpace)/2);
				setBatchMode("true");	// toggle batch mode back on
			} if (selEY<=1.5*paraLabfontS)
				selEY += paraLabfontS;
			if (selEX<offsetX) selEX = offsetX;
			endX = selEX + longestStringWidth;
			if ((endX+offsetX)>imageWidth) selEX = imageWidth - longestStringWidth - offsetX;
			paraLabelX = selEX;
			paraLabelY = selEY;
		}
	}
	roiManager("show none");
	run("Flatten");
	flatImage = getTitle();
	if (is("Batch Mode")==false) setBatchMode(true);
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	// roiManager("show none");
	// iterate through the ROI Manager list and colorize ROIs and rename ROIs and draw scaled labels
	fontArray = newArray(items);
	for (i=0; i<items; i++) {
		showStatus("Creating labels for object " + i + ", " + (roiManager("count")-i) + " more to go");
		roiManager("Select", i);
		labelValue = values[i];
		if (dpChoice=="Auto")
			decPlaces = autoCalculateDecPlacesFromValueOnly(labelValue);
		labelString = d2s(labelValue,decPlaces); // Reduce Decimal places for labeling - move these two lines to below the labels you prefer
		Roi.getBounds(roiX, roiY, roiWidth, roiHeight);
		roiMin = roiWidth;
		lFontS = fontS; /* initial estimate */
		setFont(fontName,lFontS, fontStyle);
		lFontS = fontSCorrection * fontS * roiMin/(getStringWidth(labelString));
		if (lFontS>maxLFontS) lFontS = maxLFontS; 
		if (lFontS<minLFontS) lFontS = minLFontS;
		setFont(fontName,lFontS, fontStyle);
		if (ctrChoice=="ROI Center") 
			textOffset = roiX + ((roiWidth) - getStringWidth(labelString))/2;
		else textOffset = getResult("mc_X\(px\)",i) - getStringWidth(labelString)/2;
		setColorFromColorName("white");
		if (ctrChoice=="ROI Center")
			drawString(labelString, textOffset, roiY+roiHeight/2 + lFontS/2);
		else drawString(labelString, textOffset, getResult("mc_Y\(px\)",i) + lFontS/2);	
			fontArray[i] = lFontS; // to generate statistics for mean shadow drop
	}
		Array.getStatistics(fontArray, null, null, meanfontS, null);
		negAdj = 0.5;  /* negative offsets appear exaggerated at full displacement */
	if (shadowDrop<0) shadowDrop *= negAdj;
	if (shadowDisp<0) shadowDisp *= negAdj;
	if (shadowBlur<0) shadowBlur *= negAdj;
	if (innerShadowDrop<0) innerShadowDrop *= negAdj;
	if (innerShadowDisp<0) innerShadowDisp *= negAdj;
	if (innerShadowBlur<0) innerShadowBlur *= negAdj;
	fontPC = meanfontS/100;
	outlineStroke = round(fontPC * outlineStroke);
	shadowDrop = floor(fontPC * shadowDrop);
	shadowDisp = floor(fontPC * shadowDisp);
	shadowBlur = floor(fontPC * shadowBlur);
	innerShadowDrop = floor(fontPC * innerShadowDrop);
	innerShadowDisp = floor(fontPC * innerShadowDisp);
	innerShadowBlur = floor(fontPC * innerShadowBlur);
			
	setThreshold(0, 128);
	setOption("BlackBackground", false);
	run("Convert to Mask");
		// Create drop shadow if desired
	if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0) {
		createShadowDropFromMask();
	}
	// Create inner shadow if desired
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
	setBackgroundFromColorName(selColor);
	run("Clear");
	run("Select None");
	if (isOpen("inner_shadow"))
		imageCalculator("Subtract", flatImage,"inner_shadow");
		closeImageByTitle("shadow");
	closeImageByTitle("inner_shadow");
	closeImageByTitle("label_mask");

	// Draw summary over top of object labels
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	setColorFromColorName("white");
	if (summaryChoice!="No") {
		if (paraLabChoice=="Yes") {
			setFont(fontName,paraLabfontS, fontStyle);
			drawString(paraLabel, paraLabelX, paraLabelY);
			paraLabelY += round(1.2 * paraLabfontS);
		}
		setFont(fontName,statsLabfontS, fontStyle);
		for (i=0; i<statsLines; i++) {
			// if (statsLabLine[i]!="None") statsLines = statsLines + 1;
			if (statsLabLine[i]!="None") {
				drawString(statsLabLineText[i], paraLabelX, paraLabelY);
				paraLabelY += round(1.2 * statsLabfontS);			
			}
		}
	}
	setThreshold(0, 128);
	setOption("BlackBackground", false);
	run("Convert to Mask");

	// Create drop shadow if desired
	if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0) {
		createShadowDropFromMask();
	}
	// Create inner shadow if desired
	if (innerShadowDrop!=0 || innerShadowDisp!=0 || innerShadowBlur!=0) {
		createInnerShadowFromMask();
	}
	if (isOpen("shadow"))		
		imageCalculator("Subtract", flatImage,"shadow");
	run("Select None");
	getSelectionFromMask("label_mask");
	run("Enlarge...", "enlarge=[outlineStroke] pixel");
	setBackgroundFromColorName(summaryOutlineColor); // functionoutlineColor]")
	run("Clear");
	run("Select None");
	getSelectionFromMask("label_mask");
	setBackgroundFromColorName(summaryFontColor);
	run("Clear");
	run("Select None");
	if (isOpen("inner_shadow"))
		imageCalculator("Subtract", flatImage,"inner_shadow");
		
	closeImageByTitle("shadow");
	closeImageByTitle("inner_shadow");
	closeImageByTitle("label_mask");
		selectWindow(flatImage);
	if ((lastIndexOf(flatImage,"."))>0) labeledImageNameWOExt = substring(flatImage, 0, lastIndexOf(flatImage,"."));
	else labeledImageNameWOExt = flatImage;
	rename(unCleanLabel(labeledImageNameWOExt + "_" + parameter));
		if (countNaN!=0)
		print("\n>>>> ROI Color Coder:\n"
			+ "Some values from the \""+ parameter +"\" column could not be retrieved.\n"
			+ countNaN +" ROI(s) were labeled with a default color.");
		restoreSettings;
	setBatchMode("exit & display");
	showStatus("Labeling Macro Finished");

	/*   ( 8(|)  ( 8(|) Functions ( 8(|)  ( 8(|)   */

	function AddMCsToResultsTable () {
/* 	Based on "MCentroids.txt" Morphological centroids by thinning assumes white particles: G.Landini
	http://imagejdocu.tudor.lu/doku.php?id=plugin:morphology:morphological_operators_for_imagej:start
	http://www.mecourse.com/landinig/software/software.html
	Modified to add coordinates to Results Table: Peter J. Lee NHMFL  7/20-29/2016
	v161012
*/
	saveSettings();
	run("Options...", "iterations=1 white count=1"); /* set white background */
	setOption("BlackBackground", false);
	run("Colors...", "foreground=black background=white selection=yellow"); /* set colors */
	run("Appearance...", " "); /* do not use Inverting LUT */
	workingTitle = getTitle();
	if (checkForPlugin("morphology_collection")==0) restoreExit("Exiting: Gabriel Landini's morphology suite is needed to run this macro.");
	binaryCheck(workingTitle);
	checkForRoiManager();
	roiOriginalCount = roiManager("count");
	setBatchMode(true); //batch mode on
	start = getTime();
	getPixelSize(selectedUnit, pixelWidth, pixelHeight);
	lcf=(pixelWidth+pixelHeight)/2;
	objects = roiManager("count");
	mcImageWidth = getWidth();
	mcImageHeight = getHeight();
	showStatus("Looping through all " + roiOriginalCount + " objects for morphological centers . . .");
	for (i=0 ; i<roiOriginalCount; i++) {
		showProgress(-i, roiManager("count"));
		selectWindow(workingTitle);
		roiManager("select", i);
		Roi.getBounds(Rx, Ry, Rwidth, Rheight);
		setResult("ROIctr_X\(px\)", i, round(Rx + Rwidth/2));
		setResult("ROIctr_Y\(px\)", i, round(Ry + Rheight/2));
		Roi.getContainedPoints(RPx, RPy); // this includes holes when ROIs are used so no hole filling is needed
		newImage("Contained Points "+i,"8-bit black",Rwidth,Rheight,1); // give each sub-image a unique name for debugging purposes
		for (j=0; j<RPx.length; j++)
			setPixel(RPx[j]-Rx, RPy[j]-Ry, 255);
		selectWindow("Contained Points "+i);
		run("BinaryThin2 ", "kernel_a='0 2 2 0 1 1 0 0 2 ' kernel_b='0 0 2 0 1 1 0 2 2 ' rotations='rotate 45' iterations=-1 white");
		if (lcf==1) {
			for (RPx=1; RPx<(Rwidth-1); RPx++){
				for (RPy=1; RPy<(Rheight-1); RPy++){ // start at "1" because there should not be a pixel at the border
					if((getPixel(RPx, RPy))==255) {  
						setResult("mc_X\(px\)", i, RPx+Rx);
						setResult("mc_Y\(px\)", i, RPy+Ry);
						setResult("mc_offsetX\(px\)", i, getResult("X",i)-(RPx+Rx));
						setResult("mc_offsetY\(px\)", i, getResult("Y",i)-(RPy+Ry));
						RPy = Rheight;
						RPx = Rwidth; // one point and done
					}
				}
			}
		}
		else if (lcf!=1) {
			for (RPx=1; RPx<(Rwidth-1); RPx++){
				for (RPy=1; RPy<(Rheight-1); RPy++){ // start at "1" because there should not be a pixel at the border
					if((getPixel(RPx, RPy))==255) {
						setResult("mc_X\(px\)", i, RPx+Rx);
						setResult("mc_Y\(px\)", i, RPy+Ry);					
						// setResult("mc_X\(" + selectedUnit + "\)", i, (RPx+Rx)*lcf); //perhaps not too useful
						// setResult("mc_Y\(" + selectedUnit + "\)", i, (RPy+Ry)*lcf); //
						setResult("mc_offsetX\(px\)", i, round((getResult("X",i)/lcf-(RPx+Rx))));
						setResult("mc_offsetY\(px\)", i, round((getResult("Y",i)/lcf-(RPy+Ry))));
						RPy = Rheight;
						RPx = Rwidth; // one point and done
					}
				}
			}
		}
		closeImageByTitle("Contained Points "+i);
	}
	updateResults();
	run("Select None");
	setBatchMode("exit & display"); /* exit batch mode */
	restoreSettings();
	showStatus("MC macro Finished: " + roiManager("count") + " objects analyzed in " + (getTime()-start)/1000 + "s.");
	beep(); wait(300); beep(); wait(300); beep();
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
	function binaryCheck(windowTitle) { // for white objects on black background
		selectWindow(windowTitle);
		if (is("binary")==0) run("8-bit");
		// Quick-n-dirty threshold if not previously thresholded
		getThreshold(t1,t2); 
		if (t1==-1)  {
			run("8-bit");
			setThreshold(0, 128);
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Invert");
			}
		// Make sure black objects on white background for consistency	
		if (((getPixel(0, 0))==0 || (getPixel(0, 1))==0 || (getPixel(1, 0))==0 || (getPixel(1, 1))==0))
			run("Invert"); 
		// Sometimes the outline procedure will leave a pixel border around the outside - this next step checks for this.
		// i.e. the corner 4 pixels should now be all black, if not, we have a "border issue".
		if (((getPixel(0, 0))+(getPixel(0, 1))+(getPixel(1, 0))+(getPixel(1, 1))) != 4*(getPixel(0, 0)) ) 
				restoreExit("Border Issue"); 	
	}
	function checkForPlugin(pluginName) {
		var pluginCheck = 0, subFolderCount = 0;
		if (getDirectory("plugins") == "") restoreExit("Failure to find any plugins!");
		else pluginDir = getDirectory("plugins");
		if (!endsWith(pluginName, ".jar")) pluginName = pluginName + ".jar";
		if (File.exists(pluginDir + pluginName)) {
				pluginCheck = 1;
				showStatus(pluginName + "found in: "  + pluginDir);
		}
		else {
			pluginList = getFileList(pluginDir);
			subFolderList = newArray(pluginList.length);
			for (i=0; i<pluginList.length; i++) {
				if (endsWith(pluginList[i], "/")) {
					subFolderList[subFolderCount] = pluginList[i];
					subFolderCount = subFolderCount +1;
				}
			}
			subFolderList = Array.slice(subFolderList, 0, subFolderCount);
			for (i=0; i<subFolderList.length; i++) {
				if (File.exists(pluginDir + subFolderList[i] +  "\\" + pluginName)) {
					pluginCheck = 1;
					showStatus(pluginName + " found in: " + pluginDir + subFolderList[i]);
					i = subFolderList.length;
				}
			}
		}
		return pluginCheck;
	}
	function checkForRoiManager() {
		if (roiManager("count")==0)  {
			Dialog.create("No ROI");
			Dialog.addCheckbox("Run Analyze-particles to generate roiManager values?", true);
			Dialog.addMessage("This macro requires that all objects have been loaded into the roi manager.");
			Dialog.show();
			analyzeNow = Dialog.getCheckbox(); //if (analyzeNow==true) ImageJ analyze particles will be performed, otherwise exit;
			if (analyzeNow==true) {
				setOption("BlackBackground", false);
				run("Analyze Particles...", "display clear add");
			}
			else restoreExit();
		}
	}	
	function cleanLabel(string) {
		string= replace(string, "\\^2", fromCharCode(178)); // superscript 2 
		string= replace(string, "\\^3", fromCharCode(179)); // superscript 3 UTF-16 (decimal)
		string= replace(string, "\\^-1", fromCharCode(0x207B) + fromCharCode(185)); // superscript -1
		string= replace(string, "\\^-2", fromCharCode(0x207B) + fromCharCode(178)); // superscript -2
		string= replace(string, "\\^-^1", fromCharCode(0x207B) + fromCharCode(185)); // superscript -1
		string= replace(string, "\\^-^2", fromCharCode(0x207B) + fromCharCode(178)); // superscript -2
		string= replace(string, "(?<![A-Za-z0-9])u(?=m)", fromCharCode(181)); // micrometer units
		string= replace(string, "\\b[aA]ngstrom\\b", fromCharCode(197)); // angstrom symbol
		string= replace(string, "  ", " "); // double spaces
		string= replace(string, "_", fromCharCode(0x2009)); // replace underlines with thin spaces
		string= replace(string, "px", "pixels"); // expand pixel abbreviation
		return string;
	}	
	function closeImageByTitle(windowTitle) {  /* cannot be used with tables */
        if (isOpen(windowTitle)) {
		selectWindow(windowTitle);
        close();
		}
	}
	function createShadowDropFromMask() {
		showStatus("Creating drop shadow for labels . . . ");
		newImage("shadow", "8-bit black", imageWidth, imageHeight, 1);
		getSelectionFromMask("label_mask");
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX+shadowDisp, selMaskY+shadowDrop);
		setBackgroundColor(shadowDarkness, shadowDarkness, shadowDarkness);
		run("Clear");
		getSelectionFromMask("label_mask");
		expansion = abs(shadowDisp) + abs(shadowDrop) + abs(shadowBlur);
		if (expansion>0) run("Enlarge...", "enlarge=[expansion] pixel");
		if (shadowBlur>0) run("Gaussian Blur...", "sigma=[shadowBlur]");
		run("Select None");
	}
	function createInnerShadowFromMask() {
		showStatus("Creating inner shadow for labels . . . ");
		newImage("inner_shadow", "8-bit white", imageWidth, imageHeight, 1);
		getSelectionFromMask("label_mask");
		setBackgroundColor(innerShadowDarkness, innerShadowDarkness, innerShadowDarkness);
		run("Clear Outside");
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX-innerShadowDisp, selMaskY-innerShadowDrop);
		setBackgroundColor(innerShadowDarkness, innerShadowDarkness, innerShadowDarkness);
		run("Clear Outside");
		getSelectionFromMask("label_mask");
		expansion = abs(innerShadowDisp) + abs(innerShadowDrop) + abs(innerShadowBlur);
		if (expansion>0) run("Enlarge...", "enlarge=[expansion] pixel");
		if (innerShadowBlur>0) run("Mean...", "radius=[innerShadowBlur]"); //Gaussian is too large
		if (fontSize<12) run("Unsharp Mask...", "radius=0.5 mask=0.2"); // A tweak to sharpen effect for small font sizes
		imageCalculator("Max", "inner_shadow","label_mask");
		run("Select None");
		run("Invert");  /* create an image that can be subtracted - works better for color than min */
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
	function getSelectionFromMask(selection_Mask){
		tempTitle = getTitle();
		selectWindow(selection_Mask);
		run("Create Selection"); /* selection inverted perhaps because mask has inverted lut? */
		run("Make Inverse");
		selectWindow(tempTitle);
		run("Restore Selection");
	}
		function unCleanLabel(string) {
		string= replace(string, fromCharCode(178), "\\^2"); // superscript 2 
		string= replace(string, fromCharCode(179), "\\^3"); // superscript 3 UTF-16 (decimal)
		string= replace(string, fromCharCode(0x207B) + fromCharCode(185), "\\^-1"); // superscript -1
		string= replace(string, fromCharCode(0x207B) + fromCharCode(178), "\\^-2"); // superscript -2
		string= replace(string, fromCharCode(181), "u"); // micrometer units
		string= replace(string, fromCharCode(197), "Angstrom"); // angstrom symbol
		string= replace(string, fromCharCode(0x2009), "_"); // replace underlines with thin spaces
		string= replace(string, "_\\+", "\\+"); /* clean up autofilenames */
		string= replace(string, "\\+\\+", "\\+"); /* clean up autofilenames */
		string= replace(string, "__", "_"); /* clean up autofilenames */
		 /* clean up autofilenames */
		return string;
	}
	function restoreExit(message){ // clean up before aborting macro then exit
		restoreSettings(); //clean up before exiting
		setBatchMode("exit & display"); // not sure if this does anything useful if exiting gracefully but otherwise harmless
		exit(message);
	}
	function writeLabel(labelColor){
		setColorFromColorName(labelColor);
		drawString(finalLabel, finalLabelX, finalLabelY); 
	}	
	function writeObjectLabelNoRamp() {
		roiManager("Select", i);
		labelValue = getResult(parameter,i);
		if (dpChoice=="Auto")
			decPlaces = autoCalculateDecPlacesFromValueOnly(labelValue);
		labelString = d2s(labelValue,decPlaces); // Reduce Decimal places for labeling - move these two lines to below the labels you prefer
		Roi.getBounds(roiX, roiY, roiWidth, roiHeight);
		lFontSize = fontSize; /* initial estimate */
		setFont(font,lFontSize,fontStyle);
		lFontSize = fontSizeCorrection * fontSize * roiWidth/(getStringWidth(labelString)); // adjust label font size so it fits within object width
		if (lFontSize>fontSizeCorrection*roiHeight) lFontSize = fontSizeCorrection*roiHeight; // readjust label font size so label fits within object height
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
}