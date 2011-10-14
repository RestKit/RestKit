# JSONKit Changelog

## Version 1.X ????/??/??

**IMPORTANT:** The following changelog notes are a work in progress.  They apply to the work done on JSONKit post v1.4.  Since JSONKit itself is inbetween versions, these changelog notes are subject to change, may be wrong, and just about everything else you could expect at this point in development.

### New Features

*    When `JKSerializeOptionPretty` is enabled, JSONKit now sorts the keys.

*    Normally, JSONKit can only serialize NSNull, NSNumber, NSString, NSArray, and NSDictioonary like objects.  It is now possible to serialize an object of any class via either a delegate or a `^` block.
    
    The delegate or `^` block must return an object that can be serialized by JSONKit, however, otherwise JSONKit will fail to serialize the object.  In other words, JSONKit tries to serialize an unsupported class of the object just once, and if the delegate or ^block returns another unsupported class, the second attempt to serialize will fail.  In practice, this is not a problem at all, but it does prevent endless recursive attempts to serialize an unsupported class.
    
    This makes it trivial to serialize objects like NSDate or NSData.  A NSDate object can be formatted using a NSDateFormatter to return a ISO-8601 `YYYY-MM-DDTHH:MM:SS.sssZ` type object, for example.  Or a NSData object could be Base64 encoded.

    This greatly simplifies things when you have a complex, nested objects with objects that do not belong to the classes that JSONKit can serialize.

    It should be noted that the same caching that JSONKit does for the supported class types also applies to the objects of an unsupported class- if the same object is serialized more than once and the object is still in the serialization cache, JSONKit will copy the previous serialization result instead of invoking the delegate or `^` block again.  Therefore, you should not expect or depend on your delegate or block being called each time the same object needs to be serialized AND the delegate or block MUST return a "formatted object" that is STRICTLY invariant (that is to say the same object must always return the exact same formatted output).
    
    To serialize NSArray or NSDictionary objects using a delegate&ndash;
    
    **NOTE:** The delegate is based a single argument, the object with the unsupported class, and the supplied `selector` method must be one that accepts a single `id` type argument (i.e., `formatObject:`).  
    **IMPORTANT:** The `^` block MUST return an object with a class that can be serialized by JSONKit, otherwise the serialization will fail.
    
    <pre>
    &#x200b;- (NSData \*)JSONDataWithOptions:(JKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingDelegate:(id)delegate selector:(SEL)selector error:(NSError \*\*)error;
    &#x200b;- (NSString \*)JSONStringWithOptions:(JKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingDelegate:(id)delegate selector:(SEL)selector error:(NSError \*\*)error;
    </pre>
    
    To serialize NSArray or NSDictionary objects using a `^` block&ndash;
    
    **NOTE:** The block is passed a single argument, the object with the unsupported class.  
    **IMPORTANT:** The `^` block MUST return an object with a class that can be serialized by JSONKit, otherwise the serialization will fail.
    
    <pre>
    &#x200b;- (NSData \*)JSONDataWithOptions:(JKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingBlock:(id(&#x005E;)(id object))block error:(NSError \*\*)error;
    &#x200b;- (NSString \*)JSONStringWithOptions:(JKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingBlock:(id(&#x005E;)(id object))block error:(NSError \*\*)error;
    </pre>
    
    Example using the delegate way:
    
    <pre>
    @interface MYFormatter : NSObject {
      NSDateFormatter \*outputFormatter;
    }
    @end
    &#x200b;
    @implementation MYFormatter
    -(id)init
    {
      if((self = [super init]) == NULL) { return(NULL); }
      if((outputFormatter = [[NSDateFormatter alloc] init]) == NULL) { [self autorelease]; return(NULL); }
      [outputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZ"];
      return(self);
    }
    &#x200b;
    -(void)dealloc
    {
      if(outputFormatter != NULL) { [outputFormatter release]; outputFormatter = NULL; }
      [super dealloc];
    }
    &#x200b;
    -(id)formatObject:(id)object
    {
      if([object isKindOfClass:[NSDate class]]) { return([outputFormatter stringFromDate:object]); }
      return(NULL);
    }
    @end
    &#x200b;
    {
      MYFormatter \*myFormatter = [[[MYFormatter alloc] init] autorelease];
      NSArray \*array = [NSArray arrayWithObject:[NSDate dateWithTimeIntervalSinceNow:0.0]];

      NSString \*jsonString = NULL;
      jsonString = [array                    JSONStringWithOptions:JKSerializeOptionNone
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;serializeUnsupportedClassesUsingDelegate:myFormatter
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;selector:@selector(formatObject:)
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;error:NULL];
      NSLog(@"jsonString: '%@'", jsonString);
      // 2011-03-25 11:42:16.175 formatter_example[59120:903] jsonString: '["2011-03-25T11:42:16.175-0400"]'
    }
    </pre>
    
    Example using the `^` block way:
    
    <pre>
    {
      NSDateFormatter \*outputFormatter = [[[NSDateFormatter alloc] init] autorelease];
      [outputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZ"];
      &#x200b;
      jsonString = [array                 JSONStringWithOptions:encodeOptions
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;serializeUnsupportedClassesUsingBlock:&#x005E;id(id object) {
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if([object isKindOfClass:[NSDate class]]) { return([outputFormatter stringFromDate:object]); }
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return(NULL);
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;error:NULL];
      NSLog(@"jsonString: '%@'", jsonString);
      // 2011-03-25 11:49:56.434 json_parse[59167:903] jsonString: '["2011-03-25T11:49:56.434-0400"]'
    }
    </pre>

### Major Changes

*   The way that JSONKit implements the collection classes was modified.  Specifically, JSONKit now follows the same strategy that the Cocoa collection classes use, which is to have a single subclass of the mutable collection class.  This concrete subclass has an ivar bit that determines whether or not that instance is mutable, and when an immutable instance receives a mutating message, it throws an exception.

## Version 1.4 2011/23/03

### Highlights

*   JSONKit v1.4 significantly improves the performance of serializing and deserializing.  Deserializing is 23% faster than Apples binary `.plist`, and an amazing 549% faster than Apples binary `.plist` when serializing.

### New Features

*   JSONKit can now return mutable collection classes.
*   The `JKSerializeOptionFlags` option `JKSerializeOptionPretty` was implemented.
*   It is now possible to serialize a single [`NSString`][NSString].  This functionality was requested in issue #4 and issue #11.

### Deprecated Methods

*   The following `JSONDecoder` methods are deprecated beginning with JSONKit v1.4 and will be removed in a later release&ndash;
    
    <pre>
    &#x200b;- (id)parseUTF8String:(const unsigned char \*)string length:(size_t)length;
    &#x200b;- (id)parseUTF8String:(const unsigned char \*)string length:(size_t)length error:(NSError \*\*)error;
    &#x200b;- (id)parseJSONData:(NSData \*)jsonData;
    &#x200b;- (id)parseJSONData:(NSData \*)jsonData error:(NSError \*\*)error;
    </pre>
    
    The JSONKit v1.4 <code>objectWith&hellip;</code> methods should be used instead.

### NEW API's

*   The following methods were added to `JSONDecoder`&ndash;
    
    These methods replace their deprecated <code>parse&hellip;</code> counterparts and return immutable collection objects.
    
    <pre>
    &#x200b;- (id)objectWithUTF8String:(const unsigned char \*)string length:(NSUInteger)length;
    &#x200b;- (id)objectWithUTF8String:(const unsigned char \*)string length:(NSUInteger)length error:(NSError \*\*)error;
    &#x200b;- (id)objectWithData:(NSData \*)jsonData;
    &#x200b;- (id)objectWithData:(NSData \*)jsonData error:(NSError \*\*)error;
    </pre>
    
    These methods are the same as their <code>objectWith&hellip;</code> counterparts except they return mutable collection objects.
    
    <pre>
    &#x200b;- (id)mutableObjectWithUTF8String:(const unsigned char \*)string length:(NSUInteger)length;
    &#x200b;- (id)mutableObjectWithUTF8String:(const unsigned char \*)string length:(NSUInteger)length error:(NSError \*\*)error;
    &#x200b;- (id)mutableObjectWithData:(NSData \*)jsonData;
    &#x200b;- (id)mutableObjectWithData:(NSData \*)jsonData error:(NSError \*\*)error;
    </pre>

*   The following methods were added to `NSString (JSONKitDeserializing)`&ndash;
    
    These methods are the same as their <code>objectFrom&hellip;</code> counterparts except they return mutable collection objects.
    
    <pre>
    &#x200b;- (id)mutableObjectFromJSONString;
    &#x200b;- (id)mutableObjectFromJSONStringWithParseOptions:(JKParseOptionFlags)parseOptionFlags;
    &#x200b;- (id)mutableObjectFromJSONStringWithParseOptions:(JKParseOptionFlags)parseOptionFlags error:(NSError \*\*)error;
    </pre>

*   The following methods were added to `NSData (JSONKitDeserializing)`&ndash;
    
    These methods are the same as their <code>objectFrom&hellip;</code> counterparts except they return mutable collection objects.
    
    <pre>
    &#x200b;- (id)mutableObjectFromJSONData;
    &#x200b;- (id)mutableObjectFromJSONDataWithParseOptions:(JKParseOptionFlags)parseOptionFlags;
    &#x200b;- (id)mutableObjectFromJSONDataWithParseOptions:(JKParseOptionFlags)parseOptionFlags error:(NSError \*\*)error;
    </pre>

*   The following methods were added to `NSString (JSONKitSerializing)`&ndash;
    
    These methods are for those uses that need to serialize a single [`NSString`][NSString]&ndash;
    
    <pre>
    &#x200b;- (NSData \*)JSONData;
    &#x200b;- (NSData \*)JSONDataWithOptions:(JKSerializeOptionFlags)serializeOptions includeQuotes:(BOOL)includeQuotes error:(NSError \*\*)error;
    &#x200b;- (NSString \*)JSONString;
    &#x200b;- (NSString \*)JSONStringWithOptions:(JKSerializeOptionFlags)serializeOptions includeQuotes:(BOOL)includeQuotes error:(NSError \*\*)error;
    </pre>
    
### Bug Fixes

*   JSONKit has a fast and a slow path for parsing JSON Strings.  The slow path is needed whenever special string processing is required, such as the conversion of `\` escape sequences or ill-formed UTF-8.  Although the slow path had a check for characters < `0x20`, which are not permitted by the [RFC 4627][], there was a bug such that the condition was never actually checked.  As a result, JSONKit would have incorrectly accepted JSON that contained characters < `0x20` if it was using the slow path to process a JSON String.
*   The low surrogate in a <code>\u<i><b>high</b></i>\u<i><b>low</b></i></code> escape sequence in a JSON String was incorrectly treating `dfff` as ill-formed Unicode.  This was due to a comparison that used `>= 0xdfff` instead of `> 0xdfff` as it should have.
*   `JKParseOptionLooseUnicode` was not properly honored when parsing some types of ill-formed Unicode in <code>\u<i><b>HHHH</b></i></code> escapes in JSON Strings.

### Important Notes
    
*   JSONKit v1.4 now uses custom concrete subclasses of [`NSArray`][NSArray], [`NSMutableArray`][NSMutableArray], [`NSDictionary`][NSDictionary], and [`NSMutableDictionary`][NSMutableDictionary]&mdash; `JKArray`, `JKMutableArray`, `JKDictionary`, and `JKMutableDictionary`. respectively.  These classes are internal and private to JSONKit, you should not instantiate objects from these classes directly.

    In theory, these custom classes should behave exactly the same as the respective Foundation / Cocoa counterparts.
    
    As usual, in practice may have non-linear excursions from what theory predicts.  It is also virtually impossible to properly test or predict how these custom classes will interact with software in the wild.
    
    Most likely, if you do encounter a problem, it will happen very quickly, and you should report a bug via the [github.com JSONKit Issue Tracker][bugtracker].
    
    In addition to the required class cluster primitive methods, the custom collection classes also include support for [`NSFastEnumeration`][NSFastEnumeration], along with methods that support the bulk retrieval of the objects contents.
    
    #### Exceptions Thrown
    
    The JSONKit collection classes will throw the same exceptions for the same conditions as their respective Foundation counterparts.  If you find a discrepancy, please report a bug via the [github.com JSONKit Issue Tracker][bugtracker].
    
    #### Multithreading Safety
    
    The same multithreading rules and caveats for the Foundation collection classes apply to the JSONKit collection classes.  Specifically, it should be safe to use the immutable collections from multiple threads concurrently.
    
    The mutable collections can be used from multiple threads as long as you provide some form of mutex barrier that ensures that if a thread needs to mutate the collection, then it has exclusive access to the collection&ndash; no other thread can be reading from or writing to the collection until the mutating thread has finished.  Failure to ensure that there are no other threads reading or writing from the mutable collection when a thread mutates the collection will result in `undefined` behavior.
    
    #### Mutable Collection Notes
    
    The mutable versions of the collection classes are meant to be used when you need to make minor modifications to the collection.  Neither `JKMutableArray` or `JKMutableDictionary` have been optimized for nor are they intended to be used in situations where you are adding a large number of objects or new keys&ndash; these types of operations will cause both classes to frequently reallocate the memory used to hold the objects in the collection.
    
    #### `JKMutableArray` Usage Notes
    
    * You should minimize the number of new objects you added to the array.  The array is not designed for high performance insertion and removal of objects.  If the array does not have any extra capacity it must reallocate the backing store.  When the array is forced to grow the backing store, it currently adds an additional 16 slots worth of spare capacity.  The array is instantiated without any extra capacity on the assumption that dictionaries are going to be mutated more than arrays.  The array never shrinks the backing store.
    
    * Replacing objects in the array via [`-replaceObjectAtIndex:withObject:`][-replaceObjectAtIndex:withObject:] is very fast since the array simply releases the current object at the index and replaces it with the new object.
    
    * Inserting an object in to the array via [`-insertObject:atIndex:`][-insertObject:atIndex:] cause the array to [`memmove()`][memmove] all the objects up one slot from the insertion index.  This means this operation is fastest when inserting objects at the last index since no objects need to be moved.
    
    * Removing an object from the array via [`-removeObjectAtIndex:`][-removeObjectAtIndex:] causes the array to [`memmove()`][memmove] all the objects down one slot from the removal index.  This means this operation is fastest when removing objects at the last index since no objects need to be moved.  The array will not resize its backing store to a smaller size.
    
    * [`-copy`][-copy] and [`-mutableCopy`][-mutableCopy] will instantiate a new [`NSArray`][NSArray] or [`NSMutableArray`][NSMutableArray] class object, respectively, with the contents of the receiver.
    
    #### `JKMutableDictionary` Usage Notes
    
    * You should minimize the number of new keys you add to the dictionary.  If the number of items in the dictionary exceeds a threshold value it will trigger a resizing operation.  To do this, the dictionary must allocate a new, larger backing store, and then re-add all the items in the dictionary by rehashing them to the size of the newer, larger store.  This is an expensive operation.  While this is a limitation of nearly all hash tables, the capacity for the hash table used by `JKMutableDictionary` has been chosen to minimize the amount of memory used since it is anticipated that most dictionaries will not grow significantly once they are instantiated.
    
    * If the key already exists in the dictionary and you change the object associated with it via [`-setObject:forKey:`][-setObject:forKey:], this will not cause any performance problems or trigger a hash table resize.
    
    * Removing a key from the dictionary via [`-removeObjectForKey:`][-removeObjectForKey:] will not cause any performance problems.  However, the dictionary will not resize its backing store to the smaller size.
    
    * [`-copy`][-copy] and [`-mutableCopy`][-mutableCopy] will instantiate a new [`NSDictionary`][NSDictionary] or [`NSMutableDictionary`][NSMutableDictionary] class object, respectively, with the contents of the receiver.

### Major Changes

*   The `JK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS` pre-processor define flag that was added to JSONKit v1.3 has been removed.
    
    `JK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS` was added in JSONKit v1.3 as a temporary work around.  While the author was aware of other ways to fix the particular problem caused by the usage of "transfer of ownership callbacks" with Core Foundation classes, the fix provided in JSONKit v1.3 was trivial to implement.  This allowed people who needed that functionality to use JSONKit while a proper solution to the problem was worked on.  JSONKit v1.4 is the result of that work.
    
    JSONKit v1.4 no longer uses the Core Foundation collection classes [`CFArray`][CFArray] and [`CFDictionary`][CFDictionary].  Instead, JSONKit v1.4 contains a concrete subclass of [`NSArray`][NSArray] and [`NSDictionary`][NSDictionary]&ndash; `JKArray` and `JKDictionary`, respectively.  As a result, JSONKit has complete control over the behavior of how items are added and managed within an instantiated collection object.  The `JKArray` and `JKDictionary` classes are private to JSONKit, you should not instantiate them direction.  Since they are concrete subclasses of their respective collection class cluster, they behave and act exactly the same as [`NSArray`][NSArray] and [`NSDictionary`][NSDictionary].
    
    The first benefit is that the "transfer of ownership" object ownership policy can now be safely used.  Because the JSONKit collection objects understand that some methods, such as [`-mutableCopy`][-mutableCopy], should not inherit the same "transfer of ownership" object ownership policy, but must follow the standard Cocoa object ownership policy.  The "transfer of ownership" object ownership policy reduces the number of [`-retain`][-retain] and [`-release`][-release] calls needed to add an object to a collection, and when creating a large number of objects very quickly (as you would expect when parsing JSON), this can result in a non-trivial amount of time.  Eliminating these calls means faster JSON parsing.
    
    A second benefit is that the author encountered some unexpected behavior when using the [`CFDictionaryCreate`][CFDictionaryCreate] function to create a dictionary and the `keys` argument contained duplicate keys.  This required JSONKit to de-duplicate the keys and values before calling [`CFDictionaryCreate`][CFDictionaryCreate].  Unfortunately, JSONKit always had to scan all the keys to make sure there were no duplicates, even though 99.99% of the time there were none.  This was less than optimal, particularly because one of the solutions to this particular problem is to use a hash table to perform the de-duplication.  Now JSONKit can do the de-duplication while it is instantiating the dictionary collection, solving two problems at once.
    
    Yet another benefit is that the recently instantiated object cache that JSONKit uses can be used to cache information about the keys used to create dictionary collections, in particular a keys [`-hash`][-hash] value.  For a lot of real world JSON, this effectively means that the [`-hash`][-hash] for a key is calculated once, and that value is reused again and again when creating dictionaries.  Because all the information required to create the hash table used by `JKDictionary` is already determined at the time the `JKDictionary` object is instantiated, populating the `JKDictionary` is now a very tight loop that only has to call [`-isEqual:`][-isEqual:] on the rare occasions that the JSON being parsed contains duplicate keys.  Since the functions that handle this logic are all declared `static` and are internal to JSONKit, the compiler can heavily optimize this code.
    
    What does this mean in terms of performance?  JSONKit was already fast, but now, it's even faster.  Below is some benchmark times for [`twitter_public_timeline.json`][twitter_public_timeline.json] in [samsoffes / json-benchmarks](https://github.com/samsoffes/json-benchmarks), where _read_ means to convert the JSON to native Objective-C objects, and _write_ means to convert the native Objective-C to JSON&mdash;
    
    <pre>
    v1.3 read : min:  456.000 us, avg:  460.056 us, char/s:  53341332.36 /  50.870 MB/s
    v1.3 write: min:  150.000 us, avg:  151.816 us, char/s: 161643041.58 / 154.155 MB/s</pre>
    
    <pre>
    v1.4 read : min:  285.000 us, avg:  288.603 us, char/s:  85030301.14 /  81.091 MB/s
    v1.4 write: min:  127.000 us, avg:  129.617 us, char/s: 189327017.29 / 180.556 MB/s</pre>
    
    JSONKit v1.4 is nearly 60% faster at reading and 17% faster at writing than v1.3.
    
    The following is the JSON test file taken from the project available at [this blog post](http://psionides.jogger.pl/2010/12/12/cocoa-json-parsing-libraries-part-2/).  The keys and information contained in the JSON was anonymized with random characters.  Since JSONKit relies on its recently instantiated object cache for a lot of its performance, this JSON happens to be "the worst corner case possible".
    
    <pre>
    v1.3 read : min: 5222.000 us, avg: 5262.344 us, char/s:  15585260.10 /  14.863 MB/s
    v1.3 write: min: 1253.000 us, avg: 1259.914 us, char/s:  65095712.88 /  62.080 MB/s</pre>
    
    <pre>
    v1.4 read : min: 4096.000 us, avg: 4122.240 us, char/s:  19895736.30 /  18.974 MB/s
    v1.4 write: min: 1319.000 us, avg: 1335.538 us, char/s:  61409709.05 /  58.565 MB/s</pre>
    
    JSONKit v1.4 is 28% faster at reading and 6% faster at writing that v1.3 in this worst-case torture test.
    
    While your milage may vary, you will likely see improvements in the 50% for reading and 10% for writing on your real world JSON.  The nature of JSONKits cache means performance improvements is statistical in nature and depends on the particular properties of the JSON being parsed.
    
    For comparison, [json-framework][], a popular Objective-C JSON parsing library, turns in the following benchmark times for [`twitter_public_timeline.json`][twitter_public_timeline.json]&mdash;
    
    <pre>
    &#x200b;     read : min: 1670.000 us, avg: 1682.461 us, char/s:  14585776.43 /  13.910 MB/s
    &#x200b;     write: min: 1021.000 us, avg: 1028.970 us, char/s:  23849091.81 /  22.744 MB/s</pre>
    
    Since the benchmark for JSONKit and [json-framework][] was done on the same computer, it's safe to compare the timing results.  The version of [json-framework][] used was the latest v3.0 available via the master branch at the time of this writing on github.com.
    
    JSONKit v1.4 is 483% faster at reading and 694% faster at writing than [json-framework][].

### Other Changes

*   Added a `__clang_analyzer__` pre-processor conditional around some code that the `clang` static analyzer was giving false positives for.  However, `clang` versions &le; 1.5 do not define `__clang_analyzer__` and therefore will continue to emit analyzer warnings.
*   The cache now uses a Galois Linear Feedback Shift Register PRNG to select which item in the cache to randomly age.  This should age items in the cache more fairly.
*   To promote better L1 cache locality, the cache age structure was rearranged slightly along with modifying when an item is randomly chosen to be aged.
*   Removed a lot of internal and private data structures from `JSONKit.h` and put them in `JSONKit.m`.
*   Modified the way floating point values are serialized.  Previously, the [`printf`][printf] format conversion `%.16g` was used.  This was changed to `%.17g` which should theoretically allow for up to a full `float`, or [IEEE 754 Single 32-bit floating-point][Single Precision], of precision when converting floating point values to decimal representation. 
*   The usual sundry of inconsequential tidies and what not, such as updating the `README.md`, etc.
*   The catagory additions to the Cocoa classes were changed from `JSONKit` to `JSONKitDeserializing` and `JSONKitSerializing`, as appropriate.

## Version 1.3 2011/05/02

### New Features

*   Added the `JK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS` pre-processor define flag.
    
    This is typically enabled by adding `-DJK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS` to the compilers command line arguments or in `Xcode.app` by adding `JK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS` to a projects / targets `Pre-Processor Macros` settings.
    
    The `JK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS` option enables the use of custom Core Foundation collection call backs which omit the [`CFRetain`][CFRetain] calls.  This results in saving several [`CFRetain`][CFRetain] and [`CFRelease`][CFRelease] calls typically needed for every single object from the parsed JSON.  While the author has used this technique for years without any issues, an unexpected interaction with the Foundation [`-mutableCopy`][-mutableCopy] method and Core Foundation Toll-Free Bridging resulting in a condition in which the objects contained in the collection to be over released.  This problem does not occur with the use of [`-copy`][-copy] due to the fact that the objects created by JSONKit are immutable, and therefore [`-copy`][-copy] does not require creating a completely new object and copying the contents, instead [`-copy`][-copy] simply returns a [`-retain`][-retain]'d version of the immutable object which is significantly faster along with the obvious reduction in memory usage.
    
    Prior to version 1.3, JSONKit always used custom "Transfer of Ownership Collection Callbacks", and thus `JK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS` was effectively implicitly defined.
    
    Beginning with version 1.3, the default behavior of JSONKit is to use the standard Core Foundation collection callbacks ([`kCFTypeArrayCallBacks`][kCFTypeArrayCallBacks], [`kCFTypeDictionaryKeyCallBacks`][kCFTypeDictionaryKeyCallBacks], and [`kCFTypeDictionaryValueCallBacks`][kCFTypeDictionaryValueCallBacks]).  The intention is to follow "the principle of least surprise", and the author believes the use of the standard Core Foundation collection callbacks as the default behavior for JSONKit results in the least surprise.
    
    **NOTE**: `JK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS` is only applicable to `(CF|NS)` `Dictionary` and `Array` class objects.
    
    For the vast majority of users, the author believes JSONKits custom "Transfer of Ownership Collection Callbacks" will not cause any problems.  As previously stated, the author has used this technique in performance critical code for years and has never had a problem.  Until a user reported a problem with [`-mutableCopy`][-mutableCopy], the author was unaware that the use of the custom callbacks could even cause a problem.  This is probably due to the fact that the vast majority of time the typical usage pattern tends to be "iterate the contents of the collection" and very rarely mutate the returned collection directly (although this last part is likely to vary significantly from programmer to programmer).  The author tends to avoid the use of [`-mutableCopy`][-mutableCopy] as it results in a significant performance and memory consumption penalty.  The reason for this is in "typical" Cocoa coding patterns, using [`-mutableCopy`][-mutableCopy] will instantiate an identical, albeit mutable, version of the original object.  This requires both memory for the new object and time to iterate the contents of the original object and add them to the new object.  Furthermore, under "typical" Cocoa coding patterns, the original collection object continues to consume memory until the autorelease pool is released.  However, clearly there are cases where the use of [`-mutableCopy`][-mutableCopy] makes sense or may be used by an external library which is out of your direct control.
    
    The use of the standard Core Foundation collection callbacks results in a 9% to 23% reduction in parsing performance, with an "eye-balled average" of around 13% according to some benchmarking done by the author using Real World&trade; JSON (i.e., actual JSON from various web services, such as Twitter, etc) using `gcc-4.2 -arch x86_64 -O3 -DNS_BLOCK_ASSERTIONS` with the only change being the addition of `-DJK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS`.
    
    `JK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS` is only applicable to parsing / deserializing (i.e. converting from) of JSON.  Serializing (i.e., converting to JSON) is completely unaffected by this change.

### Bug Fixes

*   Fixed a [bug report regarding `-mutableCopy`](https://github.com/johnezang/JSONKit/issues#issue/3).  This is related to the addition of the pre-processor define flag `JK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS`.

### Other Changes

*   Added `JK_EXPECTED` optimization hints around several conditionals.
*   When serializing objects, JSONKit first starts with a small, on stack buffer.  If the encoded JSON exceeds the size of the stack buffer, JSONKit switches to a heap allocated buffer.  If JSONKit switched to a heap allocated buffer, [`CFDataCreateWithBytesNoCopy`][CFDataCreateWithBytesNoCopy] is used to create the [`NSData`][NSData] object, which in most cases causes the heap allocated buffer to "transfer" to the [`NSData`][NSData] object which is substantially faster than allocating a new buffer and copying the bytes.
*   Added a pre-processor check in `JSONKit.m` to see if Objective-C Garbage Collection is enabled and issue a `#error` notice that JSONKit does not support Objective-C Garbage Collection.
*   Various other minor or trivial modifications, such as updating `README.md`.

### Other Issues

*   When using the `clang` static analyzer (the version used at the time of this writing was `Apple clang version 1.5 (tags/Apple/clang-60)`), the static analyzer reports a number of problems with `JSONKit.m`.
    
    The author has investigated these issues and determined that the problems reported by the current version of the static analyzer are "false positives".  Not only that, the reported problems are not only "false positives", they are very clearly and obviously wrong.  Therefore, the author has made the decision that no action will be taken on these non-problems, which includes not modifying the code for the sole purpose of silencing the static analyzer.  The justification for this is "the dog wags the tail, not the other way around."

## Version 1.2 2011/01/08

### Bug Fixes

*   When JSONKit attempted to parse and decode JSON that contained `{"key": value}` dictionaries that contained the same key more than once would likely result in a crash.  This was a serious bug.
*   Under some conditions, JSONKit could potentially leak memory.
*   There was an off by one error in the code that checked whether or not the parser was at the end of the `UTF8` buffer.  This could result in JSONKit reading one by past the buffer bounds in some cases.

### Other Changes

*   Some of the methods were missing `NULL` pointer checks for some of their arguments.  This was fixed.  In generally, when JSONKit encounters invalid arguments, it throws a `NSInvalidArgumentException` exception.
*   Various other minor changes such as tightening up numeric literals with `UL` or `L` qualification, assertion check tweaks and additions, etc.
*   The README.md file was updated with additional information.

### Version 1.1

No change log information was kept for versions prior to 1.2.

[bugtracker]: https://github.com/johnezang/JSONKit/issues
[RFC 4627]: http://tools.ietf.org/html/rfc4627
[twitter_public_timeline.json]: https://github.com/samsoffes/json-benchmarks/blob/master/Resources/twitter_public_timeline.json
[json-framework]: https://github.com/stig/json-framework
[Single Precision]: http://en.wikipedia.org/wiki/Single_precision
[kCFTypeArrayCallBacks]: http://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFArrayRef/Reference/reference.html#//apple_ref/c/data/kCFTypeArrayCallBacks
[kCFTypeDictionaryKeyCallBacks]: http://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFDictionaryRef/Reference/reference.html#//apple_ref/c/data/kCFTypeDictionaryKeyCallBacks
[kCFTypeDictionaryValueCallBacks]: http://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFDictionaryRef/Reference/reference.html#//apple_ref/c/data/kCFTypeDictionaryValueCallBacks
[CFRetain]: http://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFTypeRef/Reference/reference.html#//apple_ref/c/func/CFRetain
[CFRelease]: http://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFTypeRef/Reference/reference.html#//apple_ref/c/func/CFRelease
[CFDataCreateWithBytesNoCopy]: http://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFDataRef/Reference/reference.html#//apple_ref/c/func/CFDataCreateWithBytesNoCopy
[CFArray]: http://developer.apple.com/library/mac/#documentation/CoreFoundation/Reference/CFArrayRef/Reference/reference.html
[CFDictionary]: http://developer.apple.com/library/mac/#documentation/CoreFoundation/Reference/CFDictionaryRef/Reference/reference.html
[CFDictionaryCreate]: http://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFDictionaryRef/Reference/reference.html#//apple_ref/c/func/CFDictionaryCreate
[-mutableCopy]: http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSObject_Class/Reference/Reference.html%23//apple_ref/occ/instm/NSObject/mutableCopy
[-copy]: http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSObject_Class/Reference/Reference.html%23//apple_ref/occ/instm/NSObject/copy
[-retain]: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Protocols/NSObject_Protocol/Reference/NSObject.html#//apple_ref/occ/intfm/NSObject/retain
[-release]: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Protocols/NSObject_Protocol/Reference/NSObject.html#//apple_ref/occ/intfm/NSObject/release
[-isEqual:]: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Protocols/NSObject_Protocol/Reference/NSObject.html#//apple_ref/occ/intfm/NSObject/isEqual:
[-hash]: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Protocols/NSObject_Protocol/Reference/NSObject.html#//apple_ref/occ/intfm/NSObject/hash
[NSArray]: http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSArray_Class/index.html
[NSMutableArray]: http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSMutableArray_Class/index.html
[-insertObject:atIndex:]: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSMutableArray_Class/Reference/Reference.html#//apple_ref/occ/instm/NSMutableArray/insertObject:atIndex:
[-removeObjectAtIndex:]: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSMutableArray_Class/Reference/Reference.html#//apple_ref/occ/instm/NSMutableArray/removeObjectAtIndex:
[-replaceObjectAtIndex:withObject:]: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSMutableArray_Class/Reference/Reference.html#//apple_ref/occ/instm/NSMutableArray/replaceObjectAtIndex:withObject:
[NSDictionary]: http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSDictionary_Class/index.html
[NSMutableDictionary]: http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSMutableDictionary_Class/index.html
[-setObject:forKey:]: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSMutableDictionary_Class/Reference/Reference.html#//apple_ref/occ/instm/NSMutableDictionary/setObject:forKey:
[-removeObjectForKey:]: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSMutableDictionary_Class/Reference/Reference.html#//apple_ref/occ/instm/NSMutableDictionary/removeObjectForKey:
[NSData]: http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSData_Class/index.html
[NSFastEnumeration]: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSFastEnumeration_protocol/Reference/NSFastEnumeration.html
[NSString]: http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/index.html
[printf]: http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man3/printf.3.html
[memmove]: http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man3/memmove.3.html
