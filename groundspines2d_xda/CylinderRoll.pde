import vitamin.math.*;
import java.util.Collections;  
import java.util.ArrayList;  
import java.util.Comparator; 
import vitamin.interpolation.*;

class CylinderRoll
{
  CylinderRoll( int tailSize, float tailWidth, int facets, float headSize, boolean renderHead )
  {
    _parent = null;

    _doRenderHead = renderHead;
    _doUpdate = true;

    _isDead = false;

    _tailSize = tailSize;
    _tailRenderSegments = 0;
    _tailWidth = tailWidth;

    _initPos = new Vector3();

    _headSize = headSize;
    _head = new Vector3();
    _target = new Vector3();
    _right = new Vector3();

    _usePerlin = false;
    _perlin = new Vector3();

    _add = new Vector3();

    _age = 0;
    _agePer = 0;
    _timeToLive = 30;
    _invTimeToLive = 1.0 / _timeToLive;

    _color = new Vector4( 1, 1, 1, 1 );
    _destColor = new Vector4( 0, 0, 0, .1 );

    _gravity = new Vector3( 0, 0.1, 0 );

    _leafTexID = 0;
    _leafCurrSizeX = 0;
    _leafCurrSizeY = 0;
    _leafSizeX = 1;
    _leafSizeY = 4;
    leafTime = 0;
    leafStartTime = 0;
    leafGrowTime = random(0.25, 1);

    _facets = facets;

    _dispoffset = 0;
    _displaces = 0;
    _dispscale = 9;

    _depth = 0;
    _maxDepth = 1;

    _timeChildCount = 0;
    _timeToAddChild = 0;
    _maxChildren = 1000;
    _children = new ArrayList();    

    resetAngles();    
  }

  void resetAngles()
  {
    //    if( _depth >= 1 )
    {
      _theta = random( -PI, PI );
      _phi = 0;//random( -PI/2, PI/2 );
    }
    /*    else
     {
     _theta = random( -PI/2, PI/2 );
     _phi = random( -PI, PI );
     }*/

    // 2D
    _thetaAdd = random( -PI*0.1, PI*0.1 ) * 1;
    _phiAdd = random( -PI*0.1, PI*0.1 );

    /*    // 3D    
     _thetaAdd = .1;//random( 0, PI/100.0 );
     _phiAdd = .01;//random( -PI*0.1, PI*0.1 ) * .2;*/

    _angle = random( 0, PI );
    _angleAdd = random( -1, 1 );
    _rad = random( -3, 3 ) * 3;

    _addDamp = random( 0.15, 0.5 );
  }

  void setRelation( CylinderRoll parent, int depth, int maxDepth )
  {
    _parent = parent;
    _depth = depth;
    _maxDepth = maxDepth;
  }



  float getRads(float val1, float val2, float mult, float div)
  {
    float rads = noise(val1/div, val2/div, frameCount/div );

    if (rads < minNoise) minNoise = rads;
    if (rads > maxNoise) maxNoise = rads;

    rads -= minNoise;
    rads *= 1.0/(maxNoise - minNoise);

    return rads * mult;
  }


  void setCylinderDetail( int d )
  {
    _facets = d;
  }

  void setCylinderRadius( int r )
  {
    _tailWidth = r;
  }   

/*  void loadHeadTexture( String file )
  {
    _headTex = new XTexture( file );
  }*/

  void findPerlin()
  {
    float xyRads = getRads( _head.x, _head.z, 5.0, 15.0 );
    float yRads = getRads( _head.x, _head.y, 5.0, 15.0 );
    //    _perlin.set( cos(xyRads), sin(yRads), sin(xyRads) );

    //    _perlin.set( cos(1.2*xyRads), sin(4*yRads), sin(1.2*xyRads) );
    //    _perlin.mul( 2.85 );

    _perlin.set( cos(5.2*xyRads), sin(4*yRads), sin(5.2*xyRads) );
    _perlin.mul( 2.85 );

    //    _perlin.set( cos(10.2*xyRads), sin(4*yRads), sin(10.2*xyRads) );
    //    _perlin.mul( 2.85 );
  }

  void computeTail()
  {
    _tailRenderSegments = 0;
    if( _tail == null )
    {
      _tail = new Vector3[_tailSize];
      _tailColor = new Vector4[_tailSize];

      for( int i=0; i<_tailSize; i++ )
      {
        _tail[i] = new Vector3();
        _tail[i] = _head.copy();

        _tailColor[i] = new Vector4( 1, 1, 1, .1 );
      }
    }
    else
    {
      for( int i=0; i<_tailSize; i++ )
      {
        _tail[i] = _head.copy();
        _tailColor[i] = new Vector4( 1, 1, 1, .1 );
      }
    }

    if( yTable == null ) yTable = new int[_tailSize];
    for( int i=0; i<_tailSize; i++ )
      yTable[i] = i * (_facets+1);
    if( _vertices == null ) _vertices = new Vector3[ ((_tailSize)*(_facets+1)) ];
    if( _normals == null ) _normals = new Vector3[ ((_tailSize)*(_facets+1)) ];
    if( _texcoords == null ) _texcoords = new Vector3[ ((_tailSize)*(_facets+1)) ]; 
    for( int i=0; i<((_tailSize)*(_facets+1)); i++ )
    {
      _vertices[i] = new Vector3();
      _normals[i] = new Vector3();
      _texcoords[i] = new Vector3(); 
    }
  }


  boolean isDead( Vector3 p )
  {
    if( Vector3.distance(_tail[_tail.length-1], p) < 0.00001 )
    {
      _isDead = true;
      return true;
    }

    return false;
  }


  boolean isDead()
  {
    if( _age >= _timeToLive )
    {
      _isDead = true;
      return true;
    }

    return false;
  }

  void setTailSize( int t )
  {
    _tailSize = t;
    computeTail();
  }

  void setTimeToLive( float t )
  {
    _timeToLive = t;
    _invTimeToLive = 1.0 / _timeToLive;
  }

  void setHeadY( float y )
  {
    _head.y = y;
    _initPos = _head.copy();
  }

  void setHead( float x, float y )
  {
    _head.set( x, y, 0 );
    _initPos = _head.copy();
    _target = _head.copy();
  }

  void setHead( float x, float y, float z )
  {
    _head.set( x, y, z );
    _initPos = _head.copy();
  }

  void setHead( Vector3 h )
  {
    _head = h.copy();
    _initPos = _head.copy();
  }

  void addHead( float x, float y )
  {
    //if( _doUpdate )
    if( !_usePerlin )
    {
      _head.add( x, y, 0 );
      //_add.set( x, y, 0 );
    }
  }

  void addHead( float x, float y, float z )
  {
    //if( _doUpdate )
    if( !_usePerlin )
    {
      _head.add( x, y, z );
      //_add.set( x, y, z );
    }
  }

  void addHead( Vector3 a )
  {
    //if( _doUpdate )
    if( !_usePerlin )
    {
      _head.add( a.copy() );
      //_add = a.copy();
    }
  }

  void doRenderHead( boolean f )
  {
    _doRenderHead = f;
  }



