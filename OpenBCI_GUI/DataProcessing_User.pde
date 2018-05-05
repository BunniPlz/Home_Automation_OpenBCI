import java.nio.file.*;
import java.io.*;
import static java.nio.file.StandardOpenOption.*;
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
int previous_letter_index; //Keeps track of the previous letter so that we can save data into the right array element.  
final String filename = "TargetData.txt";
final String filename2 = "Background.txt";
final boolean appendData = true;
float [][][] Time_Data = new float[500][4][5]; //Hardcoded. From left to right, the first dimension represents 500 samples (the last two seconds of run time). The second element represents the 4 channels we use. The third dimension represents the 5 different letters.
//------------------------------------------------------------------------
//                            Classes
//------------------------------------------------------------------------
//KNN classifier (stores the testing data).
class KNNinfo {
   float Time;
   float SNR_dB;
   float Peak;
 }
 class MinimumIndices {
   int MinIndex;
   float MinDistance;
 }
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
  final int MAX_DATA_SAMPLES = 200; //Arbitrary number of test samples for now. EDIT LATER
  final int N = 5; //Maximum number of points we use to check (for extra accuracy).
  final int max_wait_runs = 5; //The amount of one second intervals that should be waited for.
  final int maxruns_persecond = 24;
  final int option = 1; //Set to the option you want. If set to 1, it will do frequency-domain analysis. If set to 2, it will do time-domain analysis.
  /*VARIABLES THAT KEEP TRACK OF TIMING*/
  int currentmillis = 0;
  int previousmillis = 0;
  int runs = 0;
  boolean wait = false; //If true, then it will not collect data. If false, then it will collect data.
  int wait_runs = 0;
  /*VARIABLES THAT HOLD DATA FOR EACH CHANNEL*/
  //float[][][] rms = new float[24][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //24 samples since this part of the program is only called 240 times in 10 seconds, which is 24 times per second.
  //float[][][] background_rms = new float[24][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //4 is the number of channels used.
  float[][][] rms = new float[48][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //24 samples since this part of the program is only called 240 times in 10 seconds, which is 24 times per second.
  float[][][] background_rms = new float[48][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //4 is the number of channels used.
  int sample_position = 0;
  int trial_count = 0; //Count the number of trials we have stored.
  int currentruncount = 0;
  int num_skips = 0;
  int num_completions = 0;
  int num_runs = 0;
  float distance;
  float[] max_hit = new float[NUM_LETTERS_USED];
  //int[] sample_positions_ofletters;
  /*******************************************/
  boolean switchesActive = false;
  boolean file_active = false;
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
  final String[] Devices = new String[]{"A", "B", "C", "D", "E"}; //Test string incorporating the device names.
  KNNinfo[] Data = new KNNinfo[MAX_DATA_SAMPLES];
  MinimumIndices[] CompData = new MinimumIndices[N];
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
     for (int i = 0; i < MAX_DATA_SAMPLES; i++) {
       Data[i] = new KNNinfo(); //Needs a way to initialize the test data.
    }
    for (int i = 0; i < N; i++) {
      CompData[i] = new MinimumIndices();
      CompData[i].MinDistance = 100000; //Dummy Initialization.
    }
    //Load KNN data here
    //sample_positions_ofletters = new int[25];
  }

  //add some functions here...if you'd like

  //here is the processing routine called by the OpenBCI main program...update this with whatever you'd like to do. Many conditions are checked here.
  public void process(float[][] data_newest_uV, //holds raw bio data that is new since the last call
    float[][] data_long_uV, //holds a longer piece of buffered EEG data, of same length as will be plotted on the screen
    float[][] data_forDisplay_uV, //this data has been filtered and is ready for plotting on the screen
    FFT[] fftData) {              //holds the FFT (frequency spectrum) of the latest data

    //for example, you could loop over each EEG channel to do some sort of time-domain processing
    //using the sample values that have already been filtered, as will be plotted on the display
    float EEG_value_uV;
    currentmillis = millis();
    //println("Filter type is " + dataProcessing.getFilterDescription());
    //if(w_p300speller.classification && !file_active) {
    //  //INITIALIZE FILE.
      
    //  file_active = true;
    //} else if(!w_p300speller.classification && file_active) {
      
    //  file_active = false;
    //}
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
          previous_letter_index = previous_rand_index; //Set the previous_letter_index to the previous_rand_index so that we can read data which has already passed.
          previous_rand_index = current_rand_index; //Set the previous index to the current index.
          //sample_positions_ofletters[trial_count] = sample_position;
          num_skips++;
          sample_position = 0;
          num_runs++;
          thread("Collect");
        } 
      }
        //if (sample_position < 24) { //Continue to collect data only if it has not finished that sample early.
        if (sample_position < 48) {
        processMultiChannel(data_newest_uV, data_long_uV, data_forDisplay_uV, fftData);
        }
        if(num_runs == 0) {
          //println("reset does not happen during the first run, num_runs = " + num_runs);
        }
    } else {
      if(trial_count == 24) { //compensate for the lack of data and check anyways.
        switch (option) {
        case 1:
          CheckSNR();
          break;
        case 2:
          thread("SaveData");
        case 3:
          thread("KNNAlgorithm");
          break;
        default:
        println("The max value num_runs goes to is: " + num_runs);
        }
      }
    }
    }

