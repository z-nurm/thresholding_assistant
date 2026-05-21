	/* DESCRIPTION:
	 *  
	 *  	An interactive Fiji/ImageJ macro that helps to determine optimal intensity threshold values 
	 *  	for multi-channel fluorescence images, which might be needed in subsequent processing. 
	 * 		It randomly samples a user-defined number (by default, 5) of .tif images from the input 
	 *  	directory, and processes each channel separately. It applies an initial automatic threshold, 
	 *  	and displays a side-by-side montage of the original and thresholded channel, and prompts the user 
	 *  	to accept or manually adjust the threshold values over another iteration. Accepted threshold 
	 *  	values are accumulated across all inspected images and averaged to get a final per-channel 
	 *  	threshold value, which is displayed in the session-info window and saved as a .txt file.
	 *  
	 * How-to:
	 * 		1. Run the macro via Plugins > Macros > Run, or drag the .ijm file into the Fiji toolbar
	 * 		2. In the opening dialog: Select the input directory containing .tif images,
	 * 		enter the total number of channels in the images, set the sample size (how many 
	 * 		randomly selected images to review) and check "Skip Ch1 thresholding" if 
	 * 		Channel 1 (e.g. DAPI) should be excluded. 
	 * 		3. For each sampled image, the macro thresholds channels using Intermodes 
	 * 		and displays a montage of the originals alongside the thresholded result.
	 * 		A dialog asks whether to iterate: click "Yes" to manually adjust threshold values, 
	 * 		or "No" to accept the current result and move on to the next image/conclude the macro.
	 * 		Afterwards, a second dialog asks whether to continue to the next image ("Yes") 
	 * 		or stop and finalize ("No") the macro.
	 * 		4. Once stopped, the macro computes the mean threshold per channel across all accepted 
	 * 		estimates, prints them, and saves a session log to the parent directory.
	 * 		
	 * Features:
	 * 		1. Adjustable sample size and channel count via opening menu
	 * 		2. Randomly selects images from the input directory for a valid threshold estimate
	 * 		3. Optional skipping of Channel 1 (typically a channel such as DAPI)
	 * 		4. Includes image processing to reduce noise 
	 * 		5. First iteration uses Intermodes thresholding as a starting estimate; 
	 * 			subsequent iterations require adjusted values
	 * 		6. Side-by-side montage display (original vs. thresholded) for visual inspection
	 * 		7. Thresholds are refined iteratively, until a satisfactory result is obtained
	 * 		9. Final estimate is the rounded mean of accepted per-channel thresholds
	 * 		10. Session-info log records per-iteration threshold values, and final estimates, 
	 * 			saved as a timestamped .txt file in the parent directory
	 * 		
	 * Limitations:
	 * 		1. May not work on MacOS
	 * 		2. Works only on ".tif" images
	 * 		3. Channel processing is hardcoded and may need to be readjusted
	 * 		4. If any macro dialog is canceled, the final estimate might not be obtained
	 * 		5. Non-standard stack arrangements can produce incorrect channel assignments
	 * 
	 * Note: it is recommended to go through at most 3 iterations per image and 
	 * at least 3 different images in total.
	 * 
	 * Requirements: 
	 * 		1. Fiji (Fiji is just ImageJ) version 1.54p or plain ImageJ
	 * 		2. Java version - 21.0.7 (64-bit)
	 * 		(*Tested on Linux Mint, 22.4)
	 * 
	 * Developed by Zafar Nurmatov in April, 2026 at the University of Bonn
	 */

	var iter_state = ""; var round_num = 1;
	var macro_state = "";
	var	temp_est = newArray(); var final_buffer = newArray();
	var current_estimate = newArray(); var final_estimate = newArray();
	var	inter_estimate = newArray(); var trash = newArray();
	//var lower = 0; var upper = 0;

