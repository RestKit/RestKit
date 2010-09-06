//
//  RKTwitterViewController.h
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright Two Toasters 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>

@interface RKTwitterViewController : UIViewController <UITableViewDelegate, RKObjectLoaderDelegate> {
	IBOutlet UITableView* _tableView;
	NSArray* _statuses;
}

/**
 * An array of RKTStatus objects
 */
@property (nonatomic, retain) NSArray* statuses;

@end
