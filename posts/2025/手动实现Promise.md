---
title: 手动实现Promise
tags: [javascript]
categories: [javascript教程]
date: 2025-3-19
description: 常见 Array 方法
articleGPT: 这是一篇关于手写Promise方法的教程文章
references:
---

# 手动实现Promise

```js
class myPromise{
    //设置静态状态属性
	static pendding = "待定";static fufilled = "完成";static rejected = "失败";
    constructor(fun) {
        //设置初始状态
        this.status = myPromise.pendding;
        this.result = null;
        //两个数组分别存储 .then() 注册的成功和失败回调。
        this.resolveCallback = [];
		this.rejectCallback = [];
		try {
            //执行用户传入的函数 fun，确保 resolve 和 reject 方法内部的 this 指向当前实例。
            fun(this.resolve.bind(this),this.reject.bind(this));
        }catch(err) {
            //抛出异常
            this.reject(err);
        }
    }
    //状态改为 fulfilled，并执行成功回调
    resolve(result){
        setTimeout(()=>{
            if(this.status === myPromise.pending){
                this.status = myPromise.fulfilled;
                this.result = result;
                this.resolveCallback.forEach(callback => callback(result));
            }
        })
    }
    //状态改为 rejected，并执行失败回调
	reject(result){
        setTimeout(()=>{
            if(this.status === myPromise.pending){
                this.status = myPromise.rejected;
                this.result = result;
                this.rejectCallback.forEach(callback => callback(result));
            }
        })
    }
    //成功或失败的回调
	then(onFufilled,onRejected){
		if(this.status === myPromise.pendding){
            //如果当前是 pending 状态，表示异步操作还没完成，就把回调函数先存起来，等待调用。
			this.resolveCallback.push(onFufilled);
            this.rejectCallback.push(onRejected);
        }
        if(this.status === myPromise.fufilled){
            //如果状态已经是 fulfilled（调用 then 的时候异步已完成），立即（用 setTimeout 模拟异步）执行 onFulfilled。
            setTimeout(()=>{
                onFufilled(this.result);
            },0);
        }
        if(this.status === myPromise.rejected){
            //如果已是 rejected 状态，异步调用失败回调。
            setTimeout(()=>{
                onRejected(this.result);
            },0);
        }
    }
    //只处理失败的情况
    catch(onRejected) {
    	return this.then(null, onRejected);
	}
    //无论 resolve 还是 reject，都会执行。
    finally(callback) {
        return this.then(
            value => {
                return myPromise.resolve(callback()).then(() => value);
            },
            reason => {
                return myPromise.resolve(callback()).then(() => { throw reason });
            }
        );
    }
}
```

