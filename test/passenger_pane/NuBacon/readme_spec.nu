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
