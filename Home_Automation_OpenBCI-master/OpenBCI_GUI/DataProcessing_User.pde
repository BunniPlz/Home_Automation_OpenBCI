
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
  boolean switchesActive = false;
  final float detection_thresh_dB = 6.0f;
  final float min_allowed_peak_freq_Hz = 35.5f;
  final float max_allowed_peak_freq_Hz = 44.0f;
  final float[] processing_band_low_Hz = {35.6};
  final float[] processing_band_high_Hz = {38.1};

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
    processMultiPerson(data_newest_uV, data_long_uV, data_forDisplay_uV, fftData);



    }
    
    //Monitors multiple channels and checks for what they do
  public void processMultiPerson(float[][] data_newest_uV, float[][]data_long_uV, float[][] data_forDisplay_uV, FFT[] fftData) {
    boolean isDetected = false;
    String txt = " ";
    int Ichan = 7; //Channel currently being used
    findPeakFrequency(fftData, Ichan); 
    if ((detectedPeak[Ichan].freq_Hz >= processing_band_low_Hz[0]) && (detectedPeak[Ichan].freq_Hz < processing_band_high_Hz[0])) {
        if (detectedPeak[Ichan].SNR_dB >= detection_thresh_dB) {
          detectedPeak[Ichan].threshold_dB = detection_thresh_dB;
          detectedPeak[Ichan].isDetected = true;
          isDetected = true;
        }
    } 
    //Check the next channel to see if there is any detection.
     Ichan = 6;    //change according to the channel being used for corresponding action
      findPeakFrequency(fftData, Ichan);
      if ((detectedPeak[Ichan].freq_Hz >= processing_band_low_Hz[0]) && (detectedPeak[Ichan].freq_Hz < processing_band_high_Hz[0])) { //look in alpha band
        if (detectedPeak[Ichan].SNR_dB >= detection_thresh_dB) {
          detectedPeak[Ichan].threshold_dB = detection_thresh_dB;
          detectedPeak[Ichan].isDetected = true;
          isDetected = true;
        }
      }
      Ichan = 5;
      findPeakFrequency(fftData, Ichan);
        if ((detectedPeak[Ichan].freq_Hz >= processing_band_low_Hz[0]) && (detectedPeak[Ichan].freq_Hz < processing_band_high_Hz[0])) {
          if (detectedPeak[Ichan].SNR_dB >= detection_thresh_dB) {
            detectedPeak[Ichan].threshold_dB = detection_thresh_dB;
            detectedPeak[Ichan].isDetected = true;
            isDetected = true;
          }
        }
       Ichan = 4;
       findPeakFrequency(fftData, Ichan);
        if ((detectedPeak[Ichan].freq_Hz >= processing_band_low_Hz[0]) && (detectedPeak[Ichan].freq_Hz < processing_band_high_Hz[0])) {
          if (detectedPeak[Ichan].SNR_dB >= detection_thresh_dB) {
            detectedPeak[Ichan].threshold_dB = detection_thresh_dB;
            detectedPeak[Ichan].isDetected = true;
            isDetected = true;
          }
    }
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

    //decide if peak is big enough to be detected
    detectedPeak[Ichan].SNR_dB = 20.0f*(float)java.lang.Math.log10(detectedPeak[Ichan].rms_uV_perBin / detectedPeak[Ichan].background_rms_uV_perBin);

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