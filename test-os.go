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
		"openstack availability zone list",
		"openstack catalog list",
		"openstack command list",
		"openstack extension list",
		"openstack flavor list",
		"openstack floating ip list",
		"openstack floating ip list", "openstack flavor list",
		"openstack image list",
		"openstack ip availability list",
		"openstack keypair list",
		"openstack module list",
		"openstack network agent list",
		"openstack network list",
		"openstack network service provider list",
		"openstack port list",
		"openstack project list",
		"openstack router list",
		"openstack security group list",
		"openstack security group rule list",
		"openstack server group list",
		"openstack server list",
		"openstack snapshot list",
		"openstack subnet list",
		"openstack volume backend pool list",
		"openstack volume list",
		"openstack volume snapshot list",
		"openstack volume transfer request list",
	}

	for _, cmd := range cmds {
		go run(cmd, ch)
	}

	for range cmds {
		// receive from channel ch
		fmt.Print(<-ch)
	}
}

func run(command string, ch chan<- string) {
	parts := strings.Split(command, " ")
	cmd := exec.Command(parts[0], parts[1:]...)
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		// send to channel
		ch <- fmt.Sprintf("--> ERR: %s\n%s%s\n", command, stdoutStderr, err)
		return
	}
	// send to channel
	//ch <- fmt.Sprintf("--> CMD: %s\n%s", command, stdoutStderr)
	ch <- fmt.Sprintf("--> OK: %s\n", command)
}
