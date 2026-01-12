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













