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


// Aesthetics - Color properties, etc.
int colorBackground = color(61, 61, 61);
int colorNode = color(219, 171, 206);
int colorLine = color(171, 206, 219);

// Input Graph
Triangulation graph = new Triangulation(11);

// Interactivity
int nodeSelected = -1;
int edge = 3;

public void mousePressed()
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

public void mouseDragged()
{
  // Only drag a node if we selected one.
  if (nodeSelected == -1) return;
  graph.vx[nodeSelected] = mouseX;
  graph.vy[nodeSelected] = mouseY;
  graph.triangulate();
}

public void setup()
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

public void draw() 
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


// Namespace containing some standard geometric functions.
static class Geom
{
  // Counter-Clockwise Predicate.
  //   + Return 1  if (a,b,c) are CCW-oriented
  //   + Return 0  if (a,b,c) are colinear
  //   + Return -1 if (a,b,c) are CW-oriented 
  public static int CCW(float a_x, float a_y, float b_x, float b_y, float c_x, float c_y)
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
  public static boolean lineIntersection(float a1_x, float a1_y, float a2_x, float a2_y, float b1_x, float b1_y, float b2_x, float b2_y)
  {
    return (CCW(a1_x, a1_y, a2_x, a2_y, b1_x, b1_y) != CCW(a1_x, a1_y, a2_x, a2_y, b2_x, b2_y)) &&
           (CCW(b1_x, b1_y, b2_x, b2_y, a1_x, a1_y) != CCW(b1_x, b1_y, b2_x, b2_y, a2_x, a2_y));
  }
}

// Holds a planar embedding and triangulation of a set of 2D vertices.
class Triangulation
{
  // Vertices.
  int vertexMax, vertexCount;
  float[] vx, vy;
  
  // Edges.
  int edgeMax, edgeCount;
  int[] ev1, ev2;
  int[] et1, et2;
  
  // Triangles.
  int triMax, triCount;
  int[] tv1, tv2, tv3;
  int[] te1, te2, te3;
  
  // Create a new triangulation that can hold [maxVertices] vertices.
  Triangulation(int maxVertices)
  {
    vertexMax = maxVertices;
    // vertexMax + 1 (because we also have the infinite 
    edgeMax = (vertexMax + 1) * 3 - 6;
    triMax = (vertexMax + 1) * 2 - 4;
    vertexCount = edgeCount = triCount = 0;
    
    vx = new float[vertexMax];
    vy = new float[vertexMax];
    ev1 = new int[edgeMax];
    ev2 = new int[edgeMax];
    et1 = new int[edgeMax];
    et2 = new int[edgeMax];
    tv1 = new int[triMax];
    tv2 = new int[triMax];
    tv3 = new int[triMax];
    te1 = new int[triMax];
    te2 = new int[triMax];
    te3 = new int[triMax];
  }
  
  // Add the vertex ([x],[y]) to the triangulation, if possible.
  public void addVertex(float x, float y)
  {
    if (vertexCount >= vertexMax) return;
    vx[vertexCount] = x;
    vy[vertexCount] = y;
    vertexCount += 1;
  }
  
  // Return the triangle that vertex [v] is inside of.
  public int findTriangle(int v)
  {
    for (int t = 0; t < triCount; t++)
      if (inTriangle(v, tv1[t], tv2[t], tv3[t])) 
        return t;

    return -1;
  }
  
  // Compute a triangulation of the vertices (overwrites old edges/triangles).
  public void triangulate()
  { 
    // Start with triangle v0, v1, v2.
    if (vertexCount < 3) return;
    tv1[0] = 0; tv2[0] = 1; tv3[0] = 2;
    te1[0] = 0; te2[0] = 1; te3[0] = 2;

    tv1[1] = 0; tv2[1] = 1; tv3[1] = -1;
    te1[1] = 0; te2[1] = 3; te3[1] = 4;

    tv1[2] = 1; tv2[2] = 2; tv3[2] = -1;
    te1[2] = 1; te2[2] = 5; te3[2] = 3;
    
    tv1[3] = 2; tv2[3] = 0; tv3[3] = -1;
    te1[3] = 2; te2[3] = 4; te3[3] = 5;
    
    ev1[0] =  0; ev2[0] =  1; et1[0] = 0; et2[0] = 1;
    ev1[1] =  1; ev2[1] =  2; et1[1] = 0; et2[1] = 2;
    ev1[2] =  2; ev2[2] =  0; et1[2] = 0; et2[2] = 3;
    ev1[3] =  1; ev2[3] = -1; et1[3] = 1; et2[3] = 2;
    ev1[4] =  0; ev2[4] = -1; et1[4] = 1; et2[4] = 3;
    ev1[5] =  2; ev2[5] = -1; et1[5] = 2; et2[5] = 3;

    edgeCount = 6;
    triCount = 4;
    
    // Loop through the rest of the points, adding triangles.
    for (int v = 3; v < vertexCount; v++)
    {
      // record the triCount before adding a bunch of triangles
      addPointInTriangulation(v);
    }
  }
  
