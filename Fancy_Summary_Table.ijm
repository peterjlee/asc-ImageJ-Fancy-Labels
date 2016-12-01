/* Inspired by the BAR ROI_Color_Coder.ijm

	This macro adds a statistical summary of the analysis to the image in the selection box or at one of the corners of the image.

	This version defaults to choosing units automatically
	This version: v161017
 */
macro "Add Summary Table to Copy of Image"{
	// assess required conditions before proceeding
	requires("1.47r");
	saveSettings;

	/* Set options for black objects on white background as this works better for publications */
	run("Options...", "iterations=1 white count=1"); /* set white background */
	run("Colors...", "foreground=black background=white selection=yellow"); /* set colors */
	setOption("BlackBackground", false);
	run("Appearance...", " "); /* do not use Inverting LUT */
	// The above should be the defaults but this makes sure (black particles on a white background)
	// http://imagejdocu.tudor.lu/doku.php?id=faq:technical:how_do_i_set_up_imagej_to_deal_with_white_particles_on_a_black_background_by_default

	selEType = selectionType; 
	if (selEType>=0) {
		getSelectionBounds(selEX, selEY, selEWidth, selEHeight);
		// if (selEType==5) getLine(selEX, selEY, selEX2, selEY2, selLineWidth);
		// if (selEType==2 || selEType==3 || selEType==6 || selEType==7 || selEType==8|| selEType==10)
		// getSelectionCoordinates(selEXCoords, selEYCoords);
	}

	t=getTitle();
	// Checks to see if a Ramp legend has been selected by accident
	if (matches(t, ".*Ramp.*")==1) showMessageWithCancel("Title contains \"Ramp\"", "Do you want to label" + t + " ?"); 
		setBatchMode(true);
	checkForResults();
	items= nResults;

	imageWidth = getWidth();
	imageHeight = getHeight();
	id = getImageID();

	getPixelSize(unit, null, null);
	fontSize = 22; /* default font size */
	lineSpacing = 1.1;
	outlineStroke = 8; /* default outline stroke: % of font size */
	shadowDrop = 12;  /* default outer shadow drop: % of font size */
	dIShO = 5; /* default inner shadow drop: % of font size */
	offsetX = round(1 + imageWidth/150); /* default offset of label from edge */
	offsetY = round(1 + imageHeight/150); /* default offset of label from edge */

	outlineColor = "black"; 	
	originalImageDepth = bitDepth();

	paraLabFontSize = round((imageHeight+imageWidth)/60);

	decPlacesSummary = -1;	//defaults to scientific notation
		/* Then Dialog . . . */

	Dialog.create("Label Formatting Options");
		headings = split(String.getResultsHeadings);
		Dialog.addChoice("Measurement:", headings, "Area");
		if (originalImageDepth==24)
			colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray", "red", "pink", "green", "blue", "yellow", "orange", "garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "gray_modern", "green_dark_modern", "green_modern", "orange_modern", "pink_modern", "purple_modern", "red_N_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern"); 
		else colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray");
		Dialog.addChoice("Text color:", colorChoice, colorChoice[0]);
		fontStyleChoice = newArray("bold", "bold antialiased", "italic", "italic antialiased", "bold italic", "bold italic antialiased", "unstyled");
		Dialog.addChoice("Font style:", fontStyleChoice, fontStyleChoice[1]);
		fontNameChoice = newArray("SansSerif", "Serif", "Monospaced");
		Dialog.addChoice("Font name:", fontNameChoice, fontNameChoice[0]);
		Dialog.addNumber("Line Spacing", lineSpacing,0,3,"");
		unitChoice = newArray("Auto", "Manual", unit, unit+"^2", "None", "pixels", "pixels^2", fromCharCode(0x00B0), "degrees", "radians", "%", "arb.");
		Dialog.addChoice("Unit Label \(if needed\):", unitChoice, unitChoice[0]);
		Dialog.addNumber("Outline Stroke:", outlineStroke,0,3,"% of font size");
		Dialog.addChoice("Outline (background) color:", colorChoice, colorChoice[1]);
		Dialog.addNumber("Shadow Drop: �", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Displacement Right: �", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Gaussian Blur:", floor(0.75 * shadowDrop),0,3,"% of font size");
		Dialog.addNumber("Shadow Darkness:", 75,0,3,"%\(darkest = 100%\)");

		Dialog.addMessage("The following \"Inner Shadow\" options do not change the Overlay scale bar");
		Dialog.addNumber("Inner Shadow Drop: �", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner Displacement Right: �", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner Shadow Mean Blur:",floor(dIShO/2),1,3,"% of font size");
		Dialog.addNumber("Inner Shadow Darkness:", 20,0,3,"% \(darkest = 100%\)");

						
		Dialog.show();
		parameter = Dialog.getChoice();
		labelColor = Dialog.getChoice();
		fontStyle = Dialog.getChoice();
		fontName = Dialog.getChoice();
		lineSpacing = Dialog.getNumber();
		unitLabel = Dialog.getChoice();
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

	// Determine parameter label
	parameterLabel = parameter;
	if (unitLabel=="Auto") unitLabel = unitLabelFromString(parameter, unit);

	if (unitLabel=="Manual") {
		unitLabel = unitLabelFromString(parameter, unit);
			Dialog.create("Manual unit input");
			Dialog.addString("Label:", unitLabel, 8);
			Dialog.addMessage("^2 & um etc. replaced by " + fromCharCode(178) + " & " + fromCharCode(181) + "m...");
			Dialog.show();
			unitLabel = Dialog.getString();
	}
	if (unitLabel=="None") unitLabel = ""; 
	parameterLabel = stripUnitFromString(parameter);
	unitLabel= cleanLabel(unitLabel);	
	parameterLabel= cleanLabel(parameterLabel);
	parameterLabel = replace(parameterLabel, "px", "pixels"); // expand "px" used to keep Results columns narrower
	//recombine units and labels
	if (unitLabel!="") paraLabel = parameterLabel + ", " + unitLabel;
	else paraLabel = parameterLabel;
	// parameterLabel = replace(parameterLabel, "_", fromCharCode(0x2009)); // replace underlines with thin spaces
	parameterLabel = expandLabel(parameterLabel);
						
	negAdj = 0.5;  /* negative offsets appear exaggerated at full displacement */
	if (shadowDrop<0) shadowDrop *= negAdj;
	if (shadowDisp<0) shadowDisp *= negAdj;
	if (shadowBlur<0) shadowBlur *= negAdj;
	if (innerShadowDrop<0) innerShadowDrop *= negAdj;
	if (innerShadowDisp<0) innerShadowDisp *= negAdj;
	if (innerShadowBlur<0) innerShadowBlur *= negAdj;
		fontPC = fontSize/100; /* convert percent to pixels */
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
		if (fontStyle=="unstyled") fontStyle="";

	paraLabFontSize = round((imageHeight+imageWidth)/45);
	statsLabFontSize= round((imageHeight+imageWidth)/60);
		// get values for chosen parameter
	values= newArray(items);
	for (i=0; i<items; i++)
		values[i]= getResult(parameter,i);
	Array.getStatistics(values, arrayMin, arrayMax, arrayMean, arraySD);
	decPlacesSummary = autoCalculateDecPlacesFromValueOnly(arrayMean);
	coeffVar = (100/arrayMean)*arraySD;
	dpLab = decPlacesSummary+2; // Increase dp over ramp label autosetting		
	coeffVar = d2s(coeffVar,dpLab);
	arrayMeanLab = d2s(arrayMean,dpLab);
	coeffVarLab = d2s((100/arrayMean)*arraySD,dpLab);
	arraySDLab = d2s(arraySD,dpLab);
	arrayMinLab = d2s(arrayMin,dpLab);
	arrayMaxLab = d2s(arrayMax,dpLab);
	sortedValues = Array.copy(values);
	sortedValues = Array.sort(sortedValues);
	arrayMedian = sortedValues[round(items/2)];
	arrayMedianLab = d2s(arrayMedian,dpLab);
				
	if (selEType>=0) loc = 6; //default choice selector for dialog
	else loc = 2; //default choice selector for dialog - center
	paraLabel = expandLabel(paraLabel);
		/* Then Dialog . . . */
	Dialog.create("Feature Label Formatting Options");
		if (selEType>=0) paraLocChoice = newArray("Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right", "Center of New Selection", "At Selection"); 
		else paraLocChoice = newArray("Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right", "Center of New Selection"); 
		Dialog.addChoice("Location of Summary:", paraLocChoice, paraLocChoice[loc]);
		Dialog.addChoice("Parameter Label: " + paraLabel, newArray("Yes", "No"), "Yes");
		Dialog.addNumber("Image Label Font size:", paraLabFontSize);			
		statsChoice = newArray("None", "Dashed line:  ---", "Number of objects:  "+items,  "Mean:  "+arrayMeanLab, "Median:  "+arrayMedianLab, "StdDev:  "+arraySDLab, "CoeffVar:  "+coeffVarLab, "Min-Max:  "+arrayMinLab+"-"+arrayMaxLab, "Minimum:  "+arrayMinLab, "Maximum:  "+arrayMaxLab, "Long dashed underline:  ___");
		statsChoiceLines = 8;
		for (i=0; i<statsChoiceLines; i++)
			Dialog.addChoice("Statistics Label Line "+(i+1)+":", statsChoice, statsChoice[i+1]);
		dpChoice = newArray(dpLab, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8);
		Dialog.addChoice("Change Decimal Places from "+dpLab, dpChoice, dpLab);
		Dialog.addNumber("Statistics Label Font size:", statsLabFontSize);
		Dialog.show();
		
		paraLabPos = Dialog.getChoice();
		paraLabChoice = Dialog.getChoice();
		paraLabFontSize =  Dialog.getNumber();
		statsLabLine = newArray(statsChoiceLines);
		for (i=0; i<statsChoiceLines; i++)
			statsLabLine[i] = Dialog.getChoice();
		decPlacesSummary = Dialog.getChoice();
		statsLabFontSize = Dialog.getNumber();
			
	if (paraLabChoice=="Yes") labLines = 1;

	else labLines = 0;
	statsLines = 0;
	statsLabLineText = newArray(8);
	setFont(fontName, statsLabFontSize, fontStyle);
	longestStringWidth = 0;
	for (i=0; i<statsChoiceLines; i++) {
		// if (statsLabLine[i]!="None") statsLines = statsLines + 1;
		if (statsLabLine[i]!="None") {
			statsLines = i + 1;
			statsLabLine[i] = substring(statsLabLine[i], 0, indexOf(statsLabLine[i], ":  "));
			if (statsLabLine[i]=="Dashed line") statsLabLineText[i] = "----------";
			else if (statsLabLine[i]=="Number of objects") statsLabLineText[i] = "Objects = " + items;
			else if (statsLabLine[i]=="Mean") statsLabLineText[i] = "Mean = " + d2s(arrayMean,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="Median") statsLabLineText[i] = "Median = " + d2s(arrayMedian,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="StdDev") statsLabLineText[i] = "Std.Dev. = " + d2s(arraySD,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="CoeffVar") statsLabLineText[i] = "Coeff.Var. = " + d2s(coeffVar,decPlacesSummary) + "%";
			else if (statsLabLine[i]=="Min-Max") statsLabLineText[i] = "Range = " + d2s(arrayMin,decPlacesSummary) + " - " + d2s(arrayMax,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="Minimum") statsLabLineText[i] = "Minimum = " + d2s(arrayMin,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="Maximum") statsLabLineText[i] = "Maximum = " + d2s(arrayMax,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="Long Dashed Underline:  ___") statsLabLineText[i] = "__________";
			if (unitLabel==fromCharCode(0x00B0)) statsLabLineText[i] = replace(statsLabLineText[i], " "+ fromCharCode(0x00B0), fromCharCode(0x00B0)); // tweak to remove space before degree symbol
			if (getStringWidth(statsLabLineText[i])>longestStringWidth) longestStringWidth = getStringWidth(statsLabLineText[i]);
		}
	}
	linesSpace = lineSpacing * ((labLines*paraLabFontSize)+(statsLines*statsLabFontSize)); // Calculate vertical space taken up by text

	if (paraLabChoice=="Yes") {
		setFont(fontName, paraLabFontSize, fontStyle);
		if (getStringWidth(paraLabel)>longestStringWidth) longestStringWidth = getStringWidth(paraLabel);
	}
	if (paraLabPos == "Top Left") {
		selEX = offsetX;
		selEY = offsetY;
	} else if (paraLabPos == "Top Right") {
		selEX = imageWidth - longestStringWidth - offsetX;
		selEY = offsetY;
	} else if (paraLabPos == "Center") {
		selEX = round((imageWidth/2) - longestStringWidth/2);
		selEY = round((imageHeight/2) - (linesSpace/2));
	} else if (paraLabPos == "Bottom Left") {
		selEX = offsetX;
		selEY = imageHeight - (offsetY + linesSpace); 
	} else if (paraLabPos == "Bottom Right") {
		selEX = imageWidth - longestStringWidth - offsetX;
		selEY = imageHeight - (offsetY + linesSpace);
	} else if (paraLabPos == "Center of New Selection"){
		if (is("Batch Mode")==true) setBatchMode(false); /* Does not accept interaction while batch mode is on */
		setTool("rectangle");
		msgtitle="Location for the summary labels...";
		msg = "Draw a box in the image where you want to center the summary labels...";
		waitForUser(msgtitle, msg);
		getSelectionBounds(newSelEX, newSelEY, newSelEWidth, newSelEHeight);

		selEX = newSelEX + round((newSelEWidth/2) - longestStringWidth/1.5);
		selEY = newSelEY + round((newSelEHeight/2) - (linesSpace/2));
		if (is("Batch Mode")==false) setBatchMode(true);	// toggle batch mode back on

	} else if (selEType>=0) {
		selEX = selEX + round((selEWidth/2) - longestStringWidth/1.5);
		selEY = selEY + round((selEHeight/2) - (linesSpace/2));
	}
	run("Select None");
	if (selEY<=1.5*paraLabFontSize)
		selEY += paraLabFontSize;
	if (selEX<offsetX) selEX = offsetX;
	endX = selEX + longestStringWidth;
	if ((endX+offsetX)>imageWidth) selEX = imageWidth - longestStringWidth - offsetX;
	paraLabelX = selEX;
	paraLabelY = selEY;
	setColorFromColorName("white");

	roiManager("show none");
	// roiManager("Show All without labels");
	run("Flatten");
	flatImage = getTitle();
	if (is("Batch Mode")==false) setBatchMode(true);
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	roiManager("show none");
	roiManager("deselect");
	run("Select None");

	// Draw summary over top of labels

	if (paraLabChoice=="Yes") {
		setFont(fontName, paraLabFontSize, fontStyle);
		drawString(paraLabel, paraLabelX, paraLabelY);
		paraLabelY += lineSpacing * paraLabFontSize;
	}
	setFont(fontName,statsLabFontSize, fontStyle);
	for (i=0; i<statsLines; i++) {
		// if (statsLabLine[i]!="None") statsLines = statsLines + 1;
		if (statsLabLine[i]!="None") {
			drawString(statsLabLineText[i], paraLabelX, paraLabelY);
			paraLabelY += lineSpacing * statsLabFontSize;

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

	showStatus("Fancy Summary Table Macro Finished");
		/* ( 8(|)   ( 8(|)  ASC Functions  ( 8(|)  ( 8(|)   */

	function autoCalculateDecPlacesFromValueOnly(value){ // note this version is different from the one used for ramp legends
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
	function checkForResults() {
		if (nResults==0)	{
			Dialog.create("No Results to Work With");
			Dialog.addCheckbox("Run Analyze-particles to generate table?", true);
			Dialog.addMessage("This macro requires a Results table to analyze.");
			Dialog.show();
			analyzeNow = Dialog.getCheckbox(); //if (analyzeNow==true) ImageJ analyze particles will be performed, otherwise exit;
			if (analyzeNow==true) {
				if (roiManager("count")!=0) {
					roiManager("deselect")
					roiManager("delete"); 
				}
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

		string= replace(string, " " + fromCharCode(0x00B0), fromCharCode(0x00B0)); // remove space before degree symbol
		string= replace(string, " �", fromCharCode(0x00B0)); // remove space before degree symbol
		return string;
	}
	function closeImageByTitle(windowTitle) {  /* cannot be used with tables */
        if (isOpen(windowTitle)) {
		selectWindow(windowTitle);
        close();
		}
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
	function pad(n) {
		n= toString(n); if (lengthOf(n)==1) n= "0"+n; return n;
	}
		/* End ASC Color Functions */
		
	function expandLabel(string) {  // mostly for better looking summary tables
		string = replace(string, "Raw Int Den", "Raw Int. Density");
		string = replace(string, "FeretAngle", "Feret Angle");
		string = replace(string, "FiberThAnn", "Fiber Thickn. from Annulus");
		string = replace(string, "FiberLR", "Fiber Length R");
		string = replace(string, "Da", "Diam:area");
		string = replace(string, "Dp", "Diam:perim.");
		string = replace(string, "equiv", "equiv.");
		string = replace(string, "_", " ");
		string = replace(string, "�", "degrees");
		string = replace(string, "0-90", "0-90�"); // put this here as an exception to the above
		string = replace(string, "�, degrees", "�"); // that would be otherwise too many degrees
		string= replace(string, fromCharCode(0x00C2), ""); // remove mystery �
		string = replace(string, " ", fromCharCode(0x2009)); // use this last so all spaces converted
		return string;
	}		

	function getSelectionFromMask(selection_Mask){
		tempTitle = getTitle();
		selectWindow(selection_Mask);
		run("Create Selection"); /* selection inverted perhaps because mask has inverted lut? */
		run("Make Inverse");
		selectWindow(tempTitle);
		run("Restore Selection");
	}
	function removeTrailingZerosAndPeriod(string) { //removes trailing zeros after period
		while (endsWith(string,".0")) {
			string=substring(string,0, lastIndexOf(string, ".0"));
		}
		while(endsWith(string,".")) {
			string=substring(string,0, lastIndexOf(string, "."));
		}
		return string;
	}
	function restoreExit(message){ // clean up before aborting macro then exit
		restoreSettings(); //clean up before exiting
		setBatchMode("exit & display"); // not sure if this does anything useful if exiting gracefully but otherwise harmless
		exit(message);
	}
	function stripUnitFromString(string) {
		if (endsWith(string,"\)")) { // label with units from string string if available
			unitIndexStart = lastIndexOf(string, "\(");
			unitIndexEnd = lastIndexOf(string, "\)");
			stringUnit = substring(string, unitIndexStart+1, unitIndexEnd);
			unitCheck = matches(stringUnit, ".*[0-9].*");
			if (unitCheck==0) {  //if it contains a number it probably isn't a unit
				stringLabel = substring(string, 0, unitIndexStart);
			}
			else stringLabel = string;
		}
		else stringLabel = string;
		return stringLabel;
	}
	function unCleanLabel(string) { // this function replaces special characters with standard characters for file system compatible filenames
		string= replace(string, fromCharCode(178), "\\^2"); // superscript 2 
		string= replace(string, fromCharCode(179), "\\^3"); // superscript 3 UTF-16 (decimal)
		string= replace(string, fromCharCode(0x207B) + fromCharCode(185), "\\^-1"); // superscript -1
		string= replace(string, fromCharCode(0x207B) + fromCharCode(178), "\\^-2"); // superscript -2
		string= replace(string, fromCharCode(181), "u"); // micrometer units
		string= replace(string, fromCharCode(197), "Angstrom"); // angstrom symbol
		string= replace(string, fromCharCode(0x2009) + fromCharCode(0x00B0), "deg"); // replace thin spaces degrees combination

		string= replace(string, fromCharCode(0x2009), "_"); // replace thin spaces
		string= replace(string, "_\\+", "\\+"); /* clean up autofilenames */
		string= replace(string, "\\+\\+", "\\+"); /* clean up autofilenames */
		string= replace(string, "__", "_"); /* clean up autofilenames */
		 /* clean up autofilenames */
		return string;
	}
	function unitLabelFromString(string, imageUnit) {
	if (endsWith(string,"\)")) { // label with units from string string if available
		unitIndexStart = lastIndexOf(string, "\(");
		unitIndexEnd = lastIndexOf(string, "\)");
		stringUnit = substring(string, unitIndexStart+1, unitIndexEnd);
		unitCheck = matches(stringUnit, ".*[0-9].*");
		if (unitCheck==0) {  //if it contains a number it probably isn't a unit
			unitLabel = stringUnit;
		}
		else {
			unitLabel = "";
		}
	}
	else {
		if (string=="Area") unitLabel = imageUnit + fromCharCode(178);
		else if (string=="AR" || string=="Circ" || string=="Round" || string=="Solidity") unitLabel = "";
		else if (string=="Mean" || string=="StdDev" || string=="Mode" || string=="Min" || string=="Max" || string=="IntDen" || string=="Median" || string=="RawIntDen" || string=="Slice") unitLabel = "";
		else if (string=="Angle" || string=="FeretAngle" || string=="Angle_0-90" || string=="FeretAngle_0-90") unitLabel = fromCharCode(0x00B0);
		else if (string=="%Area") unitLabel = "%";
		else unitLabel = imageUnit;
	}
	return unitLabel;
	}
}