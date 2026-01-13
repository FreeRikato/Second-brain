## When to

| Scenario                           | Example                      | Why Single Executable Helps                  |
| ---------------------------------- | ---------------------------- | -------------------------------------------- |
| Serverless/Lambda                  | AWS Lambda, Vercel Functions | Upload one file instead of node_modules/     |
| Enterprise/air-gapped environments | Internal company systems     | No internet = can't download dependencies    |
| Simplified deployment              | Docker containers, VMs       | One file to copy, no dependency install      |
| Distribution to customers          | CLI tools, desktop apps      | User just runs the binary                    |
| Version locking                    | Legacy systems               | Freeze exact versions, no npm install issues |
## When not to
| Scenario                            | Why Not                                       |
| ----------------------------------- | --------------------------------------------- |
| Standard web server                 | Docker/node_modules works fine                |
| Team environment                    | package.json + npm install is simpler         |
| Rapid development                   | Rebuilding single binary slows down iteration |
| Monolith with many dependencies<br> | Binary becomes huge, slow to build            |

## Decision tree
**Do you need single executable?**
        │
        ├─ YES → Why?
        │         ├─ Air-gapped environment? → YES
        │         ├─ Serverless deployment? → YES
        │         ├─ Distribute to customers? → YES
        │         └─ Simplify Docker image? → MAYBE (multi-stage is better)
        │
        └─ NO → Standard deployment (tsc + node) is fine