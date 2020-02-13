import Foundation
import UIKit
import Display
//import LegacyUI
import TelegramPresentationData
import SwiftSignalKit
import AccountContext
import Zip

private class TopChatsCell: UITableViewCell {
    
    override public func layoutSubviews() {
       super.layoutSubviews()
       if let frameWidth = self.imageView?.frame.width {
           self.imageView?.layer.cornerRadius = frameWidth / 2.0
           self.imageView?.clipsToBounds = true
       }
        let padding = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        bounds = bounds.inset(by: padding)
    }
}

extension FileManager {
    func listurls(directory: String, skipsHiddenFiles: Bool = false ) -> [URL]? {
        let fileURLs = try? contentsOfDirectory(at: URL(string: directory)!, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
}

final class TopChatsController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    
    private let context: AccountContext
    
    var rootNavigationController: NavigationController?
    var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    var dismiss: (() -> Void)?
    var imageLoader: ImageCacheLoader
    
    public var pushControllerImpl: ((ViewController) -> Void)?
    
    var tableView: UITableView = UITableView()
    var topChats: [TopChat] = []
    var filteredTopChats: [TopChat] = []
    let cellReuseIdentifier = "TopChatsCell"
    
    
//    let loadingView = UIView()
//
//    /// Spinner shown during load the TableView
//    let spinner = UIActivityIndicatorView()
//
//    /// Text shown during load the TableView
//    let loadingLabel = UILabel()
    
    public init(context: AccountContext) {
        self.context = context
        self.presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        self.imageLoader = ImageCacheLoader()
        
        super.init(nibName: nil, bundle: nil)
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
            |> deliverOnMainQueue).start(next: { [weak self] presentationData in
                if let strongSelf = self {
                    let previousTheme = strongSelf.presentationData.theme
                    let previousStrings = strongSelf.presentationData.strings
                    
                    strongSelf.presentationData = presentationData
                    
                    if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                        strongSelf.updateThemeAndStrings()
                    }
                }
            })
        print("DOWNLOADING ARCHIVE")
        URLSession(configuration: URLSessionConfiguration.default).dataTask(with: URL(string: ARCHIVE_URL)!) { data, response, error in
            print("RESPONSE", response, "ERROR", error)
             // ensure there is data returned from this HTTP response
            guard let data = data else {
                 print("No data")
                 return
            }
    
            guard let archive = Archive(data: data, accessMode: .read) else  {
                print("Can't get archive data")
                return
            }
            
//            let name = "archive.zip"
//            let fileManager = FileManager.default
//
//            do {
//                let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
//                let fileURL = documentDirectory.appendingPathComponent(name)
//                try data.write(to: fileURL)
//            } catch {
//                print("ERROR WRITING", error)
//            }
//             do {
//                let currentWorkingPath = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
//                var sourceURL = URL(fileURLWithPath: currentWorkingPath.path)
//                sourceURL.appendPathComponent("archive.zip")
//                var destinationURL = URL(fileURLWithPath: currentWorkingPath.path)
//                destinationURL.appendPathComponent("directory")
//                try fileManager.removeItem(at: destinationURL)
//                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
//                try fileManager.unzipItem(at: sourceURL, to: destinationURL)
//                destinationURL.appendPathComponent("topchats-latest")
//                print(fileManager.listurls(directory: destinationURL.path))
//            } catch {
//                print("Extraction of ZIP archive failed with error:\(error)")
//            }
            
            
            
            
            guard let entry = archive["topchats-latest/" + FILE_NAME] else {
                print("topchats.json missing")
                return
            }
            var jsonData = Data()
            do  {
                try archive.extract(entry, consumer: { (data) in
                    print("DATA COUNT", data.count)
                    jsonData.append(data)
                })
            } catch {
                print("Error extracting \(FILE_NAME)")
            }
            print("READY DECOMPILE")
             // Parse JSON into Post array struct using JSONDecoder
             guard let parsedTopChats = try? JSONDecoder().decode([TopChat].self, from: jsonData) else {
                 print("Error: Couldn't decode data into topchats model")
                 return
             }
            
            self.topChats = parsedTopChats
            print("Chats parsed!")
//             for topChat in parsedTopChats {
//                print(topChat)
//                 if topChat.a.isEmpty {
//                     self.topChats.append(topChat)
//                 }
//             }
            
             // Make sure to update UI in main thread
//             DispatchQueue.main.async {
//                 self.tableView.reloadData()
//                 // self.removeLoadingScreen()
//             }
         }.resume()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.register(TopChatsCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        
        self.view.addSubview(self.tableView)
        self.tableView.frame = self.view.bounds
        self.tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.backgroundColor = self.presentationData.theme.chatList.pinnedItemBackgroundColor
        self.tableView.separatorColor = self.presentationData.theme.chatList.itemSeparatorColor
        
//        if self.topChats.isEmpty {
//            setLoadingScreen()
//        }
        
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("APPEAR TABLEVIEW")
        self.getNavigationController()
        if !self.topChats.isEmpty {
            print("reloading table")
        DispatchQueue.main.async {
            self.tableView.reloadData()
            // self.removeLoadingScreen()
         }
            
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return topChats.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell: TopChatsCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! TopChatsCell
        
        let topChat = topChats[indexPath.row]
        
        cell.textLabel?.text = topChat.title
        cell.textLabel?.textColor = self.presentationData.theme.chatList.titleColor
        cell.backgroundColor = self.presentationData.theme.chatList.pinnedItemBackgroundColor
        let view = UIView()
        view.backgroundColor = self.presentationData.theme.chatList.itemSelectedBackgroundColor
        cell.selectedBackgroundView = view
        
        imageLoader.obtainImageWithPath(imagePath: AVATAR_URL + topChat.image) { (image) in
            // Before assigning the image, check whether the current cell is visible
            if let updateCell = tableView.cellForRow(at: indexPath) as? TopChatsCell {
                updateCell.imageView?.image = image
                updateCell.setNeedsLayout()
            }
        }
        
        return cell
    }
    
    private func updateThemeAndStrings() {
        //self.title = self.presentationData.strings.Settings_AppLanguage
        //self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .plain, target: self, action: #selector(self.cancelPressed))
        
        if self.isViewLoaded {
            self.tableView.backgroundColor = self.presentationData.theme.chatList.pinnedItemBackgroundColor
            self.tableView.separatorColor = self.presentationData.theme.chatList.itemSeparatorColor
//            loadingLabel.textColor = self.presentationData.theme.chatList.titleColor
//            //loadingLabel.text = "Loading..."
//            spinner.color = self.presentationData.theme.chatList.titleColor
            self.tableView.reloadData()
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topChat = topChats[indexPath.row]
         
        print("TTOPCHAT A \(topChat.a)")
        
        print("You tapped cell \(topChat).")
        let _ = (self.context.sharedContext.resolveUrl(account: self.context.account, url: "https://t.me/\(topChat.username)") |> deliverOnMainQueue).start(next: { resolvedUrl in
            let openUrlSignal = self.context.sharedContext.openResolvedUrl(resolvedUrl, context: self.context, urlContext: .generic, navigationController: self.getNavigationController(), openPeer: { peerId, navigation in
                switch navigation {
                case let .chat(_, subject):
                    if let navigationController = self.getNavigationController() {
                        self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: self.context, chatLocation: .peer(peerId), subject: subject))
                    }
                case let .withBotStartPayload(botStart):
                    if let navigationController = self.getNavigationController() {
                        self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: self.context, chatLocation: .peer(peerId), botStart: botStart, keepStack: .always))
                    }
                case .info:
                    let _ = (self.context.account.postbox.loadedPeerWithId(peerId)
                        |> deliverOnMainQueue).start(next: { peer in
                            if let controller = self.context.sharedContext.makePeerInfoController(context: self.context, peer: peer, mode: .generic) {
                                self.getNavigationController()?.pushViewController(controller)
                            }
                        })
                default:
                    break
                }
            }, sendFile: nil, sendSticker: nil, present: {c, a in
                (self.parent?.parent as? TopChatsViewController)?.present(c, in: .window(.root), with: a)
            }, dismissInput: {
                self.dismiss?()
            }, contentContext: nil)
        })
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func cancelPressed() {
        self.dismiss?()
    }
    
    func getNavigationController() -> NavigationController? {
        if let strongRootNavigationController = self.rootNavigationController {
            return strongRootNavigationController
        }
        
        if let strongParentRootNVC = (self.parent?.parent as? TopChatsViewController)?.navigationController as? NavigationController {
            self.rootNavigationController = strongParentRootNVC
            return strongParentRootNVC
        }
        
        return nil
    }
    
    public func scrollToTop() {
        self.tableView.scrollToTop(true)
    }
    
