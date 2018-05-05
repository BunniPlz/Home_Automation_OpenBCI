
////////////////////////////////////////////////////
//
//    W_P300Speller.pde (ie "P300 Speller")
//
//    This is a Template Widget, intended to be used as a starting point for OpenBCI Community members that want to develop their own custom widgets!
//    Good luck! If you embark on this journey, please let us know. Your contributions are valuable to everyone!
//
//    Created by: Conor Russomanno, November 2016
//
///////////////////////////////////////////////////,

class W_P300Speller extends Widget {

  //to see all core variables/methods of the Widget class, refer to Widget.pde
  //put your custom variables here...
  //Button widgetTemplateButton;
  Button button_StartSpeller;
  Button button_CollectClassification;
  private final int MAX_ROW = 1;
  private final int MAX_COLUMN = 5;
  public int runcount = 0;
  private int lastRuncount = 0;
  private int randrow = 0;
  private int randcol = 0;
  private int[] letter_pattern;
  private int targetLetterIndex = 0;
  private int targetLetterHitCount = 0;
  private int targetLetterRow = 0;
  private int targetLetterColumn = 0;
  
  int currentmillis = 0;
  int previousmillis = 0;
  int elapsedTime_ms = 0;
  private int maxRunCount = 60;  // temp magic number
  private int maxHitCount = 25;  // temp magic number
  private int stimuliDelay = 1000; // millisecond delay between switching row and columns
  private String fileString = "C:\\Users\\the0r\\Documents\\School\\CSUF\\EGCP598 BCI LAB\\Home_Automation_OpenBCI\\OpenBCI_GUI\\SavedData\\P300SpellerStimuliRecord.txt";
  private int[] hit_count;
  private int NUM_LETTERS = 5;
  private int letter_runs = 0;
  private boolean spellerStarted = false;
  private boolean countdownStarted = false;
  private boolean dice_roll_success = false;
  private int totalruns = 0;
  private char previous_character = 'F';
  private int countdownDuration = 10000;  // delay before rows begin to flash (ms)
  public int countdownCurrent;  // delay to allow response to settle before beginning speller acquisition
  char[] characters = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'};
  private String fs = System.getProperty("file.separator");
  private PFont bigFont;
  private int target_character_index = 0;
  private int target_index_variable = 0;
  private int class_runs = 0;
  private final int MAX_RUNS = 5;
  public boolean classification = false; //Classify the signal
  public int[] target_indices;
  W_P300Speller(PApplet _parent){
    super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)

    //This is the protocol for setting up dropdowns.
    //Note that these 3 dropdowns correspond to the 3 global functions below
    //You just need to make sure the "id" (the 1st String) has the same name as the corresponding function
    //addDropdown("Dropdown1", "Drop 1", Arrays.asList("A", "B"), 0);
    //addDropdown("Dropdown2", "Drop 2", Arrays.asList("C", "D", "E"), 1);
    //addDropdown("Dropdown3", "Drop 3", Arrays.asList("F", "G", "H", "I"), 3);

    /*
    widgetTemplateButton = new Button (x + w/2, y + h/2, 200, navHeight, "Design Your Own Widget!", 12);
    widgetTemplateButton.setFont(p4, 14);
    widgetTemplateButton.setURL("http://docs.openbci.com/Tutorials/15-Custom_Widgets");
    */
    bigFont = loadFont("CourierNewPSMT-24.vlw");
    println("W_P300_Speller - loaded font CourierNewPSMT-24.vlw");
    
