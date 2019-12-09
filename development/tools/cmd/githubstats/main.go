package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/jamiealquiza/envy"
	"github.com/pkg/errors"
	"github.com/shurcooL/githubv4"
	"github.com/spf13/cobra"
	"golang.org/x/oauth2"
)

type Issues struct {
	Open   IssuesStats
	Closed IssuesStats
}

type IssuesStats struct {
	TotalCount       int64
	Bugs             int64
	PriorityCritical int64
	Regressions      int64
	TestFailing      int64
	TestMissing      int64
}

type Report struct {
	Issues     Issues
	Type       string
	Owner      string
	Repository string
	Timestamp  time.Time
}

type Config struct {
	GithubAccessToken string
	GithubRepoOwner   string
	GithubRepoName    string
}

var (
	query struct {
		Repository struct {
			Issues struct {
				TotalCount int64
			} `graphql:"issues(states: [$state], labels: $labels)"`
		} `graphql:"repository(owner: $repositoryOwner, name: $repositoryName)"`
	}

	query_no_labels struct {
		Repository struct {
			Issues struct {
				TotalCount int64
			} `graphql:"issues(states: [$state])"`
		} `graphql:"repository(owner: $repositoryOwner, name: $repositoryName)"`
	}
)

func getStats(cfg Config) {
	src := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: cfg.GithubAccessToken},
	)
	httpClient := oauth2.NewClient(context.Background(), src)

	client := githubv4.NewClient(httpClient)

	r := Report{
		Timestamp:  time.Now(),
		Type:       "GithubIssuesStatsReport",
		Repository: cfg.GithubRepoName,
		Owner:      cfg.GithubRepoOwner,
	}

	variables := map[string]interface{}{
		"repositoryOwner": githubv4.String(cfg.GithubRepoOwner),
		"repositoryName":  githubv4.String(cfg.GithubRepoName),
	}

	// Total count
	variables["state"] = githubv4.IssueState("OPEN")
	err := client.Query(context.Background(), &query_no_labels, variables)
	if err != nil {
		log.Fatal(err)
	}
	r.Issues.Open.TotalCount = query_no_labels.Repository.Issues.TotalCount

	variables["state"] = githubv4.IssueState("CLOSED")
	err = client.Query(context.Background(), &query_no_labels, variables)
	if err != nil {
		log.Fatal(err)
	}
	r.Issues.Closed.TotalCount = query_no_labels.Repository.Issues.TotalCount

	// Closed
	variables["labels"] = []githubv4.String{"bug"}
	r.Issues.Closed.Bugs = executeQuery(client, variables)

	variables["labels"] = []githubv4.String{"regression"}
	r.Issues.Closed.Regressions = executeQuery(client, variables)

	variables["labels"] = []githubv4.String{"test-failing"}
	r.Issues.Closed.TestFailing = executeQuery(client, variables)

	variables["labels"] = []githubv4.String{"test-missing"}
	r.Issues.Closed.TestMissing = executeQuery(client, variables)

	variables["labels"] = []githubv4.String{"priority/critical"}
	r.Issues.Closed.PriorityCritical = executeQuery(client, variables)

	// Open
	variables["state"] = githubv4.IssueState("OPEN")
	variables["labels"] = []githubv4.String{"bug"}
	r.Issues.Open.Bugs = executeQuery(client, variables)

	variables["labels"] = []githubv4.String{"regression"}
	r.Issues.Open.Regressions = executeQuery(client, variables)

	variables["labels"] = []githubv4.String{"test-failing"}
	r.Issues.Open.TestFailing = executeQuery(client, variables)

	variables["labels"] = []githubv4.String{"test-missing"}
	r.Issues.Open.TestMissing = executeQuery(client, variables)

	variables["labels"] = []githubv4.String{"priority/critical"}
	r.Issues.Open.PriorityCritical = executeQuery(client, variables)

	json, err := json.Marshal(r)
	fatalOnError(err, "while marshaling json")
	fmt.Println(string(json))
}

func executeQuery(client *githubv4.Client, variables map[string]interface{}) int64 {
	err := client.Query(context.Background(), &query, variables)
	if err != nil {
		fatalOnError(err, "while executing query")
	}
	return query.Repository.Issues.TotalCount
}

func fatalOnError(err error, context string) {
	if err != nil {
		log.Fatal(errors.Wrap(err, context))
	}
}

func main() {
	cfg := Config{}
	var rootCmd = &cobra.Command{
		Use:   "githubstats",
		Short: "githubstats fetches stats for github issues",
		Long:  `githubstats fetches stats for github issues and prints JSON report`,
		Run: func(cmd *cobra.Command, args []string) {
			getStats(cfg)
		},
	}

	rootCmd.PersistentFlags().StringVarP(&cfg.GithubAccessToken, "github-access-token", "t", "", "github token [Required]")
	rootCmd.PersistentFlags().StringVarP(&cfg.GithubRepoOwner, "github-repo-owner", "o", "", "owner/organisation name [Required]")
	rootCmd.PersistentFlags().StringVarP(&cfg.GithubRepoName, "github-repo-name", "r", "", "repository name [Required]")

	rootCmd.MarkPersistentFlagRequired("github-token")
	rootCmd.MarkPersistentFlagRequired("owner")
	rootCmd.MarkPersistentFlagRequired("repo")

	envy.ParseCobra(rootCmd, envy.CobraConfig{Prefix: "APP", Persistent: true, Recursive: false})

	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}
