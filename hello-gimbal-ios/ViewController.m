
#import "ViewController.h"
#import <Gimbal/Gimbal.h>

@interface ViewController () <GMBLPlaceManagerDelegate, GMBLCommunicationManagerDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate, UIAlertViewDelegate, AVSpeechSynthesizerDelegate, GMBLCommunicationManagerDelegate>

@property (nonatomic) GMBLPlaceManager *placeManager;
@property (nonatomic) GMBLCommunicationManager *communicationManager;

@property (nonatomic) NSMutableArray *placeEvents;
@property CLLocationManager *locationManager;
@property CLHeading *currentHeading;
@property CBCentralManager *centralManager;

@property int lastRSSI;

@property AVSpeechSynthesizer *synth;

@property (weak, nonatomic) IBOutlet UILabel *headingLabel;

@property BOOL isSpeaking;
@end

@implementation ViewController




- (void)viewDidLoad
{
    [super viewDidLoad];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], CBCentralManagerOptionShowPowerAlertKey, nil];
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];

    self.synth = [[AVSpeechSynthesizer alloc] init];
    self.synth.delegate = self;

    [self SpeakWords:@"Hello, Welcome to Batwomen navigation. Please search for a location that has batwomen enabled" withDelay:1];

    self.locationManager = [[CLLocationManager alloc] init];

    [self.locationManager requestAlwaysAuthorization];

    self.currentHeading = [[CLHeading alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    //Could change to increments of 5.
    self.locationManager.headingFilter = 1;

    self.locationManager.delegate = self;
    [self.locationManager startUpdatingHeading];

    self.placeEvents = [NSMutableArray new];

    self.placeManager = [GMBLPlaceManager new];
    self.placeManager.delegate = self;

    self.communicationManager = [GMBLCommunicationManager new];
    self.communicationManager.delegate = self;
    
    self.placeManager = [GMBLPlaceManager new];
    self.placeManager.delegate = self;

    [GMBLPlaceManager startMonitoring];
    [GMBLCommunicationManager startReceivingCommunications];
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    AudioServicesPlaySystemSound (1113);
    self.isSpeaking = NO;
}

-(void)SpeakWords:(NSString *) words withDelay:(int) delay
{
    if (self.isSpeaking == NO)
    {
    self.isSpeaking = YES;
    AudioServicesPlaySystemSound (1113);
    AVSpeechUtterance *utterance = [AVSpeechUtterance
                                    speechUtteranceWithString:words];
    utterance.rate = .2;
    utterance.pitchMultiplier = 1;
    utterance.preUtteranceDelay = delay;
    utterance.postUtteranceDelay = 1;
    utterance.volume = 1;
//    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-au"];
    [_synth speakUtterance:utterance];
    }
}


#pragma Location Manager Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{

    self.currentHeading = newHeading;
    self.headingLabel.text = [NSString stringWithFormat:@"%d°", (int)newHeading.magneticHeading];

    if (self.isSpeaking == NO)
    {

        if ((int)newHeading.magneticHeading  == 356)
    {
        [self SpeakWords:@"The bathroom is 10 meters in this direction." withDelay:0];
    }
    else if ((int)newHeading.magneticHeading == 283)
    {
        [self SpeakWords:@"The Living Room is 5 meters in this direction" withDelay:0];
    }
    else if ((int)newHeading.magneticHeading == 194)
    {
        [self SpeakWords:@"The bedroom is 10 meters down this hall" withDelay:0];
    } else if ((int)newHeading.magneticHeading == 120)
    {
        [self SpeakWords:@"The exit door is down the hall 5 meters this way." withDelay:0];
    }

    }
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    if(self.currentHeading == nil)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}


-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"fail");
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"%ld state on/off", central.state);
    if (central.state == CBCentralManagerStatePoweredOff) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bluetooth" message:@"Turn it on" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:0, nil];
        [alert show];
    }
}


-(void)placeManager:(GMBLPlaceManager *)manager didReceiveBeaconSighting:(GMBLBeaconSighting *)sighting forVisits:(NSArray *)visits
{
    if (sighting.RSSI > -80)
    {
    NSLog(@"%@", sighting.beacon.name);
    NSLog(@"%li", (long)sighting.RSSI);


    _lastRSSI = (int)sighting.RSSI;

    if (sighting.RSSI > - 70)
    {
        [self SpeakWords:@"Beacon Spot Found. Please rotate in place for directions." withDelay:0];
        [GMBLPlaceManager stopMonitoring];
        [GMBLCommunicationManager stopReceivingCommunications];
    }
    else if (sighting.RSSI > -70)
    {
        [self SpeakWords:@"Getting Closer" withDelay:0];
    }

        if (_lastRSSI > (int)sighting.RSSI)
        {
            [self SpeakWords:@"Hotter" withDelay:0];
            //        AudioServicesPlaySystemSound (1053);
        }
        else
        {
            [self SpeakWords:@"Colder" withDelay:0];
            //        AudioServicesPlaySystemSound(1054);
        }

    }
}

# pragma mark - Gimbal Place Manager Delegate methods
- (void)placeManager:(GMBLPlaceManager *)manager didBeginVisit:(GMBLVisit *)visit
{
     NSLog(@"Begin %@", [visit.place description]);
    [self.placeEvents insertObject:visit atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)placeManager:(GMBLPlaceManager *)manager didEndVisit:(GMBLVisit *)visit
{
    NSLog(@"End %@", [visit.place description]);
    [self.placeEvents insertObject:visit atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}


-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"fail");

    if([[[UIDevice currentDevice] systemVersion] floatValue]<8.0)
    {
        UIAlertView* curr1=[[UIAlertView alloc] initWithTitle:@"Location not enabled." message:@"Settings -> Batwomen -> Contacts" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [curr1 show];
    }
    else
    {
        UIAlertView* curr2=[[UIAlertView alloc] initWithTitle:@"Location not enabled." message:@"Settings -> Batwomen -> Contacts" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Settings", nil];
        curr2.tag=121;
        [curr2 show];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
           [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

# pragma mark - Table View methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.placeEvents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    GMBLVisit *visit = (GMBLVisit*)self.placeEvents[indexPath.row];
    
    if (visit.departureDate == nil)
    {
        cell.textLabel.text = [NSString stringWithFormat:@"Begin: %@", visit.place.name];
        cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:visit.arrivalDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
    }
    else
    {
        cell.textLabel.text = [NSString stringWithFormat:@"End: %@", visit.place.name];
        cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:visit.departureDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
    }
    
    return cell;
}


@end
