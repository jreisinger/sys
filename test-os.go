// Run commands in parallel.

package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func main() { // main runs in a goroutine
	ch := make(chan string)

	// Check we have set the OS_* envvars.
	if os.Getenv("OS_PASSWORD") == "" {
		fmt.Fprintln(os.Stderr, "I don't see OS_PASSWORD envvar. Exiting ...")
		os.Exit(1)
	}

	cmds := []string{
		"openstack server list",
		"openstack network list",
		"openstack volume list",
		"openstack image list",
		//"openstack stack list",
	}

	for _, cmd := range cmds {
		go run(cmd, ch)
	}

	for range cmds {
		fmt.Print(<-ch) // receive from channel ch
	}
}

func run(command string, ch chan<- string) {
	parts := strings.Split(command, " ")
	cmd := exec.Command(parts[0], parts[1:]...)
	stdoutStderr, err := cmd.CombinedOutput()
	ch <- fmt.Sprintf("--> CMD: %s\n%s", command, stdoutStderr)
	if err != nil {
		ch <- fmt.Sprintf("%s\n", err) // send to channel ch
		return
	}
}
