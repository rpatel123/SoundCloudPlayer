import UIKit
import AVFoundation
import AVKit

class PlayerViewController: UIViewController {
    var tracks: [Track]!
    var scAPI: SoundCloudAPI!

    var currentIndex: Int!
    var player: AVQueuePlayer!
    var trackImageView: UIImageView!

    var playPauseButton: UIButton!
    var nextButton: UIButton!
    var previousButton: UIButton!

    var artistLabel: UILabel!
    var titleLabel: UILabel!
    var didPlay: [Track]!
    
    var trackCurr: URL! = nil


    var paused = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.white

        scAPI = SoundCloudAPI()
        scAPI.loadTracks(didLoadTracks)
        self.didPlay = []
        currentIndex = 0

        player = AVQueuePlayer()

        loadVisualElements()
        loadPlayerButtons()
    }

    func loadVisualElements() {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let offset = height - width


        trackImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0,
                                                   width: width, height: width))
        trackImageView.contentMode = UIViewContentMode.scaleAspectFill
        trackImageView.clipsToBounds = true
        view.addSubview(trackImageView)

        titleLabel = UILabel(frame: CGRect(x: 0.0, y: width + offset * 0.15,
                                           width: width, height: 20.0))
        titleLabel.textAlignment = NSTextAlignment.center
        view.addSubview(titleLabel)

        artistLabel = UILabel(frame: CGRect(x: 0.0, y: width + offset * 0.25,
                                            width: width, height: 20.0))
        artistLabel.textAlignment = NSTextAlignment.center
        artistLabel.textColor = UIColor.gray
        view.addSubview(artistLabel)
    }


    func loadPlayerButtons() {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let offset = height - width

        let playImage = UIImage(named: "play")?.withRenderingMode(.alwaysTemplate)
        let pauseImage = UIImage(named: "pause")?.withRenderingMode(.alwaysTemplate)
        let nextImage = UIImage(named: "next")?.withRenderingMode(.alwaysTemplate)
        let previousImage = UIImage(named: "previous")?.withRenderingMode(.alwaysTemplate)

        playPauseButton = UIButton(type: UIButtonType.custom)
        playPauseButton.frame = CGRect(x: width / 2.0 - width / 30.0,
                                       y: width + offset * 0.5,
                                       width: width / 15.0,
                                       height: width / 15.0)
        playPauseButton.setImage(playImage, for: UIControlState())
        playPauseButton.setImage(pauseImage, for: UIControlState.selected)
        playPauseButton.addTarget(self, action: #selector(playOrPauseTrack),
                                  for: .touchUpInside)
        view.addSubview(playPauseButton)

        previousButton = UIButton(type: UIButtonType.custom)
        previousButton.frame = CGRect(x: width / 2.0 - width / 30.0 - width / 5.0,
                                      y: width + offset * 0.5,
                                      width: width / 15.0,
                                      height: width / 15.0)
        previousButton.setImage(previousImage, for: UIControlState())
        previousButton.addTarget(self, action: #selector(previousTrackTapped(_:)),
                                 for: UIControlEvents.touchUpInside)
        view.addSubview(previousButton)

        nextButton = UIButton(type: UIButtonType.custom)
        nextButton.frame = CGRect(x: width / 2.0 - width / 30.0 + width / 5.0,
                                  y: width + offset * 0.5,
                                  width: width / 15.0,
                                  height: width / 15.0)
        nextButton.setImage(nextImage, for: UIControlState())
        nextButton.addTarget(self, action: #selector(nextTrackTapped(_:)),
                             for: UIControlEvents.touchUpInside)
        view.addSubview(nextButton)

    }

    func loadTrackElements() {
        let track = tracks[currentIndex]
        asyncLoadTrackImage(track)
        titleLabel.text = track.title
        artistLabel.text = track.artist
    }


    
    func playOrPauseTrack(_ sender: UIButton) {
        let path = Bundle.main.path(forResource: "Info", ofType: "plist")
        let clientID = NSDictionary(contentsOfFile: path!)?.value(forKey: "client_id") as! String
        let track = tracks[currentIndex]
        let url = URL(string: "https://api.soundcloud.com/tracks/\(track.id as Int)/stream?client_id=\(clientID)")!
        // FILL ME IN
        
        if trackCurr != url {
            let newTrack = AVPlayerItem(url: url);
            player = AVQueuePlayer(playerItem: newTrack);
        }
        
        trackCurr = url;
        
        if player.rate != 0 {
            let newImage = UIImage(named: "play")
            playPauseButton.setImage(newImage, for: UIControlState.normal)
            player.pause()
        } else {
            let newImage = UIImage(named: "pause")
            playPauseButton.setImage(newImage, for: UIControlState.normal)
            player.play()
        }

    }


    func nextTrackTapped(_ sender: UIButton) {
        if tracks.count-1 > currentIndex {
            currentIndex = currentIndex + 1;
            loadTrackElements();
            let path = Bundle.main.path(forResource: "Info", ofType: "plist")
            let clientID = NSDictionary(contentsOfFile: path!)?.value(forKey: "client_id") as! String
            let track = tracks[currentIndex];
            let url = URL(string: "https://api.soundcloud.com/tracks/\(track.id as Int)/stream?client_id=\(clientID)")!
            let newTrack = AVPlayerItem(url: url);
            player = AVQueuePlayer(playerItem: newTrack);
            trackCurr = url;
        }
        player.play()

    }



    func previousTrackTapped(_ sender: UIButton) {
        if (Int(player.currentTime().value) / Int(player.currentTime().timescale)) > 3 {
            player.seek(to: CMTime(seconds: 0, preferredTimescale: 1));
        }
        else {
            currentIndex = currentIndex - 1;
            loadTrackElements();
            let path = Bundle.main.path(forResource: "Info", ofType: "plist")
            let clientID = NSDictionary(contentsOfFile: path!)?.value(forKey: "client_id") as! String
            let track = tracks[currentIndex];
            let url = URL(string: "https://api.soundcloud.com/tracks/\(track.id as Int)/stream?client_id=\(clientID)")!
            let newTrack = AVPlayerItem(url: url);
            player = AVQueuePlayer(playerItem: newTrack);
            trackCurr = url;
        }
        player.play();
    }


    func asyncLoadTrackImage(_ track: Track) {
        let url = URL(string: track.artworkURL)
        let session = URLSession(configuration: URLSessionConfiguration.default)

        let task = session.dataTask(with: url!) {(data, response, error) -> Void in
            if error == nil {
                let image = UIImage(data: data!)
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                    DispatchQueue.main.async {
                        self.trackImageView.image = image
                    }
                }
            }
        }
        task.resume()
    }
    
    func didLoadTracks(_ tracks: [Track]) {
        self.tracks = tracks
        loadTrackElements()
    }
}

