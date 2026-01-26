**Terminal UIs in Typescript** is the motto of this framework  where it is possible to build terminal interfaces with flexbox layouts and first-class typescript support

```bash
bun create tui
```

## Hello world

```ts
import { createCliRenderer, Text } from "@opentui/core"

const renderer = await createCliRenderer({
	exitOnCtlC: true
})

renderer.root.add(
	Text({
		content: "Hello, OpenTUI!",
		fg: "#00FF00"
	})
)
```

**Output:**
![[Pasted image 20260126064038.png]]

## Composing components
```ts
import { createCliRenderer, Box, Text } from "@opentui/core";

const renderer = await createCliRenderer({
  exitOnCtrlC: true,
});

renderer.root.add(
  Box(
    { borderStyle: "rounded", padding: 1, flexDirection: "column", gap: 1 },
    Text({ content: "Welcome", fg: "FFFF00" }),
    Text({ content: "Press Ctrl+C to exit" }),
  ),
);
```

**Output:**
![[Pasted image 20260126064510.png]]

