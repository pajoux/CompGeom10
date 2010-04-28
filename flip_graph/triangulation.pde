
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
    edgeMax = vertexMax * 3 - 6;
    triMax = vertexMax * 2 - 4;
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
  void addVertex(float x, float y)
  {
    if (vertexCount >= vertexMax) return;
    vx[vertexCount] = x;
    vy[vertexCount] = y;
    vertexCount += 1;
  }
  
  // Return the triangle that vertex [v] is inside of.
  int findTriangle(int v)
  {
    for (int t = 0; t < triCount; t++)
      if (inTriangle(v, tv1[t], tv2[t], tv3[t])) 
        return t;
    return -1;
  }
  
  // Compute a triangulation of the vertices (overwrites old edges/triangles).
  void triangulate()
  { 
    // Start with triangle v0, v1, v2.
    if (vertexCount < 3) return;
    tv1[0] = 0; tv2[0] = 1; tv3[0] = 2;
    te1[0] = 0; te2[0] = 1; te3[0] = 2;
    ev1[0] = 0; ev2[0] = 1; et1[0] = 0; et2[0] = -1;
    ev1[1] = 1; ev2[1] = 2; et1[1] = 0; et2[1] = -1;
    ev1[2] = 2; ev2[2] = 0; et1[2] = 0; et2[2] = -1;
    edgeCount = 3;
    triCount = 1;
    
    // Loop through the rest of the points, adding triangles.
    for (int v = 3; v < vertexCount; v++)
    {
      int t = findTriangle(v);
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
      
      // Update the edge-triangle stuff.
      if (et1[e1] == t) { et1[e1] = t; et2[e1] = et2[e1]; } else { et1[e1] = et1[e1]; et2[e1] = t; }
      if (et1[e2] == t) { et1[e2] = triCount; et2[e2] = et2[e2]; } else { et1[e2] = et1[e2]; et2[e2] = triCount; }
      if (et1[e3] == t) { et1[e3] = triCount+1; et2[e3] = et2[e3]; } else { et1[e3] = et1[e3]; et2[e3] = triCount+1; }
      et1[edgeCount+0] = triCount+1; et2[edgeCount+0] = t;
      et1[edgeCount+1] = t; et2[edgeCount+1] = triCount;
      et1[edgeCount+2] = triCount; et2[edgeCount+2] = triCount+1;
      
      // Increase number of edges/triangles.
      edgeCount += 3;
      triCount += 2;
    }
  }
  
  // Make a deep copy of this triangulation.
  Triangulation clone()
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
  
  // Object's [equals] overrided.
  boolean equals(Object obj)
  {
    if (obj instanceof Triangulation)
    {
      boolean e1 = equals((Triangulation)obj);
      return e1;
    }
    return false;
  }
  
  // Object's [hashCode] overrided.
  int hashCode()
  {
    // Flip some bits all over the place.
    int h = 21;
    for (int e = 0; e < edgeCount; e++)
    {
      // NOTE that we must use BITWISE XOR because it is commutative,
      // and we don't know the ordering of the edges etc.
      h ^= (ev1[e] ^ ev2[e]);
      h ^= (et1[e] ^ et2[e]);
    }
    return h;
  }
  
  // Test if two triangulations are equal (assuming same vertices).
  boolean equals(Triangulation t)
  {
    if (edgeCount != t.edgeCount) return false;
    for (int e = 0; e < edgeCount; e++)
    {
      // Find the edge in the other triangulation.
      boolean found = false;
      for (int eo = 0; eo < edgeCount; eo++)
      {
        if ((ev1[e] == t.ev1[eo] && ev2[e] == t.ev2[eo]) ||
            (ev1[e] == t.ev2[eo] && ev2[e] == t.ev1[eo]))
        {
          found = true;
          break;
        }
      }
      if (!found)
        return false;
    }
    return true;
  }
  
  // Return whether or not [edge] can be flipped or not.
  boolean canFlip(int edge)
  {
    int t1 = et1[edge];
    int t2 = et2[edge];
    
    // Take into account the infinite triangle points?
    if (t1 == -1 || t2 == -1) return false;
    
    int v1 = ev1[edge];
    int v2 = ev2[edge];
    int v3 = triPointNotOnEdge(t1, edge);
    int v4 = triPointNotOnEdge(t2, edge);
    
    return !inTriangle(v1, v2, v3, v4) && !inTriangle(v2, v1, v3, v4) &&
           !inTriangle(v3, v1, v2, v4) && !inTriangle(v4, v1, v2, v3);
  }
  
  boolean inTriangle(int x, int a, int b, int c)
  {
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
  void flip (int edge)
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
  void switchTriangleEdgeMap(int edge, int t1, int t2)
  {
    if (et1[edge] == t1)
      et1[edge] = t2;
    else if (et2[edge] == t1)
      et2[edge] = t2;
  }

  void updateTriangle(int tri, int v1, int v2, int v3,
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
  int triEdgeBetweenPoints (int tri, int v1, int v2)
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
    else { println("HELLO!"); return -1; }
  }
  
  // precondition: edge is on triangle
  int triPointNotOnEdge (int tri, int edge)
  {
    if (te1[tri] == edge)
      return tv3[tri];
    else if (te2[tri] == edge)
      return tv1[tri];
    else if (te3[tri] == edge)
      return tv2[tri];
    else return -1;
  }
  
  int closestNode(float x, float y, float distance)
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
  void drawGraph()
  {
    // Draw all the edges.
    for (int i = 0; i < edgeCount; i++)
    {
      stroke(colorLine);
      line(vx[ev1[i]], vy[ev1[i]], vx[ev2[i]], vy[ev2[i]]);
    }
    
    // Draw all the nodes.
    for (int i = 0; i < vertexCount; i++)
    {
      fill(colorNode);
      stroke(colorNode);
      ellipse(vx[i], vy[i], 10, 10);
    }
  }
}
