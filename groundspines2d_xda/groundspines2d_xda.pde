// victor martins, pixelnerve.

import javax.media.opengl.*;
import processing.opengl.*;
import vitamin.*;
import TUIO.*;

boolean useTUIO = true;
//boolean saveBigFrame = false;
boolean saveFrameSequence = false;
//int frameToStop = 2000;

static int FLOWERS = 0;
static int WORMS = 1;
static int FX_COUNT = 2;
int mCurrEffect = 0;
boolean doChangeEffect = true;

static int	TESS_RESOLUTION = 30;
static int	MAX_VERTICES = 3000;
static int	MAX_LINES = 12;

int WIDTH = 1024;
int HEIGHT = 768;
float aspectRatio = WIDTH/(float)HEIGHT; 


	final float cmul = 1.0f/(float)255.0f;
	Color4 colors[] = { new Color4(29, 195, 43, 1 ),
						new Color4(163, 187, 125, 1 ),
						new Color4(222, 237, 167, 1 ),
						new Color4(38, 128, 4, 1 ),
						new Color4(12, 39, 46, 1 ),

						new Color4(80,57,42, 1 ),
						new Color4(182,73,0, 1 ),
						new Color4(173,187,75, 1 ),
						new Color4(217,208,145, 1 ),
						new Color4(170,8,69, 1 ),
	};


VGL vgl;

TuioProcessing tuioClient;


Vector3 eye, target, up;

float xPos, yPos;
float oldXPos, oldYPos;
float clickTime = 0;

//XTexture cylTex;
//XTexture leafTex;
VTexture2D cylTex;
VTexture2D leafTex;
VTexture2D sunflowerTex;

int numRibs = 10;
int numSegs = 20;
Vector3[][] buf;
Vector3[][] obuf;

float[] shadowAlpha;
float[] cylTimeSpeed;
ArrayList[] renderbuf;


int			mTotalVertices;
boolean			mIsNewLine;
int               	mCurrLinha;
ArrayList<Linha>	mLinhas;

//CylinderRoll cyl;

VTimer timer;
float frameTime;
float time;
float startTime;
float stoppedTime;

CylinderRoll rootRib;


PImage imgShades;
int numShades = 128;
int[] shades; 