macro "Thresholding Help" {
	
	// Initial dialog
	Dialog.create("Thresholding Assistant");
	Dialog.addDirectory("The input directory", "", 15);
	Dialog.addNumber("Total number of channels", 3);
	Dialog.addNumber("Sample Size", 5);
	Dialog.addCheckbox("Skip Ch1 thresholding", true);
	Dialog.addCheckbox(" Adjust image processing?", false);
	Dialog.show();
	inputDir = Dialog.getString();
	target_num = Dialog.getNumber();
	sample_size = Dialog.getNumber();
	ch1_stat = Dialog.getCheckbox();
	proc_set = Dialog.getCheckbox();
	parentDir = File.getDirectory(inputDir);
	inputFolder = File.getName(inputDir);
	if (inputDir == "") {
		exit("Error: No input folder provided");
	}
	if (target_num == 0) {
		exit("Error: No targets provided");
	}
	if (ch1_stat == true) {
			ch1_counter = 1;
		} else {
			ch1_counter = 0;
	}
	
	setOption("ScaleConversions", true);
	run("Options...", "iterations=1 count=1 black do=Nothing");
	var current_estimate = newArray(target_num - ch1_counter);
	current_estimate = Array.fill(current_estimate, 0);

	// Concludes the macro by calculating final thresholds
	function finalize() {
		for (i = 0; i < target_num - ch1_counter; i++) {
			temp_array = newArray();
			for (k = 0; k < final_buffer.length; k++) {	
				if (k % (target_num - ch1_counter) == i) {
					temp_array[temp_array.length] = final_buffer[k];
				}
			}
			Array.getStatistics(temp_array, min, max, mean, stdDev);
			final_estimate[final_estimate.length] = round(mean);
		}
	}
	
	// Pop-up window 1
	function iter_pop_up() {
		Dialog.create("Attention!");
		Dialog.addMessage("Adjust the thresholds on this image again?"+ 
	 	"\nYes, go through one more iteration.\nNo, go to the next image/stop"+
		"\nCancel to abort the macro");
		Dialog.enableYesNoCancel("Yes", "No");
		Dialog.show;
		iter_state = Dialog.getYesNoCancel;
	}
	
	// Pop-up window 2
	function macro_pop_up() {
		Dialog.create("Attention!");
		Dialog.addMessage("Continue adjusting the thresholds?"+ 
	 	"\nYes, go the next image.\nNo, stop and conclude the process"+
		"\nCancel to abort the macro");
		Dialog.enableYesNoCancel("Yes", "No");
		Dialog.show;
		macro_state = Dialog.getYesNoCancel;
	}

	// Adds accepted threshold values to the temporary array
	function est_update() { 
		for (i = 1; i <= target_num - ch1_counter; i++) {
			final_buffer[final_buffer.length] = current_estimate[i - 1];
		} 
	}	

	// Chooses only .tif images from the input directory
	function isTiff(filename) { 
		valid = false;
		if (filename.matches(".*.tif")) {
			valid = true;
		}
		return valid;
	}	
	
	// Adds a zero to the left of a single-digit number
	function padding_two_digits(number) {
		if (number >= 10) {
			return number;
		} else {
			number = "0" + toString(number);
			return number;
		}
	}
	
	function isInArray(num, ar) {
		stat = false;
		for (i = 1; i <= ar.length; i++) {
			if (ar[i - 1] == num) {
				stat = true;
				break
			}
		}
		return stat;
	}
	
	function iterate() {
		Dialog.create("Adjust the thresholds");
		string = String.join(newArray("Channel", "Threshold"), "       ");
		Dialog.addMessage(string, 14);
		for (i = 1 + ch1_counter; i <= target_num; i++) {
			Dialog.setInsets(5, 10, 3); 
			Dialog.addNumber("_", i);
			Dialog.addToSameRow();  
			Dialog.addNumber("_", current_estimate[i - ch1_counter - 1]);
		}
		Dialog.show();
		for (i = 1 + ch1_counter; i <= target_num; i++) {
			trash[trash.length] = Dialog.getNumber();
			current_estimate[i - ch1_counter - 1] = Dialog.getNumber();
		}
	}
	
	function thresholding() {
		if (current_estimate[i - ch1_counter - 1] == 0) {
			setAutoThreshold("Intermodes dark raw");
			getThreshold(lower, upper); 
			current_estimate[i - ch1_counter - 1] = parseInt(lower);
		} else {
			lower = current_estimate[i - ch1_counter - 1];
			setThreshold(lower, 255, "dark raw");
		}
				
		run("Despeckle");
		run("Median...", "radius=5");
		run("Make Binary");
				
		if ((ch1_stat == false) && (getTitle() == "C1-Thresholded")) {
			run("Fill Holes");
			run("Watershed");
		}
	}
	
	function img_processing() {
		setOption("BlackBackground", true);
		setBatchMode(true);
		round_num = 1;
		while (round_num != 0) {
			
			if (round_num == 1) {
				current_estimate = Array.fill(current_estimate, 0);
				original_title = getInfo("image.title");
				print("Image: " + original_title);
				selectWindow(original_title);
				run("Select None");
				selectWindow(original_title);
				run("8-bit");
				run("Duplicate...",  "ignore duplicate");
				rename("Channel"); 
				run("Stack to Images");
				if (ch1_stat == true) {
					close("Channel-0001"); 
				}
				close(original_title);
			} 
			
			if (round_num != 1) {
				iterate();
			}
			
			for (i = 1 + ch1_counter; i <= target_num; i++) { 
				selectWindow("Channel-00"+ padding_two_digits(i)); 
				run("Duplicate...",  "ignore duplicate");
				rename("C" + i + "-Thresholded");
				selectWindow("C" + i + "-Thresholded");
				
				thresholding();
				
				print("Iteration " + round_num + ", Channel " 
				+ i+ ", Threshold: " + current_estimate[i - ch1_counter - 1]);
				run("Concatenate...", "  title=[Channel " + i + "] keep image1=" +
				"Channel-00"+ padding_two_digits(i) + " image2=" + 
				"C" + i + "-Thresholded");
				selectWindow("C" + i + "-Thresholded");
				close();
				selectWindow("Channel " + i);
				run("Make Montage...", "columns=2 rows=1 scale=0.25 font=24 label");
				selectWindow("Montage"); rename("Montage " + i);
				setBatchMode("show");
			}		
			round_num += 1;
			iter_pop_up();
			if (iter_state == "yes") {
				print("\n");
				for (k = 1 + ch1_counter; k <= target_num; k++) { 
					close("Montage " + k);
					close("Channel " + k);
				}	
				continue;
			} else {
				est_update();
				round_num = 0;
			}
		} 	
	}
	
	function batch_processing(inputDir) { //
		
		setOption("BlackBackground", true);
		print("Note: it is recommended to go through at most 3 iterations"+"\n" 
			+ "per image and at least 3 different images in total." + "\n");
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		print("Start Time: ", month+1+ "/" + dayOfMonth + "/" + year, 
		padding_two_digits(hour) + ":" + padding_two_digits(minute));
		
		rand_selection = newArray();
		files = getFileList(inputDir);
		
		// Batch selection of random images (If possible)
		if (sample_size >= files.length) {
			sample_size = files.length;
			rand_selection = Array.getSequence(sample_size-1);
		} else {
			rand_selection[0] = round(random*(files.length-1));
			while (rand_selection.length < sample_size) {
				temp = round(random*(files.length-1));
				if (isInArray(temp, rand_selection) == false) {
					rand_selection[rand_selection.length] = temp;
				}
			}
		}
		
		for (i = 1; i <= sample_size; i++) {
			file_path = inputDir + files[rand_selection[i - 1]];
			if (isTiff(file_path)) {
				round_num = 1;
				setBatchMode(true);
				open(file_path);	
				img_processing();
				macro_pop_up();
				if ((macro_state == "yes") && (i != sample_size)) {
					print("\n");
					est_update();
					close("*");
					continue; // next image
				} else { 
					// conclude the entire process (macro-whole)
					if (i == sample_size) {
						est_update();
					}
					print("\n");
					close("*"); 
					finalize();
					print("Suggested thresholds: ", String.join(final_estimate));
					break;
				}
			}	
		} 
		
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		print("End Time: ", month+1+"/"+dayOfMonth+ "/"+ year, padding_two_digits(hour)+ ":"
		+ padding_two_digits(minute));
		session_info = getInfo("log");
		File.saveString(session_info, parentDir + inputFolder+ "_" + dayOfMonth + 
		"-"+ month+1+ "-"+year+"_" + padding_two_digits(hour) +"-" + padding_two_digits(minute) + 
		"_" + "thresholding_info.txt");	
		close("*");
		run("Collect Garbage");
	}
		
	batch_processing(inputDir); 
}