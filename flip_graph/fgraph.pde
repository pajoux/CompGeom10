

class FNode
{
  FGraph graph;
  boolean marked;
  float level;
  boolean fixed;
  
  // Embedding data.
  float x, y, z;
  
  // Displacement data (for embedifying)
  float disp_x, disp_y, disp_z;
  
  // Backtrack
  FNode backNode;
  
  // Graph data.
  Triangulation tri;
  ArrayList neighborNodes;
  
  FNode(Triangulation t)
  {
    marked = false;
    neighborNodes = new ArrayList();
    tri = t;
    level = 1.0;
    backNode = null;
    fixed = false;
    z = random(-500, 500);
  }
  
  void addNeighbor(FNode node)
  {
    neighborNodes.add(node);
  }
}

class FGraph
{
  HashMap hm;
  FNode root;
  ArrayList loopNodes;
  float rotation = 0.0;
  float rotation2 = 0.0;
  int minDelaunayEdges;
    
  // Build a flip graph from a given triangulation.
  FGraph(Triangulation t)
  {
    minDelaunayEdges = t.interiorEdgeCount;
    bfs(t);
    //embedify();
  }
  
  void bfs(Triangulation t)
  {
    hm = new HashMap();
    LinkedList queue = new LinkedList();
    
    // Starting node.
    root = new FNode(t);
    root.x = random(0, width);//width / 2.0;
    root.y = random(0, height);//height / 2.0;
    queue.addLast(root);
    hm.put(t, root);
    
    // Loop
    FNode loopNodeA = null, loopNodeB = null;
    
    while (!queue.isEmpty())
    {
      // Get the next triangulation to work with.
      FNode node = (FNode)queue.removeFirst();
      Triangulation tri = node.tri;
      minDelaunayEdges = min(node.tri.delaunayEdgeCount, minDelaunayEdges);

      // Mark the node.
      node.marked = true;

      // Count how many neighbors we will have.
      int ncount = 0;
      for (int e = 0; e < tri.edgeCount; e++)
      {
        if (tri.canFlip(e))
          ncount += 1;
      }

      // Loop through each edge, adding it as a neighbor.
      for (int e = 0, i = 0; e < tri.edgeCount; e++)
      {
        if (!tri.canFlip(e))
          continue;
        
        // Compute the flipped triangulation.
        Triangulation triFlip = tri.clone();
        triFlip.flip(e);
        
        // Find or create a node for the triangulation.
        FNode nodeFlip = (FNode)hm.get(triFlip);
        if (nodeFlip == null)
        {
          nodeFlip = new FNode(triFlip);
          hm.put(triFlip, nodeFlip);
          
          // If we create it, compute it's position.
          float r = (float)(((2 * Math.PI) / ncount) * i);
          nodeFlip.x = random(0, width);
          nodeFlip.y = random(0, height);
          i += 1;
        }
        
        // If we already finished this node, don't add it, and mark the loop.
        if (nodeFlip.marked)
        {
          if (node.backNode != nodeFlip)
          {
            loopNodeA = node;
            loopNodeB = nodeFlip;
          }
        }
        else
        {
          // Add a back pointer to the node.
          nodeFlip.backNode = node;
          // Push it to the queue to be processed later.
          queue.addLast(nodeFlip);
        }
        // Add it as a neighbor.
        node.addNeighbor(nodeFlip);
      }
    }
    println("There are " + hm.size() + " nodes in the flip graph!");
    
    // If the follow node is null, just use all the nodes and fix them.
    if (loopNodeA == null)
    {
      loopNodes = new ArrayList();
      Collection nodes = hm.values();
      Iterator iter = nodes.iterator();
      while (iter.hasNext())
      {
        loopNodes.add(iter.next());
      }
      return;
    }
    
    // Get the loop.
    HashSet loopSet = new HashSet();
    FNode follow = loopNodeA;
    while (follow.backNode != null)
    {
      loopSet.add(follow.tri);
      follow = follow.backNode;
    }
    // Find the shared node in the loop.
    follow = loopNodeB;
    while (follow.backNode != null)
    {
      if (loopSet.contains(follow.tri)) break;
      follow = follow.backNode;
    }
    // Now build a list of the nodes.
    FNode stop = follow;
    loopNodes = new ArrayList();
    for (follow = loopNodeA; !follow.tri.equals(stop.tri); follow = follow.backNode)
    {
      loopNodes.add(follow);
    }
    loopNodes.add(stop);
    ArrayList loopNodesRev = new ArrayList();
    for (follow = loopNodeB; !follow.tri.equals(stop.tri); follow = follow.backNode)
    {
      loopNodesRev.add(follow);
    }
    for (int i = loopNodesRev.size() - 1; i >= 0; i--)
    {
      loopNodes.add(loopNodesRev.get(i));
    }
    
    println("loop nodes size: " + loopNodes.size());
  }
  
