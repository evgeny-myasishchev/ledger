//go:build tools
// +build tools

// See https://github.com/go-modules-by-example/index/blob/master/010_tools/README.md
// for some notes on this file

package tools

import (
	_ "sigs.k8s.io/kind"
)
