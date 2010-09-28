#!/usr/bin/env bash

DIFF_FLAGS="-u"
if [[ `uname` == *W32* ]] ; then
  DIFF_FLAGS="-wu"
fi

if [ -z "$testBin" ]; then
    testBin="$1"
fi

# find test binary on both platforms.  allow the caller to force a
# particular test binary (useful for non-cmake build systems).
if [ -z "$testBin" ]; then
	testBin="../build/test/Debug/yajl_test.exe"
	if [[ ! -x $testBin ]] ; then
	  testBin="../build/test/yajl_test"
	  if [[ ! -x $testBin ]] ; then
	    echo "cannot execute test binary: '$testBin'"  
	    exit 1;
	  fi
	fi
fi

echo "using test binary: $testBin"

let testsSucceeded=0
let testsTotal=0 

for file in cases/*.json ; do
  allowComments="-c"

  # if the filename starts with dc_, we disallow comments for this test
  if [[ $(basename $file) == dc_* ]] ; then
    allowComments=""
  fi
  echo -n " test case: '$file': "
  let iter=1
  success="success"

  # parse with a read buffer size ranging from 1-31 to stress stream parsing
  while (( $iter < 32 )) && [ $success == "success" ] ; do
    $testBin $allowComments -b $iter < $file > ${file}.test  2>&1
    diff ${DIFF_FLAGS} ${file}.gold ${file}.test
    if [[ $? == 0 ]] ; then
      if (( $iter == 31 )) ; then let testsSucceeded+=1 ; fi
    else 
      success="FAILURE"
      let iter=32
    fi
    let iter+=1
    rm ${file}.test
  done

  echo $success
  let testsTotal+=1
done

echo $testsSucceeded/$testsTotal tests successful

if [[ $testsSucceeded != $testsTotal ]] ; then
  exit 1
fi

exit 0
