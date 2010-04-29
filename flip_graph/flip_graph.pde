import processing.opengl.*;

/// Aesthetics - Color properties, etc.
color colorBackground = color(61, 61, 61);
color colorNode = color(219, 171, 206);
color colorLine = color(171, 206, 219);
color colorButton = color(206, 219, 171);
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

/// Flip Button - Properties for the "flip" button.
int flipButtonX = 5;
int flipButtonY = heightInit - 30;
int flipButtonW = 60;
int flipButtonH = 30;
boolean flipButtonHover = false;

/// Triangulation Properties
Triangulation tri = new Triangulation(8);
float triSmallWidth  = widthInit / 5.0;
float triSmallHeight = heightInit / 5.0;
float triAnim = 1.0;

// Input Graph
FGraph fgraph = null;
FNode node;

// Interactivity
int nodeSelected = -1;
int edge = 3;

// Draw the button.
void drawFlipButton()
{
  stroke(colorButton);
  fill(colorButton);
  text("Flip It", 18, height - 12, 12);
  if (flipButtonHover) fill(red(colorButton), green(colorButton), blue(colorButton), 100);
  else noFill();
  rect(flipButtonX, flipButtonY, flipButtonW, flipButtonH);
}
void updateFlipButton()
{
  flipButtonHover = mouseX >= flipButtonX && mouseX <= flipButtonX + flipButtonW &&
                    mouseY >= flipButtonY && mouseY <= flipButtonY + flipButtonH;
}
void pressFlipButton()
{
  animMode = ANIM_TRI_SHRINK;
  mouseMode = MODE_FLIP;
  fgraph = new FGraph(tri);
  fgraph.embedify();
  flipButtonHover = false;
}

void mousePressed()
{
  // If the mouse if over the button, handle the button press.
  if (flipButtonHover)
  {
    pressFlipButton();
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

void mouseDragged()
{
  // Only drag a node if we selected one.
  if (nodeSelected == -1) return;
  tri.vx[nodeSelected] = mouseX;
  tri.vy[nodeSelected] = mouseY;
  tri.triangulate();
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
}

void draw() 
{ 
  // Draw the background.
  background(colorBackground);

  // Draw the flip graph.
  if (mouseMode == MODE_FLIP)
  {
    // Draw it.
    fgraph.draw();
    node = fgraph.closestNode(mouseX, mouseY, 20);
    
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
  fill(128, 128, 128, 255 * (1.0 - triAnim));
  noStroke();
  rect(0, 0, triSmallWidth, triSmallHeight);
  float s = 1.0 - triAnim;
  tri.drawGraph(0, 0, s * triSmallWidth + triAnim * width, s * triSmallHeight + triAnim * height);
  
  // Draw the neighbors for the flip graph.
  if (node != null)
  {
    int count = node.neighborNodes.size();
    for (int i = 0; i < count; i++)
    {
      FNode nn = (FNode)node.neighborNodes.get(i);
      stroke(100, 20, 20);
      line(node.x, node.y, nn.x, nn.y);
    }
    
    fill(255, 0, 0);
    stroke(255, 0, 0);
    ellipse(node.x, node.y, 10, 10);
  }
  
  // Add an FPS counter.
  fill(255);
  text("FPS: " + round(frameRate), width - 50, 12);
  
  // Draw the flip button.
  if (mouseMode == MODE_TRI)
  {
    updateFlipButton();
    drawFlipButton();
  }
}

