
//------------------------------------------------------------------------
//                       Global Variables & Instances
//------------------------------------------------------------------------

DataProcessing_User dataProcessing_user;
boolean drawEMG = false; //if true... toggles on EEG_Processing_User.draw and toggles off the headplot in Gui_Manager
boolean drawAccel = false;
boolean drawPulse = false;
boolean drawFFT = true;
boolean drawBionics = false;
boolean drawHead = true;


String oldCommand = "";
boolean hasGestured = false;

//------------------------------------------------------------------------
//                            Classes
//------------------------------------------------------------------------
class DetectedPeak { 
  int bin;
  float freq_Hz;
  float rms_uV_perBin;
  float background_rms_uV_perBin;
  float SNR_dB;
  boolean isDetected;
  float threshold_dB;
 
  DetectedPeak() {
    clear();
  }

  void clear() {
    bin=0;
    freq_Hz = 0.0f;
    rms_uV_perBin = 0.0f;
    background_rms_uV_perBin = 0.0f;
    SNR_dB = -100.0f;
    isDetected = false;
    threshold_dB = 0.0f;
  }

  void copyTo(DetectedPeak target) {
    target.bin = bin;
    target.freq_Hz = freq_Hz;
    target.rms_uV_perBin = rms_uV_perBin;
    target.background_rms_uV_perBin = background_rms_uV_perBin;
    target.SNR_dB = SNR_dB;
    target.isDetected = isDetected;
    target.threshold_dB = threshold_dB;
  }
}

