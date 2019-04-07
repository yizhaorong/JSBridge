//
//  JSBridge_JS.m
//  WebViewDemo
//
//  Created by yizhaorong on 2019/4/6.
//  Copyright © 2019 yizhaorong. All rights reserved.
//

#import "JSBridge_JS.h"

#define CONVERT_TO_STRING(x) @#x;

static NSString *const kWKSendFunction = CONVERT_TO_STRING(
    function _sendAsyncMessage(message, responseCallback) {
     if (responseCallback && typeof (responseCallback) === 'function') {
         var callbackID = _getUUID();
         message.callbackID = callbackID;
         message.callbackFunction = 'window.JSBridge.callbackDispatcher';
         responseCallbacks[callbackID] = responseCallback;
     }
     
     try {
         window.webkit.messageHandlers.JSBridge.postMessage(message);
     } catch (error) {
         console.log('error native message');
     }
    }

    function _sendSyncMessage(message) {
     try {
         //将消息体直接JSON字符串化，调用Prompt()
         var resultjson = prompt(JSON.stringify(message));
         //直接用 = 接收 Prompt()的返回数据，JSON反解
         var resultObj = resultjson ? JSON.parse(resultjson) : {};
         return resultObj;
     } catch (error) {
         console.log('error native message');
     }
    }
)

static NSString *const kSendFunction = CONVERT_TO_STRING(
    function _sendAsyncMessage(message, responseCallback) {
     if (responseCallback && typeof (responseCallback) === 'function') {
         var callbackID = _getUUID();
         message.callbackID = callbackID;
         message.callbackFunction = 'window.JSBridge.callbackDispatcher';
         responseCallbacks[callbackID] = responseCallback;
     }
     
     try {
         window.JSBridge_postAsyncMessage(message);
     } catch (error) {
         console.log('error native message');
     }
    }

    function _sendSyncMessage(message) {
     try {
         var resultJson = window.JSBridge_postSyncMessage(message);
         return JSON.parse(resultJson);
     } catch (error) {
         console.log('error native message');
     }
    }
)

static NSString *const kBridgeFormatString = CONVERT_TO_STRING(
   (function () {
        if (window.JSBridge) {
            return;
        }
    
        window.JSBridge = {
        registerHandler: registerHandler,
        callHandler: callHandler,
        syncCallHandler: syncCallHandler,
        callbackDispatcher: callbackDispatcher,
        onListenEvent: onListenEvent,
        eventDispatcher: eventDispatcher,
        callJSHandler: callJSHandler
        };
    
        var messageHandlers = {};
        var responseCallbacks = {};
        var eventCallMap = {};
    
        function registerHandler(handlerName, handler) {
            messageHandlers[handlerName] = handler;
        }
    
        function callHandler(handlerName, data, responseCallback) {
            if (arguments.length == 2 && typeof data == 'function') {
                responseCallback = data;
                data = null;
            }
            _sendAsyncMessage({ "handlerName": handlerName, "params": data }, responseCallback);
        }
    
        function syncCallHandler(handlerName, data) {
            return _sendSyncMessage({ "handlerName": handlerName, "params": data });
        }
    
        function callbackDispatcher(callbackID, resultjson) {
            var handler = responseCallbacks[callbackID];
            if (handler && typeof (handler) === 'function') {
                // JSON.parse(resultjson)
                console.log(resultjson);
                var resultObj = resultjson ? JSON.parse(resultjson) : {};
                handler(resultObj);
                delete responseCallbacks[callbackID];
            }
        }
    
        function onListenEvent(eventId, handler) {
            var handlerList = eventCallMap[eventId];
            if (handlerList === undefined) {
                handlerList = [];
                eventCallMap[eventId] = handlerList;
            }
            if (handler !== undefined) {
                handlerList.push(handler);
            }
        }
    
        function eventDispatcher(eventId, resultjson) {
            var handlerList = eventCallMap[eventId];
            for (var key in handlerList) {
                if (handlerList.hasOwnProperty(key)) {
                    var handler = handlerList[key];
                    if (handler && typeof (handler) === 'function') {
                        var resultObj = resultjson ? JSON.parse(resultjson) : {};
                        handler(resultObj);
                    }
                }
            }
        }
    
        function callJSHandler(handlerName, data) {
            var handler = messageHandlers[handlerName];
            var result = handler(data);
            if (typeof (result) === 'object') {
                return JSON.stringify(result);
            } else if (typeof (result) === 'string') {
                return result;
            }
            return "";
        }
    
        %@
    
        function _S4() {
            return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
        }
    
        function _getUUID() {
            return (_S4() + _S4() + "-" + _S4() + "-" + _S4() + "-" + _S4() + "-" + _S4() + _S4() + _S4());
        }
    })();
)

NSString *JSBridge_js(BOOL isWKWebView) {
    static NSString *javascriptForUIWebView;
    static NSString *javascriptForWKWebView;
    if (isWKWebView) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            javascriptForWKWebView = [NSString stringWithFormat:kBridgeFormatString, kWKSendFunction];
        });
        return javascriptForWKWebView;
    } else {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            javascriptForUIWebView = [NSString stringWithFormat:kBridgeFormatString, kSendFunction];
        });
        return javascriptForUIWebView;
    }
}
