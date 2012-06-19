
class Sphere
{
  int sphereStacks = 120;
  int sphereSlices = 120;
  Vector3[] sphereSurface;
  int[] sphereIndices;
  Vector3[] sphereSurfaceUV;
  Vector3[] sphereSurfaceNormal;
  Color4 _color;
  float _radius;
  
  int _callListID;
  boolean _callListCompiled;

  Sphere()
  {  
    _callListID = 0;
    _callListCompiled = false;

    _color = new Color4( 1.0f, 0.0f, 1.0f, 1.0f );
  }
  
  Sphere( boolean useList )
  {  
    _callListID = vgl.gl().glGenLists( 1 );
    _callListCompiled = false;

    _color = new Color4( 1.0f, 0.0f, 1.0f, 1.0f );
  }


  void buildSphere( int stacks, int slices, float rad )
  {
    Vector3 c = new Vector3( 0, 0, 0 );

    sphereStacks = stacks;
    sphereSlices = slices;
    
    int i, j;
    _radius = rad;

    Vector3 e = new Vector3();
    Vector3 p = new Vector3();

    int wid = slices;
    int len = (stacks+1)*(slices);
    sphereSurface = new Vector3[len];
    sphereSurfaceNormal = new Vector3[len];
    sphereSurfaceUV = new Vector3[len];
    
    for (j=0;j<len;j++)
    {
      sphereSurface[j] = new Vector3();
      sphereSurfaceNormal[j] = new Vector3();
      sphereSurfaceUV[j] = new Vector3();
    }
  
  
   //
   // compute sphere surface points
   //
   for( j=0; j<stacks+1; j++ )
   {
        for( i=0; i<slices; i++ )
        {
          float theta = j * PI / (stacks);
          float phi = i * 2 * PI / (slices);
  	  float sinTheta = sin(theta);
  	  float sinPhi = sin(phi);
  	  float cosTheta = cos(theta);
  	  float cosPhi = cos(phi);
  
          float tmpi = (1.0 - ((i) / float(slices-1)));
          tmpi *= 3.0;
          float tmpj = ((j) / float(stacks));
  
          e.x = cosPhi * sinTheta;
          e.y = cosTheta;
          e.z = sinPhi * sinTheta;
          p.x = c.x + _radius * e.x;
          p.y = c.y + _radius * e.y;
          p.z = c.z + _radius * e.z;
  
          int idx = j * wid + i;
          sphereSurface[idx].x = p.x;
          sphereSurface[idx].y = p.y;
          sphereSurface[idx].z = p.z;
          sphereSurfaceNormal[idx].x = e.x;
          sphereSurfaceNormal[idx].y = e.y;
          sphereSurfaceNormal[idx].z = e.z;
          sphereSurfaceNormal[idx].normalize();
          
          sphereSurfaceUV[idx].x = tmpi; //4*(i/(float)n);
          sphereSurfaceUV[idx].y = tmpj; //4*2*((j+1)/(float)n);
        }
    }
  
    for( i=0; i<stacks+1; i++ )
    {
      sphereSurface[(i)*slices+slices-1].x = sphereSurface[(i)*slices+0].x;
      sphereSurface[(i)*slices+slices-1].y = sphereSurface[(i)*slices+0].y;
      sphereSurface[(i)*slices+slices-1].z = sphereSurface[(i)*slices+0].z;
      sphereSurfaceNormal[(i)*slices+slices-1].x = sphereSurfaceNormal[(i)*slices+0].x;
      sphereSurfaceNormal[(i)*slices+slices-1].y = sphereSurfaceNormal[(i)*slices+0].y;
      sphereSurfaceNormal[(i)*slices+slices-1].z = sphereSurfaceNormal[(i)*slices+0].z;
      //sphereSurfaceUV[(i)*slices+slices-1].x = sphereSurfaceUV[(i)*slices+0].x;
      //sphereSurfaceUV[(i)*slices+slices-1].y = sphereSurfaceUV[(i)*slices+0].y;
      //sphereSurfaceUV[(i)*slices+slices-1].z = sphereSurfaceUV[(i)*slices+0].z;
    }

    sphereIndices = new int[len*2];
    int index = 0;
    for( j=0; j<stacks; j++ )
    {
      for( i=0; i<slices; i++ )
      {
        sphereIndices[index+0] = j*slices + (i%slices);
        sphereIndices[index+0] = (j+1)*slices + (i%slices);
      }
    }
  }


  void draw()
  {
    this.draw( 0, 0, 0, 1 );
  }


  void draw( float r )
  {
    this.draw( 0, 0, 0, r );
  }


