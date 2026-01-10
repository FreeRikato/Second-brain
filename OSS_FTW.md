I'm building a tool that leverages the GitHub API to streamline open source contribution by helping me find issues I can actually work on.

## The Problem
Finding suitable open source issues is exhausting because they often fall into three categories:
- Already claimed by another contributor
- Already have an associated PR
- Too complex for my current skill level

## The Solution
My application will:
1. Fetch repository metadata via GitHub API
2. Scan open issues and their discussions
3. Identify which issues already have PRs linked to them
4. Filter out issues that are taken or too advanced
5. Use an AI agent (like Claude Code) to analyze remaining issues and determine if they're a good match for my skills

This way, I can focus my energy on issues that are actually available and within my ability to resolve.