  void update( float time, float dt )
  {
    if( _parent == null && Vector3.distance(_head, _tail[0]) < 10 )
    {
      return;
    }

    if( _type == 0 )
    {
      for( int i=_tailRenderSegments; i>0; i-- )
      {
        _tail[i] = _tail[i-1];
      }
      _tail[0] = _head.copy();

      _tailRenderSegments++;      
      if( _tailRenderSegments > _tailSize-1 )
        _tailRenderSegments = _tailSize-1;
    }
    else if( _type == 1 )
    {    
      if( _age < _timeToLive )
      {
        if( _tailRenderSegments < _tailSize )
        {

          float per = 1 - ( _tailRenderSegments / (float)((_tailSize-1)) );

/*          float rr = Linear.easeIn( time-clickTime, _color.x, _destColor.x, per );
          float gg = Linear.easeIn( time-clickTime, _color.y, _destColor.y, per );
          float bb = Linear.easeIn( time-clickTime, _color.z, _destColor.z, per );
          float aa = Linear.easeIn( time-clickTime, _color.w, _destColor.w, per );
*/

          float rr = _color.x*(1-per) + (_destColor.x) * (per);
          float gg = _color.y*(1-per) + (_destColor.y) * (per);
          float bb = _color.z*(1-per) + (_destColor.z) * (per);
          float aa = _color.w*(1-per) + (_destColor.w) * (per);

          _tailColor[(_tailSize-1)-_tailRenderSegments].set( rr, gg, bb, aa );


/*          float rr = _color.x + (_destColor.x-_color.x) * (per);
          float gg = _color.y + (_destColor.y-_color.y) * (per);
          float bb = _color.z + (_destColor.z-_color.z) * (per);
          float aa = _color.w + (_destColor.w-_color.w) * (per);
*/

          for( int i=_tailRenderSegments; i>0; i-- )
          {
            _tail[i] = _tail[i-1];            
//            _tailColor[i] = _tailColor[i-1];
          }
          _tail[0] = _head.copy();
//          _tailColor[0].set( rr, gg, bb, 1 );
          _tailRenderSegments++;          
        }
        else
        {
          _doUpdate = false;
        }
      }
      else
      {
        _doUpdate = false;
      }
    }

    if( _doUpdate )
    {
      /*      if( _usePerlin )
       {
       //findPerlin();
       //_add.add( _perlin );
       //_head.add( _add );
       //_add.mul( _damp );
       
       float target_distance = 200.0;
       float redirect_distance = 60.0;
       float d = Vector3.distance( _head, _target );//dist( _head.x, _head.y, _head.z, tx, ty, tz );
       if( d < target_distance )
       {
       _target.x += random(-redirect_distance, redirect_distance);
       _target.y += random(-redirect_distance, redirect_distance);
       _target.z += random(-redirect_distance, redirect_distance);
       //tx = global.constrainX(tx);
       //ty = global.constrainY(ty);
       //tz = 0;
       }
       _add.x += (_target.x-_head.x) * 0.002;
       _add.y += (_target.y-_head.y) * 0.002;
       _add.z += (_target.z-_head.z) * 0.002;
       _head.add( _add );      
       _add.mul( 0.97 );
       }
       else*/
      {
        _head.add( _add );

        float sinTheta = sin(_theta) * _rad;
        float cosTheta = cos(_theta) * _rad;
//        float sinPhi = sin(_phi);
//        float cosPhi = cos(_phi);
        _rad *= 0.95;

        /*
        _add.x += _right.x * cosTheta * 3;
         _add.y += _right.y * sinTheta * 3;
         */
        _add.x += cosTheta;
        _add.y += sinTheta;

        /*
        _add.x += sinTheta * cosPhi;
         _add.y += cosTheta;
         _add.z += sinTheta * sinPhi;
         */

        _add.add( _gravity );
        _add.mul( _addDamp );

        _theta += _thetaAdd;
//        _phi += _phiAdd;        
      }
    }

    _age ++;
    _agePer = _age * _invTimeToLive;
  }


  void draw( float time, float dt )
  {
    vgl.enableTexture( false );
    vgl.setAlphaBlend();
    //    vgl.setAdditiveBlend();

    vgl.enableTexture( true );
    vgl.gl().glBindTexture( GL.GL_TEXTURE_2D, cylTex.getId() );

    renderTail( time );
    //renderTailCylinder();



    // Draw leaf
    //    if( _doRenderHead )
    {
      renderHead( time );
    }


    // Comment this loop to get back to using normal ribbon
    for( int i=0; i<_children.size(); i++ )
    {
      CylinderRoll child = (CylinderRoll)_children.get(i);
      child.draw( time, dt );
      //child.update( time );

      //if( child.isDead() )
      if( child.isDead(_tail[_tail.length-1]) )
        child.reset( _head, _timeToLive );    
    }

    update( time, dt );

    if( mousePressed || tuioOn ) addChild( dt );

    // Stop head motion once it completes its growth      
    if( !_doUpdate )
      _head = _tail[0].copy();    
  }



  void renderHead( float time )
  {
    if( _parent == null ) return; // root has no leafs

    // only render head when end of the tail is reached
    if( _tailRenderSegments < _tailSize-1 )
    {
      // get time taken to grow. use this to reset time that is used to make the leaf grow up
      leafStartTime = time;
      return;
    }


    int rangeDepth = _maxDepth;
    /*
    // Only draw leafs on depth at certain depths
     int minDepth = _maxDepth/2;
     int maxDepth = _maxDepth;
     int rangeDepth = maxDepth - minDepth;
     if( _depth < minDepth && _depth >= maxDepth ) return;*/

    // clamp time
    leafTime += timer.getFrameTime();
    if( leafTime >= leafGrowTime ) leafTime = leafGrowTime;

    // scale factor to grow leaf
    float ttt = Quart.easeOut( leafTime, 0, 1, leafGrowTime );

    // size of the leaf
    float sx = ttt*_leafSizeX;
    float sy = ttt*_leafSizeY;
    //println( leafTime + ", " + sx + ", " + sy  );//+ ", " + _depth + ", " + _maxDepth );

    int i = 0;
    Vector3 dir = Vector3.sub( _tail[i], _tail[i+2] );
    dir.normalize();

    Vector3 up = new Vector3(0, 1, 0);
    Vector3[] rect= new Vector3[4];
    rect[0] = new Vector3( -1*sx, 0*sy, 0 );
    rect[1] = new Vector3( -1*sx, 1*sy, 0 );
    rect[2] = new Vector3(  1*sx, 1*sy, 0 );
    rect[3] = new Vector3(  1*sx, 0*sy, 0 );
    transformRect( up, dir, new Vector3(), rect );
    Vector3 p0 = Vector3.add( _tail[i], rect[0] );
    Vector3 p1 = Vector3.add( _tail[i], rect[1] );
    Vector3 p2 = Vector3.add( _tail[i], rect[2] );
    Vector3 p3 = Vector3.add( _tail[i], rect[3] );

    Vector3 N = Vector3.cross( up, dir );
    N.normalize();



    vgl.fill( 1, 1 );

//    vgl.gl().glEnable( GL.GL_SAMPLE_ALPHA_TO_COVERAGE ); 

    vgl.gl().glDisable( GL.GL_CULL_FACE );
    vgl.setDepthWrite( false );
    vgl.setDepthMask( false );
    vgl.setAlphaBlend();
//    vgl.setAdditiveBlend();

    vgl.enableTexture( true );
    vgl.gl().glBindTexture( GL.GL_TEXTURE_2D, _leafTexID );

    vgl.gl().glBegin( GL.GL_QUADS );
    vgl.gl().glNormal3f( N.x, N.y, N.z ); 
    vgl.gl().glColor4f( _destColor.x*5, _destColor.y*5, _destColor.z*5, _destColor.w*5 );
    //    vgl.gl().glColor4f( vgl._r, vgl._g, vgl._b, vgl._a );

    vgl.gl().glTexCoord2f( 0, 1 ); 
    vgl.gl().glVertex3f( p0.x, p0.y, p0.z );
    vgl.gl().glTexCoord2f( 0, 0  ); 
    vgl.gl().glVertex3f( p1.x, p1.y, p1.z );
    vgl.gl().glTexCoord2f( 1, 0 );
    vgl.gl().glVertex3f( p2.x, p2.y, p2.z );	
    vgl.gl().glTexCoord2f( 1, 1 ); 
    vgl.gl().glVertex3f( p3.x, p3.y, p3.z );
    vgl.gl().glEnd();

    /*
    leafTex2.enable();
     vgl.gl().glBlendFunc( GL.GL_ONE, GL.GL_ONE );
     
     vgl.gl().glBegin( GL.GL_QUADS );
     vgl.gl().glNormal3f( N.x, N.y, N.z ); 
     vgl.gl().glColor4f( vgl._r, vgl._g, vgl._b, vgl._a );
     vgl.gl().glTexCoord2f( 0, 1 ); 
     vgl.gl().glVertex3f( p0.x, p0.y, p0.z );
     vgl.gl().glTexCoord2f( 0, 0  ); 
     vgl.gl().glVertex3f( p1.x, p1.y, p1.z );
     vgl.gl().glTexCoord2f( 1, 0 );
     vgl.gl().glVertex3f( p2.x, p2.y, p2.z );	
     vgl.gl().glTexCoord2f( 1, 1 ); 
     vgl.gl().glVertex3f( p3.x, p3.y, p3.z );
     vgl.gl().glEnd();
     */

    vgl.enableTexture( false );

    //    vgl.gl().glDisable( GL.GL_SAMPLE_ALPHA_TO_COVERAGE ); 
  }




