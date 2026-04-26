#!/bin/bash

# Build for Linux (mepb)
echo "Building mepb binary..."
go build -o mepb

echo "✅ Done!"
ls -lh mepb
