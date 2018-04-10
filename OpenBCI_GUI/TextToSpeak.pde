
/*This class serves to produce voices to activate smart devices in the home. Add
in the variation of which device depending on the time.*/
// ---- Define variables for indices that represent specific smart devices. Probably not the best idea, but we can implement a GUI to choose these things in the future
final int SMART_LOCK = 2;
//final int SMART_BULB = 1;
class TextToSpeak {
  boolean state;
  String item;
  String sentence;
  TTS tts;
  void Initialize(String dname) { //Initialize the TextToSpeak object with a device name, state to 0, and creating an actual object for tts.
    state = false;
    item = dname;
    tts = new TTS();
  }
  void Trigger(int rand_index) {
    switch(rand_index) {
      case SMART_LOCK:
      if (state == false) {
        sentence = "Alexa, ask August to lock " + item;
        tts.speak(sentence);
        state = true;
      } else {
        sentence = "Alexa, ask August to unlock " + item + " Pin: 1234";
        tts.speak(sentence);
        state = false;
      }
      break;
      default:
      //Normal devices (plugs/smart bulb), turn on and off
        if (state == false) { //Enter if the state of the device is OFF
         item = "Alexa, turn on " + item;
         tts.speak(item); //Perform TTS.
         state = true; //Set state to ON.
        } else { //Enter if the state of the device is ON
         item = "Alexa, turn off " + item;
         tts.speak(item);
         state = false; //Set state to OFF.
        }
      break;
    }
  }
}
/*
TextToSpeak Device = new TextToSpeak[MAX_DEVICES] Create TextToSpeak objects up to the
amount of devices we have.*/