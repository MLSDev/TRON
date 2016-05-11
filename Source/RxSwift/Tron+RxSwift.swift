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
import RxSwift
import Alamofire

extension APIRequest {
    
    /**
     Creates on Observable of success Model type. It starts a request each time it's subscribed to.
     
     - returns: Observable<ModelType>
     */
    public func rxResult() -> Observable<Model.ModelType> {
        return Observable.create({ observer in
            let token = self.performWithSuccess({ result in
                observer.onNext(result)
                observer.onCompleted()
            }, failure: { error in
                observer.onError(error)
            })
            return AnonymousDisposable {
                token?.cancel()
            }
        })
    }
}

extension MultipartAPIRequest {
    
    /**
     Creates a tuple of observables, first for progress reporting, second for parsed result reporting
     
     - returns - tuple of Observable<Progress> and Observable<ModelType>
     */
    public func rxUpload() -> (progress: Observable<Progress>, result: Observable<Model.ModelType>) {
        var requestToken : Alamofire.Request?
        
        var progressObserver : AnyObserver<Progress>?
        let progressObservable = Observable<Progress>.create { observer in
            progressObserver = observer
            return NopDisposable.instance
        }.startWith((0,0,0))
        
        var resultObserver : AnyObserver<Model.ModelType>?
        let resultObservable = Observable<Model.ModelType>.create { observer in
            resultObserver = observer
            return AnonymousDisposable {
                requestToken?.cancel()
            }
        }
        performWithSuccess({ result in
            resultObserver?.onNext(result)
            resultObserver?.onCompleted()
            }, failure: { error in
                resultObserver?.onError(error)
            }, progress: { progress in
                progressObserver?.onNext(progress)
                if progress.totalBytesWritten >= progress.totalBytesExpectedToWrite {
                    progressObserver?.onCompleted()
                }
        }) { token in
            requestToken = token
        }
        
        return (progressObservable, resultObservable)
    }
}