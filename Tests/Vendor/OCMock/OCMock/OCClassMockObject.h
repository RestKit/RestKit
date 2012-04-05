//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2005-2008 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMockObject.h>

@interface OCClassMockObject : OCMockObject
{
	Class	mockedClass;
}

- (id)initWithClass:(Class)aClass;

- (Class)mockedClass;

@end
