
// Aesthetics - Color properties, etc.
color colorBackground = color(61, 61, 61);
color colorNode = color(219, 171, 206);
color colorLine = color(171, 206, 219);

// Namespace containing some standard geometric functions.
static class Geom
{
  // Counter-Clockwise Predicate.
  //   + Return 1  if (a,b,c) are CCW-oriented
  //   + Return 0  if (a,b,c) are colinear
  //   + Return -1 if (a,b,c) are CW-oriented 
  static int CCW(float a_x, float a_y, float b_x, float b_y, float c_x, float c_y)
  {
    float r1_x = a_x - c_x;
    float r1_y = a_y - c_y;
    float r2_x = b_x - c_x;
    float r2_y = b_y - c_y;
    float det  = r1_x * r2_y - r2_x * r1_y;
    if (det > 0)
      return 1;
    else if (det == 0)
      return 0;
    else
      return -1;
  }

  // Line-segment Intersection.
  //   + Return true if line-segment [a1,a2] intersects [b1,b2]
  //   + Assumes general-position.
  static boolean lineIntersection(float a1_x, float a1_y, float a2_x, float a2_y, float b1_x, float b1_y, float b2_x, float b2_y)
  {
    return (CCW(a1_x, a1_y, a2_x, a2_y, b1_x, b1_y) != CCW(a1_x, a1_y, a2_x, a2_y, b2_x, b2_y)) &&
           (CCW(b1_x, b1_y, b2_x, b2_y, a1_x, a1_y) != CCW(b1_x, b1_y, b2_x, b2_y, a2_x, a2_y));
  }
}

// A simple object to store a graph with some edges.
class Graph
{
  // Nodes in the graph.
  //   + A node (x,y) is stored as: px[i]=x, py[i]=y
  int nodeMax;
  int nodeCount;
  float[] px;
  float[] py;
  
  // Edges in the graph (as node indices).
  //   + An edge (a,b) is stored as: ea[i]=a, eb[i]=b
  int edgeMax;
  int edgeCount;
  int[] ea;
  int[] eb;
  
  // Constructor given the number of nodes to store in graph.
  Graph(int maxNodes)
  {
    nodeMax = maxNodes;
    nodeCount = 0;
    edgeMax = nodeMax * 3 - 6;
    edgeCount = 0;
    
    px = new float[nodeMax];
    py = new float[nodeMax];
    ea = new int[edgeMax];
    eb = new int[edgeMax];
  }
  
  // Add a node (x,y) to the graph.
  //   + Returns whether the node was added (false if too many nodes)
  boolean addNode(float x, float y)
  {
    if (nodeCount >= nodeMax) return false;
    px[nodeCount] = x;
    py[nodeCount] = y;
    nodeCount += 1;
    return true;
  }
  
  // Add an edge [a,b] to the graph.
  //   + return whether the edge was added (false is too many edges)
  boolean addEdge(int a, int b)
  {
    if (edgeCount >= edgeMax) return false;
    ea[edgeCount] = a;
    eb[edgeCount] = b;
    edgeCount += 1;
    return true;
  }
  
  // Check if the edge [a,b] overlaps any current edges in the graph.
  //   + Return true if edge [a,b] overlaps some existing edge.
  boolean edgeOverlap(int a, int b)
  {
    // Look at all the edges to see if overlap.
    for (int i = 0; i < edgeCount; i++)
    {
      // Edge [a,b] already exists so it overlaps.
      if ((ea[i] == a && eb[i] == b) ||
          (ea[i] == b && eb[i] == a)) { return true; }
      // Edge [a,b] shares a point with current edge, skip.
      if ((ea[i] == a || eb[i] == b) ||
          (ea[i] == b || eb[i] == a)) { continue; }
      // If the line segments intersect, it overlaps.
      if (Geom.lineIntersection(px[a], py[a], px[b], py[b],
            px[ea[i]], py[ea[i]], px[eb[i]], py[eb[i]]))
      {
        return true;
      }
    }
    
    // No overlaps were found.
    return false;
  } 
  
  // Triangulate the current graph.
  //   + Find a (bad) triangulation (badly) by filling edges.
  //   + NOTE: Overwrites all old edges!
  void triangulate()
  {
    // A (very) bad algorithm to compute a probably bad triangulation.
    // Takes O(n^3) time!
    // Simply loop through every possible pair of edges (without double counting)
    // and see if adding that edge overlaps an existing edge. If it doesn't, add it.
    edgeCount = 0;
    for (int i = 0; i < nodeCount; i++)
      for (int j = i+1; j < nodeCount; j++)
        if (!edgeOverlap(i, j)) addEdge(i, j);
  }
  
  // Return node that is less than distance away from (x,y).
  //   + If more than 1 node is close, closest is returned.
  //   + Return -1 if no such node.
  int closestNode(float x, float y, float distance)
  {
    if (nodeCount <= 0) return -1;
    float d = dist(x, y, px[0], py[0]);
    int j = 0;
    for (int i = 1; i < nodeCount; i++)
    {
      float td = dist(x, y, px[i], py[i]);
      if (td < d)
      {
        d = td;
        j = i;
      }
    }
    if (d < distance)
      return j;
    else
      return -1;
  }
  
  // Draw the graph.
  void drawGraph()
  {
    // Draw all the edges.
    for (int i = 0; i < edgeCount; i++)
    {
      stroke(colorLine);
      line(px[ea[i]], py[ea[i]], px[eb[i]], py[eb[i]]);
    }

    // Draw all the nodes.
    for (int i = 0; i < nodeCount; i++)
    {
      fill(colorNode);
      stroke(colorNode);
      ellipse(px[i], py[i], 10, 10);
    }
  }
}

// Input Graph
Graph graph = new Graph(11);

////
// Interactivity
////
int nodeSelected = -1;

void mousePressed()
{
  // Only do stuff on LEFT mouse click.
  if (mouseButton != LEFT) return;
  
  // Check to see if we aren't on top of another node.
  nodeSelected = graph.closestNode(mouseX, mouseY, 6);
  if (nodeSelected == -1)
  {
    graph.addNode(mouseX, mouseY);
    graph.triangulate();
  }
}

void mouseDragged()
{
  // Only drag a node if we selected one.
  if (nodeSelected == -1) return;
  graph.px[nodeSelected] = mouseX;
  graph.py[nodeSelected] = mouseY;
  graph.triangulate();
}

void setup()
{
  // Set the font for drawing text with.
  PFont font = createFont("Verdana", 12);
  textFont(font);
  
  // Set window/drawing properties.
  size(800, 600);
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
}