///___________________________________________________________
void setup()
{
  size( WIDTH, HEIGHT, OPENGL );

  hint( ENABLE_OPENGL_4X_SMOOTH );
  frameRate( 60 );

  aspectRatio = width/(float)height; 
  vgl = new VGL( this );

  if( useTUIO ) 
    tuioClient  = new TuioProcessing(this);


  imgShades = loadImage( "texture_blue.png" );  
//  imgShades = loadImage( "cancelada_inv.png" );
  shades = new int[numShades];
  for(int j=0; j<numShades; j++ )
  {
    int x = (int)random(0, imgShades.width);
    int y = (int)random(0, imgShades.height);
    shades[j] = imgShades.pixels[x+y*imgShades.width];
  }
  

//  cylTex = new XTexture( "ribbon.png" );
//  leafTex = new XTexture( "w_circle.png" );  
  cylTex = new VTexture2D( vgl.gl(), dataPath("ribbon.png" ) );
  leafTex = new VTexture2D( vgl.gl(), dataPath("w_circle.png" ) );  
  sunflowerTex = new VTexture2D( vgl.gl(), dataPath("05.png") );

  eye = new Vector3();
  target = new Vector3();
  up = new Vector3( 0, 1, 0 );


        mCurrLinha = 0;
        mLinhas = new ArrayList<Linha>();
        mTotalVertices = 0;
        mIsNewLine = false;


  //  CylinderRoll( int tailSize, float tailWidth, int facets, float headSize, boolean renderHead )
//  cyl = new CylinderRoll( 10000+numSegs, 2, 2, 0, false );
//  cyl.computeTail();
//  cyl.setHead( 0, 0, 0 );

  rootRib = new CylinderRoll( numSegs*2, 2, 2, 0, true );
  rootRib.computeTail();
  rootRib._type = 0;
  rootRib.setHead( 0, 40, 0 );
  rootRib._leafTexID = leafTex.getId();
  rootRib._color.set( 1, 1, 1, 1/10.0 );

  cylTimeSpeed = new float[numRibs];
  shadowAlpha = new float[numRibs];

  buf = new Vector3[numRibs][numSegs];
  obuf = new Vector3[numRibs][numSegs];
  for( int i=0; i<numRibs; i++ )
  {
    obuf[i] = new Vector3[numSegs];
    buf[i] = new Vector3[numSegs];
  }


  for( int j=0; j<numRibs; j++ )
  {
    shadowAlpha[j] = 0;//random(0.0, 0.25 );
    cylTimeSpeed[j] = random( 0.5, 5 );

    float theta = 0;
    float tadd = random( -5, 5 );
    //float tadd = random( -360.0/(float)numSegs, 360.0/(float)numSegs );

    // Position of each particle is generated randomly, but I used a special normalized coordinates. 
    // Using following formula (cos(?)sqrt(1-u²), sin(?)sqrt(1-u²), u) where 0???2? and -1?u?1, 
    // gives me an evenly distributed set of points instead of spherical coordinates, 
    // which causes too many points to cluster at the poles    
    float rad = 200; //10 + random( 250 );
    float angle = j*2*PI / (float)numRibs; //random( 0.0, 2*PI );
    float u = random( -1.0, 1.0 );
    //float u = (j/(float)numRibs)*2 - 1; //random( -1.0, 1.0 );
    float x = rad * cos( angle ) * sqrt(1-u*u);
    float y = -10;
    float z = rad * sin( angle ) * sqrt(1-u*u);
    //    float x = rad * cos( angle );
    //    float y = -10;
    //    float z = rad * sin( angle );


    /*    Vector3 pos = new Vector3( x, y, z );    
     boolean foundSpot = false;
     while( !foundSpot )
     {
     int count = 0;
     for( int j2=0; j2<numRibs; j2++ )
     {
     if( j2 != j )
     {
     rad = 10 + random( 300 );
     angle = random( -PI, PI );
     x = rad * cos( angle );
     y = 0;
     z = rad * sin( angle );
     Vector3 tmp = new Vector3( x, y, z );
     if( Vector3.distance(tmp, pos) > 30 )
     {
     count++;
     }
     }
     }
     println( count );
     if( count >= numRibs-5 )
     {      
     foundSpot = true;
     break;
     }      
     }*/


    float headX = random(8,10);// * 1.5;
    float headY = headX * 0.85;// * random(1,3);

    float hx = headX;
    float hy = headY;

    /*    buf[j][0] = new Vector3();
     buf[j][0].set( x, y, z );
     obuf[j][0] = new Vector3();
     obuf[j][0].set( x, y, z );*/
    for( int i=0; i<numSegs; i++ )
    {     
      buf[j][i] = new Vector3();
      buf[j][i].set( x, y, z );

      obuf[j][i] = new Vector3();
      obuf[j][i].set( x, y, z );

      //      if( i > 4 )
      {
        x += (hx * sin( radians(theta) ));
        y += (hy * cos( radians(theta) ));

        hx -= (headX/(float)numSegs) * 2;
        //        if( hx < 1.0 ) hx = 1.0;
        hy -= (headY/(float)numSegs);
        //        hy -= 2*pow( (headY/(float)numSegs), i);
        //        if( hy < 1.0 ) hy = 1.0;

        theta += tadd;    
      }  
      //      else
      //        y += hy;
    }
  }

  renderbuf = new ArrayList[numRibs];
  for( int j=0; j<numRibs; j++ )
  {
    renderbuf[j] = new ArrayList();
  }

  oldXPos = WIDTH/2;
  oldYPos = HEIGHT/2;
 

  timer = new VTimer();
  frameTime = 0;
  stoppedTime = 0;
  startTime = millis() * 0.001;
  timer.start();
}



Vector3 linearInterpolate( Vector3[] points, float tval )
{ 
  // 0 <= tval < points.length-1
  int i = int(tval); 
  if ( i >= points.length-1 ) return null;   // dont go over bounds

  float t = tval - i;
  float t1 = 1-t;  

  Vector3 p0 = points[i+0];
  Vector3 p1 = points[i+1]; 
  float px = p0.x*t1 + p1.x*t;
  float py = p0.y*t1 + p1.y*t;
  float pz = p0.z*t1 + p1.z*t;

  return new Vector3( px, py, pz );
} 





