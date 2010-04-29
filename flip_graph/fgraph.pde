

class FNode
{
  boolean marked;
  float level;
  
  // Embedding data.
  float x, y;
  
  // Graph data.
  Triangulation tri;
  ArrayList neighborNodes;
  
  FNode(Triangulation t)
  {
    marked = false;
    neighborNodes = new ArrayList();
    tri = t;
    level = 1.0;
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
  
  // Build a flip graph from a given triangulation.
  FGraph(Triangulation t)
  {
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
    
    while (!queue.isEmpty())
    {
      // Get the next triangulation to work with.
      FNode node = (FNode)queue.removeFirst();
      Triangulation tri = node.tri;
      
      // If we already finished this node, skip it.
      if (node.marked) continue;
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
          nodeFlip.x = random(0, width);  //(20 * (8 - node.level)) * (float)Math.cos(r) + node.x;
          nodeFlip.y = random(0, height); //(20 * (8 - node.level)) * (float)Math.sin(r) + node.y;
          nodeFlip.level = node.level + 1.0;
          i += 1;
        }
        
        // Push it to the queue to be processed later.
        queue.addLast(nodeFlip);
        
        // Add it as a neighbor.
        node.addNeighbor(nodeFlip);
      }
    }
    println("There are " + hm.size() + " nodes in the flip graph!");
  }
  
  FNode closestNode(float x, float y, float distance)
  {
    Collection nodes = hm.values();
    Iterator iter = nodes.iterator();
    float d = dist(x, y, root.x, root.y);
    FNode nn = root;
    while (iter.hasNext())
    {
      // Draw all the links.
      FNode node = (FNode)iter.next();
      float td = dist(x, y, node.x, node.y);
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
  
  void embedify()
  {
    // Pick some random points to be fixed.
    HashMap fixed = new HashMap();
    Collection nodes = hm.values();
    Iterator iter = nodes.iterator();
    int i = 0;
    while (iter.hasNext() && i < 5 && i < hm.size())
    {
      FNode node = (FNode)iter.next();
      fixed.put(node.tri, node);
      i++;
    }
    
    println("tired");
    
    // Now relax the inner points for a while.
    for (i = 0; i < 200; i++)
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
            x += nei.x;
            y += nei.y;
          }
          node.x = x / node.neighborNodes.size();
          node.y = y / node.neighborNodes.size();
        }
      }
    }
  }
  
  void draw()
  {
    Collection nodes = hm.values();
    Iterator iter = nodes.iterator();
    while (iter.hasNext())
    {
      // Draw all the links.
      FNode node = (FNode)iter.next();
      float goodness = (float)node.tri.countDelaunayEdges() / (float)node.tri.countInteriorEdges();
      color nodeValue = color(255*(1-goodness), 255*goodness, 0); 
      
      for (int i = 0; i < node.neighborNodes.size(); i++)
      {
        FNode nn = (FNode)node.neighborNodes.get(i);
        float nnGoodness = (float)node.tri.countDelaunayEdges() / (float)node.tri.countInteriorEdges();
        color nnValue = color(255*(1-nnGoodness), 255*nnGoodness, 0); 

        beginShape(LINES);
        stroke(nodeValue);
        vertex(node.x, node.y);
        stroke(nnValue);
        vertex(nn.x, nn.y);
        endShape();
        
//        stroke(colorLine, 100);
//        line(node.x, node.y, nn.x, nn.y);
      }
    }
    iter = nodes.iterator();
    while (iter.hasNext())
    {
      FNode node = (FNode)iter.next();
      float goodness = (float)node.tri.countDelaunayEdges() / (float)node.tri.countInteriorEdges();
      color nodeValue = color(255*(1-goodness), 255*goodness, 0); 
      fill(nodeValue);
      stroke(nodeValue);
      ellipse(node.x, node.y, 10, 10);
    }
  }
<<<<<<< HEAD
  
}
=======
}
>>>>>>> 71f5c8883025c27527e058d6538814adbe0a6262
