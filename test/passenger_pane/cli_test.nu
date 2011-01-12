(load "test_helper")

(describe "CLI" `(
  (before (do ()
    (set @cli ((CLI alloc) init))
  ))
  
  (it "is not authorized by default" (do ()
    (~ (@cli isAuthorized) should be:false)
  ))
))


(describe "CLI, when unauthorized" `(do
  (before (do ()
    (set @cli ((CLI alloc) init))
    (@cli setPathToCLI:pathToCLI)
  ))
  
  (it "lists currently configured applications" (do ()
    (set applications (@cli listApplications))
    (~ (applications count) should be:3)
    (set hostnames `())
    (for ((set index 0) (< index (applications count)) (set index (+ index 1)))
      (set application (applications objectAtIndex:index) description)
      (set hostnames (append hostnames (list (application host))))
    )
    (~ hostnames should equal:`("manager.boom.local" "scoring.boom.local" "diagnose.local"))
  ))
))


((Bacon sharedInstance) run)