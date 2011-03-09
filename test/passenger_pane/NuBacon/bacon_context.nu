(class BaconContext is NSObject
  ; use the dynamic `ivars' so the user can add ivars in before/after
  (ivars (id) _name
         (id) _before
         (id) _after
         (id) _specifications
         (id) _printedName
         (id) _delegate
         (id) _currentSpecificationIndex)
  
  (- (id) initWithName:(id)name specifications:(id)specifications is
    (self initWithName:name before:nil after:nil specifications:specifications)
  )

  (- (id) initWithName:(id)name before:(id)beforeFilters after:(id)afterFilters specifications:(id)specifications is
    (self init)

    ; register this context *before* evalling the specifications list, which may contain nested contexts
    ; that have to be after this one in the contexts list
    ((Bacon sharedInstance) addContext:self)

    (if (beforeFilters)
      (then (set @_before (beforeFilters mutableCopy)))
      (else (set @_before (NSMutableArray array)))
    )
    (if (afterFilters)
      (then (set @_after (afterFilters mutableCopy)))
      (else (set @_after (NSMutableArray array)))
    )

    (set @_name name)
    (set @_printedName nil)
    (set @_currentSpecificationIndex 0)

    (set @_specifications (NSMutableArray array))
    (specifications each:(do (x) (eval x))) ; create a BaconSpecification for each entry in the quoted list

    self
  )

  (- (id) childContextWithName:(id)childName specifications:(id)specifications is
    ((BaconContext alloc) initWithName:"#{@_name} #{childName}" before:@_before after:@_after specifications:specifications)
  )
  
  (- (id) name is @_name)
  
  (- (id) setDelegate:(id)delegate is
    (set @_delegate delegate)
  )
  
  (- (id) run is
    (if (> (@_specifications count) 0)
      (then
        ; TODO
        (set report t)
        (if (report)
          (unless (@_printedName)
            (set @_printedName t)
            (puts "\n#{@_name}")
          )
        )

        (set specification (self currentSpecification))
        (specification performSelector:"run" withObject:nil afterDelay:0)
        ; TODO
        ;((NSRunLoop mainRunLoop) runUntilDate:(NSDate dateWithTimeIntervalSinceNow:0.1))
      )
      (else
        (self finalize)
      )
    )
  )

  (- (id) currentSpecification is
    (@_specifications objectAtIndex:@_currentSpecificationIndex)
  )
  
  (- (id) specificationDidFinish:(id)specification is
    (if (< (+ @_currentSpecificationIndex 1) (@_specifications count))
      (then
        (set @_currentSpecificationIndex (+ @_currentSpecificationIndex 1))
        (self run)
      )
      (else
        (self finalize)
      )
    )
  )

  (- (id) finalize is
    (if (@_delegate respondsToSelector:"contextDidFinish:")
      (@_delegate contextDidFinish:self)
    )
  )

  (- (id) before:(id)block is
    (@_before addObject:block)
  )
  
  (- (id) after:(id)block is
    (@_after addObject:block)
  )
  
  (- (id) addSpecification:(id)description withBlock:(id)block report:(id)report is
    (set specification ((BaconSpecification alloc) initWithContext:self description:description block:block before:@_before after:@_after report:report))
    (@_specifications addObject:specification)
  )
)
