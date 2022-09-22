# asc-ImageJ-Fancy-Labels
<p>These label macros use outlines and shadows to create labels on images that stand out against the image underneath.</p>

<h4 id = "FancyScaleBar">Fancy Scale Bar</h4><p>This macro (<a href="https://github.com/peterjlee/asc-ImageJ-Fancy-Labels/blob/master/Fancy_Scale_Bar.ijm" Title = "Applied Superconductivity Center Fancy Scale Bar Macro Directory" >link</a>) adds extensive formatting options to the original version  by Wayne Rasband that was subsequently enhanced by<a href="https://imagej.588099.n2.nabble.com/Overlay-Scalebar-Plugins-td6380378.html#a6394996"> Frank Sprenger</a>. The scale bar can be an overlay or applied to the original or a copy of the image. If the image is in color there are multiple color options (the selection is restricted to grayscale choices for grayscale images to retain the original bit depth). The units can be changed from the original embedded scale (i.e. from nm to &micro;m etc.).</p><p>
<img src="/images/ASC_Fancy_Scale_Bar_1302x267Anim.gif" alt="Examples of ASC Fancy Scale Bar for ImageJ">
 </p>
 
<p>Using the line selection tool the precise length and angle can be shown (single or multiple arrows can be used):</p>
    
<p><img src="/images/F-ScaleBar_Arrows_Length_Angle_1024x182.jpg" alt="Example of Fancy Scale Bar used to label length and angle" width="512" /></p> 

<p>If a line selection tool is used the text can be rotated to the measured angle and arbitray text can be used for the label.</p>
 
<h4 id = "FastnFancyScaleBarRerun">Fast'nFancy Scale Bar Rerun</h4><p>
  Variant of the Fancy Scale Bar macro that creates a copy of the active image with a fancy scale bar without any user interaction. It will use preferences saved by the Fancy Scale Bar macro.</p>
  
<h4 id = "FancySummaryTable" >Fancy Summary Label Table</h4><p>This macro (<a href="https://github.com/peterjlee/asc-ImageJ-Fancy-Labels/blob/master/Fancy_Summary_Table.ijm" Title = "Applied Superconductivity Center Fancy Summary Table Label Macro Directory" >link</a>) adds up to 8 lines of statistical summary to an image. There are extensive formatting options including outlines and shadows to help the text stand out against the image. If the image is in color there are multiple color options.</p><p><img src="/images/fancy_summary_table_example_Daeq_gng_512x170.png" alt="ASC Fancy Summary Table Label example" width="512" /></p>

<h4 id = "FancyTextLabels">Fancy Text Labels</h4><p>This macro (<a href="https://github.com/peterjlee/asc-ImageJ-Fancy-Labels/blob/master/Fancy_Text_Labels.ijm" Title = "Applied Superconductivity Center Fancy Text Label Macro Directory" >link</a>) adds up to 8 lines of user created text to an image. There are extensive formatting options including outlines and shadows to help the text stand out against the image. If the image is in color there are multiple color options.</p><p><img src="/images/FancyTextLabels_ColorExample_512x92.gif" alt="ASC Fancy Text Label example" width="512" /></p>

<h4 id = "FancySliceLabels">Fancy Slice Labels</h4>
<p>This macro (<a href="https://github.com/peterjlee/asc-ImageJ-Fancy-Labels/blob/master/Fancy_Slice_Labels.ijm" Title = "Applied Superconductivity Center Fancy Text Label Macro Directory" >link</a>) adds multiple lines of text to a copy of the image. Sequential numbers can be added as well as prefixes and suffixes. Text in the slice labels can be globally replaced. Non-formated slice labels can be applied with more counter variables and previews to images using ImageJ's "Label Stacks" and Dan White's (MPI-CBG) "Series Labeler", so you might want to try that more sophisticated programming first to see if it meets your needs sufficiently. You can also try utilize imageJ's "stack sorter."</p>
    
<p><img src="/images/FancySliceLabels_Menus_839x520_pal32.png" alt="ASC Fancy Slice Label menus" width="839" /></p>
<p><img src="/images/FancySliceLabels_Example_451x172.gif" alt="Fancy Slice Label example" width="451" /></p>Magneto optical images by Anatolii Polyanskii.
<p><sub><sup>
 <strong>Legal Notice:</strong> <br />
These macros have been developed to demonstrate the power of the ImageJ macro language and we assume no responsibility whatsoever for its use by other parties, and make no guarantees, expressed or implied, about its quality, reliability, or any other characteristic. On the other hand we hope you do have fun with them without causing harm.
<br />
The macros are continually being tweaked and new features and options are frequently added, meaning that not all of these are fully tested. Please contact me if you have any problems, questions or requests for new modifications.
 </sup></sub>
</p>


<h4 id = "Fancy_Feature_Labeler">Fancy Feature Labeler</h4>
<p>This macro (<a href="https://github.com/peterjlee/asc-ImageJ-Fancy-Labels/blob/master/Fancy_Feature_Labeler.ijm" Title = "Applied Superconductivity Center Fancy Feature Labeler Macro" >link</a>) adds scaled result labels to each ROI object.</p>
<p><img src="/images/Bronze-Nb3Sn_FFL_sub_ID_717x135crop.png" alt="ASC Fancy Feature Label example" width="717" /></p>

<h4 id = "FancyFeatureLabelerSummary">Fancy Feature Labeler with Summary</h4>
<p>This macro (<a href="https://github.com/peterjlee/asc-ImageJ-Fancy-Labels/blob/master/Fancy_Feature_Labeler+Summary.ijm" Title = "Applied Superconductivity Center Fancy Feature Labeler Macro" >link</a>) adds scaled result labels to each ROI object and a summary of selected statistics.</p>
<p><img src="/images/Bronze-Nb3Sn_FFL_Dp_512x160_anigif.gif" alt="ASC Fancy Feature Label example" width="512" /></p>

<h4 id = "FancyBorders">Fancy Border</h4>
<p>This macro (<a href="https://github.com/peterjlee/asc-ImageJ-Fancy-Labels/blob/master/Fancy_Border.ijm" Title = "Applied Superconductivity Center Fancy Border Macro" >link</a>) adds a color border to a selection. The border can consist of up to 3 layers of different thickness and can be a non-destructive overlay.</p>
<p><img src="/images/Fancy_Borders_anigif_270x223_v190506.gif" alt="ASC Fancy Border example" width="270" /></p>
