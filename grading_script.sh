#!/bin/bash

# vars
assignment_num=2
grading_loc=~/sp23-assignment$assignment_num/grading_output

# HELPER FUNCTIONS #

# clones a student's repo and places their mdadm.c in the template assignment
# input:  $1 = student's git username
#         $2 = student's git commit number
# output: None
function clone(){
    cd ~
    git clone git@github.com:PSUCMPSC311/sp23-assignment$assignment_num-$1.git
    cd sp23-assignment$assignment_num-$1
    git checkout $2
    cp mdadm.c ~/sp23-assignment$assignment_num/mdadm.c

    # diff mdadm.h ~/sp23-assignment$assignment_num/mdadm.h # grep output
}

# tests the test cases for this assignment
# input:  None
# output: pass status of the test cases and which test cases failed
function test_cases(){
	cd ~/sp23-assignment$assignment_num
	make clean > /dev/null
	make > /dev/null
	CASES_RESULT=$(./tester | grep -v passed | tac)
	echo "$CASES_RESULT"
}

# tests the traces for this assignment
# input:  None
# output: pass status of all traces
function test_traces(){
    # vars
    trace_amount=3
    count=0

    # moving and building
    cd ~/sp23-assignment$assignment_num
    make clean > /dev/null
	make > /dev/null

    # testing #
    # simple-input
	simple_result=$(test_trace simple)
    count=$((count+=$?))
    # random-input
    random_result=$(test_trace random)
    count=$((count+=$?))
    # linear-input
    linear_result=$(test_trace linear)
    count=$((count+=$?))
    
    # returning
    TRACES_RESULT=$(echo "$simple_result
    $random_result
    $linear_result
    Total score: $count/$trace_amount
    " | grep -v passed | tac)
    echo "$TRACES_RESULT"
}

# helper for test_traces, tests a single trace
# input:  $1 = trace type
# output: the differences between the expected and actual input
function test_trace(){
    ./tester -w traces/$1-input > trace_output
    # diff returns 0 on no differences and 1 on differences
    diff -q traces/$1-expected-output trace_output
    # $? access return of last called function
    if (($? != 0)); then
        echo "$1 trace failed"
        return 0
    else
        echo "$1 trace passed"
        return 1
    fi
}

# removes the student's repo so the next one can be tested
# input:  None
# output: None
function clean_grading(){
	cd ~
	rm -rf sp23-assignment$assignment_num-*
}

# grading script
cd ~
cat /dev/null > $grading_loc

while IFS=" " read -r git_id commit_num; do
    echo "$git_id's results:" >> $grading_loc
    
    if [[ "$commit_num" != "" ]]; then
        # clone assignment
        clone $git_id $commit_num

        # test and output result
        cases_return=$(test_cases)
        echo " $cases_return" >> $grading_loc
        
        # these are only for assignment 3
        # traces_return=$(test_traces)
        # echo " $traces_return" >> $grading_loc

        # clean up before moving on
        clean_grading
    else
        echo " 0/10 - no submission" >> $grading_loc
    fi
    
    echo "" >> $grading_loc
done