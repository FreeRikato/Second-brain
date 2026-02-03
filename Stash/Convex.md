| Category         | Traditional Tech                                | Convex Replacement                                   |
| ---------------- | ----------------------------------------------- | ---------------------------------------------------- |
| Database         | PostgreSQL, MongoDB, MySQL                      | Built-in Document Database                           |
| API Layer        | Express, Fastify, Next.js API Routes            | Query & Mutation Functions                           |
| Real-time Sync   | WebSockets, Socket.io, Firebase Realtime DB     | Automatic Reactivity                                 |
| Authentication   | Auth0, Clerk, Supabase Auth                     | Convex Auth (with provider integrations)             |
| File Storage     | AWS S3, Cloudflare R2                           | Convex File Storage                                  |
| Caching          | Redis, Memcached                                | Automatic Reactive Caching                           |
| Background Jobs  | BullMQ, Celery, AWS Lambda                      | Convex Actions & Cron Jobs                           |
| Scheduling       | node-cron, AWS EventBridge                      | Cron Functions                                       |
| Full-text Search | Elasticsearch, Algolia                          | Vector & Text Search (built-in)                      |
| State Management | React Query, SWR                                | Auto-synced Hooks (useQuery)                         |


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