  void draw( float x, float y, float z, float r )
  {
  
    // If the list is compiled and everything is ok, render
    if( _callListID > 0 && _callListCompiled )
    {
      vgl.gl().glCallList( _callListID );
      return;
    }

    if( _callListID > 0 && !_callListCompiled )
    {      
      vgl.gl().glNewList( _callListID, GL.GL_COMPILE ); 
      
      //vgl.enableLighting( true );
//      float[] matdiff = { _color.r, _color.g, _color.b, _color.a };
//      FloatBuffer fb = FloatBuffer.wrap( matdiff );
//      vgl.gl().glMaterialfv( GL.GL_FRONT_AND_BACK, GL.GL_DIFFUSE, fb );
    }


    int idx = 0;
    int idx2 = 0;
    for( int j=0; j<sphereStacks; j++ )
    {
      idx = j * (sphereSlices);
      idx2 = (j+1) * (sphereSlices);

      vgl.gl().glBegin( GL.GL_TRIANGLE_STRIP );
      vgl.gl().glColor4f( _color.r, _color.g, _color.b, _color.a );
      _color.debug();
      for( int i=0; i<sphereSlices; i++ )
      {
        float x1 = x+(sphereSurface[idx+i].x * r);
        float y1 = y+(sphereSurface[idx+i].y * r);
        float z1 = z+(sphereSurface[idx+i].z * r);
        float x2 = x+(sphereSurface[idx2+i].x * r);
        float y2 = y+(sphereSurface[idx2+i].y * r);
        float z2 = z+(sphereSurface[idx2+i].z * r);

        float nx1 = sphereSurfaceNormal[idx+i].x;
        float ny1 = sphereSurfaceNormal[idx+i].y;
        float nz1 = sphereSurfaceNormal[idx+i].z;
        float nx2 = sphereSurfaceNormal[idx2+i].x;
        float ny2 = sphereSurfaceNormal[idx2+i].y;
        float nz2 = sphereSurfaceNormal[idx2+i].z;

        vgl.gl().glNormal3f( nx1, ny1, nz1 );
        vgl.gl().glVertex3f( x1, y1, z1 );

        vgl.gl().glNormal3f( nx2, ny2, nz2 );
        vgl.gl().glVertex3f( x2, y2, z2 );
      }
      vgl.gl().glEnd();
    }


    if( _callListID > 0 && !_callListCompiled )
    {
      vgl.gl().glEndList();
      _callListCompiled = true;
    }
    
  }


  void drawSphereTextured( float x, float y, float z, float r )
  {
    // If the list is compiled and everything is ok, render
    if( _callListID > 0 && _callListCompiled )
    {
      vgl.gl().glCallList( _callListID );
      return;
    }

    if( _callListID > 0 && !_callListCompiled )
    {
      vgl.gl().glNewList( _callListID, GL.GL_COMPILE ); 

      //vgl.enableLighting( true );
//      float[] matdiff = { _color.r, _color.g, _color.b, _color.a };
//      FloatBuffer fb = FloatBuffer.wrap( matdiff );
//      vgl.gl().glMaterialfv( GL.GL_FRONT_AND_BACK, GL.GL_DIFFUSE, fb );
    }
    
    int idx = 0;
    int idx2 = 0;
    for( int j=0; j<sphereStacks; j++ )
    {
      idx = j * (sphereSlices);
      idx2 = (j+1) * (sphereSlices);
  
      vgl.gl().glBegin( GL.GL_TRIANGLE_STRIP );
      vgl.gl().glColor4f( _color.r, _color.g, _color.b, _color.a );
      for( int i=0; i<sphereSlices; i++ )
      {
        float x1 = x+(sphereSurface[idx+i].x * r);
        float y1 = y+(sphereSurface[idx+i].y * r);
        float z1 = z+(sphereSurface[idx+i].z * r);
        float x2 = x+(sphereSurface[idx2+i].x * r);
        float y2 = y+(sphereSurface[idx2+i].y * r);
        float z2 = z+(sphereSurface[idx2+i].z * r);
  
        float nx1 = sphereSurfaceNormal[idx+i].x;
        float ny1 = sphereSurfaceNormal[idx+i].y;
        float nz1 = sphereSurfaceNormal[idx+i].z;
        float nx2 = sphereSurfaceNormal[idx2+i].x;
        float ny2 = sphereSurfaceNormal[idx2+i].y;
        float nz2 = sphereSurfaceNormal[idx2+i].z;
  
        vgl.gl().glNormal3f( nx1, ny1, nz1 );
        vgl.gl().glTexCoord2f( sphereSurfaceUV[idx+i].x, sphereSurfaceUV[idx+i].y );
        vgl.gl().glVertex3f( x1, y1, z1 );
  
        vgl.gl().glNormal3f( nx2, ny2, nz2 );
        vgl.gl().glTexCoord2f( sphereSurfaceUV[idx2+i].x, sphereSurfaceUV[idx2+i].y );
        vgl.gl().glVertex3f( x2, y2, z2 );
      }
      vgl.gl().glEnd();
    }
    
    if( _callListID > 0 && !_callListCompiled )
    {
      vgl.gl().glEndList();
      _callListCompiled = true;
    }
  }

  /*
   *
   *
  */
  void setColor( float r, float g, float b, float a )
  {
    _color.set( r, g, b, a );
  }
}
