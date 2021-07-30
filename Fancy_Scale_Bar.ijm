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
*/
	macroL = "Fancy_Scale_Bar_v210730]";
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
	imageDepth = bitDepth();
	checkForUnits();
	getDimensions(imageWidth, imageHeight, channels, slices, frames);
	startSliceNumber = getSliceNumber();
	remSlices = slices-startSliceNumber;
	if (selEType==5) sbFontSize = maxOf(10, round((imageHeight+imageWidth)/90)); /* set minimum default font size as 12 */
	else sbFontSize = maxOf(12, round((imageHeight+imageWidth)/60)); /* set minimum default font size as 12 */
	getVoxelSize(pixelWidth, pixelHeight, pixelDepth, selectedUnit);
	if (selectedUnit == "um") selectedUnit = micron;
	sF = getScaleFactor(selectedUnit);
	scaleFactors = newArray(1E3,1,1E-2,1E-3,1E-6,1E-9,1E-12);
	metricUnits = newArray("km","m","cm","mm","µm","nm","pm");
	// unitI = indexOfArray(metricUnits,selectedUnit,0);
	// for (i=0; i<lengthOf(scaleFactors); i++){
		// newUnitI = -1;
		// if (pixelWidth*imageWidth/5 > 1000) { /* test whether scale bar is likely to be more than 1000 units */
			// for (j=0; j<unitI; j++){
				// if (scaleFactors[j] > sF){
					// newSF = scaleFactors[j];
					// newUnitI = j;
				// }
				// else j = unitI;
			// }
		// }
		// else if (pixelWidth*imageWidth/5 < 1) { /* test whether scale bar is likely to have tiny units */
			// for (j=unitI; j<lengthOf(scaleFactors); j++){
				// if (scaleFactors[j] < sF){
					// newSF = scaleFactors[j];
					// newUnitI = j;
				// }
				// else j = lengthOf(scaleFactors);
			// }
		// }
		// if (newUnitI>=0){
			// selectedUnit = metricUnits[newUnitI];
			// nPW = pixelWidth*sF/newSF;
			// nPH = pixelHeight*sF/newSF;
			// setVoxelSize(nPW, nPH, pixelDepth, selectedUnit);
			// getVoxelSize(pixelWidth, pixelHeight, pixelDepth, selectedUnit);
		// }
	// }
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
		if (selEType!=5){
			sbWidth = lcf*selEWidth;
			sbDP = autoCalculateDecPlacesFromValueOnly(sbWidth);
			sbWidth = d2s(sbWidth, sbDP);
		}
		else {
			lineXPx = abs(selLX[1]-selLX[0]); /* used for label offsets later */
			lineYPx = abs(selLY[1]-selLY[0]); /* used for label offsets later */
			lineLength = sqrt(pow(lineXPx,2) + pow(lineYPx,2));
			sbWidth = lcf*lineLength;
			sbDP = autoCalculateDecPlacesFromValueOnly(sbWidth)+2; /* Add more dp for line labeling */
			sbWidth = d2s(sbWidth, sbDP);
			lineAngle = (180/PI) * Math.atan2(lineYPx, lineXPx);
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
	Dialog.create("Scale Bar Parameters: " + macroL);
		if (selEType==5){
			Dialog.addNumber("Selected line length \(" + d2s(lineLength,1) + " pixels\):", sbWidth, dpSB+2, 10, selectedUnit);
			Dialog.addNumber("Selected line angle \(" + fromCharCode(0x00B0) + " from horizontal\):", lineAngle, 2, 5, fromCharCode(0x00B0));
			Dialog.addString("Length/angle separator:", "No angle label",10);
			Dialog.setInsets(-90, 370, 0);
			Dialog.addMessage("Length labeling mode:\nSelect none or a non-\nstraight-line selection\nto draw a scale bar",13,"#782F40");
			modeStr = "length line";
		} else {
			Dialog.addMessage("Scale bar mode: Use the straight line selection tool for length labeling",12,"#099FFF");
			Dialog.addNumber("Length of scale bar:", sbWidth, dpSB, 10, selectedUnit);
			modeStr = "scale bar";
		}
		if (sF!=0) {
			newUnit = newArray(""+selectedUnit+" Length x1", "cm \(Length x"+nSF[1]+"\)","mm \(Length x"+nSF[2]+"\)","µm \(Length x"+nSF[3]+"\)","microns \(Length x"+nSF[4]+"\)", "nm \(Length x"+nSF[5]+"\)", "Å \(Length x"+nSF[6]+"\)", "pm \(Length x"+nSF[7]+"\)", "inches \(Length x"+nSF[8]+"\)", "human hair \(Length x"+nSF[9]+"\)");
			Dialog.addChoice("Override unit with new choice?", newUnit, newUnit[0]);
		}
		Dialog.addNumber("Font size \(\"FS\"\):", sbFontSize, 0, 4,"");
		Dialog.addNumber("Thickness of " + modeStr + " :",19,0,3,"% of font size");										 
		colorChoice = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray", "red", "cyan", "pink", "green", "blue", "yellow", "orange", "garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "gray_modern", "green_dark_modern", "green_modern", "orange_modern", "pink_modern", "purple_modern", "jazzberry_jam", "red_N_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern", "Radical Red", "Wild Watermelon", "Outrageous Orange", "Atomic Tangerine", "Neon Carrot", "Sunglow", "Laser Lemon", "Electric Lime", "Screamin' Green", "Magic Mint", "Blizzard Blue", "Shocking Pink", "Razzle Dazzle Rose", "Hot Magenta");
		grayChoice = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray");
		iTC = indexOfArray(colorChoice, call("ij.Prefs.get", "fancy.scale.font.color",colorChoice[0]),0);
		iBC = indexOfArray(colorChoice, call("ij.Prefs.get", "fancy.scale.outline.color",colorChoice[1]),1);
		iTCg = indexOfArray(grayChoice, call("ij.Prefs.get", "fancy.scale.font.gray",colorChoice[0]),0);
		iBCg = indexOfArray(grayChoice, call("ij.Prefs.get", "fancy.scale.outline.gray",colorChoice[1]),1);
		if (imageDepth==24){
			Dialog.addChoice("Color of " + modeStr + " and text:", colorChoice, colorChoice[iTC]);
			Dialog.addChoice("Outline (background) color:", colorChoice, colorChoice[iBC]);
		}
		else {
			Dialog.addChoice("Gray tone of " + modeStr + " and text:", colorChoice, colorChoice[iTCg]);
			Dialog.addChoice("Gray tone (background) color:", colorChoice, colorChoice[iBCg]);
			Dialog.addMessage("Image depth is " + imageDepth + " bits: Only graytones used unless overlays are selected for output",13,"#099FFF");
			Dialog.addChoice("Overlay color of " + modeStr + " and text:", colorChoice, colorChoice[iTC]);
			Dialog.addChoice("Overlay outline (background) color:", colorChoice, colorChoice[iBC]);

		}
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
		// Dialog.setInsets(-10, 20, 10); /* It seems that my efforts to raise the height of radio button group have been futile */
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
		if(Overlay.size>0){
			Dialog.setInsets(0, 235, 0);
			Dialog.addCheckbox("Remove the " + Overlay.size + " existing overlays", false);
		}
		if (slices>1) {
			Dialog.addMessage("Slice range for labeling \(1-"+slices+"\):");
			Dialog.addNumber("First slice in label range:", startSliceNumber);
			Dialog.addNumber("Last slice in label range:", slices);
		}
		else if (channels>1) {
			Dialog.addMessage("All "+channels+" channels will be identically labeled.");
		}
		Dialog.addCheckbox("Tweak formatting?",false);
	Dialog.show();
		selLengthInUnits = Dialog.getNumber;
		if (selEType==5){
			angleLabel = Dialog.getNumber;
			angleSeparator = Dialog.getString;
		}		
		if (sF!=0) overrideUnit = Dialog.getChoice;
		fontSize =  Dialog.getNumber;
		sbHeightPC = Dialog.getNumber; /*  set minimum default bar height as 2 pixels */
		scaleBarColor = Dialog.getChoice;
		outlineColor = Dialog.getChoice;
		if (imageDepth!=24){
			scaleBarColorOv = Dialog.getChoice;
			outlineColorOv = Dialog.getChoice;
		}
		selPos = Dialog.getChoice;
		if (selEType==5) offsetLR = Dialog.getString;
		textStyleMod = Dialog.getRadioButton;
		sBStyle = Dialog.getRadioButton;
		barHThickness = Dialog.getChoice;
		selOffsetX = Dialog.getNumber;
		selOffsetY = Dialog.getNumber;
		fontStyle = Dialog.getChoice;
		fontName = Dialog.getChoice;

		overWrite = Dialog.getRadioButton;
		if(Overlay.size>0)	remOverlays = Dialog.getCheckbox;
		else remOverlays = false;
		allSlices = false;
		labelRest = true;
		if (textStyleMod=="Emboss") emboss = true;
		else emboss = false;
		if (textStyleMod=="No shadows") noShadow = true;
		else noShadow = false;
		if (textStyleMod=="No text") noText = true;
		else noText = false;
		if (slices>1) {
			startSliceNumber = Dialog.getNumber;
			endSlice = Dialog.getNumber;
			if ((startSliceNumber==0) && (endSlice==slices)) allSlices=true;
			if (startSliceNumber==endSlice) labelRest=false;
		}
		else {startSliceNumber = 1;endSlice = 1;}
		if (sF!=0) { 
			oU = indexOfArray(newUnit, overrideUnit,0);
			oSF = nSF[oU];
			selectedUnit = overrideUnitChoice[oU];
		}
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
		if (Dialog.getCheckbox){
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
	setBatchMode(true);
	 /* save last used color settings in user in preferences */
	sbHeight = maxOf(2,round(fontSize*sbHeightPC/100)); /*  set minimum default bar height as 2 pixels */
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
	if (remOverlays){
		while (Overlay.size!=0) Overlay.remove;
		/* Some overlays seem hard to remove . . . this tries really hard!  */
		if(Overlay.size>0) {
			run("Remove Overlay");
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
				run("Remove Overlay");
			}
			if (slices==1 && channels>1) {
				for (i=0; i<channels; i++){
					for (j=0; j<initialOverlaySize; j++){
						setChannel(i+1);
						if (j<Overlay.size){
							Overlay.activateSelection(j);
							overlaySelectionName = getInfo("selection.name");
							if (indexOf(overlaySelectionName,"cale")>=0) Overlay.removeSelection(j);
							run("Remove Overlay");
						}
					}
				}
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
		run("Select None");
		selectWindow(activeImage);
		run("Duplicate...", "title=&tS duplicate");
		if (startsWith(overWrite,"New 8") || startsWith(overWrite,"New R")){
			if (startsWith(overWrite,"New 8")) run("8-bit");
			else run("RGB Color");
			call("ij.Prefs.set", "fancy.scale.reduceDepth", true); /* not used here but saved for future version of fast'n fancy variant */
		}
		activeImage = getTitle();
		imageDepth = bitDepth();
	}
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
	selLengthLabel = removeTrailingZerosAndPeriod(toString(selLengthInUnits));
	label = selLengthLabel + " " + selectedUnit;
	if (selEType==5){
		if (angleSeparator!="No angle label") label += angleSeparator + " " + angleLabel + fromCharCode(0x00B0);
	}
	labelL = getStringWidth(label);
	labelSemiL = labelL/2;
	if (!noShadow) {
		negAdj = 0.5;  /* negative offsets appear exaggerated at full displacement */
		if (shadowDrop<0) shadowDrop *= negAdj;
		if (shadowDisp<0) shadowDisp *= negAdj;
		if (shadowBlur<0) shadowBlur *= negAdj;
		if (innerShadowDrop<0) innerShadowDrop *= negAdj;
		if (innerShadowDisp<0) innerShadowDisp *= negAdj;
		if (innerShadowBlur<0) innerShadowBlur *= negAdj;
	
		if (shadowDrop!=0) shadowDrop = maxOf(1, round(fontFactor * shadowDrop));
		if (shadowDisp!=0) shadowDisp = maxOf(1, round(fontFactor * shadowDisp));
		if (shadowBlur!=0) shadowBlur = maxOf(1, round(fontFactor * shadowBlur));
		innerShadowDrop = floor(fontFactor * innerShadowDrop);
		innerShadowDisp = floor(fontFactor * innerShadowDisp);
		innerShadowBlur = floor(fontFactor * innerShadowBlur);
		if (selOffsetX<(shadowDisp+shadowBlur+1)) selOffsetX += (shadowDisp+shadowBlur+1);  /* make sure shadow does not run off edge of image */
		if (selOffsetY<(shadowDrop+shadowBlur+1)) selOffsetY += (shadowDrop+shadowBlur+1);
	}
	// if (barThickness=="small") sbHeight = fontSize/4;
	// else if (barThickness=="medium") sbHeight = fontSize/4;
	// else (barThickness=="large") sbHeight = fontSize;											  
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
		if (is("Batch Mode")==false) setBatchMode(true);	/* toggle batch mode back on */
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
	/* stop overrun on scale bar by label of more than 20% */
	if (selEType!=5){
		selEX = maxOf(minOf(selEX,maxSelEX),selOffsetX);
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
	}
	else {
		finalLabel = label;
		maxLabelEx = imageWidth-(selOffsetX + labelL);
		finalLabelX = maxOf(minOf(selEX,maxLabelEx),selOffsetX);
		// finalLabelX = maxOf(selOffsetX,selEX);
		// overrunX = imageWidth-(finalLabelX + selOffsetX + getStringWidth(label));
		// print(imageWidth, finalLabelX, selOffsetX, getStringWidth(label),imageWidth-(finalLabelX + selOffsetX + getStringWidth(label)));
		// if(overrunX<0) finalLabelX+=overrunX;
		finalLabelY = maxOf(selOffsetY+fontSize, minOf(imageHeight-selOffsetY,selEY));
	}
	/* Create new image that will be used to create bar/label */
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	setColor(255,255,255);
	/* Although text should overlap any bar we write it first here so that we can also create a separate text mask to use later */
	if (!noText){
		writeLabel7(fontName, fontSize, "white", label,finalLabelX,finalLabelY,false);
		tempID = getImageID;
		run("Duplicate...", "title=text_mask");
		selectImage(tempID);
	}
	if (sBStyle=="Solid Bar" && selEType!=5) fillRect(selEX, selEY, selLengthInPixels, sbHeight); /* Rectangle drawn to produce thicker bar */
	else {
		if (sBStyle=="Solid Bar") arrowStyle = "Headless";
		else if (sBStyle=="I-Bar") arrowStyle = "Bar Double";
		else if (sBStyle=="Arrows")  arrowStyle = "Double";
		else if (sBStyle=="S-Arrow")  arrowStyle = "Notched";
		else if (sBStyle=="S-Arrows")  arrowStyle = "Notched Double";
		else arrowStyle = "";
		arrowStyle += " " + barHThickness;								   
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
	newImage("outline_template", "8-bit black", imageWidth, imageHeight, 1);
	getSelectionFromMask("label_mask");
	run("Enlarge...", "enlarge=&outlineStroke pixel");
	setBackgroundFromColorName("white");
	run("Clear", "slice");
	run("Select None");
	run("Invert");
	getSelectionFromMask("label_mask");
	run("Clear", "slice");	
	/* Now create outline around text in case of overlap */
	if (!noText){
		newImage("outline_text", "8-bit black", imageWidth, imageHeight, 1);
		setBackgroundFromColorName("white");
		getSelectionFromMask("text_mask");
		run("Clear", "slice");
		run("Enlarge...", "enlarge=&outlineStroke pixel");
		run("Clear Outside");
		run("Select None");
		imageCalculator("Min", "outline_template","outline_text");
		run("Select None");
		run("Invert");
		imageCalculator("Max", "label_mask","outline_template");
		selectWindow("outline_template");
		run("Invert");
	}
	/* If Overlay chosen add fancy scale bar as overlay */
	if (endsWith(overWrite,"verlays")) {
		/* Create shadow and outline selection masks to be used for overlay components */
		scaleBarColorHex = getHexColorFromRGBArray(scaleBarColor);
		outlineColorHex = getHexColorFromRGBArray(outlineColor);
		if(!noShadow) {
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
			run("Select None");			
		}
		/* shadow and outline selection masks have now been created */
		selectWindow(activeImage);
		for (sl=startSliceNumber; sl<endSlice+1; sl++) {
			setSlice(sl);
			if (allSlices) sl=0;
			if(!noShadow) {
				getSelectionFromMask("ovShadowMask");
				List.setMeasurements;
				bgGray = List.getValue("Mean");
				List.clear();
				if (imageDepth==16 || imageDepth==32) bgGray = round(bgGray/256);
				grayHex = toHex(round(bgGray*(100-shadowDarkness)/100));
				shadowHex = "#" + ""+pad(grayHex) + ""+pad(grayHex) + ""+pad(grayHex);
				setSelectionName("Scale Bar Shadow");
				run("Add Selection...", "fill="+shadowHex);
			}
			getSelectionFromMask("outline_template");
			run("Make Inverse");
			setSelectionName("Scale Bar Outline");
			run("Add Selection...", "fill=&outlineColorHex");
			/* alignment of overlay drawn text varies with font so the label_mask is reused instead of redrawing the text directly */
			getSelectionFromMask("label_mask");
			setSelectionName("Scale Label" + scaleBarColor);
			run("Add Selection...", "fill=" + scaleBarColorHex);
			Overlay.setPosition(sl);
			run("Select None");
			if (allSlices) sl = endSlice+1;
		}
		run("Select None");
		closeImageByTitle("ovShadowMask");
	}
	/* End overlay fancy scale bar section */
	else {
		/* Create shadow and outline selection masks to be used for bitmap components */
		if (!noShadow) {
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
			if (isOpen("shadow") && (shadowDarkness>0) && !noShadow) imageCalculator("Subtract", tS,"shadow");
			else if (isOpen("shadow") && (shadowDarkness<0) && !noShadow) imageCalculator("Add", tS,"shadow");
			run("Select None");
			/* apply outline around label */
			getSelectionFromMask("outline_template");
			run("Make Inverse");
			setBackgroundFromColorName(outlineColor);
			run("Clear", "slice");
			run("Select None");
			/* color label */
			getSelectionFromMask("label_mask");
			setBackgroundFromColorName(scaleBarColor);
			run("Clear", "slice");
			run("Select None");
			if (!noText && (imageDepth==16 || imageDepth==32)) writeLabel7(fontName,fontSize,scaleBarColor,label,finalLabelX,finalLabelY,true); /* force anti-aliasing */
			if (!noShadow) {
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
				closeImageByTitle("outline_only_template");
				run("Select None");
			}
			if(emboss) {
				getSelectionFromMask("label_mask");
				run("Convolve...", "text1=[0.25 0 0 0 0\n0 0.25  0 0 0\n0 0 1 0 0\n0 0 0 -0.25  0\n0 0 0 0 -0.25 ]");
				run("Select None");
			}
		}
	}
	closeImageByTitle("shadow");
	closeImageByTitle("inner_shadow");
	closeImageByTitle("label_mask");
	closeImageByTitle("text_mask");
	closeImageByTitle("outline_template");
	closeImageByTitle("outline_text");
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
			v180831 some cleanup */
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
					subFolderCount += 1;
				}
			}
			subFolderList = Array.trim(subFolderList, subFolderCount);
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
		else if (colorName == "cyan") cA = newArray(0, 255, 255);
		else if (colorName == "orange") cA = newArray(255, 165, 0);
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
		else if (colorName == "red_N_modern") cA = newArray(227,24,55);
		else if (colorName == "red_modern") cA = newArray(192,80,77);
		else if (colorName == "tan_modern") cA = newArray(238,236,225);
		else if (colorName == "violet_modern") cA = newArray(76,65,132);
		else if (colorName == "yellow_modern") cA = newArray(247,238,69);
		/* Fluorescent Colors https://www.w3schools.com/colors/colors_crayola.asp */
		else if (colorName == "Radical Red") cA = newArray(255,53,94);			/* #FF355E */
		else if (colorName == "Wild Watermelon") cA = newArray(253,91,120);		/* #FD5B78 */
		else if (colorName == "Outrageous Orange") cA = newArray(255,96,55);	/* #FF6037 */
		else if (colorName == "Supernova Orange") cA = newArray(255,191,63);	/* FFBF3F Supernova Neon Orange*/
		else if (colorName == "Atomic Tangerine") cA = newArray(255,153,102);	/* #FF9966 */
		else if (colorName == "Neon Carrot") cA = newArray(255,153,51);			/* #FF9933 */
		else if (colorName == "Sunglow") cA = newArray(255,204,51); 			/* #FFCC33 */
		else if (colorName == "Laser Lemon") cA = newArray(255,255,102); 		/* #FFFF66 "Unmellow Yellow" */
		else if (colorName == "Electric Lime") cA = newArray(204,255,0); 		/* #CCFF00 */
		else if (colorName == "Screamin' Green") cA = newArray(102,255,102); 	/* #66FF66 */
		else if (colorName == "Magic Mint") cA = newArray(170,240,209); 		/* #AAF0D1 */
		else if (colorName == "Blizzard Blue") cA = newArray(80,191,230); 		/* #50BFE6 Malibu */
		else if (colorName == "Dodger Blue") cA = newArray(9,159,255);			/* #099FFF Dodger Neon Blue */
		else if (colorName == "Shocking Pink") cA = newArray(255,110,255);		/* #FF6EFF Ultra Pink */
		else if (colorName == "Razzle Dazzle Rose") cA = newArray(238,52,210); 	/* #EE34D2 */
		else if (colorName == "Hot Magenta") cA = newArray(255,0,204);			/* #FF00CC AKA Purple Pizzazz */
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
		/* v171024 */
		if (inputUnit=="km") scaleFactor = 1E3;
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
	function removeTrailingZerosAndPeriod(string) { /* Removes any trailing zeros after a period */
		while (endsWith(string,".0")) string=substring(string,0, lastIndexOf(string, ".0"));
		while(endsWith(string,".")) string=substring(string,0, lastIndexOf(string, "."));
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
		if (lastIndexOf(string, ".")!=-1) {
			knownExt = newArray("tif", "tiff", "TIF", "TIFF", "png", "PNG", "GIF", "gif", "jpg", "JPG", "jpeg", "JPEG", "jp2", "JP2", "txt", "TXT", "csv", "CSV", "psd", "PSD", "xls", "XLS");
			for (i=0; i<knownExt.length; i++) {
				index = lastIndexOf(string, "." + knownExt[i]);
				if (index>=(lengthOf(string)-(lengthOf(knownExt[i])+1))) string = substring(string, 0, index);
			}
		}
		return string;
	}
	function unCleanLabel(string) {
	/* v161104 This function replaces special characters with standard characters for file system compatible filenames
	+ 041117 to remove spaces as well */
		string= replace(string, fromCharCode(178), "\\^2"); /* superscript 2 */
		string= replace(string, fromCharCode(179), "\\^3"); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, fromCharCode(0xFE63) + fromCharCode(185), "\\^-1"); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
		string= replace(string, fromCharCode(0xFE63) + fromCharCode(178), "\\^-2"); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
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
	function writeLabel7(font, size, color, text,x,y,aA){
	/* Requires the functions setColorFromColorName, getColorArrayFromColorName(colorName) etc. 
	v190619 all variables as options */
		if (aA == true) setFont(font , size, "antialiased");
		else setFont(font, size);
		setColorFromColorName(color);
		drawString(text, x, y); 
	}