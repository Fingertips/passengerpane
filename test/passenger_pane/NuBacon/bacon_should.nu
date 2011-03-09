(class BaconShould is NSObject
  (ivar (id) object
        (id) negated
        (id) descriptionBuffer
  )
  
  (- (id) initWithObject:(id)object is
    (self init) ;; TODO check if it's nil
    (set @object object)
    (set @negated nil)
    (set @descriptionBuffer "")
    self
  )
  
  (- (id) object is
    @object
  )
  
  (- (id) should is
    self
  )
  
  (- (id) should:(id)block is
    (self satisfy:nil block:block)
  )
  
  (- (id) not is
    (set @negated t)
    (@descriptionBuffer appendString:" not")
    self
  )
  
  (- (id) not:(id)block is
    (set @negated t)
    (@descriptionBuffer appendString:" not")
    (self satisfy:nil block:block)
  )
  
  (- (id) be is
    (@descriptionBuffer appendString:" be")
    self
  )
  
  (- (id) a is
    (@descriptionBuffer appendString:" a")
    self
  )
  
  (- (id) an is
    (@descriptionBuffer appendString:" an")
    self
  )
  
  (- (id) satisfy:(id)description block:(id)block is
    ($BaconSummary addRequirement)
    (unless description (set description "satisfy `#{block}'"))
    (set description "expected `#{@object}' to#{@descriptionBuffer} #{description}")
    (set passed (block @object))
    (if (passed)
      (then
        (if (@negated)
          (throw ((BaconError alloc) initWithDescription:description))
        )
      )
      (else
        (unless (@negated)
          (throw ((BaconError alloc) initWithDescription:description))
        )
      )
    )
  )
  
  (- (id) be:(id)value is
    (if (send value isKindOfClass:NuBlock)
      (then
        (self satisfy:"be `#{value}'" block:value)
      )
      (else
        (self satisfy:"be `#{value}'" block:(do (object)
          (eq object value)
        ))
      )
    )
  )
  
  (- (id) a:(id)value is
    (if (send value isKindOfClass:NuBlock)
      (then
        (self satisfy:"a `#{value}'" block:value)
      )
      (else
        (self satisfy:"a `#{value}'" block:(do (object)
          (eq object value)
        ))
      )
    )
  )
  
  (- (id) equal:(id)value is
    (self satisfy:"equal `#{value}'" block:(do (object)
      (eq object value)
    ))
  )
  
  (- (id) closeTo:(id)otherValue is
    (self closeTo:otherValue delta:0.00001)
  )
  
  (- (id) closeTo:(id)otherValue delta:(id)delta is
    (if (eq (otherValue class) NuCell)
      (then
        (set otherValues (otherValue array))
        (self satisfy:"close to `#{otherValue}'" block:(do (values)
          (set result t)
          (values eachWithIndex:(do (value index)
            (set otherValue (otherValues objectAtIndex:index))
            (set result (and result (and (>= otherValue (- value delta)) (<= otherValue (+ value delta)))))
          ))
          result
        ))
      )
      (else
        (self satisfy:"close to `#{otherValue}'" block:(do (value)
          (and (>= otherValue (- value delta)) (<= otherValue (+ value delta)))
        ))
      )
    )
  )
  
  (- (id) match:(id)regexp is
    (self satisfy:"match /#{(regexp pattern)}/" block:(do (string)
      (regexp findInString:string)
    ))
  )
  
  (- (id) change:(id)valueBlock by:(id)delta is
    (self satisfy:"change `#{(send valueBlock body)}' by `#{delta}'" block:(do (changeBlock)
      (set before (call valueBlock))
      (call changeBlock)
      (eq (+ before delta) (call valueBlock))
    ))
  )
  
  (- (id) change:(id)valueBlock is
    (self satisfy:"change `#{(send valueBlock body)}'" block:(do (changeBlock)
      (set before (call valueBlock))
      (call changeBlock)
      (not (eq before (call valueBlock)))
    ))
  )
  
  (- (id) raise is
    (set result nil)
    (self satisfy:"raise any exception" block:(do (block)
      (try
        (call block)
        (catch (e)
          (set result e)
          t
        )
        nil
      )
    ))
    result
  )
  
  (- (id) raise:(id)exceptionName is
    (set result nil)
    (self satisfy:"raise an exception of type `#{exceptionName}'" block:(do (block)
      (try
        (call block)
        (catch (e)
          (set result e)
          (eq (e name) exceptionName)
        )
      )
    ))
    result
  )
  
  (- (id) handleUnknownMessage:(id)methodName withContext:(id)context is
    (set name ((first methodName) stringValue))
    (set args (cdr methodName))
    (set description name)
    (if (args) (then (set description "#{description}#{args}")))
    (if (@object respondsToSelector:name)
      (then
        ; forward the message as-is
        (self satisfy:description block:(do (object)
          (object sendMessage:methodName withContext:context)
        ))
      )
      (else
        (set predicate "is#{((name substringToIndex:1) uppercaseString)}#{(name substringFromIndex:1)}")
        (if (@object respondsToSelector:predicate)
          (then
            ; forward the predicate version of the message with the args
            (self satisfy:description block:(do (object)
              (set symbol ((NuSymbolTable sharedSymbolTable) symbolWithString:predicate))
              (sendMessageWithList object (append (list symbol) (cdr methodName)))
            ))
          )
          (else
            (set parts ((regex "([A-Z][a-z]*)") splitString:name))
            (set firstPart (parts objectAtIndex:0))
            (set firstPart (firstPart stringByAppendingString:"s"))
            (parts replaceObjectAtIndex:0 withObject:firstPart)
            (set thirdPersonForm (parts componentsJoinedByString:""))
            (if (@object respondsToSelector:thirdPersonForm)
              (then
                ; example: respondsToSelector: is matched as respondToSelector:
                (self satisfy:description block:(do (object)
                  (set symbol ((NuSymbolTable sharedSymbolTable) symbolWithString:thirdPersonForm))
                  (sendMessageWithList object (append (list symbol) (cdr methodName)))
                ))
              )
              (else
                ; the object does not respond to any of the messages
                (super handleUnknownMessage:methodName withContext:context)
              )
            )
          )
        )
      )
    )
  )
)
