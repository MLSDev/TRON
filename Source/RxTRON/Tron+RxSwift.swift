//
//  Tron+RxSwift.swift
//  TRON
//
//  Created by Denys Telezhkin on 19.04.16.
//  Copyright © 2016 - present MLSDev. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import TRON
import RxSwift
import Alamofire

extension APIRequest {

    /**
     Creates on Observable of success Model type. It starts a request each time it's subscribed to.

     - returns: Observable<Model>
     */
    public func rxResult() -> Observable<Model> {
        return Observable.create({ observer in
            let token = self.perform(withSuccess: { result in
                observer.onNext(result)
                observer.onCompleted()
            }, failure: { error in
                observer.onError(error)
            })
            return Disposables.create {
                token.cancel()
            }
        })
    }
}

extension UploadAPIRequest {
    /**
     Creates on Observable of success Model type. It starts a request each time it's subscribed to.
     
     - returns: Observable<Model>
     */
    public func rxResult() -> Observable<Model> {
        return Observable.create({ observer in
            let token = self.perform(withSuccess: { result in
                observer.onNext(result)
                observer.onCompleted()
            }, failure: { error in
                observer.onError(error)
            })
            return Disposables.create {
                token.cancel()
            }
        })
    }
}

extension DownloadAPIRequest {
    /**
     Creates on Observable of success Model type. It starts a request each time it's subscribed to.
     
     - returns: Observable<Model>
     */
    public func rxResult() -> Observable<URL> {
        return Observable.create({ observer in
            let token = self.performCollectingTimeline(withCompletion: { response in
                if let url = response.fileURL {
                    observer.onNext(url)
                    observer.onCompleted()
                } else {
                    observer.onError(response.error ?? DownloadError(response))
                }
            })
            return Disposables.create {
                token.cancel()
            }
        })
    }
}
