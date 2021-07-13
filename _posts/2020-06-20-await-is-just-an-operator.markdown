---
layout: post
title:  "Await is just an Operator"
date:   2020-06-20 23:24:00 -0700
categories: csharp
---

In .NET, and C# in particular, “await” is an operator just like ++ or &&. You can create all sorts of custom awaitable objects and build custom awaitable expressions.

Here is the simplest of examples!

Lets start by defining a task. A task needs to implement a single method:
* GetAwaiter()
    - Returns an Awaiter. We will get to this next, its also got a schema to implement.

{% highlight csharp %}
/// <summary>
/// A simple task.
/// </summary>
public class SimpleTask
{
    /// <summary>
    /// Gets the simple awaiter for the task.
    /// </summary>
    /// <returns>The awaiter.</returns>
    public SimpleAwaiter GetAwaiter()
    {
        return new SimpleAwaiter();
    }
}
{% endhighlight %}

Now for the Awaiter. The awaiter needs a few things defined:

* GetResult()
    - Gets the result of the task.
    - Can be a void or non-void method.
* IsCompleted
    - A property which returns a value indicating whether a task has completed. Ours is synchronous, so this always returns true.
* ICriticalNotifyCompletion or INotifyCompletion
    - OnCompleted(Action continuation)
        + Called when returning from an async completion. If ICriticalNotifyCompletion is not implemented, then this will also be invoked on a synchronous completion.
    - UnsafeOnCompleted(Action continuation)
        + Only available if ICriticalNotifyCompletion is implemented, and will be invoked on a synchronous completion of the task. OnCompleted will not be called.

{% highlight csharp %}
using System;
using System.Runtime.CompilerServices;

public class SimpleAwaiter : ICriticalNotifyCompletion, INotifyCompletion
{
    /// <summary>
    /// Our task never runs async, so its always completed.
    /// </summary>
    public bool IsCompleted => true;

    /// <summary>
    /// Our task doesnt return anything, so this can be a void method, 
    /// but lets return something so we have something to await.
    /// </summary>
    public string GetResult() => "Hello World";

    public void OnCompleted(Action continuation)
    {
        // OnCompleted is called on returning from an async completion.
        throw new NotImplementedException();
    }

    public void UnsafeOnCompleted(Action continuation)
    {
        // UnsafeOnCompleted is called after a sync completion.
        continuation();
    }
}
{% endhighlight %}

Heres an example of how this can all work!

{% highlight csharp %}
class Program
{
    public static async Task Main(string[] args)
    {
        Console.WriteLine(await new SimpleTask());
    }
}
{% endhighlight %}

Give it a shot! The result will be “Hello World” in the console.

A good place to check for more information is the C# language reference: [await-expressions](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/expressions#await-expressions)