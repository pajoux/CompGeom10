
/// Aesthetics - Color properties, etc.
color colorBackground = color(61, 61, 61);
color colorNode = color(219, 171, 206);
color colorLine = color(171, 206, 219);
color colorButton = color(206, 219, 171);
color colorGreen = color(206, 219, 171);
int widthInit  = 800;
int heightInit = 600;
float drawScale = 1.0;

/// Mouse Mode - Mode of the clicking.
final int MODE_TRI  = 0;  // Placing/Moving triangulation points.
final int MODE_FLIP = 1;  // Navigating the flip graph.
int mouseMode = MODE_TRI;

/// Drawing Mode - What type of animation to be doing.
final int ANIM_TRI_SHRINK = 1;
final int ANIM_NONE = 0;
int animMode = ANIM_NONE;

/// Buttons - All the buttons.
Button delButton   = new Button(5, heightInit - 30, 120, 30, "Delaunay Edges");
Button angleButton = new Button(5 + 120 + 5, heightInit - 30, 120, 30, "Minimum Angle");
Button ftodButton  = new Button(5 + 240 + 10, heightInit - 30, 120, 30, "Flips to Delaunay");
Button flipButton  = new Button(5, heightInit - 30, 160, 30, "Generate Flip Graph");
Button resetButton = new Button(widthInit - 70, heightInit - 30, 60, 30, "Reset");

/// Triangulation Properties
Triangulation tri = new Triangulation(8);
float triSmallWidth  = widthInit / 5.0;
float triSmallHeight = heightInit / 5.0;
float triAnim = 1.0;

PGraphics pg;

// Input Graph
FGraph fgraph = null;
FNode node;

// Interactivity
int nodeSelected = -1;
int edge = 3;

// Draw the button.
void pressResetButton()
{
  mouseMode = MODE_TRI;
  fgraph = null;
  tri = new Triangulation(8);
  animMode = ANIM_NONE;
  triAnim = 1.0;
  drawScale = 1.0;
  resetButton.hover = false;
}
void pressFlipButton()
{
  animMode = ANIM_TRI_SHRINK;
  mouseMode = MODE_FLIP;
  fgraph = new FGraph(tri);
  fgraph.embedify();
  flipButton.hover = false;
}

void mousePressed()
{
  // If the mouse if over the button, handle the button press.
  if (flipButton.pressed())
  {
    pressFlipButton();
    return;
  }
  else if (resetButton.pressed())
  {
    pressResetButton();
    return;
  }
  else if (delButton.pressed())
  {
    fgraph.currentMode = FGraph.DEL_EDGES_MODE;
    return;
  }
  else if (angleButton.pressed())
  {
    fgraph.currentMode = FGraph.MIN_ANGLE_MODE;
    return;
  }
  else if (ftodButton.pressed())
  {
    return;
  }
  
  // Handle general mouse input.
  switch (mouseMode)
  {
    case MODE_TRI:
    {
      // Try to select a node.
      nodeSelected = tri.closestNode(mouseX, mouseY, 10);
      // If nothing is selected, place a new point.
      if (nodeSelected == -1)
      {
        tri.addVertex(mouseX, mouseY);
        tri.triangulate();
      }
      break;
    }
    case MODE_FLIP:
    {
      if (node != null)
      {
        tri = node.tri;
      }
      break;
    }
  }
  return;
}

void keyPressed()
{
  if (key == ' ')
  {
    node = null;
  }
}

void mouseDragged()
{
  // Only drag a node if we selected one.
  switch (mouseMode)
  {
    case MODE_TRI:
    {
      if (nodeSelected == -1) return;
      tri.vx[nodeSelected] = mouseX;
      tri.vy[nodeSelected] = mouseY;
      tri.triangulate();
      break;
    }
    case MODE_FLIP:
    {
      fgraph.rotation += ((mouseX - pmouseX) / 180.0 * PI);
      fgraph.rotation2 += ((mouseY - pmouseY));
      break;
    }
  }
}

void setup()
{
  // Set the font for drawing text with.
  PFont font = createFont("Verdana", 12);
  textFont(font);
  
  // Set window/drawing properties.
  size(widthInit, heightInit);
  frameRate(25);
  smooth();
  
  pg = createGraphics(widthInit, heightInit, P3D);
  pg.smooth();
}

void draw() 
{ 
  // Draw the background.
  background(colorBackground);

  // Draw the flip graph.
  if (mouseMode == MODE_FLIP)
  {
    // Draw it.
    if (!mousePressed)
    { FNode temp = fgraph.closestNode(mouseX, mouseY, 10); if (temp != null) node = temp; }
    fgraph.draw(node);
    
    // Draw a "fade" in.
    if (animMode == ANIM_TRI_SHRINK)
    {
      fill(red(colorBackground), green(colorBackground), blue(colorBackground), 255 * triAnim);
      noStroke();
      rect(0, 0, width, height);
    }
  }
  
  // Draw the triangulation.
  // Update the animation if needed.
  if (animMode == ANIM_TRI_SHRINK)
  {
    triAnim = triAnim * (1.0 - 0.2);
    if (triAnim <= 0.0001) animMode = ANIM_NONE;
  }
  noFill();
  stroke(red(colorGreen), green(colorGreen), blue(colorGreen), 255 * (1.0 - triAnim));
  rect(-1, -1, triSmallWidth+1, triSmallHeight+1);
  float s = 1.0 - triAnim;
  tri.drawGraph(0, 0, s * triSmallWidth + triAnim * width, s * triSmallHeight + triAnim * height);
  
  // Add an FPS counter.
  fill(255);
  text("FPS: " + round(frameRate), width - 50, 12);
  
  // Draw the flip button.
  if (mouseMode == MODE_TRI)
  {
    flipButton.update(); flipButton.draw();
  }
  else if (mouseMode == MODE_FLIP)
  {
    resetButton.update(); resetButton.draw();
    delButton.update(); delButton.draw();
    angleButton.update(); angleButton.draw();
    ftodButton.update(); ftodButton.draw();
  }
}

