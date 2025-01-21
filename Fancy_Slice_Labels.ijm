macro "Fancy Slice Labels" {
	/* This macro adds multiple lines of text to a copy of the image.
		Peter J. Lee Applied Superconductivity Center at National High Magnetic Field Laboratory.
		ANSI encoded for Windows.
		Slices can be named with sequential numbers using imageJ's "stack sorter"
		Non-formated slice labels can be applied with more variables and previews to images using ImageJ's "Label Stacks" and Dan White's (MPI-CBG) "Series Labeler", so you might want to try that more sophisticated programming first.
		v180629 First version based on v180628 of the Fancy Text Label macro.
		v181018 First working version  >:-}  .
		v190415 Adds option to update embedded slice labels.
		v190627 Skips slices without labels rather than clearing them :-$ . Also Function updates.
		v190628 Adds options to add prefixes, suffixes and a counter as well as replacing strings in slice labels. Minor fixes.
		+ v200707 Changed imageDepth variable name added macro label.
		+ v210316-v210325 Changed toChar function so shortcuts (i.e. "pi") only converted to symbols if followed by a space.
		+ v210503 Split menu options so that auto-generation menu is simpler
		+ v211022 Updated color choices  v220310-11 Added warning if some slices had no label (TIF-lzw does not store labels). f2: updated pad function f3: updated colors
		+ v220727 Minor format changes f1-f3: updated colors
		+ v230418-9: Simplified. Replaced inner shadow with raised/recessed. Font autoshrunk per slice if text overflows margins. Centers adjusted per slice. F1: Updated indexOf functions. F2: getColorArrayFromColorName_v230908.  F7 : Replaced function: pad. F8: Updated getColorFromColorName function (012324). F9: updated function unCleanLabel.
		+ v240709: Updated color selection.
		+ v250121: Added not-fancy formatting option (much quicker and uses anti-aliasing). Fixed some formatting issues.
	 */
	macroL = "Fancy_Slice_Labels_v250121.ijm";
	if (nImages < 1) exit("This macro \(" + macroL + "\) requires at least one image to be open");
	requires("1.47r");
	saveSettings;
	if (selectionType >= 0) {
		selEType = selectionType;
		selectionExists = true;
		getSelectionBounds(orSelEX, orSelEY, orSelEWidth, orSelEHeight);
		baseMenuHeight = 587;
	} else {
		selectionExists = false;
		baseMenuHeight = 460;
	}
	originalImage = getTitle();
	/*	Set options for black objects on white background as this works better for publications */
	run("Options...", "iterations=1 white count=1"); /* Set the background to white */
	run("Colors...", "foreground=black background=white selection=yellow"); /* Set the preferred colors for these macros */
	setOption("BlackBackground", false);
	run("Appearance...", " ");
	/* do not use Inverting LUT *
	/* Check to see if a Ramp legend rather than the image has been selected by accident */
	if (matches(originalImage, ".*Ramp.*") == 1) showMessageWithCancel("Title contains \"Ramp\"", "Do you want to label" + originalImage + " ?");
	getDimensions(imageWidth, imageHeight, channels, slices, frames);
	sH = screenHeight();
	sW = screenWidth();
	menuRowHeight = 29;
	maxMenuSlices = floor((sH - baseMenuHeight) / menuRowHeight);
	maxLabelString = imageWidth / 10; /* Assumes a minimum font character width of 5 */
	startSliceNumber = getSliceNumber();
	remSlices = nSlices - startSliceNumber;
	allSliceLabels = newArray();
	for (i = 0, emptyLabelN = 0, maxString = 0; i < nSlices; i++) {
		setSlice(i + 1);
		allSliceLabels[i] = getInfo("slice.label");
		if (allSliceLabels[i] == "") emptyLabelN++;
		else {
			stringL = lengthOf(allSliceLabels[i]);
			if (stringL > maxString) maxString = stringL;
		}
	}
	maxLabelString = minOf(maxLabelString, maxString);
	setSlice(startSliceNumber);
	imageDims = imageHeight + imageWidth;
	imageDepth = bitDepth();
	if (imageDepth == 16) {
		Dialog.create("Bit depth conversion");
		Dialog.addMessage("Sorry, this macro does not work well with 16-bit images./nBut perhaps a labeled 16-bit image is unnecessary?");
		conversionChoice = newArray("RGB Color", "8-bit Gray", "Exit");
		Dialog.addRadioButtonGroup("Choose:", conversionChoice, 3, 1, "8-bit Gray");
		Dialog.show();
		convertTo = Dialog.getRadioButton();
		if (convertTo == "8-bit Gray") run("8-bit");
		else if (convertTo == "RGB Color") run("RGB Color");
		else restoreExit("Goodbye");
	}
	imageDepth = bitDepth();
	id = getImageID();
	maxFontW = imageWidth / (1.2 * maxLabelString);
	maxFontH = imageHeight / (1.2 * getValue("font.height"));
	fontSize = floor(minOf(maxFontW, maxFontH)); /* default font size */
	if (fontSize < 12) fontSize = maxOf(10, fontSize); /* set minimum default font size as 10 */
	defScaleBarFS = maxOf(12, round((minOf(imageHeight, imageWidth)) / 30)); /* used as information in the 1st options dialog */
	setFont("", fontSize, "bold antialiased");
	fontHeight = getValue("font.height");
	lineSpacing = 1.1;
	outlineStrokePx = maxOf(1, fontHeight / 20); /* default outline stroke: % of font size */
	shadowDrop = 10; /* default outer shadow drop: % of font size */
	shadowDisp = shadowDrop;
	shadowBlur = floor(0.6 * shadowDrop);
	shadowDarkness = 40;
	offsetX = round(1 + imageWidth / 150); /* default offset of label from edge */
	offsetY = round(1 + imageHeight / 150); /* default offset of label from edge */
	/* Then Dialog . . . */
	Dialog.create("Label Format and Edit Options: " + macroL);
	Dialog.addNumber("Start slice number:", startSliceNumber, 0, 4, "#");
	Dialog.addNumber("End slice number:", nSlices, 0, 4, "#");
	if (emptyLabelN > 0) Dialog.addMessage("Warning: " + emptyLabelN + " slices had no label", 12, "red");
	if (selectionExists == 1) {
		textLocChoices = newArray("Top Left", "Top Right", "Top Center", "Center", "Bottom Left", "Bottom Center", "Bottom Right", "Center of New Selection", "Center of Selection");
		iLoc = indexOfArray(textLocChoices, call("ij.Prefs.get", "fancy.sliceLabels.location", textLocChoices[6]), 6);
	} else {
		textLocChoices = newArray("Top Left", "Top Right", "Top Center", "Center", "Bottom Left", "Bottom Center", "Bottom Right", "Center of New Selection");
		iLoc = indexOfArray(textLocChoices, call("ij.Prefs.get", "fancy.sliceLabels.location", textLocChoices[0]), 0);
	}
	Dialog.addChoice("Location of Label:", textLocChoices, textLocChoices[iLoc]);
	textJustChoices = newArray("auto", "left", "center", "right");
	if (selectionExists == 1) {
		Dialog.addNumber("Original selection X start = ", orSelEX);
		Dialog.addNumber("Original selection Y start = ", orSelEY);
		Dialog.addNumber("Original selection width = ", orSelEWidth);
		Dialog.addNumber("Original selection height = ", orSelEHeight);
		Dialog.addCheckbox("Restore this selection at macro completion?", true);
		if (orSelEX < imageWidth * 0.4) just = "left";
		else if (orSelEX > imageWidth * 0.6) just = "right";
		else just = "center";
		Dialog.addChoice("Text justification, Auto = " + just, textJustChoices, textJustChoices[0]);
	} else {
		restoreSelection = false;
		Dialog.addChoice("Text justification", textJustChoices, textJustChoices[0]);
	}
	Dialog.addNumber("Font size:", fontSize, 0, 4, "\(default fancy scalebar font size is " + defScaleBarFS + "\)");
	fancyStyleEffectsOptions = newArray("No shadows", "No outline", "Raised", "Recessed");
	fancyStyleEffectsDefaults = newArray(false, false, false, false);
	fancyStyleEffectsPrefs = call("ij.Prefs.get", "fancy.sliceLabels.fancyStyleEffects", "not found");
	if (fancyStyleEffectsPrefs != "not found") {
		fancyStyleEffects = split(fancyStyleEffectsPrefs, "|");
		if (fancyStyleEffects.length == fancyStyleEffectsOptions.length) fancyStyleEffectsDefaults = fancyStyleEffects;
	}
	Dialog.setInsets(10, 20, 0);
	Dialog.addCheckboxGroup(1, fancyStyleEffectsOptions.length, fancyStyleEffectsOptions, fancyStyleEffectsDefaults);
	if (fancyStyleEffectsPrefs == "|1|1|0|0") notFancy = true;
	else notFancy = false;
	Dialog.addCheckbox("No fancy text formatting \(overrides above\)", notFancy);
	grayChoices = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray");
	colorChoicesStd = newArray("red", "green", "blue", "cyan", "magenta", "yellow", "pink", "orange", "violet");
	colorChoicesMod = newArray("aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "blue_honolulu", "gray_modern", "green_dark_modern", "green_modern", "green_modern_accent", "green_spring_accent", "orange_modern", "pink_modern", "purple_modern", "red_n_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern");
	colorChoicesNeon = newArray("jazzberry_jam", "radical_red", "wild_watermelon", "outrageous_orange", "supernova_orange", "atomic_tangerine", "neon_carrot", "sunglow", "laser_lemon", "electric_lime", "screamin'_green", "magic_mint", "blizzard_blue", "dodger_blue", "shocking_pink", "razzle_dazzle_rose", "hot_magenta");
	colorChoicesFSU = newArray("garnet", "gold", "stadium_night", "westcott_water", "vault_garnet", "legacy_blue", "plaza_brick", "vault_gold");
	if (imageDepth == 24) {
		colorChoices = Array.concat(grayChoices, colorChoicesStd, colorChoicesMod, colorChoicesNeon, colorChoicesFSU);
		iTC = indexOfArray(colorChoices, call("ij.Prefs.get", "fancy.sliceLabels.text.color", colorChoices[0]), 0);
		iOC = indexOfArray(colorChoices, call("ij.Prefs.get", "fancy.sliceLabels.outline.color", colorChoices[1]), 1);
	} else {
		colorChoices = grayChoices;
		iTC = indexOfArray(grayChoices, call("ij.Prefs.get", "fancy.sliceLabels.text.gray", grayChoices[0]), 0);
		iOC = indexOfArray(grayChoices, call("ij.Prefs.get", "fancy.sliceLabels.outline.gray", grayChoices[1]), 1);
	}
	Dialog.addChoice("Text color:", colorChoices, colorChoices[iTC]);
	fontNameChoices = getFontChoiceList();
	Dialog.addChoice("Font name:", fontNameChoices, fontNameChoices[0]);
	Dialog.addChoice("Outline (background) color:", colorChoices, colorChoices[iOC]);
	Dialog.addNumber("Outline stroke:", outlineStrokePx, 0, 3, "pixels");
	Dialog.addCheckbox("Tweak the Formatting?", false);
	Dialog.addCheckbox("Destructive overwrite \(ignored if only renaming slices\)?", false);
	if (emptyLabelN == 0) Dialog.addCheckbox("Auto-generate all labels as a sequence only? Existing labels will not be used", false);
	else if (emptyLabelN == slices) Dialog.addCheckbox("Auto-generate all labels as a sequence only?", true);
	else Dialog.addCheckbox("Auto-generate all labels as a sequence only \(no editing options given\)?", false);
	Dialog.addCheckbox("Diagnostic mode:", false);
	Dialog.show();
	startSliceNumber = Dialog.getNumber();
	endSliceNumber = Dialog.getNumber();
	textLocChoice = Dialog.getChoice();
	call("ij.Prefs.set", "fancy.sliceLabels.location", textLocChoice);
	if (selectionExists == 1) {
		selEX = Dialog.getNumber(); /* Allows user to tweak pre-selection using dialog boxes */
		selEY = Dialog.getNumber();
		selEWidth = Dialog.getNumber();
		selEHeight = Dialog.getNumber();
		restoreSelection = Dialog.getCheckbox();
	}
	just = Dialog.getChoice();
	fontSize = Dialog.getNumber();
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
	notFancy = Dialog.getCheckbox();
	if (notFancy) fancyStyleEffectsString = "|1|1|0|0";
	call("ij.Prefs.set", "fancy.sliceLabels.fancyStyleEffects", fancyStyleEffectsString);
	/* End of checkbox group */
	textColor = Dialog.getChoice();
	if (imageDepth == 24) call("ij.Prefs.set", "fancy.sliceLabels.text.color", textColor);
	else call("ij.Prefs.set", "fancy.sliceLabels.text.gray", textColor);
	fontName = Dialog.getChoice();
	call("ij.Prefs.set", "fancy.sliceLabels.fontName", fontName);
	outlineColor = Dialog.getChoice();
	if (imageDepth == 24) call("ij.Prefs.set", "fancy.sliceLabels.outline.color", outlineColor);
	else call("ij.Prefs.set", "fancy.sliceLabels.outline.gray", outlineColor);
	outlineStrokePx = Dialog.getNumber();
	tweakFormat = Dialog.getCheckbox();
	overWrite = Dialog.getCheckbox();
	autoGenerate = Dialog.getCheckbox();
	diagnostics = Dialog.getCheckbox();
	if (!diagnostics) setBatchMode(true);
	else IJ.log("fancyStyleEffectsString: " + fancyStyleEffectsString + "\nFont Size: " + fontSize);
	setFont(fontName, fontSize);
	fontHeight = getValue("font.height");
	if (diagnostics) IJ.log("font height: " + fontHeight);
	if (noOutline) outlineStrokePx = 0;
	insideMarginsLR = imageWidth - 2 * offsetX;
	longestStringWidth = 0; /* reset longest string width for modified versions */
	if (autoGenerate) {
		Dialog.create("Label \(Autogenerated\) Options:");
		Dialog.addMessage("\"^2\" & \"um\" etc. replaced by " + fromCharCode(178) + " & " + fromCharCode(181) + "m etc. if followed by a space.");
		labelChoices = newArray("Add labels only", "Rename slices only", "Label & rename");
		// Dialog.addNumber("First slice to label:", getSliceNumber,0,4,""),
		// Dialog.addNumber("Last slice to label:", nSlices,0,4,""),
		Dialog.addChoice("Label and/or rename slices:", labelChoices, "Add labels only");
		Dialog.addString("Prefix text", "", minOf(20, maxLabelString));
		Dialog.addString("Suffix text", "", minOf(20, maxLabelString));
		Dialog.addNumber("Counter start", 0, 0, 5, "");
		Dialog.addToSameRow();
		Dialog.addNumber("Counter increment", 1, 0, 7, "");
		Dialog.addNumber("Counter label decimal places", 0, 0, 2, "");
		Dialog.addToSameRow();
		Dialog.addString("Counter separation symbols: ", "-", 3);
		countPosChoices = newArray("None", "Before prefix", "After prefix", "Before suffix", "After suffix");
		Dialog.addRadioButtonGroup("Counter position: ", countPosChoices, 1, 4, countPosChoices[0]);
		Dialog.setInsets(5, 0, 10);
		Dialog.show();
		// startSlice = Dialog.getNumber;
		// endSlice = Dialog.getNumber;
		// sliceCount = endSlice-startSlice+1;
		labelChoice = Dialog.getChoice();
		prefix = Dialog.getString;
		suffix = Dialog.getString;
		startN = Dialog.getNumber;
		addN = Dialog.getNumber;
		decP = Dialog.getNumber;
		cSep = Dialog.getString;
		countPos = Dialog.getRadioButton;
		sliceTextLabels = newArray();
		for (i = 0; i < endSliceNumber; i++) {
			if (countPos == "None") sliceTextLabels[i] = prefix + suffix;
			else {
				ctr = d2s(startN + i * addN, decP);
				if (countPos == "Before prefix") sliceTextLabels[i] = "" + ctr + cSep + prefix + suffix;
				else if (countPos == "After prefix") sliceTextLabels[i] = prefix + cSep + ctr + cSep + suffix;
				else if (countPos == "Before suffix") sliceTextLabels[i] = prefix + cSep + ctr + cSep + suffix;
				else sliceTextLabels[i] = prefix + suffix + cSep + ctr;
			}
			if (labelChoice != "Add labels only") {
				setSlice(startSliceNumber + i);
				newLabel = sliceTextLabels[i];
				/* symbols are not converted for slice names */
				run("Set Label...", "label=&newLabel");
			}
			sliceTextLabels[i] = "" + toChar(sliceTextLabels[i]); /* Use degree symbol */
			sliceTextLabels[i] = "" + cleanLabel(sliceTextLabels[i]);
			stringLength = getStringWidth(sliceTextLabels[i]);
			if (stringLength > longestStringWidth) longestStringWidth = minOf(insideMarginsLR, stringLength);
		}
	} else {
		Dialog.create("Label Text Options: " + macroL);
		sliceLabelDialogLimit = minOf(maxMenuSlices, remSlices + 1);
		Dialog.addMessage("\"^2\" & \"um\" etc. replaced by " + fromCharCode(178) + " & " + fromCharCode(181) + "m etc. if followed by a space.\nThe number of slices to be labeled is limited to " + maxMenuSlices + " by screen height.\nAdditional slices can be labeled by repeating this macro from first unlabeled slice.");
		labelChoices = newArray("Add labels only", "Rename slices only", "Label & rename");
		Dialog.addChoice("Label and/or rename slices:", labelChoices, "Add labels only");
		Dialog.addString("Prefix text", "", minOf(20, maxLabelString));
		Dialog.addString("Suffix text", "", minOf(20, maxLabelString));
		Dialog.addNumber("Counter start", 0, 0, 5, "");
		Dialog.addToSameRow();
		Dialog.addNumber("Counter increment", 1, 0, 7, "");
		Dialog.addNumber("Counter label decimal places", 0, 0, 2, "");
		Dialog.addToSameRow();
		Dialog.addString("Counter separation symbols: ", "-", 3);
		countPosChoices = newArray("None", "Before prefix", "After prefix", "Before suffix", "After suffix");
		Dialog.addRadioButtonGroup("Counter position: ", countPosChoices, 1, 4, countPosChoices[0]);
		if (maxLabelString > 0) {
			Dialog.addString("Replace this label text:", "", minOf(20, maxLabelString));
			Dialog.addString(" . . . with \(escape regEx characters\):", "", minOf(20, maxLabelString));
		}
		Dialog.setInsets(5, 0, 10);
		for (i = 0; i < (minOf(endSliceNumber, sliceLabelDialogLimit)); i++)
			Dialog.addString("Slice No. " + (i + startSliceNumber) + " input label:", allSliceLabels[i + startSliceNumber - 1], minOf(100, maxLabelString));
		Dialog.show();
		labelChoice = Dialog.getChoice();
		prefix = Dialog.getString;
		suffix = Dialog.getString;
		startN = Dialog.getNumber;
		addN = Dialog.getNumber;
		decP = Dialog.getNumber;
		cSep = Dialog.getString;
		countPos = Dialog.getRadioButton;
		replaceString = false;
		if (maxLabelString > 0) {
			oldString = Dialog.getString;
			newString = Dialog.getString;
			if (lengthOf(oldString) > 0) replaceString = true;
		}
		sliceTextLabels = newArray();
		longestStringWidth = 0; /* reset longest string width for modified versions */
		for (i = 0; i < (minOf(endSliceNumber, sliceLabelDialogLimit)); i++) {
			sLabel = Dialog.getString();
			if (replaceString) {
				sLabel = replace(sLabel, oldString, newString);
			}
			if (countPos == "None") sliceTextLabels[i] = prefix + sLabel + suffix;
			else {
				ctr = d2s(startN + i * addN, decP);
				if (countPos == "Before prefix") sliceTextLabels[i] = "" + ctr + cSep + prefix + sLabel + suffix;
				else if (countPos == "After prefix") sliceTextLabels[i] = prefix + cSep + ctr + cSep + sLabel + suffix;
				else if (countPos == "Before suffix") sliceTextLabels[i] = prefix + sLabel + cSep + ctr + cSep + suffix;
				else sliceTextLabels[i] = prefix + sLabel + suffix + cSep + ctr;
			}
			if (labelChoice != "Add labels only") {
				setSlice(startSliceNumber + i);
				newLabel = sliceTextLabels[i];
				/* symbols are not converted for slice names */
				run("Set Label...", "label=&newLabel");
			}
			sliceTextLabels[i] = "" + toChar(sliceTextLabels[i]); /* Use degree symbol */
			sliceTextLabels[i] = "" + cleanLabel(sliceTextLabels[i]);
			stringLength = getStringWidth(sliceTextLabels[i]);
			if (stringLength > longestStringWidth) longestStringWidth = stringLength;
		}
	}
	/* End of options dialog */
	/* Begin labeling of slices */
	if (labelChoice != "Rename slices only") {
		if (tweakFormat && (!noShadow && !noOutline)) {
			Dialog.create("Advanced Formatting Options");
			if (!notOutline) {
				Dialog.addNumber("Outline stroke:", outlineStrokePx, 0, 3, "pixels");
				Dialog.addChoice("Outline (background) color:", colorChoices, colorChoices[1]);
			}
			if (!noShadow) {
				Dialog.addNumber("Shadow Drop: ?", shadowDrop, 0, 3, "% of font size");
				Dialog.addNumber("Shadow Displacement Right: ?", shadowDrop, 0, 3, "% of font size");
				Dialog.addNumber("Shadow Gaussian blur:", floor(0.4 * shadowDrop), 0, 3, "% of font size");
				Dialog.addNumber("Shadow Darkness:", 100, 0, 3, "%\(darkest = 100%\)");
			}
			Dialog.show();
			if (!notOutline) {
				outlineStrokePx = Dialog.getNumber();
				outlineColor = Dialog.getChoice();
			}
			if (!noShadow) {
				shadowDrop = Dialog.getNumber();
				shadowDisp = Dialog.getNumber();
				shadowBlur = Dialog.getNumber();
				shadowDarkness = Dialog.getNumber();
			}
		}
		textColorArray = getColorArrayFromColorName(textColor);
		Array.getStatistics(textColorArray, fontIntMean);
		fontInt = floor(fontIntMean);
		outlineColorArray = getColorArrayFromColorName(outlineColor);
		Array.getStatistics(outlineColorArray, outlineIntMean);
		outlineInt = floor(outlineIntMean);
		negAdj = 0.5; /* negative offsets appear exaggerated at full displacement */
		if (!noShadow) {
			if (shadowDrop < 0) shadowDrop *= negAdj;
			if (shadowDisp < 0) shadowDisp *= negAdj;
			if (shadowBlur < 0) shadowBlur *= negAdj;
		}
		fontFactor = fontSize / 100;
		if (outlineStrokePx != 0) outlineStrokePx = maxOf(1, round(fontFactor * outlineStrokePx)); /* if some outline is desired set to at least one pixel */
		if (!noShadow) {
			shadowDrop = round(fontFactor * shadowDrop);
			shadowDisp = round(fontFactor * shadowDisp);
			shadowBlur = round(fontFactor * shadowBlur);
			if (offsetX < (shadowDisp + shadowBlur + 1)) offsetX = (shadowDisp + shadowBlur + 1); /* make sure shadow does not run off edge of image */
			if (offsetY < (shadowDrop + shadowBlur + 1)) offsetY = (shadowDrop + shadowBlur + 1);
		}
		if (textLocChoice == "Top Left") {
			selEX = offsetX;
			selEY = offsetY;
			if (just == "auto") just = "left";
		} else if (textLocChoice == "Top Right") {
			selEX = imageWidth - longestStringWidth - offsetX;
			selEY = offsetY;
			if (just == "auto") just = "right";
		} else if (textLocChoice == "Top Center") {
			selEX = round((imageWidth - longestStringWidth) / 2);
			selEY = offsetY;
			if (just == "auto") just = "center";
		} else if (textLocChoice == "Center") {
			selEX = round((imageWidth - longestStringWidth) / 2);
			selEY = round(imageHeight / 2 + fontHeight);
			if (just == "auto") just = "center";
		} else if (textLocChoice == "Bottom Left") {
			selEX = offsetX;
			selEY = imageHeight - offsetY;
			if (just == "auto") just = "left";
		} else if (textLocChoice == "Bottom Right") {
			selEX = imageWidth - longestStringWidth - offsetX;
			selEY = imageHeight - offsetY;
			if (just == "auto") just = "right";
		} else if (textLocChoice == "Bottom Center") {
			selEX = round((imageWidth - longestStringWidth) / 2);
			selEY = imageHeight - offsetY;
			if (just == "auto") just = "center";
		} else if (textLocChoice == "Center of New Selection") {
			if (is("Batch Mode") == true) setBatchMode(false); /* Does not accept interaction while batch mode is on */
			setTool("rectangle");
			msgtitle = "Location for the text labels...";
			msg = "Draw a box in the image where you want to center the text labels...";
			waitForUser(msgtitle, msg);
			getSelectionBounds(orSelEX, orSelEY, orSelEWidth, orSelEHeight); /* this set for restore */
			restoreSelection = getBoolean("Restore this selection at the end of the macro?");
			if (is("Batch Mode") == false) setBatchMode(true); /* toggle batch mode back on */
			getSelectionBounds(selEX, selEY, selEWidth, selEHeight); /* this set to change */
		}
		if (endsWith(textLocChoice, "election")) {
			shrinkX = minOf(1, selEWidth / longestStringWidth);
			shrinkY = minOf(1, selEHeight / fontHeight);
			shrinkF = minOf(shrinkX, shrinkY);
			shrunkFont = shrinkF * fontSize;
			if (shrinkF < 1) {
				Dialog.create("Shrink Text");
				Dialog.addCheckbox("Text will not fit inside selection; Reduce font size from " + fontSize + "?", true);
				Dialog.addNumber("Choose new font size; font size for fit =", round(shrunkFont));
				Dialog.show;
				reduceFontSize = Dialog.getCheckbox();
				shrunkFont = Dialog.getNumber();
				shrinkF = shrunkFont / fontSize;
			} else reduceFontSize = false;
			if (reduceFontSize == true) {
				fontSize = shrunkFont;
				setFont("", shrunkFont, "");
				fontHeight = getValue("font.height");
				linesSpace = shrinkF * linesSpace;
				longestStringWidth = shrinkF * longestStringWidth;
				fontFactor = fontSize / 100;
				if (outlineStrokePx > 1) outlineStrokePx = maxOf(1, round(fontFactor * outlineStrokePx));
				else if (outlineStrokePx > 0) outlineStrokePx = round(fontFactor * outlineStrokePx);
				if (!noShadow) {
					if (shadowDrop > 1) shadowDrop = maxOf(1, round(fontFactor * shadowDrop));
					else shadowDrop = round(fontFactor * shadowDrop);
					if (shadowDisp > 1) shadowDisp = maxOf(1, round(fontFactor * shadowDisp));
					else shadowDisp = round(fontFactor * shadowDisp);
					if (shadowBlur > 1) shadowBlur = maxOf(1, round(fontFactor * shadowBlur));
					else shadowBlur = round(fontFactor * shadowBlur);
				}
			}
			selEX += round((selEWidth / 2) - longestStringWidth / 2);
			selEY += round((selEHeight / 2) + fontHeight);
			if (just == "auto") {
				if (selEX < imageWidth * 0.4) just = "left";
				else if (selEX > imageWidth * 0.6) just = "right";
				else just = "center";
			}
		}
		run("Select None");
		if (selEY <= 1.5 * fontHeight)
			selEY += fontHeight;
		selEX = maxOf(selEX, offsetX);
		endX = selEX + longestStringWidth;
		if ((endX + offsetX) > imageWidth) selEX = imageWidth - longestStringWidth - offsetX;
		roiManager("show none");
		if (!overWrite) {
			if (nSlices == 1) run("Duplicate...", "title=" + getTitle() + "+text");
			else run("Duplicate...", "title=" + getTitle() + "+text duplicate");
		}
		workingImage = getTitle();
		workingImageName = getInfo("window.title");
		outlineColorRGBs = getColorArrayFromColorName(outlineColor);
		textColorRGBs = getColorArrayFromColorName(textColor);
		for (i = 0; i < lengthOf(sliceTextLabels); i++) {
			stringWidth = getStringWidth(sliceTextLabels[i]);
			overRun = stringWidth / insideMarginsLR;
			if (overRun > 1) fontSize /= overRun;
			stringWidth = getStringWidth(sliceTextLabels[i]);
			textLabelX = selEX;
			textLabelY = selEY;
			setSlice(startSliceNumber + i);
			if (sliceTextLabels[i] != "") {
				if (notFancy) writeLabel7(fontName, fontSize, textColor, sliceTextLabels[i], textLabelX, textLabelY, true);
				else {
					/* Create Label Mask */
					newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
					roiManager("deselect");
					run("Select None");
					if (sliceTextLabels[i] != "-blank-") {
						if (just == "right") textLabelX += longestStringWidth - stringWidth;
						else if (just != "left") textLabelX += (longestStringWidth - getStringWidth(sliceTextLabels[i])) / 2;
						if (indexOf(textLocChoice, "Center") > 0) selEX = textLabelX = round((imageWidth - stringWidth) / 2);
						else if (indexOf(textLocChoice, "Left") > 0) textLabelX = offsetX;
						else if (indexOf(textLocChoice, "Right") > 0 && (just == "right" || just == "auto")) textLabelX = imageWidth - (stringWidth + offsetX);
						writeLabel7(fontName, fontSize, "white", sliceTextLabels[i], textLabelX, textLabelY, false);
					}
					selectWindow("label_mask");
					setThreshold(0, 128);
					setOption("BlackBackground", false);
					run("Convert to Mask");
					run("Select None");
					// selectWindow("label_mask");
					/* Create drop shadow if desired */
					if (!noShadow) {
						if (shadowDrop != 0 || shadowDisp != 0 || shadowBlur != 0) {
							showStatus("Creating drop shadow for labels . . . ");
							createShadowDropFromMask7Safe("label_mask", shadowDrop, shadowDisp, shadowBlur, shadowDarkness, outlineStrokePx);
							if (isOpen("shadow") && (shadowDarkness > 0))
								imageCalculator("Subtract", workingImage, "shadow");
							else if (isOpen("shadow") && (shadowDarkness < 0))
								imageCalculator("Add", workingImage, "shadow");
							run("Select None");
						}
					}
					/* Create outline around text */
					if (outlineStrokePx > 0) {
						selectWindow(workingImage);
						getSelectionFromMask("label_mask");
						run("Enlarge...", "enlarge=&outlineStrokePx pixel");
						safeColornameFillClear(outlineColor);
						run("Enlarge...", "enlarge=1 pixel");
						run("Gaussian Blur...", "sigma=0.85");
						run("Convolve...", "text1=[-0.0556 -0.0556 -0.0556 \n-0.0556 1.4448  -0.0556 \n-0.0556 -0.0556 -0.0556]"); /* moderate sharpen */
						run("Select None");
					}
					/* Create text */
					if (sliceTextLabels[i] == "-blank-") {
						getSelectionFromMask("label_mask");
						safeColornameFillClear(textColor);
						run("Select None");
					} else writeLabel7(fontName, fontSize, textColor, sliceTextLabels[i], textLabelX, textLabelY, true); /* Now restore antialiased text */
					getSelectionFromMask("label_mask");
					run("Enlarge...", "enlarge=1 pixel");
					run("Gaussian Blur...", "sigma=0.75");
					run("Unsharp Mask...", "radius=1 mask=0.75");
					if (raised || recessed) {
						outlineRGBs = getColorArrayFromColorName(outlineColor);
						Array.getStatistics(outlineRGBs, null, null, outlineColorMean, null);
						textRGBs = getColorArrayFromColorName(textColor);
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
					closeImageByTitle("shadow");
					closeImageByTitle("label_mask");
				}
			}
		}
		selectWindow(workingImage);
		if (startsWith(overWrite, "New")) {
			suffixLoc = lastIndexOf(workingImageName, ".");
			if (suffixLoc > 0) workingImageNameWOExt = unCleanLabel(substring(workingImageName, 0, suffixLoc));
			else workingImageNameWOExt = unCleanLabel(workingImage);
			rename(workingImageNameWOExt + "+text");
		}
	}
	restoreSettings;
	setBatchMode("exit & display");
	if (endsWith(textLocChoice, "election") && (restoreSelection == true)) makeRectangle(orSelEX, orSelEY, orSelEWidth, orSelEHeight);
	else run("Select None");
	setSlice(startSliceNumber);
	showStatus("Fancy Text Labels Finished");
	call("java.lang.System.gc");
}
	/*
		( 8(|)	( 8(|)	All ASC Functions	@@@@@:-)	@@@@@:-)
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
		/* v181002: reselects original image at end if open
		   v200925: uses "while" instead of if so it can also remove duplicates
		   v230411:	checks to see if any images open first.
		*/
		if(nImages>0){
			oIID = getImageID();
			while (isOpen(windowTitle)) {
				selectWindow(windowTitle);
				close();
			}
			if (isOpen(oIID)) selectImage(oIID);
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
		if (oStroke>0) run("Enlarge...", "enlarge=" + oStroke + " pixel"); /* Adjust shadow size so that shadow extends beyond stroke thickness */
		run("Clear");
		run("Select None");
		if (oShadowBlur>0) {
			run("Gaussian Blur...", "sigma=" + oShadowBlur);
			run("Unsharp Mask...", "radius=" + oShadowBlur + " mask=0.4"); /* Make Gaussian shadow edge a little less fuzzy */
		}
		/* Now make sure shadow or glow does not impact outline */
		getSelectionFromMask(mask);
		if (oStroke>0) run("Enlarge...", "enlarge=" + oStroke + " pixel");
		Color.setBackground("black");
		run("Clear");
		run("Select None");
		/* The following are needed for different bit depths */
		if (imageDepth==16 || imageDepth==32) run(imageDepth + "-bit");
		run("Enhance Contrast...", "saturated=0 normalize");
		divider = (100 / abs(oShadowDarkness));
		run("Divide...", "value=" + divider);
		Color.setBackground(orBG);
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
	/* Hex conversion below adapted from T.Ferreira, 20010.01 https://imagej.net/doku.php?id=macro:rgbtohex */
	function getHexColorFromColorName(colorNameString) {
		/* v231207: Uses IJ String.pad instead of function: pad */
		colorArray = getColorArrayFromColorName(colorNameString);
		 r = toHex(colorArray[0]); g = toHex(colorArray[1]); b = toHex(colorArray[2]);
		 hexName= "#" + "" + String.pad(r, 2) + "" + String.pad(g, 2) + "" + String.pad(b, 2);
		 return hexName;
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
			v230919 You can add a list of fonts that do not produce good results with the macro. 230921 more exclusions. v240306: Restored SansSerif.
		*/
		systemFonts = getFontList();
		IJFonts = newArray("SansSerif", "Serif", "Monospaced");
		fontNameChoices = Array.concat(IJFonts, systemFonts);
		blackFonts = Array.filter(fontNameChoices, "([A-Za-z] + .*[bB]l.*k)");
		eBFonts = Array.filter(fontNameChoices, "([A-Za-z] + .*[Ee]xtra.*[Bb]old)");
		uBFonts = Array.filter(fontNameChoices, "([A-Za-z] + .*[Uu]ltra.*[Bb]old)");
		fontNameChoices = Array.concat(blackFonts, eBFonts, uBFonts, fontNameChoices); /* 'Black' and Extra and Extra Bold fonts work best */
		faveFontList = newArray("Your favorite fonts here", "Arial Black", "Myriad Pro Black", "Myriad Pro Black Cond", "Noto Sans Blk", "Noto Sans Disp Cond Blk", "Open Sans ExtraBold", "Roboto Black", "Alegreya Black", "Alegreya Sans Black", "Tahoma Bold", "Calibri Bold", "Helvetica", "SansSerif", "Calibri", "Roboto", "Tahoma", "Times New Roman Bold", "Times Bold", "Goldman Sans Black", "Goldman Sans", "SansSerif", "Serif");
		/* Some fonts or font families don't work well with ASC macros, typically they do not support all useful symbols, they can be excluded here using the .* regular expression */
		offFontList = newArray("Alegreya SC Black", "Archivo.*", "Arial Rounded.*", "Bodon.*", "Cooper.*", "Eras.*", "Fira.*", "Gill Sans.*", "Lato.*", "Libre.*", "Lucida.*", "Merriweather.*", "Montserrat.*", "Nunito.*", "Olympia.*", "Poppins.*", "Rockwell.*", "Tw Cen.*", "Wingdings.*", "ZWAdobe.*"); /* These don't work so well. Use a ".*" to remove families */
		faveFontListCheck = newArray(faveFontList.length);
		for (i=0, counter=0; i<faveFontList.length; i++) {
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
				if (endsWith(offFontList[j], ".*")){
					if (startsWith(fontNameChoices[i], substring(offFontList[j], 0, indexOf(offFontList[j], ".*")))){
						fontNameChoices = Array.deleteIndex(fontNameChoices, i);
						i = maxOf(0, i-1);
					}
					// fontNameChoices = Array.filter(fontNameChoices, "(^" + offFontList[j] + ")"); /* RegEx not working and very slow */
				}
			}
		}
		fontNameChoices = Array.concat(faveFontListCheck, fontNameChoices);
		for (i=0; i<fontNameChoices.length; i++) {
			for (j=i + 1; j<fontNameChoices.length; j++)
				if (fontNameChoices[i]==fontNameChoices[j]) fontNameChoices = Array.deleteIndex(fontNameChoices, j);
		}
		return fontNameChoices;
	}
	function getSelectionFromMask(sel_M){
		/* v220920 only inverts if full image selection */
		batchMode = is("Batch Mode"); /* Store batch status mode before toggling */
		if (!batchMode) setBatchMode(true); /* Toggle batch mode on if previously off */
		tempID = getImageID();
		selectWindow(sel_M);
		run("Create Selection"); /* Selection inverted perhaps because the mask has an inverted LUT? */
		getSelectionBounds(gSelX, gSelY, gWidth, gHeight);
		if(gSelX==0 && gSelY==0 && gWidth==Image.width && gHeight==Image.height)	run("Make Inverse");
		run("Select None");
		selectImage(tempID);
		run("Restore Selection");
		if (!batchMode) setBatchMode(false); /* Return to original batch mode setting */
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
	function restoreExit(message){ /* v220316
		NOTE: REQUIRES previous run of saveSettings	*/
		restoreSettings(); /* Restore previous settings before exiting */
		setBatchMode("exit & display"); /* Probably not necessary if exiting gracefully but otherwise harmless */
		call("java.lang.System.gc");
		if (message!="") exit(message);
		else exit;
	}
	function safeColornameFillClear(colorName) {
	/* Requires function getColorArrayFromColorName
		v230418 1st version pjl */
		if(selectionType>=0){
			orBGC = getValue("color.background");
			colorArray = getColorArrayFromColorName(colorName);
			setBackgroundColor(colorArray[0], colorArray[1], colorArray[2]);
			run("Clear", "slice");
			setBackgroundColor(orBGC);
		}
	}
	function toChar(string) {
		/* v180612 first version
			v1v180627 Expanded, v200428 removed "symbol" prefi
			v210316 only replaces text if followed by a space, fixes "pi" in pixel etc.  */
		string= replace(string,"Angstrom ", fromCharCode(0x212B)+" "); /* ANGSTROM SIGN */
		string= replace(string,"alpha ", fromCharCode(0x03B1)+" ");
		string= replace(string,"Alpha ", fromCharCode(0x0391)+" ");
		string= replace(string,"beta ", fromCharCode(0x03B2)+" "); /* Lower case beta */
		string= replace(string,"Beta ", fromCharCode(0x0392)+" "); /* ß CAPITAL */
		string= replace(string,"gamma ", fromCharCode(0x03B3)+" "); /* MATHEMATICAL SMALL GAMMA */
		string= replace(string,"Gamma ", fromCharCode(0xD835)+" "); /* MATHEMATICAL BOLD CAPITAL  GAMMA */
		string= replace(string,"delta ", fromCharCode(0x1E9F)+" "); /*  SMALL LETTER DELTA */
		string= replace(string,"Delta ", fromCharCode(0x0394)+" "); /*  CAPITAL LETTER DELTA */
		string= replace(string,"epsilon ", fromCharCode(0x03B5)+" "); /* GREEK SMALL LETTER EPSILON */
		string= replace(string,"Epsilon ", fromCharCode(0x0395)+" "); /* GREEK CAPITAL LETTER EPSILON */
		string= replace(string,"zeta ", fromCharCode(0x03B6)+" "); /* GREEK SMALL LETTER ZETA */
		string= replace(string,"Zeta ", fromCharCode(0x0396)+" "); /* GREEK CAPITAL LETTER ZETA */
		string= replace(string,"theta ", fromCharCode(0x03B8)+" "); /* GREEK SMALL LETTER THETA */
		string= replace(string,"Theta ", fromCharCode(0x0398)+" "); /* GREEK CAPITAL LETTER THETA */
		string= replace(string,"iota ", fromCharCode(0x03B9)+" "); /* GREEK SMALL LETTER IOTA */
		string= replace(string,"Iota ", fromCharCode(0x0196)+" "); /* GREEK CAPITAL LETTER IOTA */
		string= replace(string,"kappa ", fromCharCode(0x03BA)+" "); /* GREEK SMALL LETTER KAPPA */
		string= replace(string,"Kappa ", fromCharCode(0x0196)+" "); /* GREEK CAPITAL LETTER KAPPA */
		string= replace(string,"lambda ", fromCharCode(0x03BB)+" "); /* GREEK SMALL LETTER LAMDA */
		string= replace(string,"Lambda ", fromCharCode(0x039B)+" "); /* GREEK CAPITAL LETTER LAMDA */
		string= replace(string,"mu ", fromCharCode(0x03BC)+" "); /* µ GREEK SMALL LETTER MU */
		string= replace(string,"Mu ", fromCharCode(0x039C)+" "); /* GREEK CAPITAL LETTER MU */
		string= replace(string,"nu ", fromCharCode(0x03BD)+" "); /*  GREEK SMALL LETTER NU */
		string= replace(string,"Nu ", fromCharCode( 0x039D)+" "); /*  GREEK CAPITAL LETTER NU */
		string= replace(string,"xi ", fromCharCode(0x03BE)+" "); /* GREEK SMALL LETTER XI */
		string= replace(string,"Xi ", fromCharCode(0x039E)+" "); /* GREEK CAPITAL LETTER XI */
		string= replace(string,"pi ", fromCharCode(0x03C0)+" "); /* GREEK SMALL LETTER Pl */
		string= replace(string,"Pi ", fromCharCode(0x03A0)+" "); /* GREEK CAPITAL LETTER Pl */
		string= replace(string,"rho ", fromCharCode(0x03C1)+" "); /* GREEK SMALL LETTER RHO */
		string= replace(string,"Rho ", fromCharCode(0x03A1)+" "); /* GREEK CAPITAL LETTER RHO */
		string= replace(string,"sigma ", fromCharCode(0x03C3)+" "); /* GREEK SMALL LETTER SIGMA */
		string= replace(string,"Sigma ", fromCharCode(0x03A3)+" "); /* GREEK CAPITAL LETTER SIGMA */
		string= replace(string,"phi ", fromCharCode(0x03C6)+" "); /* GREEK SMALL LETTER PHI */
		string= replace(string,"Phi ", fromCharCode(0x03A6)+" "); /* GREEK CAPITAL LETTER PHI */
		string= replace(string,"omega ", fromCharCode(0x03C9)+" "); /* GREEK SMALL LETTER OMEGA */
		string= replace(string,"Omega ", fromCharCode(0x03A9)+" "); /* GREEK CAPITAL LETTER OMEGA */
		string= replace(string,"eta ", fromCharCode(0x03B7)+" "); /*  GREEK SMALL LETTER ETA */
		string= replace(string,"Eta ", fromCharCode(0x0397)+" "); /*  GREEK CAPITAL LETTER ETA */
		string= replace(string,"sub2 ", fromCharCode(0x2082)+" "); /*  subscript 2 */
		string= replace(string,"sub3 ", fromCharCode(0x2083)+" "); /*  subscript 3 */
		string= replace(string,"sub4 ", fromCharCode(0x2084)+" "); /*  subscript 4 */
		string= replace(string,"sub5 ", fromCharCode(0x2085)+" "); /*  subscript 5 */
		string= replace(string,"sup2 ", fromCharCode(0x00B2)+" "); /*  superscript 2 */
		string= replace(string,"sup3 ", fromCharCode(0x00B3)+" "); /*  superscript 3 */
		string= replace(string,">= ", fromCharCode(0x2265)+" "); /* GREATER-THAN OR EQUAL TO */
		string= replace(string,"<= ", fromCharCode(0x2264)+" "); /* LESS-THAN OR EQUAL TO */
		string= replace(string,"xx ", fromCharCode(0x00D7)+" "); /* MULTIPLICATION SIGN */
		string= replace(string,"copyright ", fromCharCode(0x00A9)+" "); /* © */
		string= replace(string,"ro ", fromCharCode(0x00AE)+" "); /* registered sign */
		string= replace(string,"tm ", fromCharCode(0x2122)+" "); /* ™ */
		string= replace(string,"parallelto ", fromCharCode(0x2225)+" "); /* PARALLEL TO  note CANNOT use "|" key */
		// string= replace(string,"perpendicularto ", fromCharCode(0x27C2)+" "); /* PERPENDICULAR note CANNOT use "|" key */
		string= replace(string,"degree ", fromCharCode(0x00B0)+" "); /* Degree */
		string= replace(string, "degreeC ", fromCharCode(0x00B0)+fromCharCode(0x2009) + "C"); /* Degree C */
		string= replace(string, "arrow-up ", fromCharCode(0x21E7)+" "); /* 'UPWARDS WHITE ARROW */
		string= replace(string, "arrow-down ", fromCharCode(0x21E9)+" "); /* 'DOWNWARDS WHITE ARROW */
		string= replace(string, "arrow-left ", fromCharCode(0x21E6)+" "); /* 'LEFTWARDS WHITE ARROW */
		string= replace(string, "arrow-right ", fromCharCode(0x21E8)+" "); /* 'RIGHTWARDS WHITE ARROW */
		return string;
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
		string = string.replace(fromCharCode(0x2009), "_"); /* Replace thin spaces */
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