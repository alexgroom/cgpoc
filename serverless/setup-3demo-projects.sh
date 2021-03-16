# Script to create 3 demo projects in increasing stages of deploymeny
./setup-noproject.sh agcoolserve3
./setup-noproject.sh agcoolserve2
./setup-noproject.sh agcoolserve1
# Now add eventing
./setup-eventing.sh agcoolserve2
./setup-eventing.sh agcoolserve3
# Now add golang config
./setup-noprojectgolang.sh agcoolserve3
 