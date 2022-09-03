//
//  AppViewController.swift
//  DiRE TV
//
//  Created by ARUN PRASATH on 31/08/22.
//

import UIKit
import AVKit
import AVFoundation
import MarqueeLabel




class AppViewController: UIViewController {
    
    
    @IBOutlet weak var playerView: VideoPlayerView!
    @IBOutlet weak var tickerView: UIView!
    @IBOutlet weak var marqueeTextValues: MarqueeLabel!
    @IBOutlet weak var dateTimeText: UILabel!
    @IBOutlet weak var whiteLogo: UIImageView!
    
    var videosList = [String]()
    var playerIndex = -1
    var tickerData = NSMutableAttributedString()
    var isOffline = false
    var eventURl =
          "https://vimeo.com/event/2171363/embed/11f17392b8?autoplay=1&loop=1&autopause=0&muted=0"
    
    var timer = Timer()
    var playerAVView:AVPlayer!
    var tickerTimer = Timer()

    deinit {
        timer.invalidate()
        tickerTimer.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default
                   .addObserver(self,
                                selector: #selector(statusManager),
                                name: .flagsChanged,
                                object: nil)
        self.view.backgroundColor = .black
        whiteLogo.alpha = 0.5
        whiteLogo.isHidden = true
        tickerView.isHidden = true
        playerView.bringSubviewToFront(whiteLogo)
        timer = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        tickerTimer = Timer.scheduledTimer(timeInterval: 300.0, target: self, selector: #selector(tickerFunc), userInfo: nil, repeats: true)
        playerView.backgroundColor = .clear
        self.playVideo()
//        tickerApi()
       
        
        if playerIndex == 0 || playerIndex == -1 || (playerIndex + 1) == self.videosList.count {
            getVideos(completion: { (videos) in
                DispatchQueue.main.async {
                    self.videosList = videos
                    self.playerIndex = 0
                    self.checkPreload()
                }
            })
        }
    }
    
    @objc func statusManager(_ notification: Notification) {
        print(notification,"notification Value")
        switch Network.reachability.status {
              case .unreachable:
                  print("unreachable")
              case .wwan:
                 print("wwan")
              case .wifi:
            print("wifi")
              }
        print("Reachability Summary")
           print("Status:", Network.reachability.status)
           print("HostName:", Network.reachability.hostname ?? "nil")
           print("Reachable:", Network.reachability.isReachable)
           print("Wifi:", Network.reachability.isReachableViaWiFi)
       }
    
    
    func checkPreload() {
        print(playerIndex)
        if playerIndex + 1 == self.videosList.count {
            getVideos(completion: { (videos) in
                DispatchQueue.main.async {
                    self.playerIndex = -1
                    self.videosList = videos
                    self.checkPreload()
                }
            })
        }
        let urls = self.videosList
            .suffix(from: min(playerIndex + 1, videosList.count))
            .prefix(1)
        print(urls,"url")
        if (!urls.isEmpty) {
            if let urlValue = URL(string: urls.first!) {
                VideoPreloadManager.shared.set(waiting: Array(arrayLiteral: urlValue))
                VideoPreloadManager.shared.start()
            }
        }
    }
    
    @objc func tickerFunc() {
        self.tickerData = NSMutableAttributedString(string: "")
        fetchTickerData(completion: { (ticker) in
            print(ticker.items?.count, "ticker.items?.count")
            let map = ticker.items?.map({ (items) -> NSMutableAttributedString in
                
               
                let titleAttributes : [NSAttributedString.Key : Any] = [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30, weight: .bold)
                        /*UIFont.systemFont(ofSize: 30, weight: .bold)*/]
                let contentOtherAttributes : [NSAttributedString.Key : Any] = [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30, weight: .bold)
                        /*UIFont.systemFont(ofSize: 30, weight: .regular)*/,]
                let iOtherAttributes : [NSAttributedString.Key : Any]  = [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 100, weight: .bold)]
                let titleText = NSMutableAttributedString.init(string: "\(items.title ?? "")     ")
                titleText.addAttributes(titleAttributes, range: NSRange(location: 0, length: titleText.length))
                /*(string: "\(itemsV.title ?? "")    ", attributes: titleAttributes)*/
                let contentText = NSMutableAttributedString.init(string: "\(items.content ?? "")")
                contentText.addAttributes(contentOtherAttributes, range: NSRange(location: 0, length: contentText.length))
                
                /*(string: "\(itemsV.content ?? "")  ", attributes: contentOtherAttributes)*/
                let iText = NSMutableAttributedString.init(string: " I ")
                iText.addAttributes(iOtherAttributes, range: NSRange(location: 0, length: iText.length))
                /*(string: "I ", attributes: iOtherAttributes)*/
                
//                titleText.append(contentText)
//                titleText.append(iText)
//                self.tickerData.append(titleText)
                
                iText.append(titleText)
                iText.append(contentText)
                self.tickerData.append(iText)
                return  self.tickerData
            })
//            print(map, "map")
            DispatchQueue.main.async  {
                self.marqueeTextValues.contentMode = .center
                self.marqueeTextValues.baselineAdjustment = .alignCenters
                self.marqueeTextValues.attributedText =  map?.first!
                self.marqueeTextValues.speed = MarqueeLabel.SpeedLimit.duration(300)
                self.marqueeTextValues.type = .continuous
                self.marqueeTextValues.forceScrolling = false
                self.marqueeTextValues.animationCurve = .linear
                self.marqueeTextValues.allowsDefaultTighteningForTruncation = false
//                self.marqueeTextValues.leadingBuffer = 30
//                self.marqueeTextValues.trailingBuffer = 30

        
            }
        })
    }
    
    
    @objc func tick() {
        let foramt = DateFormatter()
        foramt.dateFormat = "HH : mm"
        dateTimeText.text = foramt.string(from: Date())
        dateTimeText.textColor = .black
    }
    
    
    private func playVideo() {
        let path = Bundle.main.path(forResource: "splash_background", ofType: "mp4")!
        let videoURL = URL(fileURLWithPath: path)
        playerView.playerLayer.videoGravity = .resizeAspect
        playerView.play(for: videoURL)
        NotificationCenter.default
            .addObserver(self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
                         object: playerView.playerLayer.player?.currentItem
        )
    }
    
    
   @objc func playerDidFinishPlaying(_ note: NSNotification) {
       tickerFunc()
//       playerIndex += 1
       playVideoUrl()
//      checkPreload()
    }
    
    func playVideoUrl() {
        if !videosList.isEmpty {
            guard let videoURL = URL(string: self.videosList[playerIndex]) else { return }
            playerView.playerLayer.videoGravity = .resizeAspect
            playerView.play(for: videoURL)
            self.whiteLogo.isHidden = false
            self.tickerView.isHidden = false
            NotificationCenter.default
                .addObserver(self,
                selector: #selector(playerDidFinishPlaying1),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerView.playerLayer.player?.currentItem
            )
        }
        
    }
    
    @objc func playerDidFinishPlaying1(_ note: NSNotification) {
        playerIndex += 1
        playVideoUrl()
        checkPreload()
     }
    

    
    func getVideos(completion: @escaping ([String])-> ()) {
        let urlString = "https://tv.dire.it/api/Videos/getallvideos?page=0&size=10&category=all"
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) {data, res, err in
                if let data = data {
                    do {
                        let json = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String : Any]
                        let videos = json["videos"] as! NSArray
                        var frnd = [String]()
                        for val in videos {
                            if let vid = val as? [String : Any] {
                                frnd.append(vid["mp4url"] as! String)
                            }
                        }
                       print(frnd)
                      completion(frnd)
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }.resume()
        }
    }
    
    func getLive(completion: @escaping (Bool)-> ()) {
        let urlString = "https://tv.dire.it/api/Videos/getlivestatus"
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) {data, res, err in
                if let data = data {
                    do {
                        let json = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String : Any]
                        let isLive = json["isLive"] as! Bool
                      completion(isLive)
                        
                        
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }.resume()
        }
    }
    
    
    func fetchTickerData(completion: @escaping (TickerData)-> ()) {
        let urlString = "https://api.rss2json.com/v1/api.json?rss_url=https://www.dire.it/feed/ultimenews&api_key=nfrmkxownjdzgy2n5vtuwkhav7w8ivakwqyz6wtj&count=100"
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) {data, res, err in
                if let data = data {
                    do {
                        let jsonDecoder = JSONDecoder()
                        let responseModel = try jsonDecoder.decode(TickerData.self, from: data)
                        completion(responseModel)
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }.resume()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
           let menuPressRecognizer = UITapGestureRecognizer()
           menuPressRecognizer.addTarget(self, action: #selector(self.menuButtonAction(recognizer:)))
        menuPressRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
           self.view.addGestureRecognizer(menuPressRecognizer)
    }
    
    @objc func menuButtonAction(recognizer:UITapGestureRecognizer) {
        exit(EXIT_SUCCESS)
    }

}



/*
 Future<List<String>> getVideos() async {
     try {
       final client = http.Client();
       final url = Uri.parse(
           'https://tv.dire.it/api/Videos/getallvideos?page=0&size=10&category=all');
       final response = await client.get(url);
       client.close();
       final data = convert.json.decode(response.body) as Map<String, dynamic>;
       final db = data['videos'] as List<dynamic>;
       final videoURL = db.map((e) => e['mp4url'].toString()).toList();
       List<String> bulkURl = List<String>.from(videoURL);
       return bulkURl;
     } catch (e) {
       setState(() {
         isOffline = true;
       });
       rethrow;
     }
   }
 
 Future getLive() async {
     try {
       final client = http.Client();
       const url = 'https://tv.dire.it/api/Videos/getlivestatus';
       final uri = Uri.parse(url);
       final response = await client.get(uri);
       client.close();
       final data = convert.json.decode(response.body) as Map<String, dynamic>;
       final db = data['isLive'] as bool;
       return db;
     } catch (e) {
       rethrow;
     }
   }

   Future fetchTickerData() async {
     try {
       final client = http.Client();
       const firsturl = 'https://www.dire.it/feed/ultimenews';
       const finalurl =
           'https://api.rss2json.com/v1/api.json?rss_url=${firsturl}&api_key=nfrmkxownjdzgy2n5vtuwkhav7w8ivakwqyz6wtj&count=100';
       final url = Uri.parse(finalurl);
       final response = await client.get(url);
       client.close();
       final data = convert.json.decode(response.body) as Map<String, dynamic>;
       setState(() {
         isOffline = false;
         tickerData = data['items'];
       });
     } catch (e) {
       setState(() {
         isOffline = true;
       });
       rethrow;
     }
   }
 */


struct TickerData : Codable {
    let status : String?
    let feed : Feed?
    let items : [Items]?

    enum CodingKeys: String, CodingKey {

        case status = "status"
        case feed = "feed"
        case items = "items"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decodeIfPresent(String.self, forKey: .status)
        feed = try values.decodeIfPresent(Feed.self, forKey: .feed)
        items = try values.decodeIfPresent([Items].self, forKey: .items)
    }

}
struct Items : Codable {
    let title : String?
    let pubDate : String?
    let link : String?
    let guid : String?
    let author : String?
    let thumbnail : String?
    let description : String?
    let content : String?
    let enclosure : Enclosure?
    let categories : [String]?

    enum CodingKeys: String, CodingKey {

        case title = "title"
        case pubDate = "pubDate"
        case link = "link"
        case guid = "guid"
        case author = "author"
        case thumbnail = "thumbnail"
        case description = "description"
        case content = "content"
        case enclosure = "enclosure"
        case categories = "categories"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        pubDate = try values.decodeIfPresent(String.self, forKey: .pubDate)
        link = try values.decodeIfPresent(String.self, forKey: .link)
        guid = try values.decodeIfPresent(String.self, forKey: .guid)
        author = try values.decodeIfPresent(String.self, forKey: .author)
        thumbnail = try values.decodeIfPresent(String.self, forKey: .thumbnail)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        content = try values.decodeIfPresent(String.self, forKey: .content)
        enclosure = try values.decodeIfPresent(Enclosure.self, forKey: .enclosure)
        categories = try values.decodeIfPresent([String].self, forKey: .categories)
    }

}

struct Enclosure : Codable {
    let link : String?
    let type : String?

    enum CodingKeys: String, CodingKey {

        case link = "link"
        case type = "type"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        link = try values.decodeIfPresent(String.self, forKey: .link)
        type = try values.decodeIfPresent(String.self, forKey: .type)
    }

}

struct Feed : Codable {
    let url : String?
    let title : String?
    let link : String?
    let author : String?
    let description : String?
    let image : String?

    enum CodingKeys: String, CodingKey {

        case url = "url"
        case title = "title"
        case link = "link"
        case author = "author"
        case description = "description"
        case image = "image"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        link = try values.decodeIfPresent(String.self, forKey: .link)
        author = try values.decodeIfPresent(String.self, forKey: .author)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        image = try values.decodeIfPresent(String.self, forKey: .image)
    }

}


extension UIFont {

    public enum RobotoCondensed: String {
        case bold = "-Bold"
        case boldItalic = "-BoldItalic"
        case italic = "-Italic"
        case regular = "-Regular"
        case light = "-Light"
        case lightItalic = "-LightItalic"
    }

    static func Robotos(_ type: RobotoCondensed = .regular, size: CGFloat = 17) -> UIFont {
        return UIFont(name: "RobotoCondensed\(type.rawValue)", size: size) ?? UIFont.systemFont(ofSize: 17, weight: .regular)
    }

    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }

    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }

}


