
// Aesthetics - Color properties, etc.
color colorBackground = color(61, 61, 61);
color colorNode = color(219, 171, 206);
color colorLine = color(171, 206, 219);

// Input Graph
Triangulation graph = new Triangulation(11);
FGraph fgraph = null;
FNode node;

// Interactivity
int nodeSelected = -1;
int edge = 3;
//
//void bfs(Triangulation t)
//{
//  HashMap hm = new HashMap();
//  LinkedList queue = new LinkedList();
//  queue.addLast(t);
//  
//  while (!queue.isEmpty())
//  {
//    // Get the next triangulation to work with.
//    Triangulation tri = (Triangulation)queue.removeFirst();
//    
//    // If we have already added it to our set, skip it.
//    if (hm.containsKey(tri))
//      continue;
//      
//    // Add it to our map.
//    hm.put(tri, tri);
//    
//    // Loop through each edge.
//    for (int e = 0; e < tri.edgeCount; e++)
//    {
//      if (tri.canFlip(e))
//      {
//        Triangulation triFlip = tri.clone();
//        triFlip.flip(e);
//        queue.addLast(triFlip);
//      }
//    }
//  }
//  
//  println("There are " + hm.size() + " nodes in the flip graph!");
//}

void mousePressed()
{
  // Only do stuff on LEFT mouse click.
  if (mouseButton != LEFT)
  {
    if (fgraph == null)
    {
      fgraph = new FGraph(graph);
    }
    else
    {
      fgraph.embedify();
    }
    return;
  }
  
  if (fgraph != null)
  {
    if (node != null)
    {
      graph = node.tri;
    }
    return;
  }
  
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
  
  if (graph.vertexCount >= graph.vertexMax)
  {
    graph.flip(edge);
    edge += 1;
    if (edge >= graph.edgeCount) edge = 3;
  }
  
  fill(0, 0, 0, 200);
  noStroke();
  rect(0, 0, width, height);
  
  if (fgraph != null)
  {
    fgraph.draw();
    node = fgraph.closestNode(mouseX, mouseY, 20);
  }
  
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
  text("FPS: " + round(frameRate), 0, 12);
}

