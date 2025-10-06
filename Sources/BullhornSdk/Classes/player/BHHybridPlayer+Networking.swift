
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

        guard let validPost = post else { return }
        guard let validItem = playerItem else { return }
        
        let localOffset = BHOffsetsManager.shared.offset(for: validPost.id)
        let offset: Double = localOffset?.offset ?? 0
        let timestamp: Double = localOffset?.timestamp ?? 0

        if BHReachabilityManager.shared.isConnected(), manualPosition == 0, validItem.post.file == nil {
                                                
            postsManager.getPlaybackOffset(validPost.id, offset: offset, timestamp: timestamp.toMs()) { response in
                DispatchQueue.main.async {
                    switch response {
                    case .success(offset: let playbackOffset):
                        BHLog.p("BHPlaybackOffset loaded, offset: \(playbackOffset.offset)")
                        self.post?.updatePlaybackOffset(playbackOffset.offset, completed: playbackOffset.playbackCompleted)

                        let o = BHOffset(id: validPost.id, offset: playbackOffset.offset, timestamp: Date().timeIntervalSince1970, completed: playbackOffset.playbackCompleted)
                        BHOffsetsManager.shared.insertOrUpdateOffset(o)
                        
                        let position = playbackOffset.offset

                        if position > 0 && abs(position - validItem.position) > 12 {
                            self.seek(to: position)
                        }
                    case .failure(error: let e):
                        BHLog.w("BHPlaybackOffset load failed \(e.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func postPlaybackOffset() {
        BHLog.p("\(#function)")
        
        guard let player = mediaPlayer else { return }
        guard let item = playerItem else { return }
        guard var validPost = post else { return }
        
        let position = player.playerCurrentTime()
        let duration = player.playerDuration()
        let localPosition = ((duration - position) < 5) ? 0 : position
        let isCompleted = validPost.isPlaybackCompleted || ((duration - position) < 5)
        let timestamp = Date().timeIntervalSince1970
                
        postsManager.postPlaybackOffset(item.post.postId, position: position, playbackCompleted: isCompleted) { response in
            switch response {
            case .success(offset: let playbackOffset):
                BHLog.p("BHPlaybackOffset posted, offset: \(playbackOffset.offset), completed: \(playbackOffset.playbackCompleted)")
                
                if playbackOffset.playbackCompleted {
                    self.observersContainer.notifyObserversAsync {
                        $0.hybridPlayer(self, playerItem: item, playbackCompleted: playbackOffset.playbackCompleted)
                    }
                }
            case .failure(error: let e):
                BHLog.w("BHPlaybackOffset post failed \(e.localizedDescription)")
            }
        }
        
        let offset = BHOffset(id: item.post.postId, offset: localPosition, timestamp: timestamp, completed: isCompleted)
        BHOffsetsManager.shared.insertOrUpdateOffset(offset)
        
        post?.updatePlaybackOffset(localPosition, completed: isCompleted)
        BHNetworkManager.shared.updatePostPlayback(validPost.id, offset: localPosition, completed: isCompleted)
        BHExploreManager.shared.updatePostPlayback(validPost.id, offset: localPosition, completed: isCompleted)
        BHDownloadsManager.shared.updatePostPlayback(validPost.id, offset: localPosition, completed: isCompleted)
        BHFeedManager.shared.updatePostPlayback(validPost.id, offset: localPosition, completed: isCompleted)
        BHUserManager.shared.updatePostPlayback(validPost.id, offset: localPosition, completed: isCompleted)

        do {
            validPost.playbackOffset = localPosition
            validPost.isPlaybackCompleted = isCompleted
            let params = try validPost.toDictionary()
            if !DataBaseManager.shared.updatePost(with: validPost.id, params: params) {
                BHLog.w("Failed to save post playback offset to persistent storage")
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
        }
    }
    
    func getTranscript() {
        guard let validPost = post else { return }
        if !validPost.hasTranscript { return }
        
        BHLog.p("\(#function) for postId: \(validPost.id)")

        postsManager.getTranscript(validPost.id) { response in
            switch response {
            case .success(transcript: let transcript):
                self.transcript = transcript
                self.observersContainer.notifyObserversAsync {
                    $0.hybridPlayerDidChangeTranscript(self, transcript: transcript)
                }
            case .failure(error: let error):
                BHLog.w("\(#function) - failed to load transcript. Error: \(error)")
            }
        }
    }
    
    func getPlaylist() {
        guard let validPost = post else { return }

        BHLog.p("\(#function)")

        if BHReachabilityManager.shared.isConnected() {
            postsManager.getPlaybackQueuePosts(validPost.id) { response in
                switch response {
                case .success(posts: let posts):
                    self.addPostsToQueue(posts)
                case .failure(error: _):
                    break
                }
            }
        }
    }
}


