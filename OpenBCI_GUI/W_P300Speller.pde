
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

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.lang.StringBuilder;

class W_P300Speller extends Widget {

  //to see all core variables/methods of the Widget class, refer to Widget.pde
  //put your custom variables here...
  //Button widgetTemplateButton;
  Button button_StartSpeller;
  
  private final int MAX_ROW = 5;
  private final int MAX_COLUMN = 5;
  private int runcount = 0;
  private int randrow = 0;
  private int randcol = 0;
  
  private int targetLetterIndex = 0;
  private int targetLetterHitCount = 0;
  private int targetLetterRow = 0;
  private int targetLetterColumn = 0;
  
  private int maxRunCount = 60;  // temp magic number
  private int maxHitCount = 10;  // temp magic number
  private int stimuliDelay = 500; // millisecond delay between switching row and columns
  private String fileString = "C:\\Users\\the0r\\Documents\\School\\CSUF\\EGCP598 BCI LAB\\Home_Automation_OpenBCI\\OpenBCI_GUI\\SavedData";
  
  private boolean spellerStarted = false;
  
  private StringBuilder stimuliRecord;
  
  char[] characters = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}; 

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
    button_StartSpeller = new Button(x + 10, y + 10, 200,  navH, "Start Speller", 12);
    button_StartSpeller.setFont(p4, 14);
    
    stimuliRecord = new StringBuilder();
    randomizeTargetLetter();
    stimuliRecord.append("Target Character: ").append(characters[targetLetterIndex]).append(System.getProperty("line.separator"));
    stimuliRecord.append("Stimuli Delay: ").append(stimuliDelay).append(System.getProperty("line.separator"));
    stimuliRecord.append("Row,Col").append(System.getProperty("line.separator"));
    
  }

  void update(){
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
    if (spellerStarted && runcount > 0 && targetLetterHitCount < maxHitCount) { //In the case this is not first runtime, get random ints.
      if(floor(random(0,10)) == 1) {  // 1/10 chance of guaranteeing/forcing target hit
        randrow = targetLetterRow;
        randcol = targetLetterColumn;
      } else {
        randrow = int(random(MAX_ROW));
        //println("Randrow is equal to " + randrow);
        randcol = int(random(MAX_COLUMN));
        //println("Randcol is equal to " + randcol);
      }
      
      stimuliRecord.append(randrow).append(",").append(randcol).append(System.getProperty("line.separator"));
      
    }
    float charXOffset, charYOffset;
    charXOffset = (w/MAX_COLUMN) / 2;
    charYOffset = (h/MAX_ROW) / 2;
    for (int i = 0; i < MAX_ROW; i++) { //y value
      float ypos = (h/MAX_ROW)*i;
      for (int j = 0; j < MAX_COLUMN; j++) { //x value
        float xpos = (w/MAX_COLUMN)*j;
        if (runcount == 0 || !spellerStarted){ //If first runtime, this is a special case. Display all characters
          fill(0f);
          if(j+(i*(MAX_ROW)) == targetLetterIndex) {  // color the target letter blue
            fill(0f, 0f, 255f);
          }
          stroke(255f);
          rect(xpos, ypos, (w/MAX_COLUMN), (h/MAX_ROW));
          textSize(32);
          fill(255f, 255f, 255f);
          text(characters[(j+(i*(MAX_ROW)))], xpos + charXOffset, ypos + charYOffset);
        } else if (runcount > 0 && targetLetterHitCount < maxHitCount) { //If any other run time between 0 and max runcount
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
              targetLetterHitCount++; // increment times target letter has been highlighted in the intersection
              System.out.printf("Target Letter Hit Count: %d. Index: %d - Char: %c - Row: %d - Col: %d \n", targetLetterHitCount, j+(i*MAX_ROW), characters[(j+(i*MAX_COLUMN))], i, j);
            }
          }

          stroke(255f);  // rectangle border color
          rect(xpos, ypos, (w/MAX_COLUMN), (h/MAX_COLUMN));  // draw rectangle
          textSize(32);  // set text size
          fill(255f, 255f, 255f);  // text color white
          text(characters[(j+(i*(MAX_COLUMN)))], xpos + charXOffset, ypos + charYOffset);  // writes the character 
          //System.out.printf("Index: %d - Char: %c - Row: %d - Col: %d \n", j+(i*MAX_ROW), characters[(j+(i*MAX_COLUMN))], i, j);
        } else {
          toggleSpeller();
        }
      }  // end column loop
    }  // end row loop
    
    if(spellerStarted) {
      delay(stimuliDelay);
      runcount++;
    }
      
    // END -- Drawing character boxes
    
    button_StartSpeller.draw();
    popStyle();

  }
  
  void resetSpeller() {
    runcount = 0;
    targetLetterHitCount = 0;
    randomizeTargetLetter();
  }
  
  void randomizeTargetLetter() {
    targetLetterRow = int(random(MAX_ROW));
    targetLetterColumn = int(random(MAX_COLUMN));
    targetLetterIndex = targetLetterColumn+(targetLetterRow*MAX_COLUMN);
    System.out.printf("Target letter: %c - Index: %d - Row,Column: %d, %d\n", characters[targetLetterIndex], targetLetterIndex, targetLetterRow, targetLetterColumn); 
  }

  void screenResized(){
    super.screenResized(); //calls the parent screenResized() method of Widget (DON'T REMOVE)

    //put your code here...
    //widgetTemplateButton.setPos(x + w/2 - widgetTemplateButton.but_dx/2, y + h/2 - widgetTemplateButton.but_dy/2);


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

};

void printToFile(StringBuilder sb, String fileString) throws IOException {
  try {
    BufferedWriter bwr = new BufferedWriter(new FileWriter(new File(fileString)));
    bwr.append(sb);
    bwr.flush();
    bwr.close();
  } catch(IOException e) {
    e.printStackTrace();
  }
}

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