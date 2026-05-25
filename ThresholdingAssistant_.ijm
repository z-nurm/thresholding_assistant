
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