package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
)

func usage() {
	desc := `Run commands defined in a file in parallel. By default, shell is invoked and
env. vars are expanded. Source: https://raw.githubusercontent.com/jreisinger/sys/master/runp.go`
	fmt.Fprintf(os.Stderr, "%s\n\nUsage: %s [options] commands.txt\n", desc, os.Args[0])
	flag.PrintDefaults()
}

type Command struct {
	CmdString string
	CmdToShow string
	CmdToRun  *exec.Cmd
	Chan      chan<- string
	Verbose   bool
	NoShell   bool
}

type Commands struct {
	FilePath string
	Err      error
	Cmds     []Command
}

func (c *Commands) LoadFromFile() {
	file, err := os.Open(c.FilePath)
	if err != nil {
		c.Err = err
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()

		// skip comments
		match, _ := regexp.MatchString("^(#|/)", line)
		if match {
			continue
		}

		c.Cmds.CmdString = append(c.Cmds.CmdString, line)
	}
	c.Err = scanner.Err()
}

func (c Cmds) Prepare() {
	if c.NoShell {
		parts := strings.Split(c.CmdString, " ")
		c.CmdToRun = exec.Command(parts[0], parts[1:]...)
		c.CmdToShow = strings.Join(cmd.Args, " ")
	} else {
		c.CmdString = os.ExpandEnv(c.CmdString) // expand ${var} or $var
		shellToUse := "/bin/sh"
		c.CmdToRun = exec.Command(shellToUse, "-c", c.CmdString)
		cmdToShow = shellToUse + " -c " + strconv.Quote(strings.Join(c.CmdToRun.Args[2:], " "))
	}
}

func (c Cmds) Run() {
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		ch <- fmt.Sprintf("--> ERR: %s\n%s%s\n", cmdToShow, stdoutStderr, err)
		return
	}

	if *verbose {
		ch <- fmt.Sprintf("--> OK: %s\n%s\n", cmdToShow, stdoutStderr)
	} else {
		ch <- fmt.Sprintf("--> OK: %s\n", cmdToShow)
	}
}

func run(command string, ch chan<- string, verbose *bool, noshell *bool) {
	var cmd *exec.Cmd
	var cmdToShow string

	if *noshell {
		parts := strings.Split(command, " ")
		cmd = exec.Command(parts[0], parts[1:]...)
		cmdToShow = strings.Join(cmd.Args, " ")
	} else {
		command = os.ExpandEnv(command) // expand ${var} or $var
		shellToUse := "/bin/sh"
		cmd = exec.Command(shellToUse, "-c", command)
		cmdToShow = shellToUse + " -c " + strconv.Quote(strings.Join(cmd.Args[2:], " "))
	}

	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		ch <- fmt.Sprintf("--> ERR: %s\n%s%s\n", cmdToShow, stdoutStderr, err)
		return
	}

	if *verbose {
		ch <- fmt.Sprintf("--> OK: %s\n%s\n", cmdToShow, stdoutStderr)
	} else {
		ch <- fmt.Sprintf("--> OK: %s\n", cmdToShow)
	}
}

func main() { // main runs in a goroutine
	flag.Usage = usage

	verbose := flag.Bool("v", false, "be verbose")
	noshell := flag.Bool("n", false, "don't invoke shell and don't expand env. vars")

	flag.Parse()

	if len(flag.Args()) != 1 {
		usage()
		os.Exit(1)
	}

	// Get commands to execute from a file.
	cmds := &Commands{FilePath: flag.Args()[0]}
	cmds.LoadFromFile()
	if cmds.Err != nil {
		fmt.Fprintf(os.Stderr, "Error reading commands: %s. Exiting ...\n", cmds.Err)
		os.Exit(1)
	}
	cmds.Run()
	if cmds.Err != nil {
		fmt.Fprintf(os.Stderr, "Error reading commands: %s. Exiting ...\n", cmds.Err)
		os.Exit(1)
	}

	ch := make(chan string)

	for _, cmd := range cmds.Cmds {
		go run(cmd, ch, verbose, noshell)
	}

	for range cmds.Cmds {
		// receive from channel ch
		fmt.Print(<-ch)
	}
}