  void renderTail( float time )
  {
    float per = 1.0;
    float xp, yp, zp;
    float xOff, yOff, zOff;

    ///////////////////////////////////////
    ///////////////////////////////////////
    vgl.gl().glBegin( GL.GL_QUAD_STRIP );
    //    for ( int i=14; i<_tailSize-4; i++ )
    for ( int i=0; i<_tailRenderSegments-1; i++ )
      //    int hlen = (int)((len-1)*0.5);
      //    for ( int ii=-hlen; ii<hlen; ii++ )
    {
      //      int i = ii+hlen;
      //      per           = 1.0 - (((float)(abs(ii))/(float)(hlen)));    

      if( _parent == null ) per = 1;
      //per = (((float)i/(float)(_tailSize)));
      //      per = 1.0-(((float)i/(float)(_tailSize)));
      else
      {      
        int sss = _tailSize/8;
        if( i <= sss )  // make head
          per = 1.0 - ((sss-i) / (float)sss);
      }        
      //      else if( i >= (buf.length-sss) )  // make tail
      //        per = (((buf.length)-i) / (float)sss);
      //else
      //  per = 1.0; 

      if( per > 1.0 ) per = 1.0;
      if( per < 0.0 ) per = 0.0;

      per *= _tailWidth;

      //if( i < _tailSize-1 )
      {
        Vector3 dir = Vector3.sub( _tail[i+1], _tail[i] );
        dir.normalize();

        Vector3 V = dir.cross( new Vector3( 0, 0, 1 ) );
        V.normalize();

        Vector3 N = dir.cross( V );
        N.normalize();

        //V = N.cross( dir );
        //V = dir.cross( N );

        //V.normalize();

        if( i == 0 )
          _right = V.copy();

        xp = _tail[i].x;
        yp = _tail[i].y;
        zp = _tail[i].z;
        //        xp = _tail[i].x + _right.x*sin(i*.2+time*8)*3*(_tailSize-i)*.053;
        //        yp = _tail[i].y - 30;// + _right.y*sin(i*.2+time*8)*3*(_tailSize-i)*.053;
        //        zp = _tail[i].z + _right.z*sin(i*.2+time*8)*3*(_tailSize-i)*.053;


        xOff = V.x * per;
        yOff = V.y * per;
        zOff = V.z * per;

        if( _parent != null ) vgl.gl().glColor4f( _tailColor[i].x, _tailColor[i].y, _tailColor[i].z, _tailColor[i].w );
        else vgl.gl().glColor4f( _color.x, _color.y, _color.z, _color.w );

        vgl.gl().glNormal3f( N.x, N.y, N.z );
        vgl.gl().glTexCoord2f( 0, 0 );
        vgl.gl().glVertex3f( xp - xOff, yp - yOff, 0 ); //zp - zOff );

        vgl.gl().glNormal3f( N.x, N.y, N.z );
        vgl.gl().glTexCoord2f( 1, 1 );
        vgl.gl().glVertex3f( xp + xOff, yp + yOff, 0 ); //zp + zOff );
      }
    }
    vgl.gl().glEnd();
  }



