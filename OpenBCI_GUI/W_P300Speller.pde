
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
  
  private final int MAX_ROW = 4;
  private final int MAX_COLUMN = 4;
  private int runcount = 0;
  private int randrow = 0;
  private int randcol = 0;
  
  private boolean spellerStarted = true;
  
  char[] characters = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}; 

  W_P300Speller(PApplet _parent){
    super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)

    //This is the protocol for setting up dropdowns.
    //Note that these 3 dropdowns correspond to the 3 global functions below
    //You just need to make sure the "id" (the 1st String) has the same name as the corresponding function
    addDropdown("Dropdown1", "Drop 1", Arrays.asList("A", "B"), 0);
    addDropdown("Dropdown2", "Drop 2", Arrays.asList("C", "D", "E"), 1);
    addDropdown("Dropdown3", "Drop 3", Arrays.asList("F", "G", "H", "I"), 3);

    /*
    widgetTemplateButton = new Button (x + w/2, y + h/2, 200, navHeight, "Design Your Own Widget!", 12);
    widgetTemplateButton.setFont(p4, 14);
    widgetTemplateButton.setURL("http://docs.openbci.com/Tutorials/15-Custom_Widgets");
    */
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
    if (spellerStarted && runcount > 0) { //In the case this is not first runtime, get random ints.
      /*
      switch (runcount % 2) { //If runcount is odd, we'll say it's a column, if even, row
        case 0:
          randrow = int(random(float(MAX_ROW)));
          println("Randrow is equal to " + randrow);
          break;
        case 1:
          randcol = int(random(float(MAX_COLUMN)));
          println("Randcol is equal to " + randcol);
          break;
      }
      */
      randrow = int(random(float(MAX_ROW)));
      //println("Randrow is equal to " + randrow);
      randcol = int(random(float(MAX_COLUMN)));
      //println("Randcol is equal to " + randcol);
    }
    float charXOffset, charYOffset;
    charXOffset = (w/MAX_COLUMN) / 2;
    charYOffset = (h/MAX_ROW) / 2;
    for (int i = 0; i < MAX_ROW; i++) { //x value
      float ypos = (h/MAX_ROW)*i;
      for (int j = 0; j < MAX_COLUMN; j++) { //y value
        float xpos = (w/MAX_COLUMN)*j;
        if (runcount == 0){ //If first runtime, this is a special case. Display all characters
          fill(0f);
          stroke(255f);
          rect(xpos, ypos, (w/MAX_COLUMN), (h/MAX_ROW));
          textSize(32);
          fill(255f, 255f, 255f);
          text(characters[(j+(i*(MAX_ROW-1)))], xpos + charXOffset, ypos + charYOffset);
        } else { //If any other runtime
          if(randrow == i || randcol == j) {  
            // if current rectangle's row is the randomly selected row, or if the column is the selected column
            fill(105f);  // set rect fill color to grey(lit)
          } else {
            fill(0f);  // otherwise set the fill color to black
          }
          stroke(255f);  // rectangle border color
          rect(xpos, ypos, (w/MAX_COLUMN), (h/MAX_ROW));  // draw rectangle
          textSize(32);  // set text size
          fill(255f, 255f, 255f);  // text color white
          text(characters[(j+(i*(MAX_ROW-1)))], xpos + charXOffset, ypos + charYOffset);  // writes the character 
          //System.out.printf("Index: %d - Char: %c - Row: %d - Col: %d \n", j+(i*MAX_ROW), characters[(j+(i*MAX_ROW))], i, j);
        }
    }
      //line(0,(h/MAX_ROW)*(i), w, (h/MAX_ROW)*(i));
      //println("line " + i + " with (x1,y1) equal to (" + 0 + "," + h/MAX_ROW + ")" + " with (x2,y2) equal to (" + w + "," + h/MAX_ROW + ")" );
    }
      delay(1000);
      if(spellerStarted);
        runcount++;
      // END -- Drawing character boxes
    

    popStyle();

  }
  
  void resetSpeller() {
    spellerStarted = false; 
    runcount = 0;
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
  void customFunction(){
    //this is a fake function... replace it with something relevant to this widget

  }

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