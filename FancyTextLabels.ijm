macro "Add Multiple Lines of Fancy Text To Image" {
	/* This macro adds multiple lines of text to a copy of the image
		Peter J. Lee Applied Superconductivity Center at National High Magnetic Field Laboratory
		Version v161104
	 */
	requires("1.47r");
	saveSettings;
	if (selectionType>=0) {
		selEType = selectionType; 
		selectionExists = 1;
		getSelectionBounds(selEX, selEY, selEWidth, selEHeight);
	}
	else selectionExists = 0;
	t=getTitle();
	/* Check to see if a Ramp legend rather than the image has been selected by accident */
	if (matches(t, ".*Ramp.*")==1) showMessageWithCancel("Title contains \"Ramp\"", "Do you want to label" + t + " ?"); 
	setBatchMode(true);
	imageWidth = getWidth();
	imageHeight = getHeight();
	imageDims = imageHeight + imageWidth;
	originalImageDepth = bitDepth();
	id = getImageID();
	fontSize = round(imageDims/40); /* default font size */
	if (fontSize < 10) fontSize = 10; /* set minimum default font size as 10 */
	lineSpacing = 1.1;
	outlineStroke = 6; /* default outline stroke: % of font size */
	shadowDrop = 8;  /* default outer shadow drop: % of font size */
	dIShO = 4; /* default inner shadow drop: % of font size */
	shadowDisp = shadowDrop;
	shadowBlur = 1.1* shadowDrop;
	shadowDarkness = 50;
	innerShadowDrop = dIShO;
	innerShadowDisp = dIShO;
	innerShadowBlur = floor(dIShO/2);
	innerShadowDarkness = 20;
	offsetX = round(1 + imageWidth/150); /* default offset of label from edge */
	offsetY = round(1 + imageHeight/150); /* default offset of label from edge */
		
	/* Then Dialog . . . */
	Dialog.create("Basic Label Options");
		if (selectionExists==1) {
			textLocChoices = newArray("Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right", "Center of New Selection", "At Selection"); 
			loc = 6;
		} else {
			textLocChoices = newArray("Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right", "Center of New Selection"); 
			loc = 2;
		}
		Dialog.addChoice("Location of Summary:", textLocChoices, textLocChoices[loc]);
		if (selectionExists==1) {
			Dialog.addNumber("Selection Bounds: X start = ", selEX);
			Dialog.addNumber("Selection Bounds: Y start = ", selEY);
			Dialog.addNumber("Selection Bounds: Width = ", selEWidth);
			Dialog.addNumber("Selection Bounds: Height = ", selEHeight);
		}
		Dialog.addNumber("Image Label Font size:", fontSize);
		if (originalImageDepth==24)
			colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray", "red", "pink", "green", "blue", "yellow", "orange", "garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "gray_modern", "green_dark_modern", "green_modern", "orange_modern", "pink_modern", "purple_modern", "red_N_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern"); 
		else colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray");
		Dialog.addChoice("Text color:", colorChoice, colorChoice[0]);
		fontStyleChoice = newArray("bold", "bold antialiased", "italic", "italic antialiased", "bold italic", "bold italic antialiased", "unstyled");
		Dialog.addChoice("Font style:", fontStyleChoice, fontStyleChoice[1]);
		fontNameChoice = newArray("SansSerif", "Serif", "Monospaced");
		Dialog.addChoice("Font name:", fontNameChoice, fontNameChoice[0]);
		Dialog.addChoice("Outline (background) color:", colorChoice, colorChoice[1]);
		Dialog.addMessage("^2 & um etc. replaced by " + fromCharCode(178) + " & " + fromCharCode(181) + "m etc.\n If the units are in the parameter\n label, within \(...\) i.e. \(unit\) they will \noverride this selection:");
		textChoiceLines = 8;
		for (i=0; i<textChoiceLines; i++)
			Dialog.addString("Label Line "+(i+1)+":","-blank-", 30);
		Dialog.addRadioButtonGroup("Tweak the Formatting? ", newArray("Yes", "No"), 1, 2, "No");
								
		Dialog.show();
		textLocChoice = Dialog.getChoice();
		if (selectionExists==1) {
			selEX =  Dialog.getNumber();
			selEY =  Dialog.getNumber();
			selEWidth =  Dialog.getNumber();
			selEHeight =  Dialog.getNumber();
		}
		fontSize =  Dialog.getNumber();
		selColor = Dialog.getChoice();
		fontStyle = Dialog.getChoice();
		fontName = Dialog.getChoice();
		outlineColor = Dialog.getChoice();
		textInputLines = newArray(textChoiceLines);
		for (i=0; i<textChoiceLines; i++)
			textInputLines[i] = Dialog.getString();
		tweakFormat = Dialog.getRadioButton();
			
	if (tweakFormat=="Yes") {	
		Dialog.create("Advanced Formatting Options");
		Dialog.addNumber("Line Spacing", lineSpacing,0,3,"\(default 1\)");
		Dialog.addNumber("Outline Stroke:", outlineStroke,0,3,"% of font size");
		Dialog.addChoice("Outline (background) color:", colorChoice, colorChoice[1]);
		Dialog.addNumber("Shadow Drop: ±", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Displacement Right: ±", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Gaussian Blur:", floor(0.75 * shadowDrop),0,3,"% of font size");
		Dialog.addNumber("Shadow Darkness:", 75,0,3,"%\(darkest = 100%\)");
		// Dialog.addMessage("The following \"Inner Shadow\" options do not change the Overlay Labels");
		Dialog.addNumber("Inner Shadow Drop: ±", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner Displacement Right: ±", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner Shadow Mean Blur:",floor(dIShO/2),1,3,"% of font size");
		Dialog.addNumber("Inner Shadow Darkness:", 20,0,3,"% \(darkest = 100%\)");
						
		Dialog.show();
		lineSpacing = Dialog.getNumber();
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
	}				
	negAdj = 0.5;  /* negative offsets appear exaggerated at full displacement */
	if (shadowDrop<0) shadowDrop *= negAdj;
	if (shadowDisp<0) shadowDisp *= negAdj;
	if (shadowBlur<0) shadowBlur *= negAdj;
	if (innerShadowDrop<0) innerShadowDrop *= negAdj;
	if (innerShadowDisp<0) innerShadowDisp *= negAdj;
	if (innerShadowBlur<0) innerShadowBlur *= negAdj;
	fontFactor = fontSize/100;
	outlineStroke = floor(fontFactor * outlineStroke);
	shadowDrop = floor(fontFactor * shadowDrop);
	shadowDisp = floor(fontFactor * shadowDisp);
	shadowBlur = floor(fontFactor * shadowBlur);
	innerShadowDrop = floor(fontFactor * innerShadowDrop);
	innerShadowDisp = floor(fontFactor * innerShadowDisp);
	innerShadowBlur = floor(fontFactor * innerShadowBlur);
		if (offsetX<(shadowDisp+shadowBlur+1)) offsetX = (shadowDisp+shadowBlur+1);  /* make sure shadow does not run off edge of image */
	if (offsetY<(shadowDrop+shadowBlur+1)) offsetY = (shadowDrop+shadowBlur+1);
	if (fontStyle=="unstyled") fontStyle="";