///___________________________________________________________
void draw()
{ 
  
  frameTime = timer.getFrameTime();
  time = timer.getCurrTime();
  timer.update();
  //println( frameRate );


//   oldXPos = xPos;
//   oldYPos = yPos;


  if( useTUIO ) 
  {
    TuioCursor tcur;
    Vector tuioCursorList = null;
    tuioCursorList = tuioClient.getTuioCursors();

    if (tuioCursorList.size() > 0 )
    {
      tcur = (TuioCursor)tuioCursorList.elementAt(0);
      Vector pointList = tcur.getPath();

      //print(""+ tcur.getCursorID(),  tcur.getScreenX(width)-5,  tcur.getScreenY(height)+5);
      TuioPoint end_point = (TuioPoint)pointList.elementAt(0);

//      xPos = end_point.getScreenX(width);
//      yPos = height - end_point.getScreenY(height);
//      yPos = height - tcur.getScreenX(width);
//      xPos = width - tcur.getScreenY(height);
      //println( xPos + " " + yPos ); 
      //println( "has a point    " + xPos + " " + yPos );
    }
    else
    {
      xPos = oldXPos;
      yPos = oldYPos;
      //println( xPos + " " + yPos ); 
      //System.err.println( "NO point   " + xPos + " " + yPos);
    }
  }
  else
  {
    if( mousePressed )
    {
      xPos = mouseX;
      yPos = mouseY;
    }
  }


  vgl.begin();



  eye.set( rootRib._tail[1].x, rootRib._tail[1].y, rootRib._tail[1].z+150 );
  target.set( rootRib._tail[1].x, rootRib._tail[1].y, rootRib._tail[1].z );

  if( frameCount < 2 )
    vgl.background( 0 );
    
  if( doChangeEffect )
  {
      vgl.background( 0 );
      doChangeEffect = false;
  }
    
  vgl.ortho( width, height );

/*  vgl.enableTexture( false );
  vgl.pushMatrix();
  vgl.translate( width/2, height/2 );
  vgl.fill( 0, 1/(60.0) );
  vgl.rect( width, height );
  vgl.popMatrix();*/
  


    if( mCurrEffect == FLOWERS )
    {
      //
      // Draw main ribbon
      //
      vgl.setDepthWrite( false );
      vgl.setDepthMask( false );
      vgl.setAlphaBlend();
      vgl.gl().glDisable( GL.GL_CULL_FACE );
      vgl.enableTexture( false );
      rootRib.setHead( xPos, yPos, 0 );//60+cos(time*.259)*140, 60+sin(time*.1592)*140, 0 );
      rootRib.draw( time, frameTime );
    //  rootRib.update( time );
    }

    if( mCurrEffect == WORMS )
    {
        // Linhas
        vgl.background( 0 );
        renderLinhas();
    }


  vgl.end();
}





void update( float time )
{  
  for( int j=0; j<numRibs; j++ )
  {
    for( int i=0; i<numSegs; i++ )
    {
      float xx = .1*sin(time+(i/(float)numSegs));//random( -.1, .1 );

      buf[j][i].x = obuf[j][i].x + xx*i;//random( -.3*i, .3*i );
      buf[j][i].z = obuf[j][i].z + xx*i;//random( -.3*i, .3*i );
    }
  }

  /*
  // FUCK UP ONE
   float girth = 5;
   for( int j=0; j<numRibs; j++ )
   {
   buf[j][0].x = buf[j][0].x + sin(.1*j+time)*1;
   buf[j][0].z = buf[j][0].z + cos(.1*j+time)*1;
   //    buf[j][0].y += sin(j+time)*4;
   //    buf[j][0].z += cos(j+time*.5)*4;
   
   //    for( int i=numSegs-1; i>0; i-- )
   for( int i=1; i<numSegs; i++ )
   {
   float dx = buf[j][i].x - buf[j][i-1].x;
   float dy = buf[j][i].y - buf[j][i-1].y;
   float dz = buf[j][i].z - buf[j][i-1].z;
   
   float d = sqrt( dx*dx + dy*dy + dz*dz );
   float invD = 1.0 / d;
   buf[j][i].x = (buf[j][i-1].x + ((dx * girth) * invD));
   buf[j][i].y = (buf[j][i-1].y + ((dy * girth) * invD));
   buf[j][i].z = (buf[j][i-1].z + ((dz * girth) * invD));
   }   
   }*/
}


void keyPressed()
{
    if( key == ' ' )
    {
        mCurrEffect++;
        mCurrEffect = mCurrEffect % FX_COUNT;
        doChangeEffect = true;

        mCurrLinha = 0;
        mLinhas.clear();
    }

  if( key == 's' || key == 'S'  )
    save( "screen"+frameCount+".png" ); 
    
  if( key == 'c' || key == 'C' )
  {  
    vgl.background( 0 );
    rootRib.reset( new Vector3(xPos, yPos, 0), 100000 );
    mCurrLinha = 0;
    mLinhas.clear();
  }   
  
  if( key == 'q' || key == 'Q' )
  {
    rootRib._color.set( random(1), random(1), random(1), random(1) );
  }
}


