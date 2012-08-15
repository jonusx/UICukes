/* UICukes UIApplicationSteps.m
 *
 * Copyright © 2012, The OCCukes Organisation. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the “Software”), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 *	The above copyright notice and this permission notice shall be included in
 *	all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
 * EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 ******************************************************************************/

#import <OCCukes/OCCukes.h>
#import <OCExpectations/OCExpectations.h>

#import "UIApplicationHelpers.h"

/*
 * For this to work, you need to add -all_load to your Other Linker Flags. But
 * only for the test target, though you typically need that flag on application
 * targets when linking against static libraries in general. Without that flag,
 * the linker will not automatically run the constructor method. You will need
 * to execute the method manually instead.
 */
__attribute__((constructor))
static void StepDefinitions()
{
	@autoreleasepool {
		[OCCucumber given:@"^the device is in \"(.*?)\" orientation$" step:^(NSArray *arguments) {
			// There are four orientations: portrait, upside-down portrait,
			// landscape left and landscape right. Hence there are two major
			// descriptions of orientation: portrait and landscape. But within
			// these two a further more-detailed description. Use the
			// Apple-provided macros and enumerators to convert the orientation
			// to strings for comparison with the given argument.
			[OCSpecNullForNil([UIApplication sharedApplication]) shouldNot:be_null];
			UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
			[@(UIDeviceOrientationIsValidInterfaceOrientation(interfaceOrientation)) should:be_true];
			[UILocalizedDescriptionsFromInterfaceOrientation(interfaceOrientation) should:include(arguments[0])];
		} file:__FILE__ line:__LINE__];
		
		// Create a bunch of step definitions for matching expectations about
		// interface orientation, where the expectation follows one of the forms:
		//
		//	the device is in <some> orientation
		//	the device is not in <some> orientation
		//
		// Here, <some> represents one of the orientation descriptions:
		// portrait, portrait upside down, portrait upside-down, upside-down
		// portrait, landscape, landscape left, landscape right.
		for (NSNumber *expected in @[ @(UIInterfaceOrientationPortrait), @(UIInterfaceOrientationPortraitUpsideDown), @(UIInterfaceOrientationLandscapeLeft), @(UIInterfaceOrientationLandscapeRight) ])
		{
			for (NSString *description in UILocalizedDescriptionsFromInterfaceOrientation([expected intValue]))
			{
				[OCCucumber given:[NSString stringWithFormat:@"^the device is in %@ orientation$", description] step:^(NSArray *arguments) {
					[OCSpecNullForNil([UIApplication sharedApplication]) shouldNot:be_null];
					UIInterfaceOrientation actual = [[UIApplication sharedApplication] statusBarOrientation];
					[@(UIDeviceOrientationIsValidInterfaceOrientation(actual)) should:be_true];
					[@(actual) should:equal(expected)];
				} file:__FILE__ line:__LINE__];
				[OCCucumber given:[NSString stringWithFormat:@"^the device is not in %@ orientation$", description] step:^(NSArray *arguments) {
					[OCSpecNullForNil([UIApplication sharedApplication]) shouldNot:be_null];
					UIInterfaceOrientation actual = [[UIApplication sharedApplication] statusBarOrientation];
					[@(UIDeviceOrientationIsValidInterfaceOrientation(actual)) should:be_true];
					[@(actual) shouldNot:equal(expected)];
				} file:__FILE__ line:__LINE__];
			}
		}
		
		[OCCucumber given:@"^the app has the name \"(.*?)\"$" step:^(NSArray *arguments) {
			[OCSpecNullForNil([UIApplication sharedApplication]) shouldNot:be_null];
			NSBundle *bundle = [NSBundle mainBundle];
			NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:[bundle bundlePath]];
			[[displayName stringByDeletingPathExtension] should:be(arguments[0])];
		} file:__FILE__ line:__LINE__];
		
		[OCCucumber then:@"^tap the first text field$" step:^(NSArray *arguments) {
			// Collect all the text fields in the application's key window. Pick
			// the first. But what does it mean, the 'first' text
			// field. Interpret this to mean the top-most and left-most text
			// field. Sort them by frame y and x coordinates. Ignore hidden
			// views, including any sub-views belonging to hidden views. Use the
			// key window as the frame of reference when comparing coordinates.
			UIApplication *application = [UIApplication sharedApplication];
			UIWindow *keyWindow = [application keyWindow];
			NSMutableArray *textFields = [NSMutableArray array];
			NSMutableArray *views = [NSMutableArray arrayWithObject:keyWindow];
			for (NSUInteger index = 0; index < [views count]; index++)
			{
				UIView *view = views[index];
				if (![view isHidden])
				{
					[views addObjectsFromArray:[view subviews]];
					if ([view isKindOfClass:[UITextField class]])
					{
						[textFields addObject:view];
					}
				}
			}
			[textFields sortUsingComparator:^NSComparisonResult(UITextField *textField1, UITextField *textField2) {
				CGRect frame1 = [keyWindow convertRect:[textField1 frame] fromView:textField1];
				CGRect frame2 = [keyWindow convertRect:[textField2 frame] fromView:textField2];
				NSComparisonResult result = [@(frame1.origin.y) compare:@(frame2.origin.y)];
				return result != NSOrderedSame ? result : [@(frame1.origin.x) compare:@(frame2.origin.x)];
			}];
			[@([textFields[0] becomeFirstResponder]) should:be_true];
		} file:__FILE__ line:__LINE__];
	}
}
