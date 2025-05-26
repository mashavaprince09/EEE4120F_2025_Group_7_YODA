`timescale 1ns/1ns

module read_image #(
	parameter	WIDTH = 512,
				HEIGHT = 512,
				START_UP_DELAY = 100,
				MAX_SIZE = 512*512,
				FILENAME = "img/mage.hex"
)(
	input clock,			// Clock for timing the code.
	input startFlag,		// Flag starting the entire edge detection operation.
	input reset,			// Flag for resetting the entire module.
	output [7:0] pixel,		// Used to stream out the output as bytes
	output sendFlag,		// Flag used to allert the testbench that data is ready to be sent out
	output doneFlag			// Flag used to allert the testbench that all the data has been sent out
);

	//-------------------TIMING ROUTINES---------------------------------
	time t_start;	// Stores the start time of the critical section
	time t_end;		// Stores the end time of the critical section
	time duration;	// Stores the duration of the critical section
	//-------------------------------------------------------------------

	reg [7:0] pixel;						// Used to stream out the output as bytes.
	reg [7:0] img2 [0:WIDTH-1][0:HEIGHT-1];	// Block of memory that stores the median Filtered result.
	reg [7:0] img [0:WIDTH-1][0:HEIGHT-1];	// Block of memory that that stores the image read in from an external file.
	reg sendFlag;							// Flag used to allert the testbench that data is ready to be sent out.
	reg doneFlag;							// Flag used to allert the testbench that all the data has been sent out.
	reg medianFlag;							// Internal flag used to signal that median filtering should commence.

	reg [9:0] i,j; // Indices used to send out Filtered bits

	reg []

	//-------------- Median_Filter_Variables-------------------------------
	reg [7:0] sorter [0:8];		// Array used to store elements that are to be sorted
	reg [8:0] k1,k2;			// Indices used for sorting
	//---------------------------------------------------------------------


	//---------------------SOBEL FILTER VARIABLES-----------------------------
		reg [7:0] p00, p01, p02;   // Top row pixels
		reg [7:0] p10, p11, p12;   // Middle row pixels
		reg [7:0] p20, p21, p22;   // Bottom row pixels

		// Internal registers for Gx and Gy calculations
		reg signed [11:0] gx, gy;         // 12-bit signed for intermediate results
		reg [11:0] abs_gx, abs_gy;        // Absolute values
		reg [11:0] magnitude_sum;        // Sum of absolute values

		parameter threshold = 150;         // Edge threshold
	//------------------------------------------------------------------------

	// Resets the bits when reset flag is high
	always @(reset) begin
		medianFlag = 0;
		i=0;
		j=0;
		sendFlag = 0;
		doneFlag = 0;
		k1 = 0;
		k2 = 0;
	end

	// Read Hexadecimal values into array
	// Does not share the same clock as the rest of the system
	always @(posedge startFlag && !reset) begin
		$readmemh(FILENAME, img, 0, MAX_SIZE-1); 	// reads data from text file
		#2097152; 									// serial communication overhead
		medianFlag = 1;								// Start Medain Filtering
		t_start = $time;							// Critical section time
	end


	// Median Filtering below
	//--------------------------------------------------------------------------------
	always @(posedge clock && medianFlag && !reset) begin
		i=0;
		j=0;
		k1 = 0;
		k2 = 0;
		for (i = 0; i < HEIGHT; i = i + 1) begin
            for (j = 0; j < WIDTH; j = j + 1) begin

				if(i==0 || i == HEIGHT-1 || j==0 || j==WIDTH-1) begin // Edge Bits are left Unfiltered.
					img2[i][j] = img[i][j];
				end
				else begin

					sorter[0] = img[i-1][j-1]; sorter[1] = img[i][j-1]; sorter[2] = img[i+1][j-1];
					sorter[3] = img[i-1][j]; sorter[4] = img[i][j]; sorter[5] = img[i+1][j];	
					sorter[6] = img[i-1][j+1]; sorter[7] = img[i][j+1]; sorter[8] = img[i+1][j+1];

					for (k1 = 0; k1 < 8; k1 = k1 + 1) begin
						for (k2 = 0; k2 < 8; k2 = k2 + 1) begin
							if (sorter[k2] > sorter[k2+1]) begin

								// Swap values
								sorter[k2] = sorter[k2] ^ sorter[k2+1];
								sorter[k2+1] = sorter[k2] ^ sorter[k2+1];
								sorter[k2] = sorter[k2] ^ sorter[k2+1];
							end
						end
					end

					img2[i][j] = sorter[4];	// Get the medain value
				end
			end
		end
	
	medianFlag = 0; // Reset bit once operation is done.
	sendFlag = 1;
	i = 0;
	j=0;
	end
	//--------------------------------------------------------------------------------





	// Clock Synchronized
	// Sends out stored bits one at a time (serail) at clock rate
	// Firtly executes the median filtering and then sends out the result to 
	always @(posedge clock && sendFlag && !reset)begin
		if(i == HEIGHT) begin
			doneFlag = 1;
			sendFlag = 0;
			t_end = $time;
			duration = t_end-t_start;
			$display("Critical Time: %0t ns", duration); // outputs the critical section time.
		end else if(i==0 || i == HEIGHT-1 || j==0 || j==WIDTH-1) begin
			pixel = 0;	// For edge pixels, just output zeros
		end else begin

			// Set pixels
			p00 = img2[i-1][j-1]; p01 = img2[i][j-1]; p02 = img2[i+1][j-1];
			p10 = img2[i-1][j]; p11 = img2[i][j]; p12 = img2[i+1][j];	
			p20 = img2[i-1][j+1]; p21 = img2[i][j+1]; p22 = img2[i+1][j+1];

			// Gx = [-1 0 1; -2 0 2; -1 0 1] * window
			gx = (p02 + (p12 << 1) + p22) - (p00 + (p10 << 1) + p20);
			
			// Gy = [-1 -2 -1; 0 0 0; 1 2 1] * window
			gy = (p20 + (p21 << 1) + p22) - (p00 + (p01 << 1) + p02);
			
			// Calculate absolute values
			abs_gx = (gx < 0) ? -gx : gx;
			abs_gy = (gy < 0) ? -gy : gy;

			// Approximate the magnitude using manhatton distance
			magnitude_sum = abs_gx + abs_gy;

			// Thresholding to make sure non-edges are ignored.
			pixel = (magnitude_sum > threshold) ? 255 : 0;
		end

		// Increment loop variables 
		if(j == WIDTH-1) begin // Last element of the the row
			j = 0;
			i = i+1;			// Go to the next column
		end else begin
			j = j+1;		// Go to next element in row
		end

	end



endmodule

// TestBench Below

module tb;

	parameter outputFile = "out/sobel.hex"; // output file

	reg clk; // Global clock. Everything is synchronized on this clock.
	reg sobel_clk; // Clock for just the sobel filter.

	reg startFlag, reset;		// Flags used by the read_file module
	wire[7:0] pixel_stream;		// Bus used to get bits from the 
	wire doneFlag;
	wire sendFlag; // Signals the end of the program

	integer file; // Used for file io (output hex file)
	integer temp; // For for delaying the termination of the program.
	integer pew; // used to ensure proper handshaking

	initial begin // Async.
		pew = 0;
		reset = 1;
		temp = 0;
		clk = 0;
		#4 reset = 0;	// Start-up time
		startFlag = 1; // Signals the reader to start processing
		#5; // Longer than 1 clock cycle to ensure that signal is not missed.
		startFlag = 0; // Preserve power
		file = $fopen(outputFile, "w"); // Ouput hex file
	end


	// Exits the program
	always @(posedge clk && doneFlag)begin
		if(temp > 5)begin // Wait 5 clock cycles
			$fclose(file);

			$display("Total_Time: %0t ns", $time); // outputs the total simulation time
			$finish;
		end
		temp <= temp+1;
	end

	
	// Exports output to external file one pixel at a time (serail)
	always @(posedge clk && sendFlag) begin
		if(pew != 0) $fwrite(file, "%0h\n", pixel_stream); // Export to external file.
		else pew = pew+1; // Ignore the first sample
	end

	// The system clock
	always begin
		#1 clk = ~clk;	// Period = 2ns
	end


	// connect to the read_image module
	read_image r1(
		.startFlag(startFlag),
		.pixel(pixel_stream),
		.doneFlag (doneFlag),
		.clock (clk),
		.sendFlag (sendFlag),
		.reset(reset)
	);

endmodule
