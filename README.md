<h3> Description  </h3>
An interactive Fiji/ImageJ macro that helps to determine optimal intensity threshold values for multi-channel fluorescence images, which might be needed in subsequent processing. It randomly samples a user-defined number (by default, 5) of .tif images from the input directory, and processes each channel separately. It applies an initial automatic threshold, and displays a side-by-side montage of the original and thresholded channel, and prompts the user to accept or manually adjust the threshold values over another iteration. Accepted threshold values are accumulated across all inspected images and averaged to get a final per-channel threshold value, which is displayed in the session-info window and saved as a .txt file.<br>


<h3> Workflow </h3>
1. Run the macro via Plugins > Macros > Run, or drag the .ijm file into the Fiji toolbar<br>
2. In the opening dialog: Select the input directory containing .tif images, enter the total number of channels in the images (e.g. three channels),
set the sample size (how many randomly selected images to review) and check "Skip Ch1 thresholding" if Channel 1 (e.g. DAPI) should be excluded. <br>
3. For each sampled image, the macro thresholds channels using Intermodes and displays a montage of the originals alongside the thresholded result.
A dialog asks whether to iterate: click "Yes" to manually adjust threshold values, or "No" to accept the current result and move on to the next image/conclude 
the macro. Afterwards, a second dialog asks whether to continue to the next image ("Yes") or stop and finalize ("No") the macro.<br>
4. Once stopped, the macro computes the mean threshold per channel across all accepted estimates, prints them, and saves a session log to the parent directory.

<h3> Features </h3>
1. Adjustable sample size and channel count via opening menu<br>
2. Randomly selects images from the input directory for a valid threshold estimate<br>
3. Optional skipping of Channel 1 (typically a channel such as DAPI)<br>
4. Includes image processing to reduce noise <br>
5. First iteration uses Intermodes thresholding as a starting estimate; subsequent iterations require adjusted values<br>
6. Side-by-side montage display (original vs. thresholded) for visual inspection<br>
7. Thresholds are refined iteratively, until a satisfactory result is obtained<br>
9. Final estimate is the rounded mean of accepted per-channel thresholds<br>
10. Session-info log records per-iteration threshold values, and final estimates, saved as a timestamped .txt file in the parent directory<br>
  
<h3> Limitations </h3>
1. May not work on MacOS<br>
2. Works only on ".tif" images<br>
3. Channel processing is hardcoded and may need to be readjusted<br>
4. If any macro dialog is canceled, the final estimate might not be obtained<br>
5. Non-standard stack arrangements can produce incorrect channel assignments<br>
<br>
Note: it is recommended to go through at most 3 iterations per image and at least 3 different images in total. <br>


<h3> Requirements </h3>
1. Fiji (Fiji is just ImageJ) version 1.54p or plain ImageJ<br>
2. Java version - 21.0.7 (64-bit)<br>
(Tested on Linux Mint, 22.4)<br>
<br>

*Developed by Zafar Nurmatov in April, 2026 at the University of Bonn*


