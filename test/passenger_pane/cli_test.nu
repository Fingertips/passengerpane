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
  
  (it "restarts an application" (do ()
    (set applications (@cli listApplications))
    (@cli restart:(applications objectAtIndex:0))
    
    (set arguments (NSString stringWithContentsOfFile:pathToCLIArguments encoding:NSUTF8StringEncoding error:nil))
    (~ arguments should equal:"[\"restart\", \"manager.boom.local\"]")
  ))
))

(describe "CLI, when authorized" `(do
  (before (do ()
    (set @cli ((CLI alloc) init))
    (@cli setPathToCLI:pathToCLI)
    (@cli fakeAuthorize)
  ))
  
  (it "adds a new application" (do ()
    (set attributes (NSMutableDictionary dictionary))
    (attributes setValue:"test.local" forKey:"host")
    (attributes setValue:"assets.test.local" forKey:"aliases")
    (attributes setValue:"/path/to/test" forKey:"path")
    (attributes setValue:"production" forKey:"environment")
    (attributes setValue:"/path/to/test.conf" forKey:"config_filename")
    (set application ((Application alloc) initWithAttributes:attributes))
    
    (@cli add:application)
    
    (set arguments (NSString stringWithContentsOfFile:pathToCLIArguments encoding:NSUTF8StringEncoding error:nil))
    (puts arguments)
    (~ arguments should equal:"[\"add\", \"manager.boom.local\"]")
  ))
))

((Bacon sharedInstance) run)