//This macro contains steps to process and segment lipid droples from 20x images of c2c12 myoblasts in 12-well_plates


rename("lipid1");
run("Duplicate...", "title=lipid2");
run("Remove Outliers...", "radius=10 threshold=50 which=Bright");
imageCalculator("Subtract create", "lipid1","lipid2");
rename("lipidRes");
setAutoThreshold("MaxEntropy");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Remove Outliers...", "radius=0.5 threshold=1 which=Bright");
run("Invert");
run("Watershed");
close("lipid1");
close("lipid2");
selectWindow("lipidRes");