//**********************************************
//Loop through, calculate, and get data saved.
//**********************************************
  public void processMultiChannel(float[][] data_newest_uV, float[][]data_long_uV, float[][] data_forDisplay_uV, FFT[] fftData) {
    boolean isDetected = false;
    //if (sample_position < 48 && previous_rand_index < MAX_DEVICES) { //As long as previous_rand_index is equal to its initial value of 100 (or larger than MAX_DEVICES), it will not begin reading data (option 1), in this case, we have detection checks only when the index is less than MAX_DEVICES (5) 
    if (sample_position < 48 && previous_rand_index < MAX_DEVICES) {
     for(int Ichan = 0; Ichan < NUM_CHANNELS_USED; Ichan++) {
       
       //println("Ichan = " + Ichan);
       findPeakFrequency(fftData,Ichan);
     }
     sample_position++;
     //if(sample_position == 24) {
     if(sample_position == 48) { //If we finish all samples, increment number of completed runs.
       num_completions++;
     }
    } else {
    }
  }
  
//***************************************************************************
//Misleading name, but it either checks RMS or SNR (right now it checks RMS)
//***************************************************************************
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
      float RMS = 0;
      int hit_count[] = new int [NUM_LETTERS_USED];
      float max_hit[] = new float [NUM_LETTERS_USED];
      int letter_to_trigger;
      //Initialize
      //FILE WRITE IN THE FOR LOOP depending on the indices of the random letter.
      
      //int hit_count[][] = new int[NUM_CHANNELS_USED][NUM_LETTERS_USED]; //Keep track of the hit for each channel and each character. A variant in case we need it.
      //Increment through all the data collected for each
      for(int letter_position = 0; letter_position < NUM_LETTERS_USED; letter_position++) {
        max_hit[letter_position] = rms[5][0][letter_position];
        for(int t = 0; t < 48; t++) { // Start at sample 5 and go to sample 36. Checking samples of interest for the P300. //Check these samples for a spike at that time.
          
          for(int Ichan = 0; Ichan < 4; Ichan++) {
           RMS = rms[t][Ichan][letter_position]/NUM_OF_TRIALS;
           //SNR = 20.0f*(float)java.lang.Math.log10(RMS/(background_rms[t][Ichan][letter_position]/NUM_OF_TRIALS)); //Division by NUM_OF_TRIALS to get rid of low SNR experienced through averaging.
           if(RMS > max_hit[letter_position]) {
             max_hit[letter_position] = RMS;
           }
           //********************************
           //Commented out SNR analysis below
           //********************************
          //println("SNR : " + SNR);
           //if (SNR > detection_thresh_dB) { //Maybe check for the EEG peak as well.
           //  hit_count[letter_position]++; //If SNR is above the threshold, then increment hit counts.
           //  println("Hit for letter position: " + letter_position + " at SNR: " + SNR + "... with RMS: " + RMS);
           //}   
            //int index = 0;
            //for(int letter_position = 0; letter_position < 5; letter_position++) {
            //  if (rms[t][Ichan][letter_position] > max){
            //    max = rms[t][Ichan][letter_position]
            //    index
            //  }
            
            }
      }
      }
        //letter_to_trigger = findLettertoDetectSNR(hit_count); //Return the position of the letter to be triggered.
        letter_to_trigger = findLettertoDetectRMS(max_hit);
        println("Trigger on index letter of " + letter_to_trigger);
        VoiceCommand(letter_to_trigger);
      }
//*********************************************************************
//Compare RMS to find the most likely letter (frequency analysis based)
//*********************************************************************
   int findLettertoDetectRMS(float[] max_hit) {
     int maxRMS_letter_index = 0;
     float max_RMS = 0;
     for(int letter_position = 0; letter_position < NUM_LETTERS_USED; letter_position++) {
       if (max_hit[letter_position] > max_RMS) {
         max_RMS = max_hit[letter_position];
         maxRMS_letter_index = letter_position;
       }
     }
     return maxRMS_letter_index;
   }
