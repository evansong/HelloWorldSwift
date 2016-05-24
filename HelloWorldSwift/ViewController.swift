//
//  Copyright (c) 2011-2014 orbotix. All rights reserved.
//

import UIKit

class ViewController: UIViewController, RKResponseObserver {
    var robot: RKConvenienceRobot!
    var ledON = false
    
    @IBOutlet var connectionLabel: UILabel!
    @IBOutlet weak var lblOutput: UILabel!
    @IBOutlet weak var lblSpheroState: UILabel!
    @IBOutlet weak var lblSpheroVelocity: UILabel!
    @IBOutlet weak var lblSpheroPosition: UILabel!
    @IBOutlet weak var lblSpheroLocator: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.appWillResignActive(_:)), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.appDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        RKRobotDiscoveryAgent.sharedAgent().addNotificationObserver(self, selector: #selector(ViewController.handleRobotStateChangeNotification(_:)))
    }
    
    func handleAsyncMessage(message: RKAsyncMessage!, forRobot robot: RKRobotBase!) {
        if let sensorMessage = message as? RKDeviceSensorsAsyncData {
            let sensorData = sensorMessage.dataFrames.last as? RKDeviceSensorsData;
            
            if let sensorDataValue = sensorData {
            
                let acceleration = sensorDataValue.accelerometerData.acceleration;
                let attitude = sensorDataValue.attitudeData;
                let gyro = sensorDataValue.gyroData;
                //let locatorData = sensorDataValue.locatorData;
                
                let accelX = acceleration.x;
                let accelY = acceleration.y;
                let accelZ = acceleration.z;
                
                let roll = attitude.roll;
                let yaw = attitude.yaw;
                let pitch = attitude.pitch;
                
                let gyroX = gyro.rotationRate.x;
                let gyroY = gyro.rotationRate.y;
                let gyroZ = gyro.rotationRate.z;
                
                lblSpheroVelocity.text = "Acceleration > X: \(accelX), Y: \(accelY), Z: \(accelZ)";
            
                lblSpheroState.text = "Roll: \(roll)  Yaw: \(yaw) Pitch: \(pitch)";
                
                lblSpheroPosition.text = "Gyro > X: \(gyroX), Y: \(gyroY), Z: \(gyroZ)";
                /*
                if (locatorData != nil)
                {
                    lblSpheroLocator.text = locatorData.description;// "Position > X: \(locatorData.position.x), Y: \(locatorData.position.y)";
                }
                */
            }
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        connectionLabel = nil;
    }

    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    @IBAction func sleepButtonTapped(sender: AnyObject) {
        if let robot = self.robot {
            connectionLabel.text = "Sleeping"
            robot.sleep()
        }
    }
    
    func appWillResignActive(note: NSNotification) {
        RKRobotDiscoveryAgent.disconnectAll()
        stopDiscovery()
    }
    
    func appDidBecomeActive(note: NSNotification) {
        startDiscovery()
    }
    
    func handleRobotStateChangeNotification(notification: RKRobotChangedStateNotification) {
        let noteRobot = notification.robot
        
        switch (notification.type) {
        case .Connecting:
            connectionLabel.text = "\(notification.robot.name()) Connecting"
            break
        case .Online:
            let conveniencerobot = RKConvenienceRobot(robot: noteRobot);
            
            if (UIApplication.sharedApplication().applicationState != .Active) {
                conveniencerobot.disconnect()
            } else {
                self.robot = RKConvenienceRobot(robot: noteRobot);

                self.robot.addResponseObserver(self);
                self.robot.enableStabilization(false);
                self.robot.enableLocator(true);
                
                //Create a mask for the sensors you are interested in
                let mask: RKDataStreamingMask = [.AccelerometerFilteredAll, .IMUAnglesFilteredAll, .GyroFilteredAll];
                
                self.robot.enableSensors(mask, atStreamingRate: RKStreamingRate.DataStreamingRate10 );

                connectionLabel.text = noteRobot.name()
                togleLED()
            }
            break
        case .Disconnected:
            connectionLabel.text = "Disconnected"
            startDiscovery()
            robot = nil;
            
            break
        default:
            NSLog("State change with state: \(notification.type)")
        }
    }
    
    func startDiscovery() {
        connectionLabel.text = "Discovering Robots"
        RKRobotDiscoveryAgent.startDiscovery()
    }
    
    @IBAction func didTouch0(sender: AnyObject) {
        self.robot.driveWithHeading(0.0, andVelocity: 0.5);
        lblOutput.text = "Moving forward";
    }
    
    @IBAction func didTouch90(sender: AnyObject) {
        self.robot.driveWithHeading(90.0, andVelocity: 0.5);
        lblOutput.text = "Moving right";
    }
    
    @IBAction func didTouch180(sender: AnyObject) {
        self.robot.driveWithHeading(180.0, andVelocity: 0.5);
        lblOutput.text = "Moving backward";
    }
    
    @IBAction func didTouch270(sender: AnyObject) {
        self.robot.driveWithHeading(270.0, andVelocity: 0.5);
        lblOutput.text = "Moving left";
    }
    
    func stopDiscovery() {
        RKRobotDiscoveryAgent.stopDiscovery()
    }
    
    func togleLED() {
        if let robot = self.robot {
            if (ledON) {
                robot.setLEDWithRed(0.0, green: 0.0, blue: 0.0)
            } else {
                robot.setLEDWithRed(0.0, green: 0.0, blue: 1.0)
            }
            ledON = !ledON
            
            let delay = Int64(0.5 * Float(NSEC_PER_SEC))
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue(), { () -> Void in
                self.togleLED();
            })
        }
    }
}