//    private func loadData() {
//        // Load all data at once
//
//    }
    
    // Set the activity indicator into the main view
//    private func setLoadingScreen() {
//
//        // Sets the view which contains the loading text and the spinner
//        let width: CGFloat = 120
//        let height: CGFloat = 30
//        let x = (tableView.frame.width / 2) - (width / 2)
//        let y = (tableView.frame.height / 2) - (height / 2) - (navigationController?.navigationBar.frame.height)!
//        loadingView.frame = CGRect(x: x, y: y, width: width, height: height)
//
//        // Sets loading text
//        loadingLabel.textColor = self.presentationData.theme.chatList.titleColor
//        loadingLabel.textAlignment = .center
//        loadingLabel.text = "Loading..."
//        loadingLabel.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
//
//        // Sets spinner
//        spinner.style = .gray
//        spinner.color = self.presentationData.theme.chatList.titleColor
//        spinner.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//        spinner.startAnimating()
//
//        // Adds text and spinner to the view
//        loadingView.addSubview(spinner)
//        loadingView.addSubview(loadingLabel)
//
//        tableView.addSubview(loadingView)
//
//    }
//
//    // Remove the activity indicator from the main view
//    private func removeLoadingScreen() {
//
//        // Hides and stops the text and the spinner
//        if spinner.isAnimating {
//            spinner.stopAnimating()
//        }
//        spinner.isHidden = true
//        loadingLabel.isHidden = true
//
//    }
    
}

