package main

import (
	"bufio"
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/client"
	"github.com/docker/docker/pkg/stdcopy"
	"github.com/pkg/errors"
)

type authError struct {
	Err error
}

func (e *authError) Error() string {
	return "Failed to find AWS Credentials"
}

func (e *authError) Unwrap() error {
	return e.Err
}

func requireIntrospectorComposition(ctx context.Context, cli *client.Client) types.Container {
	containers, err := cli.ContainerList(ctx, types.ContainerListOptions{
		Filters: filters.NewArgs(filters.Arg("label", "introspector-cli")),
	})
	if err != nil {
		panic(err)
	}
	if len(containers) > 1 {
		panic("More than one Introspector CLI found running")
	}
	if len(containers) == 0 {
		panic("Could not find Introspector CLI container running")
	}
	return containers[0]
}

func loadAwsCredentials(ctx context.Context) (map[string]string, error) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, &authError{err}
	}
	creds, err := cfg.Credentials.Retrieve(ctx)
	if err != nil {
		return nil, &authError{err}
	}
	env := make(map[string]string)
	env["AWS_ACCESS_KEY_ID"] = creds.AccessKeyID
	env["AWS_SECRET_ACCESS_KEY"] = creds.SecretAccessKey
	if len(creds.SessionToken) > 0 {
		env["AWS_SESSION_TOKEN"] = creds.SessionToken
	}
	return env, nil
}

func needsAwsCredential(userCmd []string) bool {
	for _, token := range userCmd {
		if token == "--help" || token == "-h" {
			return false
		}
	}
	if len(userCmd) >= 3 {
		if userCmd[0] == "account" && userCmd[1] == "aws" && (userCmd[2] == "import" || userCmd[2] == "remap") {
			return true
		}
	}
	return false
}

func needsGcpCredential(userCmd []string) bool {
	if len(userCmd) >= 3 {
		if userCmd[0] == "account" && userCmd[1] == "gcp" && (userCmd[2] == "import" || userCmd[2] == "remap" || userCmd[2] == "credential") {
			return true
		}
	}
	return false
}

func runFileCommand(filename string, rest []string) ([]string, error) {
	f, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	bytes, err := ioutil.ReadAll(f)
	if err != nil {
		return nil, err
	}
	cmd := []string{"run", string(bytes)}
	cmd = append(cmd, rest...)
	return cmd, nil
}

func unrollRunCommands(cmd []string) ([][]string, error) {
	if len(cmd) < 2 || cmd[0] != "run" {
		return [][]string{cmd}, nil
	}
	queryTarget := cmd[1]
	info, err := os.Stat(queryTarget)
	if os.IsNotExist(err) {
		// Let introspector handle whatever
		return [][]string{cmd}, nil
	} else if err != nil {
		return nil, errors.Wrapf(err, "Failed to stat %v", queryTarget)
	}
	if info.IsDir() {
		infos, err := ioutil.ReadDir(queryTarget)
		if err != nil {
			return nil, errors.Wrapf(err, "Failed to ReadDir(%v)", queryTarget)
		}
		cmds := [][]string{}
		for _, info := range infos {
			if strings.HasSuffix(info.Name(), ".sql") {
				filename := filepath.Join(queryTarget, info.Name())
				subCommand, err := runFileCommand(filename, cmd[2:])
				if err != nil {
					return nil, err
				}
				cmds = append(cmds, subCommand)
			}
		}
		return cmds, nil
	}
	runCommand, err := runFileCommand(queryTarget, cmd[2:])
	if err != nil {
		return nil, err
	}
	return [][]string{runCommand}, nil
}

func cmdPassthrough(ctx context.Context, cli *client.Client, introspector types.Container, userCmd []string) error {
	var env map[string]string

	cmd := append([]string{"python", "introspector.py"}, userCmd...)
	if needsAwsCredential((userCmd)) {
		awsEnv, err := loadAwsCredentials(ctx)
		if err != nil {
			return err
		}
		env = awsEnv
	}

	envStrings := []string{}
	for key, val := range env {
		envStrings = append(envStrings, fmt.Sprintf("%v=%v", key, val))
	}
	execResp, err := cli.ContainerExecCreate(ctx, introspector.ID, types.ExecConfig{
		Cmd:          cmd,
		WorkingDir:   "/app",
		AttachStderr: true,
		AttachStdout: true,
		AttachStdin:  true,
		Env:          envStrings,
	})
	if err != nil {
		return err
	}
	resp, err := cli.ContainerExecAttach(ctx, execResp.ID, types.ExecStartCheck{})
	if err != nil {
		return err
	}
	defer resp.Close()
	// read the output
	outputDone := make(chan error)
	go func() {
		// StdCopy demultiplexes the stream into two buffers
		_, err = stdcopy.StdCopy(os.Stdout, os.Stderr, resp.Reader)
		outputDone <- err
	}()

	stdin := bufio.NewScanner(os.Stdin)
	go func() {
		for stdin.Scan() {
			resp.Conn.Write(stdin.Bytes())
			resp.Conn.Write([]byte("\n"))
		}
	}()

	select {
	case err := <-outputDone:
		if err != nil {
			return err
		}
		break

	case <-ctx.Done():
		return ctx.Err()
	}

	return nil
}

func main() {
	cmd := os.Args[1:]
	ctx := context.Background()
	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		panic(err)
	}
	_, err = cli.ServerVersion(ctx)
	if err != nil {
		if client.IsErrConnectionFailed((err)) {
			fmt.Println("Cannot find docker server. Is it installed and running?")
			os.Exit(1)
		}
		panic(err)
	}
	introspector := requireIntrospectorComposition(ctx, cli)
	cmds, err := unrollRunCommands(cmd)
	if err != nil {
		panic(err)
	}
	for _, cmd := range cmds {
		err = cmdPassthrough(ctx, cli, introspector, cmd)
		if err != nil {
			var authErr *authError
			if errors.As(err, &authErr) {
				fmt.Println("Failed to find AWS Credentials. Please ensure that your enviroment is correctly configued as described here: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html")
				os.Exit(1)
			} else {
				panic(err)
			}
		}
	}
}
