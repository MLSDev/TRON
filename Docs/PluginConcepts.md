While global plugins are cool to monitor all network requests in an app, local plugins for concrete APIRequest can be incredibly powerful, because you can be certain, that plugin is working with a single APIRequest.

Here are some examples of cool local plugins:

* Showing progress HUD while request is Loading
* Blocking UIButton or UIBarButtonItem from being tapped one more time while request is in progress

## MMProgressHUD

Here's simple `MMProgressHUD` plugin, that allows showing progress HUD while request is loading:

```swift
import Foundation
import TRON
import MMProgressHUD

class MMProgressHUDPlugin : Plugin {
    var progressTitle: String?
    var successTitle : String
    var errorTitle: String?

    init(progress: String, success: String, errorTitle: String?) {
        self.progressTitle = progress
        self.successTitle = success
        self.errorTitle = errorTitle
    }

    func willSendRequest(request: NSURLRequest?) {
        MMProgressHUD.showWithTitle(progressTitle)
    }

    func requestDidReceiveResponse(response: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?))
    {
        if let error = response.3 {
            MMProgressHUD.dismissWithError(errorTitle ?? String(error.code))
        } else {
            MMProgressHUD.dismissWithSuccess(successTitle)
        }
    }
}

extension APIRequest {
    func progressTitle(title: String, successTitle: String = "Success", errorTitle: String? = nil) -> Self {
        let progressPlugin = MMProgressHUDPlugin(progress: title,
            success: successTitle, errorTitle: errorTitle)
        plugins.append(progressPlugin)
        return self
    }
}

extension MultipartAPIRequest {
    func progressTitle(title: String, successTitle: String = "Success", errorTitle: String? = nil) -> Self {
        let progressPlugin = MMProgressHUDPlugin(progress: title,
            success: successTitle, errorTitle: errorTitle)
        plugins.append(progressPlugin)
        return self
    }
}
```

Example usage:

```swift
API.User.Login("user@gmail.com", password: "foobar").progressTitle("Logging in...").performWithSuccess({ user in
    print("user logged in")
})
```

This way progress reporting is built-in into our loading system and switching from `MMProgressHUD` to `MBProgressHUD` for example will take minutes of our time instead of hours.


## UserInteractionBlockingPlugin

Idea of plugin is simple: let's say you have, for example, like button. When user taps, you should send a like request. However, you may also need to prevent user from tapping again, and sending one more request. This is where this plugin comes in:

```swift
import Foundation
import TRON

protocol UserInteractionBlockable : class
{
    var userInteractionEnabled : Bool { get set }
}

extension UIView : UserInteractionBlockable {}
extension UIBarButtonItem : UserInteractionBlockable {
    var userInteractionEnabled : Bool {
        get { return enabled }
        set { enabled = newValue }
    }
}

class UserInteractionBlockingPlugin : Plugin
{
    let blockable: UserInteractionBlockable

    init(blockable: UserInteractionBlockable) {
        self.blockable = blockable
    }

    func willSendRequest(request: NSURLRequest?) {
        blockable.userInteractionEnabled = false
    }

    func requestDidReceiveResponse(response: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?)) {
        blockable.userInteractionEnabled = true
    }
}

extension APIRequest
{
    func blockElement(blockable: UserInteractionBlockable) -> Self
    {
        let plugin = UserInteractionBlockingPlugin(blockable: blockable)
        plugins.append(plugin)
        return self
    }
}

extension MultipartAPIRequest {
    func blockElement(blockable: UserInteractionBlockable) -> Self
    {
        let plugin = UserInteractionBlockingPlugin(blockable: blockable)
        plugins.append(plugin)
        return self
    }
}
```

Example usage:

```swift
@IBAction func likesButtonTapped(sender: UIButton) {
    let request = post.isLiked ? API.Post.unlike(post) : API.Post.like(post)
    request.blockElement(sender)
    request.performWithSuccess({ updatedPost in
        post.isLiked = updatedPost.isLiked
        post.likesCount = post.likesCount
    })
}
```