  public void addPointInTriangulation(int v)
  {
    ArrayList triHits = new ArrayList();
    for (int t = 0; t < triCount; t++)
      if (inTriangle(v, tv1[t], tv2[t], tv3[t]))
        triHits.add(t);
    
    if (triHits.size() == 1)
      addPointInTriangle(v, ((Integer)triHits.get(0)).intValue());    
    else
    {
      // multiple triangles indicates that we're in the infinite face
      // but we're exposed to more than one edge on the convex hull
      int infRightPoint = -1;
      int infLeftPoint = -1;
      int infRightEdge = -1;
      int infLeftEdge = -1;      
      int infRightTri = -1;
      int infLeftTri = -1;
      
      for (int i = 0; i < triHits.size(); i++)
      {
        int t = ((Integer)triHits.get(i)).intValue();
        replaceInfinitePoint(t, v);
        
        int v1, v2;
        if (tv1[t] == v)
        {
          v1 = tv2[t];
          v2 = tv3[t]; 
        }
        else if (tv2[t] == v)
        {
          v1 = tv1[t];
          v2 = tv3[t]; 
        }
        else
        {
          v1 = tv1[t];
          v2 = tv2[t];
        }
                         
        // determine which edge is "left"
        int vLeft, vRight;
        if (Geom.CCW(vx[v], vy[v], vx[v1], vy[v1], vx[v2], vx[v2]) == -1) 
        {
          vRight = v2;
          vLeft = v1;
        }
        else
        {
          vRight = v1;
          vLeft = v2;
        }

        int eLeft = triEdgeBetweenPoints(t, v, vLeft);
        int eRight = triEdgeBetweenPoints(t, v, vRight);
        
        // check to see if these points are the maximum "left" or "right"
        if (infRightPoint == -1 || Geom.CCW(vx[v], vy[v], vx[infRightPoint], vy[infRightPoint], vx[vRight], vy[vRight]) == -1)
        {
          infRightEdge = eRight;
          infRightPoint = vRight; 
          infRightTri = t;
        }
        if (infLeftPoint == -1 || Geom.CCW(vx[v], vy[v], vx[infRightPoint], vy[infLeftPoint], vx[vLeft], vy[vLeft]) == 1)
        {
          infLeftEdge = eLeft;
          infLeftPoint = vLeft; 
          infLeftTri = t;
        }
      }
      
      // infinite edges
      int eInfLeft = edgeCount++;
      int eInfRight = edgeCount++;
      int eInfV = edgeCount++;
      
      int tInfLeft = triCount++;
      int tInfRight = triCount++;
      
      ev1[eInfLeft] = -1; ev2[eInfLeft] = infLeftPoint;
      et1[eInfLeft] = infLeftTri; et2[eInfLeft] = tInfLeft;
      ev1[eInfRight] = -1; ev2[eInfRight] = infRightPoint;
      et1[eInfRight] = infRightTri; et1[eInfRight] = tInfRight;
      ev1[eInfV] = -1; ev2[eInfV] = v;
      et1[eInfV] = tInfLeft; et1[eInfV] = tInfRight;
      
      // now we need to create two new infinite triangle for v
      tv1[tInfLeft] = v; tv2[tInfLeft] = infLeftPoint; tv3[tInfLeft] = -1;
      te1[tInfLeft] = infLeftEdge; te2[tInfLeft] = eInfLeft; te3[tInfLeft] = eInfV;
      
      tv1[tInfRight] = v; tv2[tInfRight] = infRightPoint; tv3[tInfRight] = -1;
      te1[tInfRight] = infRightEdge; te2[tInfRight] = eInfRight; te3[tInfRight] = eInfV;
    }
  }
  
