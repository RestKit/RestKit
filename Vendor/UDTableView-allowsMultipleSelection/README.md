UDTableView allowsMultipleSelection backport to pre iOS5
=========

you will need <b>Apple LLVM</b> to compile, alternately you can move declarations from .m to .h and use <b>GCC</b><br /><br />
tested on iOS3.0 (first gen iPhone)<br />
tested on iOS4.2 (iPhone 3GS)<br />
tested on iOS5.0 (iPhone 4)

Pros
----------
drop in replacement (no code to change in your app) just change UITableView to UDTableView. <br />
Implamentation gracefully fallbacks to default iOS implementation if run on iOS5+

Cons
----------
???
