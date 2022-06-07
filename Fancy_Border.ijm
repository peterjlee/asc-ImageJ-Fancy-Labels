macro "Fancy Border" {
/* v190503 1st version PJL 5/3/2019 4:54 PM
	v190506 Adds ability to add all three of inner, outer and center borders.
	+ v200706 Changed imageDepth variable name added macro label.
	+ v211022 Updated color choices
	+ v211025 Updated stripKnownExtensionFromString
	+ v211104: Updated stripKnownExtensionsFromString function    v211112: Again  f5: updated pad function
*/
	macroL = "Fancy_Border_v211112-f5.ijm";
	requires("1.52i"); /* Utilizes Overlay.setPosition(0) from IJ >1.52i */
	saveSettings(); /* To restore settings at the end */
	selEType = selectionType;  /* Returns the selection type, where 0=rectangle, 1=oval, 2=polygon, 3=freehand, 4=traced, 5=straight line, 6=segmented line, 7=freehand line, 8=angle, 9=composite and 10=point.*/
	if (selEType>=0) {
		getSelectionBounds(selEX, selEY, selEWidth, selEHeight);
		if ((selEWidth + selEHeight)<6) selEType=-1; /* Ignore junk selections that are suspiciously small */
	}
	else restoreExit("Sorry, a selection is required");
	setBatchMode(true);
	originalImage = getTitle();
	imageDepth = bitDepth();
	getDimensions(imageWidth, imageHeight, channels, slices, frames);
	run("Create Mask");
	if(is("Inverting LUT")) run("Invert LUT"); /* more effectively removes Inverting LUT */
	rename("selection_mask");
	run("Select None");
	selectWindow(originalImage);
	startSliceNumber = getSliceNumber();
	remSlices = slices-startSliceNumber;
	dBrderThick = maxOf(round((imageWidth+imageHeight)/1000),1);
	if (imageDepth==24) colorChoice = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray", "red", "cyan", "pink", "green", "blue", "yellow", "orange", "garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "blue_honolulu", "gray_modern", "green_dark_modern", "green_modern", "orange_modern", "pink_modern", "purple_modern", "jazzberry_jam", "red_n_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern", "radical_red", "wild_watermelon", "outrageous_orange", "atomic_tangerine", "neon_carrot", "sunglow", "laser_lemon", "electric_lime", "screamin'_green", "magic_mint", "blizzard_blue", "shocking_pink", "razzle_dazzle_rose", "hot_magenta");
	else colorChoice = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray");
	fancyBorderLocationsString = call("ij.Prefs.get", "fancy.borderLocations", "false|true|false");
	fancyBorderLocations = split(fancyBorderLocationsString,"|");
	Dialog.create("Border Format: " + macroL);
		Dialog.addMessage("Borders are added in the order: inner,outer,center")
		Dialog.addCheckbox("Draw border marking inside of selection?", fancyBorderLocations[0]);
		Dialog.addNumber("Width of inner border:",dBrderThick,0,3,"pixels");
		iIBC = indexOfArray(colorChoice, call("ij.Prefs.get", "fancy.innerBorderColor",colorChoice[1]),1);
		Dialog.addChoice("Inner border color:", colorChoice, colorChoice[iIBC]);
		Dialog.addCheckbox("Draw border marking outside of selection?",  fancyBorderLocations[1]);
		Dialog.addNumber("Width of outer border:",dBrderThick,0,3,"pixels");
		iOBC = indexOfArray(colorChoice, call("ij.Prefs.get", "fancy.outerBorderColor",colorChoice[1]),1);
		Dialog.addChoice("Outer border color:", colorChoice, colorChoice[iOBC]);
		Dialog.addCheckbox("Draw border marking centered on selection?",  fancyBorderLocations[2]);
		Dialog.addNumber("Width of center border:",dBrderThick,0,3,"pixels");
		iCBC = indexOfArray(colorChoice, call("ij.Prefs.get", "fancy.centerBorderColor",colorChoice[1]),1);
		Dialog.addChoice("Center border color:", colorChoice, colorChoice[iCBC]);
		overwriteChoice = newArray("Add overlays");
		if (Overlay.size>0) overwriteChoice = Array.concat(overwriteChoice, "Replace ALL overlays");
		if (selEType<2) overwriteChoice = Array.concat(overwriteChoice, "Destructive overwrite", "New image");
		if (overwriteChoice.length==1) Dialog.addMessage("Output:_________________ \n  \n  Borders added as overlays.\n  Use rectangle or ellipse selections for\n     destructive overwrite.\n  Use 'flatten' to merge overlays with image.");
		else Dialog.addRadioButtonGroup("Output:_________________ ", overwriteChoice, 3, overwriteChoice.length, overwriteChoice[overwriteChoice.length-1]);
	Dialog.show();
		innerBorder = Dialog.getCheckbox();
		innerBorderThickness = Dialog.getNumber; /*  set minimum default bar height as 2 pixels */
		innerBorderColor = Dialog.getChoice;
		outerBorder = Dialog.getCheckbox();
		outerBorderThickness = Dialog.getNumber; /*  set minimum default bar height as 2 pixels */
		outerBorderColor = Dialog.getChoice;
		centerBorder = Dialog.getCheckbox();
		centerBorderThickness = Dialog.getNumber; /*  set minimum default bar height as 2 pixels */
		centerBorderColor = Dialog.getChoice;
		if (selEType<2 || Overlay.size>0) overWrite = Dialog.getRadioButton;
		else overWrite = "Add overlays";
	if (startsWith(overWrite,"Replace")) while (Overlay.size!=0) Overlay.remove;
	fancyBorderLocations = "" + innerBorder + "|" + outerBorder + "|" + centerBorder;
	call("ij.Prefs.set", "fancy.borderLocations", fancyBorderLocations);
	 /* save last used settings in user in preferences */
	call("ij.Prefs.set", "fancy.innerBorderColor", innerBorderColor);
	innerBorderColorHex = getHexColorFromRGBArray(innerBorderColor);
	call("ij.Prefs.set", "fancy.outerBorderColor", outerBorderColor);
	outerBorderColorHex = getHexColorFromRGBArray(outerBorderColor);
	call("ij.Prefs.set", "fancy.centerBorderColor", centerBorderColor);
	centerBorderColorHex = getHexColorFromRGBArray(centerBorderColor);
	expSelI = -round(innerBorderThickness/2);
	expSelO = round(outerBorderThickness/2);
	/* If Overlay chosen add fancy border as overlay */
	if (endsWith(overWrite,"verlays")){
		run("Restore Selection");
		if (innerBorder) {
			getSelectionFromMask("selection_mask");
			run("Enlarge...", "enlarge=&expSelI pixel");
			setSelectionName("Fancy inner border");
			Overlay.addSelection(innerBorderColorHex, innerBorderThickness);
		}
		if (outerBorder) {
			getSelectionFromMask("selection_mask");
			run("Enlarge...", "enlarge=&expSelO pixel");
			setSelectionName("Fancy outer border");
			Overlay.addSelection(outerBorderColorHex, outerBorderThickness);
		}
		if (centerBorder) {
			getSelectionFromMask("selection_mask");
			setSelectionName("Fancy center border");
			Overlay.addSelection(centerBorderColorHex, centerBorderThickness);
		}
	}
	else {
		if (startsWith(overWrite,"Destructive overwrite")) {
			tS = originalImage;
		}
		else {
			tS = "" + stripKnownExtensionFromString(unCleanLabel(originalImage)) + "+selBrdr";
			run("Select None");
			selectWindow(originalImage);
			run("Duplicate...", "title=&tS duplicate");
			run("Restore Selection");
		}
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
		}
		if(selEType==0) {
			if (innerBorder) {
				setColor(innerBorderColorHex);
				setLineWidth(innerBorderThickness);
				drawRect(selEX-expSelI, selEY-expSelI, selEWidth+2*expSelI, selEHeight+2*expSelI);
			}
			if (outerBorder) {
				setColor(outerBorderColorHex);
				setLineWidth(outerBorderThickness);
				drawRect(selEX-expSelO, selEY-expSelO, selEWidth+2*expSelO, selEHeight+2*expSelO);
			}
			if (centerBorder) {
				setColor(centerBorderColorHex);
				setLineWidth(centerBorderThickness);
				drawRect(selEX, selEY, selEWidth, selEHeight);
			}
		}
		if(selEType==1) {
			if (innerBorder) {
				setColor(innerBorderColorHex);
				setLineWidth(innerBorderThickness);
				drawOval(selEX-expSelI, selEY-expSelI, selEWidth+2*expSelI, selEHeight+2*expSelI);
			}
			if (outerBorder) {
				setColor(outerBorderColorHex);
				setLineWidth(outerBorderThickness);
				drawOval(selEX-expSelO, selEY-expSelO, selEWidth+2*expSelO, selEHeight+2*expSelO);
			}
			if (centerBorder) {
				setColor(centerBorderColorHex);
				setLineWidth(centerBorderThickness);
				drawOval(selEX, selEY, selEWidth, selEHeight);
			}
		}
	}
	restoreSettings();
	getSelectionFromMask("selection_mask");
	closeImageByTitle("selection_mask");
	setBatchMode("exit & display"); /* exit batch mode */
	showStatus("Fancy Borders Added");
}
	/*
		( 8(|)  ( 8(|)  Functions	@@@@@:-)	@@@@@:-)
	*/
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
	function getColorArrayFromColorName(colorName) {
		/* v180828 added Fluorescent Colors
		   v181017-8 added off-white and off-black for use in gif transparency and also added safe exit if no color match found
		   v191211 added Cyan
		   v211022 all names lower-case, all spaces to underscores v220225 Added more hash value comments as a reference
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
	function setBackgroundFromColorName(colorName) {
		colorArray = getColorArrayFromColorName(colorName);
		setBackgroundColor(colorArray[0], colorArray[1], colorArray[2]);
	}
	/* Hex conversion below adapted from T.Ferreira, 20010.01 http://imagejdocu.tudor.lu/doku.php?id=macro:rgbtohex */
	function pad(n) {
	  /* This version by Tiago Ferreira 6/6/2022 eliminates the toString macro function */
	  if (lengthOf(n)==1) n= "0"+n; return n;
	  if (lengthOf(""+n)==1) n= "0"+n; return n;
	}
	
	function getHexColorFromRGBArray(colorNameString) {
		colorArray = getColorArrayFromColorName(colorNameString);
		 r = toHex(colorArray[0]); g = toHex(colorArray[1]); b = toHex(colorArray[2]);
		 hexName= "#" + ""+pad(r) + ""+pad(g) + ""+pad(b);
		 return hexName;
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
	function restoreExit(message){ /* Make a clean exit from a macro, restoring previous settings */
		/* 9/9/2017 added Garbage clean up suggested by Luc LaLonde - LBNL */
		restoreSettings(); /* Restore previous settings before exiting */
		setBatchMode("exit & display"); /* Probably not necessary if exiting gracefully but otherwise harmless */
		run("Collect Garbage");
		exit(message);
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