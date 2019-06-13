run("Gaussian Blur...", "sigma=1");
run("Subtract Background...", "rolling=50");
setAutoThreshold("Mean");
run("Convert to Mask");
run("Invert");
run("Remove Outliers...", "radius=10 threshold=50 which=Dark");
run("Erode");
run("Fill Holes");
run("Watershed");
run("Invert");

//filter out small non-round objects
run("Shape Filter", "area=75-infinity area_convex_hull=0-Infinity perimeter=0-Infinity perimeter_convex_hull=10-1000 feret_diameter=0-Infinity min._feret_diameter=0-Infinity max._inscr._circle_diameter=0-Infinity area_eq._circle_diameter=0-Infinity long_side_min._bounding_rect.=0-Infinity short_side_min._bounding_rect.=0-Infinity aspect_ratio=1-Infinity area_to_perimeter_ratio=0-Infinity circularity=0-Infinity elongation=0-1 convexity=0-1 solidity=0-1 num._of_holes=0-Infinity thinnes_ratio=0-1 contour_temperatur=0-1 orientation=0-180 fractal_box_dimension=0-2 option->box-sizes=2,3,4,6,8,12,16,32,64");