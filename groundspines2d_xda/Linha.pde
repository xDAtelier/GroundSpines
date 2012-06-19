import vitamin.*;
import javax.media.opengl.*;
import static javax.media.opengl.GL.*;

import java.nio.FloatBuffer;
import java.util.ArrayList;

import vitamin.interpolation.*;
import vitamin.math.Color4;
import vitamin.math.MathUtils;
import vitamin.math.Vector3;
import vitamin.utils.BufferUtils;


class Linha
{
	static final boolean USE_PATH_SKELETON = false;
	static final boolean USE_TEXTURE = true;
    static final int MAX_VERTICES = 300;
    static final float MIN_DISTANCE = 15;
    static final float LEG_SIZE = 2.25f;



    public void LOG( String msg )
    {
    	System.out.println( "****INFO:  " + msg );
    }


    Linha( int id, Color4 color_, float lineWidth )
    {
    	// Id for the finger drawing this line. It gets null'ed after line is closed/complete
    	mID = id;
    	
    	mAlpha = 1.0f;
    	mColor = color_;
    	
        mDoBodyAnimation = false;
        
        mIsDead = false;
        
        mIsAnimated = false;
        mIsLineClosed = false;
        
        mPointList = new ArrayList<Vector3>();
        mLine = new ArrayList<LineJoint>();
        
        mCountTime = 0;
        mAnimateTime = 5;
        mIsAnimated = false;
        mHeadVel = new Vector3();
        mHeadAccel = new Vector3();
        mHeadDir = new Vector3();
        mAccel = 0;   
        mDamping = MathUtils.random(0.75f, 0.95f );

        mLineCountTime = 0;
        mLineAnimationTime = 2.5f;
        mLineWidth = 1;
        mLineTargetWidth = lineWidth;
        
        mAge = 0;
        mLifeTime = 9+MathUtils.random(20);
        mOneOverLifeTime = 1.0f / mLifeTime;

        mLineType = (int)(MathUtils.random(100))%2;
        
        
        // Alloc vertex data memory
        allocate( MAX_VERTICES );
        
//        mBodyMesh = new Mesh( false, 3, 3, 
//        		new VertexAttribute(Usage.Position, 3, "a_position"),
//                new VertexAttribute(Usage.Color, 4, "a_color"),    
//        		new VertexAttribute(Usage.TextureCoordinates, 2, "a_texcoord") );    
    }

    
    void allocate( int vertexCount )
    {
    	mPathVertexBuffer = null;
    	mBodyVertices = null;
        mBodyVertexBuffer = null;
        mBodyTexCoords = null;
        mBodyTexCoordBuffer = null;        
        mBodyColors = null;
        mBodyColorBuffer = null;        
        mBodyColorBuffer2 = null;        
    	mLegsVertexBuffer = null;
        mLegsVertices = null;  
        mLegsColorBuffer = null;
    	
        // Alloc vertex data memory
        
        if( USE_PATH_SKELETON ) mPathVertexBuffer = BufferUtils.createFloatBuffer( vertexCount*3 );
        
        mBodyVertices = new float[vertexCount*3*2];
        mBodyVertexBuffer = BufferUtils.createFloatBuffer( vertexCount*3*2 );
        mBodyTexCoords = new float[vertexCount*2*2];
        mBodyTexCoordBuffer = BufferUtils.createFloatBuffer( vertexCount*2*2 );        
        mBodyColors = new float[vertexCount*4*2];
        mBodyColorBuffer = BufferUtils.createFloatBuffer( vertexCount*4*2 );        
        mBodyColorBuffer2 = BufferUtils.createFloatBuffer( vertexCount*4*2 );        

        mLegsVertices = new float[vertexCount*4*3];    
        mLegsVertexBuffer = BufferUtils.createFloatBuffer( vertexCount*4*3 );
        mLegsColorBuffer = BufferUtils.createFloatBuffer( vertexCount*4*4 );
    }


    void addPoint( Vector3 p )
    {
        if( mIsLineClosed ) return;
        if( mLine.size() >= MAX_VERTICES ) {
        	//process( TailsListener.TESS_RESOLUTION );
        	return;
        }

        mPointList.add( p );

        // Line joint has position + current segment length.
        if( mLine.size() > 1 ) 
        {
            Vector3 dir = Vector3.sub( p, mLine.get(mLine.size()-1).mPoint );
            float distFromLast = dir.length();
            mLine.add( new LineJoint(p, distFromLast) );
        }
        else
        {
            mLine.add( new LineJoint(p, 1) );
        }
    }


    void setTexture( VTexture2D tex )
    {
        mTex = tex;
    }


    void step( VGL vgl, float time, float frameTime )
    {
    	// No less than 2 triangles, or a single segment snake
    	if( mIsDead ) return;
    	
        update( time, frameTime );
        repelHeadFromPath( mLineWidth*2 );
        //repelPathPoints( mLineWidth*0.75f );
        constraintToScreen();
        computeMesh( time );

        render( vgl );
    }


