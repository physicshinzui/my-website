+++
title = "Code block environment"
tags = ["environment", "code"]
summary = ""
+++

# test code block.
This note is for checking code block styling and copy-button behavior.

## Julia
```julia
using LinearAlgebra

A = [1.0 2.0; 3.0 4.0]
b = [1.0, 0.0]
x = A \ b

println(x)
```

## Python
```python
from pathlib import Path

root = Path("notebooks")
markdown_files = sorted(root.rglob("*.md"))

for path in markdown_files:
    print(path)
```

## Bash
```bash
julia --project=. dev.jl
```

## Plain text
```text
The quick brown fox jumps over the lazy dog.
Copy this block to verify the button state changes correctly.
```