  void renderTailCylinder()
  {
    float invsteps = 1.0 / (float)(_tailSize);
    float invfacets = 1.0 / (float)(_facets);

    float pi2OverSteps = TWO_PI / (_tailSize);
    float pi2OverFacets = TWO_PI / _facets;
    float pi2MulInvsteps = TWO_PI * invsteps;
    float pi2MulInvfacets = TWO_PI * invfacets;

    //    float _p = 5;
    //    float _q = 5;
    //    float _scale = 20;
    //    float _thickness = 10;


    ///////////////////////////////////////////////////////////
    // Draw vine mesh
    ///////////////////////////////////////////////////////////

    //    int hlen = (int)((_tailSize-1)*0.5);
    //    for( int jj=-hlen; jj<hlen; jj++ )    
    //    for ( int j=0; j<_tailSize-1; j++ )
    for( int j=0; j<_tailRenderSegments-1; j++ )
    {
      //      int j = jj+hlen;

      /*      // draw textured quads along the path
       activeNoteTex.enable();
       // Draw activator center 
       vgl.setAlphaBlend();
       vgl.setDepthWrite( false );
       vgl.fill( .3 );//, 1.0-_agePer );
       vgl.pushMatrix();
       vgl.translate( _tail[j].x, _tail[j].y, _tail[j].z );
       //      vgl.rotateX( 90 );
       vgl.quad( 15 );
       vgl.popMatrix();
       activeNoteTex.disable();*/

      float per = 1.0;

      int sss = _tailSize/8;
      if( j <= sss )  // make head
        per = 1.0 - ((sss-j) / (float)sss);
      //else if( j >= (buf.length-sss) )  // make tail
      //per = (((buf.length)-j) / (float)sss);
      else
        per = 1.0; 

      /*      //      per = 1.0 - (((float)(abs(jj))/(float)(hlen)));
       if( _type == 1 ) per = (((float)(j)/(float)(_tailSize)));
       else per = 1;
       per = j / (float)_tailRenderSegments; //_tailSize;
       */
      /*
      float dthd1 = 10;
       float th = _tailWidth;
       float dthd2 = _tailSize;
       float dthm = 1 * _tailWidth;
       
       //if( j < 10 )
       // {
       // per = 1.0-(dthm-min(dthm*(j)/dthd1,dthm)); //(dthm-min(dthm*(min(_tailSize,_tailRenderSegments)-(j))/dthd2,dthm));
       // per = max( per, 0 );
       // }
       //else
       {
       per = (dthm-min(dthm*(min(_tailSize,_tailRenderSegments)-(j))/dthd2,dthm));
       //per = max( per, 0 );
       }
       */

      per *= _tailWidth;


      // first point
      Vector3 center = new Vector3();
      center = _tail[j];//.copy();

      // next point
      Vector3 nextPoint = new Vector3();
      nextPoint = _tail[j+1];//.copy();

      // get TBN matrix for transformation
      Vector3 T = new Vector3();
      T.x = nextPoint.x - center.x;
      T.y = nextPoint.y - center.y;
      T.z = nextPoint.z - center.z;
      T.normalize();

      Vector3 N = new Vector3( 0, 1, 1 );
      /*N.x = nextPoint.x + center.x;
       N.y = nextPoint.y + center.y;
       N.z = nextPoint.z + center.z;
       N.normalize();*/

      Vector3 B = T.cross( N );
      B.normalize();
      N = B.cross( T );
      // normalize vectors
      N.normalize();

      if( j == 0 )
      {
        _right = N.copy();
      }

      // go through facets and tweak a bit with some distortions
      for( int i=0; i<_facets+1; i++ )
      {
        float x = (sin(i * pi2OverFacets) * per);
        float y = (cos(i * pi2OverFacets) * per);        

        // distort knot along the curve
        if( _displaces != 0.0 )
        {
          x *= (1 + (sin(_dispoffset + _displaces * j * pi2OverSteps) * _dispscale));
          y *= (1 + (cos(_dispoffset + _displaces * j * pi2OverSteps) * _dispscale));
        }

        int idx = yTable[j] + i;
        _vertices[ idx ].x = N.x * x + B.x * y + center.x;
        _vertices[ idx ].y = N.y * x + B.y * y + center.y;
        _vertices[ idx ].z = N.z * x + B.z * y + center.z;

        _texcoords[ idx ].x = ((float)i / (float)_facets) * 1;
        _texcoords[ idx ].y = ((float)(j) / (float)_tailRenderSegments) * 10; 
        //        _texcoords[ idx ].y = ((float)(j-_tailSize) / (float)_tailSize) * 10; 
        //        _texcoords[ idx ].y = ((float)j / (float)_tailSize-1) * 10; 

        // get vertex normal
        _normals[ idx ].x = _vertices[ idx ].x - center.x;
        _normals[ idx ].y = _vertices[ idx ].y - center.y;
        _normals[ idx ].z = _vertices[ idx ].z - center.z;
        // normalize
        _normals[ idx ].normalize();
      }

      // duplicate sideways vertices/normals
      int idxSrc = yTable[j] + 0;
      int idxDest = yTable[j] + _facets;

      _vertices[ idxDest ].x = _vertices[ idxSrc ].x;
      _vertices[ idxDest ].y = _vertices[ idxSrc  ].y;
      _vertices[ idxDest ].z = _vertices[ idxSrc ].z;
      _texcoords[ idxDest ].x = _texcoords[ idxSrc ].x;
      _texcoords[ idxDest ].y = _texcoords[ idxSrc ].y;
      _normals[ idxDest ].x = _normals[ idxSrc ].x;
      _normals[ idxDest].y = _normals[ idxSrc ].y;
      _normals[ idxDest ].z = _normals[ idxSrc ].z;
    }

    /*    // duplicate vertices/normals. to get a closed surface
     for( int i=0; i<_facets+1; i++ )
     {
     _vertices[yTable[_tailSize-1] + i].x = _vertices[i].x;
     _vertices[yTable[_tailSize-1] + i].y = _vertices[i].y;
     _vertices[yTable[_tailSize-1] + i].z = _vertices[i].z;
     _normals[yTable[_tailSize-1] + i].x = _normals[i].x;
     _normals[yTable[_tailSize-1] + i].y = _normals[i].y;
     _normals[yTable[_tailSize-1] + i].z = _normals[i].z;        
     }*/
    /*    // first are last as well
     _vertices[yTable[_tailSize-1] + _facets].x = _vertices[0].x;
     _vertices[yTable[_tailSize-1] + _facets].y = _vertices[0].y;
     _vertices[yTable[_tailSize-1] + _facets].z = _vertices[0].z;
     _normals[yTable[_tailSize-1] + _facets].x = _normals[0].x;
     _normals[yTable[_tailSize-1] + _facets].y = _normals[0].y;
     _normals[yTable[_tailSize-1] + _facets].z = _normals[0].z; */


    // Increase color as it grows
    //    _color.x += 0.01;
    //    _color.y += 0.01;
    //    _color.z += 0.01;

    //    vgl.enableLighting( false );
    //    vgl.enableTexture( false );
    /*    CGpass pass = diffuseSpecularCG.getTechniqueFirstPass( "Technique_Diffuse" );
     while( pass != null ) 
     {
     CgGL.cgSetPassState( pass );     
     
     diffuseSpecularCG.setTextureParameter( "ColorSampler", hll4.getId() );
     diffuseSpecularCG.setParameter3f( "lightPos", lightPos );
     diffuseSpecularCG.setParameter3f( "cameraPos", eye );
     diffuseSpecularCG.setParameter4x4f( "WorldViewProjection", CgGL.CG_GL_MODELVIEW_PROJECTION_MATRIX, CgGL.CG_GL_MATRIX_IDENTITY );
     diffuseSpecularCG.setParameter4x4f( "World", CgGL.CG_GL_MODELVIEW_MATRIX, CgGL.CG_GL_MATRIX_INVERSE_TRANSPOSE );
     */

    int j = 0;
    float umul= 1;
    float vmul = 10;
    float u, v1, v2;
    v1 = vmul*j * invsteps;
    v2 = vmul*(j+1) * invsteps;

    /*      vgl.gl().glBegin( GL.GL_TRIANGLE_STRIP );
     for( int i=0; i<_facets+1; i+=1 )
     {
     u = umul*i * invfacets; 
     
     vgl.gl().glColor4f( _color.x, _color.y, _color.z, 1.0 );//-_agePer );
     //        vgl.gl().glColor4f( _color.x-_agePer, _color.y-_agePer, _color.z-_agePer, 1 );//-_agePer );
     
     vgl.gl().glNormal3f( _normals[yTable[j]+i].x, _normals[yTable[j]+i].y, _normals[yTable[j]+i].z );
     vgl.gl().glTexCoord2f( u, v1 ); 
     vgl.gl().glVertex3f( _vertices[yTable[j]+i].x, _vertices[yTable[j]+i].y, _vertices[yTable[j]+i].z );
     
     vgl.gl().glNormal3f( _normals[yTable[j+1]+i].x, _normals[yTable[j+1]+i].y, _normals[yTable[j+1]+i].z );
     vgl.gl().glTexCoord2f( u, v2 );         
     vgl.gl().glVertex3f( _vertices[yTable[j+1]+i].x, _vertices[yTable[j+1]+i].y, _vertices[yTable[j+1]+i].z );
     }      
     vgl.gl().glEnd();*/

    //for( j=0; j<_tailSize-1; j++ )
    for( j=0; j<_tailRenderSegments-2; j++ )
    {
      //      v1 = vmul*j / (float)_tailRenderSegments;//* invsteps;
      //      v2 = vmul*(j+1) / (float)_tailRenderSegments;// * invsteps; 

      vgl.gl().glBegin( GL.GL_TRIANGLE_STRIP );
      for( int i=0; i<_facets+1; i++ )
      {
        //        u = umul*i * invfacets; 

        vgl.gl().glColor4f( _color.x, _color.y, _color.z, _color.w );
        //vgl.gl().glColor4f( _color.x-_agePer, _color.y-_agePer, _color.z-_agePer, _color.w-_agePer );

        vgl.gl().glNormal3f( _normals[yTable[j]+i].x, _normals[yTable[j]+i].y, _normals[yTable[j]+i].z );
        //        vgl.gl().glTexCoord2f( u, v1 ); 
        vgl.gl().glTexCoord2f( _texcoords[yTable[j]+i].x, _texcoords[yTable[j]+i].y ); 
        vgl.gl().glVertex3f( _vertices[yTable[j]+i].x, _vertices[yTable[j]+i].y, _vertices[yTable[j]+i].z );

        vgl.gl().glNormal3f( _normals[yTable[j+1]+i].x, _normals[yTable[j+1]+i].y, _normals[yTable[j+1]+i].z );
        //        vgl.gl().glTexCoord2f( u, v2 );         
        vgl.gl().glTexCoord2f( _texcoords[yTable[j+1]+i].x, _texcoords[yTable[j+1]+i].y ); 
        vgl.gl().glVertex3f( _vertices[yTable[j+1]+i].x, _vertices[yTable[j+1]+i].y, _vertices[yTable[j+1]+i].z );
      }      
      vgl.gl().glEnd();
    }

    //      CgGL.cgResetPassState( pass );
    //      pass = CgGL.cgGetNextPass( pass );
    //    }     

    /****
     * ///////////////////////////////////////////////////////////
     * // Draw leafs on the vines
     * ///////////////////////////////////////////////////////////
     * 
     * //    vgl.setDepthWrite( false );
     * //    vgl.setDepthMask( false );
     * //    vgl.gl().glAlphaFunc( GL.GL_GREATER, 0.5 );
     * //    vgl.gl().glEnable( GL.GL_ALPHA_TEST );
     * 
     * vgl.gl().glEnable( GL.GL_SAMPLE_ALPHA_TO_COVERAGE );
     * 
     * float flowerThreshold = 0.7;
     * //    float vall = random( 0, 5 );
     * float vall = _tailRenderSegments%15;//180;//random( 190 );
     * 
     * if( _flowerCount < _numFlowers )
     * {
     * //      if( vall == 0 && _tailRenderSegments < _tailSize )
     * if( vall < flowerThreshold && _tailRenderSegments < _tailSize )
     * {
     * _flowerCount ++;
     * _flowers.add( new Vector4(_head.x, _head.y, _head.z, 0) );
     * // size for each leaf. it will increase, giving the growth effect
     * _flowersSizeValue.add( new Vector3(0, 0, 0) );
     * 
     * // we use vall to determine the direction of the leaf.
     * // if over some value it goes the dir way otherwise go opposite way (invert)
     * _flowersDir.add( new Vector4(_right.x, _right.y, _right.z, vall) );
     * }
     * 
    /*      // Sort data back to front. 
     * // store distance in w channel of our 4-d vector
     * for( int i=0; i<_flowers.size(); i++ )
     * {
     * Vector3 flowerPos = ((Vector4)_flowers.get(i)).getXYZ();
     * Vector3 dist = Vector3.sub( eye, flowerPos );
     * float d = Vector3.dot( dist, dist );
     * ((Vector4)_flowers.get(i)).w = d;
     * }
     * Collections.sort(_flowers, new Comparator() 
     * {
     * public int compare(Object o1, Object o2) 
     * {  
     * Vector4 p1 = (Vector4)o1;  
     * Vector4 p2 = (Vector4)o2;  
     * return p1.w < p2.w ? -1 : (p1.w > p2.w ? +1 : 0);  
     * }  
     } );  */
    /****    }
     * 
     * pass = alphaCoverageCG.getTechniqueFirstPass( "Technique_AlphaToCoverage" );
     * while( pass != null ) 
     * {
     * CgGL.cgSetPassState( pass );     
     * 
     * //    flowerTex.enable();
     * for( int i=0; i<_flowers.size(); i++ )
     * {
     * Vector4 p = (Vector4)_flowers.get(i);
     * Vector4 pd = (Vector4)_flowersDir.get(i);
     * Vector3 growSize = (Vector3)_flowersSizeValue.get(i);
     * 
     * if( growSize.x < 4.0 ) growSize.x += 0.4;
     * //      if( growSize.x < 5.0 ) growSize.x += 0.06;
     * 
     * vgl.pushMatrix();
     * vgl.translate( p.x, p.y, p.z );
     * //      vgl.rotateY( 30 );
     * //      vgl.rect( _headSize*p.w, _headSize*2*p.w );
     * vgl.scale( growSize.x );
     * 
     * float s = 1;//p.w;
     * Vector3[] rect= new Vector3[4];
     * rect[0] = new Vector3( -6*s,  0*s, 0 );
     * rect[1] = new Vector3(  6*s,  0*s, 0 );
     * rect[2] = new Vector3(  6*s, 20*s, 0 );
     * rect[3] = new Vector3( -6*s, 20*s, 0 );
     * 
     * // Render this leaf in the normal's direction or the opposite
     * // Based on a random value we check against
     * transformRect( new Vector3(0, 1, 0), pd.getXYZ(), new Vector3(), rect );
     * //      if( pd.w > flowerThreshold*0.75 )
     * //        transformRect( new Vector3(0, 1, 0), pd.getXYZ(), new Vector3(), rect );
     * //      else
     * //        pd.mul( -1 );
     * //        transformRect( new Vector3(0, 1, 0), pd.getXYZ(), new Vector3(), rect );
     * //      }
     * 
     * 
     * alphaCoverageCG.setTextureParameter( "ColorSampler", flowerTex.getId() );
     * alphaCoverageCG.setTextureParameter( "DervSampler", flowerAlphaTex.getId() );
     * alphaCoverageCG.setParameter3f( "lightPos", lightPos );
     * alphaCoverageCG.setParameter3f( "camPos", eye );
     * alphaCoverageCG.setParameter2f( "texSize", flowerTex.getWidth(), flowerTex.getHeight() );
     * alphaCoverageCG.setParameter4x4f( "WorldViewProjection", CgGL.CG_GL_MODELVIEW_PROJECTION_MATRIX, CgGL.CG_GL_MATRIX_IDENTITY );
     * alphaCoverageCG.setParameter4x4f( "World", CgGL.CG_GL_MODELVIEW_MATRIX, CgGL.CG_GL_MATRIX_INVERSE_TRANSPOSE );
     * 
     * 
     * vgl.gl().glBegin( GL.GL_QUADS );
     * vgl.gl().glColor4f( 1, 1, 1, 1 );
     * 
     * vgl.gl().glTexCoord2f( 0, 0 ); 
     * vgl.gl().glNormal3f( pd.x, pd.y, pd.z );
     * vgl.gl().glVertex3f( rect[0].x, rect[0].y, rect[0].z );
     * //      vgl.gl().glVertex3f( rect[0].x*s, rect[0].y*s, rect[0].z*s );
     * 
     * vgl.gl().glTexCoord2f( 1, 0 ); 
     * vgl.gl().glNormal3f( pd.x, pd.y, pd.z );
     * vgl.gl().glVertex3f(  rect[1].x, rect[1].y, rect[1].z );
     * //      vgl.gl().glVertex3f(  rect[1].x*s, rect[1].y*s, rect[1].z*s );
     * 
     * vgl.gl().glTexCoord2f( 1, 1 ); 
     * vgl.gl().glNormal3f( pd.x, pd.y, pd.z );
     * vgl.gl().glVertex3f( rect[2].x, rect[2].y, rect[2].z );
     * //      vgl.gl().glVertex3f( rect[2].x*s, rect[2].y*s, rect[2].z*s );
     * 
     * vgl.gl().glTexCoord2f( 0, 1 ); 
     * vgl.gl().glNormal3f( pd.x, pd.y, pd.z );
     * vgl.gl().glVertex3f( rect[3].x, rect[3].y, rect[3].z );
     * //      vgl.gl().glVertex3f( rect[3].x*s, rect[3].y*s, rect[3].z*s );
     * vgl.gl().glEnd();
     * 
     * vgl.popMatrix();
     * }
     * //    flowerTex.disable();
     * 
     * CgGL.cgResetPassState( pass );
     * pass = CgGL.cgGetNextPass( pass );
     * }     
     * 
     * vgl.gl().glDisable( GL.GL_SAMPLE_ALPHA_TO_COVERAGE );
     * //    vgl.gl().glDisable( GL.GL_ALPHA_TEST );
     * vgl.setDepthMask( true );
     * vgl.setDepthWrite( true );    
     ***/
  }