extension UITableView{
    
    func hasRowAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.section < numberOfSections && indexPath.row < numberOfRows(inSection: indexPath.section)
    }
    
    func scrollToTop(_ animated: Bool = false) {
        let indexPath = IndexPath(row: 0, section: 0)
        if hasRowAtIndexPath(indexPath: indexPath) {
            scrollToRow(at: indexPath, at: .top, animated: animated)
        }
    }
    
}

//public func getTopChatsController(/*context: AccountContext? = nil,*/ theme: PresentationTheme? = nil, strings: PresentationStrings? = nil, initialLayout: ContainerViewLayout? = nil) -> ViewController {
//    let nativeController = TopChatsController()
//    var finalLayout: ContainerViewLayout? = nil
//
//    if let strongInitialLayout = initialLayout {
//        finalLayout = strongInitialLayout
//    } else {
////        let statusBarHost = MonkeyApplicationStatusBarHost()
////        let (window, hostView) = nativeWindowHostView()
////        let window1 = Window1(hostView: hostView, statusBarHost: statusBarHost)
////        finalLayout = ContainerViewLayout(size: nativeController.view.bounds.size, metrics: LayoutMetrics(), deviceMetrics: window1.deviceMetrics, intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, inputHeightIsInteractivellyChanging: false, inVoiceOver: false)
//    }
//    nativeController.edgesForExtendedLayout = []
//
//    let viewController = convertController(controller: nativeController, theme: theme, strings: strings, initialLayout: finalLayout)
//    viewController.tabBarItem.image = UIImage(bundleImageName: "Chat List/Tabs/IconChats")
////    viewController.setNavigationBarHidden(true, animated: false)
////    viewController.navigationBar.transform = CGAffineTransform(translationX: -1000.0, y: 0.0)
//
//    return viewController
//}


final class TopChatsControllerNode: ASDisplayNode {
    var dismiss: (() -> Void)?
    
    override init() {
        super.init()
        
        self.setViewBlock({
            return UITracingLayerView()
        })
        
        self.backgroundColor = UIColor.white
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
    }
    
    //    func animateIn() {
    //        self.layer.animatePosition(from: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), to: self.layer.position, duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring)
    //    }
    //
    //    func animateOut() {
    //        self.layer.animatePosition(from: self.layer.position, to: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), duration: 0.2, timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, removeOnCompletion: false, completion: { [weak self] _ in
    //            if let strongSelf = self {
    //                strongSelf.dismiss?()
    //            }
    //        })
    //    }
}


