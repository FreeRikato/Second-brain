![[Pasted image 20260113002647.png]]

There are multiple files in a project like for example even in a react app.

All the files/modules bundle them up and make it optimized + backward compatibility

There comes up a concept called tree-shaking where unused code is removed

## Webpack - legacy compatibility
- Extremely powerful + customizable
- Huge plugin ecosystem
- Industry standard for years (used in react, angular or vue)

- Steep learning curve
- Slower builds compared to modern bundlers

## Parcel - Quick setup
- Super beginner-friendly
- Zero configuration (out of the box)
- Built-in HMR

- Less flexible
- Small community

## esbuild - Speed

- Incredibly fast (10-100x)
- Great for dev builds
- Used under the hood in other tools (vite & bun)

- lower-level tool (not a complete framework by itself)
- limited plugin ecosystem compared to webpack

## Vite (New standard)

- Lightning fast dev server (uses esbuild for dev)
- Rollup-based production build (highly optimized)
- Minimal config, works with React, Vue or Svelte
- Excellent DX

- Not as customizable
- Newer compared to others


A bundler is a **tool that combines multiple files into one (or a few) files** that browsers can run

![[Pasted image 20260113143606.png]]

**Do you need a bundler for backend?**
No, *tsc* alone is sufficient for Node.js backends

**Browser**: Cannot resolve imports -> Needs bundler
**Node.js**: Can resolve imports natively -> No bundler needed

![[Pasted image 20260113144155.png]]

**How to decide the bundler approach for backends**

| Approach         | Setup complexity | Use case                       |
| ---------------- | ---------------- | ------------------------------ |
| tsc only         | Simple           | Mose Express Projects          |
| esbuild (bundle) | Medium           | Production, single-file deploy |

**When to use bundlers for backend?**

| Use Case                       | Bundler? | Why                             |
| ------------------------------ | -------- | ------------------------------- |
| Standard production deployment | No       | tsc output runs fine in Node.js |
| Single executable deployment   | Yes      | Bundle everything into one file |
| Faster build times             | Yes      | esbuild is much faster than tsc |
| Lambda/Serverless functions    | Yes      | Single file is easier to deploy |
| Docker containers              | No       | No benefit, adds complexity     |

Actually, [[When to use single executable deployment?]]

