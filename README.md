Reason for _roy_:

We run [Resque](https://github.com/resque/resque) workers hosted on AWS using auto scaling groups.  In order to ensure workers are always running we use the super awesome [God](www.godrb.com) gem.

Our issue is when scaling-in we need to inform the resque workers to gracefully shutdown .i.e:

* Finish the current job
* Stop polling for new jobs
* Terminate the process

While we do make use of Resque's remote shutdown - God does what God does best and restarts the process.  One solution would be to implement remote pause in Resque - we required additional management of our remote nodes during termination.

More to follow.
