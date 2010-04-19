
// Aesthetics - Color properties, etc.
color colorBackground = color(61, 61, 61);
color colorNode = color(219, 171, 206);
color colorLine = color(171, 206, 219);

// Input Graph
Triangulation graph = new Triangulation(11);

// Interactivity
int nodeSelected = -1;
int edge = 3;

void mousePressed()
{
  // Only do stuff on LEFT mouse click.
  if (mouseButton != LEFT) return;
  
  // Check to see if we aren't on top of another node.
  nodeSelected = graph.closestNode(mouseX, mouseY, 6);
  if (nodeSelected == -1)
  {
    graph.addVertex(mouseX, mouseY);
    graph.triangulate();
  }
}

void mouseDragged()
{
  // Only drag a node if we selected one.
  if (nodeSelected == -1) return;
  graph.vx[nodeSelected] = mouseX;
  graph.vy[nodeSelected] = mouseY;
  graph.triangulate();
}

void setup()
{
  // Set the font for drawing text with.
  PFont font = createFont("Verdana", 12);
  textFont(font);
  
  // Set window/drawing properties.
  size(800, 600);
  frameRate(25);
  smooth();
  stroke(255);
  background(0, 0, 0);
}

void draw() 
{
  // Draw the background.
  background(colorBackground);
  
  // Draw the graph.
  graph.drawGraph();
  
  // Add an FPS counter.
  fill(255);
  text("FPS: " + round(frameRate), 0, 12);
  
  if (graph.vertexCount >= graph.vertexMax)
  {
    graph.flip(edge);
    edge += 1;
    if (edge >= graph.edgeCount) edge = 3;
  }
}

