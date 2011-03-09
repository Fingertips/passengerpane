NuBacon -- small RSpec clone
============================

    "Truth will sooner come out from error than from confusion."
                                               ---Francis Bacon

NuBacon is a [Nu][nu] port of [Bacon][ba], a small [Ruby RSpec][rs] clone.

It is a [Behavior-Driven Development][bdd] test library for Nu and in
extension for Objective-C. It is being developed while using in our iOS
application, more on that will be announced.


Installation
------------

There's currently no Nu specific package manager, so you will have to
grab the source directly:

As a zip archive:

    $ curl https://github.com/alloy/NuBacon/zipball/0.1 -o NuBacon-0.1.zip
    $ unzip NuBacon-0.1.zip

Or as a git clone:

    $ git clone git@github.com:alloy/NuBacon.git
    $ cd NuBacon
    $ git checkout 0.1

Or checkout master if you’re feeling adventurous. The runloop code,
for instance, is not yet available in a release.

Whirl-wind tour
---------------

    (load "bacon")

    (set emptyArray (do (array) (eq (array count) 0)))

    (describe "An array" `(
      (before (do ()
        (set @ary (NSArray array))
        (set @otherArray (`("noodles") array))
      ))

      (it "is empty" (do ()
        (~ @ary should not containObject:1)
      ))

      (it "has zero elements" (do ()
        (~ @ary count should be:0)
        (~ @ary count should not be closeTo:0.1) ; default delta of 0.00001
        (~ @ary count should be closeTo:0.1 delta:0.2)
      ))

      (it "raises when trying to fetch an element" (do ()
        (set exception (-> (@ary objectAtIndex:0) should raise:"NSRangeException"))
        (~ (exception reason) should match:/beyond bounds/)
      ))

      (it "compares to another object" (do ()
        (~ @ary should be:@ary)
        (~ @ary should equal:@ary)
        (~ @otherArray should not be:@ary)
        (~ @otherArray should not equal:@ary)
      ))

      (it "changes the count when adding objects" (do ()
        (-> (@otherArray << "soup") should change:(do () (@otherArray count)) by:+1)
      ))

      (it "performs a long running operation" (do ()
        (@otherArray performSelector:"addObject:" withObject:"soup" afterDelay:0.5)
        (wait 0.6 (do ()
          (~ (@otherArray count) should be:2)
        ))
      ))

      ; Custom assertions are trivial to do, they are blocks returning
      ; a boolean value. The block is defined at the top.
      (it "uses a custom assertion to check if the array is empty" (do ()
        (~ @ary should be a: emptyArray)
        (~ @otherArray should not be a: emptyArray)
      ))

      (it "has super powers" (do ()
        ; flunks when it contains no assertions
      ))
    ))

    ((Bacon sharedInstance) run)

Now run it:

    $ nush readme_spec.nu

    An array
    - is empty
    - has zero elements
    - raises when trying to fetch an element
    - compares to another object
    - changes the count when adding objects
    - performs a long running operation
    - uses a custom assertion to check if the array is empty
    - has super powers [FAILURE]

    An array - has super powers: flunked [FAILURE]

    8 specifications (14 requirements), 1 failures, 0 errors

Implemented assertions
----------------------

* should:predicateBlock
* should be:object
* should (be) a:object
* should equal:object
* should (be) closeTo:__*float | list of floats*__
* should (be) closeTo:__*float | list of floats*__ delta:float
* should match:regexp
* should change:valueBlock
* should change:valueBlock by:delta
* should raise
* should raise:exceptionName
* should __*predicate method*__
* should __*dynamic predicate message matching*__
* should satisfy:message block:block


Predicate methods
-----------------

Any method of the object being tested, that can work as a predicate,
can be called on the BaconShould instance that wraps it. The result
of the method call will determine wether or not the assertion passes.
Any return value that evaluates to `true` will pass, likewise any
value that evaluates to `false` will fail. Unless the assertion has
been negated with `not`.

For instance, NSString has a `isAbsolutePath` predicate method:

    (~ "/an/absolute/path" should isAbsolutePath)
    (~ "a/relative/path" should not isAbsolutePath)

However, as you can see this does not always lead to proper English,
therefor there are a few special rules on how these methods can be
called.

