
import Foundation

// MARK: Bulletin

extension BHHybridPlayer {
    
    func fetchInteractive(completion: @escaping (CommonResult) -> Void) {
        guard let bulletin = post?.bulletin else {
            BHLog.p("post bulletin is empty. Nothing to load")
            return
        }

        BHLog.p("\(#function), id: \(bulletin.id)")

        bulletinManager.fetch(bulletin.id) { response in
            switch response {
            case .success:
                self.observersContainer.notifyObserversAsync {
                    $0.hybridPlayerDidChangeBulletin(self)
                }
                completion(.success)

            case .failure(error: let e):
                BHLog.w("Bulletin load failed \(e.localizedDescription)")
                completion(.failure(error: e))
            }
        }
    }

    func fetchBulletin() {
        guard let bulletin = post?.bulletin else {
            BHLog.p("post bulletin is empty. Nothing to load")
            return
        }

        BHLog.p("\(#function), id: \(bulletin.id)")

        bulletinManager.getBulletin(bulletin.id) { response in
            switch response {
            case .success(bulletin: _):
                self.observersContainer.notifyObserversAsync {
                    $0.hybridPlayerDidChangeBulletin(self)
                }
            case .failure(error: let e):
                BHLog.w("Bulletin load failed \(e.localizedDescription)")
            }
        }
    }

    func fetchBulletinVideoEvents() {
        guard let bulletin = post?.bulletin else {
            BHLog.p("post bulletin is empty. Nothing to load")
            return
        }

        BHLog.p("\(#function), id: \(bulletin.id)")

        bulletinManager.getVideoEvents(bulletin.id) { response in
            switch response {
            case .success(events: _):
                self.observersContainer.notifyObserversAsync {
                    $0.hybridPlayerDidChangeBulletin(self)
                }
            case .failure(error: let e):
                BHLog.w("Bulletin video events load failed \(e.localizedDescription)")
            }
        }
    }

    func fetchBulletinMessages() {
        guard let bulletin = post?.bulletin else {
            BHLog.p("post bulletin is empty. Nothing to load")
            return
        }

        BHLog.p("\(#function), id: \(bulletin.id)")

        bulletinManager.getMessages(bulletin.id) { response in
            switch response {
            case .success(events: _):
                self.observersContainer.notifyObserversAsync {
                    $0.hybridPlayerDidChangeBulletin(self)
                }
            case .failure(error: let e):
                BHLog.w("Bulletin message events load failed \(e.localizedDescription)")
            }
        }
    }

    func fetchBulletinLayoutEvents() {
        guard let bulletin = post?.bulletin else {
            BHLog.p("post bulletin is empty. Nothing to load")
            return
        }

        BHLog.p("\(#function), id: \(bulletin.id)")

        bulletinManager.getLayoutEvents(bulletin.id) { response in
            switch response {
            case .success(events: _):
                self.observersContainer.notifyObserversAsync {
                    $0.hybridPlayerDidChangeBulletin(self)
                }
            case .failure(error: let e):
                BHLog.w("Bulletin layout events load failed \(e.localizedDescription)")
            }
        }
    }
}

// MARK: Posts

extension BHHybridPlayer {
    
    func getPlaybackOffset() {
        BHLog.p("\(#function)")

        guard let item = playerItem else { return }
        
        postsManager.getPlaybackOffset(item.post.postId, offset: item.position) { response in
            switch response {
            case .success(offset: let playbackOffset):
                let position = playbackOffset.offset
                
                BHLog.p("BHPlaybackOffset loaded, offset: \(playbackOffset.offset)")

                if position != -1 && position != item.position {
                    self.seek(to: position)
                }
            case .failure(error: let e):
                BHLog.w("BHPlaybackOffset load failed \(e.localizedDescription)")
            }
        }
    }
    
    func postPlaybackOffset() {
        BHLog.p("\(#function)")
        
        guard let player = mediaPlayer else { return }
        guard let item = playerItem else { return }
        guard let validPost = post else { return }
        
        let position = player.playerCurrentTime()
        let duration = player.playerDuration()
        let isCompleted = validPost.isPlaybackCompleted || ((duration - position) < 5)
        
        postsManager.postPlaybackOffset(item.post.postId, position: player.playerCurrentTime(), playbackCompleted: isCompleted) { response in
            switch response {
            case .success(offset: let playbackOffset):
                BHLog.p("BHPlaybackOffset posted, offset: \(playbackOffset.offset), completed: \(playbackOffset.playbackCompleted)")
                self.post?.isPlaybackCompleted = playbackOffset.playbackCompleted
                
                if playbackOffset.playbackCompleted, let item = self.playerItem {
                    self.observersContainer.notifyObserversAsync {
                        $0.hybridPlayer(self, playerItem: item, playbackCompleted: playbackOffset.playbackCompleted)
                    }
                    
                    BHNetworkManager.shared.updatePlaybackCompleted(validPost.id, completed: playbackOffset.playbackCompleted)
                    BHDownloadsManager.shared.updatePlaybackCompleted(validPost.id, completed: playbackOffset.playbackCompleted)
                }
            case .failure(error: let e):
                BHLog.w("BHPlaybackOffset post failed \(e.localizedDescription)")
            }
        }
    }

}


