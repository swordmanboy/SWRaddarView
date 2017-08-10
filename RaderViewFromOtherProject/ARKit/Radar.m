//
//  Radar.m
//  ARKitDemo
//
//  Created by Ed Rackham (a1phanumeric) 2013
//  Based on mixare's implementation.
//

#import "Radar.h"

@implementation Radar{
    float _range;
}

@synthesize pois    = _pois;
@synthesize radius  = _radius;          //Km

- (id)initWithFrame:(CGRect)frame{
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor    = [UIColor clearColor];
        _radarBackgroundColour  = [UIColor colorWithRed:14.0/255.0 green:140.0/255.0 blue:14.0/255.0 alpha:0.2];
        _pointColour            = [UIColor whiteColor];
    }
    return self;
}


- (void)drawRect:(CGRect)rect{
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(contextRef, _radarBackgroundColour.CGColor);
    
    // Draw a radar and the view port 
//    CGContextFillEllipseInRect(contextRef, CGRectMake(0.5, 0.5, rect.size.width, rect.size.width));
//    CGContextSetRGBStrokeColor(contextRef, 0, 255, 0, 0.5);
    
    UIImage *brushImage = [UIImage imageNamed:@"ic_radar"];
    [brushImage drawInRect:(CGRectMake(0, 0, [self frame].size.width, [self frame].size.height))];

    
    _range = _radius;
    float scale = _range / rect.size.width;
    float radiusCircle = 0.0;
    
    if (_pois != nil) {
        for (ARGeoCoordinate *poi in _pois) {
            float x, y;
            //case1: azimiut is in the 1 quadrant of the radar
            NSLog(@"azimuth %f",poi.azimuth);
            NSLog(@"radius %f",scale);
            if (poi.azimuth >= 0 && poi.azimuth < M_PI / 2) {
                NSLog(@"type 1");
                x = radiusCircle + cosf((M_PI / 2) - poi.azimuth) * (poi.radialDistance / scale);
                y = radiusCircle - sinf((M_PI / 2) - poi.azimuth) * (poi.radialDistance / scale);
            } else if (poi.azimuth > M_PI / 2 && poi.azimuth < M_PI) {
                //case2: azimiut is in the 2 quadrant of the radar
                NSLog(@"type 2");
                x = radiusCircle + cosf(poi.azimuth - (M_PI / 2)) * (poi.radialDistance / scale);
                y = radiusCircle + sinf(poi.azimuth - (M_PI / 2)) * (poi.radialDistance / scale);
            } else if (poi.azimuth > M_PI && poi.azimuth < (3 * M_PI / 2)) {
                //case3: azimiut is in the 3 quadrant of the radar
                NSLog(@"type 3");
                x = radiusCircle - cosf((3 * M_PI / 2) - poi.azimuth) * (poi.radialDistance / scale);
                y = radiusCircle + sinf((3 * M_PI / 2) - poi.azimuth) * (poi.radialDistance / scale);
            } else if(poi.azimuth > (3 * M_PI / 2) && poi.azimuth < (2 * M_PI)) {
                //case4: azimiut is in the 4 quadrant of the radar
                NSLog(@"type 4");
                x = radiusCircle - cosf(poi.azimuth - (3 * M_PI / 2)) * (poi.radialDistance / scale);
                y = radiusCircle - sinf(poi.azimuth - (3 * M_PI / 2)) * (poi.radialDistance / scale);
            } else if (poi.azimuth == 0) {
                NSLog(@"type 5");
                x = radiusCircle;
                y = radiusCircle - poi.radialDistance / scale;
            } else if(poi.azimuth == M_PI/2) {
                x = radiusCircle + poi.radialDistance / scale;
                y = radiusCircle;
                NSLog(@"type 6");
            } else if(poi.azimuth == (3 * M_PI / 2)) {
                x = radiusCircle;
                y = radiusCircle + poi.radialDistance / scale;
                NSLog(@"type 7");
            } else if (poi.azimuth == (3 * M_PI / 2)) {
                x = radiusCircle - poi.radialDistance / scale;
                y = radiusCircle;
                NSLog(@"type 8");
            } else {
                //If none of the above match we use the scenario where azimuth is 0
                x = radiusCircle;
                y = radiusCircle - poi.radialDistance / scale;
            }
            

            
            //drawing the radar point
            CGContextSetFillColorWithColor(contextRef, _pointColour.CGColor);
//            if (x <= radiusCircle * 2 && x >= 0 && y >= 0 && y <= radiusCircle * 2) {
                NSLog(@"x is %f, y is %f",x,y);
                CGContextFillEllipseInRect(contextRef, CGRectMake(x + rect.size.width / 2.0,y + rect.size.width / 2.0, 5, 5));
//            }
            

        }
    }
}
@end


