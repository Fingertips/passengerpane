(class BaconSpecification is NSObject
  (ivars (id) context
         (id) description
         (id) block
         (id) before
         (id) after
         (id) report
         (id) exceptionOccurred
         (id) postponedBlocksCount
         (id) numberOfRequirementsBefore)

  (- (id) initWithContext:(id)context description:(id)description block:(id)block before:(id)beforeFilters after:(id)afterFilters report:(id)report is
    (self init)

    (set @context context)
    (set @description description)
    (set @block block)
    (set @report report)

    (set @postponedBlocksCount 0)
    (set @exceptionOccurred nil)

    ; create copies so that when the given arrays change later on, they don't change these
    (set @before (beforeFilters copy))
    (set @after (afterFilters copy))

    self
  )

  (- (id) runBeforeFilters is
    ((@before list) each:(do (x) (@context instanceEval:x)))
  )

  (- (id) runAfterFilters is
    ((@after list) each:(do (x) (@context instanceEval:x)))
  )

  (- (id) run is
    (if (@report)
      ($BaconSummary addSpecification)
      (print "- #{@description}")
    )
    
    (set @numberOfRequirementsBefore ($BaconSummary requirements))

    (self executeBlock:(do ()
      (self runBeforeFilters)
      ; run actual specification
      (@context instanceEval:@block)
    ))

    (if (eq @postponedBlocksCount 0) (self finalize))
  )

  (- executeBlock:(id)block is
    (try
      (call block)
      (catch (e)
        (set @exceptionOccurred t)
        (if (@report)
          (if (eq (e class) BaconError)
            (then
              ($BaconSummary addFailure)
              (set type " [FAILURE]")
            )
            (else
              ($BaconSummary addError)
              (set type " [ERROR]")
            )
          )
          (print type)
          ($BaconSummary addToErrorLog:e context:(@context name) specification:@description type:type)
        )
      )
    )
  )

  (- (id) postponeBlock:(id)block withDelay:(id)seconds is
    ; If an exception occurred, we definitely don't need to schedule any more blocks
    (unless (@exceptionOccurred)
      (set @postponedBlocksCount (+ @postponedBlocksCount 1))
      (self performSelector:"runPostponedBlock:" withObject:block afterDelay:seconds)
      ; TODO
      ;((NSRunLoop mainRunLoop) runUntilDate:(NSDate dateWithTimeIntervalSinceNow:seconds))
    )
  )

  (- (id) runPostponedBlock:(id)block is
    ; If an exception occurred, we definitely don't need execute any more blocks
    (unless (@exceptionOccurred)
      (self executeBlock:(do () (@context instanceEval:block)))
    )
    (set @postponedBlocksCount (- @postponedBlocksCount 1))
    (if (eq @postponedBlocksCount 0) (self finalize))
  )

  (- (id) finalize is
    (self executeBlock:(do () (self runAfterFilters)))

    (if (eq @numberOfRequirementsBefore ($BaconSummary requirements))
      ; the specification did not contain any requirements, so it flunked
      ; TODO ugh, exceptions for control flow, need to clean this up
      (self executeBlock:(do () (throw ((BaconError alloc) initWithDescription:"flunked"))))
    )

    (if (@report) (print "\n"))
    (if (@context respondsToSelector:"specificationDidFinish:")
      (@context specificationDidFinish:self)
    )
  )
)
