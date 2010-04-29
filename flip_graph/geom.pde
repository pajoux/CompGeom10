
// Namespace containing some standard geometric functions.
static class Geom
{
  // Counter-Clockwise Predicate.
  //   + Return 1  if (a,b,c) are CCW-oriented
  //   + Return 0  if (a,b,c) are colinear
  //   + Return -1 if (a,b,c) are CW-oriented 
  static int CCW(float a_x, float a_y, float b_x, float b_y, float c_x, float c_y)
  {
    PMatrix3D mat = new PMatrix3D(a_x, b_x, c_x, 0,
                                  a_y, b_y, c_y, 0,
                                  1  , 1  , 1  , 0,
                                  0  , 0  , 0  , 1);
    
    float det  = mat.determinant();
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
  
  // InCircle Test
  //   + Returns 1 if d is in the circle abc.
  //   + Returns 0 if d is cocircular with abc.
  //   + Returns -1 if d is outside of the circle abc.
  static int inCircle(float a_x, float a_y, float b_x, float b_y, float c_x, float c_y, float d_x, float d_y)
  {
    // TODO: for now, we have no rules on the orientation of a, b, c, so
    // we'll enforce a CCW ordering.
    if (CCW(a_x, a_y, b_x, b_y, c_x, c_y) < 0)
      return inCircle(a_x, a_y, c_x, c_y, b_x, b_y, d_x, d_y);
    
    float a_z = a_x * a_x + a_y * a_y;
    float b_z = b_x * b_x + b_y * b_y;
    float c_z = c_x * c_x + c_y * c_y;
    float d_z = d_x * d_x + d_y * d_y;
      
    PMatrix3D projection = new PMatrix3D(a_x, b_x, c_x, d_x,
                                         a_y, b_y, c_y, d_y,
                                         a_z, b_z, c_z, d_z,
                                         1  , 1  , 1  , 1  );
    
    float det = projection.determinant();
    
    if (det > 0)
      return 1;
    else if (det == 0)
      return 0;
    else
      return -1;
  }
}
