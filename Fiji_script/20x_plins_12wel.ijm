//This macro contains steps to process and segment plins2&5 from 20x images of c2c12 myoblasts in 12-well_plates

run("Subtract Background...", "rolling=50");
setAutoThreshold("Shanbhag");
run("Convert to Mask");
run("Remove Outliers...", "radius=0.5 threshold=1 which=Bright");
run("Invert");