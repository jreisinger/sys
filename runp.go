//
// Run commands in parallel.
//
package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
)

func main() { // main runs in a goroutine
	// Usage.
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s commands.txt\n", os.Args[0])
		os.Exit(1)
	}

	// Get commands to execute from a file.
	cmds, err := readCommands(os.Args[1])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading commands: %s. Exiting ...\n", err)
		os.Exit(1)
	}

	ch := make(chan string)

	for _, cmd := range cmds {
		go run(cmd, ch)
	}

	for range cmds {
		// receive from channel ch
		fmt.Print(<-ch)
	}
}

// Read commands from a file.
func readCommands(filePath string) ([]string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var cmds []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()

		// skip comments
		match, _ := regexp.MatchString("^(#|/)", line)
		if match {
			continue
		}

		cmds = append(cmds, line)
	}
	return cmds, scanner.Err()
}

// Run a command.
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
