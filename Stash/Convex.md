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