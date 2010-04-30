
class Button
{
  int x = widthInit - 70;
  int y = heightInit - 30;
  int w = 60;
  int h = 30;
  String txt = "Default";
  boolean hover = false; 
  
  Button(int x, int y, int w, int h, String txt)
  {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.txt = txt;
  }
   
  void draw()
  {
    stroke(colorButton);
    fill(colorButton);
    float tw = textWidth(txt);
    text(txt, x + w / 2.0 - tw / 2.0, y + h - 12);
    if (hover) fill(red(colorButton), green(colorButton), blue(colorButton), 100);
    else noFill();
    rect(x, y, w, h);
  }
 
  void update()
  {  
    hover = mouseX >= x && mouseX <= x + w &&
            mouseY >= y && mouseY <= y + h;
  }
 
  boolean pressed()
  {
    return hover;
  }
}