  void renderTailFromBuffer( Vector3[] buf, float yOffset )
  {
    float per;
    float xp, yp, zp;
    float xOff, yOff, zOff;

    ///////////////////////////////////////
    ///////////////////////////////////////
    vgl.gl().glBegin( GL.GL_QUAD_STRIP );
    //for ( int i=0; i<buf.length-1; i++ )
    int hlen = (int)((buf.length-1)*0.5);
    for( int ii=-hlen+1; ii<hlen+1; ii++ )     
    {
      int i = ii+hlen;
      per = 1.2 - (((float)(abs(ii))/(float)(hlen))*0.8); 

      per *= _tailWidth * 0.5;

      //      if( i < buf.length-1 )
      {
        //Vector3 perp0 = Vector3.sub( ploc[j][i], ploc[j][i+1] );
        Vector3 dir = Vector3.sub( buf[i+1], buf[i] );
        dir.normalize();
        Vector3 V = dir.cross( new Vector3( 0, 1, 0 ) );
        V.normalize();
        Vector3 N = dir.cross( V );
        N.normalize();
        V = N.cross( dir );
        //V = dir.cross( N );
        V.normalize();

        _right = V.copy();

        xp = buf[i].x;
        yp = buf[i].y;
        zp = buf[i].z;

        xOff = V.x * per;
        yOff = V.y * per;
        zOff = V.z * per;

        vgl.gl().glColor4f( 0, 0, 0, 0.5 );

        //      gl._gl.glNormal3f( N.x, N.y, N.z );
        //      gl._gl.glTexCoord2f( 0, 0 );
        vgl.gl().glVertex3f( xp - xOff, (yp - yOff) - yOffset, zp - zOff );
        //      gl._gl.glNormal3f( N.x, N.y, N.z );
        //      gl._gl.glTexCoord2f( 1, 1 );
        vgl.gl().glVertex3f( xp + xOff, (yp + yOff) - yOffset, zp + zOff );
      }
    }
    vgl.gl().glEnd();
  }


