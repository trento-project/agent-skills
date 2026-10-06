# Test double boundaries: jest and React Testing Library

## Module mocks

- Use `jest.mock` for third-party modules that you cannot inject. Do not use it for first-party
  modules that have a real object and a fakeable transport.
- Babel-transformed ESM (a package in the negative lookahead of `transformIgnorePatterns`)
  exposes exports as getters. `jest.spyOn(module, 'export')` then throws
  `Cannot set property … which has only a getter`. A module mock is the only option. Say so in a
  comment in the spec, so nobody "improves" it later.

## Spy on the real instance

```js
const disconnect = jest.spyOn(realAgent, 'disconnect');
// ...render, unmount...
expect(disconnect).toHaveBeenCalled();
```

`jest.spyOn` calls through by default, so the real behaviour still runs.

## Read the output of a wiring component

```js
const lastOptions = () => useThing.mock.calls.at(-1)[0];
const currentAgent = () => lastOptions().agent;

expect(currentAgent()).toBe(agentBefore); // identity is meaningful here
```

## The collaborator owns its own link

```js
// in the agent's own suite, not in the component's suite
agent.disconnect();
expect(channel.leave).toHaveBeenCalled();
expect(agent.channel).toBeNull();
```

## Correlation across two requests

```js
const first = await sendMessage('one');
const second = await sendMessage('two');
expect(second.run_id).not.toBe(first.run_id);
```

A helper with the shape `streamAssistantTurn(sentPayload, { deltas })` takes ids from the sent
payload. A test author then cannot pair a reply with the wrong ids by hand.

## Queries

Priority: `getByRole(role, { name })`, then `getByLabelText`, then `getByText`, then
`getByTestId` as the last resort.

Component mocks render copy:

```jsx
jest.mock('./Parts', () => ({
  Parts: () => <span>message parts</span>, // find with getByText('message parts')
}));
```

Before you remove a `data-testid` from markup, search the Cypress suite: `*.cy.js`, page
objects and fixtures.

## Shared helpers

A `renderWithSocket` helper in a shared test-utils module pulls the provider, the store and the
network client into every spec that imports that module. Wrap inside the existing helpers instead.
