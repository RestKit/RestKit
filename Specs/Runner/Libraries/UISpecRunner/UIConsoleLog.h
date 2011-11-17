
#import "UILog.h"

@interface UIConsoleLog : NSObject <UILog> {
	NSDate *start;
	NSMutableArray *errors;
	NSString *currentExample;
	NSString *currentSpec;
    
    BOOL _exitOnFinish;
}

// When YES, the application will terminate after specs finish running
@property (nonatomic, assign) BOOL exitOnFinish;

@end
