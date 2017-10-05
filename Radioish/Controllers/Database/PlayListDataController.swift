import CoreData
import Alamofire

class PlayListDataController {
    
    static let Instance = PlayListDataController()
    
    func checkIfRecent(post: Post) -> Int {
        var retVal = -1
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            playlist = try context.fetch(CD_Post.fetchRequest())
        }catch {
            print("Fetching failed")
        }
        
        
        for i in 0..<playlist.count {
            let tPost = playlist[i]
            if tPost.user_id == post.user.id {
                retVal = i
                let d1 = DateUtil.ParseStringDateToDouble(tPost.createdAt!)
                let d2 = DateUtil.ParseStringDateToDouble(post.meta.createdAt)
                if d1 >= d2 {
                    retVal = -2
                }
                return retVal
            }
        }
        return retVal
    }
    
    func updatePost(withCDPost retPost:CD_Post, post: Post) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        retPost.id = post.id
        retPost.audio = post.audio
        retPost.audio_local = post.audio
        retPost.commentsCount = Int32(post.commentsCount)
        retPost.commentedUsers = post.commentedUsers as NSArray
        retPost.createdAt = post.meta.createdAt
        
        retPost.likes = post.likes as NSArray
        retPost.playCount = Int32(post.playCount)
        retPost.postDescription = post.description
        retPost.title = post.title
        retPost.updatedAt = post.meta.updatedAt
        retPost.user_email = post.user.email
        retPost.user_id = post.user.id
        retPost.user_photo = post.user.photo
        retPost.user_fullName = post.user.fullName
        retPost.user_photoLocal = ""
        
        appDelegate.saveContext()
        
        downloadAudio(userId: retPost.user_id!, audioUrl: retPost.audio!, delegate: appDelegate, post: retPost)
    }
    
    func downloadAudio(userId: String, audioUrl: String, delegate: AppDelegate, post: CD_Post? = nil) {
        let destination : DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileUrl = documentsUrl.appendingPathComponent("\(userId).mp4")
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        Alamofire.download(audioUrl, to: destination).response { (response) in
            print(response)
            
            if response.error == nil, let filePath = response.destinationURL?.path {
                if let post = post {
                    post.audio_local = filePath
                }
                delegate.saveContext()
                print("\nFile Path: \(filePath)\n")
            }
        }
    }
    
    func convertPost(toCDPost post:Post) -> CD_Post {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let retPost = NSEntityDescription.insertNewObject(forEntityName: "CD_Post", into: managedContext) as! CD_Post
        
        self.updatePost(withCDPost: retPost, post: post)
        
        return retPost
    }
    
    func addPost(post: Post){
        let _ = PlayListDataController.Instance.convertPost(toCDPost: post)
    }
    
    func deletePost(post: CD_Post) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        managedContext.delete(post)
        appDelegate.saveContext()
    }
    
    func loadPlayList() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest : NSFetchRequest<CD_Post> = NSFetchRequest(entityName: "CD_Post")
//        let sortDescriptor = NSSortDescriptor(key: "user_fullName", ascending: true)
//        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            playlist = try context.fetch(fetchRequest)
        }catch {
            print("Fetching failed")
        }
    }
}