void mousePressed()
{
  clickTime = time;  
  rootRib.reset( new Vector3(xPos, yPos, 0), 100000 );
  
  
  if( mCurrEffect == WORMS )
  {
		if( mCurrLinha < MAX_LINES )
		{
			//mLinhas.add( new Linha( pointer, new Color4(1, 0.72f, 0, 1), 2) );
			int rnd = (int)MathUtils.random(0, colors.length-1);
			mLinhas.add( new Linha( mCurrLinha, colors[rnd], 1+MathUtils.random(10)) );
			mIsNewLine = true;
			mCurrLinha++;
		}
  }
}



void mouseDragged()
{
if( mCurrEffect == WORMS )
{
		// If max vertices reached, close down line.
		if( mTotalVertices > MAX_VERTICES ) 
		{
            for( Linha l : mLinhas )
            {
                if( l.mID == mCurrLinha-1 )
                {
                	boolean result = false;
            		result = l.process( TESS_RESOLUTION );
                    if( !result )
                    {
                        println( "mousedrag kill line" );
                    	killLine( l );
                    	//break;
                    }
                }
            }
			return;
		}

        for( Linha l : mLinhas )
        {
            if( l.mID == mCurrLinha-1 )
            {
                l.addPoint( new Vector3(mouseX, mouseY, pmouseX-mouseX) );
            }
        } 
}
}

void mouseReleased()
{
if( mCurrEffect == WORMS )
{
        if( mLinhas.size() > 0 )
        {
            for( Linha l : mLinhas )
            {
                if( l.mID == mCurrLinha-1 )
                {
                	boolean result = false;
            		result = l.process( TESS_RESOLUTION );
                    if( !result )
                    {
                    	killLine( l );
                    	//break;
                    }
                }
            }
        }
}
}


///___________________________________________________________
void stop()
{
  vgl.release();
  super.stop();
}




void setupPointLight( Vector3 pos )
{
  GL g = vgl.gl();

  float[] light_emissive = { 0.0f, 0.0f, 0.0f, 1 };
  float[] light_ambient = { 0.01f, 0.01f, 0.01f, 0 };
  float[] light_diffuse = { 0.9f, 0.9f, 0.9f, 1.0f };
//  float[] light_diffuse = { 0.10f, 0.10f, 0.10f, 1.0f };
  float[] light_specular = { 1.0f, 1.0f, 1.0f, 1.0f };  
  float[] mat_shininess = { 64 };

  float[] light_position = { pos.x, pos.y, pos.z, 1.0f };  

  FloatBuffer fb;
  fb = FloatBuffer.wrap( light_ambient );
  g.glLightfv ( GL.GL_LIGHT1, GL.GL_AMBIENT, fb );
  fb = FloatBuffer.wrap( light_diffuse );
  g.glLightfv ( GL.GL_LIGHT1, GL.GL_DIFFUSE, fb );
  fb = FloatBuffer.wrap( light_specular );
  g.glLightfv ( GL.GL_LIGHT1, GL.GL_SPECULAR, fb );
//  fb = FloatBuffer.wrap( mat_shininess );
//  g.glLightfv( GL.GL_LIGHT1, GL.GL_SHININESS, fb );

  fb = FloatBuffer.wrap( light_position );
  g.glLightfv ( GL.GL_LIGHT1, GL.GL_POSITION, fb );  

  g.glEnable( GL.GL_LIGHT1 );
  g.glEnable( GL.GL_LIGHTING );

  g.glEnable( GL.GL_COLOR_MATERIAL );
  fb = FloatBuffer.wrap( light_emissive );
  g.glMaterialfv( GL.GL_FRONT_AND_BACK, GL.GL_AMBIENT, fb );
  fb = FloatBuffer.wrap( light_diffuse );
  g.glMaterialfv( GL.GL_FRONT_AND_BACK, GL.GL_DIFFUSE, fb );
  fb = FloatBuffer.wrap( mat_shininess );
  g.glMaterialfv( GL.GL_FRONT_AND_BACK, GL.GL_SHININESS, fb );
  fb = FloatBuffer.wrap( light_specular );
  g.glMaterialfv( GL.GL_FRONT_AND_BACK, GL.GL_SPECULAR, fb );
  
}  


void renderLinhas()
{
		for( Linha l : mLinhas )
		{
			l.step( vgl, time, timer.getFrameTime() );
		}
		for( Linha l : mLinhas )
		{
			// Check for out of boundary lines
			if( l.isDead() )
			{
            	killLine( l );
				break;
			}
		}
}

	void killLine( Linha l )
	{
		mLinhas.remove( l );
		mCurrLinha--;
	}