If the predicate method starts with ‘is’ it can be omitted. The
previous example can thus be rewritten as:

    (~ "/an/absolute/path" should be an absolutePath)
    (~ "a/relative/path" should not be an absolutePath)

Method names in the third-person perspective can be called in the
first-person perspective. For example, `respondsToSelector:` can be
called by omitting the ‘s’ from ‘responds’:

    (~ "foo" should respondToSelector:"isAbsolutePath")
    (~ (NSArray array) should not respondToSelector:"isAbsolutePath")


before/after
------------

`before` and `after` need to be defined before the first specification
that should have them applied.


Nested contexts
---------------

You can nest contexts, which will run before/after filters of parent
contexts like so:

    (describe "parent context" `(
      (describe "child context" `(
      ))
    ))


Shared contexts
---------------

You can define shared contexts in NuBacon like this:

    (shared "an empty container" `(
      (it "has size zero" (do ()
        (~ (@ary count) should be:0)
      ))

      (it "is empty" (do ()
        (~ @ary should be: emptyArray)
      ))
    ))

    (describe "A new array" `(
      (before (do ()
        (set @ary (NSArray array))
      )

      (behaves_like "an empty container")
    ))

These contexts are not executed on their own, but can be included with
behaves_like in other contexts.  You can use shared contexts to
structure suites with many recurring specifications.


The ‘wait’ macro
----------------

Often in Objective-C apps, code will __not__ execute immediately, but
scheduled on a runloop for later execution. Therefor a mechanism is
needed that will postpone execution of some assertions for a period of
time. This is where the `wait` macro comes in:

      (it "performs a long running operation" (do ()
        ; Here a method call is scheduled to be performed ~0.5 seconds in the future
        (@otherArray performSelector:"addObject:" withObject:"soup" afterDelay:0.5)
        (wait 0.6 (do ()
          ; This block is executed ~0.6 seconds in the future
          (~ (@otherArray count) should be:2)
        ))
      ))

The postponed block does __not__ halt the thread, but is scheduled on
the runloop as well. This means that your runloop based code will have
a chance to perform its job before the assertions in the block are
executed.

You can schedule as many blocks as you’d want and even nest them.


Helper macros
-------------

Nesting calls to assertions can become unreadable quite fast:

    (((((@ary count) should) not) be) closeTo:0.1 delta:0.2)

For this purpose, the `~` macro has been introduced. It iterates over
the symbols in the given list and sends those as messages to the
object, which is the first item in the list:

    (~ @ary count should not be closeTo:0.1 delta:0.2)

-------------

The `raise` and `raise:` assertions will execute the block, which is
the wrapped object, and assert that an exception is, or isn't, raised.

But creating a block and wrapping it in a BaconShould instance can
look a bit arcane, and you have to remember to use `send`:

    ((send (do () ((NSArray array) objectAtIndex:0)) should) raise:"NSRangeException")

Therefore the `->` macro has been introduced:

    (-> (@ary objectAtIndex:0) should raise:"NSRangeException")

As you might have been able to tell, any extra messages are
dynamically dispatched by the `~` macro.


Thanks to
---------

* [Christian Neukirchen][cn], and other contributors, for Bacon itself!
* Tim Burks for Nu
* Laurent Sansonetti for brainwashing me about lisps ;)


Contributing
------------

There's still plenty to do, see the [TODO][td] for things that need to be done.

Once you've made your great commits:

1. [Fork][fk] NuBacon
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create a pull request or [issue][is] with a link to your branch
5. That's it!


LICENSE
-------

Copyright (C) 2010 Eloy Durán <eloy.de.enige@gmail.com>, Fingertips BV <fngtps.com>

NuBacon is freely distributable under the terms of an MIT-style license.
See [LICENSE][li] or http://www.opensource.org/licenses/mit-license.php.

[nu]:  https://github.com/timburks/nu
[ba]:  https://github.com/chneukirchen/bacon
[rs]:  http://rspec.rubyforge.org
[bdd]: http://behaviour-driven.org
[fk]:  http://help.github.com/forking
[is]:  https://github.com/alloy/NuBacon/issues
[li]:  https://github.com/alloy/NuBacon/blob/master/LICENSE
[td]:  https://github.com/alloy/NuBacon/blob/master/TODO
[cn]:  http://chneukirchen.org
