# Compound Engineering global Amp plugin research

## Goal

Make Toolnix's 33 pinned Compound Engineering skills available across the user's Amp projects and threads without consuming 33 entries in the hosted Personal Skills profile.

## Amp plugin contract

Amp directory plugins may bundle standard skill packages and register each package with `amp.registerSkill`. Amp exposes a registered package as `<plugin-name>:<skill-name>`; it does not provide a bare alias.

A plugin directory named `ce` can therefore expose concise names such as `ce:plan`, `ce:work`, and `ce:lfg`. The renderer must remove the redundant upstream `ce-` prefix from each bundled package's directory and frontmatter name. The upstream `lfg` name remains unchanged.

## Cross-skill references

The upstream instructions use bare names such as `ce-work` for several distinct purposes:

- invoking or recommending another skill;
- identifying the current workflow in prose;
- artifact metadata and configuration values;
- scratch paths, script arguments, and run identifiers.

A global replacement would corrupt non-invocation contracts. Instead, each bundled `SKILL.md` should carry an Amp namespace rule that maps any referenced Compound skill name to its registered `ce:<short-name>` counterpart when invoking or recommending a skill. Resources, scripts, metadata values, paths, and identifiers retain their upstream spelling.

## Publication boundary

Toolnix should render a complete `ce` directory plugin and provide an exporter that updates an existing Amp Global User or Workspace Plugins repository checkout. As with the Global Skills exporter, the command must not clone, commit, or push. It must reject an unmanaged destination named `ce`, preserve unrelated plugins, and record the pinned upstream revision inside the plugin.

## Validation

The rendered plugin should be tested through Amp itself. The acceptance proof is:

- the `ce` plugin loads without errors;
- exactly 33 bundled skills are registered;
- representative names are `ce:plan`, `ce:work`, and `ce:lfg`;
- no redundant name such as `ce:ce-plan` exists;
- a representative skill can be inspected with `amp skill info`; and
- the namespace rule is present while non-invocation upstream identifiers remain unchanged.