  FNode closestNode(float x, float y, float distance)
  {
    Collection nodes = hm.values();
    Iterator iter = nodes.iterator();
    float d = dist(x, y, pg.screenX(root.x, root.y, root.z), pg.screenY(root.x, root.y, root.z));
    FNode nn = root;
    while (iter.hasNext())
    {
      // Draw all the links.
      FNode node = (FNode)iter.next();
      float td = dist(x, y, pg.screenX(node.x, node.y, node.z), pg.screenY(node.x, node.y, node.z));
      if (td < d)
      {
        d = td;
        nn = node;
      }
    }
    if (d < distance)
    {
      return nn;
    }
    return null;
  }

  float C ()
  {
    float n = (float)hm.size();
    return sqrt(n / PI);
  }
  
  float cool (int i)
  {
    float n = (float)hm.size();
    return 500 * sqrt(PI / n) / (1 + (PI / n) * pow((float)i, 1.5));
  }
  
  void embedify()
  {
    // Pick some random points to be fixed.
    HashMap fixed = new HashMap();
    Collection nodes = hm.values();
    Iterator iter = nodes.iterator();
    
    float pid = (float)((Math.PI * 2.0) / (loopNodes.size()));
    for (int i = 0; i < loopNodes.size(); i++)
    {
      FNode node = (FNode)loopNodes.get(i);
      node.x = cos(pid * i) * width / 3.0;
      node.y = sin(pid * i) * height / 3.0;
      fixed.put(node.tri, node);
    }
    
    // place all non fixed points at the origin
    while (iter.hasNext())
    {
      FNode node = (FNode)iter.next();
      if (fixed.containsKey(node.tri))
        continue;
      
      node.x = 0;
      node.y = 0;      
    }
    
    // Now relax the inner points for a while.
    for (int i = 0; i < 200; i++)
    {
      nodes = hm.values();
      iter = nodes.iterator();
      while (iter.hasNext())
      {
        FNode node = (FNode)iter.next();
        if (!fixed.containsKey(node.tri))
        {
          float x = 0, y = 0;
          for (int j = 0; j < node.neighborNodes.size(); j++)
          {
            FNode nei = (FNode)node.neighborNodes.get(j);
            x += C() * (nei.x - node.x) * (nei.x - node.x) * (nei.x - node.x);
            y += C() * (nei.y - node.y) * (nei.y - node.y) * (nei.y - node.y);
          }
          float n = sqrt(x * x + y * y);
          if (n == 0)
            continue;
          node.x += min(n, cool(i)) * (x / n);
          node.y += min(n, cool(i)) * (y / n);
        }
      }
    }
  }
  
  void draw(FNode focus)
  {
    pg.beginDraw();
    pg.background(colorBackground);
    pg.camera(0.0, 500.0, -300.0/* + rotation2*/,
              0.0, 0.0, 0.0,
              0.0, 0.0, 1.0);
    pg.translate(0.0, 0.0, -200.0);
    pg.rotateZ(rotation);
    
    Collection nodes = hm.values();
    Iterator iter = nodes.iterator();
    while (iter.hasNext())
    {
      // Draw all the links.
      FNode node = (FNode)iter.next();
      float goodness = (float)(node.tri.delaunayEdgeCount - minDelaunayEdges) / (float)(node.tri.interiorEdgeCount - minDelaunayEdges);
      color nodeValue = color(255*(1-goodness), 255*goodness, 0); 
      node.z = (1-goodness) * 600;
      
      for (int i = 0; i < node.neighborNodes.size(); i++)
      {
        FNode nn = (FNode)node.neighborNodes.get(i);
        float nnGoodness = (float)(nn.tri.delaunayEdgeCount - minDelaunayEdges) / (float)(nn.tri.interiorEdgeCount - minDelaunayEdges);
        color nnValue = color(255*(1-nnGoodness), 255*nnGoodness, 0);
        nn.z = (1-nnGoodness) * 600;
        
        pg.beginShape(LINES);
        if (node == focus || nn == focus)
        { pg.stroke(colorLine); }
        else { pg.stroke(nodeValue); }
        pg.vertex(node.x, node.y, node.z);
        if (node == focus || nn == focus)
        { pg.stroke(colorLine); }
        else { pg.stroke(nnValue); }
        pg.vertex(nn.x, nn.y, nn.z);
        pg.endShape();
      }
    }
    iter = nodes.iterator();
    while (iter.hasNext())
    {
      FNode node = (FNode)iter.next();
      float goodness = (float)(node.tri.delaunayEdgeCount - minDelaunayEdges) / (float)(node.tri.interiorEdgeCount - minDelaunayEdges);
      color nodeValue = color(255*(1-goodness), 255*goodness, 0);
      float S = 5.0;
      if (node == focus)
      { pg.fill(colorLine); pg.stroke(colorLine); S = 10.0; }
      else 
      { pg.fill(nodeValue); pg.stroke(nodeValue); }
      pg.pushMatrix();
      pg.translate(node.x, node.y, node.z);
      pg.box(S);
      pg.popMatrix();
    }
    pg.endDraw();
    image(pg, 0, 0);
  }
}
