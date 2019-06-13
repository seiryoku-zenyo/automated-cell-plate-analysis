//This macro contains steps to process and segment MF-20 positive cells (myotubes) from 20x images of c2c12 in 12-well_plates

//run("Subtract Background...", "rolling=50");
run("Gaussian Blur...", "sigma=1");
setAutoThreshold("Li");
run("Convert to Mask");
run("Remove Outliers...", "radius=0.5 threshold=1 which=Bright");
run("Invert");
run("Dilate");