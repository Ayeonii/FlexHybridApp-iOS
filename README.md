
[한국어 README](https://github.com/Kyun-J/FlexHybridApp-iOS/blob/master/README-ko.md)

[Android Version](https://github.com/Kyun-J/FlexHybridApp-Android)

# FlexibleHybrid

FlexibleHybridApp is a framework that provides various convenience functions to develop HybridApp, such as implementing interfaces between Web and Native with promises.

# How to add framework

Add the following to podFile
```
    pod 'FlexHybridApp'
```

***iOS Deployment Target is 11.0.***
***The latest version is 0.3.7***

# Key features of Flex Framework interface
Basically, various functions have been added to WKWebView userContentController.
1. When the Native function is called on the Web, **Native function return is delivered to the Web as a Promise**.
2. When calling the Web function from Native, **the return value can be delivered to Async** from Web to Native.
3. Instead of WKWebViewConfiguration, you should use FlexComponent. FlexComponent includes WKWebViewConfiguration.
4. Unlike userContentController, **native behavior of each interface can be designated as a separate code block (Clouser)**.
5. When calling Native from the web, **Native code block operates in Background (DispatchQoS.background)**
6. By assigning BaseUrl to FlexWebView, **it is possible to prevent interface with other sites and pages**.

# Flex interface implementation
## Transferable Data Type
1. Like WKWebView userContentController, it can be transmitted in general data type, string, array, dictionary format.
2. It is possible to transfer JS Array to Swift Array\<Any> and JS Object to Swift Dictionary\<String, Any>.
3. When transferring data in the form of Array and Object, **the data contained in it must be one of the following data types**.

| JS | Swift |
|:--:|:--:|
| Number | Int, Float, Double |
| String | String, Character | 
| Boolean | Bool |
| Array [] | Array\<Any> |
| Object {} | Dictionary<String,Any> |
| undefined (Single Argument Only), null | nil |
| Error | FlexReject |

## WebToNative interface
The WebToNative interface has the following features.
1. Two types of normal interface, which passes values by function return, and action interface, which passes values by method call
2. Add interface code block in Clouser form
3. Clouser run on a separate Background (DispatchQoS.background)
4. The added interface can be called in the form of $flex.function on the web.
5. $flex Object can be used after window.onFlexLoad is called

### ***Nomal Interface***
Normal Interface is basically used as follows.
```swift
// in Swfit
flexComponent.setInterface("Normal") // "Normal" becomes the function name in Web JavaScript. 
{ arguments -> Any? in
    // arguments is Arguemnts Data from web. Type is Array<Any>
    // ["data1", 2, false]
    return "HiFlexWeb" // "HiFlexWeb" is passed to web in Promise pattern.
}
flexWebView = FlexWebView(frame: self.view.frame, component: flexComponent)
```
```js
// in web javascript
...
const res = await $flex.Normal("data1",2,false);
// res is "HiFlexWeb"
```
Specify the function name on the web as the first argument of `setInterface`, and the following Clouser becomes the block of code where the function operates.  
The arguments passed to Clouser are Array objects and contain the values passed when calling the function on the web.  
When passing a value from Clouser to web return, only [Transferable Data Type](#Transferable-Data-Type) is available.

### ***Action Interface***
The Action Interface is almost the same as the Normal Interface, but it sends the return value to the Web at the time of calling the `promiseReturn` method of the action object.
```swift
// in Kotlin
var mAction: FlexAction? = nil
...
flexComponent.setAction("Action")
{ (action, arguments) -> Void in
// arguments is Array<Any>, ["Who Are You?"]
// action is FlexAction Object
    mAction = action
}
flexWebView = FlexWebView(frame: self.view.frame, component: flexComponent)
...
// Returns to the Web when calling promiseReturn.
mAction?.promiseReturn(["FlexAction!!!",100]);
mAction = nil
```
```js
// in web javascript
....
const res = await $flex.Action("Who Are You?"); // Pending until promiseReturn is called...
// res is ["FlexAction!!!", 100]
```
The parameters of `promiseReturn` are only available for [Transferable Data Type](#Transferable-Data-Type).  
If the `promiseReturn` method is not called, the function in the web will be in a pending state, so be careful to call `promiseReturn` ***must*** when using the Action Interface.
If there is no passing value, you can call `resolveVoid()` instead. This is equivalent to `promiseReturn(nil)`.  
Also, the FlexAction object that had already called `promiseReturn` does not pass parameters to the web function even if `promiseReturn` is called repeatedly.

### ***Error Interface***
If you return the `FlexReject` object, you can send an error to the web.
```swift
// in swift
flexComponent.setInterface("errorTest")
{ arguments -> Any? in
    return FlexReject("errorTest")    
}
```
```js
// in js
...
try {
    const result = await $flex.errorTest();
} catch(e) {
    // e is Error("errorTest")
}
```
In `FlexAction`, you can easily pass an error by calling the `reject` function instead of `promiseReturn`.
```swift
// in swift
flexComponent.setAction("errorAction")
{ (action, arguments) -> Any? in
    action.reject("errorAction") // = action.promiseReturn(FlexReject("errorAction"))
}
```
```js
// in js
...
try {
    const result = await $flex.errorAction();
} catch(e) {
    // e is Error("errorAction")
}
```

## NativeToWeb Interface
The NativeToWeb interface has the following features.
1. If you add a function in the web's $flex.web Object, you can call the function through the `evalFlexFunc` method in Native FlexWebView.
2. After calling window.onFlexLoad (after creating $flex), you can add a function to $flex.web.
3. The $flex.web function can pass values to Native through regular return and promise return.

```js
window.onFlexLoad = () => {
    $flex.web.webFunc = (data) => {
        // data is ["data1","data2"]
        return data[0]; // "data1"
    }
    $flex.web.Return = () => {
        return Promise.resolve("this is promise")
    }
}
```
```swift
...
// call function, send data, get response
mFlexWebView.evalFlexFunc("webFunc",["data1","data2"]) // same as $flex.web.webFunc(["data1","data2"])
{ res -> Void in
    // res is "data1"
}
mFlexWebView.evalFlexFunc("Return") // same as $flex.web.Return()
{ res -> Void in
    // res is "this is promise"
}
// just call function
mFlexWebView.evalFlexFunc("Return")
// call function and send data
mFlexWebView.evalFlexFunc("webFunc",["data1","data2"])
```

# Native Class 
Describes the native classes of the framework including FlexWebView.
## FlexWebView
FlexWebView has the following features.
1. It was produced by inheriting WKWebView.
2. For asynchronous interface, FlexComponent should be used. FlexComponent includes WKWebViewConfiguration.
3. It can be used in combination with the existing WKWebView userContentController. (In this case, you cannot use the Promise pattern interface using $flex.)
4. Through the evalFlexFunc method, you can call functions in $flex.web.

### FlexWebView component
Same as WKWebView, except for the components below.
```swift
let component: FlexComponent // readOnly
var parentViewController: UIViewController? // readOnly
init (frame: CGRect, configuration: WKWebViewConfiguration) 
init (frame: CGRect, component: FlexComponent)
func evalFlexFunc(_ funcName: String)
func evalFlexFunc(_ funcName: String, _ returnAs: @escaping (_ data: Any?) -> Void)
func evalFlexFunc(_ funcName: String, sendData: Any)
func evalFlexFunc(_ funcName: String, sendData: Any, _ returnAs: @escaping (_ data: Any?) -> Void)
```
For usage of evalFlexFunc, refer to [NativeToWeb interface](#NativeToWeb-interface).

## FlexComponent
FlexComponent replaces WKWebViewConfiguration and has the following features.
1. It includes WKWebViewConfiguration, and WKWebViewConfiguration of FlexComponent is applied to FlexWebView.
2. Add asynchronous interface between Native and Web to FlexWebView through setInterface, setAction.
3. By setting the BaseUrl, you can set the interface to native only on the specified page.
4. You can add multiple settings to the $ flex Object.

### BaseUrl Setting
$flex Object can be used only in the page containing the configured BaseUrl.  
If you don't set BaseUrl, you can use $flex Object on any page.  
Once set, the BaseUrl cannot be modified again.
```swift
func setBaseUrl(_ url: String)
var BaseUrl: String? // readOnly
```

### WebToNative Interface Setting
Add an interface to the FlexWebView.  
For details, refer to [WebToNavite interface](#WebToNative-interface).
```swift
func setInterface(_ name: String, _ action: @escaping (_ arguments: Array<Any?>?) -> Any?)
func setAction(_ name: String, _ action: @escaping (_ action: FlexAction, _ arguments: Array<Any?>?) -> Void?)
```

### call NativeToWeb Interface
Call the NativeToWeb interface.
```swift
func evalFlexFunc(_ funcName: String)
func evalFlexFunc(_ funcName: String, _ returnAs: @escaping (_ data: Any?) -> Void)
func evalFlexFunc(_ funcName: String, sendData: Any)
func evalFlexFunc(_ funcName: String, sendData: Any, _ returnAs: @escaping (_ data: Any?) -> Void)
```
For usage of evalFlexFunc, refer to [NativeToWeb interface](#NativeToWeb-interface).

### Other FlexComponent components
```swift
var FlexWebView: FlexWebView? // readOnly
var configration: WKWebViewConfiguration // readOnly
var parentViewController: UIViewController? // readOnly
```

## FlexAction
Generated when the WebToNative interface added by setAction is called.  
The available methods are as follows, and only the promiseReturn function is responsible for passing the return value to the web.  
resolveVoid passes a nil value (same as promiseReturn(nil))  
The reject function automatically creates and passes a FlexReject object (same as promiseReturn(FlexReject)).
```swift
func promiseReturn(_ response: Any?)
func resolveVoid()
func reject(reason: FlexReject)
func reject(reason: String)
func reject()
```
If any of the above functions is called, the next time any function is called, the value is not passed to the Web.  
If you directly create and use FlexAction Class, there is no effect. Only FlexAction created and delivered on the interface is effective.

# $flex Object
\$flex Object is an object composed of interfaces between FlexWebView and Promise.  
$flex Object can be used with the same code as applied to [Android FlexHybridApp](https://github.com/Kyun-J/FlexHybridApp-Android).  
The components of $flex Object are as follows.  
```js
window.onFlexLoad // $flex is called upon completion of loading.
$flex // Object that contains functions that can call Native area as WebToNative
$flex.version // get Library version
$flex.web // Object used to add and use functions to be used for NativeToWeb
```
For details, refer to [Flex Interface Implementation](#Flex-Interface-Implementation).
