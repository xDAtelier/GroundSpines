boolean tuioOn = false;


// these callback methods are called whenever a TUIO event occurs

// called when an object is added to the scene
void addTuioObject(TuioObject tobj) {}

// called when an object is removed from the scene
void removeTuioObject(TuioObject tobj) {}

// called when an object is moved
void updateTuioObject (TuioObject tobj) {}






// called when a cursor is added to the scene
void addTuioCursor(TuioCursor tcur) 
{
  //println("add cursor "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY());
  tuioOn = true;
  println( tuioOn );
  clickTime = time;  
  if( rootRib != null ) rootRib.reset( new Vector3(xPos, yPos, 0), 100000 );


if( mCurrEffect == WORMS )
{
		if( mCurrLinha < MAX_LINES )
		{
			//mLinhas.add( new Linha( pointer, new Color4(1, 0.72f, 0, 1), 2) );
			int rnd = (int)MathUtils.random(0, colors.length-1);
			mLinhas.add( new Linha( tcur.getCursorID(), colors[rnd], 1+MathUtils.random(10)) );
			mIsNewLine = true;
			mCurrLinha++;
		}
}
}


// called when a cursor is moved
void updateTuioCursor (TuioCursor tcur) 
{
  yPos = HEIGHT - (tcur.getX() * WIDTH);
  xPos = WIDTH - (tcur.getY() * HEIGHT);
//  println("update cursor "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY()
//          +" "+tcur.getMotionSpeed()+" "+tcur.getMotionAccel());
          
          
if( mCurrEffect == WORMS )
{
		// If max vertices reached, close down line.
		if( mTotalVertices > MAX_VERTICES ) 
		{
            for( Linha l : mLinhas )
            {
                if( l.mID == tcur.getCursorID() )
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
			return;
		}

        for( Linha l : mLinhas )
        {
            if( l.mID == tcur.getCursorID() )
            {
                l.addPoint( new Vector3(xPos, yPos, tcur.getMotionSpeed()) );
            }
        } 
}
}


// called when a cursor is removed from the scene
void removeTuioCursor(TuioCursor tcur) 
{
//  println("remove cursor "+tcur.getCursorID()+" ("+tcur.getSessionID()+")");
  tuioOn = false;
 // println( tuioOn );
 
if( mCurrEffect == WORMS )
{
        if( mLinhas.size() > 0 )
        {
            for( Linha l : mLinhas )
            {
                if( l.mID == tcur.getCursorID() )
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

   oldXPos = xPos;
   oldYPos = yPos;
}



// called after each message bundle
// representing the end of an image frame
void refresh(TuioTime bundleTime) 
{ 
//  redraw();
}