  public void replaceInfinitePoint(int v, int t)
  {
    if (tv1[t] == -1)
    {
      tv1[t] = v;
      // the edge could have already been replaced by
      // a previous call to replaceInfinitePoint
      if (ev1[te1[t]] == -1)
        ev1[te1[t]] = v;
      else if (ev2[te1[t]] == -1)
        ev2[te1[t]] = v;

      // the edge could have already been replaced by
      // a previous call to replaceInfinitePoint
      if (ev1[te3[t]] == -1)
        ev1[te3[t]] = v;
      else if (ev2[te3[t]] == -1)
        ev2[te3[t]] = v;      
    }
    else if (tv2[t] == -1)
    {
      tv2[t] = v;
      // the edge could have already been replaced by
      // a previous call to replaceInfinitePoint
      if (ev1[te1[t]] == -1)
        ev1[te1[t]] = v;
      else if (ev2[te1[t]] == -1)
        ev2[te1[t]] = v;

      // the edge could have already been replaced by
      // a previous call to replaceInfinitePoint
      if (ev1[te2[t]] == -1)
        ev1[te2[t]] = v;
      else if (ev2[te2[t]] == -1)
        ev2[te2[t]] = v;            
    }
    else
    {
      tv3[t] = v;
      // the edge could have already been replaced by
      // a previous call to replaceInfinitePoint
      if (ev1[te3[t]] == -1)
        ev1[te3[t]] = v;
      else if (ev2[te3[t]] == -1)
        ev2[te3[t]] = v;

      // the edge could have already been replaced by
      // a previous call to replaceInfinitePoint
      if (ev1[te2[t]] == -1)
        ev1[te2[t]] = v;
      else if (ev2[te2[t]] == -1)
        ev2[te2[t]] = v;                  
    }
  }
  
  public void addPointInTriangle(int v, int t)
  {
    int e1 = te1[t], e2 = te2[t], e3 = te3[t];

    // Add three edges.
    ev1[edgeCount+0] = tv1[t]; ev2[edgeCount+0] = v;
    ev1[edgeCount+1] = tv2[t]; ev2[edgeCount+1] = v;
    ev1[edgeCount+2] = tv3[t]; ev2[edgeCount+2] = v;
      
    // triangle 2
    tv1[triCount] = tv2[t]; tv2[triCount] = tv3[t]; tv3[triCount] = v;
    te1[triCount] = te2[t]; te2[triCount] = edgeCount+2; te3[triCount] = edgeCount+1;
      
    // triangle 3
    tv1[triCount+1] = tv3[t]; tv2[triCount+1] = tv1[t]; tv3[triCount+1] = v;
    te1[triCount+1] = te3[t]; te2[triCount+1] = edgeCount; te3[triCount+1] = edgeCount+2;
      
    // triangle 1
    tv3[t] = v; te2[t] = edgeCount+1; te3[t] = edgeCount;
    
    println("triangle1 " + tv1[t] + ", " + tv2[t] + ", " + tv3[t]);
    println("triangle2 " + tv1[triCount] + ", " + tv2[triCount] + ", " + tv3[triCount]);
    println("triangle3 " + tv1[triCount+1] + ", " + tv2[triCount+1] + ", " + tv3[triCount+1]);
    
    // Update the edge-triangle stuff.
    if (e1 == -1) { } else if (et1[e1] == t) { et1[e1] = t; et2[e1] = et2[e1]; } else { et1[e1] = et1[e1]; et2[e1] = t; }
    if (e2 == -1) { } else if (et1[e2] == t) { et1[e2] = triCount; et2[e2] = et2[e2]; } else { et1[e2] = et1[e2]; et2[e2] = triCount; }
    if (e3 == -1) { } else if (et1[e3] == t) { et1[e3] = triCount+1; et2[e3] = et2[e3]; } else { et1[e3] = et1[e3]; et2[e3] = triCount+1; }
    et1[edgeCount+0] = triCount+1; et2[edgeCount+0] = t;
    et1[edgeCount+1] = t; et2[edgeCount+1] = triCount;
    et1[edgeCount+2] = triCount; et2[edgeCount+2] = triCount+1;
    
    // Increase number of edges/triangles.
    edgeCount += 3;
    triCount += 2;
  }
  