class DataProcessing_User {
  private float fs_Hz;  //sample rate
  private int n_chan; //Same as nchan in EEG_Processing, except it is named n_chan.
  DetectedPeak[] detectedPeak;
  DetectedPeak[] peakPerBand;
  int cd; //Takes a look at whether or not cd is equal
  final int TOTAL_TRIALS = 25; //# flashes per letter * total amount of letters.
  final int NUM_CHANNELS_USED = 4;
  final int NUM_OF_TRIALS = 5; //NUMBER OF TRIALS FOR TARGET DETECTION
  final int NUM_LETTERS_USED = 5;
  /*VARIABLES THAT KEEP TRACK OF TIMING*/
  int currentmillis = 0;
  int previousmillis = 0;
  int currentmillis_rate = 0; //Control the speed of the program.
  int previousmillis_rate = 0; //Control the speed of the program.
  final int maxruns_persecond = 24;
  int runs = 0;
  boolean wait = false; //If true, then it will not collect data. If false, then it will collect data.
  final int max_wait_runs = 5; //The amount of one second intervals that should be waited for.
  int wait_runs = 0;
  /*VARIABLES THAT HOLD DATA FOR EACH CHANNEL*/
  float[][][] rms = new float[24][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //24 samples since this part of the program is only called 240 times in 10 seconds, which is 24 times per second.
  float[][][] background_rms = new float[24][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //4 is the number of channels used.
  int sample_position = 0;
  int trial_count = 0; //Count the number of trials we have stored.
  int currentruncount = 0;
  int num_skips = 0;
  int num_completions = 0;
  //int[] sample_positions_ofletters;
  /*******************************************/
  boolean switchesActive = false;
  //Keep track of the time
  int sample_count = 0; //An amount we will divide by 10 in order to get the average sample_count.
  //Keep track of the previous_rand_index
  int previous_rand_index = 0; //LOOK AT THIS.
  //SET THE MAX DEVICES (amount of smart devices you have).
  final int MAX_DEVICES = 5;
  //final int time_per_target = 500; //Set the time spent at each target character to be equal to 500 ms. May need to be set differently depending on the time per character flash
  final float detection_thresh_dB = 6.0f;
  final float min_allowed_peak_freq_Hz = 7.9f;
  final float max_allowed_peak_freq_Hz = 12.1f;
  final float[] processing_band_low_Hz = {8.0};
  final float[] processing_band_high_Hz = {12.0};
  //TextToSpeak[] Device = new TextToSpeak[MAX_DEVICES]; //Dummy initialization
  //DEVICE NAMES BELOW, MODIFY TO SUIT THE NAMES WE WANT
  /*The first array element will be active during the first character, the second array element
  element will be active during the second character, and so on.*/
  //In the string array below, devices will correspond to the characters in the array from A to Z, with A representing the first element
  final String[] Devices = new String[]{"Test", "Plug", "One", "Two", "Three"}; //Test string incorporating the device names.

  Button leftConfig = new Button(3*(width/4) - 65,height/4 - 120,20,20,"\\/",fontInfo.buttonLabel_size);
  Button midConfig = new Button(3*(width/4) + 63,height/4 - 120,20,20,"\\/",fontInfo.buttonLabel_size);
  Button rightConfig = new Button(3*(width/4) + 190,height/4 - 120,20,20,"\\/",fontInfo.buttonLabel_size);



  //class constructor
  DataProcessing_User(int NCHAN, float sample_rate_Hz) {
    n_chan = NCHAN;
    fs_Hz = sample_rate_Hz;
    
    detectedPeak = new DetectedPeak[n_chan];
    for (int Ichan=0; Ichan<n_chan; Ichan++) detectedPeak[Ichan]=new DetectedPeak();

    int nBands = processing_band_low_Hz.length;
    
    peakPerBand = new DetectedPeak[nBands];
    for (int Iband=0; Iband<nBands; Iband++) peakPerBand[Iband] = new DetectedPeak();
    String Temp;
    for (int d=0; d<MAX_DEVICES; d++) {
       Device[d] = new TextToSpeak(); //Initialize each Device's TTS
       Initialize(Device[d], Devices[d]);
    }
    //sample_positions_ofletters = new int[25];
  }

  //add some functions here...if you'd like

  //here is the processing routine called by the OpenBCI main program...update this with whatever you'd like to do
  public void process(float[][] data_newest_uV, //holds raw bio data that is new since the last call
    float[][] data_long_uV, //holds a longer piece of buffered EEG data, of same length as will be plotted on the screen
    float[][] data_forDisplay_uV, //this data has been filtered and is ready for plotting on the screen
    FFT[] fftData) {              //holds the FFT (frequency spectrum) of the latest data

    //for example, you could loop over each EEG channel to do some sort of time-domain processing
    //using the sample values that have already been filtered, as will be plotted on the display
    float EEG_value_uV;
    currentmillis = millis();
    if(((currentmillis-previousmillis)/1000) >= 1) { //If a second has passed, enter.
      previousmillis=currentmillis;
      if(wait == true) { //If wait is true from detection, increment until we can begin again.
        wait_runs++;
        //println("Waiting...");
        if (wait_runs == max_wait_runs) { //Check if safe to run again.
          wait = false; //It is now safe to run again.
          wait_runs = 0;
        }
      }
      //println("Reset runs...");
    }
    if(w_p300speller.countdownCurrent == 0 && wait == false) { //If countdownCurrent is equal to 0, then we will begin data collection. It will only take samples as long as the number of runs per second is equal to 24.
      //println("Program rate is " + (sample_count/10));
      if(trial_count == 25) { //reset trial_count.
        println("Reset trial_count");
        trial_count = 0;
        sample_position = 0;
      }
      else {
        if(((w_p300speller.runcount)) != trial_count && sample_position > 0) {
          trial_count = w_p300speller.runcount;
          println("TRIALCOUNT IN DATAPROCESSING_USER IS NOW : " + trial_count);
          println("Skipping some data...");
          previous_rand_index = current_rand_index;
          //sample_positions_ofletters[trial_count] = sample_position;
          num_skips++;
          sample_position = 0;
        } 
      }
        if (sample_position < 24) { //Continue to collect data only if it has not finished that sample early.
        processMultiChannel(data_newest_uV, data_long_uV, data_forDisplay_uV, fftData);
        }
    } else {
      if(trial_count == 24) { //compensate for the lack of data and check anyways.
        CheckSNR();
      }
    }
    //else { //Dummy function to collect sample rate.
    //  println("Begin dummy function");
    //  processMultiChannelDummy(data_newest_uV, data_long_uV, data_forDisplay_uV, fftData);
    //  sample_count++;
    //}
    }


    
    //Monitors multiple channels and checks for what they do
  //public void processMultiChannelDummy(float[][] data_newest_uV, float[][]data_long_uV, float[][] data_forDisplay_uV, FFT[] fftData) {
  //  boolean isDetected = false;
  //  String txt = " ";
  //  if (sample_position < 250 && previous_rand_index < MAX_DEVICES) { //As long as previous_rand_index is equal to its initial value of 100 (or larger than MAX_DEVICES), it will not begin reading data (option 1), in this case, we have detection checks only when the index is less than MAX_DEVICES (5) 
  //   for(int Ichan = 0; Ichan < NUM_CHANNELS_USED; Ichan++) {
  //     println("Ichan is equal to " + Ichan);
  //     findPeakFrequency(fftData,Ichan);
  //   }
  //   sample_position++;
  //  } 
  //  else {
  //  //previous_rand_index = current_rand_index; 
  //  //if (sample_position == 24) { //Once 24 samples are taken, recollect starting at sample_position # 0. #trials will increase. This continues until trial_count reaches TOTAL TRIAL COUNT, at which point it will perform post-processing.
  //  //  sample_position = 0; //This makes the assumption that once it starts, the previous_rand_index will not become >= MAX_DEVICES.
  //  //  //trial_count++;
  //  //  num_completions++;
  //  //  println("Moving onto trial # " + trial_count);
  //  //}
  // }
  //}
  public void processMultiChannel(float[][] data_newest_uV, float[][]data_long_uV, float[][] data_forDisplay_uV, FFT[] fftData) {
    //currentmillis = millis(); //Refresh the amount of milliseconds the system has accumulated.
    boolean isDetected = false;
    String txt = " ";
    //println("Sample rate is " + cyton.getSampleRate());
    if (sample_position < 24 && previous_rand_index < MAX_DEVICES) { //As long as previous_rand_index is equal to its initial value of 100 (or larger than MAX_DEVICES), it will not begin reading data (option 1), in this case, we have detection checks only when the index is less than MAX_DEVICES (5) 
     for(int Ichan = 0; Ichan < NUM_CHANNELS_USED; Ichan++) {
       
       //println("Ichan = " + Ichan);
       findPeakFrequency(fftData,Ichan);
     }
     sample_position++;
     if(sample_position == 24) {
     num_completions++;
     }
    } else {
    //previous_rand_index = current_rand_index; 
    //if (sample_position == 24) { //Once 250 samples are taken, recollect starting at sample_position # 0. #trials will increase. This continues until trial_count reaches TOTAL TRIAL COUNT, at which point it will perform post-processing.
    //  sample_position = 0; //This makes the assumption that once it starts, the previous_rand_index will not become >= MAX_DEVICES.
    //  trial_count++;
    //  num_completions++;
    //  println("Moving onto trial # " + trial_count);
    //  //if (trial_count == TOTAL_TRIALS) //Assume that each letter flashes an equal amount of times (in this case, 5 flashes per letter, so 25 total flashes) 
    //  //{
    //  //  CheckSNR(); //Once we iterate through all trials, call CheckSNR to check the signal-to-noise ratio of the sampled data between certain sampling points.
    //  //} 
    // }
    }
  }
  
   void CheckSNR() {
     //Variables are displayed below for reference.
      //final int TOTAL_TRIALS = 25; //# flashes per letter * total amount of letters.
      //final int NUM_CHANNELS_USED = 4;
      //final int NUM_OF_TRIALS = 5; //NUMBER OF TRIALS FOR TARGET DETECTION
      //final int NUM_LETTERS_USED = 5;
      ///*VARIABLES THAT HOLD DATA FOR EACH CHANNEL*/
      //float[][][] rms = new float[250][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //250 samples because of 250 samples per second.
      //float[][][] background_rms = new float[250][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //4 is the number of channels used.
      //int sample_position = 0;
      //int trial_count = 0; //Count the number of trials we have stored.
      ///*******************************************/
      float SNR = 0;
      int hit_count[] = new int [NUM_LETTERS_USED];
      int letter_to_trigger;
      //Initialize
      //int hit_count[][] = new int[NUM_CHANNELS_USED][NUM_LETTERS_USED]; //Keep track of the hit for each channel and each character. A variant in case we need it.
      //Increment through all the data collected for each
      for(int letter_position = 0; letter_position < NUM_LETTERS_USED; letter_position++) {
      for(int t = 5; t < 10; t++) { //Checking samples of interest for the P300. //Check these samples for a spike at that time.
        for(int Ichan = 0; Ichan < 4; Ichan++) {
         SNR = 20.0f*(float)java.lang.Math.log10((rms[t][Ichan][letter_position]/NUM_OF_TRIALS)/(background_rms[t][Ichan][letter_position]/NUM_OF_TRIALS)); //Division by NUM_OF_TRIALS to get rid of low SNR experienced through averaging.
         
        //println("SNR : " + SNR);
         if (SNR > detection_thresh_dB) { //Maybe check for the EEG peak as well.
           hit_count[letter_position]++; //If SNR is above the threshold, then increment hit counts.
           println("Hit for letter position: " + letter_position + " at SNR: " + SNR);
         }
          //int index = 0;
          //for(int letter_position = 0; letter_position < 5; letter_position++) {
          //  if (rms[t][Ichan][letter_position] > max){
          //    max = rms[t][Ichan][letter_position]
          //    index
          //  }
          
          }
      }
      }
        letter_to_trigger = findLettertoDetect(hit_count); //Return the position of the letter to be triggered.
        println("Trigger on index letter of " + letter_to_trigger);
        VoiceCommand(letter_to_trigger);
      }
   
   int findLettertoDetect(int[] hit_count) { 
     //Algorithm to find the true letter that was actually detected by finding the letter with the maximum amount of hits.
     int hit_count_max = 0;
     int max_hit_counts_index=0;
     for(int letter_position = 0; letter_position < NUM_LETTERS_USED; letter_position++) { //5 represents the number of characters.
       if(hit_count[letter_position] > hit_count_max) {
         hit_count_max = hit_count[letter_position];
         max_hit_counts_index = letter_position;
       }
     }
     return max_hit_counts_index;
   }
   
   //Function to play voice commands.
   void VoiceCommand(int letter_to_trigger) {
     device_to_play = letter_to_trigger;
     thread("Trigger");
     println("Done with command");
     trial_count = 0;
     sample_position = 0;
     wait = true;
     println("Number of skips : " + num_skips);
     println("Number of completions : " + num_completions);
     //Reinitialize arrays.
     float[][][] rms = new float[24][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //24 samples since this part of the program is only called 240 times in 10 seconds, which is 24 times per second.
     float[][][] background_rms = new float[24][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //4 is the number of channels used.
   }
   
  //Finds Peak Frequency, among some other information. Taken from EEG Processing.
   void findPeakFrequency(FFT[] fftData, int Ichan) {

    //loop over each EEG channel and find the frequency with the peak amplitude
    float FFT_freq_Hz, FFT_value_uV;
    //for (int Ichan=0;Ichan < n_chan; Ichan++) {

    //clear the data structure that will hold the peak for this channel
    detectedPeak[Ichan].clear();

    //loop over each frequency bin to find the one with the strongest peak
    int nBins =  fftData[Ichan].specSize();
    for (int Ibin=0; Ibin < nBins; Ibin++) {
      FFT_freq_Hz = fftData[Ichan].indexToFreq(Ibin); //here is the frequency of htis bin

        //is this bin within the frequency band of interest?
      if ((FFT_freq_Hz >= min_allowed_peak_freq_Hz) && (FFT_freq_Hz <= max_allowed_peak_freq_Hz)) {
        //we are within the frequency band of interest

        //get the RMS voltage (per bin)
        FFT_value_uV = fftData[Ichan].getBand(Ibin) / ((float)nBins); 
        
        //FFT_value_uV = fftData[Ichan].getBand(Ibin);

        //decide if this is the maximum, compared to previous bins for this channel
        if (FFT_value_uV > detectedPeak[Ichan].rms_uV_perBin) {
          //this is bigger, so hold onto this value as the new "maximum"
          detectedPeak[Ichan].bin  = Ibin;
          detectedPeak[Ichan].freq_Hz = FFT_freq_Hz;
          detectedPeak[Ichan].rms_uV_perBin = FFT_value_uV;
        }
      } //close if within frequency band
    } //close loop over bins
    // Store rms value and average over the number of trials.
    rms[sample_position][Ichan][previous_rand_index] += detectedPeak[Ichan].rms_uV_perBin; //Multiply by 10000 to avoid truncation.
    //println("Raw RMS :" + detectedPeak[Ichan].rms_uV_perBin + " FOR TRIAL # " + trial_count + " ON ICHAN # " + Ichan);
    //println("Rms of signal " + "sample position " + sample_position + " is: " + rms[sample_position][Ichan][previous_rand_index] + " FOR TRIAL # " + trial_count + " ON ICHAN # " + Ichan);
    //loop over the bins again (within the sense band) to get the average background power, excluding the bins on either side of the peak
    float sum_pow=0.0;
    int count=0;
    for (int Ibin=0; Ibin < nBins; Ibin++) {
      FFT_freq_Hz = fftData[Ichan].indexToFreq(Ibin);
      if ((FFT_freq_Hz >= min_allowed_peak_freq_Hz) && (FFT_freq_Hz <= max_allowed_peak_freq_Hz)) {
        if ((Ibin < detectedPeak[Ichan].bin - 1) || (Ibin > detectedPeak[Ichan].bin + 1)) {
          FFT_value_uV = fftData[Ichan].getBand(Ibin) / ((float)nBins);  //get the RMS per bin
          sum_pow+=pow(FFT_value_uV, 2.0f);
          count++;
        }
      }
    }
    //compute mean
    detectedPeak[Ichan].background_rms_uV_perBin = sqrt(sum_pow / count);
    //NEWLY ADDED BACKGROUND ARRAY BELOW TO KEEP TRACK OF VALUES.
    background_rms[sample_position][Ichan][previous_rand_index] += sqrt(sum_pow/count);
    //println("Background rms of " + "sample position " + sample_position + " is: " + background_rms[sample_position][Ichan][previous_rand_index] + " for rand_index: " + previous_rand_index + " FOR TRIAL # " + trial_count + " ON ICHAN # " + Ichan);
    //decide if peak is big enough to be detected
    detectedPeak[Ichan].SNR_dB = 20.0f*(float)java.lang.Math.log10(detectedPeak[Ichan].rms_uV_perBin / detectedPeak[Ichan].background_rms_uV_perBin);
    //println("SNR: " + detectedPeak[Ichan].SNR_dB);
    //kludge
    //if ((detectedPeak[Ichan].freq_Hz >= processing_band_low_Hz[0]) && (detectedPeak[Ichan].freq_Hz <= processing_band_high_Hz[0])) {
    //  if (detectedPeak[Ichan].SNR_dB >= detection_thresh_dB-2.0) {
    //    detectedPeak[Ichan].threshold_dB = detection_thresh_dB;
    //    detectedPeak[Ichan].isDetected = true;
    //  }
    //} else {
    //  if (detectedPeak[Ichan].SNR_dB >= detection_thresh_dB) {
    //    detectedPeak[Ichan].threshold_dB = detection_thresh_dB;
    //    detectedPeak[Ichan].isDetected = true;
    //  }
    //}

    //} // end loop over channels
  } //end method findPeakFrequency
}
 /*//For Future use in classification.
 class KNNinfo {
 float Time;
 float SNR_dB;
 float Peak;
 }
 KNNinfo[] data = new KNNinfo[MAX_DATA];
 for (int i = 0; i < MAX_DATA; i++) {
   data[i] = new KNNinfo();
 }
 int current_max_index;
 //Not sure what to do when there is not a full amount of data inside the KNN algorithm.
 //Include somewhere: a new class that takes into account the classification of each
 KNNAlgorithm(){ //Perform KNN algorithm
   float Time = float(currentmillis - previousmillis);
   float SNR_dB = detectedPeak[Ichan].SNR_dB;
   float Peak = detectedPeak[Ichan].rms_uV_perBin;
   for (int i = 0; i < current_max_index; i++) {
     float x = (pow(data[i].Time)-pow(Time)); //Compute the distance (for x on this line) between the points in data and the recently acquired data.
     float y = (pow(data[i].SNR_dB)-pow(SNR_dB));
     float z = (pow(data[i].Peak)-pow(Peak));
     distance = sqrt(x + y + z);
     //Add multiple indices depending on the amount of checks we want to perform. For loop with N classifications.
     for (int j = 0; j < N; j++) {
       if (distance < minindex.distance){
         minindex.distance = distance;
         minindex.index = i;
       }
     }
   }
   for (int i = 0; i < N; i++) {
      if(data[minindex[i].index] == 'A'){
        numpointsnearA++;
      } else { //no detection region
        numpointsnearB++;
      }
   }
   if (numpointsnearA > numpointsnearB) {
     detection = true;
   } else {
     detection = false;
   }
 }
 */ 