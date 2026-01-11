An Extension is just a Website but with superpowers. Browser can only understand HTML, CSS and JS. The knowledge of building a website is transferrable to building extensions.

**Normal website** -> Loaded from remote server (like `google.com`)
**Extension** -> Loaded from hard drive and lives inside browser's interface (toolbar), not inside a specific tab

## Development Mode

For local development, security verifications have to be bypassed to test "Unpacked" (raw) code.

Navigate to `chrome://extensions` => Toggle Developer mode

Each time there is a code change, the extension has to be reloaded from its source since chrome reads and caches the code changes for once.


| Extension Component | Requires extension reload |
|---|--- |
| The manifest | Yes |
| Service worker | Yes |
| Content scripts | Yes (plus the host page) |
| The Popup | No |
| Options page | No |
| Other extensions HTML pages | No |


Install the npm package chrome-types to take advantage of auto-completion for
the Chrome API.

## Understanding `Manifest.json`

Browsers are highly secured and do not run code unless they know exactly what it is and what permissions it needs.

- The identity and capabilities of software must be explicitly declared for the browser to accept. Kind of like a "passport"

Create a file `manifest.json` and in it have this config -

> "manifest_version": 3

This tells chrome that we are following the latest rules for how extensions work

> "action"

This defines the intent in the extension like clicking on a button show HTML file

### Manifest.json
```json
{
  "name": "Hello Extensions",
  "description": "Base Level Extension",
  "version": "1.0",
  "manifest_version": 3,
  "action": {
    "default_popup": "hello.html",
    "default_icon": "hello_extensions.png"
  }
}
```

## Creating the Popup

### hello.html
```html
<html>
  <body>
    <h1>Hello Extensions</h1>
    <script src="popup.js"></script>
  </body>
</html>
```

### popup.js
```js
console.log("This is a popup!")
```

## How Extensions Work

### Event Loop

Extensions are event-driven and are dormant until something triggers them to wake up

Software shouldn't run unless there is a trigger by the user in order to save memory and battery

The trigger is controller with the `action` key. The extension does nothing until the **Click Event** occurs on the toolbar icon.

Once clicked => Chrome looks at the manifest => Find `hello.html` => Renders it => Runs `popup.js` => When clicked away => Destroys instance

Popup is **"ephemeral"** (short-lived)

### Context Isolation

Every tab in chrome is a "sandbox" and variables + logs from one tab can't be seen in another.

The extension popup is a tiny, separate browser tab floating over the main window.

> **NOTE**: As each extension popup is a tab on its own, opening up developer tools will be opened for that particular tab in main browser window and not for the extension.
>
> **Solution**: Right click on the popup itself and choose "inspect". This opens up devtools window specifically for that tiny floating HTML page

## Debugging

During development, logs are crucial to debug and develop. Use `console.log()` statements in popup.js to inspect behavior.

When there is a breakage in the extension, the errors can be seen in the extensions tab with `Errors` button

## Structuring an extension project


![Codebase structure](https://developer.chrome.com/static/docs/extensions/get-started/tutorial/hello-world/image/the-contents-an-extensio-fc9e4690df76c_1920.png)

