import vitamin.math.Vector3;

class LineJoint
{
    public LineJoint( Vector3 point, float length )
    {
        mPoint = point.copy();
        mLength = length;
    }
    
    public void setPosition( float x, float y )
    {
        mPoint.x = x;
        mPoint.y = y;
    }
    public void setLength( float length )
    {
        mLength = length;
    }
    
        
    
    Vector3 mPoint;
    float mLength;
}
