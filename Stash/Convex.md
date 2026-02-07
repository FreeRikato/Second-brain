| Category         | Traditional Tech                            | Convex Replacement                       |
| ---------------- | ------------------------------------------- | ---------------------------------------- |
| Database         | PostgreSQL, MongoDB, MySQL                  | Built-in Document Database               |
| API Layer        | Express, Fastify, Next.js API Routes        | Query & Mutation Functions               |
| Real-time Sync   | WebSockets, Socket.io, Firebase Realtime DB | Automatic Reactivity                     |
| Authentication   | Auth0, Clerk, Supabase Auth                 | Convex Auth (with provider integrations) |
| File Storage     | AWS S3, Cloudflare R2                       | Convex File Storage                      |
| Caching          | Redis, Memcached                            | Automatic Reactive Caching               |
| Background Jobs  | BullMQ, Celery, AWS Lambda                  | Convex Actions & Cron Jobs               |
| Scheduling       | node-cron, AWS EventBridge                  | Cron Functions                           |
| Full-text Search | Elasticsearch, Algolia                      | Vector & Text Search (built-in)          |
| State Management | React Query, SWR                            | Auto-synced Hooks (useQuery)             |


| Term     | What It Does                                    | Analogy                                              |
| -------- | ----------------------------------------------- | ---------------------------------------------------- |
| Query    | READS data from database                        | SELECT in SQL, GET in REST                           |
| Mutation | WRITES/CHANGES data                             | INSERT/UPDATE/DELETE in SQL, POST/PUT/DELETE in REST |
| Action   | Runs side effects (API calls, heavy processing) | Backend API endpoints, background jobs               |

| Term       | What It Does                | Analogy                                 |
| ---------- | --------------------------- | --------------------------------------- |
| Schema     | Defines your data structure | TypeScript types, SQL table definitions |
| Document   | A single data record        | A row in SQL table, a JSON object       |
| Index      | Optimizes data lookup speed | SQL indexes, book's table of contents   |
| Collection | Groups similar documents    | A table in SQL                          |

| Term        | What It Does                                    | Analogy                                |
| ----------- | ----------------------------------------------- | -------------------------------------- |
| useQuery    | Subscribes to Query functions (auto-updates UI) | React Query's useQuery but auto-synced |
| useMutation | Calls Mutation functions                        | Form submissions, button clicks        |
| useAction   | Calls Action functions                          | API calls, complex operations          |

| Term          | What It Means                                              |
| ------------- | ---------------------------------------------------------- |
| Convex Cloud  | The platform hosting your app (no self-hosting needed)     |
| Deployment    | Instant updates to production (one command)                |
| Reactivity    | UI auto-updates when data changes                          |
| Deterministic | Functions produce same output for same input (predictable) |
| Idempotent    | Running multiple times doesn't cause side effects          |
| Subscription  | Client listens to data changes automatically               |

| Challenge | Why It's Hard |
|-----------|---------------|
| Remote persistence | Data lives somewhere you don't control |
| Asynchronous APIs | Requires async/await, not synchronous access |
| Shared ownership | Others can change data without your knowledge |
| Staleness | Data becomes outdated automatically |

| Pillar     | Physical Equivalent     | AWS Abstraction               | What It Does                 |
| ---------- | ----------------------- | ----------------------------- | ---------------------------- |
| Compute    | Servers/CPUs            | EC2, Lambda, ECS              | Processing power to run code |
| Storage    | Hard drives/Tapes       | EBS, S3, EFS                  | Persist data durably         |
| Networking | Routers/Switches/Cables | VPC, subnets, security groups | Connect resources securely   |


| Service | Pillar     | Managed?            | Stateful?     | Serverless?        |
| ------- | ---------- | ------------------- | ------------- | ------------------ |
| EC2     | Compute    | No (you manage OS)  | Optional      | No                 |
| Lambda  | Compute    | Yes (fully managed) | No            | Yes                |
| S3      | Storage    | Yes                 | Yes (objects) | Yes                |
| RDS     | Storage    | Yes (managed DB)    | Yes           | No (has instances) |
| VPC     | Networking | Partial             | Yes (config)  | N/A                |

| Action           | How To Do It                                |
| ---------------- | ------------------------------------------- |
| Edit text        | Double-click any text node in the DOM tree  |
| Edit attributes  | Double-click attributes (e.g., class="btn") |
| Delete element   | Press Delete key or right-click → Delete    |
| Hide element     | Press H key (toggles visibility)            |
| Reorder elements | Drag and drop in the DOM tree               |
| Copy element     | Ctrl+C / Cmd+C                              |