  void renderTailCylinderFromBuffer( Vector3[] buf, float uscale, float vscale )
  {
    if( buf == null || buf.length <= 0 ) return;

    float invsteps = 1.0 / (float)(buf.length);
    float invfacets = 1.0 / (float)(_facets);

    float pi2OverSteps = TWO_PI / (float)(buf.length);
    float pi2OverFacets = TWO_PI / (float)_facets;
    //    float pi2MulInvsteps = TWO_PI * invsteps;
    //    float pi2MulInvfacets = TWO_PI * invfacets;

    ///////////////////////////////////////////////////////////
    // Draw vine mesh
    ///////////////////////////////////////////////////////////

    //int hlen = (int)((buf.length-1)*0.5);
    //for( int jj=-hlen; jj<hlen+1; jj++ )     
    for( int j=0; j<(buf.length-1); j++ )
    {
      float per = 0;
      //int j = jj+hlen;       
      //per = 1.2 - (((float)(abs(jj))/(float)(hlen))*0.8); 

      /*      int sss = 20;
       if( j <= sss )  // make head
       per = 1.0 - ((sss-j) / (float)sss);
       else if( j >= (buf.length-sss) )  // make tail
       per = (((buf.length)-j) / (float)sss);
       else
       per = 1.0;*/

      //      per = 1 - (j / 200.0 ); //invsteps); 

      // make it grow based on a maxsize value and current size
      per = (buf.length/200.0) - (j / 200.0 ); //invsteps); 

      per *= _tailWidth;

      /*      float dthd1 = 10;
       float th = _tailWidth;
       float dthd2 = buf.length;
       float dthm = 1 * _tailWidth;
       //      float per = (dthm-min(dthm*(min(1000,buf.length)-(j))/dthd2,dthm));
       if( j < 10 )
       {
       per = 1.0-(dthm-min(dthm*(j)/dthd1,dthm)); //(dthm-min(dthm*(min(_tailSize,_tailRenderSegments)-(j))/dthd2,dthm));
       per = max( per, 0 );
       }
       else if( j >= 10 && j < buf.length-30 )
       {
       per = (dthm-min(dthm*(min(_tailSize,buf.length)-(j))/dthd2,dthm));
       per = max( per, 0 );
       }
       else
       {      
       per = 1.0-(dthm-min(dthm*(j)/dthd1,dthm)); //(dthm-min(dthm*(min(_tailSize,_tailRenderSegments)-(j))/dthd2,dthm));
       per = max( per, 0 );
       }*/

      // first point
      Vector3 center = buf[j];

      // next point
      Vector3 nextPoint = buf[j+1];

      // get TBN matrix for transformation
      Vector3 T = Vector3.sub( nextPoint, center );
      T.normalize();

      Vector3 N = new Vector3( 0, 1, 1 );
      //N = Vector3.add( nextPoint, center );
      //N.normalize();

      Vector3 B = Vector3.cross( T, N );
      B.normalize();
      N = Vector3.cross( B, T );
      N.normalize();

      // Compute right vector for the head point
      if( j == 0 )
      {
        _right = N.copy();
      }

      // go through facets and tweak a bit with some distortions
      for( int i=0; i<_facets+1; i++ )
      {
        float x = (sin(i * pi2OverFacets) * per);
        float y = (cos(i * pi2OverFacets) * per * 1.5);

        int idx = j*buf.length + i; //yTable[j] + i;
        _vertices[ idx ].x = N.x * x + B.x * y + center.x;
        _vertices[ idx ].y = N.y * x + B.y * y + center.y;
        _vertices[ idx ].z = N.z * x + B.z * y + center.z;

        _texcoords[ idx ].x = (i * invfacets) * uscale;
        _texcoords[ idx ].y = (j * invsteps) * vscale;

        // get vertex normal
        _normals[ idx ] = Vector3.sub( _vertices[idx], center );
        _normals[ idx ].normalize();
      }

      // duplicate sideways vertices/normals
      int idxSrc = j * buf.length + 0; //yTable[j] + 0;
      int idxDest = j * buf.length + _facets; //yTable[j] + _facets;

      _vertices[idxDest].set( _vertices[idxSrc] );
      _texcoords[idxDest].set( _texcoords[idxSrc] );
      _normals[idxDest].set( _normals[idxSrc] );
    }

    /*    // duplicate vertices/normals. to get a closed surface
     for( int i=0; i<_facets+1; i++ )
     {
     _vertices[yTable[_tailSize-1] + i].x = _vertices[i].x;
     _vertices[yTable[_tailSize-1] + i].y = _vertices[i].y;
     _vertices[yTable[_tailSize-1] + i].z = _vertices[i].z;
     _normals[yTable[_tailSize-1] + i].x = _normals[i].x;
     _normals[yTable[_tailSize-1] + i].y = _normals[i].y;
     _normals[yTable[_tailSize-1] + i].z = _normals[i].z;        
     }*/
    /*    // first are last as well
     _vertices[yTable[_tailSize-1] + _facets].x = _vertices[0].x;
     _vertices[yTable[_tailSize-1] + _facets].y = _vertices[0].y;
     _vertices[yTable[_tailSize-1] + _facets].z = _vertices[0].z;
     _normals[yTable[_tailSize-1] + _facets].x = _normals[0].x;
     _normals[yTable[_tailSize-1] + _facets].y = _normals[0].y;
     _normals[yTable[_tailSize-1] + _facets].z = _normals[0].z; */


    // Increase color as it grows
    //    _color.x += 0.01;
    //    _color.y += 0.01;
    //    _color.z += 0.01;

    //    vgl.enableLighting( false );
    //    vgl.enableTexture( false );
    /*    CGpass pass = diffuseSpecularCG.getTechniqueFirstPass( "Technique_Diffuse" );
     while( pass != null ) 
     {
     CgGL.cgSetPassState( pass );     
     
     diffuseSpecularCG.setTextureParameter( "ColorSampler", hll4.getId() );
     diffuseSpecularCG.setParameter3f( "lightPos", lightPos );
     diffuseSpecularCG.setParameter3f( "cameraPos", eye );
     diffuseSpecularCG.setParameter4x4f( "WorldViewProjection", CgGL.CG_GL_MODELVIEW_PROJECTION_MATRIX, CgGL.CG_GL_MATRIX_IDENTITY );
     diffuseSpecularCG.setParameter4x4f( "World", CgGL.CG_GL_MODELVIEW_MATRIX, CgGL.CG_GL_MATRIX_INVERSE_TRANSPOSE );
     */

    /*
    //
     // BOTTOM
     //
     for( int i=0; i<_facets-2; i++ )
     {
     vgl.gl().glBegin( GL.GL_TRIANGLES );
     vgl.gl().glColor4f( 1, 0, ((i+1)/(float)_facets+1)*0.1, 1 );
     
     vgl.gl().glNormal3f( _normals[0].x, _normals[0].y, _normals[0].z );
     //        vgl.gl().glTexCoord2f( _texcoords[y+0].x, _texcoords[y+0].y ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE1, 1, 0, 0 ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE2,  0, 1, 0 ); 
     vgl.gl().glVertex3f( _vertices[0].x, _vertices[0].y, _vertices[0].z );
     
     vgl.gl().glNormal3f( _normals[i+1].x, _normals[i+1].y, _normals[i+1].z );
     //        vgl.gl().glTexCoord2f( _texcoords[y+0].x, _texcoords[y+0].y ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE1, 1, 0, 0 ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE2,  0, 1, 0 ); 
     vgl.gl().glVertex3f( _vertices[i+1].x, _vertices[i+1].y, _vertices[i+1].z );
     
     vgl.gl().glNormal3f( _normals[i+2].x, _normals[i+2].y, _normals[i+2].z );
     //        vgl.gl().glTexCoord2f( _texcoords[y+0].x, _texcoords[y+0].y ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE1, 1, 0, 0 ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE2,  0, 1, 0 ); 
     vgl.gl().glVertex3f( _vertices[i+2].x, _vertices[i+2].y, _vertices[i+2].z );
     vgl.gl().glEnd();
     }
     
     
     //
     // TOP
     //
     for( int ii=(buf.length*_facets)-_facets; ii<buf.length*_facets; ii++ )
     {
     vgl.gl().glBegin( GL.GL_TRIANGLES );
     vgl.gl().glColor4f( 1, 0, ((ii+1)/(float)_facets+1)*0.1, 1 );
     
     vgl.gl().glNormal3f( _normals[ii+0].x, _normals[ii+0].y, _normals[ii+0].z );
     //        vgl.gl().glTexCoord2f( _texcoords[y+0].x, _texcoords[y+0].y ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE1, 1, 0, 0 ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE2,  0, 1, 0 ); 
     vgl.gl().glVertex3f( _vertices[ii+0].x, _vertices[ii+0].y, _vertices[ii+0].z );
     
     vgl.gl().glNormal3f( _normals[ii+1].x, _normals[ii+1].y, _normals[ii+1].z );
     //        vgl.gl().glTexCoord2f( _texcoords[y+0].x, _texcoords[y+0].y ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE1, 1, 0, 0 ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE2,  0, 1, 0 ); 
     vgl.gl().glVertex3f( _vertices[ii+1].x, _vertices[ii+1].y, _vertices[ii+1].z );
     
     vgl.gl().glNormal3f( _normals[ii+2].x, _normals[ii+2].y, _normals[ii+2].z );
     //        vgl.gl().glTexCoord2f( _texcoords[y+0].x, _texcoords[y+0].y ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE1, 1, 0, 0 ); 
     //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE2,  0, 1, 0 ); 
     vgl.gl().glVertex3f( _vertices[ii+2].x, _vertices[ii+2].y, _vertices[ii+2].z );
     vgl.gl().glEnd();
     }
     */


    //
    // RENDER RIBBON
    //
    int i=0;
    int j=0;
    for( j=0; j<buf.length-2; j++ )
    {
      //      v1 = vmul*j / (float)_tailRenderSegments;//* invsteps;
      //      v2 = vmul*(j+1) / (float)_tailRenderSegments;// * invsteps; 

      vgl.gl().glBegin( GL.GL_TRIANGLE_STRIP );
      for( i=0; i<_facets+1; i++ )
      {
        int idx0 = j * buf.length + i;
        int idx1 = (j+1) * buf.length + i;

        //        u = umul*i * invfacets; 

        vgl.gl().glColor4f( _color.x, _color.y, _color.z, _color.w );
        //        vgl.gl().glColor4f( 0, 0, ((i+1)/(float)_facets+1)*0.1, 1 );
        //        vgl.gl().glColor4f( random(1), random(1), random(1), 1 );

        vgl.gl().glNormal3f( _normals[idx0].x, _normals[idx0].y, _normals[idx0].z );
        //        vgl.gl().glTexCoord2f( _texcoords[yTable[j]+i].x, _texcoords[yTable[j]+i].y ); 
        //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE1, 1, 0, 0 ); 
        //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE2,  0, 1, 0 ); 
        vgl.gl().glVertex3f( _vertices[idx0].x, _vertices[idx0].y, _vertices[idx0].z );

        vgl.gl().glNormal3f( _normals[idx1].x, _normals[idx1].y, _normals[idx1].z );
        //        vgl.gl().glTexCoord2f( _texcoords[yTable[j+1]+i].x, _texcoords[yTable[j+1]+i].y ); 
        //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE1, 1, 0, 0 ); 
        //        vgl.gl().glMultiTexCoord3f( GL.GL_TEXTURE2,  0, 1, 0 ); 
        vgl.gl().glVertex3f( _vertices[idx1].x, _vertices[idx1].y, _vertices[idx1].z );
      }      
      vgl.gl().glEnd();
    }

    //      CgGL.cgResetPassState( pass );
    //      pass = CgGL.cgGetNextPass( pass );
    //    }     
  }


