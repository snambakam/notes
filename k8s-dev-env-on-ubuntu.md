# K8S Development Environment on Ubuntu

## Download kind and add it to PATH

```
go get sigs.k8s.io/kind
```

In $HOME/.bashrc, add the following

```
export PATH=$PATH:$(go env GOPATH)/bin
```

## Download kubectl

```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

# References

* [Install kubectl on linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