//**********************************************************************   
//Compares SNR to find the most likely letter (frequency analysis based)
//**********************************************************************
   int findLettertoDetectSNR(int[] hit_count) { 
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
   
//*******************************************
//Function to play voice commands.
//*******************************************
   void VoiceCommand(int letter_to_trigger) {
     device_to_play = letter_to_trigger;
     thread("Trigger");
     println("Done with command");
     trial_count = 0;
     sample_position = 0;
     wait = true;
     println("Number of skips : " + num_skips);
     println("Number of completions : " + num_completions);
     //Reinitialize arrays. Below is 24 sample case.
     //float[][][] rms = new float[24][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //24 samples since this part of the program is only called 240 times in 10 seconds, which is 24 times per second.
     //float[][][] background_rms = new float[24][NUM_CHANNELS_USED][NUM_LETTERS_USED];//4 is the number of channels used.
     //Below is 48 sample reinitialization case.
     float[][][] rms = new float[48][NUM_CHANNELS_USED][NUM_LETTERS_USED]; //24 samples since this part of the program is only called 240 times in 10 seconds, which is 24 times per second.
     float[][][] background_rms = new float[48][NUM_CHANNELS_USED][NUM_LETTERS_USED];
   }
   
//*********************************************
//Incomplete, meant to load in data.
//*********************************************
   void loadTestData() {
     //1) Read from text file?
     //2) Store in Data array
     //3) Or, you can try storing directly when initialized (meaning this function isn't needed).
     
   }
//************************************************************************
//KNN Algorithm
//************************************************************************
   void KNNAlgorithm(float SNR, float amplitude, int letter_index, float Time){ //Perform KNN algorithm\ Change to boolean and say if it is a hit or miss.
   for (int i = 0; i < MAX_DATA_SAMPLES; i++) { //For each data point in the test samples, compute the distance
     float x = (pow(Data[i].Time,2)-pow(Time,2)); //Compute the distance (for x on this line) between the points in data and the recently acquired data.
     float y = (pow(Data[i].Peak,2)-pow(amplitude,2));
     distance = sqrt(x + y);
     //Add multiple indices depending on the amount of checks we want to perform. For loop with N classifications.
     for (int j = 0; j < N; j++) { //For each index up to N, check if distance < minindex.distance to find the N closest samples.
       if (distance < CompData[j].MinDistance){
         CompData[j].MinDistance = distance;
         CompData[j].MinIndex = i;
       
       }
     }
   }
   }
//**********************************************************
//Frequency-Domain Analysis
//**********************************************************
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
       //} // end loop over channels
  } //end method findPeakFrequency
}

//********************************************
//Public functions below for threading
//********************************************
 void Collect(){
    //IMPORTANT TO USE.
    int run_count = 0;
    final int numSeconds = 5;
    final int numPoints = 1250;
    int p = 0;
    int index = previous_letter_index;
    final float timeBetweenPoints = (float)numSeconds / (float)numPoints;
    for(int channelNumber = 0; channelNumber < 4; channelNumber++) {
      if(dataBuffY_filtY_uV[channelNumber].length > numPoints){
        for (int i = 750; i < dataBuffY_filtY_uV[channelNumber].length; i++) {
          float time = -(float)numSeconds + (float)(i-(dataBuffY_filtY_uV[channelNumber].length-1250))*timeBetweenPoints + 2;
          if(p < 500) {
            //println("Test data 1 : " + dataBuffY_filtY_uV[channelNumber][i]);
            Time_Data[p++][channelNumber][previous_letter_index] += dataBuffY_filtY_uV[channelNumber][i]; //add to slowly get rms.
            //println("Time Data is: " + Time_Data[p-1][channelNumber][previous_letter_index]);
          }
        }
        p = 0;
      }
    }
  }
//**************************************************
//Function to save data into text. Still incomplete.
//**************************************************
  void SaveData() {
  //FileWriter f = new FileWriter(filename, appendData);
  //FileWriter b = new FileWriter(filename2, appendData);
  //Different channels for each letter detection.
  //Different channels mean different EEG signals.
  //So representation for each letter detection has to be stored in various channels.
  for(int Sample_index = 0; Sample_index < 500; Sample_index++) {
    for(int letter_index = 0; letter_index < 5; letter_index++) {
      for(int iChan = 0; iChan < 4; iChan++) {
        
      }
    
    }
  }
  }
  void fwrite(FileWriter f, String data, boolean appendData){
  //Path file = Paths.get(filename);
    try
    {
      f.write(data);
    }
    catch(Exception e)
    {
        System.out.println("Message: " + e);
    }
}