  void transformRect( Vector3 up, Vector3 V, Vector3 offset, Vector3[] rect ) 
  {
    for( int i=0; i<4; i++ )
    {
      Vector3 v = rect[i];
      Vector3 P = new Vector3( v.x, v.y, v.z );

      Vector3 NY = up.copy();
      NY.normalize();
      Vector3 NV = V.copy();
      NV.normalize();

      Vector3 N = NY.cross( NV );	// axis of rotation
      N.normalize();

      float dot = NY.dot( NV );	// cos angle
      float rad = ( acos(dot) );	// angle of rotation (radians)

      // quat from an angle and a rotation axis
      Quaternion quat = new Quaternion();

      quat.rotateAxis( N, rad );
      //                Vector3 axis = Vector3.sub( N, NY );
      //		quat.rotateAxis( axis, rad );

      // transform vertex
      Vector3 dv = quat.mul( P );

      v.set( dv );
      // translate to right position

      //                Vector3 disp = N.copy();
      //                disp.mul( _tailWidth*0.125 );
      //                offset.add( disp );

      v.add( offset );
    }
  } 

  void reset()
  {
    reset( _initPos, _timeToLive );
  }

  void reset( Vector3 newPos, float ttl )
  {
    setHead( newPos );
    computeTail();
    setTimeToLive( ttl );
    _tailRenderSegments = 0;
    _age = 0;

    if( _parent != null )
      _maxChildren = (int)random(100, _parent._maxChildren);

    _leafCurrSizeX = 0;
    _leafCurrSizeY = 0;
    leafTime = 0;
    leafStartTime = 0;
    leafGrowTime = random( 0.25, 1 );

    for( int i=0; i<_children.size(); i++ )
    {
      ((CylinderRoll)_children.get(i)).reset();
    }
    _children.clear();

    resetAngles();

    _doUpdate = true;  
  }



