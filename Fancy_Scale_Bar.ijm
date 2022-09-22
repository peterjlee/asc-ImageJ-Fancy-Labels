macro "Fancy Scale Bar" {
/* Original code by Wayne Rasband, improved by Frank Sprenger and deposited on the ImageJ mailing server: (http:imagej.588099.n2.nabble.com/Overlay-Scalebar-Plugins-td6380378.html#a6394996). KS added choice of font size, scale bar height, + any position for scale bar and some options that allow to set the image calibration (only for overlay, not in Meta data). Kees Straatman, CBS, University of Leicester, May 2011
	Grotesquely modified by Peter J. Lee NHMFL to produce shadow and outline effects.
	v211203: Simple format is now an option in all cases.
	v220304: Simple format now uses chosen colors for more flexibility.
	v220510: Checks to make sure default text color is not the same as the background for simple format f2: updated pad function f3: updated colors
	v220711: Added dialog info showing more precise lengths for non-line selections.
	v220726: Fixes anti-aliasing issue and adds a transparent text option.
	v220808-10: Minor tweaks to inner shadow and font size v220810_f1 updates CZ scale functions only f2: updated colors f3: Updated checkForPlugins function
	v220823: Gray choices for graychoices only. Corrected gray index formulae.
	v220916: Uses imageIDs instead of titles to avoid issues with duplicate image titles. Overlay outlines restored.
	v220920: Allows use of just text for labeling arrows if a line selection is used. Arrow width corrected.
	v220921: Overlay issues with new version of getSelectionFromMask function fixed v220921b: Allows rotation of label text if line selected
*/
	macroL = "Fancy_Scale_Bar_v220921b.ijm";
	requires("1.52i"); /* Utilizes Overlay.setPosition(0) from IJ >1.52i */
	saveSettings(); /* To restore settings at the end */
	micron = getInfo("micrometer.abbreviation");
	if(is("Inverting LUT")) run("Invert LUT"); /* more effectively removes Inverting LUT */
	selEType = selectionType;
	if (selEType>=0) {
		getSelectionBounds(selEX, selEY, selEWidth, selEHeight);
		if ((selEWidth + selEHeight)<6) selEType=-1; /* Ignore junk selections that are suspiciously small */
		if (selEType==5) getSelectionCoordinates(selLX, selLY);
	}
	run("Select None");
	activeImage = getTitle();
	activeImageID = getImageID();
	imageDepth = bitDepth();
	checkForUnits();
	getDimensions(imageWidth, imageHeight, channels, slices, frames);
	overlayN = Overlay.size;
	medianBGIs = guessBGMedianIntensity();
	medianBGI = round((medianBGIs[0]+medianBGIs[1]+medianBGIs[2])/3);
	bgI = maxOf(0,medianBGI);
	if (imageDepth==8 || imageDepth==24) bgIpc = round(bgI*100/255);
	else if (imageDepth==16) bgIpc = round(bgI*100/65536);
	if (bgIpc<3 || bgIpc>97) sText = true;
	else sText = false;
	/* End simple text default options */
	startSliceNumber = getSliceNumber();
	remSlices = slices-startSliceNumber;
	if (selEType==5) sbFontSize = maxOf(10, round((imageHeight+imageWidth)/90)); /* set minimum default font size as 12 */
	else sbFontSize = maxOf(12, round((imageHeight+imageWidth)/60)); /* set minimum default font size as 12 */
	getVoxelSize(pixelWidth, pixelHeight, pixelDepth, selectedUnit);
	if (selectedUnit == "um") selectedUnit = micron;
	sF = getScaleFactor(selectedUnit);
	micronS = getInfo("micrometer.abbreviation");
	lcf=(pixelWidth+pixelHeight)/2;
	lcfFactor=1/lcf;
	dOutS = 5; /* default outline stroke: % of font size */
	dShO = 7;  /* default outer shadow drop: % of font size */
	dIShO = 4; /* default inner shadow drop: % of font size */
	/* set default tweaks */
	outlineStroke = dOutS;
	shadowDrop = dShO;
	shadowDisp = dShO;
	shadowBlur = floor(0.75*dShO);
	shadowDarkness = 30;
	innerShadowDrop = dIShO;
	innerShadowDisp = dIShO;
	innerShadowBlur = floor(dIShO/2);
	innerShadowDarkness = 20;
	textLabel = "";
	rotText = false;
	diagnostic = false;
	if (sF!=0) {
		nSF = newArray(1,sF/(1E-2),sF/(1E-3),sF/(1E-6),sF/(1E-6),sF/(1E-9),sF/(1E-10),sF/(1E-12), sF/(2.54E-2), sF/(1E-4));
		overrideUnitChoice = newArray(selectedUnit, "cm", "mm", micronS, "microns", "nm", "Å", "pm", "inches", "human hairs");
	}
	if (selEType>=0) {
		if (selEType!=5){
			sbWidth = lcf*selEWidth;
			sbDP = autoCalculateDecPlacesFromValueOnly(sbWidth);
			sbPreciseWidth = d2s(sbWidth, sbDP+3);
			sbWidth = d2s(sbWidth, sbDP);
		}
		else {
			lineXPx = abs(selLX[1]-selLX[0]); /* used for label offsets later */
			lineYPx = abs(selLY[1]-selLY[0]); /* used for label offsets later */
			lineLength = sqrt(pow(lineXPx,2) + pow(lineYPx,2));
			sbWidth = lcf*lineLength;
			sbDP = autoCalculateDecPlacesFromValueOnly(sbWidth)+2; /* Add more dp for line labeling */
			sbPreciseWidth = d2s(sbWidth, sbDP+3);
			sbWidth = d2s(sbWidth, sbDP);
			lineAngle = Math.toDegrees(atan2(selLY[1]-selLY[0], selLX[1]-selLX[0]));
			if (abs(lineAngle)>0.01) rotText = true;
			lineXPx = abs(selLX[1]-selLX[0]);
			lineYPx = abs(selLY[1]-selLY[0]);
			lineMidX = (selLX[0] + selLX[1])/2;
			lineMidY = (selLY[0] + selLY[1])/2;
		}
	}
	else sbWidth = lcf*imageWidth/5;
	selOffsetX = maxOf(dOutS,round(imageWidth/120));
	selOffsetY = maxOf(dOutS,round(maxOf(imageHeight/180, 0.35*sbFontSize)));
	run("Set Scale...", "distance=&lcfFactor known=1 pixel=1 selectedUnit=&selectedUnit");
	indexSBWidth = parseInt(substring(d2s(sbWidth, -1),indexOf(d2s(sbWidth, -1), "E")+1));
	dpSB = maxOf(0,1 - indexSBWidth);
	sbWidth1SF = round(sbWidth/pow(10,indexSBWidth));
	sbWidth2SF = round(sbWidth/pow(10,indexSBWidth-1));
	preferredSBW = newArray(10,20,25,50,75); /* Edit this list to your preferred 2 digit numbers */
	sbWidth2SFC = closestValueFromArray(preferredSBW,sbWidth2SF,100); /* alternatively could be sbWidth1SF*10 */
	if (selEType!=5) sbWidth = pow(10,indexSBWidth-1)*sbWidth2SFC;
	fScaleBarOverlays = countOverlaysByName("cale");
	Dialog.create("Scale Bar Parameters: " + macroL);
		if (selEType==5){
			Dialog.addNumber("Selected line length \(" + d2s(lineLength,1) + " pixels\):", sbWidth, dpSB+2, 10, selectedUnit);
			Dialog.addNumber("Selected line angle \(" + fromCharCode(0x00B0) + " from horizontal\):", lineAngle, 2, 5, fromCharCode(0x00B0));
			Dialog.addString("Length/angle separator:", "No angle label",10);
			Dialog.addString("Insert text here for text only", textLabel,20);
			Dialog.addCheckbox("Rotate text " + lineAngle + fromCharCode(0x00B0) + "?", rotText);
			Dialog.setInsets(-130, 370, 0);
			Dialog.addMessage("Length labeling mode:\nSelect none or a non-\nstraight-line selection\nto draw a scale bar",13,"#782F40");
			modeStr = "length line";
		} else {
			Dialog.addMessage("Scale bar mode: Use the straight line selection tool for length labeling",12,"#099FFF");
			dText = "Length of scale bar";
			if (selEType>=0) dText += "\(precise length = " + sbPreciseWidth + "\)";
			Dialog.addNumber(dText + ":", sbWidth, dpSB, 10, selectedUnit);
			modeStr = "scale bar";
		}
		if (sF!=0) {
			newUnit = newArray(""+selectedUnit+" Length x1", "cm \(Length x"+nSF[1]+"\)","mm \(Length x"+nSF[2]+"\)",micronS+" \(Length x"+nSF[3]+"\)","microns \(Length x"+nSF[4]+"\)", "nm \(Length x"+nSF[5]+"\)", "Å \(Length x"+nSF[6]+"\)", "pm \(Length x"+nSF[7]+"\)", "inches \(Length x"+nSF[8]+"\)", "human hair \(Length x"+nSF[9]+"\)");
			Dialog.addChoice("Override unit with new choice?", newUnit, newUnit[0]);
		}
		Dialog.addNumber("Font size \(\"FS\"\):", sbFontSize, 0, 4,"");
		Dialog.addNumber("Thickness of " + modeStr + " :",19,0,3,"% of font size");
		grayChoices = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray");
		colorChoicesStd = newArray("red", "green", "blue", "cyan", "magenta", "yellow", "pink", "orange", "violet");
		colorChoicesMod = newArray("garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "blue_honolulu", "gray_modern", "green_dark_modern", "green_modern", "green_modern_accent", "green_spring_accent", "orange_modern", "pink_modern", "purple_modern", "red_n_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern");
		colorChoicesNeon = newArray("jazzberry_jam", "radical_red", "wild_watermelon", "outrageous_orange", "supernova_orange", "atomic_tangerine", "neon_carrot", "sunglow", "laser_lemon", "electric_lime", "screamin'_green", "magic_mint", "blizzard_blue", "dodger_blue", "shocking_pink", "razzle_dazzle_rose", "hot_magenta");
		colorChoices = Array.concat(grayChoices, colorChoicesStd, colorChoicesMod, colorChoicesNeon);
		iTC = indexOfArray(colorChoices, call("ij.Prefs.get", "fancy.scale.font.color",colorChoices[0]),0);
		iBC = indexOfArray(colorChoices, call("ij.Prefs.get", "fancy.scale.outline.color",colorChoices[1]),1);
		iTCg = indexOfArray(grayChoices, call("ij.Prefs.get", "fancy.scale.font.gray",grayChoices[0]),0);
		iBCg = indexOfArray(grayChoices, call("ij.Prefs.get", "fancy.scale.outline.gray",grayChoices[1]),1);
		/* Reverse Black/white if it looks like it will not work with background intensity
		Note: keep white/black color order in colorChoices for intensity reversal after background intensity check */
		gCiMax = grayChoices.length-1;
		cCiMax = colorChoices.length-1;
		if (bgIpc>97){
			if(indexOf(colorChoices[iTC],"white")>=0 && sText) iTC = minOf(cCiMax,iTC+1);
			if(indexOf(colorChoices[iTC],"white")>=0) iBC = minOf(cCiMax,iTC+1); /* invert default b/w of text for outline */
			else if(indexOf(colorChoices[iTC],"black")>=0) iBC = maxOf(0,iTC-1); /* invert default b/w of text for outline */
			if(indexOf(grayChoices[iTCg],"white")>=0 && sText) iTCg = minOf(gCiMax,iTCg+1);
			if(indexOf(grayChoices[iTCg],"white")>=0) iBCg = minOf(gCiMax,iTCg+1);
			else if(indexOf(grayChoices[iTCg],"black")>=0) iBCg = maxOf(0,iTCg-1); /* invert default b/w of text for outline */
		}
		else if (bgIpc<3){
			if(indexOf(colorChoices[iTC],"black")>=0 && sText) iTC = maxOf(0,iTC-1);
			if(indexOf(colorChoices[iTC],"black")>=0) iBC = maxOf(0,iTC-1); /* invert default b/w of text for outline */
			else if(indexOf(colorChoices[iTC],"white")>=0) iBC = minOf(cCiMax,iTC+1); /* invert default b/w of text for outline */
			if(indexOf(grayChoices[iTCg],"black")>=0 && sText) iTCg = maxOf(0,iTCg-1);
			if(indexOf(grayChoices[iTCg],"black")>=0) iBCg = maxOf(0,iTCg-1);
			else if(indexOf(grayChoices[iTCg],"white")>=0) iBCg = minOf(gCiMax,iTCg+1); /* invert default b/w of text for outline */
		}
		if (imageDepth==24){
			Dialog.addChoice("Color of " + modeStr + " and text:", colorChoices, colorChoices[iTC]);
			Dialog.addChoice("Outline (background) color:", colorChoices, colorChoices[iBC]);
		}
		else {
			Dialog.addChoice("Gray tone of " + modeStr + " and text:", grayChoices, grayChoices[iTCg]);
			Dialog.addChoice("Gray tone of background:", grayChoices, grayChoices[iBCg]);
			Dialog.addMessage("Image depth is " + imageDepth + " bits: Only gray tones used unless overlays are selected for output",13,"#099FFF");
			Dialog.addChoice("Overlay color of " + modeStr + " and text:", colorChoices, colorChoices[iTC]);
			Dialog.addChoice("Overlay outline (background) color:", colorChoices, colorChoices[iBC]);
		}
		Dialog.addMessage("Guessed background % of white is " + bgIpc + "%; choose text color appropriately ",13,"#782F40");
		Dialog.addCheckbox("Override \"fancy\" formatting with simple text, no outline or shadow?", sText);
		if (selEType>=0) {
			if (selEType!=5){
				locChoice = newArray("Top Left", "Top Right", "Bottom Center", "Bottom Left", "Bottom Right", "At Center of New Selection", "At Selection");
				iLoc = indexOfArray(locChoice, call("ij.Prefs.get", "fancy.scale.location",locChoice[6]),6);
			}
			else {
				locChoice = newArray("Center of Line", "Left of Center", "Right of Center", "Over Center", "Under Center"); /* location choices unique to straight line selection */
				iLoc = indexOfArray(locChoice, call("ij.Prefs.get", "fancy.scale.location",locChoice[2]),2);
			}
		}
		else {
			locChoice = newArray("Top Left", "Top Right", "Bottom Center", "Bottom Left", "Bottom Right", "At Center of New Selection");
			iLoc = indexOfArray(locChoice, call("ij.Prefs.get", "fancy.scale.location",locChoice[4]),4);
		}
		Dialog.addChoice("Location of " + modeStr + ":", locChoice, locChoice[iLoc]);
		if (selEType==5) {
			Dialog.addString("For L/R of Center only: L\R offset","Auto",3);
			Dialog.addMessage("Adjustment in pixels from center. \"Auto\" recommended",12,"#782F40");
		}
		textStyleEffectsChoices = newArray("Default", "No text", "No shadows", "Emboss");
		Dialog.addRadioButtonGroup("Text style modifiers \(\"Default\" recommended, emboss does not apply to overlays\):___",textStyleEffectsChoices,1,4,"Default");
		if (selEType==5) sBStyleChoices = newArray("Solid Bar", "I-Bar", "Arrow", "Arrows", "S-Arrow", "S-Arrows");
		else sBStyleChoices = newArray("Solid Bar", "I-Bar", "Arrows", "S-Arrows");
		iSBS = indexOfArray(sBStyleChoices, call("ij.Prefs.get", "fancy.scale.bar.style",sBStyleChoices[0]),0);
		Dialog.addRadioButtonGroup("Bar styles \(arrowheads are solid triangles or \"S-Arrows\" which are \"stealth\"/notched\):__", sBStyleChoices, 1, 3, sBStyleChoices[iSBS]);
		if (selEType==5){
			Dialog.addMessage("Single arrow points in the direction drawn",12,"#782F40");
		}
		barHThicknessChoices = newArray("small", "medium", "large");
		iHT = indexOfArray(barHThicknessChoices, call("ij.Prefs.get", "fancy.scale.barHeader.thickness",barHThicknessChoices[0]),0);
		Dialog.addChoice("Arrowhead/bar header thickness",barHThicknessChoices, barHThicknessChoices[iHT]);
		Dialog.addNumber("X offset from edge \(for corners only\)", selOffsetX,0,1,"pixels");
		Dialog.addNumber("Y offset from edge \(corners only\)", selOffsetY,0,1,"pixel");
		fontStyleChoice = newArray("bold", "italic", "bold italic", "unstyled");
		iFS = indexOfArray(fontStyleChoice, call("ij.Prefs.get", "fancy.scale.font.style",fontStyleChoice[0]),0);
		Dialog.addChoice("Font style*:", fontStyleChoice, fontStyleChoice[iFS]);
		fontNameChoice = getFontChoiceList();
		iFN = indexOfArray(fontNameChoice, call("ij.Prefs.get", "fancy.scale.font",fontNameChoice[0]),0);
		Dialog.addChoice("Font name:", fontNameChoice, fontNameChoice[iFN]);
		overwriteChoice = newArray("New image","Add to image","Add as overlays");
		if (imageDepth==16) overwriteChoice = Array.concat("New 8-bit image",overwriteChoice);
		else if (imageDepth==32) overwriteChoice = Array.concat("New RGB image",overwriteChoice);
		iOver = indexOfArray(overwriteChoice, call("ij.Prefs.get", "fancy.scale.output",overwriteChoice[0]),0);
		Dialog.addRadioButtonGroup("Output \(\"Add to image\" modifies current image\):____________ ", overwriteChoice, 1, lengthOf(overwriteChoice),overwriteChoice[iOver]);
		if(overlayN > 0 && fScaleBarOverlays > 0){
				Dialog.setInsets(0, 235, 0);
				Dialog.addCheckbox("Remove the " + fScaleBarOverlays + " existing named scale bar overlays", true);
		}
		if(overlayN > fScaleBarOverlays){
				Dialog.setInsets(0, 235, 0);
				Dialog.addCheckbox("Remove all " + overlayN + " existing overlays \(simple text is unnamed\)", true);
		}
		if (slices>1) {
			Dialog.addMessage("Slice range for labeling \(1-"+slices+"\):");
			Dialog.addNumber("First slice in label range:", startSliceNumber);
			Dialog.addNumber("Last slice in label range:", slices);
		}
		else if (channels>1) {
			Dialog.addMessage("All "+channels+" channels will be identically labeled.");
		}
		Dialog.addCheckboxGroup(1,2,newArray("Tweak formatting?","Transparent fill"),newArray(false,false));
		Dialog.addCheckbox("Diagnostic mode?",diagnostic);
	Dialog.show();
		selLengthInUnits = Dialog.getNumber;
		if (selEType==5){
			angleLabel = Dialog.getNumber;
			angleSeparator = Dialog.getString;
			textLabel = Dialog.getString;
			rotText = Dialog.getCheckbox();
		}
		if (sF!=0) overrideUnit = Dialog.getChoice;
		else overrideUnit = "";
		fontSize =  Dialog.getNumber;
		sbHeightPC = Dialog.getNumber; /*  set minimum default bar height as 2 pixels */
		if (imageDepth==24){
			scaleBarColor = Dialog.getChoice;
			outlineColor = Dialog.getChoice;
		}
		else {
			scaleBarColor = Dialog.getChoice;
			outlineColor = Dialog.getChoice;
			scaleBarColorOv = Dialog.getChoice;
			outlineColorOv = Dialog.getChoice;
		}
		/* Simple text option */
		sText = Dialog.getCheckbox();
		selPos = Dialog.getChoice;
		if (selEType==5) offsetLR = Dialog.getString;
		textStyleMod = Dialog.getRadioButton;
		sBStyle = Dialog.getRadioButton;
		barHThickness = Dialog.getChoice;
		selOffsetX = Dialog.getNumber;
		selOffsetY = Dialog.getNumber;
		fontStyle = Dialog.getChoice;
		fontName = Dialog.getChoice;
		overWrite = Dialog.getRadioButton();
		if(overlayN > 0 && fScaleBarOverlays > 0) remOverlays = Dialog.getCheckbox();
		else remOverlays = false;
		if(overlayN > fScaleBarOverlays) remAllOverlays = Dialog.getCheckbox();
		remAllOverlays = false;
		allSlices = false;
		labelRest = true;
		if (textStyleMod=="Emboss") emboss = true;
		else emboss = false;
		if (textStyleMod=="No shadows") noShadow = true;
		else noShadow = false;
		if (textStyleMod=="No text") noText = true;
		else noText = false;
		if (slices>1) {
			startSliceNumber = Dialog.getNumber();
			endSlice = Dialog.getNumber();
			if ((startSliceNumber==0) && (endSlice==slices)) allSlices=true;
			if (startSliceNumber==endSlice) labelRest=false;
		}
		else {startSliceNumber = 1;endSlice = 1;}
		if (sF!=0) {
			oU = indexOfArray(newUnit, overrideUnit,0);
			oSF = nSF[oU];
			selectedUnit = overrideUnitChoice[oU];
		}
		tweakF = Dialog.getCheckbox();
		transparent = Dialog.getCheckbox();
		diagnostic = Dialog.getCheckbox();
		if (!sText){
			if (tweakF){
				Dialog.create("Scale Bar Format Tweaks: " + macroL);
				Dialog.addMessage("Font size \(FS\): " + fontSize);
				Dialog.addNumber("Outline stroke:",dOutS,0,3,"% of font size \(\"%FS\"\)");
				Dialog.addNumber("Shadow drop: ±",dShO,0,3,"%FS");
				Dialog.addNumber("Shadow shift \(+ve right\)",dShO,0,3,": %FS");
				Dialog.addNumber("Shadow Gaussian blur:", floor(0.75*dShO),0,3,"%FS");
				Dialog.addNumber("Shadow darkness \(darkest = 100%\):", 30,0,3,"% \(negative = glow\)");
				if (!endsWith(overWrite,"verlays")) {
					/* Overlays do not have inner shadows */
					Dialog.addMessage("Inner Shadow options:______");
					Dialog.addNumber("Inner shadow drop ±", dIShO,0,1,"%FS");
					Dialog.addNumber("Inner shadow shift:", dIShO,0,1,"%FS \(+ve right\)");
					Dialog.addNumber("Inner shadow mean blur:",floor(dIShO/2),1,2,"%FS");
					Dialog.addNumber("Inner shadow darkness \(darkest = 100%\):",20,0,3,"% \(negative = glow\)");
				}
			Dialog.show();
				outlineStroke = Dialog.getNumber;
				shadowDrop = Dialog.getNumber;
				shadowDisp = Dialog.getNumber;
				shadowBlur = Dialog.getNumber;
				shadowDarkness = Dialog.getNumber;
				if (!endsWith(overWrite,"verlays")) {
					innerShadowDrop = Dialog.getNumber;
					innerShadowDisp = Dialog.getNumber;
					innerShadowBlur = Dialog.getNumber;
					innerShadowDarkness = Dialog.getNumber;
				}
			}
		}
	if (!diagnostic) setBatchMode(true);
	 /* save last used color settings in user in preferences */
	sbHeight = maxOf(2,round(fontSize*sbHeightPC/100)); /*  set minimum default bar height as 2 pixels */
	if (!sText){  /* simplified formatting is not saved */
		if (imageDepth==24){
			call("ij.Prefs.set", "fancy.scale.font.color", scaleBarColor);
			call("ij.Prefs.set", "fancy.scale.outline.color", outlineColor);
		}
		else {
			call("ij.Prefs.set", "fancy.scale.font.gray", scaleBarColor);
			call("ij.Prefs.set", "fancy.scale.outline.gray", outlineColor);
			if (endsWith(overWrite,"overlays")){
				scaleBarColor = scaleBarColorOv;
				outlineColor = outlineColorOv;
				call("ij.Prefs.set", "fancy.scale.font.color", scaleBarColor);
				call("ij.Prefs.set", "fancy.scale.outline.color", outlineColor);
			}
		}
	}
	if (startsWith(overWrite,"New")){
		tS = "" + stripKnownExtensionFromString(unCleanLabel(activeImage));
		if (selEType!=5){
			if (endsWith(tS, "_EmbScale")) tS = replace(tS, "_EmbScale", ""); /* just removes my preferred note for embedded scale */
			if (!endsWith(tS, "cale")) tS = tS + "+scale";
		} else {
			if (endsWith(tS, "LLabel")) tS = tS + "s";
			else if (!endsWith(tS, "LLabels")) tS += "+LLabel";
		}
		selectImage(activeImageID);
		run("Select None");
		run("Duplicate...", "title=&tS duplicate");
		if (remAllOverlays) removeOverlaysByName("");
		else if (remOverlays) removeOverlaysByName("cale");
		if (startsWith(overWrite,"New 8") || startsWith(overWrite,"New R")){
			if (startsWith(overWrite,"New 8")) run("8-bit");
			else run("RGB Color");
			call("ij.Prefs.set", "fancy.scale.reduceDepth", true); /* not used here but saved for future version of fast'n fancy variant */
		}
		activeImage = getTitle();
		activeImageID = getImageID();
		imageDepth = bitDepth();
	}
	else if (remAllOverlays) removeOverlaysByName("");
	else if (remOverlays) removeOverlaysByName("cale");
	setFont(fontName,fontSize, fontStyle);
	 /* save last used settings in user in preferences */
	call("ij.Prefs.set", "fancy.scale.font.style", fontStyle);
	call("ij.Prefs.set", "fancy.scale.font", fontName);
	call("ij.Prefs.set", "fancy.scale.bar.style", sBStyle);
	call("ij.Prefs.set", "fancy.scale.location", selPos);
	call("ij.Prefs.set", "fancy.scale.output", overWrite);
	call("ij.Prefs.set", "fancy.scale.barHeader.thickness", barHThickness);
	if (imageDepth!=16 && imageDepth!=32 && fontStyle!="unstyled") fontStyle += "antialiased"; /* antialising will be applied if possible */
	fontFactor = fontSize/100;
	if (outlineStroke!=0) outlineStroke = maxOf(1, round(fontFactor * outlineStroke)); /* if some outline is desired set to at least one pixel */
	selLengthInPixels = selLengthInUnits / lcf;
	if (sF!=0) selLengthInUnits *= oSF; /* now safe to change units */
	if(textLabel!="") label = textLabel;
	else{
		selLengthLabel = removeTrailingZerosAndPeriod(toString(selLengthInUnits));
		label = selLengthLabel + " " + selectedUnit;
	}
	if (selEType==5 && textLabel==""){
		if (angleSeparator!="No angle label") label += angleSeparator + " " + angleLabel + fromCharCode(0x00B0);
	}
	labelL = getStringWidth(label);
	labelSemiL = labelL/2;
	if (!noShadow && !sText) {
		negAdj = 0.5;  /* negative offsets appear exaggerated at full displacement */
		if (shadowDrop<0) shadowDrop *= negAdj;
		if (shadowDisp<0) shadowDisp *= negAdj;
		if (shadowBlur<0) shadowBlur *= negAdj;
		if (innerShadowDrop<0) innerShadowDrop *= negAdj;
		if (innerShadowDisp<0) innerShadowDisp *= negAdj;
		if (innerShadowBlur<0) innerShadowBlur *= negAdj;
		if (shadowDrop>=0) shadowDrop = maxOf(1, round(fontFactor * shadowDrop));
		else if (shadowDrop<=0) shadowDrop = minOf(-1, round(fontFactor * shadowDrop));
		if (shadowDisp>=0) shadowDisp = maxOf(1, round(fontFactor * shadowDisp));
		else if (shadowDisp<=0) shadowDisp = minOf(-1, round(fontFactor * shadowDisp));
		if (shadowBlur>=0) shadowBlur = maxOf(1, round(fontFactor * shadowBlur));
		else if (shadowBlur<=0) shadowBlur = minOf(-1, round(fontFactor * shadowBlur));
		innerShadowDrop = fontFactor * innerShadowDrop;
		innerShadowDisp = fontFactor * innerShadowDisp;
		innerShadowBlur = fontFactor * innerShadowBlur;
		if(abs(innerShadowDrop)<0.3) innerShadowDrop = 0;
		if(abs(innerShadowDisp)<0.3) innerShadowDisp = 0;
		if(abs(innerShadowBlur)<0.3) innerShadowBlur = (innerShadowDrop+innerShadowDisp)/2;
		if (selOffsetX<(shadowDisp+shadowBlur+1)) selOffsetX += (shadowDisp+shadowBlur+1);  /* make sure shadow does not run off edge of image */
		if (selOffsetY<(shadowDrop+shadowBlur+1)) selOffsetY += (shadowDrop+shadowBlur+1);
	}
	if (sText){
		scaleBarColorOv = scaleBarColor;
		outlineColorOv = outlineColor;
		outlineStroke = 0;
		outlineStrokePC = 0;
		shadowDrop = 0;
		shadowDisp = 0;
		shadowBlur = 0;
		innerShadowDrop = 0;
		innerShadowDisp = 0;
		innerShadowBlur = 0;
	}
	if (fontStyle=="unstyled") fontStyle="";
	if (selPos == "Top Left") {
		selEX = selOffsetX;
		selEY = selOffsetY;
		if (sBStyle!="Solid Bar") selEY += sbHeight;
	} else if (selPos == "Top Right") {
		selEX = imageWidth - selLengthInPixels - selOffsetX;
		selEY = selOffsetY;
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
	} else if (selPos=="At Center of New Selection"){
		if (is("Batch Mode")==true) setBatchMode("exit & display");	/* toggle batch mode off */
		run("Select None");
		setTool("rectangle");
		title="position";
		msg = "draw a box in the image where you want the scale bar to be centered";
		waitForUser(title, msg);
		getSelectionBounds(newSelEX, newSelEY, newSelEWidth, newSelEHeight);
		selEX = newSelEX + round((newSelEWidth/2) - selLengthInPixels/2);
		selEY = newSelEY + round(newSelEHeight/2)- sbHeight - selOffsetY;
		if (is("Batch Mode")==false && !diagnostic) setBatchMode(true);	/* toggle batch mode back on */
	} else if (selPos=="At Selection"){
		if (selEY>imageHeight/2) selEY += selEHeight;  /*  Annotation relative to the bottom of the selection if in lower half of image */
		selEY = minOf(selEY, imageHeight-(sbHeight/2 + selOffsetY));
	} else if (selPos=="Center of Line"){
		selEX = lineMidX - labelSemiL;
		selEY = lineMidY + fontSize/2;
	} else if (selPos=="Left of Center"){
		if (offsetLR=="Auto") offsetLR = pow(lineXPx,1.88)/selLengthInPixels;
		else offsetLR = parseInt(offsetLR);
		selEX = maxOf(minOf(selLX[0],selLX[1])-labelL - fontSize/2, lineMidX - (labelL +  fontSize/2 + offsetLR));
		selEY = lineMidY + 0.75 * fontSize;
	} else if (selPos=="Right of Center"){
		if (offsetLR=="Auto") offsetLR = pow(lineXPx,1.9)/selLengthInPixels;
		else offsetLR = parseInt(offsetLR);
		selEX = minOf(maxOf(selLX[0],selLX[1]) + fontSize, lineMidX + fontSize/2 +offsetLR);
		selEY = lineMidY + 0.75 * fontSize;
	}	else if (selPos=="Over Center"){
		selEX = lineMidX - labelSemiL;
		selEY = minOf(selLY[0],selLY[1]) - fontSize/4;
	} else if (selPos=="Under Center"){
		selEX = lineMidX - labelSemiL;
		selEY = maxOf(selLY[0],selLY[1]) + 1.25 * fontSize;
	}
	 /*  edge limits for bar - assume intent is not to annotate edge objects */
	maxSelEY = imageHeight - round(sbHeight/2) + selOffsetY;
	selEY = maxOf(minOf(selEY,maxSelEY),selOffsetY);
	maxSelEX = imageWidth - (selLengthInPixels + selOffsetX);
	lLF = 1;
	if (endsWith(fontName,"Black") || endsWith(fontName,"ExtraBold")){
		if (selectedUnit.length>2) lLF = 1 + 0.02 * (selectedUnit.length-2); /* label length correction factor */
	}
	/* stop overrun on scale bar by label*/
	if (selEType!=5){
		selEX = maxOf(minOf(selEX,maxSelEX),selOffsetX);
		stringOF = lLF * getStringWidth(label)/selLengthInPixels;
		if (stringOF > 1) {
			shrinkFactor = getNumber("Label is " + stringOF + "x scale bar; shrink font by x", 1/stringOF);
			fontSize *= shrinkFactor;
			setFont("",fontSize);
		}
		/* stop text overrun */
		lWidth = lLF * getStringWidth(label);
		stringOver = (lWidth-selLengthInPixels*0.8);
		endPx = selEX+lWidth;
		oRun = endPx - imageWidth + selOffsetX;
		if (oRun > 0) selEx -= oRun;
		fontHeight = getValue("font.height");
		/* Adjust label location */
		if (selEY<=1.5*fontHeight)
				textYcoord = selEY + sbHeight + fontHeight;
		else textYcoord = selEY - sbHeight;
		textXOffset = round((selLengthInPixels - lLF * getStringWidth(label))/2);
		finalLabel = label;
		finalLabelX = selEX + textXOffset;
		finalLabelY = textYcoord;
	}
	else {
		finalLabel = label;
		maxLabelEx = imageWidth-(selOffsetX + labelL);
		finalLabelX = maxOf(minOf(selEX,maxLabelEx),selOffsetX);
		finalLabelY = maxOf(selOffsetY+fontSize, minOf(imageHeight-selOffsetY,selEY));
	}
	if (sBStyle=="Solid Bar") arrowStyle = "Headless";
	else if (sBStyle=="I-Bar") arrowStyle = "Bar Double";
	else if (sBStyle=="Arrows")  arrowStyle = "Double";
	else if (sBStyle=="S-Arrow")  arrowStyle = "Notched";
	else if (sBStyle=="S-Arrows")  arrowStyle = "Notched Double";
	else arrowStyle = "";
	arrowStyle += " " + barHThickness;
	if (sText && transparent && endsWith(overWrite,"verlays")) simpleTransOv = true;
	else simpleTransOv = false;
	if (!sText || simpleTransOv){
		/* Create new image that will be used to create bar/label */
		newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
		setColor(255,255,255);
		/* Although text should overlap any bar we write it first here so that we can also create a separate text mask to use later */
		if (!noText){
			tempID = getImageID;
			newImage("text_mask", "8-bit black", imageWidth, imageHeight, 1);
			writeLabel7(fontName, fontSize, "white", label,finalLabelX,finalLabelY,false);
			if(rotText){
				getSelectionFromMask("text_mask"); 
				run("Rotate...", "  angle=&lineAngle");
				setColor("white");
				fill();
				run("Make Inverse");
				setColor("black");
				fill();
				run("Select None");
			}
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
		run("Enlarge...", "enlarge=&outlineStroke pixel");
		run("Invert");
		getSelectionFromMask("label_mask");
		run("Invert");
		run("Select None");
		run("Convert to Mask");
		/* Now create outline around text in case of overlap */
		if (!noText){
			newImage("outline_text", "8-bit black", imageWidth, imageHeight, 1);
			getSelectionFromMask("text_mask");
			setColor("white");
			fill();
			run("Enlarge...", "enlarge=&outlineStroke pixel");
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
			run("Enlarge...", "enlarge=&outlineStroke pixel");
			fill();
			run("Select None");
			selectWindow("label_mask");
			getSelectionFromMask("text_mask");
			fill();
			run("Select None");
		}
		/* If Overlay chosen add fancy scale bar as overlay */
		if (endsWith(overWrite,"verlays")) {
			/* Create shadow and outline selection masks to be used for overlay components */
			scaleBarColorHex = getHexColorFromRGBArray(scaleBarColor);
			outlineColorHex = getHexColorFromRGBArray(outlineColor);
			if(!noShadow) { /* Create ovShadowMask */
				selectWindow("label_mask");
				run("Select None");
				run("Duplicate...", "title=ovShadowMask");
				getSelectionFromMask("label_mask");
				getSelectionBounds(xShad, yShad, wShad, hShad);
				setSelectionLocation(xShad+shadowDisp, yShad+shadowDrop);
				dilation = outlineStroke + maxOf(1,round(shadowBlur/2));
				run("Enlarge...", "enlarge=&dilation pixel");
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
				if(!noShadow && !sText) {
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
				getSelectionFromMask("outline_template");
				setSelectionName("Scale bar outline " + outlineColor);
				run("Add Selection...", "fill=&outlineColorHex");
				/* alignment of overlay drawn text varies with font so the label_mask is reused instead of redrawing the text directly */
				if(!transparent) {
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
		/* End overlay + !sText fancy scale bar section  */
		else {
			/* Create shadow and outline selection masks to be used for bitmap components */
			if(!noShadow && !sText) {
				/* Create drop shadow if desired */
				if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0)
					createShadowDropFromMask7("label_mask", shadowDrop, shadowDisp, shadowBlur, shadowDarkness, outlineStroke);
				/* Create inner shadow if desired */
				if (innerShadowDrop!=0 || innerShadowDisp!=0 || innerShadowBlur!=0)
					createInnerShadowFromMask6("label_mask",innerShadowDrop, innerShadowDisp, innerShadowBlur, innerShadowDarkness);
			}
			if (startsWith(overWrite,"Add to image")) tS = activeImage;
			selectWindow(tS);
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
				if (isOpen("shadow") && (shadowDarkness>0) && !noShadow && !sText) imageCalculator("Subtract", tS,"shadow");
				else if (isOpen("shadow") && (shadowDarkness<0) && !noShadow && !sText) imageCalculator("Add", tS,"shadow");
				run("Select None");
				if (!sText){
					/* apply outline around label */
					if(!transparent) getSelectionFromMask("outline_filled");
					else getSelectionFromMask("outline_template");
					setBackgroundFromColorName(outlineColor);
					run("Clear", "slice");
					run("Enlarge...", "enlarge=1 pixel");
					run("Gaussian Blur...", "sigma=0.55");
					run("Convolve...", "text1=[-0.0556 -0.0556 -0.0556 \n-0.0556 1.4448  -0.0556 \n-0.0556 -0.0556 -0.0556]"); /* moderate sharpen */
					run("Select None");
				}
				/* color label */
				if(!transparent) {
					if(!rotText){
						writeLabel7(fontName,fontSize,scaleBarColor,label,finalLabelX,finalLabelY,true);
						if (sBStyle=="Solid Bar" && selEType!=5) fillRect(selEX, selEY, selLengthInPixels, sbHeight); /* Rectangle drawn to produce thicker bar */
						else {
							if (selEType!=5) makeArrow(selEX,selEY,selEX+selLengthInPixels,selEY,arrowStyle);
							else makeArrow(selLX[0],selLY[0],selLX[1],selLY[1],arrowStyle); /* Line location is as drawn (no offsets) */
							if(sBStyle=="Solid Bar") Roi.setStrokeWidth(sbHeight);
							else Roi.setStrokeWidth(sbHeight/2);
							run("Fill");
						}
						run("Select None");
						if (!noText && (imageDepth==16 || imageDepth==32)) writeLabel7(fontName,fontSize,scaleBarColor,label,finalLabelX,finalLabelY,true); /* force anti-aliasing */
					}
					else {
						getSelectionFromMask("label_mask");
						setColorFromColorName(scaleBarColor);
						run("Fill");
						run("Select None");
					}
				}	
				if (!noShadow && !sText) {
					if (isOpen("inner_shadow")) imageCalculator("Subtract", tS,"inner_shadow");
				}
				/* Fonts do not anti-alias in 16 and 32-bit images so this is an alternative approach */
				if (!noText && outlineStroke>0 && fontSize > 12 && (imageDepth==16 || imageDepth==32)) {
					imageCalculator("XOR create", "label_mask","outline_template");
					selectWindow("Result of label_mask");
					rename("outline_only_template");
					selectWindow(tS);
					getSelectionFromMask("outline_only_template");
					run("Enlarge...", "enlarge=1 pixel");
					run("Gaussian Blur...", "sigma=0.55");
					run("Convolve...", "text1=[-0.0556 -0.0556 -0.0556 \n-0.0556 1.4448  -0.0556 \n-0.0556 -0.0556 -0.0556]"); /* moderate sharpen */
					run("Select None");
					getSelectionFromMask("outline_text");
					setBackgroundFromColorName(outlineColor);
					run("Fill", "slice");
					run("Select None");
				}
				if(emboss) {
					getSelectionFromMask("label_mask");
					run("Convolve...", "text1=[0.25 0 0 0 0\n0 0.25  0 0 0\n0 0 1 0 0\n0 0 0 -0.25  0\n0 0 0 0 -0.25 ]");
					run("Select None");
				}
			}
		}
		tempTitles = newArray("shadow","inner_shadow","label_mask","text_mask","outline_template","outline_text","outline_filled","outline_only_template");
		if (!diagnostic) for(i=0;i<lengthOf(tempTitles);i++) closeImageByTitle(tempTitles[i]);
	}
	else {
		if(!transparent){
			selectImage(activeImageID);
			scaleBarColorHex = getHexColorFromRGBArray(scaleBarColor);
			setColor(scaleBarColorHex);
			setFont(fontName,fontSize);
			if (endsWith(overWrite,"verlays")) finalLabelY -= fontSize/5;
			for (sl=startSliceNumber; sl<endSlice+1; sl++) {
				setSlice(sl);
				if (allSlices) sl=0;
				if (endsWith(overWrite,"verlays")) {
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
					if(!rotText){
						writeLabel7(fontName,fontSize,scaleBarColor,label,finalLabelX,finalLabelY,true);
						if (sBStyle=="Solid Bar" && selEType!=5) fillRect(selEX, selEY, selLengthInPixels, sbHeight); /* Rectangle drawn to produce thicker bar */
						else {
							if (selEType!=5) makeArrow(selEX,selEY,selEX+selLengthInPixels,selEY,arrowStyle);
							else makeArrow(selLX[0],selLY[0],selLX[1],selLY[1],arrowStyle); /* Line location is as drawn (no offsets) */
							if(sBStyle=="Solid Bar") Roi.setStrokeWidth(sbHeight);
							else Roi.setStrokeWidth(sbHeight/2);
							run("Fill");
						}
						run("Select None");
					}
					else {
						getSelectionFromMask("label_mask");
						setColorFromColorName(scaleBarColor);
						run("Fill");
						run("Select None");
					}
				}
				if (allSlices) sl = endSlice+1;
			}
		}
		/* End simple-Text fancy scale bar section */
	}
	restoreSettings();
	setSlice(startSliceNumber);
	setBatchMode("exit & display"); /* exit batch mode */
	if (endsWith(overWrite,"verlays")) Overlay.selectable(true);
	beep();beep();beep();
	call("java.lang.System.gc");
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
		/* v161102 changed to true-false
			v180831 some cleanup
			v210429 Expandable array version
			v220510 Looks for both class and jar if no extension is given
			v220818 Mystery issue fixed, no longer requires restoreExit	*/
		pluginCheck = false;
		if (getDirectory("plugins") == "") print("Failure to find any plugins!");
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
			checkForPlugin, setScaleFromCZSemHeader.
			v180820 Checks for CZ header before offering to use it.
			v200508 Simplified (and works?)
			v200925 Checks also for unit = pixels
		*/
		getPixelSize(unit, pixelWidth, pixelHeight);
		if (pixelWidth!=pixelHeight || pixelWidth==1 || unit=="" || unit=="inches" || unit=="pixels"){
			Dialog.create("Suspicious Units");
			rescaleChoices = newArray("Define new units for this image", "Use current scale", "Exit this macro");
			tiff = matches(getInfo("image.filename"),".*[tT][iI][fF].*");
			if (matches(getInfo("image.filename"),".*[tT][iI][fF].*") && (checkForPlugin("tiff_tags.jar"))) {
				tag = call("TIFF_Tags.getTag", getDirectory("image")+getTitle, 34118);
				if (indexOf(tag, "Image Pixel Size = ")>0) rescaleChoices = Array.concat(rescaleChoices,"Set Scale from CZSEM header");
			}
			else tag = "";
			rescaleDialogLabel = "pixelHeight = "+pixelHeight+", pixelWidth = "+pixelWidth+", unit = "+unit+": what would you like to do?";
			Dialog.addRadioButtonGroup(rescaleDialogLabel, rescaleChoices, 3, 1, rescaleChoices[0]) ;
			Dialog.show();
			rescaleChoice = Dialog.getRadioButton;
			if (rescaleChoice=="Define new units for this image") run("Set Scale...");
			else if (rescaleChoice=="Exit this macro") restoreExit("Goodbye");
			else if (rescaleChoice=="Set Scale from CZSEM header"){
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
		imageCalculator("Max","inner_shadow",mask);
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
		   v211022 all names lower-case, all spaces to underscores v220225 Added more hash value comments as a reference v220706 restores missing magenta
		   REQUIRES restoreExit function.  57 Colors
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
		else if (colorName == "green") cA = newArray(0,255,0); /* #00FF00 AKA Lime green */
		else if (colorName == "blue") cA = newArray(0,0,255);
		else if (colorName == "cyan") cA = newArray(0, 255, 255);
		else if (colorName == "yellow") cA = newArray(255,255,0);
		else if (colorName == "magenta") cA = newArray(255,0,255); /* #FF00FF */
		else if (colorName == "pink") cA = newArray(255, 192, 203);
		else if (colorName == "violet") cA = newArray(127,0,255);
		else if (colorName == "orange") cA = newArray(255, 165, 0);
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
	/* Hex conversion below adapted from T.Ferreira, 20010.01 http://imagejdocu.tudor.lu/doku.php?id=macro:rgbtohex */
	function getHexColorFromRGBArray(colorNameString) {
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
		/* v220126 added micrometer symbol
			v220809 further tweaked handling of microns */
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
		if (scaleFactor<0) restoreExit(inputUnit + " not recognized units; macro will exit");
		else return scaleFactor;
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
		/* v220822 1st color array version (based on https://wsr.imagej.net//macros/tools/ColorPickerTool.txt) */
		iW = Image.width-1;
		iH = Image.height-1;
		interrogate = round(maxOf(1,(iW+iH)/200));
		if (bitDepth==24){red = 0; green = 0; blue = 0;}
		else int = 0;
		xC = newArray(0,iW,0,iW);
		yC = newArray(0,0,iH,iH);
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
	function indexOfArrayThatContains(array, value) {
		/* Like indexOfArray but partial matches possible
			v190423 Only first match returned */
		indexFound = -1;
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
	function setScaleFromCZSemHeader() {
	/*	This very simple function sets the scale for SEM images taken with the Carl Zeiss SmartSEM program. It requires the tiff_tags plugin written by Joachim Wesner. It can be downloaded from http://rsbweb.nih.gov/ij/plugins/tiff-tags.html
	 There is an example image available at http://rsbweb.nih.gov/ij/images/SmartSEMSample.tif
	 This is the number of the VERY long tag that stores all the SEM information See original Nabble post by Pablo Manuel Jais: http://imagej.1557.x6.nabble.com/Importing-SEM-images-with-scale-td3689900.html imageJ version: https://rsb.info.nih.gov/ij/macros/SetScaleFromTiffTag.txt
	 v161103 with minor tweaks by Peter J. Lee National High Magnetic Field Laboratory
	 v161108 adds Boolean unit option, v171024 fixes Boolean option.
	 v180820 fixed incorrect message in dialog box.
	 v220812 REQUIRES sensibleUnits function */
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
		CZScale = sensibleUnits(distPerPixel,CZScale[1]);
		distPerPixel = parseFloat(CZScale[0]);
		CZUnit = CZScale[1];				
		setVoxelSize(distPerPixel, distPerPixel, 1, CZUnit);
	}
	else if (getBoolean("No CZSem tag found; do you want to continue?")) run("Set Scale...");
	}
	function sensibleUnits(pixelW,inUnit){
		/* v220805 1st version */
		kUnits = newArray("m", "mm", getInfo("micrometer.abbreviation"), "nm", "pm");
		if(startsWith(inUnit,"micro") || endsWith(inUnit,"ons") || inUnit=="um" || inUnit=="µm") inUnit = kUnits[2];
		iInUnit = indexOfArray(kUnits,inUnit,-1);
		if (iInUnit<0) restoreExit("Scale unit \(" + inUnit + "\) not in unitChoices");
		// print("inUnit: " + inUnit); print("inpixelW: " + pixelW);
		while (round(pixelW)>50) {
			/* */
			pixelW /= 1000;
			iInUnit -= 1;
			inUnit = kUnits[iInUnit];
		}
		while (pixelW<0.02){
			pixelW *= 1000;
			iInUnit += 1;
			inUnit = kUnits[iInUnit];				
		}
		// print("outUnit: " + inUnit); print("outpixelW: " + pixelW);
		outArray = Array.concat(pixelW,inUnit);
		return outArray;
	}
	function stripKnownExtensionFromString(string) {
		/*	Note: Do not use on path as it may change the directory names
		v210924: Tries to make sure string stays as string
		v211014: Adds some additional cleanup
		v211025: fixes multiple knowns issue
		v211101: Added ".Ext_" removal
		v211104: Restricts cleanup to end of string to reduce risk of corrupting path
		v211112: Tries to fix trapped extension before channel listing. Adds xlsx extension.
		v220615: Tries to fix the fix for the trapped extensions ...
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
					iExt = lastIndexOf(string, "." + knownExt[i]);
					if(ichanLabels>0 && iExt>(ichanLabels+lengthOf(chanLabels[j]))){
						iExt = lastIndexOf(string, "." + knownExt[i]);
						if (ichanLabels>iExt && iExt>0) string = "" + substring(string, 0, iExt) + "_" + chanLabels[j];
						ichanLabels = lastIndexOf(string, chanLabels[j]);
						for (k=0; k<uSL; k++){
							iExt = lastIndexOf(string, unwantedSuffixes[k]);  /* common ASC suffix */
							if (ichanLabels>iExt && iExt>0) string = "" + substring(string, 0, iExt) + "_" + chanLabels[j];
						}
					}
				}
				iExt = lastIndexOf(string, "." + knownExt[i]);
				if (iExt>=(lengthOf(string)-(lengthOf(knownExt[i])+1)) && iExt>0) string = "" + substring(string, 0, iExt);
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
	function unInvertLUT() {
		if (is("Inverting LUT")) run("Invert LUT");
	}
	function writeLabel7(font, size, color, text,x,y,aA){
	/* Requires the functions setColorFromColorName, getColorArrayFromColorName(colorName) etc.
	v190619 all variables as options */
		if (aA == true) setFont(font , size, "antialiased");
		else setFont(font, size);
		setColorFromColorName(color);
		drawString(text, x, y);
	}
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
v211104: Updated stripKnownExtensionsFromString function    v211112: Again
/*