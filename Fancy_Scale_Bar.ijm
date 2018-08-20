macro "Fancy Scale Bar" {
/* Original code by Wayne Rasband, improved by Frank Sprenger and deposited on the ImageJ mailing server: (http:imagej.588099.n2.nabble.com/Overlay-Scalebar-Plugins-td6380378.html#a6394996). KS added choice of font size, scale bar height, + any position for scale bar and some options that allow to set the image calibration (only for overlay, not in Meta data). Kees Straatman, CBS, University of Leicester, May 2011
Grotesquely modified by Peter J. Lee NHMFL to produce shadow and outline effects.
6/22/16-7/7/16  Add unit override option 7/13/2016 syntax updated 7/28/2016.
Centered scale bar in new selection 8/9/2016 and tweaked manual location 8/10/2016.
v161012 adds unified ASC function list and add 100 µm diameter human hair. v161031 adds "glow" option and sharpens shadow/glow edge.
v161101 minor fixes v161104 now works with images other than 8-bit too.
v161105 improved offset guesses.
v180108 set outline to at least 1 pixel if desired, updated functions and fixed typos.
v180611 replaced run("Clear" with run("Clear", "slice").
v180613 works for multiple slices.
v180711 minor corner positioning tweaks for large images.
v180722 allows any system font to be used. v180723 Adds some favorite fonts to top of list (if available).
v180730 rounds the scale bar width guess to two figures.
*/
	saveSettings(); /* To restore settings at the end */
	setBatchMode(true);
	if (is("Inverting LUT")==true) run("Invert LUT"); /* more effectively removes Inverting LUT */
	selEType = selectionType; 
	if (selEType>=0)
		getSelectionBounds(selEX, selEY, selEWidth, selEHeight);
	originalImage = getTitle();
	originalImageDepth = bitDepth();
	checkForUnits();
	getDimensions(imageWidth, imageHeight, channels, slices, frames);
	startSliceNumber = getSliceNumber();
	remSlices = slices-startSliceNumber;
	imageDims = imageHeight+imageWidth;
	sbHeight = round(imageDims / 320); /* default scale bar height */
	if (sbHeight < 2) sbHeight = 2; /*  set minimum default bar height as 2 pixels */
	getPixelSize(selectedUnit, pixelWidth, pixelHeight);
	lcf=(pixelWidth+pixelHeight)/2;
	lcfFactor=1/lcf;
	sbFontSize = round(imageDims/60);
	if (sbFontSize < 12) sbFontSize = 12; /* set minimum default font size as 12 */
	dOutS = 6; /* default outline stroke: % of font size */
	dShO = 8;  /* default outer shadow drop: % of font size */
	dIShO = 4; /* default inner shadow drop: % of font size */
	sF = getScaleFactor(selectedUnit);
	if (sF!=0) {
		nSF = newArray(1,sF/(1E-2),sF/(1E-3),sF/(1E-6),sF/(1E-6),sF/(1E-9),sF/(1E-10),sF/(1E-12), sF/(2.54E-2), sF/(1E-4));
		overrideUnitChoice = newArray(selectedUnit, "cm", "mm", "µm", "microns", "nm", "Å", "pm", "inches", "human hairs");
	}
	if (selEType>=0) {	
		sbWidth = lcf*selEWidth;
		sbDP = autoCalculateDecPlacesFromValueOnly(sbWidth);
		sbWidth = d2s(sbWidth, sbDP);
	}
	// else sbWidth = round(lcf*imageWidth/5);
	else sbWidth = lcf*imageWidth/5;
	selOffsetX = round(imageWidth/120);
	// if (selOffsetX>20) selOffsetX = 20;
	if (selOffsetX<4) selOffsetX = 4;
	selOffsetY = round(maxOf(imageHeight/180, sbHeight + sbFontSize/6));
	// if (selOffsetY>20) selOffsetY = 20;
	if (selOffsetY<4) selOffsetY = 4;
	run("Set Scale...", "distance=[lcfFactor] known=1 pixel=1 selectedUnit=[selectedUnit]");
	indexSBWidth = parseInt(substring(d2s(sbWidth, -1),indexOf(d2s(sbWidth, -1), "E")+1));
	dpSB = maxOf(0,1 - indexSBWidth);
	sbWidth = pow(10,indexSBWidth-1)*(round((sbWidth)/pow(10,indexSBWidth-1)));
	Dialog.create("Scale Bar Parameters");
		Dialog.addNumber("Length of scale bar in " + selectedUnit + "s:", sbWidth, dpSB, 10, selectedUnit);
		if (sF!=0) {
			newUnit = newArray(""+selectedUnit+" Length x1", "cm \(Length x"+nSF[1]+"\)","mm \(Length x"+nSF[2]+"\)","µm \(Length x"+nSF[3]+"\)","microns \(Length x"+nSF[4]+"\)", "nm \(Length x"+nSF[5]+"\)", "Å \(Length x"+nSF[6]+"\)", "pm \(Length x"+nSF[7]+"\)", "inches \(Length x"+nSF[8]+"\)", "human hair \(Length x"+nSF[9]+"\)");
			Dialog.addChoice("Override unit with new choice?", newUnit, newUnit[0]);
		}
		Dialog.addNumber("Height of scale bar;", sbHeight);
		if (originalImageDepth==24)
			colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray", "red", "pink", "green", "blue", "yellow", "orange", "garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "gray_modern", "green_dark_modern", "green_modern", "orange_modern", "pink_modern", "purple_modern", "red_N_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern"); 
		else colorChoice = newArray("white", "black", "light_gray", "gray", "dark_gray");
		Dialog.addChoice("Scale bar and text color:", colorChoice, colorChoice[0]);
		if (selEType>=0) {
			locChoice = newArray("Top Left", "Top Right", "Bottom Left", "Bottom Right", "At Center of New Selection", "At Selection"); 
			Dialog.addChoice("Scale bar position:", locChoice, locChoice[5]); 
		}
		else {
			locChoice = newArray("Top Left", "Top Right", "Bottom Left", "Bottom Right", "At Center of New Selection"); 
			Dialog.addChoice("Scale bar position:", locChoice, locChoice[3]); 
		}
		Dialog.addCheckbox("Hide text", false);
		Dialog.addNumber("Font size:", sbFontSize);
		Dialog.addNumber("X Offset from Edge in Pixels \(applies to corners only\)", selOffsetX,0,1,"pixels");
		Dialog.addNumber("Y Offset from Edge in Pixels \(applies to corners only\)", selOffsetY,0,1,"pixels");
		fontStyleChoice = newArray("bold", "bold antialiased", "italic", "italic antialiased", "bold italic", "bold italic antialiased", "unstyled");
		Dialog.addChoice("Font style:", fontStyleChoice, fontStyleChoice[1]);
		fontNameChoice = getFontChoiceList();
		Dialog.addChoice("Font name:", fontNameChoice, fontNameChoice[0]);
		Dialog.addNumber("Outline Stroke:", dOutS,0,3,"% of font size");
		Dialog.addChoice("Outline (background) color:", colorChoice, colorChoice[1]);
		Dialog.addNumber("Shadow Drop: ±", dShO,0,3,"% of font size");
		Dialog.addNumber("Shadow Displacement Right: ±", dShO,0,3,"% of font size");
		Dialog.addNumber("Shadow Gaussian Blur:", floor(0.75*dShO),0,3,"% of font size");
		Dialog.addNumber("Shadow Darkness \(darkest = 100%\):", 75,0,3,"% \(negative = glow\)");
		Dialog.addChoice("Shadow color \(overrides darkness in overlay\):", colorChoice, colorChoice[4]);
		Dialog.addMessage("The following \"Inner Shadow\" options do not change the Overlay scale bar");
		Dialog.addNumber("Inner Shadow Drop: ±", dIShO,0,1,"% of font size");
		Dialog.addNumber("Inner Displacement Right: ±", dIShO,0,1,"% of font size");
		Dialog.addNumber("Inner Shadow Mean Blur:",floor(dIShO/2),1,2,"% of font size");
		Dialog.addNumber("Inner Shadow Darkness \(darkest = 100%\):", 20,0,3,"% \(negative = glow\)");
		overwriteChoice = newArray("Destructive overwrite    ", "New Image", "Overlay");
		if (Overlay.size==0) overwriteChoice = newArray("Destructive overwrite", "New image", "Add overlay");
		else overwriteChoice = newArray("Destructive overwrite", "New image", "Add overlay", "Replace overlay");
		Dialog.addRadioButtonGroup("Output:__________________________ ", overwriteChoice, 2, 2, overwriteChoice[1]);
		if (remSlices>0) Dialog.addRadioButtonGroup("Add the same labels to this and next " + remSlices + " slices? ", newArray("Yes", "No"), 1, 2, "No");	
	Dialog.show();
		selLengthInUnits = Dialog.getNumber;
		if (sF!=0) overrideUnit = Dialog.getChoice;
		selHeight = Dialog.getNumber;
		selColor = Dialog.getChoice;
		selPos = Dialog.getChoice;
		if (Dialog.getCheckbox==true) ht=1;
		else ht=0;
		fontSize =  Dialog.getNumber;
		selOffsetX = Dialog.getNumber;
		selOffsetY = Dialog.getNumber;
		fontStyle = Dialog.getChoice;
		fontName = Dialog.getChoice;
		outlineStroke = Dialog.getNumber;
		outlineColor = Dialog.getChoice;
		shadowDrop = Dialog.getNumber;
		shadowDisp = Dialog.getNumber;
		shadowBlur = Dialog.getNumber;
		shadowDarkness = Dialog.getNumber;
		shadowColor = Dialog.getChoice;
		innerShadowDrop = Dialog.getNumber;
		innerShadowDisp = Dialog.getNumber;
		innerShadowBlur = Dialog.getNumber;
		innerShadowDarkness = Dialog.getNumber;
		overWrite = Dialog.getRadioButton;
		if (remSlices>0) labelRest = Dialog.getRadioButton;
		else labelRest = "No";
		if (sF!=0) { 
			oU = indexOfArray(newUnit, overrideUnit);
			oSF = nSF[oU];
			selectedUnit = overrideUnitChoice[oU];
		}

		selLengthInPixels = selLengthInUnits / lcf;
		if (sF!=0) selLengthInUnits *= oSF; /* now safe to change units */
		
		negAdj = 0.5;  /* negative offsets appear exaggerated at full displacement */
		if (shadowDrop<0) shadowDrop *= negAdj;
		if (shadowDisp<0) shadowDisp *= negAdj;
		if (shadowBlur<0) shadowBlur *= negAdj;
		if (innerShadowDrop<0) innerShadowDrop *= negAdj;
		if (innerShadowDisp<0) innerShadowDisp *= negAdj;
		if (innerShadowBlur<0) innerShadowBlur *= negAdj;
		
		fontFactor = fontSize/100;
		if (outlineStroke!=0) outlineStroke = maxOf(1, round(fontFactor * outlineStroke)); /* if some outline is desired set to at least one pixel */
		if (shadowDrop!=0) shadowDrop = maxOf(1, round(fontFactor * shadowDrop));
		if (shadowDisp!=0) shadowDisp = maxOf(1, round(fontFactor * shadowDisp));
		if (shadowBlur!=0) shadowBlur = maxOf(1, round(fontFactor * shadowBlur));
		innerShadowDrop = floor(fontFactor * innerShadowDrop);
		innerShadowDisp = floor(fontFactor * innerShadowDisp);
		innerShadowBlur = floor(fontFactor * innerShadowBlur);
		
	if (selOffsetX<(shadowDisp+shadowBlur+1)) selOffsetX += (shadowDisp+shadowBlur+1);  /* make sure shadow does not run off edge of image */
	if (selOffsetY<(shadowDrop+shadowBlur+1)) selOffsetY += (shadowDrop+shadowBlur+1);
	
	if (fontStyle=="unstyled") fontStyle="";

	if (selPos == "Top Left") {
		selEX = selOffsetX;
		selEY = selOffsetY; // + fontSize;
	} else if (selPos == "Top Right") {
		selEX = imageWidth - selLengthInPixels - selOffsetX;
		selEY = selOffsetY;// + fontSize;
	} else if (selPos == "Bottom Left") {
		selEX = selOffsetX;
		selEY = imageHeight - selHeight - (selOffsetY); 
	} else if (selPos == "Bottom Right") {
		selEX = imageWidth - selLengthInPixels - selOffsetX;
		selEY = imageHeight - selHeight - selOffsetY; 
	} else if (selPos=="At Center of New Selection"){
		if (is("Batch Mode")==true) setBatchMode("exit & display");	/* toggle batch mode off */
		run("Select None");
		setTool("rectangle");
		title="position";
		msg = "draw a box in the image where you want the scale bar to be centered";
		waitForUser(title, msg);
		getSelectionBounds(newSelEX, newSelEY, newSelEWidth, newSelEHeight);
		selEX = newSelEX + round((newSelEWidth/2) - selLengthInPixels/2);
		selEY = newSelEY + round(newSelEHeight/2);
		if (is("Batch Mode")==false) setBatchMode(true);	/* toggle batch mode back on */
	} else if (selPos=="At Selection")
		selEY += selEHeight;  /*  assume you want the annotation relative to the bottom of the selection */
	
	 /*  edge limits - assume intent is not to annotate edge objects */
	maxSelEY = imageHeight - round(selHeight/2) + selOffsetY;
	  if (selEY>maxSelEY) selEY = maxSelEY;
	if (selEY<selOffsetY) selEY = selOffsetY;
	maxSelEX = imageWidth - selLengthInPixels + selOffsetX;
	  if (selEX>maxSelEX) selEX = maxSelEX;
	if (selEX<selOffsetX) selEX = selOffsetX;
	
	 /* Determine label size and location */
	if (selEY<=1.5*fontSize)
			textYcoord = selEY + 2*selHeight + fontSize;
	else textYcoord = selEY - selHeight;
	selLengthLabel = removeTrailingZerosAndPeriod(toString(selLengthInUnits));
	label = selLengthLabel + " " + selectedUnit;
	// stop overrun on scale bar by label
	if (getStringWidth(label)>(selLengthInPixels/1.2))
		fontSize=round(fontSize*(selLengthInPixels/(1.2*(getStringWidth(label)))));
	setFont(fontName,fontSize, fontStyle);
	textOffset = round((selLengthInPixels - getStringWidth(label))/2);
	finalLabel = label;
	finalFontSize = fontSize;
	finalLabelX = selEX + textOffset;
	finalLabelY = textYcoord;
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	setColorFromColorName("white"); // function
	fillRect(selEX, selEY, selLengthInPixels, selHeight);
	if (ht==0) writeLabel("white");
	setThreshold(0, 128);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	if (endsWith(overWrite,"verlay")) {
		if (startsWith(overWrite,"Replace")) Overlay.remove;
		selColorHex = getHexColorFromRGBArray(selColor);
		outlineColorHex = getHexColorFromRGBArray(outlineColor);
		shadowColorHex = getHexColorFromRGBArray(shadowColor);
		if (ht==1){
			makeRectangle(selEX, selEY, selLengthInPixels, selHeight); 	
			run("Add Selection...", "stroke=" + outlineColorHex + " width=" + outlineStroke+" fill=" + selColorHex);
			Overlay.add;
		}
		else {
			selectWindow(originalImage);
			if (slices==1) remSlices =1;
			for (o=1; o<remSlices+1; o++) {
				if (slices>1) setSlice(startSliceNumber + o);
				else setSlice(1);
				/* Create shadow layer */
				run("Select None");
				getSelectionFromMask("label_mask");
				getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
				setSelectionLocation(selMaskX+shadowDisp, selMaskY+2*shadowDrop);
				run("Enlarge...", "enlarge=[outlineStroke] pixel"); /* shadow needs to be bigger than outline */
				Overlay.addSelection(shadowColorHex, outlineStroke, shadowColorHex);
				/* Create outline layer */
				run("Select None");
				getSelectionFromMask("label_mask");
				run("Enlarge...", "enlarge=[outlineStroke] pixel");
				getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
				setSelectionLocation(selMaskX-outlineStroke, selMaskY+(2*outlineStroke));
				Overlay.addSelection(outlineColorHex,outlineStroke,outlineColorHex);
				run("Select None");
				makeRectangle(selEX, selEY, selLengthInPixels, selHeight);
				Overlay.addSelection("", 0, selColorHex);
				setColorFromColorName(selColor);
				Overlay.drawString(finalLabel, finalLabelX, finalLabelY); 
				run("Select None");
				Overlay.show;
				if (labelRest=="No") o = remSlices+1;
			}
		}
	}
	else {
		/* Create drop shadow if desired */
		if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0)
			createShadowDropFromMask7("label_mask", shadowDrop, shadowDisp, shadowBlur, shadowDarkness, outlineStroke);
		/* Create inner shadow if desired */
		if (innerShadowDrop!=0 || innerShadowDisp!=0 || innerShadowBlur!=0)
			createInnerShadowFromMask6("label_mask",innerShadowDrop, innerShadowDisp, innerShadowBlur, innerShadowDarkness);
		if (startsWith(overWrite,"Destructive overwrite")) {
			if (labelRest=="No") frames = 1;
			else frames = remSlices +1;
			for (j=0; j<frames; j++) {
				if (isOpen("shadow") && shadowDarkness>0) imageCalculator("Subtract", originalImage,"shadow");
				if (isOpen("shadow") && shadowDarkness<0) imageCalculator("Add", originalImage,"shadow"); /* glow */
				run("Select None");
				getSelectionFromMask("label_mask");
				run("Enlarge...", "enlarge=[outlineStroke] pixel");
				setBackgroundFromColorName(outlineColor);
				run("Clear", "slice");
				run("Select None");
				getSelectionFromMask("label_mask");
				setBackgroundFromColorName(selColor);
				run("Clear", "slice");
				run("Select None");
				if (ht==0) writeLabel("selColor"); /* restore antialiasing */
				if (isOpen("inner_shadow")) imageCalculator("Subtract", originalImage,"inner_shadow");
				if (labelRest=="Yes") run("Next Slice [>]");
			}
		}
		else {
			if (labelRest=="No") frames = 1;
			else frames = remSlices +1;
			for (j=0; j<frames; j++) {
				if (isOpen("shadow")&& shadowDarkness>0) imageCalculator("Subtract create", originalImage,"shadow");
				else if (isOpen("shadow")&& shadowDarkness<0) imageCalculator("Add create", originalImage,"shadow"); /* glow */
				else imageCalculator("Copy create", originalImage, originalImage);  /* even if you don't want a shadow you may want an outline */
				/* apply outline around label */
				run("Select None");
				getSelectionFromMask("label_mask");
				run("Enlarge...", "enlarge=[outlineStroke] pixel");
				setBackgroundFromColorName(outlineColor);
				run("Clear", "slice");
				run("Select None");
				/* Now the actual label */
				getSelectionFromMask("label_mask");
				setBackgroundFromColorName(selColor);
				run("Clear", "slice");
				run("Select None");
				/* Now add the inner shadow to provide some depth */
				if (isOpen("inner_shadow") && innerShadowDarkness>0)
					imageCalculator("Subtract", "Result of " + originalImage,"inner_shadow");
				if (isOpen("inner_shadow") && innerShadowDarkness<0)
					imageCalculator("Add", "Result of " + originalImage,"inner_shadow"); /* glow */
				/* Now rename the copy */
				if (lastIndexOf(originalImage,".")>0)
					originalImageNameWOExt = substring(originalImage, 0, lastIndexOf(originalImage,"."));
				else originalImageNameWOExt = originalImage;
				rename(unCleanLabel(originalImageNameWOExt + "\+scale"));
				selectWindow(originalImage);
				if (labelRest=="Yes") run("Next Slice [>]");
			}
		}
	}
	closeImageByTitle("shadow");
	closeImageByTitle("inner_shadow");
	closeImageByTitle("label_mask");
	restoreSettings();
	setSlice(startSliceNumber);
	setBatchMode("exit & display"); /* exit batch mode */
	showStatus("Fancy Scale Bar Added");
}
	/*
		( 8(|)  ( 8(|)  Functions	@@@@@:-)	@@@@@:-)
	*/
	function autoCalculateDecPlacesFromValueOnly(value){ /* Note this version is different from the one used for ramp legends */
		valueSci = d2s(value, -1);
		iExp = indexOf(valueSci, "E");
		valueExp = parseInt(substring(valueSci, iExp+1));
		if (valueExp>=2) dP = 0;
		if (valueExp<2) dP = 2-valueExp;
		if (valueExp<-5) dP = -1; /* Scientific Notation */
		if (valueExp>=4) dP = -1; /* Scientific Notation */
		return dP;
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
	function checkForUnits() {  /* With CZSEM check Version
		/* v161108 (adds inches to possible reasons for checking calibration)
			This version requires these functions:
			checkForPlugin, setScaleFromCZSemHeader.
			v180820 Checks for CZ header before offering to use it. Tweaked dialog messages.
		*/
		getPixelSize(unit, pixelWidth, pixelHeight);
		if (pixelWidth!=pixelHeight || pixelWidth==1 || unit=="" || unit=="inches"){
			Dialog.create("Scale issues");
			Dialog.addMessage("Unit asymmetry, pixel units or dpi remnants.\nPixel width = " + pixelWidth + " \nPixel height = " + pixelHeight + "\nUnit = " + unit);
			if (matches(getInfo("image.filename"),".*[tT][iI][fF].*") && (checkForPlugin("tiff_tags.jar"))) {
				tag = call("TIFF_Tags.getTag", getDirectory("image")+getTitle, 34118);
				if (indexOf(tag, "Image Pixel Size = ")>0) {
					Dialog.addCheckbox("Do you want to try and import scale from the CZ SEM tag?", true);
					Dialog.show();
					setCZScale = Dialog.getCheckbox;
					if (setCZScale) { /* Based on the macro here: https://rsb.info.nih.gov/ij/macros/SetScaleFromTiffTag.txt */
						setScaleFromCZSemHeader();
						getPixelSize(unit, pixelWidth, pixelHeight);
						if (pixelWidth!=pixelHeight || pixelWidth==1 || unit=="" || unit=="inches") setCZScale=false;
					}
					if(!setCZScale) {
						Dialog.create("Manually set scale");
						Dialog.addCheckbox("pixelWidth = " + pixelWidth + ": Do you want to define units for this image?", true);
						Dialog.show();
						setScale = Dialog.getCheckbox;
						if (setScale)
						run("Set Scale...");
					}
				}
			}
			else if (pixelWidth!=pixelHeight || pixelWidth==1 || unit=="" || unit=="inches"){
				Dialog.create("Still no standard units");
				Dialog.addMessage("Pixel width = "+pixelsWidth+"\nPixel height = "+pixelsHeight+"/nUnit = "+unit);
				Dialog.addCheckbox("Unit asymmetry, pixel units or dpi remnants; do you want to define units for this image?", true);
				Dialog.show();
				setScale = Dialog.getCheckbox;
				if (setScale)
					run("Set Scale...");
			}
		}
	}
	function closeImageByTitle(windowTitle) {  /* Cannot be used with tables */
		if (isOpen(windowTitle)) {
		selectWindow(windowTitle);
		close();
		}
	}
	function createInnerShadowFromMask6(mask,iShadowDrop, iShadowDisp, iShadowBlur, iShadowDarkness) {
		/* Requires previous run of: originalImageDepth = bitDepth();
		because this version works with different bitDepths
		v161115 calls four variables: drop, displacement blur and darkness
		v180627 and calls mask label */
		showStatus("Creating inner shadow for labels . . . ");
		newImage("inner_shadow", "8-bit white", imageWidth, imageHeight, 1);
		getSelectionFromMask(mask);
		setBackgroundColor(0,0,0);
		run("Clear Outside");
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX-iShadowDisp, selMaskY-iShadowDrop);
		setBackgroundColor(0,0,0);
		run("Clear Outside");
		getSelectionFromMask(mask);
		expansion = abs(iShadowDisp) + abs(iShadowDrop) + abs(iShadowBlur);
		if (expansion>0) run("Enlarge...", "enlarge=[expansion] pixel");
		if (iShadowBlur>0) run("Gaussian Blur...", "sigma=[iShadowBlur]");
		run("Unsharp Mask...", "radius=0.5 mask=0.2"); /* A tweak to sharpen the effect for small font sizes */
		imageCalculator("Max", "inner_shadow",mask);
		run("Select None");
		/* The following are needed for different bit depths */
		if (originalImageDepth==16 || originalImageDepth==32) run(originalImageDepth + "-bit");
		run("Enhance Contrast...", "saturated=0 normalize");
		run("Invert");  /* Create an image that can be subtracted - this works better for color than Min */
		divider = (100 / abs(iShadowDarkness));
		run("Divide...", "value=[divider]");
	}
	function createShadowDropFromMask7(mask, oShadowDrop, oShadowDisp, oShadowBlur, oShadowDarkness, oStroke) {
		/* Requires previous run of: originalImageDepth = bitDepth();
		because this version works with different bitDepths
		v161115 calls five variables: drop, displacement blur and darkness
		v180627 adds mask label to variables	*/
		showStatus("Creating drop shadow for labels . . . ");
		newImage("shadow", "8-bit black", imageWidth, imageHeight, 1);
		getSelectionFromMask(mask);
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX + oShadowDisp, selMaskY + oShadowDrop);
		setBackgroundColor(255,255,255);
		if (oStroke>0) run("Enlarge...", "enlarge=[oStroke] pixel"); /* Adjust shadow size so that shadow extends beyond stroke thickness */
		run("Clear");
		run("Select None");
		if (oShadowBlur>0) {
			run("Gaussian Blur...", "sigma=[oShadowBlur]");
			run("Unsharp Mask...", "radius=[oShadowBlur] mask=0.4"); /* Make Gaussian shadow edge a little less fuzzy */
		}
		/* Now make sure shadow or glow does not impact outline */
		getSelectionFromMask(mask);
		if (oStroke>0) run("Enlarge...", "enlarge=[oStroke] pixel");
		setBackgroundColor(0,0,0);
		run("Clear");
		run("Select None");
		/* The following are needed for different bit depths */
		if (originalImageDepth==16 || originalImageDepth==32) run(originalImageDepth + "-bit");
		run("Enhance Contrast...", "saturated=0 normalize");
		divider = (100 / abs(oShadowDarkness));
		run("Divide...", "value=[divider]");
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
		else if (colorName == "green") cA = newArray(0,255,0);
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
	function writeLabel(labelColor){
		setColorFromColorName(labelColor);
		drawString(finalLabel, finalLabelX, finalLabelY); 
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
	function getScaleFactor(inputUnit){
		/* v171024 */
		if (inputUnit=="km") scaleFactor = 1e3;
		else if (inputUnit=="m") scaleFactor = 1;
		else if (inputUnit=="cm") scaleFactor = 1E-2;
		else if (inputUnit=="mm") scaleFactor = 1E-3;
		else if (inputUnit=="um") scaleFactor = 1E-6;
		else if (inputUnit==(fromCharCode(181)+"m")) scaleFactor = 1E-6;
		else if (inputUnit=="µm") scaleFactor =  1E-6;
		else if (inputUnit=="microns") scaleFactor =  1E-6; /* Preferred by Bio-Formats over µm but beware: Bio-Formats import of Ziess >1024 wide is incorrect */
		else if (inputUnit=="nm") scaleFactor = 1E-9;
		else if (inputUnit=="A") scaleFactor = 1E-10;
		else if (inputUnit==fromCharCode(197)) scaleFactor = 1E-10;
		else if (inputUnit=="pm") scaleFactor = 1E-12;
		else if (inputUnit=="inches") scaleFactor = 2.54E-2;
		else if (inputUnit=="human hair") scaleFactor = 1E-4; /* https://en.wikipedia.org/wiki/Orders_of_magnitude_(length)#Human_scale */
		else if (inputUnit=="pixels") scaleFactor = 0;
		else restoreExit("No recognized units defined; macro will exit");
		return scaleFactor;
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
		if (!batchMode) setBatchMode(false); /* Return to original batch mode setting */
	}
	function indexOfArray(array, value) {
	   for (i=0; i<lengthOf(array); i++)
          if (array[i]==value) return i;
      return -1;
	}
	function removeTrailingZerosAndPeriod(string) { /* Removes any trailing zeros after a period */
		while (endsWith(string,".0")) string=substring(string,0, lastIndexOf(string, ".0"));
		while(endsWith(string,".")) string=substring(string,0, lastIndexOf(string, "."));
		return string;
	}
	function restoreExit(message){ /* Make a clean exit from a macro, restoring previous settings */
		/* 9/9/2017 added Garbage clean up suggested by Luc LaLonde - LBNL */
		restoreSettings(); /* Restore previous settings before exiting */
		setBatchMode("exit & display"); /* Probably not necessary if exiting gracefully but otherwise harmless */
		run("Collect Garbage");
		exit(message);
	}
	function setScaleFromCZSemHeader() {
	/*	This very simple function sets the scale for SEM images taken with the Carl Zeiss SmartSEM program. It requires the tiff_tags plugin written by Joachim Wesner. It can be downloaded from http://rsbweb.nih.gov/ij/plugins/tiff-tags.html
	 There is an example image available at http://rsbweb.nih.gov/ij/images/SmartSEMSample.tif
	 This is the number of the VERY long tag that stores all the SEM information See original Nabble post by Pablo Manuel Jais: http://imagej.1557.x6.nabble.com/Importing-SEM-images-with-scale-td3689900.html imageJ version: https://rsb.info.nih.gov/ij/macros/SetScaleFromTiffTag.txt
	 v161103 with minor tweaks by Peter J. Lee National High Magnetic Field Laboratory
	 v161108 adds Boolean unit option, v171024 fixes Boolean option.
	 v180820 fixed incorrect message in dialog box. */
	
	/* Gets the path+name of the active image */
	path = getDirectory("image");
	if (path=="") exit ("path not available");
	name = getInfo("image.filename");
	if (name=="") exit ("name not available");
	if (!matches(getInfo("image.filename"),".*[tT][iI][fF].*")) exit("Not a TIFF file \(original Zeiss TIFF file required\)");
	if (!checkForPlugin("tiff_tags.jar")) exit("TIFF Tags plugin missing");
	path = path + name;
	/* 
	Gets the tag, and parses it to get the pixel size information */
	tag = call("TIFF_Tags.getTag", path, 34118);
	i0 = indexOf(tag, "Image Pixel Size = ");
	if (i0!=-1) {
		i1 = indexOf(tag, "=", i0);
		i2 = indexOf(tag, "AP", i1);
		if (i1==-1 || i2==-1 || i2 <= i1+4)
		   exit ("Parsing error! Maybe the file structure changed?");
		text = substring(tag,i1+2,i2-2);
		/* 
		Splits the pixel size in number+unit and sets the scale of the active image */
		splits=split(text);
		setVoxelSize(splits[0], splits[0], 1, splits[1]);
	}
	else if (getBoolean("No CZSem tag found; do you want to continue?")) run("Set Scale...");
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
		string= replace(string, fromCharCode(0x2009) + fromCharCode(0x00B0), "deg"); /* replace thin spaces degrees combination */
		string= replace(string, fromCharCode(0x2009), "_"); /* Replace thin spaces  */
		string= replace(string, " ", "_"); /* Replace spaces - these can be a problem with image combination */
		string= replace(string, "_\\+", "\\+"); /* Clean up autofilenames */
		string= replace(string, "\\+\\+", "\\+"); /* Clean up autofilenames */
		string= replace(string, "__", "_"); /* Clean up autofilenames */
		return string;
	}