  void addChild( float dt )
  {    
    // If reached max depth. quit!
    if( _depth >= _maxDepth ) return;

    // if reached end of segmentation bail out!
//    if( _tailRenderSegments >= _tailSize-3 ) return;

    // Add children based on a random condition
    //if( random(100) < 100*0.9 ) return;
    //    _timeChildCount += dt;
    //    if( _timeChildCount < _timeToAddChild ) return;
    //    _timeChildCount = 0.0;

    //    if( _children.size() < _maxChildren )
    {
//      CylinderRoll rib = new CylinderRoll( _tailSize*8, _tailWidth/2, 2, 0, true );
      CylinderRoll rib = new CylinderRoll( (int)random( _tailSize/3.0, _tailSize/2.0), _tailWidth/2, 2, 0, true );

      rib.setRelation( this, _depth+1, _maxDepth );
      rib._maxChildren = _maxChildren;
      //rib._maxChildren = (int)random(0, _maxChildren);//(int)random( 6 ); //_maxChildren/5 );
      rib.setTimeToLive( _timeToLive );

      // set dest color
      int pix = (int)random(numShades);
      float rr = red( shades[pix]) / 255.0;
      float gg = green( shades[pix]) / 255.0;
      float bb = blue( shades[pix]) / 255.0;
      float aa = alpha( shades[pix]) / 255.0;
      rib._destColor.set( rr, gg, bb, aa );
      rib._destColor.mul( 2.75 );  // intensity
//     rib._destColor.set( 1, 1, 1, 1 );

      // set src color
//      rib._color.set( _destColor.x, _destColor.y, _destColor.z, _destColor.w );
      rib._color = new Vector4( 0, 0, 0, 1 );


      rib.computeTail();
      rib._type = 1;


      if( random(100) > 30 )
      {
        rib._leafTexID = sunflowerTex.getId();
        
        rib._leafSizeX = random( 1, 10 ) * 0.5;
        rib._leafSizeY = rib._leafSizeX * 2;
      }
      else
      {
        if( leafTex.getWidth() != leafTex.getHeight() )
        {
          rib._leafSizeX = random( 1, 5 ) * 0.5;
          rib._leafSizeY = rib._leafSizeX * 4;
        }
        else
        {
          rib._leafSizeX = random( 1, 10 ) * 0.5;
          rib._leafSizeY = rib._leafSizeX * 2;
        }
        
        rib._leafTexID = leafTex.getId();
      }
//      rib._leafTexID = _leafTexID;


      // scale flowers
      float rnd = random(1, 2);
      rib._leafSizeX *= rnd;
      rib._leafSizeY *= rnd; 


      rib.setHead( _head );
      rib._add = _right.copy();
      //      rib._add.set( random(-1,1), random(-1,1), random(-1,1) );
      _children.add( rib );
    }
  }


  // _____________________________________________________________
  // Members

  int _type;        // 0 means it grows all time. mainly for root ribbons
  // 1 means it stops when reached segment number (age is used to reset ribbon)

  float minNoise, maxNoise;

  int _facets;
  int[] yTable;
  Vector3[] _vertices;
  Vector3[] _texcoords; 
  Vector3[] _normals;

  //XTexture _headTex;

  Vector4  _color;
  Vector4  _destColor;

  boolean _doRenderHead;
  boolean _doUpdate;

  boolean _isDead;
  float _age;
  float _agePer;
  float _timeToLive;
  float _invTimeToLive;

  Vector3 _initPos;

  float _headSize;
  Vector3 _head;
  Vector3 _right;
  Vector3 _target;

  Vector3  _add;
  float _addDamp;

  float _theta, _phi;
  float _thetaAdd, _phiAdd;
  float _angle, _angleAdd;
  float _rad;

  Vector3 _gravity;

  boolean _usePerlin;
  Vector3 _perlin;

  float _dispoffset;
  float _displaces;
  float _dispscale;

  float _tailWidth;
  int  _tailRenderSegments;    // counts number of tail segments to render  
  int  _tailSize;
  Vector3[] _tail;
  Vector4[] _tailColor;

  int _flowerCount;
  int _numFlowers;
  ArrayList _flowers;
  ArrayList _flowersSizeValue;
  ArrayList _flowersDir;

  int _leafTexID;
  float _leafCurrSizeX, _leafCurrSizeY;
  float _leafSizeX, _leafSizeY;
  float leafTime;
  float leafStartTime;
  float leafGrowTime;

  // Tree related members
  CylinderRoll _parent;

  int _depth;
  int _maxDepth;

  float _timeChildCount;
  float _timeToAddChild;
  int _maxChildren;
  ArrayList _children;
}

