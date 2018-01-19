import UIKit
import AVKit
import Toaster
import Alamofire
import Kingfisher
import Foundation
import SwiftyJSON
import CoreLocation
import AVFoundation
import AssetsLibrary
import NVActivityIndicatorView
import SlideMenuControllerSwift

typealias ServiceResponse = (JSON, Error?) -> Void

// Check Network Rechable
var isReachable: Bool {
    return NetworkReachabilityManager()!.isReachable
}

/// App's name (if applicable).
public var appDisplayName: String? {
    // http://stackoverflow.com/questions/28254377/get-app-name-in-swift
    return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
}

/// Shared instance of current device.
public var currentDevice: UIDevice {
    return UIDevice.current
}

// Current orientation of device.
public var deviceOrientation: UIDeviceOrientation {
    return currentDevice.orientation
}

/// Screen width.
public var screenWidth: CGFloat {
    return UIScreen.main.bounds.width
}

/// Screen height.
public var screenHeight: CGFloat {
    return UIScreen.main.bounds.height
}

/// App's bundle ID (if applicable).
public var appBundleID: String? {
    return Bundle.main.bundleIdentifier
}

/// Application icon badge current number.
public var applicationIconBadgeNumber: Int {
    get {
        return UIApplication.shared.applicationIconBadgeNumber
    }
    set {
        UIApplication.shared.applicationIconBadgeNumber = newValue
    }
}

/// App's current version (if applicable).
public var appVersion: String? {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
}

/// Check if device is iPad.
public var isPad: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

/// Check if device is iPhone.
public var isPhone: Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

/// Check if application is running on simulator (read-only).
public var isRunningOnSimulator: Bool {
    #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
        return true
    #else
        return false
    #endif
}

/// Shared instance UIApplication.
public var sharedApplication: UIApplication {
    return UIApplication.shared
}

// Get Longitude
var longitude:Double {
    return appDelegate.longitude
}

// Get Latitude
var latitude:Double {
    return appDelegate.latitude
}

extension UIViewController: NVActivityIndicatorViewable {
    
    // Go Back Action
    @IBAction func goBack(_ sender: UIButton) {
        self.navigationController!.popViewController(animated: true)
    }
    
    // Return LoggedIn userId
    func getUserId() -> String {
        let userId = UserDefaults.standard.object(forKey: "user_id")
        return (userId == nil ? "" : userId as! String)
    }
    
    // Return AuthToken
    func getToken() -> String {
        let authToken = UserDefaults.standard.object(forKey: "token")
        return (authToken == nil ? "" : authToken as! String)
    }
    
    // Return DeviceToken
    func getDeviceToken() -> String {
        let deviceToken = UserDefaults.standard.object(forKey: "DeviceToken")
        return (deviceToken == nil ? "" : deviceToken as! String)
    }
    
    // Showing Toast Message
    func showTostMessage(message: String){
        Toast(text: message).show()
        ToastView.appearance().backgroundColor = #colorLiteral(red: 0.163174212, green: 0.2325206101, blue: 0.3331266046, alpha: 1)
        ToastView.appearance().textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    // Show LoadingView When API is called
    func showLoading(_ color: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) {
        let size = CGSize(width: 40, height:40)
        startAnimating(size, message: nil, type: .ballClipRotate, color: color)
    }
    
    // Hide LoadingView
    func hideLoading() {
        stopAnimating()
    }
    
    // Listing of All Font Installed/Supported by System
    func fontName() {
        for family in UIFont.familyNames {
            print("\(family)")
            
            for name in UIFont.fontNames(forFamilyName: family) {
                print("   \(name)")
            }
        }
    }
    
    // Create Thumbnail of Given Videos URL
    func createThumbnail(_ fileUrl:URL) -> UIImage {
        do {
            let asset = AVURLAsset(url: fileUrl , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return UIImage()
        }
    }
    
    // Give Alpha Animation to the Selected View
    func setAlphaAnimation(selectedView: UIView, alpha: CGFloat) {
        if alpha == 1 {
            selectedView.isHidden = false
        }
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            selectedView.alpha = alpha
        }) {
            (complete) -> Void in
            if alpha == 0 {
                selectedView.isHidden = true
            }
        }
    }
    
