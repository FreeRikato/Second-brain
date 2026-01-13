
What is a module system?
> A module system is a way to organize and share code between different files. It solves the problem of "How do i use code from another file?"

![[Pasted image 20260113143235.png]]

**Common module systems**:

| System           | Syntax Example            | Where it runs              |
| ---------------- | ------------------------- | -------------------------- |
| CommonJS         | require(), module.exports | Node.js (legacy)           |
| ESM (ES Modules) | import, export            | Browsers + Node.js         |
| UMD              | Both syntax               | Universal (browser + Node) |

Understanding [[bundlers for js]] is crucial here since it is a major factor on deciding module system 
## module

Specifies the module format that typescript will use when compiling the code

| Option   | Use Case                           |
| -------- | ---------------------------------- |
| ESNext   | Modern ESM with latest features    |
| NodeNext | Node.js native ESM support         |
| ES2022   | Stable ESM for modern environments |
| CommonJS | Node.js require/exports (legacy)   |
| UMD      | Universal Module Definition        |
| AMD      | RequireJS (browser legacy)         |

### Decision tree for module system to use

***START***
  │
  ├─ **Is this a BROWSER/FRONTEND project?**
  │     │
  │     ├─ YES → Are you using a bundler (Vite, webpack, esbuild)?
  │     │         │
  │     │         ├─ YES → module: "ESNext" or "preserve"
  │     │         │       → Bundler handles module transformation
  │     │         │       → Example: Vite, Next.js, CRA
  │     │         │
  │     │         └─ NO → Are you targeting modern browsers?
  │     │                   │
  │     │                   ├─ YES → module: "ES2015" or higher
  │     │                   │       → Native ESM in browsers
  │     │                   │
  │     │                   └─ NO → module: "ES5" or "ES2012"
  │     │                           → Older browsers (IE11, etc)
  │     │
  │     └─ NO → Go to NODE.js section below
  │
  ├─ **Is this a NODE.js (BACKEND) project?**
  │     │
  │     ├─ YES → Does package.json have "type": "module"?
  │     │         │
  │     │         ├─ YES → module: "nodenext" or "ESNext"
  │     │         │       → Native ESM in Node.js
  │     │         │
  │     │         └─ NO → module: "CommonJS"
  │     │                 → Node.js default
  │     │
  │     └─ NO → What runtime?
  │               │
  │               ├─ Deno → module: "ESNext"
  │               │       → Deno uses native ESM
  │               │
  │               ├─ Bun → module: "ESNext"
  │               │       → Bun uses native ESM
  │               │
  │               └─ Other → Check runtime docs
  │
  └─ **Is this a LIBRARY you want to publish?**
        │
        ├─ YES → What formats do you want to support?
        │         │
        │         ├─ ESM only → module: "ESNext"
        │         │
        │         ├─ CommonJS only → module: "CommonJS"
        │         │
        │         └─ Both → Use "ESNext" + dual package exports
        │                 (main: CommonJS, module: ESM)
        │
        └─ NO → Already covered above

### Differentiating between ESM variants

All three output ESM Syntax (import/export). The difference is in
- How imports are resolved
- What features are available

> Input:

```ts
import express from "express";
import { User } from "./models";
export { getUser };
```

1. **ESNext** - uses latest JavaScript features + standard ESM resolution
![[Pasted image 20260113160317.png]]
2. **ES2022** - uses ES2022 JavaScript features + standard ESM resolution
![[Pasted image 20260113160427.png]]
3. **NodeNext** - uses ESM + Node.js-specific module resolution
![[Pasted image 20260113160604.png]]

The key difference here is **module resolution**

## moduleResolution

controls **how Typescript find imported modules**. It determines the rules for resolving import statements to actual files

| Value    | When to Use                                   |
| -------- | --------------------------------------------- |
| bundler  | Frontend with Vite, esbuild, webpack          |
| nodenext | Node.js with ESM ("type": "module")           |
| node     | Node.js with CommonJS (legacy)                |
| classic  | Very old projects (rarely used)               |
| node16   | Node.js 16+ with explicit ESM (like nodenext) |

![[Pasted image 20260113162219.png | 400]]

**What is the relationship between module and moduleResolution?**
![[Pasted image 20260113162306.png]]
![[Pasted image 20260113162647.png]]
### Decision tree for moduleResolution to use

Is this a BUNDLER project (Vite, esbuild, webpack)?
├─ YES → moduleResolution: "bundler"
│
├─ Is this NODE.js with ESM ("type": "module")?
│  ├─ YES → moduleResolution: "nodenext"
│  │
│  └─ NO → moduleResolution: "node"
│     (Legacy CommonJS Node.js)
│
└─ Very old project?
   └─ moduleResolution: "classic" (rare)

> Factoring in the module with moduleResolution

What type of project?
│
├─ FRONTEND (Browser)
│      │
│      ├─ Using bundler (Vite, esbuild, webpack)?
│      │      │
│      │      ├─ YES → module: "ESNext", moduleResolution: "bundler"
│      │      │
│      │      └─ NO → module: "ES2022", moduleResolution: "bundler"
│      │
│      └─ No bundler (modern browsers only)?
│             └─ module: "ES2022", moduleResolution: "bundler"
│
└─ NODE.JS (Backend)
	  │
	  ├─ package.json has "type": "module"?
	  │      │
	  │      ├─ YES → module: "nodenext", moduleResolution: "nodenext"
	  │      │
	  │      └─ NO → module: "CommonJS", moduleResolution: "node"


## lib

tells JavaScript which **built-in JavaScript/TypeScript features to include for type checking**

| lib Value | What It Provides                                |
| --------- | ----------------------------------------------- |
| DOM       | Browser types (document, window, etc.)          |
| ESNext    | Latest JavaScript features (Promise, Map, etc.) |
| ES2022    | ES2022-specific features                        |
| ES2021    | ES2021-specific features                        |

![[Pasted image 20260113165636.png]]

| Project Type    | lib Value         | Why                                    |
| --------------- | ----------------- | -------------------------------------- |
| Browser         | ["DOM", "ESNext"] | DOM APIs + modern JS features          |
| Node.js Backend | ["ESNext"]        | No DOM needed, modern JS features only |
| Legacy Browser  | ["DOM", "ES2020"] | Older browser support                  |

