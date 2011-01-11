(load "bacon_summary")
(load "bacon_specification")
(load "bacon_context")
(load "bacon_should")
(load "bacon_macros")

(class Bacon is NSObject
  (ivars (id) contexts
         (id) currentContextIndex)

  (+ sharedInstance is $BaconSharedInstance)

  (- init is
    (super init)
    (set @contexts (NSMutableArray array))
    (set @currentContextIndex 0)
    self
  )

  (- addContext:(id)context is
    (@contexts addObject:context)
  )

  (- (id) run is
    (set context (self currentContext))
    (context setDelegate:self)
    (context performSelector:"run" withObject:nil afterDelay:0)
    ; TODO check if this is really the right way to do it?
    ; TODO make this work nicely when there is already a runloop, like in an (iOS) app runner
    ;((NSRunLoop mainRunLoop) runUntilDate:(NSDate dateWithTimeIntervalSinceNow:0.1))
    ;((NSRunLoop mainRunLoop) runUntilDate:(NSDate distantFuture))
    (try
      ((NSApplication sharedApplication) run)
      (catch (e))
      ; running on iOS most probably
    )
  )

  (- (id) currentContext is
    (@contexts objectAtIndex:@currentContextIndex)
  )

  (- (id) contextDidFinish:(id)context is
    (if (< (+ @currentContextIndex 1) (@contexts count))
      (then
        (set @currentContextIndex (+ @currentContextIndex 1))
        (self run)
      )
      (else
        ; DONE!
        ($BaconSummary print)
        (try
          ((NSApplication sharedApplication) terminate:self)
          (catch (e))
          ; running on iOS most probably
        )
      )
    )
  )
)
(set $BaconSharedInstance ((Bacon alloc) init))

; TODO How should I subclass NSException?
(class BaconError is NSObject
  (ivar (id) description)
  
  (- (id) initWithDescription:(id)description is
    (self init)
    (set @description description)
    self
  )
  
  (- (id) name is "BaconError")
  (- (id) reason is @description)
)

(class NSObject
  (- (id) instanceEval:(id)block is
    (set c (send block context))
    (send block evalWithArguments:nil context:c self:self)
  )

  (- (id) should is ((BaconShould alloc) initWithObject:self))
  (- (id) should:(id)block is (((BaconShould alloc) initWithObject:self) satisfy:nil block:block))
)

