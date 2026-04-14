---
date: 2026-04-09T13:46:48Z
researcher: pi
git_commit: 8b2916b978f80d1a2b0cb56f8e03e7673e43fe61
branch: main
repository: toolnix
topic: "Experimental pi model backend via Together serverless Qwen3-Coder-Next, with Nebius as a latency fallback"
tags: [research, pi, model-backend, together, nebius, qwen, agents]
status: complete
last_updated: 2026-04-09
last_updated_by: pi
last_updated_note: "Initial research note for experimental OpenAI-compatible pi backend configuration"
---

# Research: experimental pi model backend via Together serverless Qwen3-Coder-Next

## Research question

What is the cleanest experimental path for adding a new model backend to `pi`, starting with Together serverless and the model `Qwen/Qwen3-Coder-Next-FP8`, while keeping open a later move to lower-latency dedicated infrastructure such as Together dedicated or Nebius?

## Summary

The shortest practical path is to add a custom provider to `~/.pi/agent/models.json` using pi's built-in OpenAI-compatible provider support.

This is directly supported by pi's documented custom model flow:

- custom providers belong in `~/.pi/agent/models.json`
- `api: "openai-completions"` is the correct pi API type for OpenAI-compatible chat-completions backends
- `baseUrl: "https://api.together.xyz/v1"` is the documented Together OpenAI-compatible base URL
- `apiKey: "TOGETHER_API_KEY"` is valid because pi resolves provider keys from environment-variable names in `models.json`

Together's current public serverless model catalog explicitly lists `Qwen/Qwen3-Coder-Next-FP8` as a chat model with function calling and structured outputs. That makes Together serverless the best low-friction starting point for an experiment.

Nebius also exposes an OpenAI-compatible API at `https://api.studio.nebius.com/v1` and documents `-fast` model flavors for lower latency. That makes Nebius a plausible fallback or comparison provider if serverless latency jitter becomes noticeable.

The main uncertainty is not pi compatibility, but provider/product availability details:

- this research pass verified Together serverless support for `Qwen/Qwen3-Coder-Next-FP8`
- this pass did **not** find equally strong public documentation proving that the exact same model is currently offered on Together on-demand dedicated
- this pass did **not** verify a Nebius catalog entry for the exact same `Qwen3-Coder-Next` model string, only Nebius's general OpenAI compatibility and `-fast` flavor behavior

So the recommendation is:

1. start with Together serverless now
2. prove pi compatibility and real interactive quality first
3. only then choose whether to move to Together dedicated or Nebius for more predictable latency

## Findings

### 1. pi already supports this integration style

Pi's docs explicitly describe adding custom providers and models through `~/.pi/agent/models.json` when the upstream speaks a supported API such as OpenAI Chat Completions.

Relevant pi findings:

- `docs/models.md` documents the `providers` schema for `models.json`
- `docs/models.md` lists `openai-completions` as the most compatible OpenAI-style API option
- `docs/providers.md` says custom providers can be added through `models.json` when they speak a supported API
- `docs/custom-provider.md` confirms that an extension is only needed for non-standard streaming/auth or custom OAuth flows

This means the experimental backend does **not** require a pi extension or code change if the target provider is sufficiently OpenAI-compatible.

### 2. Together is verified for the proposed first step

Together's public docs verify the key pieces needed for the initial pi experiment:

- OpenAI-compatible base URL: `https://api.together.xyz/v1`
- standard bearer-token auth using `TOGETHER_API_KEY`
- chat-completions interface at `/v1/chat/completions`
- support for OpenAI-style messages, system prompts, streaming, and tools

Most importantly, Together's serverless model catalog currently lists:

- model name: `Qwen3-Coder-Next`
- API model string: `Qwen/Qwen3-Coder-Next-FP8`
- context length: `262144`
- function calling: `Yes`
- structured outputs: `Yes`

That is enough evidence to justify a direct pi `models.json` experiment against Together serverless.

### 3. Nebius is a plausible second provider, but with weaker exact-model confirmation

Nebius documents:

- an OpenAI-compatible inference API
- base URL `https://api.studio.nebius.com/v1`
- bearer-token auth via `NEBIUS_API_KEY`
- `-fast` model flavors for lower latency / faster output

This makes Nebius a credible later comparison backend for the same general integration pattern.

However, this research pass did **not** confirm:

- that `Qwen/Qwen3-Coder-Next-FP8` is currently available on Nebius under that exact model string
- that Nebius dedicated endpoints currently expose that exact model as the preferred production path

So Nebius is best treated here as a likely latency-oriented follow-up option, not the primary verified starting point.

### 4. Dedicated-path claims remain partially unverified

The user suggestion included a likely migration path from Together serverless to either Together on-demand dedicated or Nebius dedicated/Fast.

This note found enough documentation to say that this path is conceptually reasonable, because:

- Together documents both serverless and dedicated endpoint products
- Together documents endpoint filtering by `type` and `usage_type`
- Nebius documents performance-oriented `-fast` model flavors and broader endpoint/deployment surfaces

But the exact commercial/product claim still needs live verification before becoming a stronger repo recommendation:

- whether Together currently offers `Qwen/Qwen3-Coder-Next-FP8` as on-demand dedicated
- whether Nebius currently offers the same model and preferred endpoint class for it

## Recommended experimental path

### Recommended first step

Use Together serverless first.

Why this is the best initial path:

- pi compatibility is straightforward and already documented
- Together's OpenAI-compatible base URL is clearly documented
- the exact `Qwen/Qwen3-Coder-Next-FP8` model is publicly listed in Together's current serverless catalog
- the integration requires only local pi configuration, not repo changes or pi extensions

