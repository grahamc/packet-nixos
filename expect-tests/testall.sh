#!/bin/sh

started=0
check() {
    sleep 1
    class="$1"
    started=$((started + 1))
    echo "Started $class, writing to ./testlog.$class"
    (
        (
            start=$(date)
            ./create.sh "$class" 2>&1
            E=$?
            echo "$class start: $start"
            echo "$class end: $(date)"
            echo "$class Exit code: $E"
        ) | tee "testlog.$class"

    )&
}

check c1.large.arm
check c1.small.x86
check c1.xlarge.x86
check c2.medium.x86
check g2.large.x86
check m1.xlarge.x86
check m2.xlarge.x86
check s1.large.x86
check t1.small.x86
check x1.small.x86
check x2.xlarge.x86

wait
for i in $(seq 1 "$started"); do
    echo "Waiting $i";
    wait
    echo "$?"
done
echo "done"

tail -n3 ./testlog.*
