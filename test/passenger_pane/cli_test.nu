(load "test_helper")

(describe "CLI" `(
  (before (do ()
    (set @cli (CLI sharedInstance))
  ))
  
  (it "is not authorized by default" (do ()
    (~ (@cli isAuthorized) should be:false)
  ))
))

((Bacon sharedInstance) run)