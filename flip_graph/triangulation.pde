
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
  
  void addPointInTriangulation(int v)
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
        
        int v1, v2;
        if (tv1[t] == -1)
        {
          v1 = tv2[t];
          v2 = tv3[t]; 
        }
        else if (tv2[t] == -1)
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
        if (Geom.CCW(vx[v], vy[v], vx[v1], vy[v1], vx[v2], vy[v2]) == -1) 
        {
          vRight = v2;
          vLeft = v1;
        }
        else
        {
          vRight = v1;
          vLeft = v2;
        }

        int eLeft = triEdgeBetweenPoints(t, -1, vLeft);
        int eRight = triEdgeBetweenPoints(t, -1, vRight);
        
        // check to see if these points are the maximum "left" or "right"
        if (infRightPoint == -1 || Geom.CCW(vx[v], vy[v], vx[infRightPoint], vy[infRightPoint], vx[vRight], vy[vRight]) == -1)
        {
          infRightEdge = eRight;
          infRightPoint = vRight; 
          infRightTri = t;
        }
        if (infLeftPoint == -1 || Geom.CCW(vx[v], vy[v], vx[infLeftPoint], vy[infLeftPoint], vx[vLeft], vy[vLeft]) == 1)
        {
          infLeftEdge = eLeft;
          infLeftPoint = vLeft; 
          infLeftTri = t;
        }
      }

      int eTentLeft = edgeCount++;
      int eTentRight = edgeCount++;
      int eInfV = edgeCount++;
      
      int tInfLeft = triCount++;
      int tInfRight = triCount++;
      
      ev1[eTentLeft] = v; ev2[eTentLeft] = infLeftPoint;
      et1[eTentLeft] = infLeftTri; et2[eTentLeft] = tInfLeft;
      ev1[eTentRight] = v; ev2[eTentRight] = infRightPoint;
      et1[eTentRight] = infRightTri; et2[eTentRight] = tInfRight;
      ev1[eInfV] = -1; ev2[eInfV] = v;
      et1[eInfV] = tInfLeft; et2[eInfV] = tInfRight;
      
      replaceEdgeTriangle(infRightEdge, infRightTri, tInfRight);
      replaceEdgeTriangle(infLeftEdge, infLeftTri, tInfLeft);
      
      // now we need to create two new infinite triangle for v
      tv1[tInfLeft] = v; tv2[tInfLeft] = infLeftPoint; tv3[tInfLeft] = -1;
      te1[tInfLeft] = eTentLeft; te2[tInfLeft] = infLeftEdge; te3[tInfLeft] = eInfV;
      
      tv1[tInfRight] = v; tv2[tInfRight] = infRightPoint; tv3[tInfRight] = -1;
      te1[tInfRight] = eTentRight; te2[tInfRight] = infRightEdge; te3[tInfRight] = eInfV;
      
      for (int i = 0; i < triHits.size(); i++)
      {
        int t = ((Integer)triHits.get(i)).intValue();

        // preserve the edges on the boundary of the tent
        // as these are used by other infinite triangles
        // that we aren't updating
        if (t == infLeftTri)
          replaceTriangleEdge(t, infLeftEdge, eTentLeft);
        else if (t == infRightTri)
          replaceTriangleEdge(t, infRightEdge, eTentRight);

        updateInfiniteEdges(t, v);
        replaceTrianglePoint(t, -1, v);
      }

      for (int i = 0; i < triCount; i++)
      {
        checkTriangle(i);
      }
    }
  }

  void replaceEdgeTriangle(int e, int tOld, int tNew)
  {
    if (et1[e] == tOld)
      et1[e] = tNew;
    else if (et2[e] == tOld)
      et2[e] = tNew;
  }
  
  void replaceTriangleEdge(int t, int eOld, int eNew)
  {
    if (te1[t] == eOld)
      te1[t] = eNew;  
    else if (te2[t] == eOld)
      te2[t] = eNew;  
    else if (te3[t] == eOld)
      te3[t] = eNew;
  }

  void replaceTrianglePoint(int t, int vOld, int vNew)
  {
    if (tv1[t] == vOld)
      tv1[t] = vNew;
    else if (tv2[t] == vOld)
      tv2[t] = vNew;
    else if (tv3[t] == vOld)
      tv3[t] = vNew;
  }  

  void updateInfiniteEdges(int t, int v)
  {
    if (tv1[t] == -1)
    {
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
    else if (tv3[t] == -1)
    {
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
  
  void addPointInTriangle(int v, int t)
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
    
//    println("triangle1 " + tv1[t] + ", " + tv2[t] + ", " + tv3[t]);
//    println("triangle2 " + tv1[triCount] + ", " + tv2[triCount] + ", " + tv3[triCount]);
//    println("triangle3 " + tv1[triCount+1] + ", " + tv2[triCount+1] + ", " + tv3[triCount+1]);
    
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
    
    int v1 = ev1[edge];
    int v2 = ev2[edge];
    
    if (v1 == -1 || v2 == -1)
      return false;
    
    int v3 = triPointNotOnEdge(t1, edge);
    int v4 = triPointNotOnEdge(t2, edge);
        
    return !inTriangle(v1, v2, v3, v4) && !inTriangle(v2, v1, v3, v4) &&
           !inTriangle(v3, v1, v2, v4) && !inTriangle(v4, v1, v2, v3);
  }
    
  boolean inInfiniteTriangle(int x, int a, int b)
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
  
  boolean inTriangle(int x, int a, int b, int c)
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
    
    // since edge te2[tri1] switched from triangle 1 to triangle 2, we need to update this in thef
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
    else
    {
      println("Unable to find triEdgeBetweenPoints(" + tri + ", " + v1 + ", " + v2 + ")");
      return -1;
    }
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
    else
    {
      println("Unable to find triPointNotOnEdge(" + tri + ", " + edge + ")");
      return -1;
    }
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
  
  int countInteriorEdges()
  {
    int count = 0;
    for (int e = 0; e < edgeCount; e++)
    {
      // infinite edge
      if (ev1[e] == -1 || ev2[e] == -1)
        continue;
      
      // edge is on convex hull
      if (triPointNotOnEdge(et1[e], e) == -1 ||
          triPointNotOnEdge(et2[e], e) == -1)
        continue;
      
      count++;
    }
    return count;
  }
  
  int countDelaunayEdges()
  {
    int count = 0;
    for (int e = 0; e < edgeCount; e++)
    {
      int a = ev1[e];
      int b = ev2[e];
      int c = triPointNotOnEdge(et1[e], e);
      int d = triPointNotOnEdge(et2[e], e);
      
      // skip infinite triangles
      if (a == -1 || b == -1 || c == -1 || d == -1)
        continue;
      
      if (Geom.inCircle(vx[a], vy[a], vx[c], vy[c], vx[b], vy[b], vx[d], vy[d]) < 0)
        count++;
    }
    
    return count;
  }
  
  // Draw the graph.
  void drawGraph(float lx, float ly, float ux, float uy)
  {
    float minx = 0.0;
    float miny = 0.0;
    float maxx = width;
    float maxy = height;
    float w = maxx - minx;
    float h = maxy - miny;
    float ox = (minx + maxx) / 2.0;
    float oy = (miny + maxy) / 2.0;
    
    // Compute the difference in size.
    float sx = (ux - lx) / w;
    float sy = (uy - ly) / h;
    float X = (ux + lx) / 2.0;
    float Y = (uy + ly) / 2.0;
    
    // Draw all the edges.
    for (int i = 0; i < edgeCount; i++)
    {
      // Skip infinite edges.
      if (ev1[i] == -1 || ev2[i] == -1) continue;
      
      // Get the coordinates.
      float x1 = vx[ev1[i]];
      float y1 = vy[ev1[i]];
      float x2 = vx[ev2[i]];
      float y2 = vy[ev2[i]];
      
      // Scale correctly.
      x1 = (x1 - ox) * sx + X;
      y1 = (y1 - oy) * sy + Y;
      x2 = (x2 - ox) * sx + X;
      y2 = (y2 - oy) * sy + Y;
     
      // Draw.
      stroke(colorLine);
      line (x1, y1, x2, y2);
    }
    
    // Draw all the nodes.
    for (int i = 0; i < vertexCount; i++)
    {
      // Get the coordinates.
      float x = vx[i];
      float y = vy[i];
      
      // Scale correctly.
      x = (x - ox) * sx + X;
      y = (y - oy) * sy + Y;
      
      // Draw.
      fill(colorNode);
      stroke(colorNode);
      //text(i, x+5, y+5);
      ellipse(x, y, 10*sx, 10*sy);
    }
  }
  
  void drawEdge (int edge)
  {
    if (ev1[edge] == -1 || ev2[edge] == -1)
      return;

    int x_mid = (int)((vx[ev1[edge]] + vx[ev2[edge]]) / 2);
    int y_mid = (int)((vy[ev1[edge]] + vy[ev2[edge]]) / 2);
    text(edge, x_mid + 5, y_mid + 5);
    line(vx[ev1[edge]], vy[ev1[edge]], vx[ev2[edge]], vy[ev2[edge]]);    
  }
  
  void checkTriangle (int t)
  {
    if ((ev1[te1[t]] != tv1[t] || ev2[te1[t]] != tv2[t]) &&
        (ev2[te1[t]] != tv1[t] || ev1[te1[t]] != tv2[t]))
    {
      println("ev[te1] broken");
      printTriangle(t);
    }
    if ((ev1[te2[t]] != tv2[t] || ev2[te2[t]] != tv3[t]) &&
        (ev2[te2[t]] != tv2[t] || ev1[te2[t]] != tv3[t]))
    {
      println("ev[te2] broken");
      printTriangle(t);
    }
    if ((ev1[te3[t]] != tv1[t] || ev2[te3[t]] != tv3[t]) &&
        (ev2[te3[t]] != tv1[t] || ev1[te3[t]] != tv3[t]))
    {
      println("ev[te3] broken");
      printTriangle(t);
    }
    if (et1[te1[t]] != t && et2[te1[t]] != t)
    {
      println("et[te1] broken");
      printTriangle(t);
    }
    if (et1[te2[t]] != t && et2[te2[t]] != t)
    {
      println("et[te2] broken");
      printTriangle(t);
    }
    if (et1[te3[t]] != t && et2[te3[t]] != t)
    {
      println("et[te3] broken");
      printTriangle(t);
    }
  }

  void printTriangle (int t)
  {
    println("Triangle: " + t);
    println("Vertices: " + tv1[t] + " " + tv2[t] + " " + tv3[t]);
    println("Edges: " + te1[t] + " " + te2[t] + " " + te3[t]); 
    println("Edges: (" + ev1[te1[t]] + "," + ev2[te1[t]] + ") (" + ev1[te2[t]] + "," + ev2[te2[t]] + ") (" + ev1[te3[t]] + "," + ev2[te3[t]] + ")");
  }
}
