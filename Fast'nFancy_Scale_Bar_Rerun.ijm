macro "Fast'nFancy Scale Bar Rerun" {
/* Original code by Wayne Rasband, improved by Frank Sprenger and deposited on the ImageJ mailing server: (http:imagej.588099.n2.nabble.com/Overlay-Scalebar-Plugins-td6380378.html#a6394996).
	KS added choice of font size, scale bar height, + any position for scale bar and some options that allow to set the image calibration (only for overlay, not in Meta data). Kees Straatman, CBS, University of Leicester, May 2011
	Grotesquely modified by Peter J. Lee NHMFL to produce shadow and outline effects.
	This no-option version based on Fancy Scale-Bar v190912
	Uses preferences from the previous run of the full version of Fancy Scale Bar
	Only the creation of new images with bitmap scale bars is supported but redundant code is left in place for ease of later modification
	v200706: changed variable names to match v200706 version of Fancy Scale Bar macro. v210521 whoops should not have changed imageDepth name :-$
	v211022: Updated color choices
	v211025: Updated multiple functions
	v211104: Updated stripKnownExtensionsFromString function    v211112: Again
*/
	macroL = "Fast'nFancy_Scale_Bar_Rerun_v211112f1.ijm";
	requires("1.52i"); /* Utilizes Overlay.setPosition(0) from IJ >1.52i */
	saveSettings(); /* To restore settings at the end */
	micron = getInfo("micrometer.abbreviation");
	if(is("Inverting LUT")) run("Invert LUT"); /* more effectively removes Inverting LUT */
	selEType = selectionType; 
	if (selEType>=0) {
		getSelectionBounds(selEX, selEY, selEWidth, selEHeight);
		if ((selEWidth + selEHeight)<6) selEType=-1; /* Ignore junk selections that are suspiciously small */
	}
	run("Select None");
	activeImage = getTitle();
	imageDepth = bitDepth(); /* keep this name the same for createInnerShadowFromMask6 function */
	checkForUnits();
	getDimensions(imageWidth, imageHeight, channels, slices, frames);
	/* This version only creates new RGB and 8-bit gray images */
	if (channels==3 || imageDepth==32){
		run("RGB Color");
		imageDepth = 24;
		channels = 1;
		rename(stripKnownExtensionFromString(unCleanLabel(activeImage)) + "_RGB");
		close(activeImage);
		activeImage = getTitle();
	}
	else if (imageDepth==16){
		run("8-bit");
		imageDepth = 8;
	}
	sbFontSize = maxOf(20, round((imageHeight+imageWidth)/60)); /* set minimum default font size as 12 */
	getVoxelSize(pixelWidth, pixelHeight, pixelDepth, selectedUnit);
	if (selectedUnit == "um" || selectedUnit == "microns" || selectedUnit == "micron") selectedUnit = micron;
	sF = getScaleFactor(selectedUnit);
	scaleFactors = newArray(1.0000E3,1.0000,1.0000E-2,1.0000E-3,1.0000E-6,1.0000E-9,1.0000E-12);
	metricUnits = newArray("km","m","cm","mm","µm","nm","pm");
	for (i=0; i<5; i++){
		newUnitI = -1;
		if (pixelWidth*imageWidth/5 > 1000) { /* test whether scale bar is likely to be more than 1000 units */
			for (j=0; j<lengthOf(scaleFactors); j++){
				if (scaleFactors[j] > sF){
					newSF = scaleFactors[j];
					newUnitI = j;
				}
				else j = lengthOf(scaleFactors);
			}
		}
		else if (pixelWidth*imageWidth/5 < 1) { /* test whether scale bar is likely to have tiny units */
			for (j=0; j<lengthOf(scaleFactors); j++){
				if (scaleFactors[j] < sF){
					newSF = scaleFactors[j];
					newUnitI = j;
					j = lengthOf(scaleFactors);
				}
			}
		}
		if (newUnitI>=0){
			selectedUnit = metricUnits[newUnitI];
			nPW = pixelWidth*sF/newSF; nPH = pixelHeight*sF/newSF;
			setVoxelSize(nPW, nPH, pixelDepth, selectedUnit);
			getVoxelSize(pixelWidth, pixelHeight, pixelDepth, selectedUnit);
		}
	}
	lcf=(pixelWidth+pixelHeight)/2;
	lcfFactor=1/lcf;
	dOutS = 6; /* default outline stroke: % of font size */
	dShO = 8;  /* default outer shadow drop: % of font size */
	dIShO = 4; /* default inner shadow drop: % of font size */
	if (sF!=0) {
		nSF = newArray(1,sF/(1E-2),sF/(1E-3),sF/(1E-6),sF/(1E-6),sF/(1E-9),sF/(1E-10),sF/(1E-12), sF/(2.54E-2), sF/(1E-4));
		overrideUnitChoice = newArray(selectedUnit, "cm", "mm", "µm", "microns", "nm", "Å", "pm", "inches", "human hairs");
	}
	if (selEType>=0) {	
		sbWidth = lcf*selEWidth;
		sbDP = autoCalculateDecPlacesFromValueOnly(sbWidth);
		sbWidth = d2s(sbWidth, sbDP);
	}
	else sbWidth = lcf*imageWidth/5;
	selOffsetX = maxOf(dOutS,round(imageWidth/120));
	selOffsetY = maxOf(dOutS,round(maxOf(imageHeight/180, 0.35*sbFontSize)));
	if (selOffsetY<4) selOffsetY = 4;
	run("Set Scale...", "distance=&lcfFactor known=1 pixel=1 selectedUnit=&selectedUnit");
	indexSBWidth = parseInt(substring(d2s(sbWidth, -1),indexOf(d2s(sbWidth, -1), "E")+1));
	dpSB = maxOf(0,1 - indexSBWidth);
	sbWidth1SF = round(sbWidth/pow(10,indexSBWidth));
	sbWidth2SF = round(sbWidth/pow(10,indexSBWidth-1));
	preferredSBW = newArray(10,15,20,25,50,75); /* Edit this list to your preferred 2 digit numbers */
	sbWidth2SFC = closestValueFromArray(preferredSBW,sbWidth2SF,100); /* alternatively default input could be sbWidth1SF*10 */
	sbWidth = pow(10,indexSBWidth-1)*sbWidth2SFC;
	selLengthInUnits = sbWidth;
	sbHeightPC = 19; /*  percent of font size */
	scaleBarColor = call("ij.Prefs.get", "fancy.scale.font.color","white");
	outlineColor = call("ij.Prefs.get", "fancy.scale.outline.color","black");
	selPos = call("ij.Prefs.get", "fancy.scale.location","Bottom Right");
	sBStyle = call("ij.Prefs.get", "fancy.scale.bar.style","Solid Bar");
	fontSize =  sbFontSize;
	fontFactor = fontSize/100;
	sbHeight = maxOf(2,round(fontSize*sbHeightPC/100)); /*  set minimum default bar height as 2 pixels */
	fontStyle = call("ij.Prefs.get", "fancy.scale.font.style","bold");
	fontName = call("ij.Prefs.get", "fancy.scale.font","Arial Black");
	outlineStroke = dOutS; /* % of font size */
	shadowDrop = maxOf(1, round(fontFactor * dShO)); /* % of font size */
	shadowDisp = shadowDrop;
	shadowBlur = maxOf(1, round(fontFactor * dOutS)); /* % of font size */
	shadowDarkness = 30; /* % */
	innerShadowDrop = floor(fontFactor * dIShO); /* % of font size */
	innerShadowDisp = innerShadowDrop; /* % of font size */
	innerShadowBlur = floor(fontFactor * dIShO/2); /* % of font size */
	innerShadowDarkness = 20; /* % */
	overWrite = "New image";
	labelRest = true;
	setBatchMode(true);
	setFont(fontName,fontSize, fontStyle);
	if (fontStyle!="unstyled") fontStyle += "antialiased"; /* antialising will be applied if possible */ 
	outlineStroke = maxOf(1, round(fontFactor * outlineStroke)); /* if some outline is desired set to at least one pixel */
	selLengthInPixels = selLengthInUnits / lcf;
	innerShadowDrop = floor(fontFactor * innerShadowDrop);
	innerShadowDisp = floor(fontFactor * innerShadowDisp);
	innerShadowBlur = floor(fontFactor * innerShadowBlur);
	if (selOffsetX<(shadowDisp+shadowBlur+1)) selOffsetX += (shadowDisp+shadowBlur+1);  /* make sure shadow does not run off edge of image */
	if (selOffsetY<(shadowDrop+shadowBlur+1)) selOffsetY += (shadowDrop+shadowBlur+1);
	if (fontStyle=="unstyled") fontStyle="";
	if (selPos == "Top Left") {
		selEX = selOffsetX;
		selEY = selOffsetY; // + fontSize;
		if (sBStyle!="Solid Bar") selEY += sbHeight;
	} else if (selPos == "Top Right") {
		selEX = imageWidth - selLengthInPixels - selOffsetX;
		selEY = selOffsetY;// + fontSize;
		if (sBStyle!="Solid Bar") selEY += sbHeight;
	} else if (selPos == "Bottom Center") {
		selEX = imageWidth/2 - selLengthInPixels/2;
		selEY = imageHeight - sbHeight - (selOffsetY);
		if (sBStyle!="Solid Bar") selEY -= sbHeight/2;
	} else if (selPos == "Bottom Left") {
		selEX = selOffsetX;
		selEY = imageHeight - sbHeight - (selOffsetY);
		if (sBStyle!="Solid Bar") selEY -= sbHeight/2;
	} else if (selPos == "Bottom Right") {
		selEX = imageWidth - selLengthInPixels - selOffsetX;
		selEY = imageHeight - sbHeight - selOffsetY;
		if (sBStyle!="Solid Bar") selEY -= sbHeight/2;
	} else if (selPos=="At Center of New Selection" || (selPos=="At Selection" && selEType<0)){
		setBatchMode("exit & display");	/* need batch mode off to see selection */
		run("Select None");
		setTool("rectangle");
		title="position";
		msg = "Draw a box in the image where you want the scale bar to be centered";
		waitForUser(title, msg);
		getSelectionBounds(newSelEX, newSelEY, newSelEWidth, newSelEHeight);
		run("Select None");
		selEX = newSelEX + round((newSelEWidth/2) - selLengthInPixels/2);
		selEY = newSelEY + round(newSelEHeight/2)- sbHeight - selOffsetY;
		if (is("Batch Mode")==false) setBatchMode(true);	/* toggle batch mode back on */
	} else if (selPos=="At Selection"){
		if (selEY>imageHeight/2) selEY += selEHeight;  /*  Annotation relative to the bottom of the selection if in lower half of image */
		selEY = minOf(selEY, imageHeight-(sbHeight/2 + selOffsetY));
	}
	 /*  edge limits - assume intent is not to annotate edge objects */
	maxSelEY = imageHeight - round(sbHeight/2) + selOffsetY;
	selEY = maxOf(minOf(selEY,maxSelEY),selOffsetY);
	maxSelEX = imageWidth - selLengthInPixels + selOffsetX;
	selEX = maxOf(minOf(selEX,maxSelEX),selOffsetX);

	selLengthLabel = removeTrailingZerosAndPeriod(toString(selLengthInUnits));
	label = selLengthLabel + " " + selectedUnit;
	/* stop overrun on scale bar by label of more than 20% */
	stringOF = getStringWidth(label)/selLengthInPixels;
	
	if (stringOF > 1.2) {
		shrinkFont = getBoolean("Shrink font size by " + 1/stringOF + "x to fit within scale bar?");
		if (shrinkFont) fontSize = round(fontSize/stringOF);
		setFont("",fontSize);
	}
	/* stop text overrun */
	stringOver = (getStringWidth(label)-selLengthInPixels)/2;
	if (stringOver > 0) {
		if ((selEX-stringOver) < selOffsetX) selEX +=stringOver;
		if ((selEX+getStringWidth(label)) > (imageWidth-selOffsetX)) selEX -= stringOver;
	}
	fontHeight = getValue("font.height");
	/* Adjust label location */
	if (selEY<=1.5*fontHeight)
			textYcoord = selEY + sbHeight + fontHeight;
	else textYcoord = selEY - sbHeight;
	textXOffset = round((selLengthInPixels - getStringWidth(label))/2);
	finalLabel = label;
	finalLabelX = selEX + textXOffset;
	finalLabelY = textYcoord;
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	setColor(255,255,255);
	if (sBStyle=="Solid Bar")	fillRect(selEX, selEY, selLengthInPixels, sbHeight);
	else {
		if (sBStyle=="I-Bar") arrowStyle = "Bar Double Small";
		else if (sBStyle=="Notched Arrows")  arrowStyle = "Notched Double Small";
		else arrowStyle = "Double Small";
		makeArrow(selEX,selEY,selEX+selLengthInPixels,selEY,arrowStyle);
        Roi.setStrokeColor("white");
        Roi.setStrokeWidth(sbHeight/2);
        run("Add Selection...");
		Overlay.flatten;
		run("8-bit");
		closeImageByTitle("label_mask");
		rename("label_mask");
	}
	writeLabel7(fontName, fontSize, "white", label,finalLabelX,finalLabelY,false);
	setThreshold(0, 128);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	/* Create shadow and outline selection masks to be used for bitmap components */
	/* Create drop shadow if desired */
	if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0)
		createShadowDropFromMask7("label_mask", shadowDrop, shadowDisp, shadowBlur, shadowDarkness, outlineStroke);
	/* Create inner shadow if desired */
	if (innerShadowDrop!=0 || innerShadowDisp!=0 || innerShadowBlur!=0)
		createInnerShadowFromMask6("label_mask",innerShadowDrop, innerShadowDisp, innerShadowBlur, innerShadowDarkness);
	tS = "" + stripKnownExtensionFromString(unCleanLabel(activeImage)) + "+scale";
	run("Select None");
	selectWindow(activeImage);
	run("Duplicate...", "title=&tS duplicate");
	selectWindow(tS);
	/* Tries to remove any old scale related overlays from copied image but usually leaves 2  ¯\_(?)_/¯ */
	if(Overlay.size>0) {
		initialOverlaySize = Overlay.size;
		for (i=0; i<slices; i++){
			for (j=0; j<initialOverlaySize; j++){
				setSlice(i+1);
				if (j<Overlay.size){
					Overlay.activateSelection(j);
					overlaySelectionName = getInfo("selection.name");
					if (indexOf(overlaySelectionName,"cale")>=0) Overlay.removeSelection(j);
				}
			}
		}
		if (slices==1 && channels>1) {
			for (i=0; i<channels; i++){
				for (j=0; j<initialOverlaySize; j++){
					setChannel(i+1);
					if (j<Overlay.size){
						Overlay.activateSelection(j);
						overlaySelectionName = getInfo("selection.name");
						if (indexOf(overlaySelectionName,"cale")>=0) Overlay.removeSelection(j);
					}
				}
			}
		}
	}
	newImage("outline_template", "8-bit black", imageWidth, imageHeight, 1);
	getSelectionFromMask("label_mask");
	run("Enlarge...", "enlarge=&outlineStroke pixel");
	setBackgroundFromColorName("white");
	run("Clear", "slice");
	run("Select None");
	selectWindow(tS);
	if (slices==1 && channels>1){  /* process channels instead of slices */
		labelChannels = true;
		endSlice = channels;
	}
	else {
		labelChannels = false;
		endSlice = slices;
	}
	for (sl=1; sl<endSlice+1; sl++) {
		if (labelChannels) Stack.setChannel(sl);
		else setSlice(sl);
		run("Select None");
		if (isOpen("shadow") && (shadowDarkness>0)) imageCalculator("Subtract", tS,"shadow");
		else if (isOpen("shadow") && (shadowDarkness<0)) imageCalculator("Add", tS,"shadow");
		run("Select None");
		/* apply outline around label */
		getSelectionFromMask("outline_template");
		setBackgroundFromColorName(outlineColor);
		run("Clear", "slice");
		run("Select None");
		/* color label */
		getSelectionFromMask("label_mask");
		setBackgroundFromColorName(scaleBarColor);
		run("Clear", "slice");
		run("Select None");
		if (isOpen("inner_shadow")) imageCalculator("Subtract", tS,"inner_shadow");
	}
	closeImageByTitle("shadow");
	closeImageByTitle("inner_shadow");
	closeImageByTitle("label_mask");
	closeImageByTitle("outline_template");
	restoreSettings();
	setSlice(1);
	setBatchMode("exit & display"); /* exit batch mode */
	call("java.lang.System.gc");
	showStatus("Fast'nFancy Scale Bar Rerun completed");
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
		/* v161102 changed to true-false
			v180831 some cleanup
			v210429 Expandable array version */
		var pluginCheck = false;
		if (getDirectory("plugins") == "") restoreExit("Failure to find any plugins!");
		else pluginDir = getDirectory("plugins");
		if (!endsWith(pluginName, ".jar")) pluginName = pluginName + ".jar";
		if (File.exists(pluginDir + pluginName)) {
				pluginCheck = true;
				showStatus(pluginName + "found in: "  + pluginDir);
		}
		else {
			pluginList = getFileList(pluginDir);
			subFolderList = newArray;
			for (i=0,subFolderCount=0; i<lengthOf(pluginList); i++) {
				if (endsWith(pluginList[i], "/")) {
					subFolderList[subFolderCount] = pluginList[i];
					subFolderCount++;
				}
			}
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
			v180921 Fixed error in 2nd dialog.
			v200925 Checks also for unit = pixels
		*/
		getPixelSize(unit, pixelWidth, pixelHeight);
		if (pixelWidth!=pixelHeight || pixelWidth==1 || unit=="" || unit=="inches" || unit=="pixels"){
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
			else if (pixelWidth!=pixelHeight || pixelWidth==1 || unit=="" || unit=="inches" || unit=="pixels"){
				setScale = false;
				Dialog.create("Still no standard units");
				Dialog.addMessage("Pixel width = "+pixelWidth+"\nPixel height = "+pixelHeight+"\nUnit = "+unit);
				Dialog.addCheckbox("Unit asymmetry, pixel units or dpi remnants; do you want to define units for this image?", true);
				Dialog.show();
				setScale = Dialog.getCheckbox;
				if (setScale)
					run("Set Scale...");
			}
		}
	}
	function closeImageByTitle(windowTitle) {  /* Cannot be used with tables */
		/* v181002 reselects original image at end if open
		   v200925 uses "while" instead of if so it can also remove duplicates
		*/
		oIID = getImageID();
        while (isOpen(windowTitle)) {
			selectWindow(windowTitle);
			close();
		}
		if (isOpen(oIID)) selectImage(oIID);
	}
	function closestValueFromArray(array,value,default) {
		/* v190912 1st version pjl */
		closest = default;
		proximity = abs(default-value);
		for (i=0; i<lengthOf(array); i++){
			proxI = abs(array[i]-value);
			if (proxI<proximity) {
				closest = array[i];
				proximity = proxI;
			}
		}
	  return closest;
	}
	function createInnerShadowFromMask6(mask,iShadowDrop, iShadowDisp, iShadowBlur, iShadowDarkness) {
		/* Requires previous run of: imageDepth = bitDepth();
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
		if (expansion>0) run("Enlarge...", "enlarge=&expansion pixel");
		if (iShadowBlur>0) run("Gaussian Blur...", "sigma=&iShadowBlur");
		run("Unsharp Mask...", "radius=0.5 mask=0.2"); /* A tweak to sharpen the effect for small font sizes */
		imageCalculator("Max", "inner_shadow",mask);
		run("Select None");
		/* The following are needed for different bit depths */
		if (imageDepth==16 || imageDepth==32) run(imageDepth + "-bit");
		run("Enhance Contrast...", "saturated=0 normalize");
		run("Invert");  /* Create an image that can be subtracted - this works better for color than Min */
		divider = (100 / abs(iShadowDarkness));
		run("Divide...", "value=&divider");
	}
	function createShadowDropFromMask7(mask, oShadowDrop, oShadowDisp, oShadowBlur, oShadowDarkness, oStroke) {
		/* Requires previous run of: imageDepth = bitDepth();
		because this version works with different bitDepths
		v161115 calls five variables: drop, displacement blur and darkness
		v180627 adds mask label to variables	*/
		showStatus("Creating drop shadow for labels . . . ");
		newImage("shadow", "8-bit black", imageWidth, imageHeight, 1);
		getSelectionFromMask(mask);
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX + oShadowDisp, selMaskY + oShadowDrop);
		setBackgroundColor(255,255,255);
		if (oStroke>0) run("Enlarge...", "enlarge=&oStroke pixel"); /* Adjust shadow size so that shadow extends beyond stroke thickness */
		run("Clear");
		run("Select None");
		if (oShadowBlur>0) {
			run("Gaussian Blur...", "sigma=&oShadowBlur");
			run("Unsharp Mask...", "radius=&oShadowBlur mask=0.4"); /* Make Gaussian shadow edge a little less fuzzy */
		}
		/* Now make sure shadow or glow does not impact outline */
		getSelectionFromMask(mask);
		if (oStroke>0) run("Enlarge...", "enlarge=&oStroke pixel");
		setBackgroundColor(0,0,0);
		run("Clear");
		run("Select None");
		/* The following are needed for different bit depths */
		if (imageDepth==16 || imageDepth==32) run(imageDepth + "-bit");
		run("Enhance Contrast...", "saturated=0 normalize");
		divider = (100 / abs(oShadowDarkness));
		run("Divide...", "value=&divider");
	}
	function getColorArrayFromColorName(colorName) {
		/* v180828 added Fluorescent Colors
		   v181017-8 added off-white and off-black for use in gif transparency and also added safe exit if no color match found
		   v191211 added Cyan
		   v211022 all names lower-case, all spaces to underscores
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
		else if (colorName == "yellow") cA = newArray(255,255,0);
		else if (colorName == "orange") cA = newArray(255, 165, 0);
		else if (colorName == "cyan") cA = newArray(0, 255, 255);
		else if (colorName == "garnet") cA = newArray(120,47,64);
		else if (colorName == "gold") cA = newArray(206,184,136);
		else if (colorName == "aqua_modern") cA = newArray(75,172,198); /* #4bacc6 AKA "Viking" aqua */
		else if (colorName == "blue_accent_modern") cA = newArray(79,129,189); /* #4f81bd */
		else if (colorName == "blue_dark_modern") cA = newArray(31,73,125);
		else if (colorName == "blue_modern") cA = newArray(58,93,174); /* #3a5dae */
		else if (colorName == "gray_modern") cA = newArray(83,86,90);
		else if (colorName == "green_dark_modern") cA = newArray(121,133,65);
		else if (colorName == "green_modern") cA = newArray(155,187,89); /* #9bbb59 AKA "Chelsea Cucumber" */
		else if (colorName == "green_modern_accent") cA = newArray(214,228,187); /* #D6E4BB AKA "Gin" */
		else if (colorName == "green_spring_accent") cA = newArray(0,255,102); /* #00FF66 AKA "Spring Green" */
		else if (colorName == "orange_modern") cA = newArray(247,150,70);
		else if (colorName == "pink_modern") cA = newArray(255,105,180);
		else if (colorName == "purple_modern") cA = newArray(128,100,162);
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
		/*	v180723 first version
			v180828 Changed order of favorites
			v190108 Longer list of favorites
		*/
		systemFonts = getFontList();
		IJFonts = newArray("SansSerif", "Serif", "Monospaced");
		fontNameChoice = Array.concat(IJFonts,systemFonts);
		faveFontList = newArray("Your favorite fonts here", "Open Sans ExtraBold", "Fira Sans ExtraBold", "Noto Sans Black", "Arial Black", "Montserrat Black", "Lato Black", "Roboto Black", "Merriweather Black", "Alegreya Black", "Tahoma Bold", "Calibri Bold", "Helvetica", "SansSerif", "Calibri", "Roboto", "Tahoma", "Times New Roman Bold", "Times Bold", "Serif");
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
		/* v220126 added micrometer symbol */
		if (inputUnit=="km") scaleFactor = 1E3;
		else if (inputUnit=="m") scaleFactor = 1;
		else if (inputUnit=="cm") scaleFactor = 1E-2;
		else if (inputUnit=="mm") scaleFactor = 1E-3;
		else if (inputUnit=="um") scaleFactor = 1E-6;
		else if (inputUnit==(fromCharCode(181)+"m")) scaleFactor = 1E-6;
		else if (inputUnit=="µm") scaleFactor =  1E-6;
		else if (inputUnit==getInfo("micrometer.abbreviation")) scaleFactor =  1E-6;
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
	function getSelectionFromMask(sel_M){
		batchMode = is("Batch Mode"); /* Store batch status mode before toggling */
		if (!batchMode) setBatchMode(true); /* Toggle batch mode on if previously off */
		tempTitle = getTitle();
		selectWindow(sel_M);
		run("Create Selection"); /* Selection inverted perhaps because the mask has an inverted LUT? */
		run("Make Inverse");
		selectWindow(tempTitle);
		run("Restore Selection");
		if (!batchMode) setBatchMode(false); /* Return to original batch mode setting */
	}
	function indexOfArray(array, value, default) {
		/* v190423 Adds "default" parameter (use -1 for backwards compatibility). Returns only first found value */
		index = default;
		for (i=0; i<lengthOf(array); i++){
			if (array[i]==value) {
				index = i;
				i = lengthOf(array);
			}
		}
	  return index;
	}
	function removeTrailingZerosAndPeriod(string) {
	/* Removes any trailing zeros after a period
	v210430 totally new version: Note: Requires remTZeroP function
	Nested string functions require "" prefix
	*/
		lIP = lastIndexOf(string, ".");
		if (lIP>=0) {
			lIP = lengthOf(string) - lIP;
			string = "" + remTZeroP(string,lIP);
		}
		return string;
	}
	function remTZeroP(string,iterations){
		for (i=0; i<iterations; i++){
			if (endsWith(string,"0"))
				string = substring(string,0,lengthOf(string)-1);
			else if (endsWith(string,"."))
				string = substring(string,0,lengthOf(string)-1);
			/* Must be "else if" because we only want one removal per iteration */
		}
		return string;
	}
	function restoreExit(message){ /* Make a clean exit from a macro, restoring previous settings */
		/* 9/9/2017 added Garbage clean up suggested by Luc LaLonde - LBNL */
		restoreSettings(); /* Restore previous settings before exiting */
		setBatchMode("exit & display"); /* Probably not necessary if exiting gracefully but otherwise harmless */
		call("java.lang.System.gc");
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
	function stripKnownExtensionFromString(string) {
		/*	Note: Do not use on path as it may change the directory names
		v210924: Tries to make sure string stays as string
		v211014: Adds some additional cleanup
		v211025: fixes multiple knowns issue
		v211101: Added ".Ext_" removal
		v211104: Restricts cleanup to end of string to reduce risk of corrupting path
		v211112: Tries to fix trapped extension before channel listing. Adds xlsx extension.
		*/
		string = "" + string;
		if (lastIndexOf(string, ".")>0 || lastIndexOf(string, "_lzw")>0) {
			knownExt = newArray("dsx", "DSX", "tif", "tiff", "TIF", "TIFF", "png", "PNG", "GIF", "gif", "jpg", "JPG", "jpeg", "JPEG", "jp2", "JP2", "txt", "TXT", "csv", "CSV","xlsx","XLSX","_"," ");
			kEL = lengthOf(knownExt);
			chanLabels = newArray("\(red\)","\(green\)","\(blue\)");
			unwantedSuffixes = newArray("_lzw"," ","  ", "__","--","_","-");
			uSL = lengthOf(unwantedSuffixes);
			for (i=0; i<kEL; i++) {
				for (j=0; j<3; j++){ /* Looking for channel-label-trapped extensions */
					ichanLabels = lastIndexOf(string, chanLabels[j]);
					if(ichanLabels>0){
						index = lastIndexOf(string, "." + knownExt[i]);
						if (ichanLabels>index && index>0) string = "" + substring(string, 0, index) + "_" + chanLabels[j];
						ichanLabels = lastIndexOf(string, chanLabels[j]);
						for (k=0; k<uSL; k++){
							index = lastIndexOf(string, unwantedSuffixes[k]);  /* common ASC suffix */
							if (ichanLabels>index && index>0) string = "" + substring(string, 0, index) + "_" + chanLabels[j];	
						}				
					}
				}
				index = lastIndexOf(string, "." + knownExt[i]);
				if (index>=(lengthOf(string)-(lengthOf(knownExt[i])+1)) && index>0) string = "" + substring(string, 0, index);
			}
		}
		unwantedSuffixes = newArray("_lzw"," ","  ", "__","--","_","-");
		for (i=0; i<lengthOf(unwantedSuffixes); i++){
			sL = lengthOf(string);
			if (endsWith(string,unwantedSuffixes[i])) string = substring(string,0,sL-lengthOf(unwantedSuffixes[i])); /* cleanup previous suffix */
		}
		return string;
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
	function writeLabel7(font, size, color, text,x,y,aA){
	/* Requires the functions setColorFromColorName, getColorArrayFromColorName(colorName) etc. 
	v190619 all variables as options */
		if (aA == true) setFont(font , size, "antialiased");
		else setFont(font, size);
		setColorFromColorName(color);
		drawString(text, x, y); 
	}