### Recommended second step if latency becomes the issue

If interactive coding quality is acceptable but latency jitter becomes distracting, investigate one of these next:

1. Together dedicated for the same or equivalent model
2. Nebius as a second provider, preferably with a lower-latency `-fast` model flavor if the target model exists there

This keeps the experiment staged:

- first prove correctness and tool-use behavior
- then optimize latency and stability

## Proposed pi configuration

### Minimal Together config

```json
{
  "providers": {
    "together": {
      "baseUrl": "https://api.together.xyz/v1",
      "api": "openai-completions",
      "apiKey": "TOGETHER_API_KEY",
      "models": [
        {
          "id": "Qwen/Qwen3-Coder-Next-FP8",
          "name": "Together Qwen3-Coder-Next",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 262144,
          "maxTokens": 16384
        }
      ]
    }
  }
}
```

### Why start with `reasoning: false`

This note recommends starting conservatively with:

- `reasoning: false`
- no custom `compat` flags initially

Reason:

- the model is being adopted experimentally through a generic OpenAI-compatible path
- pi's more advanced reasoning controls can introduce provider-specific quirks around `developer` role usage or `reasoning_effort`
- it is better to first prove plain chat, tool calls, and streaming against the provider

If request-shape incompatibilities appear, the first fallback to test would be:

```json
"compat": {
  "supportsDeveloperRole": false,
  "supportsReasoningEffort": false
}
```

That matches pi's documented compatibility escape hatches for partial OpenAI-compatible backends.

### Optional Nebius template for later comparison

```json
{
  "providers": {
    "nebius": {
      "baseUrl": "https://api.studio.nebius.com/v1",
      "api": "openai-completions",
      "apiKey": "NEBIUS_API_KEY",
      "models": [
        {
          "id": "<verify-nebius-model-id>",
          "name": "Nebius experimental coder model",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 128000,
          "maxTokens": 16384
        }
      ]
    }
  }
}
```

Do not commit to a Nebius model string until the live Nebius catalog is checked.

## Validation checklist for the experiment

Before treating this as a durable recommendation, validate the Together path with:

1. plain single-turn chat
2. multi-turn chat with long system prompt/context
3. streaming behavior in pi
4. tool-call behavior for `read`, `bash`, `edit`, and `write`
5. long-context behavior on realistic coding tasks
6. error-handling quality and rate-limit ergonomics
7. subjective latency/jitter during normal interactive use

If Together passes correctness checks but feels unstable interactively, that is the right time to compare:

- Together dedicated
- Nebius with an equivalent verified model

## Risks and caveats

### 1. Exact dedicated availability remains a separate question

The first experiment should not assume the dedicated upgrade path is already validated for the exact same model.

### 2. Model recommendation != model availability

Together's general coding-agent recommendations currently highlight other models such as:

- `zai-org/GLM-5.1`
- `Qwen/Qwen3-Coder-480B-A35B-Instruct-FP8`
- `deepseek-ai/DeepSeek-V3.1`

That does **not** invalidate `Qwen/Qwen3-Coder-Next-FP8`; it only means the chosen model should be treated as an experimental selection rather than Together's most clearly documented first-party coding-agent default.

### 3. OpenAI-compatible does not always mean fully OpenAI-identical

Pi's `compat` fields exist for a reason. Even with a documented OpenAI-compatible backend, tool calling, `developer` role handling, strict schema behavior, and reasoning-specific fields can still diverge.

## Conclusion

The strongest evidence-supported recommendation is:

- add a custom Together provider in `~/.pi/agent/models.json`
- use `api: "openai-completions"`
- point it at `https://api.together.xyz/v1`
- use `TOGETHER_API_KEY`
- start with `Qwen/Qwen3-Coder-Next-FP8`

This is the fastest verified path to an experimental new pi model backend.

If real usage shows latency jitter or quality-of-service issues, then evaluate a second-stage move to:

- Together dedicated, if the target model is available there
- or Nebius, after verifying the live model catalog and preferred endpoint flavor

## References

### pi docs consulted

- `/nix/store/vwm5mgry3p2n6ycycjrgisp89nsyadix-pi-0.65.0/lib/node_modules/@mariozechner/pi-coding-agent/README.md`
- `/nix/store/vwm5mgry3p2n6ycycjrgisp89nsyadix-pi-0.65.0/lib/node_modules/@mariozechner/pi-coding-agent/docs/providers.md`
- `/nix/store/vwm5mgry3p2n6ycycjrgisp89nsyadix-pi-0.65.0/lib/node_modules/@mariozechner/pi-coding-agent/docs/models.md`
- `/nix/store/vwm5mgry3p2n6ycycjrgisp89nsyadix-pi-0.65.0/lib/node_modules/@mariozechner/pi-coding-agent/docs/custom-provider.md`

### Together docs consulted

- `https://docs.together.ai/llms.txt`
- `https://docs.together.ai/docs/serverless-models.md`
- `https://docs.together.ai/docs/openai-api-compatibility.md`
- `https://docs.together.ai/docs/how-to-use-qwen-code.md`
- `https://docs.together.ai/docs/dedicated-models.md`
- `https://docs.together.ai/reference/listendpoints.md`

### Nebius docs consulted

- `https://docs.nebius.com/studio/inference/quickstart`
- `https://docs.nebius.com/studio/inference/api`
- `https://docs.nebius.com/studio/inference/models`