    void render( VGL vgl )
    {    	
		GL gl = vgl.gl();
		//renderPath( gl );
		renderBody( gl );
    }


    void renderPath( GL gl )
    {
		//
		// Render path
		//
    	gl.glPointSize( 2 );
		gl.glEnableClientState( GL_VERTEX_ARRAY );    
		gl.glColor4f( 1, 1, 1, 1 );
		gl.glVertexPointer( 3, GL_FLOAT, 0, mPathVertexBuffer );
		gl.glDrawArrays( GL_POINTS, 0, mLine.size() );		
		gl.glDisableClientState( GL_VERTEX_ARRAY );
    }
    
    
    void renderBody( GL gl )
    {		    	
    	// Render body vertices (points)
    	if( mIsLineClosed )
    	{
    		gl.glDisable( GL_TEXTURE_2D );
    		
    		// Draw body outline points only on sperms
			if( mLineType == 1 )
			{
		    	gl.glPointSize( 2 );
				gl.glEnableClientState( GL_VERTEX_ARRAY );    
				gl.glEnableClientState( GL_COLOR_ARRAY );    
				//gl.glColor4f( 1, 1, 1, 1 );
				gl.glVertexPointer( 3, GL_FLOAT, 0, mBodyVertexBuffer );
				gl.glColorPointer( 4, GL_FLOAT, 0, mBodyColorBuffer2 );
				gl.glDrawArrays( GL_POINTS, 0, (mLine.size()-1)*2 );		
				gl.glDisableClientState( GL_COLOR_ARRAY );
				gl.glDisableClientState( GL_VERTEX_ARRAY );
			}			

			// Draw legs only in case its a worm
			if( mIsAnimated && mLineType != 1 )
			{
		    	gl.glLineWidth( 2 );
				gl.glEnableClientState( GL_VERTEX_ARRAY );    
				gl.glEnableClientState( GL_COLOR_ARRAY );    
				//gl.glColor4f( 1, 1, 1, 1 );
				gl.glVertexPointer( 3, GL_FLOAT, 0, mLegsVertexBuffer );
				gl.glColorPointer( 4, GL_FLOAT, 0, mLegsColorBuffer );
				gl.glDrawArrays( GL_LINES, 0, mLegsVertexBuffer.capacity()/3 );		
				gl.glDisableClientState( GL_COLOR_ARRAY );
				gl.glDisableClientState( GL_VERTEX_ARRAY );    	
			}			
    	}    	
    	
    	//gl.glEnable( GL_COLOR_MATERIAL );
    	
    	// Render solid body with color
    	if( USE_TEXTURE ) gl.glEnable( GL_TEXTURE_2D );
    	
		gl.glEnableClientState( GL_VERTEX_ARRAY );    
		if( USE_TEXTURE ) gl.glEnableClientState( GL_TEXTURE_COORD_ARRAY );    
		gl.glEnableClientState( GL_COLOR_ARRAY );    
		gl.glColor4f( 1, 1, 1, 1 );
		//gl.glColor4f( 1, 0.72f, 0, 1 ); // yellow
		gl.glVertexPointer( 3, GL_FLOAT, 0, mBodyVertexBuffer );
		if( USE_TEXTURE ) gl.glTexCoordPointer( 2, GL_FLOAT, 0, mBodyTexCoordBuffer );
		gl.glColorPointer( 4, GL_FLOAT, 0, mBodyColorBuffer );
		gl.glDrawArrays( GL_TRIANGLE_STRIP, 0, (mLine.size()-1)*2 );		
		gl.glDisableClientState( GL_COLOR_ARRAY );
		if( USE_TEXTURE ) gl.glDisableClientState( GL_TEXTURE_COORD_ARRAY );    
		gl.glDisableClientState( GL_VERTEX_ARRAY );
    }

    
    void computeMesh( float time )
    {
        if( mLine.size() == 0 ) return;

        float per = 1.0f;
        float xOffset, yOffset;

        int index = 0;
        int texIndex = 0;
        int colorIndex = 0;
        int legsIndex = 0;
        int count = 0;
        int segCount = (int)MathUtils.clamp( mLine.size(), 0, MIN_DISTANCE ); 

        float oneOverSegCount = 1.0f / (float)segCount;
        float oneOverLineSize = 1.0f / (float)mLine.size();

        if( USE_PATH_SKELETON ) mPathVertexBuffer.clear();

        for( int i=0; i<mLine.size()-1; i++ )
        {
            LineJoint joint1 = mLine.get(i);
            LineJoint joint2 = mLine.get(i+1);


            // Save path buffer
            if( USE_PATH_SKELETON ) 
            {
	            mPathVertexBuffer.put( joint1.mPoint.x );
	            mPathVertexBuffer.put( joint1.mPoint.y );
	            mPathVertexBuffer.put( joint1.mPoint.z );
            }

            float per0 = (i * oneOverLineSize);
            
            per = 1;
            if( i <= segCount )
            {
                //per = (1.0f/(float)segCount) + (i / (float)segCount);
                per = Cubic.easeOut( (i * oneOverSegCount), 0, 1, 1 );
                //LOG( "HEAD: " + per );
            }
            else if( i >= ((mLine.size()-1)-segCount) )
            {
                int ss = ((mLine.size()-1)-segCount);
                //per = 1 - ((i-ss) / (float)segCount);
                per = Cubic.easeIn( ((i-ss) * oneOverSegCount), 1, 0, 1 );
                //LOG( "TAIL: " + per );
                //LOG( "TAIL: " + i + ", " + ((mLine.size())-segCount) + ", " + (i-ss) + ", " + ((i-ss) / (float)segCount) );
            }
            else
            {
                per = 1.0f;
            }
            per = MathUtils.clamp( per, 0, 1 );
            if( mIsLineClosed ) per *= mLineWidth;
            
            // Body animation
            if( mDoBodyAnimation )
            {
                if( mIsAnimated ) per *= 1 + Math.abs(Math.sin( 4*per0*(time-mAnimationStartTime) + mAccel*i*0.015f) ) * 0.5f;
            }

            Vector3 curr = joint1.mPoint;
            Vector3 next = joint2.mPoint;
            Vector3 dir = Vector3.sub( curr, next );
            dir.normalize();

            Vector3 V = Vector3.cross( dir, Vector3.Z_AXIS );
            V.normalize();

            /*if( mIsAnimated ) {
            	xOffset = V.x * curr.z;	// z is difference been last pos and curr pos
            	yOffset = V.y * curr.z;	// z is difference been last pos and curr pos
            }
            else*/
            {
            	xOffset = V.x * per;
            	yOffset = V.y * per;            	
            }

//            if( count == 0 ) vgl.gl().glTexCoord2f( 0, 0 );
//            else vgl.gl().glTexCoord2f( 0, 0 );
//            vgl.gl().glTexCoord2f( 0, 0 );
            mBodyVertices[index++] = curr.x-xOffset;
            mBodyVertices[index++] = curr.y-yOffset;
            mBodyVertices[index++] = 0;
//            if( count == 0 ) vgl.gl().glTexCoord2f( 1, 0 );
//            else vgl.gl().glTexCoord2f( 1, per0 );
//            vgl.gl().glTexCoord2f( 1, per0 );
            mBodyVertices[index++] = curr.x+xOffset;
            mBodyVertices[index++] = curr.y+yOffset;
            mBodyVertices[index++] = 0;
            
            if( USE_TEXTURE ) {
	            mBodyTexCoords[texIndex++] = 0;
	            mBodyTexCoords[texIndex++] = MathUtils.clamp( per0 - oneOverLineSize, 0, 1 );
	            mBodyTexCoords[texIndex++] = 1;
	            mBodyTexCoords[texIndex++] = per0;
            }
            
            mBodyColors[colorIndex++] = mColor.r;
            mBodyColors[colorIndex++] = mColor.g;
            mBodyColors[colorIndex++] = mColor.b;
            mBodyColors[colorIndex++] = mColor.a*mAlpha;
            mBodyColors[colorIndex++] = mColor.r;
            mBodyColors[colorIndex++] = mColor.g;
            mBodyColors[colorIndex++] = mColor.b;
            mBodyColors[colorIndex++] = mColor.a*mAlpha;
            
            mBodyColorBuffer2.put( 1 );        
            mBodyColorBuffer2.put( 1 );        
            mBodyColorBuffer2.put( 1 );        
            mBodyColorBuffer2.put( mColor.a*mAlpha );        
            mBodyColorBuffer2.put( 1 );        
            mBodyColorBuffer2.put( 1 );        
            mBodyColorBuffer2.put( 1 );        
            mBodyColorBuffer2.put( mColor.a*mAlpha );
            
            
            
            
            
            // Now generate the legs
            Vector3 leftLegJoint = new Vector3( curr.x-xOffset, curr.y-yOffset, 0 );
            Vector3 rightLegJoint = new Vector3( curr.x+xOffset, curr.y+yOffset, 0 );
            Vector3 leftLegEnd = new Vector3( curr.x-xOffset*LEG_SIZE, curr.y-yOffset*LEG_SIZE, 0 );
            Vector3 rightLegEnd = new Vector3( curr.x+xOffset*LEG_SIZE, curr.y+yOffset*LEG_SIZE, 0 );
            
//            Vector3 leftEndNorm = Vector3.sub( leftLegEnd, leftLegJoint );
//            leftEndNorm.normalize();
//            Vector3 rightEndNorm = Vector3.sub( rightLegEnd, rightLegJoint );
//            rightEndNorm.normalize();
//            
//            // Transform each leg end with origin in the joint
//            Matrix rot = new Matrix();
//            float angle = (float)Math.sin(time*3) * 30;	//* mSpeed * 0.4f;
//            rot.rotationAxis( leftEndNorm, (float)MathUtils.radians(angle) );
//            leftLegEnd = Vector3.transformNormal( leftLegEnd, rot );
//            rot.rotationAxis( rightEndNorm, (float)MathUtils.radians(-angle) );
//            rightLegEnd = Vector3.transform( rightLegEnd, rot );
            
            // Left leg line
            mLegsVertices[legsIndex++] = leftLegJoint.x;
            mLegsVertices[legsIndex++] = leftLegJoint.y;
            mLegsVertices[legsIndex++] = leftLegJoint.z;
            mLegsVertices[legsIndex++] = leftLegEnd.x;
            mLegsVertices[legsIndex++] = leftLegEnd.y;
            mLegsVertices[legsIndex++] = leftLegEnd.z;
            // Right leg line
            mLegsVertices[legsIndex++] = rightLegJoint.x;
            mLegsVertices[legsIndex++] = rightLegJoint.y;
            mLegsVertices[legsIndex++] = rightLegJoint.z;
            mLegsVertices[legsIndex++] = rightLegEnd.x;
            mLegsVertices[legsIndex++] = rightLegEnd.y;
            mLegsVertices[legsIndex++] = rightLegEnd.z;

            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 1*mAlpha );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 0 );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 1*mAlpha );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 1 );        
            mLegsColorBuffer.put( 0 );        
            
            count = (count+1) % 2;
        }

        //
        // fill last point
        //
        mBodyVertices[index++] = mBodyVertices[(mBodyVertices.length-1)-7*2];
        mBodyVertices[index++] = mBodyVertices[(mBodyVertices.length-1)-8*2];
        mBodyVertices[index++] = mBodyVertices[(mBodyVertices.length-1)-9*2];
        mBodyVertices[index++] = mBodyVertices[(mBodyVertices.length-1)-7*2];
        mBodyVertices[index++] = mBodyVertices[(mBodyVertices.length-1)-8*2];
        mBodyVertices[index++] = mBodyVertices[(mBodyVertices.length-1)-9*2];
        if( USE_TEXTURE ) {
	        mBodyTexCoords[texIndex++] = mBodyTexCoords[(mBodyTexCoords.length-1)-5*2];
	        mBodyTexCoords[texIndex++] = mBodyTexCoords[(mBodyTexCoords.length-1)-6*2];
	        mBodyTexCoords[texIndex++] = mBodyTexCoords[(mBodyTexCoords.length-1)-5*2];
	        mBodyTexCoords[texIndex++] = mBodyTexCoords[(mBodyTexCoords.length-1)-6*2];
        }
        mBodyColors[colorIndex++] = mColor.r;
        mBodyColors[colorIndex++] = mColor.g;
        mBodyColors[colorIndex++] = mColor.b;
        mBodyColors[colorIndex++] = mColor.a*mAlpha;
        mBodyColors[colorIndex++] = mColor.r;
        mBodyColors[colorIndex++] = mColor.g;
        mBodyColors[colorIndex++] = mColor.b;
        mBodyColors[colorIndex++] = mColor.a*mAlpha;
        mBodyColorBuffer2.put( 1 );        
        mBodyColorBuffer2.put( 1 );        
        mBodyColorBuffer2.put( 1 );        
        mBodyColorBuffer2.put( mColor.a*mAlpha );        
        mBodyColorBuffer2.put( 1 );        
        mBodyColorBuffer2.put( 1 );        
        mBodyColorBuffer2.put( 1 );        
        mBodyColorBuffer2.put( mColor.a*mAlpha );    

        // Path line buffer
        if( USE_PATH_SKELETON ) 
        {
        	mPathVertexBuffer.put( mLine.get(mLine.size()-1).mPoint.x );
            mPathVertexBuffer.put( mLine.get(mLine.size()-1).mPoint.y );
            mPathVertexBuffer.put( mLine.get(mLine.size()-1).mPoint.z );
            mPathVertexBuffer.position( 0 );
        }
        
        // Fill out ArrayBuffers
        mBodyVertexBuffer.clear();
        mBodyVertexBuffer.put( mBodyVertices );
        mBodyVertexBuffer.position( 0 );
        if( USE_TEXTURE ) {
        	mBodyTexCoordBuffer.clear();
        	mBodyTexCoordBuffer.put( mBodyTexCoords );
        	mBodyTexCoordBuffer.position( 0 );
        }
    	mBodyColorBuffer.clear();
    	mBodyColorBuffer.put( mBodyColors );
    	mBodyColorBuffer.position( 0 );
        
    	mBodyColorBuffer2.position( 0 );
    	
    	
    	mLegsVertexBuffer.clear();
    	mLegsVertexBuffer.put( mLegsVertices );
    	mLegsVertexBuffer.position( 0 );
    	
    	mLegsColorBuffer.position( 0 );    	
    }
    
    
    
    void update( float time, float frameTime )
    {
    	// If line is not closed, bail out.
    	// Our line only animates once its completed
        if( !mIsLineClosed ) return;

        // Animate line's width
        mLineCountTime += frameTime;
        mLineCountTime = MathUtils.clamp( mLineCountTime, 0, mLineAnimationTime );
        mLineWidth = 1+Elastic.easeOut( mLineCountTime/mLineAnimationTime, 0, mLineTargetWidth, 1 );
        
        // Delay time before animation mode
        mCountTime += frameTime;
        if( !mIsAnimated && (mCountTime < mAnimateTime) ) return;

        // Keep time we started our animation
        if( !mIsAnimated ) {
            mAnimationStartTime = time;
        }
        mIsAnimated = true;
        
        mAge = (time-mAnimationStartTime);
        mAgePer = mAge * mOneOverLifeTime;
        
        mAlpha = 1-(mAgePer*mAgePer);
        
        
        //
        // Animation physics
        //
        mAccel += frameTime;
        if( mAccel > 1.0 ) mAccel = 1.0f;

        mHead = mLine.get(0).mPoint;

        float speed = 10;
/**        
		mHeadAccel.set( mHeadDir );
        mHeadAccel.x += speed * (TailsListener.mNoise.noise( (float)(Math.cos(time*0.1f)*0.01f+(mHead.y+width*0.5f)*0.1f), 
        														mHead.y*0.1f) - 0.45f);
        mHeadAccel.y += speed * (TailsListener.mNoise.noise( (float)(Math.sin(time*0.1f)*0.01f+mHead.y*0.1f), 
        														(mHead.x*10+width*0.5f)*0.1f-(time)*0.1f ) - 0.5f);
        LOG( ""+mHeadAccel.x + ", " + mHeadAccel.y );
        mHeadVel.add( mHeadAccel );
        mHead.add( mHeadVel );

        mHeadVel.mul( 0.25f );
        mHeadAccel.reset();
***/        
        mHeadVel.x += speed * (noise( (float)(time*0.01f+mHead.x*0.1f), 
				mHead.y*0.1f) - 0.5f);
        mHeadVel.y += speed * (noise( (float)(time+mHead.y*0.51f), 
        							(mHead.x+width*0.5f)*0.1f-(time)*0.1f ) - 0.5f);
        mHead.add( mHeadVel );
        mHeadVel.mul( mDamping );
        mSpeed = mHeadVel.length();


        //
        // Update based on type
        //
        switch( mLineType )
        {
            case 0:
                updateMotionWorm();
                break;
            case 1:
            	updateMotionSperm();
                break;
        }
    }


    void reset()
    {
        mLine.clear();
    }    
    
    void changeLineType( int t )
    {
        mLineType = t;
    }
    
    void updateMotionWorm()
    {
    	// Update body. head is updated elsewhere
        for( int i=1; i<mLine.size(); i++ )
        {
            LineJoint joint2 = mLine.get( i );
            LineJoint joint1 = mLine.get( i-1 );
            Vector3 dir = Vector3.sub( joint2.mPoint, joint1.mPoint );
            float len = joint1.mLength;
            float invD = 1 / dir.length();
            joint2.mPoint.x = joint1.mPoint.x + (dir.x*len)*invD;
            joint2.mPoint.y = joint1.mPoint.y + (dir.y*len)*invD;
        }
    }
    
    

    void updateMotionSperm()
    {
    	// Update body. head is updated elsewhere
        for( int i=2; i<mLine.size(); i++ )
        {
            LineJoint joint2 = mLine.get( i );
            LineJoint joint1 = mLine.get( i-2 );
            Vector3 dir = Vector3.sub( joint2.mPoint, joint1.mPoint );
            float len = joint1.mLength;
            float invD = 1 / dir.length();
            joint2.mPoint.x = mLine.get( i-1 ).mPoint.x + (dir.x*len)*invD;
            joint2.mPoint.y = mLine.get( i-1 ).mPoint.y + (dir.y*len)*invD;
        }

        float ONEOVERWIDTH = 1.0f / (float)width;
        float ONEOVERHEIGHT = 1.0f / (float)height;
        float count = (float) (-((mHead.x*ONEOVERWIDTH)*2*Math.PI) + ((mHead.y*ONEOVERHEIGHT)*2*Math.PI)); 
        mLine.get(1).mPoint.set( mHead.x-(float)Math.sin(count*0.2)*0.5f, mHead.y-(float)Math.cos(count*0.3)*0.5f, mHead.z ); 
    }



    boolean process( int res )
    {
    	LOG( "entering process()" );
    	
    	// Forget lines very small
        if( mLine.size() < 3 ) {
        	// Set to die at birth
        	mLine.clear();
        	mPointList.clear();
        	mIsDead = true;
            mID = -1;
            mIsLineClosed = true;        	
        	LOG( "line is *not* valid. kill it" );
        	return false;
        }

    	LOG( "line is valid. continue processing" );
        mID = -1;
        mIsLineClosed = true;

        //optimize( MIN_DISTANCE );
        
        // Reserve array list   
        //Collections.reverse( mLine );
        
        // Tesselate our path line
        tesselate( res );
        
        // No longer need this
        mPointList.clear();
        mPointList = null;
        
        //optimize( MIN_DISTANCE );
        
        // Reserve array list   
        //Collections.reverse( mLine );
        
        // And now we need to resize our buffers to same amount as our new pathline
        allocate( mLine.size() );
                
        // Create buffer of path points
        if( USE_PATH_SKELETON )
        {
	        mPathVertexBuffer.clear();
	        for( LineJoint j : mLine )
	        {
	        	mPathVertexBuffer.put( j.mPoint.x );
	        	mPathVertexBuffer.put( j.mPoint.y );
	        	mPathVertexBuffer.put( j.mPoint.z );
	        }
	        mPathVertexBuffer.position( 0 );
        }        

        // First time compute mesh
        update( 0, 0 );
        computeMesh( 0 );
        
        //Log.i( "INFO*****", "Linesize: " + mLine.size() + " Tris: " + mLine.size()*2 + " Verts: " + mLine.size()*3*2 );
        
        
        // Now compute our line mesh
//        VertexAttribute pos = new VertexAttribute( 0, 3, "position" );
//        VertexAttributes desc = new VertexAttributes( pos );
//        mBodyMesh = new Mesh( false, MAXmPointList, MAXmPointList*2, desc );
//        mBodyMesh.setVertices( mBodyVertices );

        // Compute direction vector
        Vector3 p0 = mLine.get( mLine.size()-1 ).mPoint;
        Vector3 p1 = mLine.get( mLine.size()-2 ).mPoint;
        Vector3 dir = Vector3.sub( p1, p0 );
        //Vector3 dir = Vector3.sub( p0, p1 );
        mHeadDir.set( dir );
        
        
        // Compute new time to start animation based on body length
        //mLineAnimationTime = mLineAnimationTime + mLine.size()*0.01f;
        
        return mIsLineClosed;
    }

    
    void repelHeadFromPath( float desiredDistance )
    {
    	if( !mIsLineClosed ) return;
    	
    	//for( int j=0; j<mLine.size(); j++ )
    	{
	        LineJoint jointJ = mLine.get( 0 );
    	    for( int i=0; i<mLine.size(); i++ )
    	    {
    	        LineJoint jointI = mLine.get( i );
    	    	//if( i != j ) 
    	    	{
    	    		float A = 3.0f;
	    	        Vector3 d = Vector3.sub( jointI.mPoint, jointJ.mPoint );
	    	        double distanceSqr = ( d.x*d.x + d.y*d.y + d.z*d.z);
	    	        double distance = Math.sqrt( distanceSqr );
	    	        double invd = 1.0f;
	    	        if( distance > 0.0f ) invd = (1.0 / distance);

	    	        if( distance <= desiredDistance ) 
	    	        {
	    	            jointI.mPoint.x += d.x * invd * A;
	    	            jointI.mPoint.y += d.y * invd * A;
	    	            //joint1.mPoint.z -= d.z * invd;     	        	
	    	            jointJ.mPoint.x -= d.x * invd * A;
	    	            jointJ.mPoint.y -= d.y * invd * A;
	    	            //joint2.mPoint.z += d.z * invd;    
	    	        }
    	    	}
    	    }
    	}
    }

    
    void repelPathPoints( float desiredDistance )
    {
    	if( !mIsLineClosed ) return;
    	
    	for( int j=0; j<mLine.size(); j++ )
    	{
	        LineJoint jointJ = mLine.get( j );
    	    for( int i=0; i<mLine.size(); i++ )
    	    {
    	        LineJoint jointI = mLine.get( i );
    	    	if( i != j ) 
    	    	{
    	    		float A = 3.0f;
	    	        Vector3 d = Vector3.sub( jointI.mPoint, jointJ.mPoint );
	    	        double distanceSqr = ( d.x*d.x + d.y*d.y + d.z*d.z);
	    	        double distance = Math.sqrt( distanceSqr );
	    	        double invd = 1.0f;
	    	        if( distance > 0.0f ) invd = (1.0 / distance);

	    	        if( distance <= desiredDistance ) 
	    	        {
	    	            jointI.mPoint.x += d.x * invd * A;
	    	            jointI.mPoint.y += d.y * invd * A;
	    	            //joint1.mPoint.z -= d.z * invd;     	        	
	    	            jointJ.mPoint.x -= d.x * invd * A;
	    	            jointJ.mPoint.y -= d.y * invd * A;
	    	            //joint2.mPoint.z += d.z * invd;    
	    	        }
    	    	}
    	    }
    	}
    }

    
    void optimize( float minimumDist )
    {
        for( int i=0; i<mLine.size()-1; i++ )
        {    	
        	LineJoint l0 = mLine.get( i );
        	LineJoint l1 = mLine.get( i+1 );
        	Vector3 dir = Vector3.sub( l0.mPoint, l1.mPoint );
        	float len = dir.length();
        	if( len < minimumDist )
        	{
        		mLine.remove( l0 );
        	}
        }
    }

    void tesselate( int res )
    {
        mSpline = new Spline3D( mPointList );
        ArrayList<Vector3> newPoints = mSpline.computeVertices( res );
        mLine.clear();
        for( Vector3 p : newPoints )
        {
            if( mLine.size() > 2 ) 
            {
                Vector3 dir = Vector3.sub( p, mLine.get(mLine.size()-1).mPoint );
                float distFromLast = dir.length();
                mLine.add( new LineJoint(p, distFromLast) );
            }
            else
            {
                mLine.add( new LineJoint(p, MIN_DISTANCE) );
            }
        }
        
        LOG( "BEFORE compute even: " + mLine.size() );
        computeEvenSpline( newPoints, MIN_DISTANCE );
        LOG( "AFTER compute even: " + mLine.size() );
                
        newPoints.clear();
        newPoints = null;
        
        mSpline.release();
        mSpline = null;
    }
    
    
    void computeEvenSpline( ArrayList<Vector3> points, float wantedDistance )
    {
      /*
        Brief description of the code:
       1) The 3rd parameter is wantedDistance which is the distance between two nodes.
       2) You can see the const DIVISOR - it is just to increase the accuracy of the distance because the algo I tried is this:-
       a) fineGrainDistance = wantedDistance/DIVISOR
       b) Calculate the actual point (Vector3) on the Spline where the distance = fineGrainDistance
       c) Do this for DIVISOR times.. you get the actual node which has distance 'wantedDistance'
       d) Repeat until reach the end of spline.
       
       So if your spline is curvy (lots of sharp bends) and the desired distance between node is big, set DIVISOR to big value.  
      */
      
      if( wantedDistance < 1 )
      {
          LOG( "Pick a bigger value" );
          return;
      }
    
      float lastLerpPoint = 0.0f;
      int DIVISOR = 1;
      float fineGrainDistance = wantedDistance / (float)DIVISOR;
      Vector3 end = new Vector3();
    
      int k = 0;
      float accLength, prevAccLength;
      Vector3 start = new Vector3( points.get(0).x, points.get(0).y, 0 );
    
      // Add first control points  
//      splinePoints.add( start );    
      //_evenPointsPath.add( new LineJoint(start, 0) );
      mLine.clear();
      mLine.add( new LineJoint(start, 0) );
    
      for( int i=1; i<points.size(); i++ )
      {
    	  end = new Vector3( points.get(i).x, points.get(i).y, 0 );
	        prevAccLength = 0.0f;
	        Vector3 tmp = Vector3.sub(end, start);
	        accLength = (float) Math.sqrt( tmp.x*tmp.x + tmp.y*tmp.y );
	    
	        while( accLength < fineGrainDistance && i < points.size()-1 ) 
	        {
	          // okay 'end' is extended
	          i++;
	          end = new Vector3( points.get(i).x, points.get(i).y, 0 );
	          prevAccLength = accLength;
	
	
	///          accLength += Vector3.sub(end, points[i-1]).length();
	          tmp = Vector3.sub( end, points.get(i-1) );
	          accLength += Math.sqrt( tmp.x*tmp.x + tmp.y*tmp.y );
	
	          // if enter the loops then we have to reset lastInterPoint..
	          lastLerpPoint = 0.0f;       
	        }
	    
	        if( i == points.size()-1 )
	          break;
	    
	        //refPoint = splineSrc.getPoint(j-1)+lastInterpPoint*(splineSrc.getPoint(j)-splineSrc.getPoint(j-1));
	        Vector3 refPoint = new Vector3( points.get(i-1).x, points.get(i-1).y, 0 );
	        Vector3 deltaVec = Vector3.sub( points.get(i), points.get(i-1) );
	        deltaVec.mul( lastLerpPoint );
	        refPoint.add( deltaVec );
	    
	//        float distanceAll = Vector3.distance( points[i], points[i-1] );
	        tmp = Vector3.sub( points.get(i), points.get(i-1) );
	        float distanceAll = (float) Math.sqrt( tmp.x*tmp.x + tmp.y*tmp.y );
	    
	        //Real wantedSubDistance = fineGrainDistance -prevAccLength;
	        float wantedSubDistance = fineGrainDistance - prevAccLength;
	    
	        //lastInterpPoint += wantedSubDistance/distanceAll;
	        lastLerpPoint += wantedSubDistance / distanceAll;
	    
	        //start = splineSrc.getPoint(j-1)+lastInterpPoint*(splineSrc.getPoint(j)-splineSrc.getPoint(j-1));
	        start = new Vector3( points.get(i-1).x, points.get(i-1).y, 0 );
	        deltaVec = Vector3.sub( points.get(i), points.get(i-1) );
	        deltaVec.mul( lastLerpPoint );
	        start.add( deltaVec );
	    
	        k++;
	    
	        if( (k % DIVISOR) == 0 )
	        {
	            Vector3 dir = Vector3.sub( start, mLine.get(mLine.size()-1).mPoint );
	            float distFromLast = dir.length();	        	
	            mLine.add( new LineJoint(start, distFromLast) );
	        	
//	            Vector3 dir = Vector3.sub( start, _evenPointsPath.size(_evenPointsPath.size()-1).mPoint );
//	            float distFromLast = dir.length();	        	
//	            _evenPointsPath.add( new LineJoint(start, distFromLast) );
	        }
      	}
      
      	// Add last control point
      	mLine.add( new LineJoint( mLine.get(mLine.size()-1).mPoint.copy(), mLine.get(mLine.size()-1).mLength) );
      	//_evenPointsPath.add( _evenPointsPath.get(_evenPointsPath.size()-1) );
      	//LOG( "EvenPointsPath Size: " + mLine.size() );
    }  
    

    boolean isDead()
    {
        if( !mIsAnimated ) return false;

        if( mIsDead ) return true;
        
        if( mAge > mLifeTime ) {
        	mIsDead = true;
        	return true;
        }

        // Count number of points visible.   
        int count = mLine.size()-1;
        for( LineJoint l : mLine )
        {
            Vector3 p = l.mPoint;
            if( p.x > (0+mLineWidth) && 
                p.x < (width-mLineWidth) &&
                p.y > (0+mLineWidth) &&
                p.y < (height-mLineWidth) )
            {
                count--;
            }
        }
        // if all points visible return false, else set for removal
        if( count == mLine.size()-1 ) {
        	mIsDead = true;
        	return true;
        }
        return false;
    }

    
    void constraintToScreen()
    {
    	if( !mIsAnimated ) return;

    	//mHead = mLine.get(0).mPoint;
    	//LOG( ""+width );
    	if( mHead.x <= 0 ) mHead.x = 0;
    	if( mHead.x >= width ) mHead.y = width;
    	if( mHead.y <= 0 ) mHead.y = 0;
    	if( mHead.y >= height ) mHead.y = height;
    }
    
    int getVertexCount()
    {
    	return mLine.size()*2;
    }




    //
    // Members
    //
    int 				mID;
    
    float 				mCountTime;
    float 				mAnimateTime;
    float 				mAnimationStartTime;   

    boolean				mIsDead;
    boolean 			mIsAnimated;
    boolean 			mIsLineClosed;
    boolean 			mDoBodyAnimation;

    int 				mLineType;

    Vector3 			mHead;
    Vector3 			mHeadVel;
    Vector3 			mHeadAccel;
    Vector3 			mHeadDir;
    float 				mAccel;
    float				mSpeed;
    float				mDamping;
 
    VTexture2D 			mTex;
 
    Spline3D 			mSpline;
    
    float				mLineCountTime, mLineAnimationTime;
    float 				mLineWidth;
    float				mLineTargetWidth;
    
    ArrayList<Vector3> 	mPointList;
    ArrayList<LineJoint> mLine;
    
    Color4				mColor;
    float				mAlpha;
    
    float				mAge;
    float				mAgePer;
    float				mLifeTime;
    float				mOneOverLifeTime;
    
    //Mesh				mBodyMesh;
    
	FloatBuffer			mPathVertexBuffer;
    
	FloatBuffer			mBodyVertexBuffer;
	FloatBuffer			mBodyTexCoordBuffer;
	FloatBuffer			mBodyColorBuffer;
	FloatBuffer			mBodyColorBuffer2;
    float[]				mBodyVertices;
    float[]				mBodyTexCoords;
    float[]				mBodyColors;

    // Legs
	FloatBuffer			mLegsVertexBuffer;
	FloatBuffer			mLegsColorBuffer;
    float[]				mLegsVertices;    
}
