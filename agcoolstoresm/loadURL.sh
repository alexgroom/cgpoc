# Load up a URL with traffic
# $1 is the URL
# $2 is the number of loops
# $3 is the delay

if test -z "$1" 
then 
  exit
fi

if test -z "$2" 
then 
  count=1000
else
  count=$2
fi

if test -z "$3" 
then 
  time=0.1s
else
  time=$3
fi

echo "Loop count" $count " delay " $time
i=0
while [ $i -le $count ] 
do
    curl $1 -o /dev/null
    sleep $time
    ((i++))
done