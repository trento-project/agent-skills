# Reading dependency source

Read the code at the version that the lock file pins. To check a release that you have not
installed, fetch it into a temporary directory.

## Fetch a published version

```bash
# npm: the tarball contains what consumers get, including dist/
cd "$(mktemp -d)" && npm pack some-package@1.2.3 && tar xzf some-package-1.2.3.tgz
ls package/dist

# Hex
mix hex.package fetch some_package 1.2.3 --unpack

# Go: prints the module cache directory
go mod download -json example.com/some/module@v1.2.3
```

The installed copy is in `node_modules/<pkg>`, `deps/<pkg>` or the Go module cache. For npm,
read the built output in `dist/`, because that is the code that runs. The `src/` tree on GitHub
can differ from it.

## Diff two versions before you claim that a bump fixes something

```bash
diff -ru old/package/dist new/package/dist | less
```

Look at the function that matters, not the changelog.

## Check what runs at runtime

```js
// in a test or a browser console
console.log(SomeClass.prototype.someMethod.toString());
console.log(SomeClass.prototype.someMethod.length); // declared parameter count
```

In JavaScript, a function ignores extra arguments without an error. If the declared parameter
count is lower than what the caller passes, the extra argument is lost.

```elixir
# in iex: which module and version actually loaded
:code.which(SomeModule)
Application.spec(:some_app, :vsn)
```

## Reproduce inside the failing process

When a tool works and the application fails, run the check from inside the application's own
runtime, with its libraries and configuration. Examples:

- Resolve the host name with the same library call that the application uses, and print the
  address.
- Print the peer certificate fingerprint from the application's own TLS connection.
- Print the library versions that the running node loaded.

A command-line tool can take a different path, for example through the hosts file instead of DNS.