var long_text = "India, officially the Republic of India (Hindi: Bhārat Gaṇarājya),[26] is a country in South Asia. It is the seventh-largest country by area, the second-most populous country, and the most populous democracy in the world. Bounded by the Indian Ocean on the south, the Arabian Sea on the southwest, and the Bay of Bengal on the southeast, it shares land borders with Pakistan to the west;[f] China, Nepal, and Bhutan to the north; and Bangladesh and Myanmar to the east. In the Indian Ocean, India is in the vicinity of Sri Lanka and the Maldives; its Andaman and Nicobar Islands share a maritime border with Thailand, Myanmar and Indonesia. Modern humans arrived on the Indian subcontinent from Africa no later than 55,000 years ago.[27][28][29] Their long occupation, initially in varying forms of isolation as hunter-gatherers, has made the region highly diverse, second only to Africa in human genetic diversity.[30] Settled life emerged on the subcontinent in the western margins of the Indus river basin 9,000 years ago, evolving gradually into the Indus Valley civilisation of the third millennium BCE.[31] By 1200 BCE, an archaic form of Sanskrit, an Indo-European language, had diffused into India from the northwest,[32][33] unfolding as the language of the Rigveda, and recording the dawning of Hinduism in India.[34] The Dravidian languages of India were supplanted in the northern and western regions.[35] By 400 BCE, stratification and exclusion by caste had emerged within Hinduism,[36] and Buddhism and Jainism had arisen, proclaiming social orders unlinked to heredity.[37] Early political consolidations gave rise to the loose-knit Maurya and Gupta Empires based in the Ganges Basin.[38] Their collective era was suffused with wide-ranging creativity,[39] but also marked by the declining status of women,[40] and the incorporation of untouchability into an organised system of belief.[g][41] In South India, the Middle kingdoms exported Dravidian-languages scripts and religious cultures to the kingdoms of Southeast Asia.[42] In the early medieval era, Christianity, Islam, Judaism, and Zoroastrianism became established on India's southern and western coasts.[43] Muslim armies from Central Asia intermittently overran India's northern plains,[44] eventually founding the Delhi Sultanate, and drawing northern India into the cosmopolitan networks of medieval Islam.[45] In the 15th century, the Vijayanagara Empire created a long-lasting composite Hindu culture in south India.[46] In the Punjab, Sikhism emerged, rejecting institutionalised religion.[47] The Mughal Empire, in 1526, ushered in two centuries of relative peace,[48] leaving a legacy of luminous architecture.[h][49] Gradually expanding rule of the British East India Company followed, turning India into a colonial economy, but also consolidating its sovereignty.[50] British Crown rule began in 1858. The rights promised to Indians were granted slowly,[51][52] but technological changes were introduced, and ideas of education, modernity and the public life took root.[53] A pioneering and influential nationalist movement emerged, which was noted for nonviolent resistance and became the major factor in ending British rule.[54][55] In 1947 the British Indian Empire was partitioned into two independent dominions,[56][57][58][59] a Hindu-majority Dominion of India and a Muslim-majority Dominion of Pakistan, amid large-scale loss of life and an unprecedented migration.[60] India has been a federal republic since 1950, governed through a democratic parliamentary system. It is a pluralistic, multilingual and multi-ethnic society. India's population grew from 361 million in 1951 to 1.211 billion in 2011.[61] During the same time, its nominal per capita income increased from US$64 annually to US$1,498, and its literacy rate from 16.6% to 74%. From being a comparatively destitute country in 1951,[62] India has become a fast-growing major economy and a hub for information technology services, with an expanding middle class.[63] It has a space programme which includes several planned or completed extraterrestrial missions. Indian movies, music, and spiritual teachings play an increasing role in global culture.[64] India has substantially reduced its rate of poverty, though at the cost of increasing economic inequality.[65] India is a nuclear-weapon state, which ranks high in military expenditure. It has disputes over Kashmir with its neighbours, Pakistan and China, unresolved since the mid-20th century.[66] Among the socio-economic challenges India faces are gender inequality, child malnutrition,[67] and rising levels of air pollution.[68] India's land is megadiverse, with four biodiversity hotspots.[69] Its forest cover comprises 21.7% of its area.[70] India's wildlife, which has traditionally been viewed with tolerance in India's culture,[71] is supported among these forests, and elsewhere, in protected habitats."