    /// Check if device is registered for remote notifications for current app (read-only).
    public static var isRegisteredForRemoteNotifications: Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }
    
    // Check Location is Allowed or Not
    func isAllowLocation() -> Bool {
        switch(CLLocationManager.authorizationStatus()) {
        case .notDetermined, .restricted, .denied:
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        }
    }
    
    // Add Menu to the screen
    func addMenu() {
        navigationController?.navigationBar.isHidden = true
        navigationItem.hidesBackButton = true
        self.slideMenuController()?.removeLeftGestures()
        self.slideMenuController()?.removeRightGestures()
        self.slideMenuController()?.addLeftGestures()
        self.slideMenuController()?.addRightGestures()
    }
    
    // Remove Menu to the screen
    func removeMenu() {
        navigationController?.navigationBar.isHidden = true
        navigationItem.hidesBackButton = false
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.rightBarButtonItem = nil
        self.slideMenuController()?.removeLeftGestures()
        self.slideMenuController()?.removeRightGestures()
    }
    
    //MARK: - WebService Call
    func webServiceCall(_ url: String, parameter: [String:Any] = [String: Any](), isWithLoading: Bool = true, imageKey: [String] = ["image"], imageData: [Data] = [Data](), videoKey: [String] = ["video"], videoData: [Data] = [Data](), audioKey: [String] = ["audio"], audioData: [Data] = [Data](), isNeedToken: Bool = true, methods: HTTPMethod = .post, completionHandler:@escaping ServiceResponse) {
        
        print("URL :- \(url)")
        print("Parameter :- \(parameter)")
        
        if isReachable {
            
            if isWithLoading {
                showLoading()
            }
            
            var headers = HTTPHeaders()
            if isNeedToken {
                headers = [
                    "Authorization": "Token \(getToken())"
                ]
            }
            
            if imageData.count > 0 || videoData.count > 0 || audioData.count > 0 {
                
                Alamofire.upload (
                    multipartFormData: { multipartFormData in
                        
                        for (key, value) in parameter {
                            multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key)
                        }
                        
                        for i in 0..<imageData.count {
                            if imageData[i].count > 0 {
                                multipartFormData.append(imageData[i], withName: imageKey[i], fileName: "file.jpeg", mimeType: "image/jpeg")
                            }
                        }
                        
                        for i in 0..<videoData.count {
                            if videoData[i].count > 0 {
                                multipartFormData.append(videoData[i], withName: videoKey[i], fileName: "file.mp4", mimeType: "video/mp4")
                            }
                        }
                        
                        for i in 0..<audioData.count {
                            if audioData[i].count > 0 {
                                multipartFormData.append(audioData[i], withName: audioKey[i], fileName: "file.m4a", mimeType: "audio/m4a")
                            }
                        }
                },
                to: url,
                headers : headers,
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseJSON { result in
                            
                            /*
                            print(result)
                            print(result.result)
                            */
                            
                            if let httpError = result.result.error {
                                
                                print(NSString(data: result.data!, encoding: String.Encoding.utf8.rawValue)!)
                                print(httpError._code)
                                
                                let response: [String: Any] = [
                                    "errorCode": httpError._code,
                                    "status": false,
                                    "message": ValidationMessage.somthingWrong
                                ]
                                
                                let json = JSON(response)
                                completionHandler(json, nil)
                                
                                print("JSON: - \(json)")
                            }
                            
                            if  result.result.isSuccess {
                                if let response = result.result.value {
                                    let json = JSON(response)
                                    completionHandler(json, nil)
                                    
                                    print("JSON: - \(json)")
                                }
                            }
                            
                            if isWithLoading {
                                self.hideLoading()
                            }
                        }
                    case .failure(let encodingError):
                        print(encodingError)
                    }
                })
            }
            else
            {
                Alamofire.request(url, method: methods ,parameters: parameter,headers: headers)
                    .responseJSON {  result in
                        
                        print(result)
                        print(result.result)
                        
                        if let httpError = result.result.error {
                            print(NSString(data: result.data!, encoding: String.Encoding.utf8.rawValue)!)
                            print(httpError._code)
                            
                            let response: [String: Any] = [
                                "errorCode": httpError._code,
                                "status": false,
                                "message": ValidationMessage.somthingWrong
                            ]
                            
                            let json = JSON(response)
                            completionHandler(json, nil)
                            
                            print("JSON: - \(json)")
                        }
                        
                        if  result.result.isSuccess {
                            if let response = result.result.value {
                                let json = JSON(response)
                                completionHandler(json, nil)
                                
                                print("JSON: - \(json)")
                            }
                        }
                        
                        if isWithLoading {
                            self.hideLoading()
                        }
                }
            }
        }
        else {
            self.showTostMessage(message: ValidationMessage.internetNotAvailable)
        }
    }
}

extension String {
    // Check for Password Validation
    func isValidPassword() -> Bool {
        if self.characters.count < 6 {
            return false
        }
        return true
    }
    
