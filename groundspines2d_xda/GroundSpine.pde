class GroundSpine
{
  int _numOfSegments;
  ArrayList _segments;
  
  Vector3 _pos;
  Vector3 _dir;
  
  float _angle;
  float _angleAdd;

  GroundSpine()
  {
    _numOfSegments = 10;
    _segments = new ArrayList();
    
    _pos = new Vector3();
    _dir = new Vector3();
    
    _angle = 0;
    _angleAdd = 0;
  }
  
  void init()
  {
    float x = random( -200, 200 );
    float y = 0;
    float z = random( -200, 200 );
    
    _pos.set( x, y, z );
    
    float headX = random(18,20) * 0.5;
    float headY = headX * 0.85;// * random(1,3);
    _dir.set( headX, headY, 0 );
    
    float hx = headX;
    float hy = headY;
    
    _segments.clear();
    _segments.add( _pos.copy() );
    for( int i=1; i<numSegs; i++ )
    {     
      _segments.add( new Vector3(x, y, z) );
      
      if( i > 4 ) //numSegs/4 )
      {
        x += (hx * sin( radians(_angle) ));
        y += (hy * cos( radians(_angle) ));
  
        hx -= (headX/(float)_numOfSegments) * 2;
        if( hx < 1.0 ) hx = 1.0;
        hy -= (headY/(float)_numOfSegments);
//        hy -= 2*pow( (headY/(float)numSegs), i);
//        if( hy < 1.0 ) hy = 1.0;
        
        _angle += _angleAdd;
      }      
    }
  }
  
}  // end class
