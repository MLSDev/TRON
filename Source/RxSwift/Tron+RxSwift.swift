//
//  Tron+RxSwift.swift
//  TRON
//
//  Created by Denys Telezhkin on 19.04.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import RxSwift

extension APIRequest {
    public func rxResult() -> Observable<Model.ModelType> {
        return Observable.create({ [weak self] observer in
            let token = self?.performWithSuccess({ result in
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
    public func rxUpload() -> (progress: Observable<Progress>, result: Observable<Model.ModelType>) {
        var requestToken : RequestToken?
        
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