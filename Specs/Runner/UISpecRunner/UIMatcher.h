
@protocol UIMatcher

-(BOOL)matches:(const void *)value objCType:(const char *)typeDescription;

@end


@interface UIMatcher : NSObject <UIMatcher>{
	id expectedValue;
	const char * expectedTypeDescription;
	SEL matchSelector;
	NSString *errorMessage;
}

@property(nonatomic, retain) NSString *errorMessage;

-(id)initWithValue:(const void *)aValue objCType:(const char *)aTypeDescription matchSelector:(SEL)aMatchSelector;
-(BOOL)matches:(id)value;
-(BOOL)be:(id)value;

+(id)withValue:(const void *)aValue objCType:(const char *)aTypeDescription matchSelector:(SEL)aMatchSelector;
+(NSString *)valueAsString:(const void *)value objCType:(const char *)typeDescription;

@end
