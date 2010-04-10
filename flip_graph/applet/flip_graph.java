import processing.core.*; 
import processing.xml.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class flip_graph extends PApplet {


int nodeCount = 10;
int nodeInput = 0;
int nodeSelected = -1;
float[] px = new float[nodeCount];
float[] py = new float[nodeCount];

int maxEdges = nodeCount * 3 - 6;
int edgeCount = 0;
int[] ea = new int[maxEdges];
int[] eb = new int[maxEdges];
boolean[] evalid = new boolean[maxEdges];

/////////////////////////////////////////////////////////////////////////////
// Drawing Routines
/////////////////////////////////////////////////////////////////////////////

public void addNode(float x, float y)
{
  if (nodeInput < nodeCount)
  {
    px[nodeInput] = x;
    py[nodeInput] = y;
    nodeInput += 1;
  }
}

public void drawNode(float x, float y)
{
  // TODO: Set color.
  stroke(255);
  ellipse(x, y, 10, 10);
}

public void drawTriangulation(int[] ea, int[] eb, int num)
{
  for (int i = 0; i < num; i++)
  {
    line(px[ea[i]], py[ea[i]], px[eb[i]], py[eb[i]]);
  }
}

/////////////////////////////////////////////////////////////////////////////
// Geometric Routines
/////////////////////////////////////////////////////////////////////////////

// returns 1 if (a,b,c) are CCW-oriented;
// returns 0 if (a,b,c) are colinear;
// returns -1 if (a,b,c) are CW-oriented.
public int CCW(float a_x, float a_y, float b_x, float b_y, float c_x, float c_y)
{
  float r1_x = a_x - c_x;
  float r1_y = a_y - c_y;
  float r2_x = b_x - c_x;
  float r2_y = b_y - c_y;
  
  float det = r1_x * r2_y - r2_x * r1_y;
  
  if (det > 0)
    return 1;
  else if (det == 0)
    return 0;
  else
    return -1;
}

// returns true if the line segment [a1, a2] intersects [b1, b2]
// only works for points in general position
public boolean lineIntersection(float a1_x, float a1_y, float a2_x, float a2_y, float b1_x, float b1_y, float b2_x, float b2_y)
{
  return (CCW(a1_x, a1_y, a2_x, a2_y, b1_x, b1_y) != CCW(a1_x, a1_y, a2_x, a2_y, b2_x, b2_y)) &&
         (CCW(b1_x, b1_y, b2_x, b2_y, a1_x, a1_y) != CCW(b1_x, b1_y, b2_x, b2_y, a2_x, a2_y));
}

// Check to see if line segment from node[a] to node[b] intersects
// any node we currently have already added.
public boolean doesEdgeIntersect(int a, int b)
{
  for (int i = 0; i < edgeCount; i++)
  {
    // Edge already exists.
    if ((ea[i] == a && eb[i] == b) ||
        (ea[i] == b && eb[i] == a))
    { 
      return true;
    }
    // Edge share one common point.
    if (ea[i] == a || ea[i] == b ||
        eb[i] == a || eb[i] == b)
    {
      continue;
    }
    if (lineIntersection(px[a], py[a], px[b], py[b], px[ea[i]], py[ea[i]], px[eb[i]], py[eb[i]]))
    {
      return true;
    }
  }
  return false;
}

public void tirangulateInc(int i)
{
  //int i = nodeInput - 1;
  for (int j = 0; j < nodeInput; j++)
  {
    if (j == i) continue;
    // Check to see if this edge intersects another edge.
    if (!doesEdgeIntersect(i, j))
    {
      ea[edgeCount] = i;
      eb[edgeCount] = j;
      evalid[edgeCount] = true;
      edgeCount++;
    }
  }
}

// Return all edges from node I in triangulate.
public void markBadEdges(int i)
{
  for (int k = 0; k < edgeCount; k++)
  {
    evalid[k] = true;
  }
  for (int j = 0; j < edgeCount; j++)
  {
    // Look for edges out of this node.
    if (ea[j] == i)
    {
      if (doesEdgeIntersect(i, eb[j]))
        evalid[j] = false;
    }
    else if (eb[j] == i)
    {
      if (doesEdgeIntersect(i, ea[j]))
        evalid[j] = false;
    }
  }
}

public void triangulate()
{
  // Loop through every possible edge pair.
  for (int i = 0; i < nodeInput; i++)
  {
    for (int j = i+1; j < nodeInput; j++)
    {
      // Check to see if this edge intersects another edge.
      if (!doesEdgeIntersect(i, j))
      {
        ea[edgeCount] = i;
        eb[edgeCount] = j;
        edgeCount++;
      }
    }
  }
}


/////////////////////////////////////////////////////////////////////////////
// Interactivity
/////////////////////////////////////////////////////////////////////////////

// Return index of node that is less than DISTANCE away from X and Y
// -1 is returned if no node that meets this property exists.
public int getClosestNode(float x, float y, float distance)
{
  if (nodeInput <= 0) return -1;
  float d = dist(x, y, px[0], py[0]);
  int j = 0;
  for (int i = 1; i < nodeInput; i++)
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

public void mousePressed()
{
  // Only do stuff on LEFT mouse click.
  if (mouseButton != LEFT) return;
  
  // Check to see if we aren't on top of another node.
  nodeSelected = getClosestNode(mouseX, mouseY, 6);
  if (nodeSelected == -1)
  {
    addNode(mouseX, mouseY);
    // Update triangulation.
    tirangulateInc(nodeInput - 1);
  }
}

public void mouseDragged()
{
  // Only drag a node if we selected one.
  if (nodeSelected == -1) return;
  
  // Change the positions.
  px[nodeSelected] = mouseX;
  py[nodeSelected] = mouseY;
  
  edgeCount = 0;
  triangulate();
  
//  // Mark any new bad edges.
//  markBadEdges(nodeSelected);
//  // Remove those edges from the list.
//  int tombCount = 0;
//  for (int i = 0; i < edgeCount; i++)
//  {
//    if (!evalid[i]) tombCount++;
//    else
//    {
//      ea[i - tombCount] = ea[i];
//      eb[i - tombCount] = eb[i];
//    }
//  }
//  edgeCount -= tombCount;
//  // Re-triangulate that point.
//  tirangulateInc(nodeSelected);
}

public void setup()
{
  size(800, 600);
  stroke(255);
  background(0, 0, 0);
}

public void draw() 
{
  fill(0);
  noStroke();
  rect(0,0,width,height);
  for (int i = 0; i < nodeInput; i++)
  {
    drawNode(px[i], py[i]);
  }
  drawTriangulation(ea, eb, edgeCount);
}


  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#FFFFFF", "flip_graph" });
  }
}
