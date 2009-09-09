#import "KeyDerivationManager.h"
#import "NSString_NV.h"
#import "NotationPrefs.h"
#import "KeyDerivationDelaySlider.h"
#import "NSData_transformations.h"

@implementation KeyDerivationManager

- (id)initWithNotationPrefs:(NotationPrefs*)prefs {
	notationPrefs = [prefs retain];
	
	//compute initial test duration for the current iteration number
	crapData = [[@"random crap" dataUsingEncoding:NSASCIIStringEncoding] retain];
	crapSalt = [[NSData randomDataOfLength:256] retain];
	
	lastHashIterationCount = [notationPrefs hashIterationCount];
	lastHashDuration = [self delayForHashIterations:lastHashIterationCount];
	
	if (![self init]) {
		[self release];
		return nil;
	}
		
	return self;
}

- (void)awakeFromNib {
	//let the user choose a delay between 50 ms and 3 1/2 secs
	[slider setMinValue:0.05];
	[slider setMaxValue:3.5];
	
	[slider setDelegate:self];
	[slider setDoubleValue:lastHashDuration];
	[self sliderChanged:slider];
	
	[self updateToolTip];
}

- (id)init {
	if ([super init]) {
		if (!view) {
			if (![NSBundle loadNibNamed:@"KeyDerivationManager" owner:self])  {
				NSLog(@"Failed to load KeyDerivationManager.nib");
				NSBeep();
				return nil;
			}
		}
	}
		
	return self;
}

- (void)dealloc {
	[notationPrefs release];
	[crapData release];
	[crapSalt release];
	
	[super dealloc];
}

- (NSView*)view {
	return view;
}

- (int)hashIterationCount {
	return lastHashIterationCount;
}

- (void)updateToolTip {
	[slider setToolTip:[NSString stringWithFormat:NSLocalizedString(@"PBKDF2 iterations: %d", nil), lastHashIterationCount]];
}

- (void)mouseUpForKeyDerivationDelaySlider:(KeyDerivationDelaySlider*)aSlider {
	
	lastHashIterationCount = [self estimatedIterationsForDuration:[aSlider doubleValue]];
	
	lastHashDuration = [self delayForHashIterations:lastHashIterationCount];
	
	//update slider for correction
	[slider setDoubleValue:lastHashDuration];
	
	[self updateToolTip];
}

- (IBAction)sliderChanged:(id)sender {
	[hashDurationField setStringValue:[NSString timeDelayStringWithNumberOfSeconds:[sender doubleValue]]];
}

- (double)delayForHashIterations:(int)count {
	NSDate *before = [NSDate date];
	[crapData derivedKeyOfLength:[notationPrefs keyLengthInBits]/8 salt:crapSalt iterations:count];
	return [[NSDate date] timeIntervalSinceDate:before];
}

- (int)estimatedIterationsForDuration:(double)duration {
	//we could compute several hash durations at varying counts and use polynomial interpolation, but that may be overkill
	
	int count = (int)((duration * (double)lastHashIterationCount) / (double)lastHashDuration);
	
	int minCount = MAX(2000, count);
	//on a 1GHz machine, don't make them wait more than a minute
	return MIN(minCount, 9000000);
}

@end