public class TopChatsViewController: ViewController {
    private var controllerNode: TopChatsControllerNode {
        return self.displayNode as! TopChatsControllerNode
    }
    
    private let innerNavigationController: UINavigationController
    private let innerController: TopChatsController
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    
    
    public var pushControllerImpl: ((ViewController) -> Void)?
    //public var presentControllerImpl: ((ViewController, Any?) -> Void)?
    
    public init(context: AccountContext) {
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        self.innerController = TopChatsController(context: context)
        self.innerNavigationController = UINavigationController(rootViewController: self.innerController)
        //        self.innerController.pushControllerImpl = { value in
        //            (self.innerNavigationController as? NavigationController)?.pushViewController(value)
        //        }
        
        super.init(navigationBarPresentationData: nil)
        
        let title = "Top Chats"
        
        self.tabBarItem.image = UIImage(bundleImageName: "Chat/Input/Media/TrendingIcon")
        self.tabBarItem.title = title
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.innerNavigationController.navigationBar.barTintColor = self.presentationData.theme.rootController.navigationBar.backgroundColor
        self.innerNavigationController.navigationBar.tintColor = self.presentationData.theme.rootController.navigationBar.accentTextColor
        self.innerNavigationController.navigationBar.shadowImage = generateImage(CGSize(width: 1.0, height: 1.0), rotatedContext: { size, context in
            context.clear(CGRect(origin: CGPoint(), size: size))
            context.setFillColor(self.presentationData.theme.rootController.navigationBar.separatorColor.cgColor)
            context.fill(CGRect(origin: CGPoint(), size: CGSize(width: 1.0, height: UIScreenPixel)))
        })
        
        self.innerNavigationController.navigationBar.isTranslucent = false
        self.innerNavigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: Font.semibold(17.0), NSAttributedString.Key.foregroundColor: self.presentationData.theme.rootController.navigationBar.primaryTextColor]
        self.navigationItem.title = title
        
        self.innerController.dismiss = { [weak self] in
            self?.cancelPressed()
        }
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
            |> deliverOnMainQueue).start(next: { [weak self] presentationData in
                if let strongSelf = self {
                    let previousTheme = strongSelf.presentationData.theme
                    let previousStrings = strongSelf.presentationData.strings
                    
                    strongSelf.presentationData = presentationData
                    
                    if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                        strongSelf.updateThemeAndStrings()
                    }
                }
            })
        
        self.scrollToTopWithTabBar = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.innerController.scrollToTop()
        }
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    private func updateThemeAndStrings() {
        print("UPDATING COLORS")
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
    }
    
    override public func loadDisplayNode() {
        self.displayNode = TopChatsControllerNode()
        self.displayNodeDidLoad()
        
        self.innerNavigationController.willMove(toParent: self)
        self.addChild(self.innerNavigationController)
        self.displayNode.view.addSubview(self.innerNavigationController.view)
        self.innerNavigationController.didMove(toParent: self)
        
        self.controllerNode.dismiss = { [weak self] in
            self?.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.innerNavigationController.viewWillAppear(false)
        self.innerNavigationController.viewDidAppear(false)
        //self.controllerNode.animateIn()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        // If we need to go higher than Tabbar
        var tabBarHeight: CGFloat
        var options: ContainerViewLayoutInsetOptions = []
        if layout.metrics.widthClass == .regular {
            options.insert(.input)
        }
        let bottomInset: CGFloat = layout.insets(options: options).bottom
        if !layout.safeInsets.left.isZero {
            tabBarHeight = 34.0 + bottomInset
        } else {
            tabBarHeight = 49.0 + bottomInset
        }
        
        let tabBarFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - tabBarHeight), size: CGSize(width: layout.size.width, height: tabBarHeight))
        
        var finalLayout = layout.size
        finalLayout.height = finalLayout.height - (tabBarFrame.height / 2.0)
        self.innerNavigationController.view.frame = CGRect(origin: CGPoint(), size: finalLayout)
        
        self.controllerNode.containerLayoutUpdated(layout, transition: transition)
    }
    
    private func cancelPressed() {
        //self.controllerNode.animateOut()
    }
    
}