    // Check for Valid Email Address
    func isValidEmail() -> Bool {
        let emailRegEx = "^[_A-Za-z0-9-]+(\\.[_A-Za-z0-9-]+)*@[A-Za-z0-9]+(\\.[A-Za-z0-9]+)*(\\.[A-Za-z]{2,})$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    // Check for String is Empty
    func isEmpty() -> Bool {
        return self.trimming().isEmpty
    }
    
    // Return the string after trimming
    func trimming() -> String {
        let strText = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return strText
    }
    
    var encodeEmoji: String? {
        let encodedStr = NSString(cString: self.cString(using: String.Encoding.nonLossyASCII)!, encoding: String.Encoding.utf8.rawValue)
        return encodedStr as String?
    }
    
    var decodeEmoji: String {
        let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false)
        if data != nil {
            let valueUniCode = NSString(data: data!, encoding: String.Encoding.nonLossyASCII.rawValue) as String?
            if valueUniCode != nil {
                return valueUniCode!
            } else {
                return self
            }
        } else {
            return self
        }
    }
}

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowOpacity = 0.4
            layer.shadowRadius = shadowRadius
        }
    }
}

extension UIImageView {
    
    // Download image and set into given imageview
    func setImage(image:String, placeholderImage: UIImage) {
        if image != "" {
            
            let url = URL(string: "\(BasePath.Path)\(image)")
            self.image = nil
            
            self.kf.indicatorType = .activity
            
            self.kf.setImage(with: url, placeholder: placeholderImage,
                             options: [.transition(.fade(1))],
                             progressBlock: nil,
                             completionHandler: nil)
        } else {
            self.image = placeholderImage
        }
    }
}

extension UITableView
{
    // Set Text when no any Data found for TableView
    func setTextForBlankTableview(message : String, color: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)) -> Void {
        let messageLabel: UILabel = UILabel(frame: CGRect(x: 17, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        messageLabel.text = message
        messageLabel.textColor = color
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.init(name: "Helvetica", size: 15.0)
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel
    }
    
    // Set Loader in FooterView When pagination is enable
    func makeFooterView(color: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        let act = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width / 2 - 15, y: 10, width: 30, height: 30))
        act.color = color
        act.type = .ballClipRotate
        view.addSubview(act)
        act.startAnimating()
        self.tableFooterView = view
    }
    
    // Remove Footer View From Tableview
    func removeFooterView() {
        self.tableFooterView = UITableViewHeaderFooterView.init()
    }
    
    // Add Pull to Refresh
    func addPullToRefresh(color: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)) -> UIRefreshControl {
        let view = UIRefreshControl()
        view.tintColor = color
        self.addSubview(view)
        return view
    }
}

extension UICollectionView
{
    func setTextForBlankTableview(message : String, color: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)) -> Void {
        let messageLabel: UILabel = UILabel(frame: CGRect(x: 17, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        messageLabel.text = message
        messageLabel.textColor = color
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.init(name: "Helvetica", size: 15.0)
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel
    }
}

extension UIImage {
    
    // Rotate Image by given Degree
    public func imageRotatedByDegrees(degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    // Fix Orentation of Given Image
    func fixOrientation() -> UIImage {
        // No-op if the orientation is already correct
        if ( self.imageOrientation == UIImageOrientation.up ) {
            return self;
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        if ( self.imageOrientation == UIImageOrientation.down || self.imageOrientation == UIImageOrientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        }
        
        if ( self.imageOrientation == UIImageOrientation.left || self.imageOrientation == UIImageOrientation.leftMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2.0))
        }
        
        if ( self.imageOrientation == UIImageOrientation.right || self.imageOrientation == UIImageOrientation.rightMirrored ) {
            transform = transform.translatedBy(x: 0, y: self.size.height);
            transform = transform.rotated(by: CGFloat(-Double.pi / 2.0));
        }
        
        if ( self.imageOrientation == UIImageOrientation.upMirrored || self.imageOrientation == UIImageOrientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        if ( self.imageOrientation == UIImageOrientation.leftMirrored || self.imageOrientation == UIImageOrientation.rightMirrored ) {
            transform = transform.translatedBy(x: self.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1);
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx: CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: self.cgImage!.bitmapInfo.rawValue)!;
        
        ctx.concatenate(transform)
        
        if ( self.imageOrientation == UIImageOrientation.left ||
            self.imageOrientation == UIImageOrientation.leftMirrored ||
            self.imageOrientation == UIImageOrientation.right ||
            self.imageOrientation == UIImageOrientation.rightMirrored ) {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.height,height: self.size.width))
        } else {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.width,height: self.size.height))
        }
        
        // And now we just create a new UIImage from the drawing context and return it
        return UIImage(cgImage: ctx.makeImage()!)
    }
}

extension UIColor {
    
    // Set RGB color for given HexaVaue
    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
    }
}