| Benchmark                        | Opus 4.6 | Opus 4.5 | Sonnet 4.5 | Gemini 3 Pro | GPT-5.2 (all) | GPT-5.3-Codex (xhigh) | GPT-5.2-Codex (xhigh) | GPT-5.2 (xhigh) |
| -------------------------------- | -------- | -------- | ---------- | ------------ | ------------- | --------------------- | --------------------- | --------------- |
| Terminal-Bench 2.0               | 65.4%    | 59.8%    | 51.0%      | 56.2%        | 64.7%         | 77.3%                 | 64.0%                 | 62.2%           |
| SWE-bench Verified               | 80.8%    | 80.9%    | 77.2%      | 76.2%        | 80.0%         | —                     | —                     | —               |
| SWE-Bench Pro (Public)           | —        | —        | —          | —            | —             | 56.8%                 | 56.4%                 | 55.6%           |
| OSWorld                          | 72.7%    | 66.3%    | 61.4%      | —            | —             | —                     | —                     | —               |
| OSWorld-Verified                 | —        | —        | —          | —            | —             | 64.7%                 | 38.2%                 | 37.9%           |
| τ2-bench Retail                  | 91.9%    | 88.9%    | 86.2%      | 85.3%        | 82.0%         | —                     | —                     | —               |
| τ2-bench Telecom                 | 99.3%    | 98.2%    | 98.0%      | 98.0%        | 98.7%         | —                     | —                     | —               |
| MCP Atlas                        | 59.5%    | 62.3%    | 43.8%      | 54.1%        | 60.6%         | —                     | —                     | —               |
| BrowseComp                       | 84.0%    | 67.8%    | 43.9%      | 59.2%        | 77.9%         | —                     | —                     | —               |
| Humanity's Last Exam (w/o tools) | 40.0%    | 30.8%    | 17.7%      | 37.5%        | 36.6%         | —                     | —                     | —               |
| Humanity's Last Exam (w/ tools)  | 53.1%    | 43.4%    | 33.6%      | 45.8%        | 50.0%         | —                     | —                     | —               |
| Finance Agent                    | 60.7%    | 55.9%    | 54.2%      | 44.1%        | 56.6%         | —                     | —                     | —               |
| GDPVal-AA Elo                    | 1606     | 1416     | 1277       | 1195         | 1462          | —                     | —                     | —               |
| GDPval (wins or ties)            | —        | —        | —          | —            | —             | 70.9%                 | —                     | 70.9%           |
| ARC AGI 2                        | 68.8%    | 37.6%    | 13.6%      | 45.1%        | 54.2%         | —                     | —                     | —               |
| GPQA Diamond                     | 91.3%    | 87.0%    | 83.4%      | 91.9%        | 93.2%         | —                     | —                     | —               |
| MMMU Pro (w/o tools)             | 73.9%    | 70.6%    | 63.4%      | 81.0%        | 79.5%         | —                     | —                     | —               |
| MMMU Pro (w/ tools)              | 77.3%    | 73.9%    | 68.9%      | —            | 80.4%         | —                     | —                     | —               |
| MMMLU                            | 91.1%    | 90.8%    | 89.5%      | 91.8%        | 89.6%         | —                     | —                     | —               |
| Cybersecurity CTF                | —        | —        | —          | —            | —             | 77.6%                 | 67.4%                 | 67.7%           |
| SWE-Lancer IC Diamond            | —        | —        | —          | —            | —             | 81.4%                 | 76.0%                 | 74.6%           |

| Code | Meaning      | What It Tells You                    |
| ---- | ------------ | ------------------------------------ |
| 200  | OK           | ✅ Success! Resource loaded perfectly |
| 304  | Not Modified | 🔄 Using cached version (faster!)    |
| 404  | Not Found    | ❌ File doesn't exist on server       |
| 500  | Server Error | 🔥 Something broke on the backend    |

| Protocol | Version  | Why It Matters                                          |
| -------- | -------- | ------------------------------------------------------- |
| http/1.1 | HTTP 1.1 | Older, slower (one request at a time per connection)    |
| h2       | HTTP/2   | Modern! Multiplexing = multiple requests simultaneously |
| h3       | HTTP/3   | Cutting-edge! Uses QUIC for even faster performance     |

| Type       | Description      | Examples             |
| ---------- | ---------------- | -------------------- |
| document   | Main HTML page   | index.html           |
| script     | JavaScript files | app.js, bundle.js    |
| stylesheet | CSS files        | style.css, theme.css |
| xhr/fetch  | API calls        | api/data, users.json |
| image      | Picture files    | logo.png, hero.jpg   |
| font       | Web fonts        | font.woff2           |