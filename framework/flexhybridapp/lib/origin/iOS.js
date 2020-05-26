(function() {
"use strict";
const keys = keysfromios;
const options = optionsfromios;
const listeners = [];
const logs = { log: console.log, debug: console.debug, error: console.error, info: console.info };
const option = {
    timeout: 60000
};
const genFName = () => {
    const name = 'f' + Math.random().toString(10).substr(2,8);
    if(window[name] === undefined) {
        return Promise.resolve(name);
    } else {
        return Promise.resolve(genFName());
    }
}
const triggerEventListener = (name, val) => {
    listeners.forEach(element => {
        if(element.e === name && typeof element.c === 'function') {
            element.c(val);
        }
    });
}
const setOptions = () => {
    Object.keys(options).forEach(k => {
        if(k === 'timeout' && typeof options[k] === 'number') {
            Object.defineProperty(option, k, {
                value: options[k], writable: false, enumerable: true
            });
        }
    });
}
setOptions();
window.$flex = {};
Object.defineProperties($flex,
    {
        version: { value: '0.3', writable: false, enumerable: true },
        addEventListener: { value: function(event, callback) { listeners.push({ e: event, c: callback }) }, writable: false, enumerable: true },
        web: { value: {}, writable: false, enumerable: true },
        options: { value: option, writable: false, enumerable: true },
        flex: { value: {}, writable: false, enumerable: false }
    }
);
keys.forEach(key => {
    if($flex[key] === undefined) {
        Object.defineProperty($flex, key, {
            value:
            function(...args) {
                return new Promise(resolve => {
                    genFName().then(name => {
                        const counter = setTimeout(() => {
                            $flex.flex[name]();
                            console.log('$flex timeout in function -- $flex.' + key);
                            triggerEventListener('timeout', { name: key });
                        }, option.timeout);
                        $flex.flex[name] = (r) => {
                            resolve(r);
                            clearTimeout(counter);
                            delete $flex.flex[name];
                        };
                        webkit.messageHandlers[key].postMessage(
                            {
                                funName: name,
                                arguments: args
                            }
                        );
                    });
                });
            },
            writable: false,
            enumerable: true
        });
    }
});
console.log = function(...args) { $flex.flexlog(...args); logs.log(...args); };
console.debug = function(...args) { $flex.flexdebug(...args); logs.debug(...args); };
console.error = function(...args) { $flex.flexerror(...args); logs.error(...args); };
console.info = function(...args) { $flex.flexinfo(...args); logs.info(...args); };
setTimeout(() => {
    if(typeof window.onFlexLoad === 'function') {
        window.onFlexLoad()
    }
},0);
})()
