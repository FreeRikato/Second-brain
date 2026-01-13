```json
{
	"compilerOptions": {
		"module": "ESNext",
		"moduleResolution": "Bundler",
		"lib": ["ESNext"],
		"outDir": "./dist",
		"target": "ESNext",
		"incremental": true,
		"tsBuildInfoFile": "./node_modules/.cache/tsbuildinfo",
		"noEmit": true, 
		"strict": true,		
		"noUncheckedIndexedAccess": true,
		"noUnusedLocals": true,
		"noUnusedParameters": true,
		"skipLibCheck": true,
		"verbatimModuleSyntax": true,
		"allowImportingTsExtensions": false,
		"baseUrl": "./src",
		"paths": {
			"@/*": ["*"]
		},
		"resolveJsonModule": true,
		"isolatedModules": true
	},
	"include": ["src"],
	"exclude": ["node_modules", "dist"]
}
```