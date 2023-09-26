macro "Fancy Scale Bar" {
/* Original code by Wayne Rasband, improved by Frank Sprenger and deposited on the ImageJ mailing server: (http:imagej.588099.n2.nabble.com/Overlay-Scalebar-Plugins-td6380378.html#a6394996). KS added choice of font size, scale bar height, + any position for scale bar and some options that allow to set the image calibration (only for overlay, not in Meta data). Kees Straatman, CBS, University of Leicester, May 2011
	Grotesquely modified by Peter J. Lee NHMFL to produce shadow and outline effects.
	v161008-v230804:  Listed at end.
	v230808: Sensible scales function replaces sensible units for more sensible scales.
	v230809: Renames image if not new but expanded. Removes left-right margin tweak for 'under' option. v230810: Minor change to text and default options. F1: updates indexOf functions. F2: getColorArrayFromColorName_v230908.
	v230911: Fix for color prefs index issue. b: Fix for missing new selection coordinates.
	v230912: Added basic tiff and jpeg save options. Fixed overlay removal issues. Adds (and F1 updates) safeSaveAndClose function.
	v230915: Main menu optimized for clarity.
	v230918: Reordered code. Removed unused plugins. Prefs keys made more consistent.
	v230919: More prefs keys added. Improved font choices. Fixed color preferences. b: simplified line labels and removed all text rotation as it was not satisfactory. Removed excess decimal places (based on pixel width).
	v230920: Additional line-mode options. Menu compacts for smaller screens. Text overlap with arrows fixed.
	v230922: In line-mode the text label and measurements can be combined and extra line end option added with tweaks to text position to minimize overlaps. RegEx also corrected in font function.
*/
	macroL = "Fancy_Scale_Bar_v230922.ijm";
	fullMenuHeight = 988; /* pixels for v230920 */
	requires("1.52i"); /* Utilizes Overlay.setPosition(0) from IJ >1.52i */
	saveSettings(); /* To restore settings at the end */
	micron = getInfo("micrometer.abbreviation");
	prefsNameKey = "fancy.scale";
	selEType = selectionType;
	if(is("Inverting LUT")){
		run("Invert LUT"); /* more effectively removes Inverting LUT */
		if (selEType<0) run("Invert"); /* Assumes you wanted the apparent contrast */
	}
	if (selEType>=0) {
		getSelectionBounds(selEX, selEY, selEWidth, selEHeight);
		if ((selEWidth + selEHeight)<6) selEType=-1; /* Ignore junk selections that are suspiciously small */
		if (selEType==5) getSelectionCoordinates(selLX, selLY); 
	}
	getStatistics(areaPix, meanInt, minInt, maxInt, stdInt);
	activeImage = getTitle();
	imageDir = getDir("image");
	activeImageID = getImageID();
	imageDepth = bitDepth();
	if(imageDepth!=24){
		if (imageDepth<8 || imageDepth>16){
			if(getBoolean("Image depth of " + imageDepth + " does not work for this macro; change to 8-bit?")){
				run("8-bit");
				imageDepth = bitDepth();
			}
			else restoreExit("Goodbye");
		}
		else if ((imageDepth==8) && indexOf(getInfo(), "Display range:") < 0){
			run("RGB Color");
			imageDepth = bitDepth();
		}
	}
	medianBGIs = guessBGMedianIntensity();
	medianBGI = round((medianBGIs[0]+medianBGIs[1]+medianBGIs[2])/3);
	bgI = maxOf(0,medianBGI);
	run("Select None");
	checkForUnits();
	getDimensions(imageWidth, imageHeight, channels, slices, frames);
	imageAR = imageWidth/imageHeight;
	remAllOverlays = false;
	overlayN = Overlay.size;
	if (overlayN>0) remAllOverlays = true;
	if (imageDepth==16) bgIpc = round(bgI*100/65536);
	else bgIpc = round(bgI*100/255);
	if ((stdInt<5 && (meanInt>205 || meanInt<50)) || bgIpc>95 || bgIpc<5) fancyStyle = "No fancy formatting";
	else fancyStyle = "Standard for busy images";
	/* End simple text default options */
	startSliceNumber = getSliceNumber();
	remSlices = slices-startSliceNumber;
	if (selEType==5) sbFontSize = maxOf(10, round((imageHeight+imageWidth)/90)); /* set minimum default font size as 12 */
	else sbFontSize = maxOf(12, round((minOf(imageHeight,imageWidth))/30)); /* set minimum default font size as 12 */
	getVoxelSize(pixelWidth, pixelHeight, pixelDepth, selectedUnit);
	pixelAR = pixelWidth/pixelHeight;
	sensibleScale = sensibleScales(pixelWidth,selectedUnit,sbFontSize*10);
	pixelWidth = parseFloat(sensibleScale[0]);
	pixelHeight = pixelWidth/pixelAR;
	selectedUnit = sensibleScale[1];
	sciPW = d2s(pixelWidth,-2);
	trueDPMax = 0 - parseInt(substring(sciPW,indexOf(sciPW,"E")+1));
	setVoxelSize(pixelWidth,pixelHeight,pixelDepth,selectedUnit);
	if (selectedUnit == "um") selectedUnit = micron;
	sF = getScaleFactor(selectedUnit);
	micronS = getInfo("micrometer.abbreviation");
	lcf=(pixelWidth+pixelHeight)/2;
	lcfFactor=1/lcf;
	pixAr = pixelHeight/pixelWidth;
	dOutS = 5; /* default outline stroke: % of font size */
	dShO = 7;  /* default outer shadow drop: % of font size */
	dIShO = 4; /* default inner shadow drop: % of font size */
	notFancy = false;
	/* set default tweaks */
	outlineStroke = dOutS;
	shadowDrop = dShO;
	shadowDisp = dShO;
	shadowBlur = floor(0.75*dShO);
	shadowDarkness = 30;
	textLabel = "";
	diagnostics = false;
	if (sF>0) {
		nSF = newArray(1,sF/(1E-2),sF/(1E-3),sF/(1E-6),sF/(1E-6),sF/(1E-9),sF/(1E-10),sF/(1E-12), sF/(2.54E-2), sF/(1E-4));
		overrideUnitChoices = newArray(selectedUnit, "cm", "mm", micronS, "microns", "nm", "Å", "pm", "inches", "human hairs");
	}
	if (selEType>=0) {
		if (selEType!=5){
			sbWidth = pixelWidth*selEWidth;
			sbDP = autoCalculateDecPlacesFromValueOnly(sbWidth);
			sbPreciseWidthString = d2s(sbWidth, sbDP+3);
		}
		else {
			lineXPx = abs(selLX[1]-selLX[0]); /* used for label offsets later */
			lineYPx = abs(selLY[1]-selLY[0]); /* used for label offsets later */
			lineLengthPx = sqrt(pow(lineXPx,2) + pow(lineYPx,2)); /* NOTE: not corrected for pixel aspect ratio */
			sbWidth = sqrt(pow(lineXPx * pixelWidth,2) + pow(lineYPx * pixelHeight,2));
			sbDP = minOf(trueDPMax, autoCalculateDecPlacesFromValueOnly(sbWidth)+2); /* Add more dp for line labeling */
			sbPreciseWidthString = d2s(sbWidth, minOf(trueDPMax, sbDP+3));
			sbWidth = parseFloat(sbPreciseWidthString);
			lineAngle = Math.toDegrees(atan2((selLY[1]-selLY[0]) * pixelHeight, (selLX[1]-selLX[0]) * pixelWidth));
			lineXPx = abs(selLX[1]-selLX[0]);
			lineYPx = abs(selLY[1]-selLY[0]);
			lineMidX = (selLX[0] + selLX[1])/2;
			lineMidY = (selLY[0] + selLY[1])/2;
		}
	}
	else {
		sbWidth = pixelWidth * imageWidth/5;
		sbDP = autoCalculateDecPlacesFromValueOnly(sbWidth)+2; /* Add more dp for line labeling */		sbWidthString = d2s(sbWidth, sbDP);
		sbWidthString = d2s(sbWidth, sbDP);
	} 
	selOffsetX = minOf(imageWidth/20,maxOf(dOutS,round(imageWidth/120)));
	selOffsetY = minOf(imageHeight/20,maxOf(dOutS,round(maxOf(imageHeight/180, 0.35*sbFontSize))));
	indexSBWidth = parseInt(substring(d2s(sbWidth, -1),indexOf(d2s(sbWidth, -1), "E")+1));
	dpSB = maxOf(0,1 - indexSBWidth);
	sbWidth1SF = round(sbWidth/pow(10,indexSBWidth));
	sbWidth2SF = round(sbWidth/pow(10,indexSBWidth-1));
	preferredSBW = newArray(10,20,25,50,75); /* Edit this list to your preferred 2 digit numbers */
	sbWidth2SFC = closestValueFromArray(preferredSBW,sbWidth2SF,100); /* alternatively could be sbWidth1SF*10 */
	if (selEType!=5) sbWidth = pow(10,indexSBWidth-1)*sbWidth2SFC;
	fScaleBarOverlays = countOverlaysByName("cale");
	/* ASC message theme */
	infoColor = "#006db0"; /* Honolulu blue */
	instructionColor = "#798541"; /* green_dark_modern (121,133,65) AKA Wasabi */
	infoWarningColor = "#ff69b4"; /* pink_modern AKA hot pink */
	infoFontSize = 12;
	degChar = fromCharCode(0x00B0);
	divChar = fromCharCode(0x00F7);
	plusminus = fromCharCode(0x00B1);
	modeStr = "scale bar";
	if (selEType>=0) {
		if (selEType!=5){
			locChoices = newArray("Top Left", "Top Right", "Bottom Center", "Bottom Left", "Bottom Right", "At Center of New Selection", "At Selection Center");
			iLoc = indexOfArray(locChoices, call("ij.Prefs.get", prefsNameKey + ".location",locChoices[6]),6);
		}
		else {
			locChoices = newArray("Over center");
			if (lineMidX>imageWidth/2) locChoices = Array.concat(locChoices,"Left of line start", "Right of line start","Left of line end", "Right of line end");
			else locChoices  = Array.concat(locChoices, "Right of line start", "Left of line start", "Right of line end", "Left of line end");
			iLoc = indexOfArray(locChoices, call("ij.Prefs.get", prefsNameKey + ".location",locChoices[0]), 0);
			modeStr = "length line";
		}
	}
	else {
		locChoices = newArray("Top Left", "Top Right", "Bottom Center", "Bottom Left", "Bottom Right", "Under Image Left","Under Image Right", "At Center of New Selection");
		iLoc = indexOfArray(locChoices, call("ij.Prefs.get", prefsNameKey + ".location",locChoices[4]),4);
	}
	if (fullMenuHeight> 0.9 * screenHeight) compactMenu = true; /* used to limit menu size for small screens */
	else compactMenu = false;
	if (compactMenu) menuLabel = "Scale Bar Parameters \(compact menu for low resolution screens\): " + macroL;
	else menuLabel = "Scale Bar Parameters: " + macroL;
	Dialog.create(menuLabel);
		if(pixelHeight!=pixelWidth) Dialog.addMessage("Warning: Non-square pixels \(pixelHeight/pixelWidth = " + pixelHeight/pixelWidth + "\)",infoFontSize,infoWarningColor);
		if (selEType==5){
			Dialog.addMessage("Currently in length labeling mode: Select none or a non-straight-line selection to draw a scale bar",infoFontSize, infoWarningColor);
			Dialog.addNumber("Selected line length \(" + d2s(lineLengthPx,1) + " pixels\):", sbWidth, dpSB, 10, selectedUnit);
			Dialog.addString("Selected line angle \(" + lineAngle + degChar + " from horizontal\):", d2s(lineAngle, 2), 5);
			Dialog.addString("Length/angle separator \(i.e. , \):", "No angle label",10);
			Dialog.addString("Text label \(end with ':' to add length/angle otherwise text only)", textLabel,20);
		} else {
			Dialog.addMessage("Currently in scale bar mode: Use the straight line selection tool to activate length labeling mode",infoFontSize+1,infoWarningColor);
			dText = "Length of scale bar";
			if (selEType>=0) dText += " \(precise length = " + sbPreciseWidthString + "\)";
			Dialog.addNumber(dText + ":", sbWidth, dpSB, 10, selectedUnit);
		}
		if (sF>0) {
			if (sbWidth>999 || sbWidth<1) {
				Dialog.setInsets(0, 255, 0);
				Dialog.addMessage("Consider changing the unit:",infoFontSize,infoWarningColor);
			}
			newUnits = newArray(""+selectedUnit+" Length x1", "cm \(Length x"+nSF[1]+"\)","mm \(Length x"+nSF[2]+"\)",micronS+" \(Length x"+nSF[3]+"\)","microns \(Length x"+nSF[4]+"\)", "nm \(Length x"+nSF[5]+"\)", "Å \(Length x"+nSF[6]+"\)", "pm \(Length x"+nSF[7]+"\)", "inches \(Length x"+nSF[8]+"\)", "human hair \(Length x"+nSF[9]+"\)");
		}
		Dialog.addChoice("Override unit with new choice?", newUnits, newUnits[0]);
		Dialog.addNumber("Font size \(\"FS\"\):", sbFontSize, 0, 4,"");
		Dialog.addNumber("Thickness of " + modeStr + " :", call("ij.Prefs.get", prefsNameKey + ".barHeightPC",70),0,3,"% of '!' character width");
		grayChoices = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray");
		colorChoicesStd = newArray("red", "green", "blue", "cyan", "magenta", "yellow", "pink", "orange", "violet");
		colorChoicesMod = newArray("garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "blue_honolulu", "gray_modern", "green_dark_modern", "green_modern", "green_modern_accent", "green_spring_accent", "orange_modern", "pink_modern", "purple_modern", "red_n_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern");
		colorChoicesNeon = newArray("jazzberry_jam", "radical_red", "wild_watermelon", "outrageous_orange", "supernova_orange", "atomic_tangerine", "neon_carrot", "sunglow", "laser_lemon", "electric_lime", "screamin'_green", "magic_mint", "blizzard_blue", "dodger_blue", "shocking_pink", "razzle_dazzle_rose", "hot_magenta");
		colorChoices = Array.concat(grayChoices, colorChoicesStd, colorChoicesMod, colorChoicesNeon);
		if (startsWith(fancyStyle,"No")){
			if ((bgIpc>50 && !startsWith(locChoices[iLoc],"Under")) || (bgIpc<50 && startsWith(locChoices[iLoc],"Under"))){
				iTC = 1; iBC = 0; iTG = 1; iBG = 0;
			}
			else {
				iTC = 0; iBC = 1; iTG = 0; iBG = 1;
			}
		}
		else {
			if ((bgIpc>30 && !startsWith(locChoices[iLoc],"Under")) || (bgIpc<30 && startsWith(locChoices[iLoc],"Under"))){
				iTC = 0; iBC = 1; iTG = 0; iBG = 1;
			}
			else {
				iTC = 1; iBC = 0; iTG = 1; iBG = 0;
			}
		}
		/* Recall non-BW colors */
		if (imageDepth==24){
			iTC = indexOfArray(colorChoices, call("ij.Prefs.get", prefsNameKey + ".font.color",colorChoices[iTC]), iTC);
			iBC = indexOfArray(colorChoices, call("ij.Prefs.get", prefsNameKey + ".outline.color",colorChoices[iBC]), iBC);
		}
		iTG = indexOfArray(grayChoices, call("ij.Prefs.get", prefsNameKey + ".font.gray",grayChoices[iTG]), iTG);
		iBG = indexOfArray(grayChoices, call("ij.Prefs.get", prefsNameKey + ".outline.gray",grayChoices[iBG]), iBG);
		/* Reverse Black/white if it looks like it will not work with background intensity
		Note: keep white/black color order in colorChoices for intensity reversal after background intensity check */
		if (imageDepth==24){
			Dialog.addChoice("Color of " + modeStr + " and text \(median intensity = "+bgIpc+"%\):", colorChoices, colorChoices[iTC]);
			Dialog.addChoice("Outline (background) color:", colorChoices, colorChoices[iBC]);
		}
		else {
			Dialog.addChoice("Gray tone of " + modeStr + " and text:", grayChoices, grayChoices[iTG]);
			Dialog.addChoice("Gray tone of background:", grayChoices, grayChoices[iBG]);
			if (compactMenu){
				Dialog.setInsets(-65,370,0);
				Dialog.addMessage("Image depth is " + imageDepth + " bits:\nOnly gray tones used unless\noverlays are selected below",infoFontSize,infoColor);
			}
			else {
				Dialog.setInsets(-3,50,0);
				Dialog.addMessage("Image depth is " + imageDepth + " bits: Only gray tones used unless overlays are selected below",infoFontSize,infoColor);
			}
		}
		if (selEType!=5){
			Dialog.addChoice("Location of " + modeStr + ":", locChoices, locChoices[iLoc]);
			Dialog.setInsets(-3,50,0); /* top,left,bottom */
			Dialog.addMessage("'Under Image' options: Expands the frame. Overrides style options below with simple text",infoFontSize,infoColor);
		}
		else {
			if (compactMenu) Dialog.addChoice("Location of " + modeStr + ":", locChoices, locChoices[iLoc]);
			else Dialog.addRadioButtonGroup("Location of " + modeStr + ":___________", locChoices, 1, locChoices.length, locChoices[iLoc]);
		}
		fancyStyles = newArray("Standard for busy images", "Minimal stroke and shadows", "No fancy formatting");
		iFancy = indexOfArray(fancyStyles, call("ij.Prefs.get", prefsNameKey + ".fancyStyle",  fancyStyles[0]),0);
		if (startsWith(locChoices[iLoc],"Under")) fancyStyle = "No fancy formatting"; /* Overrides preferences because there is no point to fancy formatting on a plain background */
		if (compactMenu) Dialog.addChoice("Choose fancy style:___________", fancyStyles, fancyStyles[iFancy]);
		else Dialog.addRadioButtonGroup("Choose fancy style:___________", fancyStyles, 1, 3, fancyStyles[iFancy]);
		fancyStyleEffectsOptions = newArray("No text", "No shadows", "Raised", "Recessed", "Transparent");
		if ((imageAR>=2 && selEType!=5) || startsWith(locChoices[iLoc],"Under")) sideBySide = true;
		else sideBySide = false;
		if (startsWith(fancyStyle,"No") || startsWith(locChoices[iLoc],"Under")){
			noShadow = true;
			noOutline = true;
			raised = false;
		}
		else {
			noShadow = false;
			noOutline = false;
			raised = false;
		}
		fancyStyleEffectsDefaults = newArray(false,noShadow,raised,raised,false);
		if (selEType!=5){
			fancyStyleEffectsDefaults = Array.concat(fancyStyleEffectsDefaults,sideBySide);
			fancyStyleEffectsOptions = Array.concat(fancyStyleEffectsOptions, "Side-by-Side");
		}
		fancyStyleEffectsPrefs = call("ij.Prefs.get", prefsNameKey + ".fancyStyleEffects","not found");
		if (fancyStyleEffectsPrefs!="not found"){
			fancyStyleEffects = split(fancyStyleEffectsPrefs, "|");
			for (i=0; i<fancyStyleEffects.length && i<fancyStyleEffectsOptions.length; i++)  fancyStyleEffectsDefaults[i] = fancyStyleEffects[i];
		}
		Dialog.setInsets(5, 0, -8);
		Dialog.addMessage("Text style modifiers \('Recessed' and 'Raised' do not apply to overlays, 'Under Image' not styled\):",infoFontSize,infoColor);
		fSL = fancyStyleEffectsOptions.length;
		fSColumns = minOf(6,fSL);
		fSRows = round(fSL/fSColumns);
		if (fSColumns*fSRows<fSL) fSRows +=1;
		Dialog.addCheckboxGroup(fSRows,fSColumns,fancyStyleEffectsOptions,fancyStyleEffectsDefaults);
		sBStyleChoices = newArray("Solid Bar", "I-Bar", "Open Arrow", "Open Arrows", "Filled Arrow", "Filled Arrows", "Notched Arrow", "Notched Arrows");
		iSBS = indexOfArray(sBStyleChoices, call("ij.Prefs.get", prefsNameKey + ".style",sBStyleChoices[0]),0);
		if (compactMenu) Dialog.addChoice("Bar styles and formatting:___________", sBStyleChoices, sBStyleChoices[iSBS]);
		else Dialog.addRadioButtonGroup("Bar styles and formatting:___________", sBStyleChoices, 2, 4, sBStyleChoices[iSBS]);
		if (selEType==5){
			if (compactMenu){
				Dialog.setInsets(-33,410,-10);
				Dialog.addMessage("Single arrow points in\nthe direction drawn",infoFontSize,infoColor);
			} 
			else Dialog.addMessage("Single arrow points in the direction drawn",infoFontSize,infoColor);
		} 
		barHThicknessChoices = newArray("Small", "Medium", "Large");
		iHT = indexOfArray(barHThicknessChoices, call("ij.Prefs.get", prefsNameKey + ".barHeader.thickness", barHThicknessChoices[0]),0);
		Dialog.addChoice("Arrowhead/bar header thickness",barHThicknessChoices, barHThicknessChoices[iHT]);
		Dialog.addNumber("X offset from edge \(minimum\)", selOffsetX,0,1,"pixels");
		Dialog.addNumber("Y offsetfrom edge \(minimum\)", selOffsetY,0,1,"pixels \(" + divChar + "2 for \"Under\" locations");
		fontNameChoice = getFontChoiceList();
		fontChoiceText = "Font name:";
		if (indexOfArrayThatContains(fontNameChoice,"Black",-1)<0 && indexOfArrayThatContains(fontNameChoice,"ExtraBold",-1)<0)
			Dialog.addMessage("No 'Black' or 'ExtraBold' fonts found: These work best here", infoFontSize, infoWarningColor); 
		else if (indexOfArrayThatContains(fontNameChoice,"Black",-1)>0 && indexOfArrayThatContains(fontNameChoice,"ExtraBold",-1)>0) fontChoiceText = "Font name \('Black' or 'ExtraBold' recommended\):";
		iFN = indexOfArray(fontNameChoice, call("ij.Prefs.get", prefsNameKey + ".font",fontNameChoice[0]),0);
		Dialog.addChoice(fontChoiceText, fontNameChoice, fontNameChoice[iFN]);
		outputLabel = "Output";
		if (imageDepth==16 || imageDepth==32){
			newChoices = newArray("New 8-bit image"); /* Fancy style effects do not work for 16-bit images */
			if (compactMenu) outputLabel += " \(8-bit or RGB image required for fancy effects\):";
			else outputLabel += " \(image needs to be converted to 8-bit to display all the fancy style effects\):______________";
		}
		else {
			newChoices = newArray("New image", "Add to image");
			if (compactMenu) outputLabel += " \('Add to image' modifies current image\):";
			else outputLabel += " \('Add to image' will modify the current image\):_______________________";
		}
		overwriteChoices = newArray("Add as overlays");
		if (imageWidth<=23000) overwriteChoices = Array.concat(newChoices, overwriteChoices);
		iOver = indexOfArray(overwriteChoices, call("ij.Prefs.get", prefsNameKey + ".output",overwriteChoices[0]),0);
		if (compactMenu) Dialog.addChoice(outputLabel, overwriteChoices, overwriteChoices[iOver]);
		else Dialog.addRadioButtonGroup(outputLabel, overwriteChoices, 1, lengthOf(overwriteChoices),overwriteChoices[iOver]);
		if (overlayN > 0 && fScaleBarOverlays > 0){
				Dialog.setInsets(0, 235, 0);
				Dialog.addCheckbox("Remove the " + fScaleBarOverlays + " existing named scale bar overlays", true);
		}
		if (overlayN > fScaleBarOverlays){
				Dialog.setInsets(0, 235, 0);
				Dialog.addCheckbox("Remove all " + overlayN + " existing overlays \(simple text is unnamed\)", remAllOverlays);
		}
		if (imageDepth!=24){
			Dialog.setInsets(5, 75, 0); /* top,left,bottom */
			Dialog.addChoice("Overlay color of " + modeStr + " and text:", colorChoices, colorChoices[iTC]);
			Dialog.setInsets(0, 75, 5); /* top,left,bottom */
			Dialog.addChoice("Overlay outline (background) color:", colorChoices, colorChoices[iBC]);
		}
		if (slices>1) Dialog.addString("Slice range for labeling \(1-"+slices+"\):", startSliceNumber+"-"+slices, 20);
		else if (channels>1) Dialog.addMessage("All "+channels+" channels will be identically labeled.", infoFontSize, warningColor);
		finalOptions = newArray("Tweak formatting?","Diagnostic mode?");
		finalOptionsChecks = newArray(false,false);
		if (imageDir!=""){
			if (lengthOf(imageDir)>50) outputD = substring(imageDir,0,25) + "..." + substring(imageDir,lengthOf(imageDir)-25);
			else outputD = imageDir;
			Dialog.addMessage("Files saved to " + outputD + " \('+scale' added to name\)", infoFontSize, infoColor);
		}
		finalOptions = Array.concat("saveTIFF", "saveJPEG", finalOptions);
		finalOptionsChecks =Array.concat(call("ij.Prefs.get", prefsNameKey + ".output.saveTIFF", 1), call("ij.Prefs.get", prefsNameKey + ".output.saveJPEG", 1), finalOptionsChecks);
		Dialog.addCheckboxGroup(1, finalOptions.length, finalOptions, finalOptionsChecks);
	Dialog.show();
		selLengthInUnits = Dialog.getNumber;
		if (selEType==5){
			angleLabel = Dialog.getString;
			angleSeparator = Dialog.getString;
			textLabel = Dialog.getString;
		}
		if (sF>0) overrideUnit = Dialog.getChoice;
		else overrideUnit = "";
		fontSize =  Dialog.getNumber;
		sbHeightPC = Dialog.getNumber;
		if (imageDepth==24){
			scaleBarColor = Dialog.getChoice;
			outlineColor = Dialog.getChoice;
		}
		else {
			scaleBarColor = Dialog.getChoice;
			outlineColor = Dialog.getChoice;
		}
		if (selEType!=5 || compactMenu) selPos = Dialog.getChoice;
		else selPos = Dialog.getRadioButton();
		if (compactMenu) fancyStyle = Dialog.getChoice();
		else fancyStyle = Dialog.getRadioButton();
		/* fancy style effects checkbox group order: 	"No text", "No shadows", "Raised", "Recessed", Side-by-side */
		noText = Dialog.getCheckbox();
		fancyStyleEffectsString = "" + d2s(noText,0);
		noShadow = Dialog.getCheckbox();
		fancyStyleEffectsString += "|" + d2s(noShadow,0);
		raised = Dialog.getCheckbox();
		fancyStyleEffectsString += "|" + d2s(raised,0);
		recessed = Dialog.getCheckbox();
		fancyStyleEffectsString += "|" + d2s(recessed,0);
		transparent = Dialog.getCheckbox();
		fancyStyleEffectsString += "|" + d2s(transparent,0);
		if (selEType!=5) sideBySide = Dialog.getCheckbox();
		/* End of checkbox group */
		/* Overrides: */
		if (startsWith(fancyStyle,"No") || startsWith(selPos,"Under")){
			notFancy = true;
			noShadow = true;
			noOutline = true;
			raised = false;
			transparent = false;
		}
		else {
			noShadow = false;
			noOutline = false;
		}
		if (compactMenu) sBStyle = Dialog.getChoice;
		else sBStyle = Dialog.getRadioButton;
		barHThickness = Dialog.getChoice;
		selOffsetX = Dialog.getNumber;
		selOffsetY = Dialog.getNumber;
		// fontStyle = Dialog.getChoice;
		fontName = Dialog.getChoice;
		if (compactMenu) overWrite = Dialog.getChoice();
		else overWrite = Dialog.getRadioButton();
		if(overlayN > 0 && fScaleBarOverlays > 0) remOverlays = Dialog.getCheckbox();
		else remOverlays = false;
		if(overlayN > fScaleBarOverlays) remAllOverlays = Dialog.getCheckbox();
		else remAllOverlays = false;
		allSlices = false;
		labelRest = true;
		if (slices>1) {
			sliceRangeS = Dialog.getString; /* changed from original to allow negative values - see below */
			sliceRange = split(sliceRangeS, "-");
			if (sliceRange.length==2) {
				startSliceNumber = parseInt(sliceRange[0]);
				endSlice = parseInt(sliceRange[1]);
			}
			if ((startSliceNumber==0) && (endSlice==slices)) allSlices=true;
			if (startSliceNumber==endSlice) labelRest=false;
		}
		else {startSliceNumber = 1;endSlice = 1;}
		if (sF>0) {
			oU = indexOfArray(newUnits, overrideUnit,0);
			oSF = nSF[oU];
			selectedUnit = overrideUnitChoices[oU];
		}
		if (imageDepth!=24){
			scaleBarColorOv = Dialog.getChoice;
			outlineColorOv = Dialog.getChoice;
		}
		saveTIFF =  Dialog.getCheckbox();
		call("ij.Prefs.set", prefsNameKey + ".output.saveTIFF", saveTIFF);
		saveJPEG =  Dialog.getCheckbox();
		call("ij.Prefs.set", prefsNameKey + ".output.saveJPEG", saveJPEG);
		tweakF = Dialog.getCheckbox();
		diagnostics = Dialog.getCheckbox();
		/*    End of Main Dialog   */
	if (notFancy && ((bgIpc<3 && endsWith(scaleBarColor,"black")) || (bgIpc>97 && endsWith(scaleBarColor,"white")))){
		Dialog.create("No-contrast warning");
		contrastTxt = "The background intensity is " + bgIpc + "%, and also the scale bar color is " + scaleBarColor;
			Dialog.addMessage(contrastTxt, infoFontSize, infoWarningColor);
			Dialog.addCheckbox("Reverse colors?",true);
		Dialog.show();
		if (Dialog.getCheckbox()){
			if (bgIpc<3) scaleBarColor = replace(scaleBarColor,"black","white");
			else scaleBarColor = replace(scaleBarColor,"white","black");
		}
	}
	if (startsWith(selPos,"Under")){
		selOffsetY /= 2;
		reverseContrast = false;
		if (bgIpc<3 && endsWith(outlineColor,"white")) reverseContrast = true;
		if (bgIpc>97 && endsWith(outlineColor,"black")) reverseContrast = true;
		if (!sideBySide || reverseContrast){
			if (reverseContrast){
				contrastTxt = "The background intensity is " + bgIpc + "%, whereas the expansion color is " + outlineColor;
				if (bgIpc<3){
					yesLabel = "Change background to black";
					if (scaleBarColor=="black") yesLabel += ", and scale bar to white";
				} 
				else {
					yesLabel = "Change background to white";
					if (scaleBarColor=="white") yesLabel += ", and scale bar to black";
				} 
				noLabel = "No change";
			}
			Dialog.create("'Under' scale bar tweaks");
				if (reverseContrast){
					Dialog.addMessage(contrastTxt, infoFontSize, infoWarningColor);
					Dialog.addCheckbox(yesLabel,reverseContrast);
				}
				Dialog.addCheckbox("Side-by-side scale bar and scale?",sideBySide);
			Dialog.show();
				if (reverseContrast) reverseContrast = Dialog.getCheckbox();
				sideBySide = Dialog.getCheckbox();
			if (reverseContrast){
				if (bgIpc<3){
					outlineColor = "black";
					if (scaleBarColor=="black") scaleBarColor = "white";				
				}
				else{
					outlineColor = "white";
					if (scaleBarColor=="white") scaleBarColor = "black";				
				}
			}
		}
	}
	if (endsWith(overWrite,"overlays")) applyOverlays = true;
	else  applyOverlays = false;
	if (fontName=="SansSerif" || fontName=="Serif" || fontName=="Monospaced") fontStyle = "bold antialiased";
	else fontStyle = "antialiased";
	setFont(fontName,fontSize,fontStyle);
	if (noShadow && noOutline && !raised && !recessed) notFancy = true;
	selLengthInPixels = selLengthInUnits / pixelWidth;
	if (sF>0) selLengthInUnits *= oSF; /* now safe to change units */
	if (textLabel!="") label = textLabel; /* textLabel is only in menu if in line mode */
	if (textLabel=="" || endsWith(textLabel, ":") || endsWith(textLabel, ": ")) {
		if (selEType!=5 || (selEType==5 && trueDPMax<=0)) selLengthLabel = removeTrailingZerosAndPeriod(toString(selLengthInUnits));
		else selLengthLabel = d2s(selLengthInUnits, trueDPMax);
		if (endsWith(textLabel,":") || endsWith(textLabel,": ")) label += " " + selLengthLabel + " " + selectedUnit;
		else label = selLengthLabel + " " + selectedUnit;
	}
	if (selEType==5 && (textLabel=="" || endsWith(textLabel, ":") || endsWith(textLabel, ": "))){
		if (angleSeparator!="No angle label") label += angleSeparator + " " + angleLabel + degChar;
	}
	lWidth = getStringWidth(label);
	labelSemiL = lWidth/2;
	if (!noText && !sideBySide && selEType!=5){
		stringOF = 0.9 * lWidth/selLengthInPixels;
		if (!startsWith(selPos,"Under") && stringOF > 1) {
			shrinkFactor = getNumber("Initial label '" + label + "' is " + stringOF + "x scale bar \(+10% margin\); shrink font by x", 1/stringOF);
			fontSize *= shrinkFactor;
			setFont(fontName,fontSize);
			lWidth = getStringWidth(label);
			labelSemiL = lWidth/2;
		}
		else if (startsWith(selPos,"Under")) {
			stringFL = (1.1 * (lWidth + selLengthInPixels) + selOffsetX)/imageWidth;
			if (stringFL > 1) exit("Combined scale width and text are too long for the 'Under' option");
		}
	}
	if (startsWith(fancyStyle,"Minimal")){
		dOutS = 1.5; /* default outline stroke: % of font size */
		dShO = 1.5;  /* default outer shadow drop: % of font size */
		dIShO = 1; /* default inner shadow drop: % of font size */
		/* set default tweaks */
		outlineStroke = maxOf(1,dOutS);
		shadowDrop = maxOf(outlineStroke,dShO);
		shadowDisp = maxOf(outlineStroke,dShO);
		shadowBlur = maxOf(outlineStroke,0.75*dShO);
	}
	if (!notFancy){
		if (tweakF){
			  Dialog.create("Scale Bar Format Tweaks: " + macroL);
			Dialog.addMessage("Font size \(FS\): " + fontSize, infoFontSize, infoColor);
			Dialog.addNumber("Outline stroke:",dOutS,1,3,"% of font size \(\"%FS\"\)");
			if (!noShadow) {
				Dialog.addNumber("Shadow drop: " + plusminus, dShO, 1, 3,"%FS");
				Dialog.addNumber("Shadow shift \(+ve right\)",dShO,1,3,": %FS");
				Dialog.addNumber("Shadow Gaussian blur:", maxOf(0.5,0.75*dShO),1,3,"%FS");
				Dialog.addNumber("Shadow darkness \(darkest = 100%\):", 30,1,3,"% \(negative = glow\)");
			}
			  Dialog.show();
			outlineStroke = Dialog.getNumber;
			if (!noShadow) {
				shadowDrop = Dialog.getNumber;
				shadowDisp = Dialog.getNumber;
				shadowBlur = Dialog.getNumber;
				shadowDarkness = Dialog.getNumber;
			}
		}
	}
	if (!diagnostics) {
		if(imageWidth+imageHeight>20000)	setBatchMode("hide");  /* a little help for large images */
		else setBatchMode(true);
	}
	 /* save last used color settings in user in preferences */
	fontHeight = getValue("font.height");
	spaceWidth = getStringWidth(" ");
	pxConv = fontHeight/fontSize;
	fontLineWidth = getStringWidth("!");
	sbHeight = maxOf(2,round(fontLineWidth*sbHeightPC/100)); /*  set minimum default bar height as 2 pixels */
	if (imageDepth==24){
		call("ij.Prefs.set", prefsNameKey + ".font.color", scaleBarColor);
		call("ij.Prefs.set", prefsNameKey + ".outline.color", outlineColor);
		if (applyOverlays){
			scaleBarColorOv = scaleBarColor;
			outlineColorOv = outlineColor;
		}
	}
	else {
		if (applyOverlays){
			scaleBarColor = scaleBarColorOv;
			outlineColor = outlineColorOv;
			call("ij.Prefs.set", prefsNameKey + ".font.color", scaleBarColor);
			call("ij.Prefs.set", prefsNameKey + ".outline.color", outlineColor);
		}
		else {
			call("ij.Prefs.set", prefsNameKey + ".font.gray", scaleBarColor);
			call("ij.Prefs.set", prefsNameKey + ".outline.gray", outlineColor);
		}
	}
	tS = "" + stripKnownExtensionFromString(unCleanLabel(activeImage));
	if (selEType!=5){
		if (endsWith(tS, "_EmbScale")) tS = replace(tS, "_EmbScale", ""); /* just removes my preferred note for embedded scale */
		if (!endsWith(tS, "cale")) tS = tS + "_scale";
	}
	else if (indexOf(tS, "LLabel")<0) tS += "_LLabel";
	c=1;
	tS0 = tS;
	while(isOpen(tS)){
		tS = "" + tS0 + c;
		c++;
	}
	if (remAllOverlays) run("Remove Overlay");
	else if (remOverlays){
		removeOverlaysByName("cale");
		removeOverlaysByName("SB"); /* ImageJ scale bars */
	}
	if (startsWith(overWrite,"New")){
		selectImage(activeImageID);	
		run("Select None");
		run("Duplicate...", "title="+tS+" duplicate");
		if (startsWith(overWrite,"New 8") || startsWith(overWrite,"New R")){
			if (startsWith(overWrite,"New 8")) run("8-bit");
			else run("RGB Color");
			call("ij.Prefs.set", prefsNameKey + ".reduceDepth", true); /* not used here but saved for future version of fast'n fancy variant */
		}
		activeImage = getTitle();
		activeImageID = getImageID();
		imageDepth = bitDepth();
	}
	if (startsWith(selPos,"Under")) {
		expH = fontHeight + 2*selOffsetY;
		if (!sideBySide) expH += 4*sbHeight;
		imageHeight += expH;
	}
	// setFont(fontName,fontSize,fontStyle);
	setFont(fontName,fontSize);
	 /* save last used settings in user in preferences */
	// call("ij.Prefs.set", prefsNameKey + ".font.style", fontStyle);
	call("ij.Prefs.set", prefsNameKey + ".font", fontName);
	call("ij.Prefs.set", prefsNameKey + ".style", sBStyle);
	call("ij.Prefs.set", prefsNameKey + ".barHeightPC",sbHeightPC);
	call("ij.Prefs.set", prefsNameKey + ".fancyStyle", fancyStyle);
	call("ij.Prefs.set", prefsNameKey + ".fancyStyleEffects", fancyStyleEffectsString);
	call("ij.Prefs.set", prefsNameKey + ".location", selPos);
	call("ij.Prefs.set", prefsNameKey + ".output", overWrite);
	call("ij.Prefs.set", prefsNameKey + ".barHeader.thickness", barHThickness);
	// if (imageDepth!=16 && imageDepth!=32 && fontStyle!="unstyled") fontStyle += "antialiased"; /* antialising will be applied if possible */
	fontFactor = fontSize/100;
	if (outlineStroke!=0) outlineStroke = maxOf(1, round(fontFactor * outlineStroke)); /* if some outline is desired set to at least one pixel */
	if (!noShadow) {
		negAdj = 0.5;  /* negative offsets appear exaggerated at full displacement */
		if (shadowDrop<0) shadowDrop *= negAdj;
		if (shadowDisp<0) shadowDisp *= negAdj;
		if (shadowBlur<0) shadowBlur *= negAdj;
		if (shadowDrop>=0) shadowDrop = maxOf(1, round(fontFactor * shadowDrop));
		else if (shadowDrop<=0) shadowDrop = minOf(-1, round(fontFactor * shadowDrop));
		if (shadowDisp>=0) shadowDisp = maxOf(1, round(fontFactor * shadowDisp));
		else if (shadowDisp<=0) shadowDisp = minOf(-1, round(fontFactor * shadowDisp));
		if (shadowBlur>=0) shadowBlur = maxOf(1, round(fontFactor * shadowBlur));
		else if (shadowBlur<=0) shadowBlur = minOf(-1, round(fontFactor * shadowBlur));
		if (selOffsetX<(shadowDisp+shadowBlur+1)) selOffsetX += (shadowDisp+shadowBlur+1);  /* make sure shadow does not run off edge of image */
		if (selOffsetY<(shadowDrop+shadowBlur+1)) selOffsetY += (shadowDrop+shadowBlur+1);
		if (shadowDrop==0 && shadowDisp==0 && shadowBlur==0) noShadow = true;
	}
	if(noOutline){
		outlineStroke = 0;
		outlineStrokePC = 0;
	}
	if (selEType!=5){
		// if (fontStyle=="unstyled") fontStyle="";
		if (selPos == "Top Left") {
			selEX = selOffsetX;
			selEY = selOffsetY;
		} else if (selPos == "Top Right") {
			selEX = imageWidth - selLengthInPixels - selOffsetX;
			selEY = selOffsetY;
		} else if (selPos == "Bottom Center") {
			selEX = imageWidth/2 - selLengthInPixels/2;
			selEY = imageHeight - sbHeight - (selOffsetY);
		} else if (selPos == "Bottom Left") {
			selEX = selOffsetX;
			selEY = imageHeight - sbHeight - (selOffsetY);
		} else if (selPos == "Bottom Right") {
			selEX = imageWidth - selLengthInPixels - selOffsetX;
			selEY = imageHeight - sbHeight - selOffsetY;
		} else if (selPos == "Under Image Left") {
			selEX = selOffsetX;
			selEY = imageHeight - maxOf(fontHeight/2,sbHeight/2) - (selOffsetY);
		} else if (selPos == "Under Image Right") {
			selEX = imageWidth - selLengthInPixels - selOffsetX;
			if (!noText) selEX -= lWidth;
			selEY = imageHeight - maxOf(fontHeight/2,sbHeight/2) - selOffsetY;
		} else if (selPos=="At Center of New Selection"){
			if (is("Batch Mode")==true) setBatchMode("exit & display");	/* toggle batch mode off */
			run("Select None");
			setTool("rectangle");
			title="position";
			msg = "draw a box in the image where you want the scale bar to be centered";
			waitForUser(title, msg);
			getSelectionBounds(newSelEX, newSelEY, newSelEWidth, newSelEHeight);
			selEX = Math.constrain(newSelEX + round((newSelEWidth/2) - maxOf(lWidth,selLengthInPixels)/2),selOffsetX,imageWidth-selOffsetY-selLengthInPixels);
			selEY = Math.constrain(newSelEY + round(newSelEHeight/2) + (sbHeight+fontHeight)/2,selOffsetY,imageHeight-selOffsetY-sbHeight);
			if (is("Batch Mode")==false && !diagnostics) setBatchMode("hide");	/* toggle batch mode back on */
		} else if (selPos=="At Selection Center"){
			selEX = Math.constrain(selEX + round((selEWidth/2) - maxOf(lWidth,selLengthInPixels)/2),selOffsetX,imageWidth-selOffsetY-selLengthInPixels);
			selEY = Math.constrain(selEY + round(selEHeight/2) + (sbHeight+fontHeight)/2,selOffsetY,imageHeight-selOffsetY-sbHeight);
		}
		if (sBStyle!="Solid Bar"){
			if (startsWith(selPos,"Bottom") || startsWith(selPos,"Under")) selEY -= sbHeight/2;
			if (startsWith(selPos,"Top")) selEY += sbHeight;
		}
	}
	else {  /* line label positions */
		rSelLX = Array.rankPositions(selLX);
		if (endsWith(selPos,"tart")){
			iXY1 = 0; iXY2 = 1;
		} else {
			iXY1 = 1; iXY2 = 0;
		}
		if (startsWith(selPos,"Right")){
			if (selLX[iXY1] + 2 * fontLineWidth>imageWidth && lineMidX>imageWidth/2) selPos = "Left of line end";
			else {
				selEX = minOf(selLX[iXY1] + 2 * fontLineWidth, imageWidth - lWidth - fontLineWidth);
				if (selLX[iXY1]>selLX[iXY2]) selEY = Math.constrain(selLY[iXY1]+fontHeight/2, fontHeight, imageHeight - fontHeight);
				else {
					selEY = Math.constrain(selLY[iXY1]+fontHeight, fontHeight, imageHeight - fontHeight);
					selEX = minOf(selEX-fontSize, imageWidth - lWidth - fontLineWidth); 
				} 
			}
		}
		if (startsWith(selPos,"Left")){
			selEX = selLX[iXY1] - fontLineWidth - lWidth;
			if (selLX[iXY1]>selLX[iXY2]){
				selEY = Math.constrain(selLY[iXY1]+fontHeight, fontHeight, imageHeight - fontHeight);
				selEX = minOf(selEX + 5 * fontSize, imageWidth - lWidth - fontLineWidth); 
			} 
			else selEY = Math.constrain(selLY[iXY1]-fontHeight/2, fontHeight, imageHeight - fontHeight);
			if (selEX<0){
				selEX = 2 * fontLineWidth;
			}
			selEX = maxOf(selLX[iXY1] - fontLineWidth - lWidth, 2 *fontLineWidth);
			if (selEY<0){
				selEX = 2 * fontLineWidth;
			}
		}
		else if (selPos=="Over center"){
			selEX = Math.constrain(lineMidX - lWidth/2, 2 *fontLineWidth, imageWidth - lWidth);
			if (abs(lineAngle)<10) selEY = Math.constrain(lineMidY - fontHeight/4, fontHeight, imageHeight-fontHeight);
			else selEY = Math.constrain(lineMidY, fontHeight, imageHeight-fontHeight);
		}
	}
	 /*  edge limits for bar - assume intent is not to annotate edge objects */
	maxSelEY = imageHeight - round(sbHeight/2) + selOffsetY;
	selEY = maxOf(minOf(selEY,maxSelEY),selOffsetY);
	maxSelEX = imageWidth - (selLengthInPixels + selOffsetX);
	/* stop overrun on scale bar by label and side-by-side label adjustments */
	if (sideBySide){
		spaceWidth *= 2; /* tweaks for better spacing for side-by-side */
		sbsWidth = lWidth + spaceWidth + selLengthInPixels;
		if (sbsWidth>imageWidth) exit("The selected side-by-side scale bar is too wide for the image");
		sbsHeight = maxOf(fontHeight,sbHeight);
		/* adjust for side-by-side orientation */
		if ((selEX + sbsWidth + selOffsetX)>imageWidth) selEX = maxOf(selOffsetX, imageWidth - sbsWidth - selOffsetX);
		selEY = Math.constrain(selEY, selOffsetY + sbHeight, imageHeight - fontHeight/2 - selOffsetY);
		if (selPos=="At Selection Center") selEY -= fontHeight/2;
		finalLabelY = selEY + fontHeight/2 ;
		if (endsWith(selPos,"Left")) finalLabelX = selEX + spaceWidth + selLengthInPixels;
		else if (endsWith(selPos,"Right")){
			finalLabelX = imageWidth - lWidth - selOffsetX;
			selEX = finalLabelX - selLengthInPixels - spaceWidth;			
		} 
		else finalLabelX = selEX + spaceWidth + selLengthInPixels;
	}
	else if (selEType!=5){
		selEX = maxOf(minOf(selEX,maxSelEX),selOffsetX);
		/* stop text overrun */
		stringOver = (lWidth-selLengthInPixels*0.8);
		endPx = selEX+lWidth;
		oRun = endPx - imageWidth + selOffsetX;
		if (oRun > 0) selEx -= oRun;
		/* Adjust label location */
		if (selEY<=1.5*fontHeight)
				textYcoord = selEY + sbHeight + fontHeight;
		else textYcoord = selEY - sbHeight;
		textXOffset = round((selLengthInPixels - getStringWidth(label))/2);
		finalLabelX = selEX + textXOffset;
		finalLabelY = textYcoord;
	}
	else {
		maxLabelEx = imageWidth-(selOffsetX + label.length);
		finalLabelX = maxOf(minOf(selEX,maxLabelEx),selOffsetX);
		finalLabelY = maxOf(selOffsetY+fontSize, minOf(imageHeight-selOffsetY,selEY));
	}
	if (startsWith(sBStyle,"Solid")) arrowStyle = "headless";
	else if (startsWith(sBStyle,"I-Bar")) arrowStyle = "bar";
	else if (startsWith(sBStyle,"Open")) arrowStyle = "open";
	else if (startsWith(sBStyle,"Filled")) arrowStyle = "filled";
	else if (startsWith(sBStyle,"Notched"))  arrowStyle = "notched";
	else arrowStyle = "";
	if (arrowStyle!=""){
		if (endsWith(sBStyle,"s")) arrowStyle += " double";
		if (transparent) arrowStyle += " outline";
		arrowStyle += " " + barHThickness;
	}
	if (notFancy && transparent && applyOverlays) simpleTransOv = true;
	else simpleTransOv = false;
	if (startsWith(selPos,"Under")) {
		originalBGCol = Color.background;
		setBackgroundFromColorName(outlineColor);
		run("Canvas Size...", "width="+imageWidth+" height="+imageHeight+" position=Top-Center");
		if (!startsWith(overWrite,"New"))	rename(stripKnownExtensionFromString(unCleanLabel(activeImage)) + "_exp");
		Color.setBackground(originalBGCol);
	}
	if (!notFancy || simpleTransOv){
		/* Create new image that will be used to create bar/label */
		newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
		setColor(255,255,255);
		/* Although text should overlap any bar we write it first here so that we can also create a separate text mask to use later */
		if (!noText){
			tempID = getImageID;
			newImage("text_mask", "8-bit black", imageWidth, imageHeight, 1);
			writeLabel7(fontName, fontSize, "white", label,finalLabelX, finalLabelY, false);
			if(!is("binary")){
				setThreshold(0, 128);
				setOption("BlackBackground", false);
				run("Convert to Mask");
			}
			run("Select None");
			selectImage(tempID);
		}
		if (sBStyle=="Solid Bar" && selEType!=5) fillRect(selEX, selEY, selLengthInPixels, sbHeight); /* Rectangle drawn to produce thicker bar */
		else {
			if (selEType!=5) makeArrow(selEX,selEY,selEX+selLengthInPixels,selEY,arrowStyle);
			else makeArrow(selLX[0],selLY[0],selLX[1],selLY[1],arrowStyle); /* Line location is as drawn (no offsets) */
			Roi.setStrokeColor("white");
			Roi.setStrokeWidth(sbHeight/2);
			run("Add Selection...");
			Overlay.flatten;
			run("8-bit");
			closeImageByTitle("label_mask");
			rename("label_mask");
		}
		setThreshold(0, 128);
		setOption("BlackBackground", false);
		run("Convert to Mask");
		run("Select None");
		newImage("outline_template", "8-bit black", imageWidth, imageHeight, 1);
		getSelectionFromMask("label_mask");
		run("Enlarge...", "enlarge="+outlineStroke+" pixel");
		run("Invert");
		getSelectionFromMask("label_mask");
		run("Invert");
		run("Select None");
		run("Convert to Mask");
		/* Now create outline around text in case of overlap */
		if (!noText){
			newImage("outline_text", "8-bit black", imageWidth, imageHeight, 1);
			// if (!is("binary")) run("Convert to Mask");
			getSelectionFromMask("text_mask");
			safeColornameFill("white");
			run("Enlarge...", "enlarge="+outlineStroke+" pixel");
			run("Invert");	
			run("Select None");
			run("Convert to Mask");
			imageCalculator("Max", "outline_template","outline_text");
			imageCalculator("XOR create", "outline_template","label_mask");
			selectWindow("Result of outline_template");
			rename("outline_filled");
			imageCalculator("OR", "label_mask","outline_text");
			selectWindow("outline_filled");
			getSelectionFromMask("text_mask");
			run("Enlarge...", "enlarge="+outlineStroke+" pixel");
			safeColornameFill("white");
			run("Select None");
			selectWindow("label_mask");
			getSelectionFromMask("text_mask");
			safeColornameFill("white");
			selectWindow("outline_template");
			if (is("Inverting LUT")) run("Invert LUT");
			o_tBG = getPixel(0,0);
			getSelectionFromMask("label_mask");
			if (o_tBG==0) safeColornameFill("black");
			else safeColornameFill("white");
			run("Select None");
		}
		else {
			newImage("outline_filled", "8-bit black", imageWidth, imageHeight, 1);
			getSelectionFromMask("label_mask");
			run("Enlarge...", "enlarge="+outlineStroke+" pixel");
			safeColornameFill("white");
		}
		/* If Overlay chosen add fancy scale bar as overlay */
		if (endsWith(overWrite,"verlays")) {
			/* Create shadow and outline selection masks to be used for overlay components */
			scaleBarColorHex = getHexColorFromColorName(scaleBarColor);
			outlineColorHex = getHexColorFromColorName(outlineColor);
			if(!noShadow && isOpen("label_mask")) { /* Create ovShadowMask */
				selectWindow("label_mask");
				run("Select None");
				run("Duplicate...", "title=ovShadowMask");
				getSelectionFromMask("label_mask");
				getSelectionBounds(xShad, yShad, wShad, hShad);
				setSelectionLocation(xShad+shadowDisp, yShad+shadowDrop);
				dilation = outlineStroke + maxOf(1,round(shadowBlur/2));
				run("Enlarge...", "enlarge="+dilation+" pixel");
				setBackgroundFromColorName("white");
				run("Clear", "slice");
				if (transparent){
					getSelectionFromMask("label_mask");
					setBackgroundFromColorName("black");
					run("Clear", "slice");
				}
				run("Select None");
			}
			/* shadow and outline selection masks have now been created */
			selectImage(activeImageID);
			for (sl=startSliceNumber; sl<endSlice+1; sl++) {
				setSlice(sl);
				if (allSlices) sl=0;
				if (!noShadow && isOpen("ovShadowMask")) {
					getSelectionFromMask("ovShadowMask");
					List.setMeasurements;
					bgGray = List.getValue("Mean");
					List.clear();
					if (imageDepth==16 || imageDepth==32) bgGray = round(bgGray/256);
					grayHex = toHex(round(bgGray*(100-shadowDarkness)/100));
					shadowHex = "#" + ""+pad(grayHex) + ""+pad(grayHex) + ""+pad(grayHex);
					setSelectionName("Scale bar shadow");
					run("Add Selection...", "fill="+shadowHex);
				}
				if (isOpen("outline_template")){
					getSelectionFromMask("outline_template");
					wait(10);
					getSelectionBounds(gSelX,gSelY,gWidth,gHeight);
					if (diagnostics) IJ.log("Outline bounds: " + gSelX + ", " + gSelY + ", " + gWidth + ", " + gHeight);
					if(gSelX==0 && gSelY==0 && gWidth==Image.width && gHeight==Image.height)	run("Make Inverse");
					setSelectionName("Scale bar outline " + outlineColor);
					run("Add Selection...", "fill="+outlineColorHex);
				}
				/* alignment of overlay drawn text varies with font so the label_mask is reused instead of redrawing the text directly */
				if (!transparent && isOpen("label_mask")) {
					getSelectionFromMask("label_mask");
					setSelectionName("Scale label " + scaleBarColor);
					run("Add Selection...", "fill=" + scaleBarColorHex);
					Overlay.setPosition(sl);
					run("Select None");
					if (allSlices) sl = endSlice+1;
				}
			}
			run("Select None");
			closeImageByTitle("ovShadowMask");
		}
		/* End overlay + (!(startsWith(fancyStyle,"No")) fancy scale bar section  */
		else {
			/* Create shadow and outline selection masks to be used for bitmap components */
			if(!noShadow) createShadowDropFromMask7Safe("label_mask", shadowDrop, shadowDisp, shadowBlur, shadowDarkness, outlineStroke);
			if (startsWith(overWrite,"Add to image")) tS = activeImage;
			selectImage(activeImageID);
			if (slices==1 && channels>1){  /* process channels instead of slices */
				labelChannels = true;
				startSliceNumber = 1;
				endSlice = channels;
			}
			else labelChannels = false;
			for (sl=startSliceNumber; sl<endSlice+1; sl++) {
				if (labelChannels) Stack.setChannel(sl);
				else setSlice(sl);
				run("Select None");
				if(!noShadow && shadowDarkness!=0){
					if (shadowDarkness>0) imageCalculator("Subtract", tS,"shadow");
					else imageCalculator("Add", tS,"shadow");
				}
				run("Select None");
				if (!noOutline){
					/* apply outline around label */
					if (isOpen("outline_filled")){
						if(!transparent) getSelectionFromMask("outline_filled");
						else getSelectionFromMask("outline_template");
					}
					if (selectionType>=0){
						setBackgroundFromColorName(outlineColor);
						run("Clear", "slice");
						if (fontSize>=12 && !applyOverlays){
							run("Enlarge...", "enlarge=1 pixel");
							run("Gaussian Blur...", "sigma=0.55");
							run("Convolve...", "text1=[-0.0556 -0.0556 -0.0556 \n-0.0556 1.4448  -0.0556 \n-0.0556 -0.0556 -0.0556] slice"); /* moderate sharpen */
						}
						run("Select None");
					}
				}
				/* color label */
				// setColor("red");
				if(!transparent) {
					setColorFromColorName(scaleBarColor);
					if (!noText) writeLabel7(fontName, fontSize, scaleBarColor, label, finalLabelX, finalLabelY, true);
					if (sBStyle=="Solid Bar" && selEType!=5) fillRect(selEX, selEY, selLengthInPixels, sbHeight); /* Rectangle drawn to produce thicker bar */
					else {
						if (selEType!=5) makeArrow(selEX,selEY,selEX+selLengthInPixels,selEY,arrowStyle);
						else makeArrow(selLX[0],selLY[0],selLX[1],selLY[1],arrowStyle); /* Line location is as drawn (no offsets) */
						if(sBStyle=="Solid Bar") Roi.setStrokeWidth(sbHeight);
						else Roi.setStrokeWidth(sbHeight/2);
						run("Fill"); /* safeColornameFill does not work here - fill only one arrow head! */
					}
					run("Select None");
					if (!noText && (imageDepth==16 || imageDepth==32)) writeLabel7(fontName, fontSize, scaleBarColor, label, finalLabelX, finalLabelY, true); /* force anti-aliasing */
					if (!noText){
						getSelectionFromMask("outline_text");
						safeColornameFill(outlineColor);
						run("Select None");
					}
				}
				if (raised || recessed){
					outlineRGBs = getColorArrayFromColorName(outlineColor);
					Array.getStatistics(outlineRGBs, null, null, outlineColorMean, null);
					scaleBarRGBs = getColorArrayFromColorName(scaleBarColor);
					Array.getStatistics(scaleBarRGBs, null, null, scaleBarColorMean, null);
					if (outlineColorMean>scaleBarColorMean){
						if (raised && !recessed){
							raised = false;
							recessed = true;
						}
						else if (!raised && recessed){
							raised = true;
							recessed = false;
						}
					}
					fontLineWidth = getStringWidth("!");
					rAlpha = fontLineWidth/40;
					if(raised) {
						getSelectionFromMask("label_mask");
						if(!noOutline) run("Enlarge...", "enlarge=1 pixel");
						run("Convolve...", "text1=[ " + createConvolverMatrix("raised",fontLineWidth) + " ] slice");
						if (rAlpha>0.33) run("Gaussian Blur...", "sigma="+rAlpha);
						run("Select None");
					}
					if(recessed) {
						getSelectionFromMask("label_mask");
						if(!noOutline && !raised) run("Enlarge...", "enlarge=1 pixel");
						run("Enlarge...", "enlarge=1 pixel");
						run("Convolve...", "text1=[ " + createConvolverMatrix("recessed",fontLineWidth) + " ] slice");
						if (rAlpha>0.33) run("Gaussian Blur...", "sigma="+rAlpha);
						run("Select None");
					}
				}
			}
		}
		tempTitles = newArray("shadow","label_mask","text_mask","outline_template","outline_text","outline_filled","outline_only_template");
		if (!diagnostics) for(i=0;i<lengthOf(tempTitles);i++) closeImageByTitle(tempTitles[i]);
	}
	else {
		if(!transparent){
			selectImage(activeImageID);
			scaleBarColorHex = getHexColorFromColorName(scaleBarColor);
			setColor(scaleBarColorHex);
			if (applyOverlays) finalLabelY -= fontSize/5;
			for (sl=startSliceNumber; sl<endSlice+1; sl++) {
				setSlice(sl);
				if (allSlices) sl=0;
				if (applyOverlays) {
					/* If Overlay chosen add fancy scale bar as overlay */
					if (!noText) Overlay.drawString(label,finalLabelX,finalLabelY);
					Overlay.show;
					if (selEType!=5) makeArrow(selEX,selEY,selEX+selLengthInPixels,selEY,arrowStyle);
					else makeArrow(selLX[0],selLY[0],selLX[1],selLY[1],arrowStyle); /* Line location is as drawn (no offsets) */
					Roi.setStrokeColor(scaleBarColorHex);
					if(sBStyle=="Solid Bar") Roi.setStrokeWidth(sbHeight);
					else Roi.setStrokeWidth(sbHeight/2);
					setSelectionName("Scale label " + scaleBarColor);
					run("Add Selection...", "fill=" + scaleBarColorHex);
					Overlay.setPosition(sl); /* Sets the stack position (slice number) */
					Overlay.show;
					run("Select None");
				}
				else {
					if (sBStyle=="Solid Bar" && selEType!=5) fillRect(selEX, selEY, selLengthInPixels, sbHeight); /* Rectangle drawn to produce thicker bar */
					else {
						if (selEType!=5) makeArrow(selEX,selEY,selEX+selLengthInPixels,selEY,arrowStyle);
						else makeArrow(selLX[0],selLY[0],selLX[1],selLY[1],arrowStyle); /* Line location is as drawn (no offsets) */
						if(sBStyle=="Solid Bar") Roi.setStrokeWidth(sbHeight);
						else Roi.setStrokeWidth(sbHeight/2);
						run("Fill");
					}
					if (!noText) writeLabel7(fontName, fontSize, scaleBarColor, label, finalLabelX, finalLabelY, true);
					run("Select None");
				}
				if (allSlices) sl = endSlice+1;
			}
		}
		/* End simple-Text fancy scale bar section */
	}
	restoreSettings();
	setSlice(startSliceNumber);
	if (saveJPEG) safeSaveAndClose("jpeg", imageDir, tS, false);
	if (saveTIFF) safeSaveAndClose("tiff", imageDir, tS, false);
	setBatchMode("exit & display"); /* exit batch mode */
	if (applyOverlays) Overlay.selectable(true);
	beep();beep();beep();
	call("java.lang.System.gc");
	showStatus("Fancy Scale Bar Added");
	/* Changelog
	v161008 Centered scale bar in new selection 8/9/2016 and tweaked manual location 8/10/2016.
	v161012 adds unified ASC function list and add 100 µm diameter human hair. v161031 adds "glow" option and sharpens shadow/glow edge.
	v161101 minor fixes v161104 now works with images other than 8-bit too.
	v161105 improved offset guesses.
	v180108 set outline to at least 1 pixel if desired, updated functions and fixed typos.
	v180611 replaced run("Clear" with run("Clear", "slice").
	v180613 works for multiple slices.
	v180711 minor corner positioning tweaks for large images.
	v180722 allows any system font to be used. v180723 Adds some favorite fonts to top of list (if available).
	v180730 rounds the scale bar width guess to two figures.
	v180921 add no-shadow option - useful for optimizing GIF color palettes for animations.
	v180927 Overlay quality greatly improved and 16-bit stacks now finally work as expected.
	v181003 Automatically adjusts scale units to ranges applicable to scale bars.
	v181018 Fixed color issue with scale text and added off-white and off-black for transparent GIFs.
	v181019 Fixed issue with filenames with spaces.
	v181207 Rearrange dialog to use Overlay.setPosition(0) from IJ >1.52i to set the overlay to display on all stack slices. "Replace overlay" now replaces All overlays (so be careful).
	v181217 Removed shadow color option.
	v181219 For overlay version uses text overlays for top layers instead of masks to reduce jaggies.
	v190108 Overlay shadow now always darker than background (or brighter if "glow"). Implemented variable passing by preceding with "&" introduced in ImageJ 1.43.
	v190125 Add "Bottom Center" location.
	v190222 Fixed overlay shadows to work correctly for 16 bit gray and 32-bit image depths. Fixed "no text" option for overlays.
	v190223 Fixed infinite overlay removal loop introduce in V190222  :-$
	v190417 Changed bar thickness from pixels to % of chosen font height so it scales with chosen font. Saves Preferences.
	v190423 Updated indexOfArray function. v190506 removed redundant function code.
	v190524 Added alternatives to simple bar using makeArrow macro function.
	v190528 Restored missing overlay font color line.
	v190618-9 Because 16 and 32-bit images do no anti-alias the fonts an alternative was added, also an emboss effect option was added.
	v190625 Fixed missing bottom and top offset for prior selection. Minor fixes to previous update.
	v190627 Fixed issue with font sizes not being reproducible and text overrunning image edge.
	v190912 Added list of preferred scale bar widths; Now attempts to label all channels for multi-channel stack.
	v190913 Min font size changed to 20. Minimum +offset increased to default outline stroke (6).
	v200302 Added change image type pop-up as 16 and 32 but versions still do not look good.
	v200706-9 Changed to Added RGB to 8 bit conversion options in 1st Dialog.
	v200925 Note "inner-shadow" closing issue fixed by close-image workaround but still not understood.
	v210616 Add ability to label lines with their calibrated lengths v210617 Added text outline for overlaps, fixed alignment of overlay labels v210618 fixed label alignment
	v210621 Finally solved font-sensitive overlay text alignment issue be reusing label mask. Menu made more compact.
	v210701 Moved format tweaks to secondary dialog to simplify use.
	v210730 Remove pre-scaling that caused errors
	v210817 Scale overlays are not removed from original image new scale is being created on copy. Fixed occasional outline expansion error when removing existing overlays
	v210826-8 Added simple text option for black or white backgrounds v210902 bug fix
	v211022 Updated color function choices
	v211025 Updated stripKnownExtensionFromString
	v211104: Updated stripKnownExtensionFromString function    v211112: Again
	v211203: Simple format is now an option in all cases.
	v220304: Simple format now uses chosen colors for more flexibility.
	v220510: Checks to make sure default text color is not the same as the background for simple format f2: updated pad function f3: updated colors
	v220711: Added dialog info showing more precise lengths for non-line selections.
	v220726: Fixes anti-aliasing issue and adds a transparent text option.
	v220808-10: Minor tweaks to inner shadow and font size v220810_f1 updates CZ scale functions only f2: updated colors f3: Updated checkForPlugins function
	v220823: Gray choices for graychoices only. Corrected gray index formulae.
	v220916: Uses imageIDs instead of titles to avoid issues with duplicate image titles. Overlay outlines restored.
	v220920: Allows use of just text for labeling arrows if a line selection is used. Arrow width corrected.
	v220921: Overlay issues with new version of getSelectionFromMask function fixed v220921b: Allows rotation of label text if line selected.
	v221005: Provides option of converting non-standard bit-depths rather than just crashing.
	v230220: Adds "Minimal" style and adds earlier (initial) font size vs scale bar check.
	v230324: Limits choice of type to overlay if the image is wider than 23,000 pixels as large images produce odd results if over this size.
	v230404: Adds "under image" option to scale bars.
	v230405: Added no-inner-shadow option, outline sharpening conditional on font size, streamlined shadow application and updated functions.
	v230407: 'Raised' and 'Recessed' option using convolve replaces inner shadow and emboss. Expanded arrow options and moved the transparency option.
	v230410: Replaced font size with font.height and font spaceWidth for most positions and added d2s to prefs string for consistency.
	v230411: Allows non-square pixels (angles are calculated using true pixel dimensions). Does not override saved default colors based on backgrounds when "Under" locations were last-used.
	v230413: Recessed and Raised effects now use expanding matrices. Font styles removed as they seem to have no impact. Bar thickness now based on '!' character width. 'No-text' option working again.
	v230417-9: Restored missing line length line for distance labels, renamed to be obvious that it is a length in pixels. Location of distance labels still inconsistent though.  f1: updated stripKnownExtensionFromString function.
	v230517: Removed line length correction factor that was not needed with getStringWidth.
	v230518: Fixed non-binary mask issue. F1: updated checkForUnits function f2: updated function stripKnownExtensionFromString.
	v230714: More tweaks for 'Under Image' options. Warning if scale bar units should be changed. v230717 Typos fixed.
	v230718-9: Side-by-side is now a listed option instead of just being automatic for 'under' locations. 'Raised' deactivated for 'Not fancy' and 'under' options. Convolve restricted to slice so stacks should work better now.
	v230721: Restricted non-fancy formatting option to scale bar mode. Simplified main menu.
	v230724: More tweaks to side-by-side positions.	v230725: Removed font size checking for side-by-side orientation. v230728 Change 'At selection' to 'At selection center'.
	v230801: More side-by-side position tweaks.
	v230804: Warning on no-contrast non-fancy color selection. F1: inches conversion
	*/	
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
			v210429 Expandable array version
			v220510 Looks for both class and jar if no extension is given
			v220818 Mystery issue fixed, no longer requires restoreExit	*/
		pluginCheck = false;
		if (getDirectory("plugins") == "") IJ.log("Failure to find any plugins!");
		else {
			pluginDir = getDirectory("plugins");
			if (lastIndexOf(pluginName,".")==pluginName.length-1) pluginName = substring(pluginName,0,pluginName.length-1);
			pExts = newArray(".jar",".class");
			knownExt = false;
			for (j=0; j<lengthOf(pExts); j++) if(endsWith(pluginName,pExts[j])) knownExt = true;
			pluginNameO = pluginName;
			for (j=0; j<lengthOf(pExts) && !pluginCheck; j++){
				if (!knownExt) pluginName = pluginName + pExts[j];
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
			}
		}
		return pluginCheck;
	}
	function checkForUnits() {  /* With CZSEM check Version
		/* v161108 (adds inches to possible reasons for checking calibration)
			This version requires these functions:
			***** checkForPlugin, setScaleFromCZSemHeader, restoreExit *****
			NOTE: restoreExit REQUIRES previous run of saveSettings
			v180820: Checks for CZ header before offering to use it.
			v200508: Simplified
			v200925: Checks also for unit = pixels
			v230524: Added options for X vs Y scales.
			v230801: pixelAR limits used instead of actual pixel dimensions.
			v230808: Allows inches.
		*/
		functionL = "checkForUnits_v230808";
		getPixelSize(unit, pixelWidth, pixelHeight);
		pixAR = pixelWidth/pixelHeight;
		if (pixAR>1.001 || pixAR<0.999 || pixelWidth==1 || unit=="" || startsWith(unit,"inch") || unit=="pixels"){
			rescaleChoices = newArray("Define new units for this image", "Make no changes", "Exit this macro");
			if (pixelWidth!=pixelHeight) rescaleChoices = Array.concat("Set height scale to width scale", "Set width scale to height scale",rescaleChoices);
			Dialog.create("Suspicious Units: " + functionL);
				tiff = matches(getInfo("image.filename"),".*[tT][iI][fF].*");
				if (tiff && (checkForPlugin("tiff_tags.jar"))) {
					tag = call("TIFF_Tags.getTag", getDirectory("image")+getTitle, 34118);
					if (indexOf(tag, "Image Pixel Size = ")>0) rescaleChoices = Array.concat("Set Scale from CZSEM header",rescaleChoices);
				}
				rescaleDialogLabel = "pixelHeight = "+pixelHeight+", pixelWidth = "+pixelWidth+", unit = "+unit+": what would you like to do?";
				if (startsWith(unit,"inch")){
					dpi = 1/pixelWidth;
					unit = "inches";
					rescaleDialogLabel = "dpi = " + dpi + ", " + rescaleDialogLabel;
					rescaleChoices = Array.concat("Convert dpi to metric",rescaleChoices);
				}
				Dialog.addRadioButtonGroup(rescaleDialogLabel, rescaleChoices, rescaleChoices.length, 1, rescaleChoices[0]) ;
			Dialog.show();
				rescaleChoice = Dialog.getRadioButton;
			if (rescaleChoice=="Define new units for this image") run("Set Scale...");
			else if (startsWith(rescaleChoice,"Convert")) run("Set Scale...", "distance="+1/(25.5*pixelWidth)+" known=1 pixel=1 unit=mm");
			else if (startsWith(rescaleChoice,"Exit this macro")) restoreExit("Goodbye");
			else if (startsWith(rescaleChoice,"Set height")) run("Set Scale...", "distance="+1/pixelWidth+" known=1 pixel=1 unit=&unit");
			else if (startsWith(rescaleChoice,"Set width")) run("Set Scale...", "distance="+1/pixelHeight+" known=1 pixel=1 unit=&unit");
			else if (startsWith(rescaleChoice,"Set Scale from CZSEM")){
				setScaleFromCZSemHeader();
				getPixelSize(unit, pixelWidth, pixelHeight);
				if (pixelWidth!=pixelHeight || pixelWidth==1 || unit=="" || unit=="inches") setCZScale=false;
				if(!setCZScale) {
					Dialog.create("Still no standard units");
						Dialog.addCheckbox("pixelWidth = " + pixelWidth + ": Do you want to define units for this image?", true);
					Dialog.show();
						setScale = Dialog.getCheckbox;
					if (setScale)
					run("Set Scale...");
				}
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
	function countOverlaysByName(overlayNameSubstring) {
		/* v210817 1st version  */
		overlayCount = 0;
		if(Overlay.size>0) {
			initialOverlaySize = Overlay.size;
			for (i=0; i<slices; i++){
				for (j=0; j<initialOverlaySize; j++){
					setSlice(i+1);
					if (j<Overlay.size){
						Overlay.activateSelection(j);
						overlaySelectionName = getInfo("selection.name");
						if (indexOf(overlaySelectionName,overlayNameSubstring)>=0) overlayCount++;
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
							if (indexOf(overlaySelectionName,overlayNameSubstring)>=0) overlayCount++;
						}
					}
				}
			}
		}
		run("Select None");
		return overlayCount;
	}
	function createConvolverMatrix(effect,thickness){
		/* v230413: 1st version PJL  Effects assumed: "Recessed or Raised" */
		matrixText = "";
		matrixSize = maxOf(3,(1 + 2*round(thickness/10)));
		matrixLC = matrixSize -1;
		matrixCi = matrixSize/2 - 0.5;
		mFact = 1/(matrixSize-1);
		for(y=0,c=0;y<matrixSize;y++){
			for(x=0;x<matrixSize;x++){
				if(x!=y){
					matrixText +=  " 0";
					if (x==matrixLC) matrixText +=  "\n";
				} 
				else {
					if (x==matrixCi) matrixText +=  " 1";
					else if (effect=="raised"){  /* Otherwise assumed to be 'recessed' */
						if (x<matrixCi) matrixText +=  " -" + mFact;
						else matrixText +=  " " + mFact;
					} 
					else {
						if (x>matrixCi) matrixText +=  " -" + mFact;
						else matrixText +=  " " + mFact;				
					}
				}
			}
		}
		matrixText +=  "\n";
		return matrixText;
	}
	function createShadowDropFromMask7Safe(mask, oShadowDrop, oShadowDisp, oShadowBlur, oShadowDarkness, oStroke) {
		/* Requires previous run of: imageDepth = bitDepth();
		because this version works with different bitDepths
		v161115 calls five variables: drop, displacement blur and darkness
		v180627 adds mask label to variables
		v230405	resets background color after application
		v230418 removed '&'s		*/
		showStatus("Creating drop shadow for labels . . . ");
		newImage("shadow", "8-bit black", imageWidth, imageHeight, 1);
		getSelectionFromMask(mask);
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX + oShadowDisp, selMaskY + oShadowDrop);
		orBG = Color.background;
		Color.setBackground("white");
		if (oStroke>0) run("Enlarge...", "enlarge="+oStroke+" pixel"); /* Adjust shadow size so that shadow extends beyond stroke thickness */
		run("Clear");
		run("Select None");
		if (oShadowBlur>0) {
			run("Gaussian Blur...", "sigma="+oShadowBlur);
			run("Unsharp Mask...", "radius="+oShadowBlur+" mask=0.4"); /* Make Gaussian shadow edge a little less fuzzy */
		}
		/* Now make sure shadow or glow does not impact outline */
		getSelectionFromMask(mask);
		if (oStroke>0) run("Enlarge...", "enlarge="+oStroke+" pixel");
		Color.setBackground("black");
		run("Clear");
		run("Select None");
		/* The following are needed for different bit depths */
		if (imageDepth==16 || imageDepth==32) run(imageDepth + "-bit");
		run("Enhance Contrast...", "saturated=0 normalize");
		divider = (100 / abs(oShadowDarkness));
		run("Divide...", "value="+divider);
		Color.setBackground(orBG);
	}
	function getColorArrayFromColorName(colorName) {
		/* v180828 added Fluorescent Colors
		   v181017-8 added off-white and off-black for use in gif transparency and also added safe exit if no color match found
		   v191211 added Cyan
		   v211022 all names lower-case, all spaces to underscores v220225 Added more hash value comments as a reference v220706 restores missing magenta
		   v230130 Added more descriptions and modified order.
		   v230908: Returns "white" array if not match is found and logs issues without exiting.
		     57 Colors 
		*/
		functionL = "getColorArrayFromColorName_v230911";
		cA = newArray(255,255,255); /* defaults to white */
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
		else if (colorName == "green") cA = newArray(0,255,0);					/* #00FF00 AKA Lime green */
		else if (colorName == "blue") cA = newArray(0,0,255);
		else if (colorName == "cyan") cA = newArray(0, 255, 255);
		else if (colorName == "yellow") cA = newArray(255,255,0);
		else if (colorName == "magenta") cA = newArray(255,0,255);				/* #FF00FF */
		else if (colorName == "pink") cA = newArray(255, 192, 203);
		else if (colorName == "violet") cA = newArray(127,0,255);
		else if (colorName == "orange") cA = newArray(255, 165, 0);
		else if (colorName == "garnet") cA = newArray(120,47,64);				/* #782F40 */
		else if (colorName == "gold") cA = newArray(206,184,136);				/* #CEB888 */
		else if (colorName == "aqua_modern") cA = newArray(75,172,198);		/* #4bacc6 AKA "Viking" aqua */
		else if (colorName == "blue_accent_modern") cA = newArray(79,129,189); /* #4f81bd */
		else if (colorName == "blue_dark_modern") cA = newArray(31,73,125);	/* #1F497D */
		else if (colorName == "blue_honolulu") cA = newArray(0,118,182);		/* Honolulu Blue #006db0 */
		else if (colorName == "blue_modern") cA = newArray(58,93,174);			/* #3a5dae */
		else if (colorName == "gray_modern") cA = newArray(83,86,90);			/* bright gray #53565A */
		else if (colorName == "green_dark_modern") cA = newArray(121,133,65);	/* Wasabi #798541 */
		else if (colorName == "green_modern") cA = newArray(155,187,89);		/* #9bbb59 AKA "Chelsea Cucumber" */
		else if (colorName == "green_modern_accent") cA = newArray(214,228,187); /* #D6E4BB AKA "Gin" */
		else if (colorName == "green_spring_accent") cA = newArray(0,255,102);	/* #00FF66 AKA "Spring Green" */
		else if (colorName == "orange_modern") cA = newArray(247,150,70);		/* #f79646 tan hide, light orange */
		else if (colorName == "pink_modern") cA = newArray(255,105,180);		/* hot pink #ff69b4 */
		else if (colorName == "purple_modern") cA = newArray(128,100,162);		/* blue-magenta, purple paradise #8064A2 */
		else if (colorName == "jazzberry_jam") cA = newArray(165,11,94);
		else if (colorName == "red_n_modern") cA = newArray(227,24,55);
		else if (colorName == "red_modern") cA = newArray(192,80,77);
		else if (colorName == "tan_modern") cA = newArray(238,236,225);
		else if (colorName == "violet_modern") cA = newArray(76,65,132);
		else if (colorName == "yellow_modern") cA = newArray(247,238,69);
		/* Fluorescent Colors https://www.w3schools.com/colors/colors_crayola.asp */
		else if (colorName == "radical_red") cA = newArray(255,53,94);			/* #FF355E */
		else if (colorName == "wild_watermelon") cA = newArray(253,91,120);	/* #FD5B78 */
		else if (colorName == "shocking_pink") cA = newArray(255,110,255);		/* #FF6EFF Ultra Pink */
		else if (colorName == "razzle_dazzle_rose") cA = newArray(238,52,210);	/* #EE34D2 */
		else if (colorName == "hot_magenta") cA = newArray(255,0,204);			/* #FF00CC AKA Purple Pizzazz */
		else if (colorName == "outrageous_orange") cA = newArray(255,96,55);	/* #FF6037 */
		else if (colorName == "supernova_orange") cA = newArray(255,191,63);	/* FFBF3F Supernova Neon Orange*/
		else if (colorName == "sunglow") cA = newArray(255,204,51);			/* #FFCC33 */
		else if (colorName == "neon_carrot") cA = newArray(255,153,51);		/* #FF9933 */
		else if (colorName == "atomic_tangerine") cA = newArray(255,153,102);	/* #FF9966 */
		else if (colorName == "laser_lemon") cA = newArray(255,255,102);		/* #FFFF66 "Unmellow Yellow" */
		else if (colorName == "electric_lime") cA = newArray(204,255,0);		/* #CCFF00 */
		else if (colorName == "screamin'_green") cA = newArray(102,255,102);	/* #66FF66 */
		else if (colorName == "magic_mint") cA = newArray(170,240,209);		/* #AAF0D1 */
		else if (colorName == "blizzard_blue") cA = newArray(80,191,230);		/* #50BFE6 Malibu */
		else if (colorName == "dodger_blue") cA = newArray(9,159,255);			/* #099FFF Dodger Neon Blue */
		else IJ.log(colorName + " not found in " + functionL + ": Color defaulted to white");
		return cA;
	}
	/* Hex conversion below adapted from T.Ferreira, 20010.01 https://imagej.net/doku.php?id=macro:rgbtohex */
	function getHexColorFromColorName(colorNameString) {
		colorArray = getColorArrayFromColorName(colorNameString);
		 r = toHex(colorArray[0]); g = toHex(colorArray[1]); b = toHex(colorArray[2]);
		 hexName= "#" + ""+pad(r) + ""+pad(g) + ""+pad(b);
		 return hexName;
	}
	function pad(n) {
	  /* This version by Tiago Ferreira 6/6/2022 eliminates the toString macro function */
	  if (lengthOf(n)==1) n= "0"+n; return n;
	  if (lengthOf(""+n)==1) n= "0"+n; return n;
	}
	function setBackgroundFromColorName(colorName) {
		colorArray = getColorArrayFromColorName(colorName);
		setBackgroundColor(colorArray[0], colorArray[1], colorArray[2]);
	}
	function setColorFromColorName(colorName) {
		colorArray = getColorArrayFromColorName(colorName);
		setColor(colorArray[0], colorArray[1], colorArray[2]);
	}
  	function getFontChoiceList() {
		/*	v180723 first version
			v180828 Changed order of favorites. v190108 Longer list of favorites. v230209 Minor optimization.
			v230919 You can add a list of fonts that do not produce good results with the macro. 230921 more exclusions.
		*/
		systemFonts = getFontList();
		IJFonts = newArray("SansSerif", "Serif", "Monospaced");
		fontNameChoices = Array.concat(IJFonts,systemFonts);
		blackFonts = Array.filter(fontNameChoices, "([A-Za-z]+.*[bB]l.*k)");
		eBFonts = Array.filter(fontNameChoices,  "([A-Za-z]+.*[Ee]xtra.*[Bb]old)");
		uBFonts = Array.filter(fontNameChoices,  "([A-Za-z]+.*[Uu]ltra.*[Bb]old)");
		fontNameChoices = Array.concat(blackFonts, eBFonts, uBFonts, fontNameChoices); /* 'Black' and Extra and Extra Bold fonts work best */
		faveFontList = newArray("Your favorite fonts here", "Arial Black", "Myriad Pro Black", "Myriad Pro Black Cond", "Noto Sans Blk", "Noto Sans Disp Cond Blk", "Open Sans ExtraBold", "Roboto Black", "Alegreya Black", "Alegreya Sans Black", "Tahoma Bold", "Calibri Bold", "Helvetica", "SansSerif", "Calibri", "Roboto", "Tahoma", "Times New Roman Bold", "Times Bold", "Goldman Sans Black", "Goldman Sans", "Serif");
		/* Some fonts or font families don't work well with ASC macros, typically they do not support all useful symbols, they can be excluded here using the .* regular expression */
		offFontList = newArray("Alegreya SC Black", "Archivo.*", "Arial Rounded.*", "Bodon.*", "Cooper.*", "Eras.*", "Fira.*", "Gill Sans.*", "Lato.*", "Libre.*", "Lucida.*",  "Merriweather.*", "Montserrat.*", "Nunito.*", "Olympia.*", "Poppins.*", "Rockwell.*", "Tw Cen.*", "Wingdings.*", "ZWAdobe.*"); /* These don't work so well. Use a ".*" to remove families */
		faveFontListCheck = newArray(faveFontList.length);
		for (i=0,counter=0; i<faveFontList.length; i++) {
			for (j=0; j<fontNameChoices.length; j++) {
				if (faveFontList[i] == fontNameChoices[j]) {
					faveFontListCheck[counter] = faveFontList[i];
					j = fontNameChoices.length;
					counter++;
				}
			}
		}
		faveFontListCheck = Array.trim(faveFontListCheck, counter);
		for (i=0; i<fontNameChoices.length; i++) {
			for (j=0; j<offFontList.length; j++){
				if (fontNameChoices[i]==offFontList[j]) fontNameChoices = Array.deleteIndex(fontNameChoices, i);
				if (endsWith(offFontList[j],".*")){
					if (startsWith(fontNameChoices[i], substring(offFontList[j], 0, indexOf(offFontList[j],".*")))){
						fontNameChoices = Array.deleteIndex(fontNameChoices, i);
						i = maxOf(0, i-1); 
					} 
					// fontNameChoices = Array.filter(fontNameChoices, "(^" + offFontList[j] + ")"); /* RegEx not working and very slow */
				} 
			} 
		}
		fontNameChoices = Array.concat(faveFontListCheck, fontNameChoices);
		for (i=0; i<fontNameChoices.length; i++) {
			for (j=i+1; j<fontNameChoices.length; j++)
				if (fontNameChoices[i]==fontNameChoices[j]) fontNameChoices = Array.deleteIndex(fontNameChoices, j);
		}
		return fontNameChoices;
	}
	function getScaleFactor(inputUnit){
		/* v220126 added micrometer symbol
			v220809 further tweaked handling of microns
			v230918 Removed restoreExit, scaleFactor returned even if -1.
			*/
		functionL = "getScaleFactor_v230918";
		micronS = getInfo("micrometer.abbreviation");
		micronSs = newArray("µm","um",fromCharCode(181)+"m","microns");
		scaleFactor = -1;
		for (i=0;i<micronSs.length;i++) if (inputUnit==micronSs[i]) inputUnit = micronS;
		kUnits = newArray("km","m","mm",micronS,"nm","pm");
		sFTemp = 1E3;
		for (i=0;i<kUnits.length;i++) {
			if (inputUnit==kUnits[i]){
				scaleFactor = sFTemp;
				i = kUnits.length;
			} else sFTemp /= 1E3;
		}
		if (scaleFactor<0){
			oddUnits = newArray("cm", "A", fromCharCode(197), "inches", "human hair", "pixels");
			oddUnits = newArray(1E-2, 1E-10, 1E-10, 2.54E-2, 1E-4, 0);
			for (i=0;i<oddUnits.length;i++) {
				if (inputUnit==oddUnits[i]){
					scaleFactor = oddUnits[i];
					i = oddUnits.length;
				}
			}
		}
		if (scaleFactor<0) IJ.log(inputUnit + " not a recognized unit \(function: " + functionL + "\)");
		return scaleFactor;
	}
	function getSelectionFromMask(sel_M){
		/* v220920 inverts selection if full width */
		batchMode = is("Batch Mode"); /* Store batch status mode before toggling */
		if (!batchMode) setBatchMode(true); /* Toggle batch mode on if previously off */
		tempID = getImageID();
		selectWindow(sel_M);
		run("Create Selection"); /* Selection inverted perhaps because the mask has an inverted LUT? */
		getSelectionBounds(gSelX,gSelY,gWidth,gHeight);
		if(gSelX==0 && gSelY==0 && gWidth==Image.width && gHeight==Image.height)	run("Make Inverse");
		run("Select None");
		selectImage(tempID);
		run("Restore Selection");
		if (!batchMode) setBatchMode(false); /* Return to original batch mode setting */
	}
	function guessBGMedianIntensity(){
		/* v220822: 1st color array version (based on https://wsr.imagej.net//macros/tools/ColorPickerTool.txt)
			v230728: Uses selected area if there is a non-line selection.
		*/
		if (selectionType<0 || selectionType>4){
			sW = Image.width-1;
			sH = Image.height-1;
			sX = 0;
			sY = 0;
		}
		else {
			getSelectionBounds(sX, sY, sW, sH);
			sW += sX;
			sH += sY;
		}
		interrogate = round(maxOf(1,(sW+sH)/200));
		if (bitDepth==24){red = 0; green = 0; blue = 0;}
		else int = 0;
		xC = newArray(sX,sW,sX,sW);
		yC = newArray(sY,sY,sH,sH);
		xAdd = newArray(1,-1,1,-1);
		yAdd = newArray(1,1,-1,-1);
		if (bitDepth==24){ reds = newArray(); greens = newArray(); blues = newArray();}
		else ints = newArray;
		for (i=0; i<xC.length; i++){
			for(j=0;j<interrogate;j++){
				if (bitDepth==24){
					v = getPixel(xC[i]+j*xAdd[i],yC[i]+j*yAdd[i]);
					reds = Array.concat(reds,(v>>16)&0xff);  // extract red byte (bits 23-17)
	           		greens = Array.concat(greens,(v>>8)&0xff); // extract green byte (bits 15-8)
	            	blues = Array.concat(blues,v&0xff);       // extract blue byte (bits 7-0)
				}
				else ints = Array.concat(ints,getValue(xC[i]+j*xAdd[i],yC[i]+j*yAdd[i]));
			}
		}
		midV = round((xC.length-1)/2);
		if (bitDepth==24){
			reds = Array.sort(reds); greens = Array.sort(greens); blues = Array.sort(blues);
			medianVals = newArray(reds[midV],greens[midV],blues[midV]);
		}
		else{
			ints = Array.sort(ints);
			medianVals = newArray(ints[midV],ints[midV],ints[midV]);
		}
		return medianVals;
	}
	function indexOfArray(array, value, default) {
		/* v190423 Adds "default" parameter (use -1 for backwards compatibility). Returns only first found value
			v230902 Limits default value to array size */
		index = minOf(lengthOf(array) - 1, default);
		for (i=0; i<lengthOf(array); i++){
			if (array[i]==value) {
				index = i;
				i = lengthOf(array);
			}
		}
	  return index;
	}
	function indexOfArrayThatContains(array, value, default) {
		/* Like indexOfArray but partial matches possible
			v190423 Only first match returned, v220801 adds default.
			v230902 Limits default value to array size */
		indexFound = minOf(lengthOf(array) - 1, default);
		for (i=0; i<lengthOf(array); i++){
			if (indexOf(array[i], value)>=0){
				indexFound = i;
				i = lengthOf(array);
			}
		}
		return indexFound;
	}
	function removeOverlaysByName(overlayNameSubstring) {
		/* Some overlays seem hard to remove . . . this tries really hard!
			Using "" as substring will remove all overlays
			v210817 1st version as function
			v210826 self-contained */
		getDimensions(null, null, channels, slices, frames);
		if(Overlay.size>0) {
			initialOverlaySize = Overlay.size;
			for (i=0; i<slices; i++){
				setSlice(i+1);
				ovl = 0;
				for (j=0; j<initialOverlaySize; j++){
					if (j<Overlay.size+1){
						Overlay.activateSelection(ovl);
						overlaySelectionName = getInfo("selection.name");
						if (indexOf(overlaySelectionName,overlayNameSubstring)>=0) {
							Overlay.removeSelection(ovl);
							run("Select None");
							if (ovl<Overlay.size){
								Overlay.activateSelection(ovl);
								overlaySelectionName = getInfo("selection.name");
								if (indexOf(overlaySelectionName,overlayNameSubstring)>=0) Overlay.removeSelection(ovl);
								/* don't know why I need this 2nd deletion attempt after index reset  - it just works for my images */
								run("Select None");
							}
						}
						else ovl++; /* only advance ovl count if slice is not removed, removing slice resets index values */
					}
				}
			}
			if (slices==1 && channels>1) {  /* not actually tested on Channels yet !! */
				for (i=0; i<channels; i++){
					setChannel(i+1);
					ovl = 0;
					for (j=0; j<initialOverlaySize; j++){
						if (j<Overlay.size){
							Overlay.activateSelection(ovl);
							overlaySelectionName = getInfo("selection.name");
							if (indexOf(overlaySelectionName,overlayNameSubstring)>=0) {
								Overlay.removeSelection(ovl);
								if (ovl<Overlay.size){
									Overlay.activateSelection(ovl);
									overlaySelectionName = getInfo("selection.name");
									if (indexOf(overlaySelectionName,overlayNameSubstring)>=0) Overlay.removeSelection(ovl);
									/* don't know why I need this 2nd deletion attempt after index reset  - it just works for my images */
								}
							}
							else ovl++; /* only advance ovl count if slice is not removed, removing slice resets index values */
						}
					}
				}
			}
		}
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
	function safeColornameFill(colorName) {
	/* Requires function getColorArrayFromColorName
		v230406: 1st version Peter J. Lee.  v230920 Switched to setColor.
		*/
		orFGC = getValue("color.foreground");
		colorArray = getColorArrayFromColorName(colorName);
		setColor(colorArray[0], colorArray[1], colorArray[2]);
		fill();
		setForegroundColor(orFGC);
	}
	function safeSaveAndClose(filetype,path,fileSaveName,closeImageIfSaved){
		/* v230411: 1st version reworked
			v230812: Uses full dialog which should save time for non-saves, includes options to change the directory and filetype.
			v230814: Close by imageID not filename. Added option to override closeImageIfSaved.
			v230915: Saves if there is no change in path rather than getting stuck in loop.
			v230920: Allows empty path string.
		*/
		functionL = "safeSaveAndClose_v230920";
		imageID = getImageID();
		fS = File.separator;
		filetypes = newArray("tiff","png","jpeg");
		extension = "tif"; /* default */
		extensions = newArray("tif","png","jpg");
		for (i=0; i<3; i++) if (filetype==filetypes[i]) extension = extensions[i];
		if (!endsWith(fileSaveName,extension)){
			if (lastIndexOf(fileSaveName,".")>fileSaveName.length-5) fileSaveName = substring(fileSaveName,0,lastIndexOf(fileSaveName,".")+1) + extension;
			else fileSaveName += "." + extension;
		}
		if (path!=""){
			if(endsWith(path,fS)) path = substring(path,0,path.length-1);
			fullPath = path + fS + fileSaveName;
		}
		else fullPath = "";
		newSave = false;
		if (!File.exists(fullPath) && fullPath!=""){
			saveAs(filetype, fullPath);
			if (File.exists(fullPath)) newSave = true;
		}
		if (!newSave) {
			Dialog.create("Options: " + functionL);
				if (path!=""){
					Dialog.addMessage("File: " + fileSaveName + " already exists in\n" + path);
					Dialog.addMessage("If no changes are made below, the existing file will be overwritten");
				}
				Dialog.addString("Change the filename?", fileSaveName, fileSaveName.length+5);
				if (path=="") path = File.directory;
				Dialog.addDirectory("Change the directory?", path);
				Dialog.addRadioButtonGroup("Change the filetype?", newArray("tiff","png","jpeg"),1,3,filetype);
				Dialog.addCheckbox("Don't save file",false);
				Dialog.addCheckbox("Close image \(imageID: " + imageID + ") after successful save", closeImageIfSaved);
			Dialog.show;
				newFileSaveName = Dialog.getString();
				newPath = Dialog.getString();
				newFiletype = Dialog.getRadioButton();
				dontSaveFile = Dialog.getCheckbox();
				closeImageIfSaved = Dialog.getCheckbox();
			if (!dontSaveFile){
				if (!File.isDirectory(newPath)) File.makeDirectory(newPath);
				if (!endsWith(newPath,fS)) newPath += fS;
				for (i=0; i<3; i++) if (newFiletype==filetypes[i]) newExtension = extensions[i];
				if (extension!=newExtension) newfileSaveName = replace(newFileSaveName,extension,newExtension);
				newFullPath = newPath + newFileSaveName;
				if (!File.exists(newFullPath) || newFullPath==fullPath) saveAs(newFiletype, newFullPath);
				else safeSaveAndClose(newFiletype,newPath,newFileSaveName,closeImageIfSaved);
				if (File.exists(newFullPath)) newSave = true;
			}
		}
		if (newSave && closeImageIfSaved && nImages>0){
			if (getImageID()==imageID) close();
			else IJ.log(functionL + ": Image ID change so fused image not closed");
		}
	}
	function sensibleScales(pixelW, inUnit, targetLength){
		/* v230808: 1st version */
		kUnits = newArray("m", "mm", getInfo("micrometer.abbreviation"), "nm", "pm");
		if (inUnit=="inches"){
			inUnit = "mm";
			pixelW *= 25.4;
			IJ.log("Inches converted to mm units");
		}
		if(startsWith(inUnit,"micro") || endsWith(inUnit,"ons") || inUnit=="um" || inUnit=="µm") inUnit = kUnits[2];
		iInUnit = indexOfArray(kUnits,inUnit,-1);
		if (iInUnit<0) restoreExit("Scale unit \(" + inUnit + "\) not in unitChoices");
		while (pixelW * targetLength > 500) {
			pixelW /= 1000;
			iInUnit -= 1;
			inUnit = kUnits[iInUnit];
		}
		while (pixelW * targetLength <0.1){
			pixelW *= 1000;
			iInUnit += 1;
			inUnit = kUnits[iInUnit];				
		}
		outArray = Array.concat(pixelW,inUnit);
		return outArray;
	}
	function setScaleFromCZSemHeader() {
		/*	This very simple function sets the scale for SEM images taken with the Carl Zeiss SmartSEM program. It requires the tiff_tags plugin written by Joachim Wesner. It can be downloaded from http://rsbweb.nih.gov/ij/plugins/tiff-tags.html
		 There is an example image available at http://rsbweb.nih.gov/ij/images/SmartSEMSample.tif
		 This is the number of the VERY long tag that stores all the SEM information See original Nabble post by Pablo Manuel Jais: http://imagej.1557.x6.nabble.com/Importing-SEM-images-with-scale-td3689900.html imageJ version: https://rsb.info.nih.gov/ij/macros/SetScaleFromTiffTag.txt
		 v161103 with minor tweaks by Peter J. Lee National High Magnetic Field Laboratory
		 v161108 adds Boolean unit option, v171024 fixes Boolean option.
		 v180820 fixed incorrect message in dialog box.
		 v220812 REQUIRES sensibleUnits function
		 v230918 Version for fancyScaleBar REQUIREs sensibleScales instead of sensibleUnits 	*/
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
			scaleCSV = substring(tag,i1+2,i2-2);
			/*
			Splits the pixel size in number+unit and sets the scale of the active image */
			CZScale=split(scaleCSV);
			distPerPixel = parseFloat(CZScale[0]);
			CZScale = sensibleScales(distPerPixel, CZScale[1], 100);
			distPerPixel = parseFloat(CZScale[0]);
			CZUnit = CZScale[1];				
			setVoxelSize(distPerPixel, distPerPixel, 1, CZUnit);
		}
		else if (getBoolean("No CZSem tag found; do you want to continue?")) run("Set Scale...");
	}
	function stripKnownExtensionFromString(string) {
		/*	Note: Do not use on path as it may change the directory names
		v210924: Tries to make sure string stays as string.	v211014: Adds some additional cleanup.	v211025: fixes multiple 'known's issue.	v211101: Added ".Ext_" removal.
		v211104: Restricts cleanup to end of string to reduce risk of corrupting path.	v211112: Tries to fix trapped extension before channel listing. Adds xlsx extension.
		v220615: Tries to fix the fix for the trapped extensions ...	v230504: Protects directory path if included in string. Only removes doubled spaces and lines.
		v230505: Unwanted dupes replaced by unusefulCombos.	v230607: Quick fix for infinite loop on one of while statements.
		v230614: Added AVI.	v230905: Better fix for infinite loop. v230914: Added BMP and "_transp" and rearranged
		*/
		fS = File.separator;
		string = "" + string;
		protectedPathEnd = lastIndexOf(string,fS)+1;
		if (protectedPathEnd>0){
			protectedPath = substring(string,0,protectedPathEnd);
			string = substring(string,protectedPathEnd);
		}
		unusefulCombos = newArray("-", "_"," ");
		for (i=0; i<lengthOf(unusefulCombos); i++){
			for (j=0; j<lengthOf(unusefulCombos); j++){
				combo = unusefulCombos[i] + unusefulCombos[j];
				while (indexOf(string,combo)>=0) string = replace(string,combo,unusefulCombos[i]);
			}
		}
		if (lastIndexOf(string, ".")>0 || lastIndexOf(string, "_lzw")>0) {
			knownExts = newArray(".avi", ".csv", ".bmp", ".dsx", ".gif", ".jpg", ".jpeg", ".jp2", ".png", ".tif", ".txt", ".xlsx");
			knownExts = Array.concat(knownExts,knownExts,"_transp","_lzw");
			kEL = knownExts.length;
			for (i=0; i<kEL/2; i++) knownExts[i] = toUpperCase(knownExts[i]);
			chanLabels = newArray(" \(red\)"," \(green\)"," \(blue\)","\(red\)","\(green\)","\(blue\)");
			for (i=0,k=0; i<kEL; i++) {
				for (j=0; j<chanLabels.length; j++){ /* Looking for channel-label-trapped extensions */
					iChanLabels = lastIndexOf(string, chanLabels[j])-1;
					if (iChanLabels>0){
						preChan = substring(string,0,iChanLabels);
						postChan = substring(string,iChanLabels);
						while (indexOf(preChan,knownExts[i])>0){
							preChan = replace(preChan,knownExts[i],"");
							string =  preChan + postChan;
						}
					}
				}
				while (endsWith(string,knownExts[i])) string = "" + substring(string, 0, lastIndexOf(string, knownExts[i]));
			}
		}
		unwantedSuffixes = newArray(" ", "_","-");
		for (i=0; i<unwantedSuffixes.length; i++){
			while (endsWith(string,unwantedSuffixes[i])) string = substring(string,0,string.length-lengthOf(unwantedSuffixes[i])); /* cleanup previous suffix */
		}
		if (protectedPathEnd>0){
			if(!endsWith(protectedPath,fS)) protectedPath += fS;
			string = protectedPath + string;
		}
		return string;
	}
	function unCleanLabel(string) {
	/* v161104 This function replaces special characters with standard characters for file system compatible filenames.
	+ 041117b to remove spaces as well.
	+ v220126 added getInfo("micrometer.abbreviation").
	+ v220128 add loops that allow removal of multiple duplication.
	+ v220131 fixed so that suffix cleanup works even if extensions are included.
	+ v220616 Minor index range fix that does not seem to have an impact if macro is working as planned. v220715 added 8-bit to unwanted dupes. v220812 minor changes to micron and Ångström handling
	*/
		/* Remove bad characters */
		string= replace(string, fromCharCode(178), "\\^2"); /* superscript 2 */
		string= replace(string, fromCharCode(179), "\\^3"); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, fromCharCode(0xFE63) + fromCharCode(185), "\\^-1"); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
		string= replace(string, fromCharCode(0xFE63) + fromCharCode(178), "\\^-2"); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
		string= replace(string, fromCharCode(181)+"m", "um"); /* micron units */
		string= replace(string, getInfo("micrometer.abbreviation"), "um"); /* micron units */
		string= replace(string, fromCharCode(197), "Angstrom"); /* Ångström unit symbol */
		string= replace(string, fromCharCode(0x212B), "Angstrom"); /* the other Ångström unit symbol */
		string= replace(string, fromCharCode(0x2009) + fromCharCode(0x00B0), "deg"); /* replace thin spaces degrees combination */
		string= replace(string, fromCharCode(0x2009), "_"); /* Replace thin spaces  */
		string= replace(string, "%", "pc"); /* % causes issues with html listing */
		string= replace(string, " ", "_"); /* Replace spaces - these can be a problem with image combination */
		/* Remove duplicate strings */
		unwantedDupes = newArray("8bit","8-bit","lzw");
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
		if (sL-extStart<=4 && extStart>0) extIncl = true;
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
	function writeLabel7(font, size, color, text, x, y, aA){
	/* Requires the functions setColorFromColorName, getColorArrayFromColorName(colorName) etc.
	v190619: All variables as options.
	v230918: With ImageJ 1.54e and newer, text antialiasing is enabled by default and you have to use the keyword 'no-smoothing'
	*/
		if (aA) setFont(font, size);
		else setFont(font, size, "no-smoothing");
		setColorFromColorName(color);
		drawString(text, x, y);
	}