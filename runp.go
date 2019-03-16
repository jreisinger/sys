//
// Run commands in parallel.
//
package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
)

func main() { // main runs in a goroutine
	flag.Usage = usage

	numCmds := flag.Int("n", -1, "number of commands to run")
	verbose := flag.Bool("v", false, "be verbose")

	flag.Parse()

	if len(flag.Args()) != 1 {
		usage()
		os.Exit(1)
	}

	// Get commands to execute from a file.
	cmds, err := readCommands(flag.Args()[0], *numCmds)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading commands: %s. Exiting ...\n", err)
		os.Exit(1)
	}

	ch := make(chan string)

	for _, cmd := range cmds {
		go run(cmd, ch, verbose)
	}

	for range cmds {
		// receive from channel ch
		fmt.Print(<-ch)
	}
}

func usage() {
	fmt.Fprintf(os.Stderr, "Run commands defined in a file in parallel.\n\n")
	fmt.Fprintf(os.Stderr, "Usage: %s [options] commands.txt\n", os.Args[0])
	flag.PrintDefaults()
}

func readCommands(filePath string, number int) ([]string, error) {
	// Open the file containing commands.
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var cmds []string
	scanner := bufio.NewScanner(file)
	counter := 0
	for scanner.Scan() {
		if number >= 0 && counter >= number {
			break
		}

		line := scanner.Text()

		// skip comments
		match, _ := regexp.MatchString("^(#|/)", line)
		if match {
			continue
		}

		cmds = append(cmds, line)
		counter += 1
	}
	return cmds, scanner.Err()
}

func run(command string, ch chan<- string, verbose *bool) {
	parts := strings.Split(command, " ")
	cmd := exec.Command(parts[0], parts[1:]...)
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		// send to channel
		ch <- fmt.Sprintf("--> ERR: %s\n%s%s\n", command, stdoutStderr, err)
		return
	}
	// send to channel
	if *verbose {
		ch <- fmt.Sprintf("--> OK: %s\n%s\n", command, stdoutStderr)
	} else {
		ch <- fmt.Sprintf("--> OK: %s\n", command)
	}
}