  // Make a deep copy of this triangulation.
  public Triangulation copy()
  {
    Triangulation t = new Triangulation(vertexMax);
    
    // Copy scalar values.
    t.vertexMax = vertexMax;
    t.vertexCount = vertexCount;
    t.edgeMax = edgeMax;
    t.edgeCount = edgeCount;
    t.triMax = triMax;
    t.triCount = triCount;
    
    // Copy arrays.
    arrayCopy(vx, t.vx);
    arrayCopy(vy, t.vy);
    arrayCopy(ev1, t.ev1);
    arrayCopy(ev2, t.ev2);
    arrayCopy(et1, t.et1);
    arrayCopy(et2, t.et2);
    arrayCopy(tv1, t.tv1);
    arrayCopy(tv2, t.tv2);
    arrayCopy(tv3, t.tv3);
    arrayCopy(te1, t.te1);
    arrayCopy(te2, t.te2);
    arrayCopy(te3, t.te3);
    
    // Return the copy.
    return t;
  }
  
  // Test if two triangulations are equal (assuming same vertices).
  public boolean equals(Triangulation t)
  {
    // Check the edge listing up to (a,b) = (b,a).
    if (edgeCount != t.edgeCount) return false;
    for (int e = 0; e < edgeCount; e++)
    {
      if (!(((ev1[e] == t.ev1[e]) && (ev2[e] == t.ev2[e])) ||
          ((ev1[e] == t.ev2[e]) && (ev2[e] == t.ev1[e]))))
      {
        return false;
      }
    }
    return true;
  }
  
  // Return whether or not [edge] can be flipped or not.
  public boolean canFlip(int edge)
  {
    int t1 = et1[edge];
    int t2 = et2[edge];
    
    int v1 = ev1[edge];
    int v2 = ev2[edge];
    
    if (v1 == -1 || v2 == -1)
      return false;
    
    int v3 = triPointNotOnEdge(t1, edge);
    int v4 = triPointNotOnEdge(t2, edge);
        
    return !inTriangle(v1, v2, v3, v4) && !inTriangle(v2, v1, v3, v4) &&
           !inTriangle(v3, v1, v2, v4) && !inTriangle(v4, v1, v2, v3);
  }
    
  public boolean inInfiniteTriangle(int x, int a, int b)
  {
    int ccw_x = ccw_x = Geom.CCW(vx[x], vy[x], vx[a], vy[a], vx[b], vy[b]);
    int ccw_i = -1;

    // since we're testing for an infinite triangle test, we know that
    // the edge ab is on the convex hull.
    // so the infinite triangle we are testing is on the opposite side
    // of the convex hull.
    // in order to determine which side the convex hull is on, we want to find
    // a point in the convex hull
    int i;
    for (i = 0; i < vertexCount; i++)
    {
      // if i is a, b, or x then it is not in the convex hull
      if (i == a || i == b || i == x)
        continue;

      ccw_i = Geom.CCW(vx[i], vy[i], vx[a], vy[a], vx[b], vy[b]);
      
      // if i is colinear with a, b, we gain no orientation information.
      // otherwise, we've found a point in the convex hull
      if (ccw_i != 0)
        break;
    }
    
    // all points are colinear with a, b
    if (i == vertexCount)
      return false;

    if (ccw_x == 0)
      return false;
    else
      return ccw_x != ccw_i;  // x is outside the convex hull
  }
  
  public boolean inTriangle(int x, int a, int b, int c)
  {
    // the case where one of the points is the infinite point
    // degenerates to a line-side test
    if (a == -1)
      return inInfiniteTriangle(x, b, c);
    else if (b == -1)
      return inInfiniteTriangle(x, c, a);
    else if (c == -1)
      return inInfiniteTriangle(x, a, b);
      
    int ccw1 = Geom.CCW(vx[x], vy[x], vx[a], vy[a], vx[b], vy[b]);
    int ccw2 = Geom.CCW(vx[x], vy[x], vx[b], vy[b], vx[c], vy[c]);
    int ccw3 = Geom.CCW(vx[x], vy[x], vx[c], vy[c], vx[a], vy[a]);
    
    // on a triangle edge
    if (ccw1 == 0 || ccw2 == 0 || ccw3 == 0)
      return true;
    else if (ccw1 == ccw2 && ccw2 == ccw3)
      return true;
    else
      return false;
  }
  