/*  */			
	textOutNumber = 0;
	textInputLinesText = newArray(textChoiceLines);
	setFont(fontName, fontSize, fontStyle);
	longestStringWidth = 0;
	for (i=0; i<textChoiceLines; i++) {
		if (textInputLines[i]!="-blank-") {
			textInputLinesText[i] = "" + cleanLabel(textInputLines[i]);
			textOutNumber = i+1; /* This allows you to have blank lines between lines but not at the end */
			if (getStringWidth(textInputLinesText[i])>longestStringWidth) longestStringWidth = getStringWidth(textInputLines[i]);
		}
	}
	linesSpace = lineSpacing * (textOutNumber-1) * fontSize;
		if (textLocChoice == "Top Left") {
		selEX = offsetX;
		selEY = offsetY;
	} else if (textLocChoice == "Top Right") {
		selEX = imageWidth - longestStringWidth - offsetX;
		selEY = offsetY;
	} else if (textLocChoice == "Center") {
		selEX = round((imageWidth - longestStringWidth)/2);
		selEY = round((imageHeight - linesSpace)/2);
	} else if (textLocChoice == "Bottom Left") {
		selEX = offsetX;
		selEY = imageHeight - (offsetY + linesSpace); 
	} else if (textLocChoice == "Bottom Right") {
		selEX = imageWidth - longestStringWidth - offsetX;
		selEY = imageHeight - (offsetY + linesSpace);
	} else if (textLocChoice == "Center of New Selection"){
		if (is("Batch Mode")==true) setBatchMode(false); /* Does not accept interaction while batch mode is on */
		setTool("rectangle");
		msgtitle="Location for the text labels...";
		msg = "Draw a box in the image where you want to center the text labels...";
		waitForUser(msgtitle, msg);
		getSelectionBounds(newSelEX, newSelEY, newSelEWidth, newSelEHeight);
		selEX = newSelEX + round((newSelEWidth/2) - longestStringWidth/1.5);
		selEY = newSelEY + round((newSelEHeight/2) - (linesSpace/2));
		if (is("Batch Mode")==false) setBatchMode(true);	/* toggle batch mode back on */
	} else if (selectionExists==1) {
		selEX = selEX + round((selEWidth/2) - longestStringWidth/1.5);
		selEY = selEY + round((selEHeight/2) - (linesSpace/2));
	}
	run("Select None");
	if (selEY<=1.5*fontSize)
		selEY += fontSize;
	if (selEX<offsetX) selEX = offsetX;
	endX = selEX + longestStringWidth;
	if ((endX+offsetX)>imageWidth) selEX = imageWidth - longestStringWidth - offsetX;
	textLabelX = selEX;
	textLabelY = selEY;
	setColorFromColorName("white");
	roiManager("show none");
	// run("Flatten"); /* changes bit depth */
	run("Duplicate...", t+"+text");
	labeledImage = getTitle();
	if (is("Batch Mode")==false) setBatchMode(true);	/* toggle batch mode back on */
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	roiManager("deselect");
	run("Select None");
	/* Draw summary over top of labels */
	setFont(fontName,fontSize, fontStyle);
	for (i=0; i<textOutNumber; i++) {
		if (textInputLines[i]!="-blank-") {
			drawString(textInputLinesText[i], textLabelX, textLabelY);
			textLabelY += lineSpacing * fontSize;
		}
		else textLabelY += lineSpacing * fontSize;
	}
	setThreshold(0, 128);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	/* Create drop shadow if desired */
	if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0)
		createShadowDropFromMask();
	/* Create inner shadow if desired */
	if (innerShadowDrop!=0 || innerShadowDisp!=0 || innerShadowBlur!=0)
		createInnerShadowFromMask();
	if (isOpen("shadow"))
		imageCalculator("Subtract", labeledImage,"shadow");
	run("Select None");
	getSelectionFromMask("label_mask");
	run("Enlarge...", "enlarge=[outlineStroke] pixel");
	setBackgroundFromColorName(outlineColor);
	run("Clear");
	run("Select None");
	getSelectionFromMask("label_mask");
	setBackgroundFromColorName(selColor);
	run("Clear");
	run("Select None");
	if (isOpen("inner_shadow"))
		imageCalculator("Subtract", labeledImage,"inner_shadow");
	closeImageByTitle("shadow");
	closeImageByTitle("inner_shadow");
	closeImageByTitle("label_mask");
	selectWindow(labeledImage);
	if ((lastIndexOf(t,"."))>0)  labeledImageNameWOExt = unCleanLabel(substring(labeledImage, 0, lastIndexOf(labeledImage,".")));
	else labeledImageNameWOExt = unCleanLabel(labeledImage);
	rename(labeledImageNameWOExt + "+text");
	restoreSettings;
	setBatchMode("exit & display");
	showStatus("Fancy Text Labels Finished");
	/* 
	( 8(|)   ( 8(|)  Functions  ( 8(|)  ( 8(|)
	*/
	function cleanLabel(string) {
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
		divider = (100/abs(innerShadowDarkness));
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
			// run("Unsharp Mask...", "radius=[shadowBlur] mask=0.4"); // Make Gaussian shadow edge a little less fuzzy
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
		divider = (100/abs(shadowDarkness));
		run("Divide...", "value=[divider]");
	}
	function getSelectionFromMask(selection_Mask){
		tempTitle = getTitle();
		selectWindow(selection_Mask);
		run("Create Selection"); /* selection inverted perhaps because mask has inverted lut? */
		run("Make Inverse");
		selectWindow(tempTitle);
		run("Restore Selection");
	}
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
	function getHexColorFromRGBArray(colorNameString) {
		colorArray = getColorArrayFromColorName(colorNameString);
		 r = toHex(colorArray[0]); g = toHex(colorArray[1]); b = toHex(colorArray[2]);
		 hexName= "#" + ""+pad(r) + ""+pad(g) + ""+pad(b);
		 return hexName;
	}
	function pad(n) {
		n= toString(n); if (lengthOf(n)==1) n= "0"+n; return n;
	}
	function unCleanLabel(string) { /* this function replaces special characters with standard characters for file system compatible filenames */
		string= replace(string, fromCharCode(178), "\\^2"); /* superscript 2 */
		string= replace(string, fromCharCode(179), "\\^3"); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, fromCharCode(0x207B) + fromCharCode(185), "\\^-1"); /* superscript -1 */
		string= replace(string, fromCharCode(0x207B) + fromCharCode(178), "\\^-2"); /* superscript -2 */
		string= replace(string, fromCharCode(181), "u"); /* micrometer units */
		string= replace(string, fromCharCode(197), "Angstrom"); /* angstrom symbol */
		string= replace(string, fromCharCode(0x2009)+"fromCharCode(0x00B0)", "deg"); /* replace thin spaces degrees combination */
		string= replace(string, fromCharCode(0x2009), "_"); /* replace thin spaces  */
		string= replace(string, "_\\+", "\\+"); /* clean up autofilenames */
		string= replace(string, "\\+\\+", "\\+"); /* clean up autofilenames */
		string= replace(string, "__", "_"); /* clean up autofilenames */
		return string;
	}
}