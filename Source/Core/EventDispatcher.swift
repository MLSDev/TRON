//
//  EventDelivery.swift
//  TRON
//
//  Created by Denys Telezhkin on 28.01.16.
//  Copyright © 2015 - present MLSDev. All rights reserved.
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

/// Class, responsible for dispatching events on different GCD queues.
public class EventDispatcher {

    /// Queue, used for processing response, received from the server. Defaults to QOS_CLASS_USER_INITIATED queue
    public var processingQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
    
    /// Queue, used to deliver success completion blocks. Defaults to dispatch_get_main_queue().
    public var successDeliveryQueue = dispatch_get_main_queue()
    
    /// Queue, used to deliver failure completion blocks. Defaults to dispatch_get_main_queue().
    public var failureDeliveryQueue = dispatch_get_main_queue()
    
    func processResponse(processingBlock: Void -> Void) {
        dispatch_async(processingQueue, processingBlock)
    }
    
    func deliverSuccess(deliveryBlock : Void -> Void) {
        dispatch_async(successDeliveryQueue, deliveryBlock)
    }
    
    func deliverFailure(deliveryBlock: Void -> Void) {
        dispatch_async(failureDeliveryQueue, deliveryBlock)
    }
}