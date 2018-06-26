macro "Add Multiple Lines of Fancy Text To Image" {
	/* This macro adds multiple lines of text to a copy of the image.
		Peter J. Lee Applied Superconductivity Center at National High Magnetic Field Laboratory.
		ANSI encoded for Windows.
		Version v170411 removes spaces in new image names to fix issue with new combination images.
		v180306 cosmetic changes to text.
		v180308 added non-destructive overlay option (overlay can be saved in TIFF header).
		v180611 Fixed stack labeling and fixed overlay.
		v180618	Added restore selection option (useful for multiple slices) and fixed label vertical location for selected options.
	 */
	requires("1.47r");
	saveSettings;
	if (selectionType>=0) {
		selEType = selectionType; 
		selectionExists = 1;
		getSelectionBounds(selEX, selEY, selEWidth, selEHeight);
	}
	else selectionExists = 0;
	originalImage = getTitle();
	/*	Set options for black objects on white background as this works better for publications */
	run("Options...", "iterations=1 white count=1"); /* Set the background to white */
	run("Colors...", "foreground=black background=white selection=yellow"); /* Set the preferred colors for these macros */
	setOption("BlackBackground", false);
	run("Appearance...", " "); /* do not use Inverting LUT *
	/* Check to see if a Ramp legend rather than the image has been selected by accident */
	if (matches(originalImage, ".*Ramp.*")==1) showMessageWithCancel("Title contains \"Ramp\"", "Do you want to label" + originalImage + " ?"); 
	setBatchMode(true);
	getDimensions(imageWidth, imageHeight, channels, slices, frames);
	sliceNumber = getSliceNumber();
	remSlices = slices-sliceNumber;
	imageDims = imageHeight + imageWidth;
	originalImageDepth = bitDepth();
	if (originalImageDepth==16) {
		Dialog.create("Bit depth conversion");
		Dialog.addMessage("This macro does not work well with 16-bit images");
		conversionChoice = newArray("RGB Color", "8-bit Gray", "Exit");
		Dialog.addRadioButtonGroup("Choose:", conversionChoice, 3, 1, "8-bit Gray");
		
		Dialog.show();
		convertTo = Dialog.getRadioButton();
		if (convertTo=="8-bit Gray") run("8-bit");
		else if (convertTo=="RGB Color") run("RGB Color");
		else restoreExit("Goodbye");
	}
	id = getImageID();
	fontSize = round(imageDims/40); /* default font size */
	if (fontSize < 10) fontSize = 10; /* set minimum default font size as 10 */
	lineSpacing = 1.1;
	outlineStroke = 7; /* default outline stroke: % of font size */
	shadowDrop = 10;  /* default outer shadow drop: % of font size */
	dIShO = 5; /* default inner shadow drop: % of font size */
	shadowDisp = shadowDrop;
	shadowBlur = floor(0.6 * shadowDrop);
	shadowDarkness = 50;
	innerShadowDrop = dIShO;
	innerShadowDisp = dIShO;
	innerShadowBlur = floor(dIShO/2);
	innerShadowDarkness = 16;
	offsetX = round(1 + imageWidth/150); /* default offset of label from edge */
	offsetY = round(1 + imageHeight/150); /* default offset of label from edge */
		
	/* Then Dialog . . . */
	Dialog.create("Basic Label Options");
		if (selectionExists==1) {
			textLocChoices = newArray("Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right", "Center of New Selection", "Center of Selection"); 
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
			Dialog.addCheckbox("Restore selection after macro?", true);
		}
		else restoreSelection = false;
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
		Dialog.addMessage("^2 & um etc. replaced by " + fromCharCode(178) + " & " + fromCharCode(181) + "m etc. If the units are in the parameter\n label, within \(...\) i.e. \(unit\) they will override this selection.\ndegreeC will be replaced with " + fromCharCode(0x00B0) + "C, symbol-Greek letter by symbol");
		textChoiceLines = 8;   
		for (i=0; i<textChoiceLines; i++)
			Dialog.addString("Label Line "+(i+1)+":","-blank-", 30);
		Dialog.addRadioButtonGroup("Tweak the Formatting? ", newArray("Yes", "No"), 1, 2, "No");
		if (Overlay.size==0) overwriteChoice = newArray("Destructive overwrite", "New Image", "Add Overlay");
		else overwriteChoice = newArray("Destructive overwrite", "New Image", "Overlay: Add", "Overlay: Replace Current");
		Dialog.addRadioButtonGroup("Output:__________________________ ", overwriteChoice, 3, 1, overwriteChoice[2]); 
		if (remSlices>0) Dialog.addRadioButtonGroup("Add the same labels to this and next " + remSlices + " slices? ", newArray("Yes", "No"), 1, 2, "No");					
		Dialog.show();
		textLocChoice = Dialog.getChoice();
		if (selectionExists==1) {
			selEX =  Dialog.getNumber();
			selEY =  Dialog.getNumber();
			selEWidth =  Dialog.getNumber();
			selEHeight =  Dialog.getNumber();
			restoreSelection = Dialog.getCheckbox();
			if (restoreSelection) {
				orSelEX = selEX;
				orSelEY = selEY;
				orSelEWidth = selEWidth;
				orSelEHeight = selEHeight;
			}
		}
		fontSize =  Dialog.getNumber();
		fontColor = Dialog.getChoice();
		fontStyle = Dialog.getChoice();
		fontName = Dialog.getChoice();
		outlineColor = Dialog.getChoice();
		textInputLines = newArray(textChoiceLines);
		for (i=0; i<textChoiceLines; i++) {
			textInputLines[i] = Dialog.getString();
			textInputLines[i] = "" + convertToSymbols(textInputLines[i]); /* Use degree symbol */
		}
		tweakFormat = Dialog.getRadioButton();
		overWrite = Dialog.getRadioButton;
		if (remSlices>0) labelRest = Dialog.getRadioButton;
		else labelRest = "No";
	if (tweakFormat=="Yes") {	
		Dialog.create("Advanced Formatting Options");
		Dialog.addNumber("Line Spacing", lineSpacing,1,3,"\(default 1\)");
		Dialog.addNumber("Outline Stroke:", outlineStroke,0,3,"% of font size");
		Dialog.addChoice("Outline (background) color:", colorChoice, colorChoice[1]);
		Dialog.addNumber("Shadow Drop: ?", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Displacement Right: ?", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Gaussian Blur:", floor(0.4 * shadowDrop),0,3,"% of font size");
		Dialog.addNumber("Shadow Darkness:", 100,0,3,"%\(darkest = 100%\)");
		// Dialog.addMessage("The following \"Inner Shadow\" options do not change the Overlay Labels");
		Dialog.addNumber("Inner Shadow Drop: ?", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner Displacement Right: ?", dIShO,0,3,"% of font size");
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
	fontColorArray = getColorArrayFromColorName(fontColor);
	Array.getStatistics(fontColorArray,null,null,fontInt,null);
	outlineColorArray = getColorArrayFromColorName(outlineColor);
	Array.getStatistics(outlineColorArray,null,null,outlineInt,null);
	shadowDarkness = (255/100) * (abs(shadowDarkness));
	innerShadowDarkness = (255/100) * (100 - (abs(innerShadowDarkness)));	
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
	linesSpace = lineSpacing * textOutNumber * fontSize;
	if (textLocChoice == "Top Left") {
		selEX = offsetX;
		selEY = offsetY;
	} else if (textLocChoice == "Top Right") {
		selEX = imageWidth - longestStringWidth - offsetX;
		selEY = offsetY;
	} else if (textLocChoice == "Center") {
		selEX = round((imageWidth - longestStringWidth)/2);
		selEY = round((imageHeight - linesSpace)/2 + fontSize);
	} else if (textLocChoice == "Bottom Left") {
		selEX = offsetX;
		selEY = imageHeight - (offsetY + linesSpace) + fontSize; 
	} else if (textLocChoice == "Bottom Right") {
		selEX = imageWidth - longestStringWidth - offsetX;
		selEY = imageHeight - (offsetY + linesSpace) + fontSize;
	} else if (textLocChoice == "Center of New Selection"){
		if (is("Batch Mode")==true) setBatchMode(false); /* Does not accept interaction while batch mode is on */
		setTool("rectangle");
		msgtitle="Location for the text labels...";
		msg = "Draw a box in the image where you want to center the text labels...";
		waitForUser(msgtitle, msg);
		getSelectionBounds(newSelEX, newSelEY, newSelEWidth, newSelEHeight);
		shrinkX = newSelEWidth/longestStringWidth;
		shrinkY = newSelEHeight/linesSpace;
		shrinkF = minOf(shrinkX, shrinkY);
		if (shrinkF < 1) reduceFontSize = getBoolean("Text will not fit in selection, reduce font size to fit?");
		if (reduceFontSize) {
			fontSize = shrinkF * fontSize;
			linesSpace = shrinkF * linesSpace;
			longestStringWidth = shrinkF * longestStringWidth;
			fontFactor = fontSize/100;
			outlineStroke = floor(fontFactor * outlineStroke);
			shadowDrop = floor(fontFactor * shadowDrop);
			shadowDisp = floor(fontFactor * shadowDisp);
			shadowBlur = floor(fontFactor * shadowBlur);
			innerShadowDrop = floor(fontFactor * innerShadowDrop);
			innerShadowDisp = floor(fontFactor * innerShadowDisp);
			innerShadowBlur = floor(fontFactor * innerShadowBlur);
		}
		selEX = newSelEX + round((newSelEWidth/2) - longestStringWidth/2);
		selEY = newSelEY + round((newSelEHeight/2) - (linesSpace/2) + fontSize);
		restoreSelection = getBoolean("Restore this selection at the end of the macro?");
		if (restoreSelection) {
			orSelEX = newSelEX;
			orSelEY = newSelEY;
			orSelEWidth = newSelEWidth;
			orSelEHeight = newSelEHeight;
		}
		if (is("Batch Mode")==false) setBatchMode(true);	/* toggle batch mode back on */
	} else if (selectionExists==1) {
		shrinkX = selEWidth/longestStringWidth;
		shrinkY = selEHeight/linesSpace;
		shrinkF = minOf(shrinkX, shrinkY);
		if (shrinkF < 1) reduceFontSize = getBoolean("Text will not fit in selection, reduce font size to fit?");
		if (reduceFontSize) {
			fontSize = shrinkF * fontSize;
			linesSpace = shrinkF * linesSpace;
			longestStringWidth = shrinkF * longestStringWidth;
			fontFactor = fontSize/100;
			outlineStroke = floor(fontFactor * outlineStroke);
			shadowDrop = floor(fontFactor * shadowDrop);
			shadowDisp = floor(fontFactor * shadowDisp);
			shadowBlur = floor(fontFactor * shadowBlur);
			innerShadowDrop = floor(fontFactor * innerShadowDrop);
			innerShadowDisp = floor(fontFactor * innerShadowDisp);
			innerShadowBlur = floor(fontFactor * innerShadowBlur);
		}
		selEX = selEX + round((selEWidth/2) - longestStringWidth/2);
		selEY = selEY + round((selEHeight/2) - (linesSpace/2) + fontSize);
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
	if (startsWith(overWrite,"New")) run("Duplicate...", "title=" + getTitle() + "+text");
	flatImage = getTitle();
	if (is("Batch Mode")==false) setBatchMode(true);	/* toggle batch mode back on */
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	roiManager("deselect");
	run("Select None");
	/* Draw summary over top of labels */
	setFont(fontName,fontSize, fontStyle);
	textLabelLineY = textLabelY;
	for (i=0; i<textOutNumber; i++) {
		if (textInputLines[i]!="-blank-") {
			drawString(textInputLinesText[i], textLabelX, textLabelLineY);
			textLabelLineY += lineSpacing * fontSize;
		}
		else textLabelLineY += lineSpacing * fontSize;
	}
	textLabelLineY = textLabelY;
	if(outlineColor=="black" && fontColor=="white") run("Duplicate...", "title=antiAliased");
	else {
		selectWindow(flatImage);
		run("Duplicate...", "title=antiAliased");
		run("Select All");
		setColorFromColorName(outlineColor);
		fill();
		roiManager("deselect");
		run("Select None");
		setColorFromColorName(fontColor);
		/* Draw summary over top of labels */
		setFont(fontName,fontSize, fontStyle);
		for (i=0; i<textOutNumber; i++) {
			if (textInputLines[i]!="-blank-") {
				drawString(textInputLinesText[i], textLabelX, textLabelLineY);
				textLabelLineY += lineSpacing * fontSize;
			}
			else textLabelLineY += lineSpacing * fontSize;
		}
		// if (outlineStroke>0) {
			// fakeAntialias = outlineStroke/2;
			// run("Gaussian Blur...", "sigma=[fakeAntialias]");
		// }
	}	
	selectWindow("label_mask");
	setThreshold(0, 128);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	if (indexOf(overWrite,"Overlay")>0) {
		selectWindow(originalImage);
		if (slices==1) remSlices =1;
		for (o=1; o<remSlices+1; o++) {
			if (slices>1) setSlice(sliceNumber + o);
			else setSlice(1);
			if (endsWith(overWrite,"Current")) Overlay.remove;
			grayHex = toHex(round(255*shadowDarkness/100));
			shadowHex = "#" + ""+pad(grayHex) + ""+pad(grayHex) + ""+pad(grayHex);
			fontColorHex = getHexColorFromRGBArray(fontColor);
			outlineColorHex = getHexColorFromRGBArray(outlineColor);
			run("Select None");
			getSelectionFromMask("label_mask");
			getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
			setSelectionLocation(selMaskX+shadowDisp, selMaskY+shadowDrop);
			Overlay.addSelection(shadowHex, outlineStroke, shadowHex);
			run("Select None");
			getSelectionFromMask("label_mask");
			run("Enlarge...", "enlarge=[outlineStroke] pixel");
			Overlay.addSelection(outlineColorHex,outlineStroke,outlineColorHex);
			run("Select None");
			setColorFromColorName(fontColor);
			textLabelLineY = textLabelY;
			for (t=0; t<textOutNumber; t++) {
				if (textInputLines[t]!="-blank-") {
					Overlay.drawString(textInputLinesText[t], textLabelX, textLabelLineY);
					textLabelLineY += lineSpacing * fontSize;
				}
				else textLabelLineY += lineSpacing * fontSize;
			}
			Overlay.show;
			if (labelRest=="No") o = remSlices+1;
		}
		if (restoreSelection==true)
			makeRectangle(orSelEX, orSelEY, orSelEWidth, orSelEHeight);
		else run("Select None");
	}		
	else {
		selectWindow("antiAliased");
		getSelectionFromMask("label_mask");
		run("Make Inverse");
		if (fontInt>=outlineInt) setColorFromColorName("white");
		else setColorFromColorName("black");
		fill();
		run("Select None");
		// selectWindow("label_mask");
		/* Create drop shadow if desired */
		if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0) {
			showStatus("Creating drop shadow for labels . . . ");
			newImage("shadow", "8-bit black", imageWidth, imageHeight, 1);
			getSelectionFromMask("label_mask");
			getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
			setSelectionLocation(selMaskX+shadowDisp, selMaskY+shadowDrop);
			setBackgroundColor(shadowDarkness, shadowDarkness, shadowDarkness);
			// setBackgroundColor(255, 255, 255);
			run("Clear", "slice");
			getSelectionFromMask("label_mask");
			expansion = abs(shadowDisp) + abs(shadowDrop) + abs(shadowBlur);
			if (expansion>0) run("Enlarge...", "enlarge=[expansion] pixel");
			if (shadowBlur>0) run("Gaussian Blur...", "sigma=[shadowBlur]");
			run("Select None");
		}
		/*	Create inner shadow if desired */
		if (innerShadowDrop!=0 || innerShadowDisp!=0 || innerShadowBlur!=0) {
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
			if (innerShadowBlur>0) run("Mean...", "radius=[innerShadowBlur]"); /* Gaussian is too large */
			if (fontSize<12) run("Unsharp Mask...", "radius=0.5 mask=0.2"); /* A tweak to sharpen effect for small font sizes */
			imageCalculator("Max", "inner_shadow","label_mask");
			run("Select None");
			run("Invert");  /* Create an image that can be subtracted - this works better for color than Min */
		}
		if (isOpen("shadow") && shadowDarkness>0)		
			imageCalculator("Subtract", flatImage,"shadow");
		else if (isOpen("shadow") && shadowDarkness<0)		
			imageCalculator("Add", flatImage,"shadow");
		run("Select None");
		/* Create outline around text */
		selectWindow(flatImage);
		getSelectionFromMask("label_mask");
		getSelectionBounds(maskX, maskY, null, null);
		outlineStrokeOffset = minOf(round(shadowDisp/2), round(maxOf(0,(outlineStroke/2)-1)));
		setSelectionLocation(maskX+outlineStrokeOffset, maskY+outlineStrokeOffset); /* Offset selection to create shadow effect */
		run("Enlarge...", "enlarge=[outlineStroke] pixel");
		setBackgroundFromColorName(outlineColor);
		run("Clear", "slice");
		outlineStrokeOffsetMod = outlineStrokeOffset/2;
		run("Enlarge...", "enlarge=[outlineStrokeOffsetMod] pixel");
		run("Gaussian Blur...", "sigma=[outlineStrokeOffsetMod]");
		run("Select None");
		/* Create text */
		getSelectionFromMask("label_mask");
		setBackgroundFromColorName(fontColor);
		run("Clear", "slice");
		run("Select None");
		if (isOpen("antiAliased")) {
			if (fontInt>=outlineInt) imageCalculator("Min",flatImage,"antiAliased");
			else imageCalculator("Max",flatImage,"antiAliased");
		}
		/* Create inner shadow or glow if requested */
		if (isOpen("inner_shadow") && innerShadowDarkness>0)
			imageCalculator("Subtract", flatImage,"inner_shadow");
		else if (isOpen("inner_shadow") && innerShadowDarkness<0)
			imageCalculator("Add", flatImage,"inner_shadow");
	
		if (labelRest=="Yes" && startsWith(overWrite,"Destructive")) {
			for (j=1; j<remSlices+1; j++) {
				setSlice(sliceNumber + j);
				if (isOpen("shadow") && shadowDarkness>0)		
				imageCalculator("Subtract", flatImage,"shadow");
				else if (isOpen("shadow") && shadowDarkness<0)		
					imageCalculator("Add", flatImage,"shadow");
				run("Select None");
				/* Create outline around text */
				selectWindow(flatImage);
				getSelectionFromMask("label_mask");
				getSelectionBounds(maskX, maskY, null, null);
				outlineStrokeOffset = minOf(round(shadowDisp/2), round(maxOf(0,(outlineStroke/2)-1)));
				setSelectionLocation(maskX+outlineStrokeOffset, maskY+outlineStrokeOffset); /* Offset selection to create shadow effect */
				run("Enlarge...", "enlarge=[outlineStroke] pixel");
				setBackgroundFromColorName(outlineColor);
				run("Clear", "slice");
				outlineStrokeOffsetMod = outlineStrokeOffset/2;
				run("Enlarge...", "enlarge=[outlineStrokeOffsetMod] pixel");
				run("Gaussian Blur...", "sigma=[outlineStrokeOffsetMod]");
				run("Select None");
				/* Create text */
				getSelectionFromMask("label_mask");
				setBackgroundFromColorName(fontColor);
				run("Clear", "slice");
				run("Select None");
				if (isOpen("antiAliased")) {
					if (fontInt>=outlineInt) imageCalculator("Min",flatImage,"antiAliased");
					else imageCalculator("Max",flatImage,"antiAliased");
				}
				/* Create inner shadow or glow if requested */
				if (isOpen("inner_shadow") && innerShadowDarkness>0)
					imageCalculator("Subtract", flatImage,"inner_shadow");
				else if (isOpen("inner_shadow") && innerShadowDarkness<0)
					imageCalculator("Add", flatImage,"inner_shadow");
			}
		}
	}
	closeImageByTitle("shadow");
	closeImageByTitle("inner_shadow");
	closeImageByTitle("label_mask");
	closeImageByTitle("antiAliased");
	selectWindow(flatImage);
	if (startsWith(overWrite, "New"))  {
		if ((lastIndexOf(originalImage,"."))>0)  flatImageNameWOExt = unCleanLabel(substring(flatImage, 0, lastIndexOf(flatImage,".")));
		else flatImageNameWOExt = unCleanLabel(flatImage);
		rename(flatImageNameWOExt + "+text");
	}
	restoreSettings;
	setBatchMode("exit & display");
	if (selectionExists==1 || textLocChoice == "Center of New Selection") {
		if (restoreSelection==true) makeRectangle(orSelEX, orSelEY, orSelEWidth, orSelEHeight);
	}
	setSlice(sliceNumber);
	showStatus("Fancy Text Labels Finished");
	run("Collect Garbage"); 
}
	/* 
	( 8(|)   ( 8(|)  Functions  ( 8(|)  ( 8(|)
	*/
	function cleanLabel(string) {
		string= replace(string, "\\^2", fromCharCode(178)); /* superscript 2 */
		string= replace(string, "\\^3", fromCharCode(179)); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, "\\^-1", fromCharCode(0x207B) + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-2", fromCharCode(0x207B) + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "\\^-^1", fromCharCode(0x207B) + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-^2", fromCharCode(0x207B) + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "(?<![A-Za-z0-9])u(?=m)", fromCharCode(181)); /* micron units */
		string= replace(string, "\\b[aA]ngstrom\\b", fromCharCode(197)); /* ?ngstr?m unit symbol */
		string= replace(string, "  ", " "); /* Replace double spaces with single spaces */
		string= replace(string, "_", fromCharCode(0x2009)); /* Replace underlines with thin spaces */
		string= replace(string, "px", "pixels"); /* Expand pixel abbreviation */
		string= replace(string, "sigma", fromCharCode(0x03C3)); /* sigma for tight spaces */
		return string;
	}
	function closeImageByTitle(windowTitle) {  /* Cannot be used with tables */
        if (isOpen(windowTitle)) {
		selectWindow(windowTitle);
        close();
		}
	}
	function convertToSymbols(string) {
		/* v180612 first version */
		string= replace(string, "symbol-alpha", fromCharCode(0x03B1));
		string= replace(string, "symbol-beta", fromCharCode(0x03B2)); /* ß */
		string= replace(string, "symbol-gamma", fromCharCode(0xD835)); /* MATHEMATICAL BOLD SMALL GAMMA */
		string= replace(string, "symbol-delta", fromCharCode(0x1E9F)); /*  SMALL LETTER DELTA */
		string= replace(string, "symbol-Delta", fromCharCode(0x0394)); /* ?  Upper case LETTER DELTA */
		string= replace(string, "symbol-epsilon", fromCharCode(0x03B5)); /* GREEK SMALL LETTER EPSILON */
		string= replace(string, "symbol-zeta", fromCharCode(0x03B6)); /* GREEK SMALL LETTER ZETA */
		string= replace(string, "symbol-theta", fromCharCode(0x03B8)); /* GREEK SMALL LETTER THETA */
		string= replace(string, "symbol-iota", fromCharCode(0x03B9)); /* GREEK SMALL LETTER IOTA */
		string= replace(string, "symbol-kappa", fromCharCode(0x03BA)); /* GREEK SMALL LETTER KAPPA */
		string= replace(string, "symbol-lambda", fromCharCode(0x03BB)); /* GREEK SMALL LETTER LAMDA */
		string= replace(string, "symbol-mu", fromCharCode(0x03BC)); /* µ GREEK SMALL LETTER MU */
		string= replace(string, "symbol-nu", fromCharCode(0x03BD)); /*  GREEK SMALL LETTER NU */
		string= replace(string, "symbol-xi", fromCharCode(0x03BE)); /* GREEK SMALL LETTER XI */
		string= replace(string, "symbol-pi", fromCharCode(0x03C0)); /* GREEK SMALL LETTER Pl */
		string= replace(string, "symbol-rho", fromCharCode(0x03C1)); /* GREEK SMALL LETTER RHO */
		string= replace(string, "symbol-sigma", fromCharCode(0x03C3)); /* GREEK SMALL LETTER SIGMA */
		string= replace(string, "symbol-phi", fromCharCode(0x03C6)); /* GREEK SMALL LETTER PHI */
		string= replace(string, "symbol-omega", fromCharCode(0x03C9)); /* GREEK SMALL LETTER OMEGA */
		string= replace(string, "symbol-eta", fromCharCode(0x03B7)); /*  GREEK SMALL LETTER ETA */
		string= replace(string, "symbol-sub2", fromCharCode(0x2082)); /*  subscript 2 */
		string= replace(string, "symbol-sub3", fromCharCode(0x2083)); /*  subscript 3 */
		string= replace(string, "symbol-sub4", fromCharCode(0x2084)); /*  subscript 4 */
		string= replace(string, "symbol-sub5", fromCharCode(0x2085)); /*  subscript 5 */
		string= replace(string, "symbol-sup2", fromCharCode(0x00B2)); /*  superscript 2 */
		string= replace(string, "symbol-sup3", fromCharCode(0x00B3)); /*  superscript 3 */
		string= replace(string, "degreeC", fromCharCode(181)); /* micron units */
		return string;
	}
	function getSelectionFromMask(selection_Mask){
		tempTitle = getTitle();
		selectWindow(selection_Mask);
		run("Create Selection"); /* Selection inverted perhaps because the mask has an inverted LUT? */
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
	function getHexColorFromRGBArray(colorNameString) {
		colorArray = getColorArrayFromColorName(colorNameString);
		 r = toHex(colorArray[0]); g = toHex(colorArray[1]); b = toHex(colorArray[2]);
		 hexName= "#" + ""+pad(r) + ""+pad(g) + ""+pad(b);
		 return hexName;
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
	function unCleanLabel(string) { 
	/* v161104 This function replaces special characters with standard characters for file system compatible filenames */
	/* mod 041117 to remove spaces as well */
		string= replace(string, fromCharCode(178), "\\^2"); /* superscript 2 */
		string= replace(string, fromCharCode(179), "\\^3"); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, fromCharCode(0x207B) + fromCharCode(185), "\\^-1"); /* superscript -1 */
		string= replace(string, fromCharCode(0x207B) + fromCharCode(178), "\\^-2"); /* superscript -2 */
		string= replace(string, fromCharCode(181), "u"); /* micron units */
		string= replace(string, fromCharCode(197), "Angstrom"); /* Ångström unit symbol */
		string= replace(string, fromCharCode(0x2009) + fromCharCode(0x00B0), "deg"); /* replace thin spaces deg */
		string= replace(string, fromCharCode(0x2009), "_"); /* Replace thin spaces  */
		string= replace(string, " ", "_"); /* Replace spaces - these can be a problem with image combination */
		string= replace(string, "_\\+", "\\+"); /* Clean up autofilenames */
		string= replace(string, "\\+\\+", "\\+"); /* Clean up autofilenames */
		string= replace(string, "__", "_"); /* Clean up autofilenames */
		return string;
	}