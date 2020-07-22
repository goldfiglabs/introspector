package main

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"runtime"

	"github.com/aws/aws-sdk-go-v2/aws/external"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/client"
	"github.com/docker/docker/pkg/stdcopy"
	"github.com/pkg/errors"
	"golang.org/x/oauth2/google"
)

func requireGoldfigComposition(ctx context.Context, cli *client.Client) types.Container {
	fmt.Println("Checking for running goldfig")
	containers, err := cli.ContainerList(ctx, types.ContainerListOptions{
		Filters: filters.NewArgs(filters.Arg("label", "goldfig-cli")),
	})
	if err != nil {
		panic(err)
	}
	if len(containers) > 1 {
		panic("More than one Gold Fig CLI found running")
	}
	if len(containers) == 0 {
		panic("Could not find Gold Fig CLI container running")
	}
	return containers[0]
}

func loadAwsCredentials(ctx context.Context) (map[string]string, error) {
	println("Looking for AWS Credentials")
	cfg, err := external.LoadDefaultAWSConfig()
	if err != nil {
		return nil, err
	}
	creds, err := cfg.Credentials.Retrieve(ctx)
	if err != nil {
		return nil, err
	}
	fmt.Println(creds)
	env := make(map[string]string)
	env["AWS_ACCESS_KEY_ID"] = creds.AccessKeyID
	env["AWS_SECRET_ACCESS_KEY"] = creds.SecretAccessKey
	if len(creds.SessionToken) > 0 {
		env["AWS_SESSION_TOKEN"] = creds.SessionToken
	}
	return env, nil
}

func loadGcpCredentials(ctx context.Context) (map[string]string, error) {
	adc, err := google.FindDefaultCredentials(ctx, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		return nil, err
	}
	token, err := adc.TokenSource.Token()
	if err != nil {
		return nil, err
	}
	if !token.Valid() {
		return nil, errors.New("Invalid token")
	}
	env := make(map[string]string)
	env["GOLDFIG_GCP_AUTH"] = string(adc.JSON)
	return env, nil
}

func needsAwsCredential(userCmd []string) bool {
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

func cmdPassthrough(ctx context.Context, cli *client.Client, gfCli types.Container, userCmd []string) error {
	var env map[string]string
	cmd := append([]string{"python", "goldfig.py"}, userCmd...)
	if needsAwsCredential((userCmd)) {
		awsEnv, err := loadAwsCredentials(ctx)
		if err != nil {
			return err
		}
		env = awsEnv
	} else if needsGcpCredential(userCmd) {
		gcpEnv, err := loadGcpCredentials(ctx)
		if err != nil {
			return err
		}
		env = gcpEnv
	}

	envStrings := []string{}
	for key, val := range env {
		envStrings = append(envStrings, fmt.Sprintf("%v=%v", key, val))
	}
	execResp, err := cli.ContainerExecCreate(ctx, gfCli.ID, types.ExecConfig{
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
	if len(cmd) > 0 && cmd[0] == "check" {
		fmt.Printf("OS: %s\nArchitecture: %s\n", runtime.GOOS, runtime.GOARCH)
		os.Exit(0)
	}
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
	gfCli := requireGoldfigComposition(ctx, cli)
	err = cmdPassthrough(ctx, cli, gfCli, cmd)
	if err != nil {
		panic(err)
	}
}