  // precondition: canFlip(edge) is true
  public void flip (int edge)
  {
    if (!canFlip(edge)) return;
    
    // two triangles on this edge
    int tri1 = et1[edge];
    int tri2 = et2[edge];
    
    // the end points of this edge
    int vEdge1 = ev1[edge];
    int vEdge2 = ev2[edge];
      
    // the points on each triangle not on this edge
    int vNot1 = triPointNotOnEdge(tri1, edge);
    int vNot2 = triPointNotOnEdge(tri2, edge);
    
    // flip the edge
    ev1[edge] = vNot1;
    ev2[edge] = vNot2;
    
    int t1Edge1 = triEdgeBetweenPoints(tri1, vNot1, vEdge1);
    int t1Edge2 = triEdgeBetweenPoints(tri2, vEdge1, vNot2);
    int t1Edge3 = edge;
    
    int t2Edge1 = triEdgeBetweenPoints(tri2, vNot2, vEdge2);
    int t2Edge2 = triEdgeBetweenPoints(tri1, vEdge2, vNot1);
    int t2Edge3 = edge;
    
    // update triangle 1
    updateTriangle(tri1, vNot1, vEdge1, vNot2,
                   t1Edge1, t1Edge2, t1Edge3);

    // update triangle 2
    updateTriangle(tri2, vNot2, vEdge2, vNot1,
                   t2Edge1, t2Edge2, t2Edge3);
    
    // since edge te2[tri1] switched from triangle 2 to triangle 1, we need to update this in the
    // edge to triangle map
    switchTriangleEdgeMap(te2[tri1], tri2, tri1);
    
    // since edge te2[tri1] switched from triangle 1 to triangle 2, we need to update this in the
    // edge to triangle map
    switchTriangleEdgeMap(te2[tri2], tri1, tri2);
  }
  
  // switches the triangle entry for an edge from t1 to t2
  // precondition: t1 is in the edge to triangle map for edge.
  public void switchTriangleEdgeMap(int edge, int t1, int t2)
  {
    if (et1[edge] == t1)
      et1[edge] = t2;
    else if (et2[edge] == t1)
      et2[edge] = t2;
  }

  public void updateTriangle(int tri, int v1, int v2, int v3,
                      int e1, int e2, int e3)
  {
    tv1[tri] = v1;
    tv2[tri] = v2;
    tv3[tri] = v3;
    te1[tri] = e1;
    te2[tri] = e2;
    te3[tri] = e3;
  }

  // precondition: two points are on triangle
  public int triEdgeBetweenPoints (int tri, int v1, int v2)
  {
    if ((v1 == tv1[tri] && v2 == tv2[tri]) ||
        (v2 == tv1[tri] && v1 == tv2[tri]))
      return te1[tri];
    else if ((v1 == tv2[tri] && v2 == tv3[tri]) ||
             (v2 == tv2[tri] && v1 == tv3[tri]))
      return te2[tri];
    else if ((v1 == tv3[tri] && v2 == tv1[tri]) ||
             (v2 == tv3[tri] && v1 == tv1[tri]))
      return te3[tri];
    else
      return -1;
  }
  
  // precondition: edge is on triangle
  public int triPointNotOnEdge (int tri, int edge)
  {
    if (te1[tri] == edge)
      return tv3[tri];
    else if (te2[tri] == edge)
      return tv1[tri];
    else if (te3[tri] == edge)
      return tv2[tri];
    else return -1;
  }
  
  public int closestNode(float x, float y, float distance)
  {
    if (vertexCount <= 0) return -1;
    float d = dist(x, y, vx[0], vy[0]);
    int j = 0;
    for (int i = 1; i < vertexCount; i++)
    {
      float td = dist(x, y, vx[i], vy[i]);
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
  public void drawGraph()
  {
    // Draw all the edges.
    for (int i = 0; i < edgeCount; i++)
    {
      stroke(colorLine);
      // do not draw infinite edges
      drawEdge(i);
    }
    
    // Draw all the nodes.
    for (int i = 0; i < vertexCount; i++)
    {
      fill(colorNode);
      stroke(colorNode);
      text(i, vx[i]+5, vy[i]+5);
      ellipse(vx[i], vy[i], 10, 10);
    }
    
    // Draw all triangles.
    for (int i = 0; i < triCount; i++)
    {
      stroke(color(255, 0, 0));
      drawEdge(te1[i]);
      drawEdge(te2[i]);
      drawEdge(te3[i]);
    }
  }
  
  public void drawEdge (int edge)
  {
    if (ev1[edge] == -1 || ev2[edge] == -1)
      return;

    line(vx[ev1[edge]], vy[ev1[edge]], vx[ev2[edge]], vy[ev2[edge]]);    
  }
}

  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#F0F0F0", "flip_graph" });
  }
}
