macro "Add Multiple Lines of Fancy Text To Image" {
	/* This macro adds multiple lines of text to a copy of the image.
		Peter J. Lee Applied Superconductivity Center at National High Magnetic Field Laboratory.
		ANSI encoded for Windows.
		Version v170411 removes spaces in New image names to fix issue with new combination images.
		v180306 cosmetic changes to text.
		v180308 added non-destructive overlay option (overlay can be saved in TIFF header).
		v180611 Fixed stack labeling and fixed overlay.
		v180618	Added restore selection option (useful for multiple slices) and fixed label vertical location for selected options.
		v180626-8 Added text justification, added fit-to-selection, fixed override of previously selected area and added and more symbols
		v180629 Added ability to import metadata from list. v180702 Added progress bar for multiple slices.
		v180803 Can have line rotated to match angle of select-line or any arbitrary angle.
		v180809 Fixed bugs introduced in v180803. Added text above line option. Added "flatten" option to embed line selection.
		v181207 "Replace overlay" now replaces All overlays (so be careful).
		v181214 Overlay fonts on BW images can now be in color. Overlay shadow now works as expected.
		v190108 Overlay shadow now set to be always darker than background (except for "glow").
		v190222 Now works for 16 and 32 bit images.
		v200706 Changed variables to match Fancy Scale Bar macro version v200706.
		v210625 Added saving of user last-used settings (preferences). Fixed overlay alignment issues by using bitmap mask instead of rewriting text.
		v210628 Improved shadow and fixed text rotation issues. Split dialog into two dialogs to allow to remove menu tweaks that might not work in scalable GUIs
		v211022 Updated color function choices  f1-4 updated functions f5-7 updated colors
		v220823 Gray indices refer to grayChoices only; f1-color update. F2: Updated indexOf functions. F3: getColorArrayFromColorName_v230908.  F8 : Replaced function: pad. F9: Updated getColorFromColorName function (012324). F10: updated function unCleanLabel.
		v240709 Updated colors.
		v250124 Added bottom and top center options to locations. Added simple formatting options. Replaced inner-shadow option with raised/embossed.
		v250127 Added semi-Fancy option and transparent overlay shadows. Restored missing "Center of Selection" option to text locations.
	 */
	macroL = "Fancy_Text_Labels_v250127.ijm";
	requires("1.47r");
	originalImage = getTitle();
	if (matches(originalImage, ".*Ramp.*")==1) showMessageWithCancel("Title contains \"Ramp\"", "Do you want to label" + originalImage + " ?");
	saveSettings;
	/*	Set options for black objects on white background as this works better for publications */
	run("Options...", "iterations=1 white count=1"); /* Set the background to white */
	run("Colors...", "foreground=black background=white selection=yellow"); /* Set the preferred colors for these macros */
	setOption("BlackBackground", false);
	run("Appearance...", " "); /* do not use Inverting LUT *
	/* Check to see if a Ramp legend rather than the image has been selected by accident */
	getPixelSize(unit, pixelWidth, pixelHeight, pixelDepth);
	getDimensions(imageWidth, imageHeight, channels, slices, frames);
	selEType = selectionType;
	scaledLineAngle = 0;
	if (selEType>=0) {
		selectionExists = true;
		if ((selEType>=5) && (selEType<=7)) {
			line = true;
			if (selEType>5) {
				/*  for 6=segmented line or 7=freehand line do a linear fit */
				getSelectionCoordinates(xPoints, yPoints);
				Array.getStatistics(xPoints, orSelEX1, orSelEX2, orSelEX, null);
				Fit.doFit("Straight Line", xPoints, yPoints);
				orSelEY1 = Fit.f(orSelEX1);
				orSelEY2 = Fit.f(orSelEX2);
			}
			else getLine(orSelEX1, orSelEY1, orSelEX2, orSelEY2, selLineWidth);
			x1=orSelEX1*pixelWidth; y1=orSelEY1*pixelHeight; x2=orSelEX2*pixelWidth; y2=orSelEY2*pixelHeight;
			lineXPx =(orSelEX1-orSelEX2); /* used for label offsets later */
			lineYPx = (orSelEY1-orSelEY2); /* used for label offsets later */
			scaledLineAngle = (180/PI) * Math.atan2(lineYPx, lineXPx);
			if (scaledLineAngle<-90) scaledLineAngle += 180;
			else if (scaledLineAngle>90) scaledLineAngle -= 180;
			scaledLineLength = sqrt(pow(x2-x1,2)+pow(y2-y1,2));
			orSelEX = minOf(orSelEX1, orSelEX2);
			orSelEY = minOf(orSelEY1, orSelEY2);
			orSelEWidth = abs(orSelEX2-orSelEX1);
			orSelEHeight = abs(orSelEY2-orSelEY1);
			selLineLength = sqrt(pow(orSelEWidth,2)+pow(orSelEHeight,2));
		}
		else {
			line = false;
			getSelectionBounds(orSelEX, orSelEY, orSelEWidth, orSelEHeight);
		}
	}
	else {
		selectionExists = false;
		line = false;
	}
	setBatchMode(true);
	startSliceNumber = getSliceNumber();
	remSlices = slices-startSliceNumber;
	imageDims = imageHeight + imageWidth;
	imageDepth = bitDepth();
	id = getImageID();
	fontSize = round(imageDims/75); /* default font size */
	if (fontSize < 10) fontSize = 10; /* set minimum default font size as 10 */
	lineSpacing = 1.1;
	outlineStroke = 7; /* default outline stroke: % of font size */
	shadowDrop = 10;  /* default outer shadow drop: % of font size */
	shadowDisp = shadowDrop;
	shadowBlur = floor(0.6 * shadowDrop);
	shadowDarkness = 50;
	offsetX = round(8 + imageWidth/150); /* default offset of label from edge */
	offsetY = round(8 + imageHeight/150); /* default offset of label from edge */
	textRot = 0;
	textAboveLine = false;
	/* Then Basic Options Dialog . . . */
	Dialog.create("Basic Label Options: " + macroL);
		if (Overlay.size==0) overwriteChoice = newArray("Overwrite", "New image", "Add overlays");
		else overwriteChoice = newArray("Overwrite", "New image", "Add overlays", "Replace All overlays");
		iOver = indexOfArray(overwriteChoice, call("ij.Prefs.get", "fancy.textLabels.output",overwriteChoice[1]),1);
		Dialog.addRadioButtonGroup("Output choices \(Overwrite & New: Destructive  Overlays: Non-destructive\):", overwriteChoice, 1, 3, overwriteChoice[iOver]);
		if (selectionExists) {
			textLocChoices = newArray("Top Left", "Top Right", "Top Center", "Center", "Bottom Left", "Bottom Center", "Bottom Right", "Center of Selection", "Center of New Selection");
			iLoc = indexOfArray(textLocChoices, "Center of Selection", 0);	/* Overrides preferences as an active selection is assumed to be a priority */
		} else {
			textLocChoices = newArray("Top Left", "Top Right", "Top Center", "Center", "Bottom Left", "Bottom Center", "Bottom Right", "Center of New Selection");
			iLoc = indexOfArray(textLocChoices, call("ij.Prefs.get", "fancy.textLabels.location", textLocChoices[0]),0);
		}
		Dialog.addChoice("Location of New Text:", textLocChoices, textLocChoices[iLoc]);
		Dialog.addNumber("Edge margin left/right:", offsetX, 0, 6, "pixels");
		Dialog.addNumber("Edge margin top/bottom:", offsetY, 0, 6, "pixels");
		if (selectionExists) {
			Dialog.addNumber("Original selection X start = ", orSelEX);
			Dialog.addNumber("Original selection Y start = ", orSelEY);
			Dialog.addNumber("Original selection width = ", orSelEWidth);
			Dialog.addNumber("Original selection height = ", orSelEHeight);
			if (selEType==0 || selEType==1 || selEType==5 || selEType==6 || selEType==7) {
				Dialog.addCheckbox("Restore this selection at macro completion?", true);
			} else restoreSelection = false;
			if (orSelEX<imageWidth*0.4) just = "left";
			else if (orSelEX>imageWidth*0.6) just = "right";
			else just = "center";
			if ((selEType>=5) && (selEType<=7)) {
				Dialog.addNumber("Text Rotation Angle = ", scaledLineAngle);
				Dialog.addMessage("Note: Rotated text may not be pretty.");
				Dialog.addCheckbox("1st line of text above line", true);
			}
		}
		else restoreSelection = false;
		textJustChoices = newArray("auto", "left", "center", "right");
		if (selectionExists)
			Dialog.addChoice("Text justification \(\"auto\" will be \""+just+"\"\)", textJustChoices, textJustChoices[0]);
		else Dialog.addChoice("Text justification", textJustChoices, textJustChoices[0]);
		Dialog.addNumber("Default font size:", fontSize);
		fontStyleChoice = newArray("bold", "bold antialiased", "italic", "italic antialiased", "bold italic", "bold italic antialiased", "unstyled");
		iFS = indexOfArray(fontStyleChoice, call("ij.Prefs.get", "fancy.textLabels.font.style",fontStyleChoice[1]),1);
		Dialog.addChoice("Font style:", fontStyleChoice, fontStyleChoice[iFS]);
		fontNameChoice = getFontChoiceList();
		iFN = indexOfArray(fontNameChoice, call("ij.Prefs.get", "fancy.textLabels.font",fontNameChoice[0]),0);
		Dialog.addChoice("Font name:", fontNameChoice, fontNameChoice[iFN]);
		fancyStyleEffectsOptions = newArray("No shadows", "No outline", "Raised", "Recessed");
		fancyStyleEffectsDefaults = newArray(false, false, false, false);
		fancyStyleEffectsPrefs = call("ij.Prefs.get", "fancy.textLabels.fancyStyleEffects", "not found");
		if (fancyStyleEffectsPrefs != "not found") {
			fancyStyleEffects = split(fancyStyleEffectsPrefs, "|");
			if (fancyStyleEffects.length == fancyStyleEffectsOptions.length) fancyStyleEffectsDefaults = fancyStyleEffects;
		}
		Dialog.setInsets(10, 20, 0);
		Dialog.addCheckboxGroup(1, fancyStyleEffectsOptions.length, fancyStyleEffectsOptions, fancyStyleEffectsDefaults);
		fancyLevels = newArray("Not Fancy", "Semi-Fancy", "Full-Fancy");
		howFancy = call("ij.Prefs.get", "fancy.textLabels.howFancy", fancyLevels[2]);
		Dialog.addRadioButtonGroup("How fancy?", fancyLevels, 1, 2, howFancy);
		grayChoices = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray");
		colorChoicesStd = newArray("red", "green", "blue", "cyan", "magenta", "yellow", "pink", "orange", "violet");
		colorChoicesMod = newArray("aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "blue_honolulu", "gray_modern", "green_dark_modern", "green_modern", "green_modern_accent", "green_spring_accent", "orange_modern", "pink_modern", "purple_modern", "red_n_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern");
		colorChoicesNeon = newArray("jazzberry_jam", "radical_red", "wild_watermelon", "outrageous_orange", "supernova_orange", "atomic_tangerine", "neon_carrot", "sunglow", "laser_lemon", "electric_lime", "screamin'_green", "magic_mint", "blizzard_blue", "dodger_blue", "shocking_pink", "razzle_dazzle_rose", "hot_magenta");
		colorChoicesFSU = newArray("garnet", "gold", "stadium_night", "westcott_water", "vault_garnet", "legacy_blue", "plaza_brick", "vault_gold");
		colorChoices = Array.concat(grayChoices, colorChoicesStd, colorChoicesMod, colorChoicesNeon, colorChoicesFSU);
		iTC = indexOfArray(colorChoices, call("ij.Prefs.get", "fancy.textLabels.font.color",colorChoices[0]),0);
		iBC = indexOfArray(colorChoices, call("ij.Prefs.get", "fancy.textLabels.outline.color",colorChoices[1]),1);
		iTCg = indexOfArray(grayChoices, call("ij.Prefs.get", "fancy.textLabels.font.gray",grayChoices[0]),0);
		iBCg = indexOfArray(grayChoices, call("ij.Prefs.get", "fancy.textLabels.outline.gray",grayChoices[1]),1);
		if (imageDepth==24){
			Dialog.addChoice("Text color:", colorChoices, colorChoices[iTC]);
			Dialog.addChoice("Outline \(background\) color:", colorChoices, colorChoices[iBC]);
		}	else {
			Dialog.addMessage("Gray options for destructive labels:________");
			Dialog.addChoice("Destructive text gray choices:", grayChoices, grayChoices[iTCg]);
			Dialog.addChoice("Destructive text outline gray choices:", grayChoices, grayChoices[iBCg]);
			Dialog.addMessage("Color options for overlay labels:________");
			Dialog.addChoice("Overlay text color choices:", colorChoices, colorChoices[iTC]);
			Dialog.addChoice("Overlay text outline color choices:", colorChoices, colorChoices[iBC]);
		}
		Dialog.addCheckbox("Tweak outline and shadow settings?", false);
	  Dialog.show();
		overWrite = Dialog.getRadioButton();
		textLocChoice = Dialog.getChoice();
		offsetX = Dialog.getNumber();
		offsetY = Dialog.getNumber();
		if (selectionExists) {
			selEX =  Dialog.getNumber(); /* Allows user to tweak pre-selection using dialog boxes */
			selEY =  Dialog.getNumber();
			selEWidth =  Dialog.getNumber();
			selEHeight =  Dialog.getNumber();
			restoreSelection = Dialog.getCheckbox();
			if ((selEType>=5) && (selEType<=7)) {
				textRot = Dialog.getNumber();
				textAboveLine = Dialog.getCheckbox;
			}
		}
		just = Dialog.getChoice();
		fontSize =  Dialog.getNumber();
		/* fancy style effects checkbox group order: "No shadows", "Raised", "Recessed" */
		fancyStyleEffectsString = "";
		noShadow = Dialog.getCheckbox();
		fancyStyleEffectsString += "|" + d2s(noShadow, 0);
		noOutline = Dialog.getCheckbox();
		fancyStyleEffectsString += "|" + d2s(noOutline, 0);
		raised = Dialog.getCheckbox();
		fancyStyleEffectsString += "|" + d2s(raised, 0);
		recessed = Dialog.getCheckbox();
		fancyStyleEffectsString += "|" + d2s(recessed, 0);
		howFancy = Dialog.getRadioButton();
		call("ij.Prefs.set", "fancy.textLabels.howFancy", howFancy);
		notFancy = false;
		if (!noShadow || !noOutline || raised || recessed) notFancy = false;
		if (howFancy == "Not Fancy") notFancy = true;
		else if (howFancy == "Semi-Fancy"){
			shadowDrop /= 2;  /* default outer shadow drop: % of font size */
			shadowDisp /= 2;
			shadowBlur /= 2;
			shadowDarkness = 25;
			outlineStroke = 3.5; /* default outline stroke: % of font size */
		}
		if (notFancy){
			noShadow = true;
			noOutline = true;
			raised = false;
			recessed = false;
			fancyStyleEffectsString = "|1|1|0|0";
		}
		call("ij.Prefs.set", "fancy.textLabels.fancyStyleEffects", fancyStyleEffectsString);
		/* End of checkbox group */
		fontStyle = Dialog.getChoice();
		fontName = Dialog.getChoice();
		if (imageDepth==24){
			fontColor = Dialog.getChoice;
			outlineColor = Dialog.getChoice;
		} else {
			desFontGray = Dialog.getChoice();
			desOutlineGray = Dialog.getChoice();
			ovFontColor = Dialog.getChoice();
			ovOutlineColor = Dialog.getChoice();
			if (endsWith(overWrite,"overlays")){
				fontColor = ovFontColor;
				outlineColor = ovOutlineColor;
			} else {
				fontColor = desFontGray;
				outlineColor = desOutlineGray;
			}
		}
		tweakFormat = Dialog.getCheckbox();
	if (tweakFormat=="Yes" && !notFancy) {
		Dialog.create("Advanced Formatting Options");
		Dialog.addNumber("Line Spacing", lineSpacing,1,3,"\(default 1\)");
		Dialog.addNumber("Outline stroke:", outlineStroke,0,3,"% of font size");
		Dialog.addNumber("Shadow Drop: ?", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Displacement Right: ?", shadowDisp,0,3,"% of font size");
		Dialog.addNumber("Shadow Gaussian blur:", shadowBlur,0,3,"% of font size");
		Dialog.addNumber("Shadow Darkness:", shadowDarkness,0,3,"%\(darkest = 100%\)");
		Dialog.show();
		lineSpacing = Dialog.getNumber();
		outlineStroke = Dialog.getNumber();
		shadowDrop = Dialog.getNumber();
		shadowDisp = Dialog.getNumber();
		shadowBlur = Dialog.getNumber();
		shadowDarkness = Dialog.getNumber();
	}
	Dialog.create("Label Options: " + macroL);
		Dialog.addMessage("\"^2\" & \"um\" etc. replaced by " + fromCharCode(178) + " & " + fromCharCode(181)
			+ "m etc. If the units are in the parameter label, within \(...\) i.e. \(unit\) they will override this selection.\n\"degreeC\" will be replaced with "
			+ fromCharCode(0x00B0) + "C, \"degree C\" will be replaced with " + fromCharCode(0x00B0) + " C, \"degrees\" by " + fromCharCode(0x00B0)
			+ ",\n\"symbol-Greek letter\" by the Greek letter, i.e. \"symbol-omega\" translates to " + fromCharCode(0x03C9) + ",\"symbol-Omega\" to " + fromCharCode(0x03A9) + "\nand \"symbol->=\" to " + fromCharCode(0x2265) + " etc. Arrows: \"arrow-up\" " + fromCharCode(0x21E7) + " \"arrow-left\" " + fromCharCode(0x21E6) + " etc.");
		textChoiceLines = 8;
		lengthOfDirectory = lengthOf(getInfo("image.directory"));
		if (lengthOfDirectory>57) {
			directorySubstring = substring(getInfo("image.directory"),lengthOfDirectory-57,lengthOfDirectory);
			directorySubstring = "..." + substring(directorySubstring, indexOf(directorySubstring, "\\"));
		}
		else directorySubstring = getInfo("image.directory");
		imageFilename = getInfo("image.filename");
		if(lastIndexOf(imageFilename,".")>0) imageFilenameWOExtension = substring(imageFilename,0,lastIndexOf(imageFilename,"."));
		else imageFilenameWOExtension = imageFilename;
		metaDataChoices1 = newArray("Enter text above or select here from this list", getTitle());
		metaDataChoices2 = newArray(getMetadata("Info"), directorySubstring, imageFilename, imageFilenameWOExtension, "pixel width = " +pixelWidth+" "+unit, "Image width = "+imageWidth +" pixels", getInfo("image.subtitle"));
		if (line) {
			lineData = newArray(""+scaledLineLength+" "+unit + ", "+scaledLineAngle+fromCharCode(0x00B0), ""+scaledLineAngle+fromCharCode(0x00B0), ""+scaledLineLength+" "+unit);
			metaDataChoices = Array.concat(metaDataChoices1,lineData,metaDataChoices2);
		}
		else metaDataChoices = Array.concat(metaDataChoices1, metaDataChoices2);
		for (i=0; i<textChoiceLines; i++) {
			tIPrefsName = "fancy.textLabels.texLabel." + i;
			textLabel = call("ij.Prefs.get", tIPrefsName,"-blank-");
			Dialog.addString("Label line "+(i+1)+":",textLabel, 35);
			Dialog.addChoice("",metaDataChoices,metaDataChoices[0]);
		}
	  Dialog.show();
			textInputLines = newArray(textChoiceLines);
		for (i=0; i<textChoiceLines; i++) {
			textInputLines[i] = Dialog.getString();
			tIPrefsName = "fancy.textLabels.texLabel." + i;
			call("ij.Prefs.set", tIPrefsName, textInputLines[i]);
			metaChoice = Dialog.getChoice();
			if (metaChoice!="Enter text above or select here from this list") textInputLines[i] = metaChoice;
			textInputLines[i] = "" + cleanLabel(textInputLines[i]); /* Use degree symbol */
		}
	if (startsWith(overWrite,"Replace")) while (Overlay.size!=0) Overlay.remove;
	if ((remSlices>0) && !endsWith(overWrite,"overlays")) labelRest = getBoolean("Add the same labels to this and next " + remSlices + " slices?");
	else labelRest = false;
	if (is("Batch Mode")==false) setBatchMode(true);	/* toggle batch mode back on */
/* save last used settings in user in preferences */
	call("ij.Prefs.set", "fancy.textLabels.font.style", fontStyle);
	call("ij.Prefs.set", "fancy.textLabels.font", fontName);
	call("ij.Prefs.set", "fancy.textLabels.location", textLocChoice);
	call("ij.Prefs.set", "fancy.textLabels.output", overWrite);
	if (imageDepth==24){
		call("ij.Prefs.set", "fancy.textlabel.font.color", fontColor);
		call("ij.Prefs.set", "fancy.textlabel.outline.color", outlineColor);
	}
	else {
		call("ij.Prefs.set", "fancy.textLabels.font.gray", fontColor);
		call("ij.Prefs.set", "fancy.textLabels.outline.gray", outlineColor);
		if (endsWith(overWrite,"overlays")){
			fontColor = ovFontColor;
			outlineColor = ovOutlineColor;
			call("ij.Prefs.set", "fancy.textLabels.font.color", fontColor);
			call("ij.Prefs.set", "fancy.textLabels.outline.color", outlineColor);
		}
	}
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
	if (textOutNumber==0) restoreExit("No text for labels");
	/* Make sure all text fits image width */
	shrinkX = imageWidth/longestStringWidth;
	fontSize = fontSize * minOf(1, shrinkX);
	longestStringWidth = longestStringWidth * minOf(1, shrinkX);
	/* determine font color intensities settings for antialiased tweak */
	fontColorArray = getColorArrayFromColorName(fontColor);
	Array.getStatistics(fontColorArray,fontIntMean);
	fontInt = floor(fontIntMean);
	fontFactor = fontSize/100;
	if (!noOutline){
		outlineColorArray = getColorArrayFromColorName(outlineColor);
		Array.getStatistics(outlineColorArray,outlineIntMean);
		outlineInt = floor(outlineIntMean);
		outlineStroke = round(fontFactor * outlineStroke);
	}
	if (!noShadow){
		negAdj = 0.5;  /* negative offsets appear exaggerated at full displacement */
		if (shadowDrop<0) shadowDrop *= negAdj;
		if (shadowDisp<0) shadowDisp *= negAdj;
		if (shadowBlur<0) shadowBlur *= negAdj;
		shadowDrop = round(fontFactor * shadowDrop);
		shadowDisp = round(fontFactor * shadowDisp);
		shadowBlur = round(fontFactor * shadowBlur);
		if (offsetX<(shadowDisp+shadowBlur+1)) offsetX = (shadowDisp+shadowBlur+1);  /* make sure shadow does not run off edge of image */
		if (offsetY<(shadowDrop+shadowBlur+1)) offsetY = (shadowDrop+shadowBlur+1);
	}
	if (fontStyle=="unstyled") fontStyle="";
/*  */
	linesSpace = lineSpacing * textOutNumber * fontSize;
	if (textLocChoice == "Top Left") {
		selEX = offsetX;
		selEY = offsetY;
		if (just=="auto") just = "left";
	} else if (textLocChoice == "Top Right") {
		selEX = imageWidth - longestStringWidth - offsetX;
		selEY = offsetY;
		if (just=="auto") just = "right";
	}else if (textLocChoice == "Top Center") {
		selEX = round((imageWidth - longestStringWidth)/2);
		selEY = offsetY;
		if (just=="auto") just = "center";
	} else if (textLocChoice == "Center") {
		selEX = round((imageWidth - longestStringWidth)/2);
		selEY = round((imageHeight - linesSpace)/2 + fontSize);
		if (just=="auto") just = "center";
	} else if (textLocChoice == "Bottom Left") {
		selEX = offsetX;
		selEY = imageHeight - (offsetY + linesSpace) + fontSize;
		if (just=="auto") just = "left";
	} else if (textLocChoice == "Bottom Right") {
		selEX = imageWidth - longestStringWidth - offsetX;
		selEY = imageHeight - (offsetY + linesSpace) + fontSize;
		if (just=="auto") just = "right";
	} else if (textLocChoice == "Bottom Center") {
		selEX = round((imageWidth - longestStringWidth)/2);
		selEY = imageHeight - (offsetY + linesSpace) + fontSize;
		if (just=="auto") just = "center";
	} else if (textLocChoice == "Center of New Selection"){
		if (is("Batch Mode")) setBatchMode(false); /* Does not accept interaction while batch mode is on */
		setTool("rectangle");
		msgtitle="Location for the text labels...";
		msg = "Draw a box in the image where you want to center the text labels...";
		waitForUser(msgtitle, msg);
		getSelectionBounds(orSelEX, orSelEY, orSelEWidth, orSelEHeight); /* this set for restore */
		restoreSelection = getBoolean("Restore this selection at the end of the macro?");
		if (is("Batch Mode")==false) setBatchMode(true);	/* toggle batch mode back on */
		getSelectionBounds(selEX, selEY, selEWidth, selEHeight); /* this set to change */
	}
	if (endsWith(textLocChoice, "election")) {
		if (line) shrinkF = selLineLength/longestStringWidth;
		// if (line) shrinkY = minOf(1,imageHeight/linesSpace);
		else {
			shrinkX = minOf(1,selEWidth/longestStringWidth);
			shrinkY = minOf(1,selEHeight/linesSpace);
			shrinkF = minOf(shrinkX, shrinkY);
		}
		shrunkFont = shrinkF * fontSize;
		if (shrinkF < 1) {
			Dialog.create("Shrink Text");
			Dialog.addCheckbox("Text will not fit inside selection; Reduce font size from " + fontSize+ "?", true);
			Dialog.addNumber("Choose new font size; font size for fit =",round(shrunkFont));
			Dialog.show;
			reduceFontSize = Dialog.getCheckbox();
			shrunkFont = Dialog.getNumber();
			shrinkF = shrunkFont/fontSize;
		}
		else reduceFontSize = false;
		if (reduceFontSize) {
			fontSize = shrunkFont;
			linesSpace = shrinkF * linesSpace;
			longestStringWidth = shrinkF * longestStringWidth;
			fontFactor = fontSize/100;
			if (!noOutline){
				if (outlineStroke>1) outlineStroke = maxOf(1,round(fontFactor * outlineStroke));
				else outlineStroke = round(fontFactor * outlineStroke);
			}
			if (!noShadow){
				if (shadowDrop>1) shadowDrop = maxOf(1,round(fontFactor * shadowDrop));
				else shadowDrop = round(fontFactor * shadowDrop);
				if (shadowDisp>1) shadowDisp = maxOf(1,round(fontFactor * shadowDisp));
				else shadowDisp = round(fontFactor * shadowDisp);
				if (shadowBlur>1) shadowBlur = maxOf(1,round(fontFactor * shadowBlur));
				else shadowBlur = round(fontFactor * shadowBlur);
			}
		}
		selEX = selEX + round((selEWidth/2) - longestStringWidth/2);
		selEY = selEY + round((selEHeight/2) - (linesSpace/2) + fontSize);
		if (just=="auto") {
			if (selEX<imageWidth*0.4) just = "left";
			else if (selEX>imageWidth*0.6) just = "right";
			else just = "center";
		}
	}
	run("Select None");
	if (selEY<=1.5*fontSize)
		selEY += fontSize;
	if (selEX<offsetX) selEX = offsetX;
	endX = selEX + longestStringWidth;
	if ((endX+offsetX)>imageWidth) selEX = imageWidth - longestStringWidth - offsetX;
	textLabelX = selEX;
	textLabelY = selEY;
	/* Now offset from line for line label */
	if ((selEType>=5) && (selEType<7) && textAboveLine) {
		textLabelX += round(cos(textRot/(180/PI))*0.75*fontSize);
		textLabelX += round(sin(textRot/(180/PI))*0.75*fontSize);
	}
	setColorFromColorName("white");
	roiManager("show none");
	if (startsWith(overWrite,"New")) {
		if (slices==1) run("Duplicate...", "title=" + getTitle() + "+text");
		else run("Duplicate...", "title=" + getTitle() + "+text duplicate");
	}
	workingImage = getTitle();
	if (is("Batch Mode")==false) setBatchMode(true);	/* toggle batch mode back on */
	setFont(fontName, fontSize, fontStyle);
	textLabelLineY = textLabelY;
	/* Create Label Mask */
	if (!notFancy){
		newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
		roiManager("deselect");
		run("Select None");
		setColor("white");
		for (i=0; i<textOutNumber; i++) {
			if (textInputLines[i]!="-blank-") {
				if (just=="left") drawString(textInputLinesText[i], textLabelX, textLabelLineY);
				else if (just=="right") drawString(textInputLinesText[i], textLabelX + (longestStringWidth - getStringWidth(textInputLinesText[i])), textLabelLineY);
				else drawString(textInputLinesText[i], textLabelX + (longestStringWidth-getStringWidth(textInputLinesText[i]))/2, textLabelLineY);
				textLabelLineY += lineSpacing * fontSize;
			}
			else textLabelLineY += lineSpacing * fontSize;
		}
		textLabelLineY = textLabelY;
		selectWindow("label_mask");
		setThreshold(0, 128);
		setOption("BlackBackground", false);
		run("Convert to Mask"); /* AKA Make Binary" */
		if (endsWith(overWrite,"verlays")) {
			selectWindow(originalImage);
			fontColorHex = getHexColorFromColorName(fontColor);
			outlineColorHex = getHexColorFromColorName(outlineColor);
			run("Select None");
			getSelectionFromMask("label_mask");
			if (textRot!=0) run("Rotate...", "  angle=&textRot");
			getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
			setSelectionLocation(selMaskX+shadowDisp, selMaskY+shadowDrop);
			dilation = outlineStroke + maxOf(1,round(shadowBlur/2));
			run("Enlarge...", "enlarge=&dilation pixel");
			if(textChoiceLines<2) run("Interpolate", "interval=&shadowBlur smooth"); /* Does not work for multiple lines */
			List.setMeasurements ;
			bgGray = List.getValue("Mean");
			List.clear();
			if (imageDepth==16 || imageDepth==32) bgGray = round(bgGray/256);
			shadowHex = "#" + "" + String.pad(toHex(255 * (100-shadowDarkness)/100), 2) + "000000";
			setSelectionName("Fancy Text Label Shadow");
			Overlay.addSelection(shadowHex, outlineStroke, shadowHex);
			run("Select None");
			getSelectionFromMask("label_mask");
			if (textRot!=0) run("Rotate...", "  angle=&textRot");
			run("Enlarge...", "enlarge=&outlineStroke pixel");
			setSelectionName("Fancy Text Label Outline");
			Overlay.addSelection(outlineColorHex,outlineStroke,outlineColorHex);
			/* Note that when the image is viewed at anything other than 100% the overlays will not appear to be lined up correctly */
			run("Select None");
			getSelectionFromMask("label_mask");
			if (textRot!=0){
				run("Rotate...", "angle=&textRot");
				setSelectionName("Fancy Rotated Text Labels");
			}
			else setSelectionName("Fancy Text Labels");
			Overlay.addSelection(outlineColorHex,outlineStroke,fontColorHex);
			Overlay.show;
		}
		else {
			if (textRot!=0){
				newImage("rot_label_mask", "8-bit black", imageWidth, imageHeight, 1);
				setColorFromColorName("white");
				getSelectionFromMask("label_mask");
				run("Rotate...", "angle=&textRot");
				fill();
				run("Select None");
				run("Convert to Mask"); /* AKA Make Binary" */
				run("Invert");
				active_Label_Mask = "rot_label_mask";
			}
			else active_Label_Mask = "label_mask";
			/* Create drop shadow if desired */
			if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0) {
				showStatus("Creating drop shadow for labels . . . ");
				createShadowDropFromMask7(active_Label_Mask, shadowDrop, shadowDisp, shadowBlur, shadowDarkness, outlineStroke);
			}
			for (s=0; s<remSlices+1; s++) {
				showProgress(-s/remSlices);
				if (isOpen("shadow") && shadowDarkness>0)
					imageCalculator("Subtract", workingImage,"shadow");
				else if (isOpen("shadow") && (shadowDarkness<0))
					imageCalculator("Add", workingImage,"shadow");
				run("Select None");
				/* Create outline around text */
				selectWindow(workingImage);
				getSelectionFromMask(active_Label_Mask);
				// if (textRot!=0) run("Rotate...", "angle=&textRot");
				getSelectionBounds(maskX, maskY, null, null);
				outlineStrokeOffset = minOf(round(shadowDisp/2), round(maxOf(0,(outlineStroke/2)-1)));
				setSelectionLocation(maskX+outlineStrokeOffset, maskY+outlineStrokeOffset); /* Offset selection to create shadow effect */
				run("Enlarge...", "enlarge=&outlineStroke pixel");
				setBackgroundFromColorName(outlineColor);
				run("Clear", "slice");
				outlineStrokeOffsetMod = outlineStrokeOffset/2;
				run("Enlarge...", "enlarge=&outlineStrokeOffsetMod pixel");
				run("Gaussian Blur...", "sigma=&outlineStrokeOffsetMod");
				run("Select None");
				/* Create text */
				getSelectionFromMask(active_Label_Mask);
				setBackgroundFromColorName(fontColor);
				run("Clear", "slice");
				run("Enlarge...", "enlarge=1 pixel");
				run("Gaussian Blur...", "sigma=0.75");
				run("Unsharp Mask...", "radius=1 mask=0.75");
				if (raised || recessed) {
					outlineRGBs = getColorArrayFromColorName(outlineColor);
					Array.getStatistics(outlineRGBs, null, null, outlineColorMean, null);
					textRGBs = getColorArrayFromColorName(fontColor);
					Array.getStatistics(textRGBs, null, null, textColorMean, null);
					if (outlineColorMean > textColorMean) {
						if (raised && !recessed) {
							raised = false;
							recessed = true;
						} else if (!raised && recessed) {
							raised = true;
							recessed = false;
						}
					}
					fontLineWidth = getStringWidth("!");
					rAlpha = fontLineWidth / 40;
					if (raised) {
						getSelectionFromMask("label_mask");
						if (!noOutline) run("Enlarge...", "enlarge=1 pixel");
						run("Convolve...", "text1=[ " + createConvolverMatrix("raised", fontLineWidth) + " ]");
						if (rAlpha > 0.33) run("Gaussian Blur...", "sigma=&rAlpha");
						run("Select None");
					}
					if (recessed) {
						getSelectionFromMask("label_mask");
						if (!noOutline && !raised) run("Enlarge...", "enlarge=1 pixel");
						run("Enlarge...", "enlarge=1 pixel");
						run("Convolve...", "text1=[ " + createConvolverMatrix("recessed", fontLineWidth) + " ]");
						if (rAlpha > 0.33) run("Gaussian Blur...", "sigma=rAlpha");
						run("Select None");
					}
				}
				run("Select None");
				if (labelRest==false) remSlices = 0;
				else run("Next Slice [>]");
			}
		}
		closeImageByTitle("shadow");
		closeImageByTitle("label_mask");
		closeImageByTitle("rot_label_mask");
	}
	else {
		selectWindow(workingImage);
		IJ.log(fontColor + " " + getHexColorFromColorName(fontColor));
		setColor("" + getHexColorFromColorName(fontColor));
		// setColor(#);
		for (s=0; s<remSlices+1; s++) {
			showProgress(-s/remSlices);
			textLabelLineY = textLabelY;
			for (i=0; i<textOutNumber; i++) {
				if (textInputLines[i]!="-blank-") {
					if (endsWith(overWrite,"verlays")){
						// setColor("" + getHexColorFromColorName(fontColor));
						if (just=="left") Overlay.drawStringtextInputLinesText[i], textLabelX, textLabelLineY, textRot);
						else if (just=="right") Overlay.drawString(textInputLinesText[i], textLabelX + (longestStringWidth - getStringWidth(textInputLinesText[i])), textLabelLineY, textRot);
						else Overlay.drawString(textInputLinesText[i], textLabelX + (longestStringWidth-getStringWidth(textInputLinesText[i]))/2, textLabelLineY, textRot);
						Overlay.show;
					} else {
						if (just=="left") drawString(textInputLinesText[i], textLabelX, textLabelLineY);
						else if (just=="right") drawString(textInputLinesText[i], textLabelX + (longestStringWidth - getStringWidth(textInputLinesText[i])), textLabelLineY);
						else drawString(textInputLinesText[i], textLabelX + (longestStringWidth-getStringWidth(textInputLinesText[i]))/2, textLabelLineY);
					}
					textLabelLineY += lineSpacing * fontSize;
				}
				else textLabelLineY += lineSpacing * fontSize;
			}
			if (labelRest==false) remSlices = 0;
			else run("Next Slice [>]");
		}
	}
	selectWindow(workingImage);
	if (startsWith(overWrite, "New"))  {
		if ((lastIndexOf(originalImage,"."))>0)  workingImageNameWOExt = unCleanLabel(substring(workingImage, 0, lastIndexOf(workingImage,".")));
		else workingImageNameWOExt = unCleanLabel(workingImage);
		rename(workingImageNameWOExt + "+text");
	}
	restoreSettings;
	run("Select None");
	setBatchMode("exit & display");
	if (endsWith(textLocChoice, "election") && restoreSelection) {
		if (selEType==0) makeRectangle(orSelEX, orSelEY, orSelEWidth, orSelEHeight);
		if (selEType==1) makeOval(orSelEX, orSelEY, orSelEWidth, orSelEHeight);
		if ((selEType>=5) && (selEType<7)) {
			makeLine(orSelEX1, orSelEY1, orSelEX2, orSelEY2);
			if (getBoolean("Create flattened image with line selection")) {
				run("Add Selection..."); /* By adding selection to overlay this also works with the overlay label */
				run("Flatten");
			}
		}
	}
	else run("Select None");
	showStatus("Fancy Text Labels Finished");
	call("java.lang.System.gc");
}
	/*
	( 8(|)   ( 8(|)  ASC and ASC-mod-BAR Functions  ( 8(|)  ( 8(|)
	*/
	function cleanLabel(string) {
		/*  ImageJ macro default file encoding (ANSI or UTF-8) varies with platform so non-ASCII characters may vary: hence the need to always use fromCharCode instead of special characters.
		v180611 added "degreeC"
		v200604	fromCharCode(0x207B) removed as superscript hyphen not working reliably
		v220630 added degrees v220812 Changed Ångström unit code
		v231005 Weird Excel characters added, micron unit correction */
		string= replace(string, "\\^2", fromCharCode(178)); /* superscript 2 */
		string= replace(string, "\\^3", fromCharCode(179)); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, "\\^-"+fromCharCode(185), "-" + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-"+fromCharCode(178), "-" + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "\\^-^1", "-" + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-^2", "-" + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "\\^-1", "-" + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-2", "-" + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "\\^-^1", "-" + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-^2", "-" + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "(?<![A-Za-z0-9])u(?=m)", fromCharCode(181)); /* micron units */
		string= replace(string, "\\b[aA]ngstrom\\b", fromCharCode(0x212B)); /* Ångström unit symbol */
		string= replace(string, "  ", " "); /* Replace double spaces with single spaces */
		string= replace(string, "_", " "); /* Replace underlines with space as thin spaces (fromCharCode(0x2009)) not working reliably  */
		string= replace(string, "px", "pixels"); /* Expand pixel abbreviation */
		string= replace(string, "degreeC", fromCharCode(0x00B0) + "C"); /* Degree symbol for dialog boxes */
		// string = replace(string, " " + fromCharCode(0x00B0), fromCharCode(0x2009) + fromCharCode(0x00B0)); /* Replace normal space before degree symbol with thin space */
		// string= replace(string, " °", fromCharCode(0x2009) + fromCharCode(0x00B0)); /* Replace normal space before degree symbol with thin space */
		string= replace(string, "sigma", fromCharCode(0x03C3)); /* sigma for tight spaces */
		string= replace(string, "plusminus", fromCharCode(0x00B1)); /* plus or minus */
		string= replace(string, "degrees", fromCharCode(0x00B0)); /* plus or minus */
		if (indexOf(string,"mý")>1) string = substring(string, 0, indexOf(string,"mý")-1) + getInfo("micrometer.abbreviation") + fromCharCode(178);
		return string;
	}
	function closeImageByTitle(windowTitle) {  /* Cannot be used with tables */
        if (isOpen(windowTitle)) {
		selectWindow(windowTitle);
        close();
		}
	}
	function createConvolverMatrix(effect, thickness){
		/* v230413: 1st version PJL Effects assumed: "Recessed or Raised".
			v240313 Added spaces after commas. */
		matrixText = "";
		matrixSize = maxOf(3, (1 + 2 * round(thickness/10)));
		matrixLC = matrixSize -1;
		matrixCi = matrixSize/2 - 0.5;
		mFact = 1/(matrixSize-1);
		for(y=0, c=0; y<matrixSize ; y++){
			for(x=0; x<matrixSize; x++){
				if(x!=y){
					matrixText += " 0";
					if (x==matrixLC) matrixText += "\n";
				}
				else {
					if (x==matrixCi) matrixText += " 1";
					else if (effect=="raised"){ /* Otherwise assumed to be 'recessed' */
						if (x<matrixCi) matrixText += " -" + mFact;
						else matrixText += " " + mFact;
					}
					else {
						if (x>matrixCi) matrixText += " -" + mFact;
						else matrixText += " " + mFact;				
					}
				}
			}
		}
		matrixText += "\n";
		return matrixText;
	}
	function toChar(string) {
		/* v180612 first version
			v1v180627 Expanded
			v200428 removed "symbol" prefix */
		string= replace(string, "Angstrom", fromCharCode(0x212B)); /* ANGSTROM SIGN */
		string= replace(string, "alpha", fromCharCode(0x03B1));
		string= replace(string, "Alpha", fromCharCode(0x0391));
		string= replace(string, "beta", fromCharCode(0x03B2)); /* Lower case beta */
		string= replace(string, "Beta", fromCharCode(0x0392)); /* ß CAPITAL */
		string= replace(string, "gamma", fromCharCode(0x03B3)); /* MATHEMATICAL SMALL GAMMA */
		string= replace(string, "Gamma", fromCharCode(0xD835)); /* MATHEMATICAL BOLD CAPITAL  GAMMA */
		string= replace(string, "delta", fromCharCode(0x1E9F)); /*  SMALL LETTER DELTA */
		string= replace(string, "Delta", fromCharCode(0x0394)); /*  CAPITAL LETTER DELTA */
		string= replace(string, "epsilon", fromCharCode(0x03B5)); /* GREEK SMALL LETTER EPSILON */
		string= replace(string, "Epsilon", fromCharCode(0x0395)); /* GREEK CAPITAL LETTER EPSILON */
		string= replace(string, "zeta", fromCharCode(0x03B6)); /* GREEK SMALL LETTER ZETA */
		string= replace(string, "Zeta", fromCharCode(0x0396)); /* GREEK CAPITAL LETTER ZETA */
		string= replace(string, "theta", fromCharCode(0x03B8)); /* GREEK SMALL LETTER THETA */
		string= replace(string, "Theta", fromCharCode(0x0398)); /* GREEK CAPITAL LETTER THETA */
		string= replace(string, "iota", fromCharCode(0x03B9)); /* GREEK SMALL LETTER IOTA */
		string= replace(string, "Iota", fromCharCode(0x0196)); /* GREEK CAPITAL LETTER IOTA */
		string= replace(string, "kappa", fromCharCode(0x03BA)); /* GREEK SMALL LETTER KAPPA */
		string= replace(string, "Kappa", fromCharCode(0x0196)); /* GREEK CAPITAL LETTER KAPPA */
		string= replace(string, "lambda", fromCharCode(0x03BB)); /* GREEK SMALL LETTER LAMDA */
		string= replace(string, "Lambda", fromCharCode(0x039B)); /* GREEK CAPITAL LETTER LAMDA */
		string= replace(string, "mu", fromCharCode(0x03BC)); /* µ GREEK SMALL LETTER MU */
		string= replace(string, "Mu", fromCharCode(0x039C)); /* GREEK CAPITAL LETTER MU */
		string= replace(string, "nu", fromCharCode(0x03BD)); /*  GREEK SMALL LETTER NU */
		string= replace(string, "Nu", fromCharCode( 0x039D)); /*  GREEK CAPITAL LETTER NU */
		string= replace(string, "xi", fromCharCode(0x03BE)); /* GREEK SMALL LETTER XI */
		string= replace(string, "Xi", fromCharCode(0x039E)); /* GREEK CAPITAL LETTER XI */
		string= replace(string, "pi", fromCharCode(0x03C0)); /* GREEK SMALL LETTER Pl */
		string= replace(string, "Pi", fromCharCode(0x03A0)); /* GREEK CAPITAL LETTER Pl */
		string= replace(string, "rho", fromCharCode(0x03C1)); /* GREEK SMALL LETTER RHO */
		string= replace(string, "Rho", fromCharCode(0x03A1)); /* GREEK CAPITAL LETTER RHO */
		string= replace(string, "sigma", fromCharCode(0x03C3)); /* GREEK SMALL LETTER SIGMA */
		string= replace(string, "Sigma", fromCharCode(0x03A3)); /* GREEK CAPITAL LETTER SIGMA */
		string= replace(string, "phi", fromCharCode(0x03C6)); /* GREEK SMALL LETTER PHI */
		string= replace(string, "Phi", fromCharCode(0x03A6)); /* GREEK CAPITAL LETTER PHI */
		string= replace(string, "omega", fromCharCode(0x03C9)); /* GREEK SMALL LETTER OMEGA */
		string= replace(string, "Omega", fromCharCode(0x03A9)); /* GREEK CAPITAL LETTER OMEGA */
		string= replace(string, "eta", fromCharCode(0x03B7)); /*  GREEK SMALL LETTER ETA */
		string= replace(string, "Eta", fromCharCode(0x0397)); /*  GREEK CAPITAL LETTER ETA */
		string= replace(string, "sub2", fromCharCode(0x2082)); /*  subscript 2 */
		string= replace(string, "sub3", fromCharCode(0x2083)); /*  subscript 3 */
		string= replace(string, "sub4", fromCharCode(0x2084)); /*  subscript 4 */
		string= replace(string, "sub5", fromCharCode(0x2085)); /*  subscript 5 */
		string= replace(string, "sup2", fromCharCode(0x00B2)); /*  superscript 2 */
		string= replace(string, "sup3", fromCharCode(0x00B3)); /*  superscript 3 */
		string= replace(string, ">=", fromCharCode(0x2265)); /* GREATER-THAN OR EQUAL TO */
		string= replace(string, "<=", fromCharCode(0x2264)); /* LESS-THAN OR EQUAL TO */
		string= replace(string, "xx", fromCharCode(0x00D7)); /* MULTIPLICATION SIGN */
		string= replace(string, "copyright=", fromCharCode(0x00A9)); /* © */
		string= replace(string, "ro", fromCharCode(0x00AE)); /* registered sign */
		string= replace(string, "tm", fromCharCode(0x2122)); /* ™ */
		string= replace(string, "parallelto", fromCharCode(0x2225)); /* PARALLEL TO  note CANNOT use "|" key */
		// string= replace(string, "perpendicularto", fromCharCode(0x27C2)); /* PERPENDICULAR note CANNOT use "|" key */
		string= replace(string, "degree", fromCharCode(0x00B0)); /* Degree */
		string= replace(string, "degreeC", fromCharCode(0x00B0)+fromCharCode(0x2009) + "C"); /* Degree C */
		string= replace(string, "arrow-up", fromCharCode(0x21E7)); /* 'UPWARDS WHITE ARROW */
		string= replace(string, "arrow-down", fromCharCode(0x21E9)); /* 'DOWNWARDS WHITE ARROW */
		string= replace(string, "arrow-left", fromCharCode(0x21E6)); /* 'LEFTWARDS WHITE ARROW */
		string= replace(string, "arrow-right", fromCharCode(0x21E8)); /* 'RIGHTWARDS WHITE ARROW */
		return string;
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
	function getSelectionFromMask(selection_Mask){
		/* v210628 check to make sure selection is not inverted */
		tempTitle = getTitle();
		selectWindow(selection_Mask);
		run("Create Selection");
		/* Check to see if selection is inverted perhaps because the mask has an inverted LUT? */
		getSelectionBounds(x, y, width, height);
		getDimensions(iwidth, iheight, null,null,null);
		if (x==0 && y==0 && width==iwidth && height==iheight) run("Make Inverse");
		selectWindow(tempTitle);
		run("Restore Selection");
	}
	function getColorArrayFromColorName(colorName) {
		/* v180828 added Fluorescent Colors
		   v181017-8 added off-white and off-black for use in gif transparency and also added safe exit if no color match found
		   v191211 added Cyan
		   v211022 all names lower-case, all spaces to underscores v220225 Added more hash value comments as a reference v220706 restores missing magenta
		   v230130 Added more descriptions and modified order.
		   v230908: Returns "white" array if not match is found and logs issues without exiting.
		   v240123: Removed duplicate entries: Now 53 unique colors.
		   v240709: Added 2024 FSU-Branding Colors. Some reorganization. Now 60 unique colors.
		*/
		functionL = "getColorArrayFromColorName_v240709";
		cA = newArray(255, 255, 255); /* defaults to white */
		if (colorName == "white") cA = newArray(255, 255, 255);
		else if (colorName == "black") cA = newArray(0, 0, 0);
		else if (colorName == "off-white") cA = newArray(245, 245, 245);
		else if (colorName == "off-black") cA = newArray(10, 10, 10);
		else if (colorName == "light_gray") cA = newArray(200, 200, 200);
		else if (colorName == "gray") cA = newArray(127, 127, 127);
		else if (colorName == "dark_gray") cA = newArray(51, 51, 51);
		else if (colorName == "red") cA = newArray(255, 0, 0);
		else if (colorName == "green") cA = newArray(0, 255, 0);						/* #00FF00 AKA Lime green */
		else if (colorName == "blue") cA = newArray(0, 0, 255);
		else if (colorName == "cyan") cA = newArray(0, 255, 255);
		else if (colorName == "yellow") cA = newArray(255, 255, 0);
		else if (colorName == "magenta") cA = newArray(255, 0, 255);					/* #FF00FF */
		else if (colorName == "pink") cA = newArray(255, 192, 203);
		else if (colorName == "violet") cA = newArray(127, 0, 255);
		else if (colorName == "orange") cA = newArray(255, 165, 0);
			/* Excel Modern  + */
		else if (colorName == "aqua_modern") cA = newArray(75, 172, 198);			/* #4bacc6 AKA "Viking" aqua */
		else if (colorName == "blue_accent_modern") cA = newArray(79, 129, 189);	/* #4f81bd */
		else if (colorName == "blue_dark_modern") cA = newArray(31, 73, 125);		/* #1F497D */
		else if (colorName == "blue_honolulu") cA = newArray(0, 118, 182);			/* Honolulu Blue #006db0 */
		else if (colorName == "blue_modern") cA = newArray(58, 93, 174);			/* #3a5dae */
		else if (colorName == "gray_modern") cA = newArray(83, 86, 90);				/* bright gray #53565A */
		else if (colorName == "green_dark_modern") cA = newArray(121, 133, 65);		/* Wasabi #798541 */
		else if (colorName == "green_modern") cA = newArray(155, 187, 89);			/* #9bbb59 AKA "Chelsea Cucumber" */
		else if (colorName == "green_modern_accent") cA = newArray(214, 228, 187); 	/* #D6E4BB AKA "Gin" */
		else if (colorName == "green_spring_accent") cA = newArray(0, 255, 102);	/* #00FF66 AKA "Spring Green" */
		else if (colorName == "orange_modern") cA = newArray(247, 150, 70);			/* #f79646 tan hide, light orange */
		else if (colorName == "pink_modern") cA = newArray(255, 105, 180);			/* hot pink #ff69b4 */
		else if (colorName == "purple_modern") cA = newArray(128, 100, 162);		/* blue-magenta, purple paradise #8064A2 */
		else if (colorName == "red_n_modern") cA = newArray(227, 24, 55);
		else if (colorName == "red_modern") cA = newArray(192, 80, 77);
		else if (colorName == "tan_modern") cA = newArray(238, 236, 225);
		else if (colorName == "violet_modern") cA = newArray(76, 65, 132);
		else if (colorName == "yellow_modern") cA = newArray(247, 238, 69);
			/* FSU */
		else if (colorName == "garnet") cA = newArray(120, 47, 64);					/* #782F40 */
		else if (colorName == "gold") cA = newArray(206, 184, 136);					/* #CEB888 */
		else if (colorName == "gulf_sands") cA = newArray(223, 209, 167);				/* #DFD1A7 */
		else if (colorName == "stadium_night") cA = newArray(16, 24, 32);				/* #101820 */
		else if (colorName == "westcott_water") cA = newArray(92, 184, 178);			/* #5CB8B2 */
		else if (colorName == "vault_garnet") cA = newArray(166, 25, 46);				/* #A6192E */
		else if (colorName == "legacy_blue") cA = newArray(66, 85, 99);				/* #425563 */
		else if (colorName == "plaza_brick") cA = newArray(66, 85, 99);				/* #572932  */
		else if (colorName == "vault_gold") cA = newArray(255, 199, 44);				/* #FFC72C  */
		   /* Fluorescent Colors https://www.w3schools.com/colors/colors_crayola.asp   */
		else if (colorName == "radical_red") cA = newArray(255, 53, 94);			/* #FF355E */
		else if (colorName == "jazzberry_jam") cA = newArray(165, 11, 94);
		else if (colorName == "wild_watermelon") cA = newArray(253, 91, 120);		/* #FD5B78 */
		else if (colorName == "shocking_pink") cA = newArray(255, 110, 255);		/* #FF6EFF Ultra Pink */
		else if (colorName == "razzle_dazzle_rose") cA = newArray(238, 52, 210);	/* #EE34D2 */
		else if (colorName == "hot_magenta") cA = newArray(255, 0, 204);			/* #FF00CC AKA Purple Pizzazz */
		else if (colorName == "outrageous_orange") cA = newArray(255, 96, 55);		/* #FF6037 */
		else if (colorName == "supernova_orange") cA = newArray(255, 191, 63);		/* FFBF3F Supernova Neon Orange*/
		else if (colorName == "sunglow") cA = newArray(255, 204, 51);				/* #FFCC33 */
		else if (colorName == "neon_carrot") cA = newArray(255, 153, 51);			/* #FF9933 */
		else if (colorName == "atomic_tangerine") cA = newArray(255, 153, 102);		/* #FF9966 */
		else if (colorName == "laser_lemon") cA = newArray(255, 255, 102);			/* #FFFF66 "Unmellow Yellow" */
		else if (colorName == "electric_lime") cA = newArray(204, 255, 0);			/* #CCFF00 */
		else if (colorName == "screamin'_green") cA = newArray(102, 255, 102);		/* #66FF66 */
		else if (colorName == "magic_mint") cA = newArray(170, 240, 209);			/* #AAF0D1 */
		else if (colorName == "blizzard_blue") cA = newArray(80, 191, 230);		/* #50BFE6 Malibu */
		else if (colorName == "dodger_blue") cA = newArray(9, 159, 255);			/* #099FFF Dodger Neon Blue */
		else IJ.log(colorName + " not found in " + functionL + ": Color defaulted to white");
		return cA;
	}
	function getHexColorFromColorName(colorNameString) {
		/* v231207: Uses IJ String.pad instead of function: pad */
		colorArray = getColorArrayFromColorName(colorNameString);
		 r = toHex(colorArray[0]); g = toHex(colorArray[1]); b = toHex(colorArray[2]);
		 hexName= "#" + "" + String.pad(r, 2) + "" + String.pad(g, 2) + "" + String.pad(b, 2);
		 return hexName;
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
	function restoreExit(message){ /* Make a clean exit from a macro, restoring previous settings */
		/* 9/9/2017 added Garbage clean up suggested by Luc LaLonde - LBNL */
		restoreSettings(); /* Restore previous settings before exiting */
		setBatchMode("exit & display"); /* Probably not necessary if exiting gracefully but otherwise harmless */
		call("java.lang.System.gc");
		exit(message);
	}
	function setColorFromColorName(colorName) {
		colorArray = getColorArrayFromColorName(colorName);
		setColor(colorArray[0], colorArray[1], colorArray[2]);
	}
	function setBackgroundFromColorName(colorName) {
		colorArray = getColorArrayFromColorName(colorName);
		setBackgroundColor(colorArray[0], colorArray[1], colorArray[2]);
	}
	function unCleanLabel(string) {
	/* v161104 This function replaces special characters with standard characters for file system compatible filenames.
	+ 041117b to remove spaces as well.
	+ v220126 added getInfo("micrometer.abbreviation").
	+ v220128 add loops that allow removal of multiple duplication.
	+ v220131 fixed so that suffix cleanup works even if extensions are included.
	+ v220616 Minor index range fix that does not seem to have an impact if macro is working as planned. v220715 added 8-bit to unwanted dupes. v220812 minor changes to micron and Ångström handling
	+ v231005 Replaced superscript abbreviations that did not work.
	+ v240124 Replace _+_ with +.
	*/
		/* Remove bad characters */
		string = string.replace(fromCharCode(178), "sup2"); /* superscript 2 */
		string = string.replace(fromCharCode(179), "sup3"); /* superscript 3 UTF-16 (decimal) */
		string = string.replace(fromCharCode(0xFE63) + fromCharCode(185), "sup-1"); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
		string = string.replace(fromCharCode(0xFE63) + fromCharCode(178), "sup-2"); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
		string = string.replace(fromCharCode(181) + "m", "um"); /* micron units */
		string = string.replace(getInfo("micrometer.abbreviation"), "um"); /* micron units */
		string = string.replace(fromCharCode(197), "Angstrom"); /* Ångström unit symbol */
		string = string.replace(fromCharCode(0x212B), "Angstrom"); /* the other Ångström unit symbol */
		string = string.replace(fromCharCode(0x2009) + fromCharCode(0x00B0), "deg"); /* replace thin spaces degrees combination */
		string = string.replace(fromCharCode(0x2009), "_"); /* Replace thin spaces  */
		string = string.replace("%", "pc"); /* % causes issues with html listing */
		string = string.replace(" ", "_"); /* Replace spaces - these can be a problem with image combination */
		/* Remove duplicate strings */
		unwantedDupes = newArray("8bit", "8-bit", "lzw");
		for (i=0; i<lengthOf(unwantedDupes); i++){
			iLast = lastIndexOf(string, unwantedDupes[i]);
			iFirst = indexOf(string, unwantedDupes[i]);
			if (iFirst!=iLast) {
				string = string.substring(0, iFirst) + string.substring(iFirst + lengthOf(unwantedDupes[i]));
				i = -1; /* check again */
			}
		}
		unwantedDbls = newArray("_-", "-_", "__", "--", "\\+\\+");
		for (i=0; i<lengthOf(unwantedDbls); i++){
			iFirst = indexOf(string, unwantedDbls[i]);
			if (iFirst>=0) {
				string = string.substring(0, iFirst) + string.substring(string, iFirst + lengthOf(unwantedDbls[i]) / 2);
				i = -1; /* check again */
			}
		}
		string = string.replace("_\\+", "\\+"); /* Clean up autofilenames */
		string = string.replace("\\+_", "\\+"); /* Clean up autofilenames */
		/* cleanup suffixes */
		unwantedSuffixes = newArray(" ", "_", "-", "\\+"); /* things you don't wasn't to end a filename with */
		extStart = lastIndexOf(string, ".");
		sL = lengthOf(string);
		if (sL-extStart<=4 && extStart>0) extIncl = true;
		else extIncl = false;
		if (extIncl){
			preString = substring(string, 0, extStart);
			extString = substring(string, extStart);
		}
		else {
			preString = string;
			extString = "";
		}
		for (i=0; i<lengthOf(unwantedSuffixes); i++){
			sL = lengthOf(preString);
			if (endsWith(preString, unwantedSuffixes[i])) {
				preString = substring(preString, 0, sL-lengthOf(unwantedSuffixes[i])); /* cleanup previous suffix */
				i=-1; /* check one more time */
			}
		}
		if (!endsWith(preString, "_lzw") && !endsWith(preString, "_lzw.")) preString = replace(preString, "_lzw", ""); /* Only want to keep this if it is at the end */
		string = preString + extString;
		/* End of suffix cleanup */
		return string;
	}
	function writeLabel_CFXY(label,labelColor,labelFontName, labelFontSize,labelX,labelY){
		setFont(labelFontName, labelFontSize, "antialiased");
		setColorFromColorName(labelColor);
		drawString(label, labelX, labelY);
	}