    button_StartSpeller = new Button(x, y - navH, 200, navH, "Start Speller", 12);
    button_StartSpeller.setFont(p4, 14);
    button_CollectClassification = new Button(x+200, y-navH, 200, navH, "Collect Data", 12);
    button_StartSpeller.setFont(p4, 14);
    countdownCurrent = countdownDuration/1000;
    hit_count = new int[5];
    letter_pattern = new int[25];
    //target_indices = new int[5]; //Reset this after
    
  }

  void update() {
    super.update(); //calls the parent update() method of Widget (DON'T REMOVE)

    //put your code here...

  }

  void draw(){
    super.draw(); //calls the parent draw() method of Widget (DON'T REMOVE)

    //put your code here... //remember to refer to x,y,w,h which are the positioning variables of the Widget class
    pushStyle();

    //widgetTemplateButton.draw();
    // START -- Drawing character boxes
    //ROW (x axis) in this case are the columns of previous code
    //COLUMN (y axis) in this case are the rows of previous code
    if (spellerStarted && targetLetterHitCount < maxHitCount) { //In the case this is not first runtime, get random ints.
      //System.out.printf("Current ms: %d, previous ms: %d, elapsed time ms: %d \n", currentmillis, previousmillis, elapsedTime_ms);
      // if elapsed time since last row and column change > stimuli delay, generate a new pair of row and col
      // otherwise, keep drawing the previous row/col
      if(countdownCurrent == 0) {  // after countdown has reached 0
        
        if(elapsedTime_ms > stimuliDelay) {
          elapsedTime_ms = 0;
          randomizeTargetLetter();
            randrow = targetLetterRow;
            randcol = targetLetterColumn;
            current_rand_index = (randcol + randrow*MAX_COLUMN);
            
            if(letter_runs > 0) { //Do not increment for the first run.
              runcount++;
            }
            letter_runs++;
        }
      } else {
        if(elapsedTime_ms > 1000) {  // every second during countdown before starting speller
          elapsedTime_ms = 0;
          countdownCurrent--;
        }
      }
    } 
    
    float charXOffset, charYOffset;
    charXOffset = (w/MAX_COLUMN) / 2;
    charYOffset = (h/MAX_ROW) / 2;
    for (int i = 0; i < MAX_ROW; i++) { //y value
      float ypos = y + (h/MAX_ROW)*i;
      for (int j = 0; j < MAX_COLUMN; j++) { //x value
        float xpos = x + (w/MAX_COLUMN)*j;
        if (runcount == 0 || !spellerStarted){ //If first runtime, this is a special case. Display all characters
        
          fill(0f);
          if(j+(i*(MAX_ROW)) == targetLetterIndex) {  // color the target letter blue
            fill(0f, 0f, 255f);
          }
          stroke(255f);
          rect(xpos, ypos, (w/MAX_COLUMN), (h/MAX_ROW));
          textSize(32);
          fill(255f, 255f, 255f);
          text(characters[(j+(i*(MAX_COLUMN)))], xpos + charXOffset, ypos + charYOffset);
        } else if (((runcount > 0) || (totalruns != 0)) && targetLetterHitCount < maxHitCount) { //If any other run time between 0 and max runcount
          if(randrow == i || randcol == j) {  
            // if current rectangle's row is the randomly selected row, or if the column is the selected column
            fill(105f);  // set rect fill color to grey(lit)
          } else {
            fill(0f);  // otherwise set the fill color to black
          }
          
          if(randrow == i && randcol == j) {  
            fill(105f, 105f, 105f);  // grey if not the target letter
            if (j+(i*(MAX_COLUMN)) == targetLetterIndex) {
              fill(0f, 0f, 255f);  // blue if target letter
              
              // increment only if stimuli has changed
              if(runcount != lastRuncount) {
                targetLetterHitCount++; // increment times target letter has been highlighted in the intersection
                System.out.printf("Target Letter Hit Count: %d. Index: %d - Char: %c - Row: %d - Col: %d \n", targetLetterHitCount, j+(i*MAX_ROW), characters[(j+(i*MAX_COLUMN))], i, j);
                lastRuncount = runcount;
                if(targetLetterHitCount == maxHitCount) { //Reset the speller to its original state if
                  for (int p = 0; p < 25; p++) {
                    println("Letter #" + p + ": " + letter_pattern[p]);
                  }
                  class_runs++;
                  if(!classification || (class_runs < MAX_RUNS)) { //If we are not classifying or classification runs has not reached the maximum amount we want to do, then we will continue to utilize the speller.
                    resetSpeller();
                  } else {
                    classification = false;
                  }
                  totalruns++;
                }
              }
            }
          }

          stroke(255f);  // rectangle border color
          rect(xpos, ypos, (w/MAX_COLUMN), (h/MAX_ROW));  // draw rectangle
          textSize(32);  // set text size
          fill(255f, 255f, 255f);  // text color white
          text(characters[(j+(i*(MAX_COLUMN)))], xpos + charXOffset, ypos + charYOffset);  // writes the character 
          //System.out.printf("Index: %d - Char: %c - Row: %d - Col: %d \n", j+(i*MAX_ROW), characters[(j+(i*MAX_COLUMN))], i, j);
        } else {
          toggleSpeller();
        }
      }  // end column loop
    }  // end row loop
    // END -- Drawing character boxes 
    
    //delay(stimuliDelay);
    elapsedTime_ms += (currentmillis - previousmillis);
    previousmillis = currentmillis;
    currentmillis = millis();
      
    //draw countdown if active
    if(countdownCurrent > 0) {
      textFont(bigFont);
      fill(255f, 255f, 255f); //text color white
      text(countdownCurrent,w/2,h/2);
    }
    
    button_StartSpeller.draw();
    button_CollectClassification.draw();
    popStyle();

  }
  
  void resetSpeller() {
    runcount = 0;
    lastRuncount = 0;
    countdownCurrent = countdownDuration/1000;
    targetLetterHitCount = 0;
    randomizeTargetLetter();
    elapsedTime_ms = 0;
    for(int i = 0; i < 5; i++) { //Reset hit_count array keeping track of all letters.
      hit_count[i] = 0;
    }
  }
  
  void randomizeTargetLetter() {
    targetLetterRow = int(random(MAX_ROW));
    float dice_roll = random(0,100);
    if(dice_roll < 20 && dice_roll >= 0 && hit_count[0] < 5 && previous_character != 'A') {  //As long as hit_count is less than 5 for 'A', 'B', 'C', 'D', 'E' for indices 0, 1, 2, 3, 4 respectively, then we can set it to the desired letter of that condition.
      targetLetterColumn = randcol = 0;
      hit_count[0]++;
      previous_character = 'A';
    }
    else if (dice_roll >= 20 - 20*(hit_count[0]/5) && dice_roll < 40 && hit_count[1] < 5 && previous_character != 'B') {
      targetLetterColumn = randcol = 1;
      hit_count[1]++;
      previous_character = 'B';
    }
    else if (dice_roll >= 40 - 40*(hit_count[1]/5) && dice_roll < 60 && hit_count[2] < 5 && previous_character != 'C') {
      targetLetterColumn = randcol = 2;
      hit_count[2]++;
      previous_character = 'C';
    }
    else if (dice_roll >= 60 - 60*(hit_count[2]/5)  && dice_roll < 80 && hit_count[3] < 5 && previous_character != 'D') {
     targetLetterColumn =  randcol = 3;
      hit_count[3]++;
      previous_character = 'D';
    }
    else if (dice_roll >= 80 - 80*(hit_count[3]/5) && dice_roll < 100 && hit_count[4] < 5 && previous_character != 'E') {
      targetLetterColumn = randcol = 4;
      hit_count[4]++;
      previous_character = 'E';
    }
    else if (dice_roll_success == false) {
      if (hit_count[0] < 5 && previous_character != 'A'){
      targetLetterColumn =  randcol = 0;
        hit_count[0]++;
        previous_character = 'A';
      }
      else if (hit_count[1] < 5 && previous_character != 'B'){
      targetLetterColumn =  randcol = 1;
        hit_count[1]++;
        previous_character = 'B';
      }
      else if (hit_count[2] < 5 && previous_character != 'C'){
       targetLetterColumn = randcol = 2;
        hit_count[2]++;
        previous_character = 'C';
      }
      else if (hit_count[3] < 5 && previous_character != 'D'){
      targetLetterColumn = randcol = 3;
        hit_count[3]++;
        previous_character = 'D';
      }
      else if (hit_count[4] < 5 && previous_character != 'E'){
       targetLetterColumn = randcol = 4;
        hit_count[4]++;
        previous_character = 'E';
      }
    }
    current_rand_index = (randcol + randrow*MAX_COLUMN);
    println("RUN # : " + runcount);
    println("NOW ON INDEX " + current_rand_index);
    letter_pattern[runcount] = current_rand_index;
    //runcount++;
    dice_roll_success = false;
    targetLetterIndex = randcol;

    targetLetterIndex = targetLetterColumn+(targetLetterRow*MAX_COLUMN);
  
  }

  void screenResized(){
    super.screenResized(); //calls the parent screenResized() method of Widget (DON'T REMOVE)

    //put your code here...
    //widgetTemplateButton.setPos(x + w/2 - widgetTemplateButton.but_dx/2, y + h/2 - widgetTemplateButton.but_dy/2);
    button_StartSpeller.setPos(x, y - navH);


  }

  void mousePressed(){
    super.mousePressed(); //calls the parent mousePressed() method of Widget (DON'T REMOVE)

    //put your code here...
    /*
    if(widgetTemplateButton.isMouseHere()){
      widgetTemplateButton.setIsActive(true);
    }
    */
    if(button_StartSpeller.isMouseHere()) {
      toggleSpeller();
    }
    if(button_CollectClassification.isMouseHere()) {
      toggleSpeller();
      classification = true;
    }
  }
  
  void toggleSpeller() {
    if(!spellerStarted) {
      spellerStarted = true;
      button_StartSpeller.setString("Stop Speller");
      stopButtonWasPressed();
    } else {
      spellerStarted = false;
      resetSpeller();
      button_StartSpeller.setString("Start Speller");
      stopButtonWasPressed();
    }
  }
  
  boolean isSpellerStarted() {
    return spellerStarted;
  }
  
  int getTargetLetterIndex() {
    return targetLetterIndex;
  }
  
  int getTargetLetterRow() {
    return targetLetterRow;
  }
  
  int getTargetLetterColumn() {
    return targetLetterColumn;
  }
  
  String getStimuliFileName() {
    return fileString;
  }

  void mouseReleased(){
    super.mouseReleased(); //calls the parent mouseReleased() method of Widget (DON'T REMOVE)

    //put your code here...
    /*
    if(widgetTemplateButton.isActive && widgetTemplateButton.isMouseHere()){
      widgetTemplateButton.goToURL();
    }
    widgetTemplateButton.setIsActive(false);
    */

  }
/*
  //add custom functions here
  void dumpStimuliRecord(){
    // dump stimuli record to file
    if(runcount > 0) {
      try {
        BufferedWriter bwr = new BufferedWriter(new FileWriter(new File(fileString)));
        bwr.append(stimuliRecord);
        bwr.flush();
        bwr.close();
      } catch(IOException e) {
        e.printStackTrace();
      }
    }
  }
*/

};

/*
//These functions need to be global! These functions are activated when an item from the corresponding dropdown is selected
void Dropdown1(int n){
  println("Item " + (n+1) + " selected from Dropdown 1");
  if(n==0){
    //do this
  } else if(n==1){
    //do this instead
  }

  closeAllDropdowns(); // do this at the end of all widget-activated functions to ensure proper widget interactivity ... we want to make sure a click makes the menu close
}

void Dropdown2(int n){
  println("Item " + (n+1) + " selected from Dropdown 2");
  closeAllDropdowns();
}

void Dropdown3(int n){
  println("Item " + (n+1) + " selected from Dropdown 3");
  closeAllDropdowns();
}
*/